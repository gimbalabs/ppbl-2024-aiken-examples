import {
    applyCborEncoding,
    applyParamsToScript,
    AppWalletKeyType,
    YaciProvider,
    deserializeAddress,
    MeshWallet,
    MeshTxBuilder,
    mConStr0,
    builtinByteString,
    PlutusScript,
    serializePlutusScript,
    stringToHex,
    outputReference,
    resolveScriptHash,
    Integer,
    ConStr0,
    deserializeDatum,
} from "@meshsdk/core";


import blueprint from "./plutus.json";
const languageVersion = "V3";

//const apiKey = process.env.BLOCKFROST_KEY as string;
//        if (!apiKey) {
//            throw console.error("BLOCKFROST_KEY not set");
//        }
//export const provider = new BlockfrostProvider(apiKey);
export const provider = new YaciProvider('http://localhost:8080/api/v1', 'http://localhost:10000');

export const newWallet = async (providedMnemonic?: string[]) => {
  let mnemonic = providedMnemonic;
  if (!providedMnemonic) {
      mnemonic = MeshWallet.brew() as string[];
      console.log(
      "Wallet generated, if you want to reuse the same address, please save the mnemonic:"
      );
      console.log(mnemonic);
  }
  const signingKey: AppWalletKeyType = {
      type: "mnemonic",
      words: mnemonic as string[],
  };

  const wallet = new MeshWallet({
          key: signingKey,
          networkId: 0,
          fetcher: provider,
          submitter: provider,
      });

  await wallet.init()
  return wallet;
};

const mintContractCbor = (
    tokenNameHex: string,
    utxoTxHash: string,
    utxoTxId: number,
  ) => {
    let scriptCbor = blueprint.validators[1]!.compiledCode;
    let utxo = outputReference(utxoTxHash, utxoTxId);

    return applyParamsToScript(
      scriptCbor,
      [builtinByteString(tokenNameHex), utxo],
      "JSON",
    );
  };

const faucetContractCbor = (accessTokenPolicy: string, faucetTokenPolicy: string) => {
    let scriptCbor = blueprint.validators[2]!.compiledCode;
    return applyParamsToScript(scriptCbor, [accessTokenPolicy, faucetTokenPolicy]);
};

export class MeshTx {
    constructor(
        public wallet: MeshWallet, 
        //public provider: BlockfrostProvider,
        public provider: YaciProvider,
        public networkId: number,
        public stakeCredential?: string | null,
        
    ) {
        this.wallet = wallet;
        this.provider = provider;
        this.networkId = networkId;
        this.stakeCredential = stakeCredential ?? null;
    }
  
    newTx = async () => {
      const address = await this.wallet.getChangeAddress();
  
      const txBuilder = new MeshTxBuilder({
        fetcher: this.provider,
        evaluator: this.provider,
      });
      const utxos = await this.wallet.getUtxos();
      txBuilder.changeAddress(address).selectUtxosFrom(utxos);
      return txBuilder;
    };
  
    newValidationTx = async () => {
      const txBuilder = await this.newTx();
      const collateral = (await this.wallet.getCollateral())[0];
      if (collateral) {
      txBuilder.txInCollateral(
        collateral.input.txHash,
        collateral.input.outputIndex,
        collateral.output.amount,
        collateral.output.address
        );
        return txBuilder;
      } else {
        throw new Error("No collateral available");
      }
    };

    getScriptAddress = (scriptCbor: string) => {
        const { address } = serializePlutusScript(
          { code: scriptCbor, version: languageVersion },
          this.stakeCredential ?? undefined,
          this.networkId,
        );
        return address;
      };

    mint = async (
        tokenName: string,
        quantity: bigint,
    ) => {
        try {
            const walletAddress = await this.wallet.getChangeAddress();
            console.log("WalletAddress:", walletAddress);
            const tokenNameHex = stringToHex(tokenName);
            const utxos = await this.provider.fetchAddressUTxOs(walletAddress);
            if (utxos.length < 1) throw new Error("No UTXOs available");
            const firstUtxo = utxos[0];

            const mintTokenScript = mintContractCbor(
                tokenNameHex,
                firstUtxo?.input.txHash ?? '',
                firstUtxo?.input.outputIndex ?? 0,
              );
            
            const mintTokenPolicy = resolveScriptHash(
                mintTokenScript,
                languageVersion,
              );

            // Log for debugging
            console.log("Building mint transaction...");
            console.log("MintTokenPolicy:", mintTokenPolicy);
            console.log("TokenNameHex:", tokenNameHex);
            console.log("Quantity:", quantity);
            const txBuilder = await this.newValidationTx();
            const txHex = await txBuilder
                .txIn(
                    firstUtxo?.input.txHash ?? '',
                    firstUtxo?.input.outputIndex ?? 0,
                    firstUtxo?.output.amount ?? [],
                    firstUtxo?.output.address ?? '',
                )
                .mintPlutusScript(languageVersion)
                .mint(quantity.toString(), mintTokenPolicy, tokenNameHex)
                .mintingScript(mintTokenScript)
                .mintRedeemerValue(mConStr0([]))
                .txOut(walletAddress, [
                    { unit: "lovelace", quantity: "2000000" },
                    { unit: mintTokenPolicy + tokenNameHex, quantity: quantity.toString() },
                  ])
                .complete();

            console.log("Transaction built successfully");
            const singedTx = await this.wallet.signTx(txHex);
            const txHash = await this.wallet.submitTx(singedTx);
            return {
                txHash,
                tokenNameHex,
                mintTokenPolicy,
            };
        } catch (error) {
            console.error("Error in mint transaction:", error);
            throw error;
        }
    };

    lock = async (
        withdrawalAmount: bigint,
        faucetLockedAmount: bigint,
        faucetTokenNameHex: string,
        faucetTokenPolicy: string,
        accessTokenPolicy: string,
    ) => {
        try {
            const walletAddress = this.wallet.getChangeAddress();
            const faucetContractScript: PlutusScript = {
                code: faucetContractCbor(accessTokenPolicy, faucetTokenPolicy),
                version: languageVersion,
              };
            const faucetScriptCbor = applyCborEncoding(faucetContractScript.code);
            const faucetScriptAddress = this.getScriptAddress(faucetScriptCbor);

            // Log for debugging
            console.log("Building lock transaction with datum...");
            console.log("ValidatorAddress:", faucetScriptAddress);
            
            const txBuilder = await this.newTx();
            const txHex = await txBuilder
                .txOut(
                    faucetScriptAddress, [
                        { unit: "lovelace", quantity: "2000000" },
                        { unit: faucetTokenPolicy + faucetTokenNameHex, quantity: faucetLockedAmount.toString() },
                    ]
                )
                .txOutInlineDatumValue(mConStr0([withdrawalAmount, faucetTokenNameHex]))
                .complete();

            console.log("Transaction built successfully");
            const singedTx = await this.wallet.signTx(txHex);
            const txHash = await this.wallet.submitTx(singedTx);
            return {
                txHash
            }
        } catch (error) {
            console.error("Error in lock transaction:", error);
            throw error;
        }
    };
  
    withdrawal = async (
        withdrawalAmount: bigint,
        faucetTokenNameHex: string,
        faucetTokenPolicy: string,
        accessTokenNameHex: string,
        accessTokenPolicy: string,

    ) => {
        try {
            let datum: ConStr0<[Integer, string]> | null = null;
            let faucetAmount: string | undefined;
            const walletAddress = await this.wallet.getChangeAddress();
            const ownPubKey = deserializeAddress(walletAddress).pubKeyHash;
            const faucetContractScript: PlutusScript = {
                code: faucetContractCbor(accessTokenPolicy, faucetTokenPolicy),
                version: languageVersion,
              };
            const faucetScriptCbor = applyCborEncoding(faucetContractScript.code);
            const faucetScriptAddress = this.getScriptAddress(faucetScriptCbor);
            console.log("FaucetScriptAddress:", faucetScriptAddress);

            const scriptInput = (
                await this.provider.fetchAddressUTxOs(faucetScriptAddress)
              ).find((input) => {
                if (input.output.plutusData) {
                  datum = deserializeDatum(input.output.plutusData);
                  faucetAmount = input.output.amount.find((amount) => amount.unit === faucetTokenPolicy + faucetTokenNameHex)?.quantity;
                  return input;
                }
                return null;
              });

            if (!datum) throw new Error("No datum found");
            console.log("Current FaucetAmount:", faucetAmount);
            const faucetAmountInt = BigInt(faucetAmount ?? 0);
            const remainingFaucetAmount = faucetAmountInt - withdrawalAmount;
            const txBuilder = await this.newValidationTx();

            // Log for debugging
            console.log("Building transaction to increment datum...");
            console.log("PubKeyHash:", ownPubKey);
            console.log("Datum:", datum);

            const txHex = await txBuilder
                .spendingPlutusScriptV3()
                .txIn(
                    scriptInput!.input.txHash,
                    scriptInput!.input.outputIndex,
                    scriptInput!.output.amount,
                    scriptInput!.output.address
                )
                .txInInlineDatumPresent()
                .txInScript(faucetScriptCbor)
                .txInRedeemerValue(mConStr0([ownPubKey, accessTokenNameHex]))
                .txOut(
                    faucetScriptAddress, [
                        { unit: "lovelace", quantity: "2000000" },
                        { unit: faucetTokenPolicy + faucetTokenNameHex, quantity: remainingFaucetAmount.toString() },
                    ]
                )
                .txOutInlineDatumValue(mConStr0([withdrawalAmount, faucetTokenNameHex]))
                .txOut(
                    walletAddress, [
                        { unit: "lovelace", quantity: "2000000" },
                        { unit: faucetTokenPolicy + faucetTokenNameHex, quantity: withdrawalAmount.toString() },
                        { unit: accessTokenPolicy + accessTokenNameHex, quantity: "1" }
                    ]
                )
                .txOut(walletAddress, [
                    { unit: "lovelace", quantity: "5000000" },
                  ]) /// leave 5 ada for collateral
                .requiredSignerHash(ownPubKey)
                .complete();

            console.log("Transaction built successfully");
            const singedTx = await this.wallet.signTx(txHex);
            const txHash = await this.wallet.submitTx(singedTx);
            return {
                txHash
            }
        } catch (error) {
            console.error("Error in withdrawal transaction:", error);
            throw error;
        }
    };
  }