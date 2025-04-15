use aiken/collection/dict
use aiken/collection/list
use cardano/assets.{PolicyId, zero}
use cardano/transaction.{Input, OutputReference, Transaction} as tx
use mocktail.{complete, mint, mocktail_tx, tx_in}
use mocktail/virgin_address.{mock_pub_key_address}
use mocktail/virgin_key_hash.{mock_policy_id}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

pub type Action {
  Mint
  Burn
}

validator one_shot(token_name: ByteArray, utxo_ref: OutputReference) {
  mint(rdmr: Action, policy_id: PolicyId, tx: Transaction) {
    let Transaction { inputs, mint, .. } = tx
    expect [Pair(asset_name, amount)] =
      mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()
    when rdmr is {
      Mint -> {
        expect Some(_input) =
          list.find(inputs, fn(input) { input.output_reference == utxo_ref })
        asset_name == token_name && amount >= 1
      }
      Burn -> asset_name == token_name && amount <= -1
    }
  }

  else(_) {
    fail
  }
}

type TestCase {
  is_mint_info_correct: Bool,
  is_token_name_correct: Bool,
}

fn get_mint_test_tx(test_case: TestCase) -> Transaction {
  let TestCase { is_mint_info_correct, is_token_name_correct } = test_case

  let token_name =
    if is_token_name_correct {
      "hello world"
    } else {
      "goodbye"
    }

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, zero, mock_pub_key_address(0, None))
    |> mint(is_mint_info_correct, 1, mock_policy_id(0), token_name)
    |> mint(!is_mint_info_correct, 2, mock_policy_id(0), token_name)
    |> complete()
}

test success_mint() {
  let test_one_shot_name = "hello world"
  let utxo = mock_utxo_ref(0, 0)
  let test_case =
    TestCase { is_mint_info_correct: True, is_token_name_correct: True }
  let tx = get_mint_test_tx(test_case)
  one_shot.mint(test_one_shot_name, utxo, Mint, mock_policy_id(0), tx)
}

test fail_mint_without_param_name_minted() {
  let test_one_shot_name = "hello world"
  let utxo = mock_utxo_ref(0, 0)
  let test_case =
    TestCase { is_mint_info_correct: True, is_token_name_correct: False }
  let tx = get_mint_test_tx(test_case)
  !one_shot.mint(test_one_shot_name, utxo, Mint, mock_policy_id(0), tx)
}
