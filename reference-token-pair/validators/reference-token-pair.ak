use aiken/builtin.{append_bytearray}
use aiken/collection/list
use cardano/address.{Address}
use cardano/assets.{AssetName, PolicyId, add, from_asset, quantity_of}
use cardano/transaction.{InlineDatum, Input, OutputReference, Transaction} as tx
use mocktail.{
  complete, mocktail_tx, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use mocktail/virgin_address.{mock_pub_key_address, mock_script_address}
use mocktail/virgin_key_hash.{mock_policy_id}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

// Todo
// Create a related minting validator

pub type ReferenceTokenDatum {
  image_url: ByteArray,
  description: ByteArray,
}

pub type ReferenceTokenRedeemer {
  new_image_url: ByteArray,
  new_description: ByteArray,
  token_name: ByteArray,
}

validator reference_token_pair(reference_token_symbol: PolicyId) {
  spend(
    _datum: Option<ReferenceTokenDatum>,
    redeemer: ReferenceTokenRedeemer,
    oref: OutputReference,
    tx: Transaction,
  ) {
    let ReferenceTokenRedeemer { new_image_url, new_description, token_name } =
      redeemer
    let Transaction { inputs, outputs, .. } = tx

    let tn100: AssetName = append_bytearray("100", token_name)
    let tn222: AssetName = append_bytearray("222", token_name)

    when list.filter(inputs, fn(input) { input.output_reference == oref }) is {
      [reference_token_input] ->
        when
          (
            list.filter(
              outputs,
              fn(output) {
                output.address == reference_token_input.output.address
              },
            ),
            list.filter(
              inputs,
              fn(input) {
                quantity_of(input.output.value, reference_token_symbol, tn222) == 1
              },
            ),
            list.filter(
              outputs,
              fn(output) {
                quantity_of(output.value, reference_token_symbol, tn222) == 1
              },
            ),
          )
        is {
          ([reference_token_output], [owner_token_input], [owner_token_output]) ->
            when reference_token_output.datum is {
              InlineDatum(ref_output_datum) -> {
                expect reference_token_datum: ReferenceTokenDatum =
                  ref_output_datum
                and {
                  reference_token_datum.image_url == new_image_url,
                  reference_token_datum.description == new_description,
                  quantity_of(
                    reference_token_input.output.value,
                    reference_token_symbol,
                    tn100,
                  ) == 1,
                  quantity_of(
                    reference_token_output.value,
                    reference_token_symbol,
                    tn100,
                  ) == 1,
                  owner_token_input.output.address == owner_token_output.address,
                }
              }
              _ -> False
            }
          _ -> False
        }
      _ -> False
    }
  }

  else(_) {
    fail
  }
}

fn mock_tx(
  old_datum: ReferenceTokenDatum,
  new_datum: ReferenceTokenDatum,
  redeemer: ReferenceTokenRedeemer,
  wallet_address: Address,
  script_address: Address,
  reference_token_symbol: PolicyId,
) -> Transaction {
  let tn100: AssetName = append_bytearray("100", redeemer.token_name)
  let tn222: AssetName = append_bytearray("222", redeemer.token_name)

  let reference_token_value =
    from_asset(reference_token_symbol, tn100, 1)
      |> add("", "", 2_000_000)
  let owner_token_value =
    from_asset(reference_token_symbol, tn222, 1)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, owner_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, reference_token_value, script_address)
    |> tx_in_inline_datum(True, old_datum)
    |> tx_out(True, wallet_address, owner_token_value)
    |> tx_out(True, script_address, reference_token_value)
    |> tx_out_inline_datum(True, new_datum)
    |> complete()
}

test test_reference_token_pair_success() {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let reference_token_symbol = mock_policy_id(2)
  let old_datum =
    ReferenceTokenDatum { image_url: "image_url", description: "description" }
  let new_datum =
    ReferenceTokenDatum {
      image_url: "new_image_url",
      description: "new_description",
    }
  let redeemer =
    ReferenceTokenRedeemer {
      new_image_url: "new_image_url",
      new_description: "new_description",
      token_name: "token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx(
      old_datum,
      new_datum,
      redeemer,
      wallet_address,
      script_address,
      reference_token_symbol,
    )

  reference_token_pair.spend(
    reference_token_symbol,
    Some(old_datum),
    redeemer,
    output_reference,
    tx,
  )
}

fn mock_tx_no_owner_token(
  old_datum: ReferenceTokenDatum,
  new_datum: ReferenceTokenDatum,
  redeemer: ReferenceTokenRedeemer,
  wallet_address: Address,
  script_address: Address,
  reference_token_symbol: PolicyId,
) -> Transaction {
  let tn100: AssetName = append_bytearray("100", redeemer.token_name)

  let reference_token_value =
    from_asset(reference_token_symbol, tn100, 1)
      |> add("", "", 2_000_000)
  // no owner token
  let owner_token_value = from_asset("", "", 2_000_000)
  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, owner_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, reference_token_value, script_address)
    |> tx_in_inline_datum(True, old_datum)
    |> tx_out(True, wallet_address, owner_token_value)
    |> tx_out(True, script_address, reference_token_value)
    |> tx_out_inline_datum(True, new_datum)
    |> complete()
}

test test_reference_token_pair_no_owner_token() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let reference_token_symbol = mock_policy_id(2)
  let old_datum =
    ReferenceTokenDatum { image_url: "image_url", description: "description" }
  let new_datum =
    ReferenceTokenDatum {
      image_url: "new_image_url",
      description: "new_description",
    }
  let redeemer =
    ReferenceTokenRedeemer {
      new_image_url: "new_image_url",
      new_description: "new_description",
      token_name: "token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx_no_owner_token(
      old_datum,
      new_datum,
      redeemer,
      wallet_address,
      script_address,
      reference_token_symbol,
    )

  reference_token_pair.spend(
    reference_token_symbol,
    Some(old_datum),
    redeemer,
    output_reference,
    tx,
  )
}

test test_reference_token_pair_invalid_datum() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let reference_token_symbol = mock_policy_id(2)
  let old_datum =
    ReferenceTokenDatum { image_url: "image_url", description: "description" }
  // invalid datum
  let new_datum =
    ReferenceTokenDatum { image_url: "image_url", description: "description" }
  let redeemer =
    ReferenceTokenRedeemer {
      new_image_url: "new_image_url",
      new_description: "new_description",
      token_name: "token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx(
      old_datum,
      new_datum,
      redeemer,
      wallet_address,
      script_address,
      reference_token_symbol,
    )

  reference_token_pair.spend(
    reference_token_symbol,
    Some(old_datum),
    redeemer,
    output_reference,
    tx,
  )
}
