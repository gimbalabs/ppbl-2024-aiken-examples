import {
    applyCborEncoding,
    applyParamsToScript,
    fromLovelace,
    parseDatumCbor
} from "@meshsdk/core-csl";
import {
    AppWalletKeyType,
    BlockfrostProvider,
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
    PubKeyHash,
    Integer,
    ConStr0,
} from "@meshsdk/core";


import blueprint from "../plutus.json";
const languageVersion = "V3";

//const apiKey = process.env.BLOCKFROST_KEY as string;
//        if (!apiKey) {
//            throw console.error("BLOCKFROST_KEY not set");
//        }
//export const provider = new BlockfrostProvider(apiKey);
export const provider = new YaciProvider('http://localhost:8080/api/v1', 'http://localhost:10000');

export const newWallet = (providedMnemonic?: string[]) => {
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

  return wallet;
};

export const sleep = (seconds: number) => {
    return new Promise(resolve => setTimeout(resolve, seconds * 1000));
}; 