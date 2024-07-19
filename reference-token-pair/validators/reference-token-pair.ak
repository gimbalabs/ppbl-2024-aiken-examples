use aiken/bytearray.{concat}
use aiken/list
use aiken/transaction.{ScriptContext, Transaction} as tx
use aiken/transaction/value

// Todo
// Create a related minting validator

type ReferenceTokenDatum {
  image_url: ByteArray,
  description: ByteArray,
}

type ReferenceTokenRedeemer {
  // How to index constructor values?
  new_image_url: ByteArray,
  new_description: ByteArray,
  token_name: ByteArray,
}

validator(reference_token_symbol: value.PolicyId) {
  fn reference_token_pair(
    datum: ReferenceTokenDatum,
    redeemer: ReferenceTokenRedeemer,
    context: ScriptContext,
  ) -> Bool {
    let ReferenceTokenDatum { image_url, description } = datum
    let ReferenceTokenRedeemer { new_image_url, new_description, token_name } =
      redeemer
    let ScriptContext { transaction, purpose } = context
    expect tx.Spend(utxo_ref) = purpose
    let Transaction { inputs, outputs, .. } = transaction

    let tn100 = concat("100", token_name)
    let tn222 = concat("222", token_name)

    expect [reference_token_input] =
      list.filter(inputs, fn(input) { input.output_reference == utxo_ref })

    expect [reference_token_output] =
      list.filter(
        outputs,
        fn(output) { output.address == reference_token_input.output.address },
      )

    expect [owner_token_input] =
      list.filter(
        inputs,
        fn(input) {
          value.quantity_of(input.output.value, reference_token_symbol, tn222) == 1
        },
      )

    expect [owner_token_output] =
      list.filter(
        outputs,
        fn(output) {
          value.quantity_of(output.value, reference_token_symbol, tn222) == 1
        },
      )

    and {
      image_url == new_image_url,
      description == new_description,
      value.quantity_of(
        reference_token_input.output.value,
        reference_token_symbol,
        tn100,
      ) == 1,
      value.quantity_of(
        reference_token_output.value,
        reference_token_symbol,
        tn100,
      ) == 1,
      owner_token_input.output.address == owner_token_output.address,
    }
  }
}
