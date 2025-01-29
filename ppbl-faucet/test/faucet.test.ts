import { describe, expect, it } from '@jest/globals';
import { 
    //MeshTx,
    newWallet,
    provider,
    sleep
} from "./offchain";

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
const wallet = newWallet(seed);
*/

const wallet = newWallet();
const networkId = 0; // set to 0 for testnet, 1 for mainnet


describe('E2E Faucet Test', () => {
    console.log("Starting E2E Faucet Test");

    beforeAll(async () => {
const address = wallet.getChangeAddress();
        console.log("Wallet Address:", address);
        await provider.addressTopup(address, "200_000") 
        await sleep(2);
    });

    afterAll(async () => {
        //await teardown();
        console.log("Counter Test Finished");
    }); 


    it('mint access token', async() => {
        console.log('\n--- Before Mint Tx ---');
        //const tx = new MeshTx(wallet, provider, networkId);
        //const txHash = await tx.mint(tokenName, quantity);
        console.log('\n--- After Mint Tx ---');
        //console.log({ txHash });
        //await sleep(2);
    }, 100000);

}); 

