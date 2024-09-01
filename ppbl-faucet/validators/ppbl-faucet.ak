use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext, Transaction} as tx
use aiken/transaction/credential.{VerificationKey, VerificationKeyCredential}
use aiken/transaction/value

/// The datum
type FaucetDatum {
  withdrawal_amount: Int,
  faucet_token_name: ByteArray,
}

/// The redeemer
type FaucetRedeemer {
  sender_pkh: Hash<Blake2b_224, VerificationKey>,
  // Just a ByteArray
  access_token_name: ByteArray,
}

validator(
  access_token_symbol: value.PolicyId,
  faucet_token_symbol: value.PolicyId,
) {
  fn ppbl_faucet(
    datum: FaucetDatum,
    redeemer: FaucetRedeemer,
    context: ScriptContext,
  ) -> Bool {
    let FaucetDatum { withdrawal_amount, faucet_token_name } = datum

    let FaucetRedeemer { sender_pkh, access_token_name } = redeemer

    let ScriptContext { transaction, purpose } = context

    expect tx.Spend(utxo_ref) = purpose

    let Transaction { inputs, outputs, .. } = transaction

    expect [faucet_input] =
      list.filter(inputs, fn(input) { input.output_reference == utxo_ref })

    expect [faucet_output] =
      list.filter(
        outputs,
        fn(output) { output.address == faucet_input.output.address },
      )

    expect [ppbl_token_input] =
      list.filter(
        inputs,
        fn(input) {
          value.quantity_of(
            input.output.value,
            access_token_symbol,
            access_token_name,
          ) == 1
        },
      )

    expect [ppbl_token_output] =
      list.filter(
        outputs,
        fn(output) {
          value.quantity_of(
            output.value,
            access_token_symbol,
            access_token_name,
          ) == 1
        },
      )

    let must_send_token_to_sender =
      ppbl_token_input.output.address == ppbl_token_output.address

    let faucet_output_to_sender =
      value.quantity_of(
        ppbl_token_output.value,
        faucet_token_symbol,
        faucet_token_name,
      ) == withdrawal_amount

    let faucet_tokens_from_input =
      value.quantity_of(
        faucet_input.output.value,
        faucet_token_symbol,
        faucet_token_name,
      )
    let faucet_tokens_in_output =
      value.quantity_of(
        faucet_output.value,
        faucet_token_symbol,
        faucet_token_name,
      )

    expect VerificationKeyCredential(output_cred) =
      ppbl_token_output.address.payment_credential

    let output_to_pkh = output_cred == sender_pkh

    let faucet_gets_remaining_tokens =
      faucet_tokens_from_input == faucet_tokens_in_output + withdrawal_amount

    and {
      faucet_input.output.datum == faucet_output.datum,
      must_send_token_to_sender,
      faucet_output_to_sender,
      faucet_gets_remaining_tokens,
      output_to_pkh,
    }
  }
}
// type TestCase {
//   is_faucet_datum_correct: Bool,
//   must_send_token_to_sender: Bool,
//   faucet_output_to_sender: Bool,
//   faucet_gets_remaining_tokens: Bool,
//   output_to_pkh: Bool,
// }

// fn get_test_tx(test_case: TestCase) -> Transaction {
//   Transaction { ..placeholder() }
// }

// test success() {
//   let output_reference = mock_utxo_ref(0, 1)
//   let mock_datum =
//     FaucetDatum {
//       withdrawal_amount: 100,
//       faucet_token_name: "faucet_token_name",
//     }
//   let redeemer =
//     FaucetRedeemer { sender_pkh: "", access_token_name: "access_token_name" }
//   let test_case =
//     TestCase {
//       is_faucet_datum_correct: True,
//       must_send_token_to_sender: True,
//       faucet_output_to_sender: True,
//       faucet_gets_remaining_tokens: True,
//       output_to_pkh: True,
//     }

//   let tx = get_cancel_test_tx(test_case)
//   let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
//   escrow_logic(unused_mock_datum, redeemer, ctx)
// }
