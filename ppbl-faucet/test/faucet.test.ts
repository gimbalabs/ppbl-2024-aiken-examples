import { describe, expect, it } from "@jest/globals";
import { MeshTx, newWallet, provider } from "./offchain";
import { MeshWallet } from "@meshsdk/core";

import { networkId } from "./types";

/*
const seed = [
    'rally',      'tape',     'wrestle',
    'enroll',     'alter',    'orange',
    'isolate',    'genuine',  'lunar',
    'february',   'island',   'curve',
    'jealous',    'stay',     'search',
    'session',    'grid',     'inside',
    'present',    'recall',   'lava',
    'often',      'above',    'rubber',
]
*/

let wallet: MeshWallet;

describe("E2E Faucet Test", () => {
  console.log("Starting E2E Faucet Test");
  let accessTokenHex: string;
  let accessTokenPolicy: string;
  let faucetTokenHex: string;
  let faucetTokenPolicy: string;
  const withdrawalAmount = 100n;
  const faucetLockedAmount = 1000000n;

  beforeAll(async () => {
    wallet = await newWallet();
    //wallet = newWallet(seed);
    const address = await wallet.getChangeAddress();
    console.log("Wallet Address:", address);
    await provider.addressTopup(address, "200_000");
    await provider.addressTopup(address, "5_000");
    await sleep(2);
  },100000);

  afterAll(async () => {
    console.log("Counter Test Finished");
  });

  it("Mint access token", async () => {
    console.log("\n--- Before Mint Access Token Tx ---");
    const tx = new MeshTx(wallet, provider, networkId);
    const result = await tx.mint("access-token", 1n);
    console.log("\n--- After Mint Access Token Tx ---");
    console.log({ result });
    accessTokenHex = result.tokenNameHex;
    accessTokenPolicy = result.mintingPolicy;
    await sleep(2);
  }, 100000);

  it("Mint faucet tokens", async () => {
    console.log("\n--- Before Mint Faucet Token Tx ---");
    const tx = new MeshTx(wallet, provider, networkId);
    const result = await tx.mint("faucet-token", 1000000n);
    console.log("\n--- After Mint Faucet Token Tx ---");
    console.log({ result });
    faucetTokenHex = result.tokenNameHex;
    faucetTokenPolicy = result.mintingPolicy;
    await sleep(2);
  }, 100000);

  it("Lock faucet tokens", async () => {
    console.log("\n--- Before Lock Faucet Token Tx ---");
    const tx = new MeshTx(wallet, provider, networkId);
    const result = await tx.lock(
      withdrawalAmount,
      faucetLockedAmount,
      faucetTokenHex,
      faucetTokenPolicy,
      accessTokenPolicy
    );
    console.log("\n--- After Lock Faucet Token Tx ---");
    console.log({ result });
    await sleep(2);
  }, 100000);

  it("Withdrawal Faucet Token", async () => {
    console.log("\n--- Before Withdrawal Faucet Token Tx ---");
    const tx = new MeshTx(wallet, provider, networkId);
    const result = await tx.withdrawal(
      withdrawalAmount,
      faucetTokenHex,
      faucetTokenPolicy,
      accessTokenHex,
      accessTokenPolicy
    );
    console.log("\n--- After Withdrawal Faucet Token Tx ---");
    console.log({ result });
    await sleep(2);
  }, 100000);

  it("Withdrawal Faucet Token", async () => {
    console.log("\n--- Before Withdrawal Faucet Token Tx ---");
    const tx = new MeshTx(wallet, provider, networkId);
    const result = await tx.withdrawal(
      withdrawalAmount,
      faucetTokenHex,
      faucetTokenPolicy,
      accessTokenHex,
      accessTokenPolicy
    );
    console.log("\n--- After Withdrawal Faucet Token Tx ---");
    console.log({ result });
    await sleep(2);
  }, 100000);

  it("Check Wallet Balance", async () => {
    const balance = await wallet.getBalance();
    console.log({ balance });
    expect(
      balance.find((b) => b.unit === faucetTokenPolicy + faucetTokenHex)
        ?.quantity
    ).toBe("200");
    expect(
      balance.find((b) => b.unit === accessTokenPolicy + accessTokenHex)
        ?.quantity
    ).toBe("1");
  });
});

const sleep = (second: number) =>
  new Promise((resolve) => setTimeout(resolve, second * 1000));
