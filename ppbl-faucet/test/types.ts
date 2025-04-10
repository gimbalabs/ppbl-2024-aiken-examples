import {
  ByteString,
  ConStr0,
  ConStr1,
  Integer,
  MintingBlueprint,
  OutputReference,
  PolicyId,
  PubKeyHash,
  SpendingBlueprint,
} from "@meshsdk/core";

import blueprint from "./plutus.json";

export const version = "V3";
export const networkId = 0; // 0 for testnet; 1 for mainnet
// Every spending validator would compile into an address with an staking key hash
// Recommend replace with your own stake key / script hash
export const stakeKeyHash = "";
export const isStakeScriptCredential = false;

export class OneShotMintBlueprint extends MintingBlueprint {
  compiledCode: string;

  constructor(params: [ByteString, OutputReference]) {
    const compiledCode = blueprint.validators[0]!.compiledCode;
    super(version);
    this.compiledCode = compiledCode;
    this.paramScript(compiledCode, params, "JSON");
  }

  param = (
    data: [ByteString, OutputReference]
  ): [ByteString, OutputReference] => data;
}

export class PpblFaucetSpendBlueprint extends SpendingBlueprint {
  compiledCode: string;

  constructor(params: [PolicyId, PolicyId]) {
    const compiledCode = blueprint.validators[2]!.compiledCode;
    super(version, networkId, stakeKeyHash, isStakeScriptCredential);
    this.compiledCode = compiledCode;
    this.paramScript(compiledCode, params, "JSON");
  }

  params = (data: [PolicyId, PolicyId]): [PolicyId, PolicyId] => data;
  datum = (data: FaucetDatum): FaucetDatum => data;
  redeemer = (data: FaucetRedeemer): FaucetRedeemer => data;
}

export type Action = Mint | Burn;

export type Mint = ConStr0<[]>;

export type Burn = ConStr1<[]>;

export type FaucetRedeemer = ConStr0<[PubKeyHash, ByteString]>;

export type FaucetDatum = ConStr0<[Integer, ByteString]>;
