# Plutus Project Based Learning 
## Testing PPBL Faucet in Aiken
#### Docker & Yaci Devkit Setup
Install docker desktop for either Mac, Windows or Linux 
https://docs.docker.com/desktop/

Run the docker desktop appication to confirm that docker engine is able to start
![image](https://github.com/user-attachments/assets/474deceb-3c0d-48b0-bab7-b3b0b94514b3)

In a terminal window, download the yaci-devkit Github repo
```
$ git clone https://github.com/bloxbean/yaci-devkit.git
$ cd yaci-devkit
$ git checkout v0.10.0-preview5
```

Now run the following commands to start up the yaci devkit
```
$ ./bin/devkit.sh start
yaci-cli:>create-node -o --era conway
devnet:default>start
```
This will start up a local cardano node and devnet.  Wait for the ```Yaci Store Started``` to appear on the terminal


You can find out the API and URLs by using the ```info``` command
```
devnet:default>info

###### Node Details (Container) ######
[💡 Node port] 3001
[💡 Node Socket Paths] 
/clusters/nodes/default/node/node.sock
[💡 Submit Api Port] 8090
[💡 Protocol Magic] 42
[💡 Block Time] 1.0 sec
[💡 Slot Length] 1.0 sec
[💡 Start Time] 1738176728
[💡 Epoch Length] 600
[💡 Security Param] 300
[💡 SlotsPerKESPeriod] 129600


#################### URLS (Host) ####################
[💡 Yaci Viewer] http://localhost:5173
[💡 Yaci Store Swagger UI] http://localhost:8080/swagger-ui.html
[💡 Yaci Store Api URL] http://localhost:8080/api/v1/
[💡 Pool Id] pool1wvqhvyrgwch4jq9aa84hc8q4kzvyq2z3xr6mpafkqmx9wce39zy


#################### Other URLS ####################
[💡 Ogmios Url (Optional)] ws://localhost:1337
[💡 Kupo Url   (Optional)] http://localhost:1442


#################### Node Ports ####################
[💡 n2n port] localhost:3001
[💡 n2c port (socat)] localhost:3333
```
#### Aiken Setup
Install Aiken using the instructions 
https://aiken-lang.org/installation-instructions

Note: If you get the following error on Intel Mac, then you will need to compile aiken from the source code.
```
$ aiken check
    Compiling test/test-proj 0.0.0 (.)
    Compiling aiken-lang/stdlib v2.2.0 (./build/packages/aiken-lang-stdlib)
Illegal instruction (core dumped)

$ git clone https://github.com/aiken-lang/aiken.git
$ sudo apt install cargo
$ sudo apt install rustup
$ rustup default stable
$ sudo apt-get install libssl-dev pkg-config
$ RUSTFLAGS="-C target-cpu=native" cargo install aiken --version 1.1.9
$ cp ~/.cargo/bin/aiken ~/.aiken/bin
```

Confirm your aiken version
```
$ aiken --version
aiken aiken v1.1.9...
```

Now download the ppbl-faucet code
```
$ git clone https://github.com/gimbalabs/ppbl-2024-aiken-examples.git
$ cd ppbl-2024-aiken-examples/ppbl-faucet/
$ git checkout ppbl2025
```

First run the unit tests within validators/ppbl-faucet.ak
```
$ aiken check
    Compiling gimbalabs/ppbl-faucet 0.1.0 (.)
    Resolving gimbalabs/ppbl-faucet
      Fetched 2 packages in 0.06s from cache
    Compiling aiken-lang/stdlib v2.2.0 (./build/packages/aiken-lang-stdlib)
    Compiling sidan-lab/vodka 0.1.10 (./build/packages/sidan-lab-vodka)
      Testing ...

    ┍━ one_shot ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    │ PASS [mem: 110811, cpu:  46899539] success_mint
    │ PASS [mem: 111412, cpu:  47066562] fail_mint_without_param_name_minted
    ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 2 tests | 2 passed | 0 failed


    ┍━ ppbl_faucet ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    │ PASS [mem: 582944, cpu: 198153287] test_ppbl_faucet_success
    │ PASS [mem: 581173, cpu: 197696638] test_ppbl_faucet_fail_wrong_faucet_amount
    │ · with traces
    │ | faucet_output_to_sender ? False
    │ PASS [mem: 286493, cpu: 104927261] test_ppbl_faucet_fail_missing_access_token
    │ · with traces
    │ | no valid ppbl token found!
    │ PASS [mem: 404839, cpu: 143371255] test_ppbl_faucet_fail_invalid_access_token
    │ · with traces
    │ | no valid ppbl token found!
    │ PASS [mem: 551996, cpu: 190671997] test_ppbl_faucet_fail_invalid_faucet_token
    │ · with traces
    │ | faucet_output_to_sender ? False
    │ PASS [mem: 583576, cpu: 198308785] test_ppbl_faucet_fail_wrong_sender_pkh
    │ · with traces
    │ | output_to_pkh ? False
    ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 6 tests | 6 passed | 0 failed


      Summary 8 checks, 0 errors, 0 warnings

```

#### Install NPM and Node modules
```
$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
$ nvm use v22.13.0
$ npm intall
```

Notes: There will be some deprecated and security warnings that you can ignore for now since this only used for testing purposes.

Now run the faucet end-to-end integration test cases using the yaci devkit local devnet.
```
$ npm test
```

The tests should run successfully and you should see the following output
```
 PASS  test/faucet.test.ts (30.199 s)
  E2E Faucet Test
    ✓ Mint access token (3510 ms)
    ✓ Mint faucet tokens (3104 ms)
    ✓ Lock faucet tokens (3182 ms)
    ✓ Withdrawal Faucet Token (3175 ms)
    ✓ Withdrawal Faucet Token (3070 ms)
    ✓ Check Wallet Balance (18 ms)

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
Snapshots:   0 total
Time:        30.607 s
Ran all test suites.
```

In the terminal window runnign yaci devkit, you can query the utxos at and address using the following command
```
devnet:default>utxos addr_test1qz3y5kacdctuxzczarxu2t3c9jswawm4xtp3n26t6l9qelyh40hlltg24lyeuw9mk3e6p7fs58sv852zmp5suuk85s9qmzzvlm
1. 4ce6cf1d49c1108c980151e0ab793ecedab297a90aeeba478e61eb3a131e0c47#1 : [Amount(unit=lovelace, quantity=2000000), Amount(unit=b10b3a5a819392a156d0190ba4a5c34f1706bad47c8ed404dfe193e16163636573732d746f6b656e, quantity=1), Amount(unit=bb07253073ca06fb0b2704c41ad26a869ec303dd12f39d4409639a366661756365742d746f6b656e, quantity=100)]
--------------------------------------------------------------------------------------
2. 4ce6cf1d49c1108c980151e0ab793ecedab297a90aeeba478e61eb3a131e0c47#2 : [Amount(unit=lovelace, quantity=5000000)]
```

You can also go to the Yaci viewer http://localhost:5173/ and view the transactions as well.

![image](https://github.com/user-attachments/assets/871ee952-9945-4d79-9ad3-ad569252a911)

![image](https://github.com/user-attachments/assets/9c6c96e5-ae4b-4a92-8a81-54c97d47387f)


