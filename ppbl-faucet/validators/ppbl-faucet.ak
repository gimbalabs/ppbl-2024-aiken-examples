use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Address, VerificationKey}
use cardano/assets.{PolicyId, add, from_asset, merge, quantity_of}
use cardano/transaction.{OutputReference, Transaction}
use mocktail.{
  complete, mocktail_tx, required_signer_hash, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}
use mocktail/virgin_address.{mock_pub_key_address, mock_script_address}
use mocktail/virgin_key_hash.{mock_policy_id, mock_pub_key_hash}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

/// The datum
pub type FaucetDatum {
  withdrawal_amount: Int,
  faucet_token_name: ByteArray,
}

/// The redeemer
pub type FaucetRedeemer {
  sender_pkh: VerificationKeyHash,
  // Just a ByteArray
  access_token_name: ByteArray,
}

validator ppbl_faucet(
  access_token_symbol: PolicyId,
  faucet_token_symbol: PolicyId,
) {
  spend(
    datum_opt: Option<FaucetDatum>,
    redeemer: FaucetRedeemer,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(FaucetDatum { withdrawal_amount, faucet_token_name }) =
      datum_opt
    let FaucetRedeemer { sender_pkh, access_token_name } = redeemer
    let Transaction { inputs, outputs, .. } = tx

    expect [faucet_input] =
      list.filter(inputs, fn(input) { input.output_reference == oref })

    expect [faucet_output] =
      list.filter(
        outputs,
        fn(output) { output.address == faucet_input.output.address },
      )

    let ppbl_token_input_opt =
      list.find(
        inputs,
        fn(input) {
          quantity_of(
            input.output.value,
            access_token_symbol,
            access_token_name,
          ) == 1
        },
      )

    when ppbl_token_input_opt is {
      Some(ppbl_token_input) -> {
        expect [ppbl_token_output] =
          list.filter(
            outputs,
            fn(output) {
              quantity_of(output.value, access_token_symbol, access_token_name) == 1
            },
          )

        let must_send_token_to_sender =
          ppbl_token_input.output.address == ppbl_token_output.address

        let faucet_output_to_sender =
          quantity_of(
            ppbl_token_output.value,
            faucet_token_symbol,
            faucet_token_name,
          ) == withdrawal_amount

        let faucet_tokens_from_input =
          quantity_of(
            faucet_input.output.value,
            faucet_token_symbol,
            faucet_token_name,
          )
        let faucet_tokens_in_output =
          quantity_of(faucet_output.value, faucet_token_symbol, faucet_token_name)

        expect VerificationKey(output_key_hash) =
          ppbl_token_output.address.payment_credential

        let output_to_pkh = output_key_hash == sender_pkh
        let faucet_gets_remaining_tokens =
          faucet_tokens_from_input == faucet_tokens_in_output + withdrawal_amount

        and {
          (faucet_input.output.datum == faucet_output.datum)?,
          must_send_token_to_sender?,
          faucet_output_to_sender?,
          faucet_gets_remaining_tokens?,
          output_to_pkh?,
        }
      }
      None -> {
        trace @"no valid ppbl token found!"
        False
      }
    }
  }

  else(_) {
    trace @"tx purpose not supported"
    fail
  }
}

fn mock_tx(
  is_owner_signed: Bool,
  datum: FaucetDatum,
  redeemer: FaucetRedeemer,
  wallet_address: Address,
  script_address: Address,
  access_token_symbol: PolicyId,
  faucet_token_symbol: PolicyId,
) -> Transaction {
  let access_token_value =
    from_asset(access_token_symbol, redeemer.access_token_name, 1)
      |> add("", "", 2_000_000)
  let faucet_token_value_input =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 1000)
      |> add("", "", 2_000_000)
  let faucet_token_value_output =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 100)
  let faucet_token_value_remaining =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 900)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, access_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, faucet_token_value_input, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(
        True,
        wallet_address,
        merge(access_token_value, faucet_token_value_output),
      )
    |> tx_out(True, script_address, faucet_token_value_remaining)
    |> tx_out_inline_datum(True, datum)
    |> required_signer_hash(is_owner_signed, redeemer.sender_pkh)
    |> complete()
}

test test_ppbl_faucet_success() {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let access_token_symbol = mock_policy_id(0)
  let faucet_token_symbol = mock_policy_id(1)
  let datum =
    FaucetDatum {
      withdrawal_amount: 100,
      faucet_token_name: "faucet_token_name",
    }
  let redeemer =
    FaucetRedeemer {
      sender_pkh: mock_pub_key_hash(0),
      access_token_name: "access_token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx(
      True,
      datum,
      redeemer,
      wallet_address,
      script_address,
      access_token_symbol,
      faucet_token_symbol,
    )

  ppbl_faucet.spend(
    access_token_symbol,
    faucet_token_symbol,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}


fn mock_tx_wrong_faucet_amount(
  is_owner_signed: Bool,
  datum: FaucetDatum,
  redeemer: FaucetRedeemer,
  wallet_address: Address,
  script_address: Address,
  access_token_symbol: PolicyId,
  faucet_token_symbol: PolicyId,
) -> Transaction {
  let access_token_value =
    from_asset(access_token_symbol, redeemer.access_token_name, 1)
      |> add("", "", 2_000_000)
  let faucet_token_value_input =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 1000)
      |> add("", "", 2_000_000)
  let faucet_token_value_output =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 500)
  let faucet_token_value_remaining =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 500)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, access_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, faucet_token_value_input, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(
        True,
        wallet_address,
        merge(access_token_value, faucet_token_value_output),
      )
    |> tx_out(True, script_address, faucet_token_value_remaining)
    |> tx_out_inline_datum(True, datum)
    |> required_signer_hash(is_owner_signed, redeemer.sender_pkh)
    |> complete()
}

test test_ppbl_faucet_fail_wrong_faucet_amount() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let access_token_symbol = mock_policy_id(0)
  let faucet_token_symbol = mock_policy_id(1)
  let datum =
    FaucetDatum {
      withdrawal_amount: 100,
      faucet_token_name: "faucet_token_name",
    }
  let redeemer =
    FaucetRedeemer {
      sender_pkh: mock_pub_key_hash(0),
      access_token_name: "access_token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx_wrong_faucet_amount(
      True,
      datum,
      redeemer,
      wallet_address,
      script_address,
      access_token_symbol,
      faucet_token_symbol,
    )

  ppbl_faucet.spend(
    access_token_symbol,
    faucet_token_symbol,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}

fn mock_tx_missing_access_token(
  is_owner_signed: Bool,
  datum: FaucetDatum,
  redeemer: FaucetRedeemer,
  wallet_address: Address,
  script_address: Address,
  faucet_token_symbol: PolicyId,
) -> Transaction {
  let faucet_token_value_input =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 1000)
      |> add("", "", 2_000_000)
  let faucet_token_value_output =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 100)
  let faucet_token_value_remaining =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 900)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(1), 0, faucet_token_value_input, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(
        True,
        wallet_address,
        faucet_token_value_output,
      )
    |> tx_out(True, script_address, faucet_token_value_remaining)
    |> tx_out_inline_datum(True, datum)
    |> required_signer_hash(is_owner_signed, redeemer.sender_pkh)
    |> complete()
}

test test_ppbl_faucet_fail_missing_access_token() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let access_token_symbol = mock_policy_id(0)
  let faucet_token_symbol = mock_policy_id(1)
  let datum =
    FaucetDatum {
      withdrawal_amount: 100,
      faucet_token_name: "faucet_token_name",
    }
  let redeemer =
    FaucetRedeemer {
      sender_pkh: mock_pub_key_hash(0),
      access_token_name: "access_token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx_missing_access_token(
      True,
      datum,
      redeemer,
      wallet_address,
      script_address,
      faucet_token_symbol,
    )

    ppbl_faucet.spend(
      access_token_symbol,
      faucet_token_symbol,
      Some(datum),
      redeemer,
      output_reference,
      tx,
    )
}


fn mock_tx_invalid_access_token(
  is_owner_signed: Bool,
  datum: FaucetDatum,
  redeemer: FaucetRedeemer,
  wallet_address: Address,
  script_address: Address,
  access_token_symbol: PolicyId,
  faucet_token_symbol: PolicyId,
) -> Transaction {
  let access_token_value =
    from_asset(access_token_symbol, redeemer.access_token_name, 1)
      |> add("", "", 2_000_000)
  let faucet_token_value_input =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 1000)
      |> add("", "", 2_000_000)
  let faucet_token_value_output =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 100)
  let faucet_token_value_remaining =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 900)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, access_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, faucet_token_value_input, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(
        True,
        wallet_address,
        merge(access_token_value, faucet_token_value_output),
      )
    |> tx_out(True, script_address, faucet_token_value_remaining)
    |> tx_out_inline_datum(True, datum)
    |> required_signer_hash(is_owner_signed, redeemer.sender_pkh)
    |> complete()
}

test test_ppbl_faucet_fail_invalid_access_token() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let access_token_symbol = mock_policy_id(0)
  let invalid_access_token_symbol = mock_policy_id(99)
  let faucet_token_symbol = mock_policy_id(1)
  let datum =
    FaucetDatum {
      withdrawal_amount: 100,
      faucet_token_name: "faucet_token_name",
    }
  let redeemer =
    FaucetRedeemer {
      sender_pkh: mock_pub_key_hash(0),
      access_token_name: "access_token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx_invalid_access_token(
      True,
      datum,
      redeemer,
      wallet_address,
      script_address,
      invalid_access_token_symbol,
      faucet_token_symbol,
    )

  ppbl_faucet.spend(
    access_token_symbol,
    faucet_token_symbol,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}


fn mock_tx_invalid_faucet_token(
  is_owner_signed: Bool,
  datum: FaucetDatum,
  redeemer: FaucetRedeemer,
  wallet_address: Address,
  script_address: Address,
  access_token_symbol: PolicyId,
  faucet_token_symbol: PolicyId,
) -> Transaction {
  let access_token_value =
    from_asset(access_token_symbol, redeemer.access_token_name, 1)
      |> add("", "", 2_000_000)
  let faucet_token_value_input =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 1000)
      |> add("", "", 2_000_000)
  let faucet_token_value_output =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 100)
  let faucet_token_value_remaining =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 900)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, access_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, faucet_token_value_input, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(
        True,
        wallet_address,
        merge(access_token_value, faucet_token_value_output),
      )
    |> tx_out(True, script_address, faucet_token_value_remaining)
    |> tx_out_inline_datum(True, datum)
    |> required_signer_hash(is_owner_signed, redeemer.sender_pkh)
    |> complete()
}

test test_ppbl_faucet_fail_invalid_faucet_token() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let access_token_symbol = mock_policy_id(0)
  let faucet_token_symbol = mock_policy_id(1)
  let invalid_faucet_token_symbol = mock_policy_id(98)
  let datum =
    FaucetDatum {
      withdrawal_amount: 100,
      faucet_token_name: "faucet_token_name",
    }
  let redeemer =
    FaucetRedeemer {
      sender_pkh: mock_pub_key_hash(0),
      access_token_name: "access_token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx_invalid_faucet_token(
      True,
      datum,
      redeemer,
      wallet_address,
      script_address,
      access_token_symbol,
      invalid_faucet_token_symbol,
    )

  ppbl_faucet.spend(
    access_token_symbol,
    faucet_token_symbol,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}


fn mock_tx_wrong_sender_pkh(
  is_owner_signed: Bool,
  datum: FaucetDatum,
  redeemer: FaucetRedeemer,
  wallet_address: Address,
  script_address: Address,
  access_token_symbol: PolicyId,
  faucet_token_symbol: PolicyId,
) -> Transaction {
  let access_token_value =
    from_asset(access_token_symbol, redeemer.access_token_name, 1)
      |> add("", "", 2_000_000)
  let faucet_token_value_input =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 1000)
      |> add("", "", 2_000_000)
  let faucet_token_value_output =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 100)
  let faucet_token_value_remaining =
    from_asset(faucet_token_symbol, datum.faucet_token_name, 900)
      |> add("", "", 2_000_000)

  mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, access_token_value, wallet_address)
    |> tx_in(True, mock_tx_hash(1), 0, faucet_token_value_input, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(
        True,
        wallet_address,
        merge(access_token_value, faucet_token_value_output),
      )
    |> tx_out(True, script_address, faucet_token_value_remaining)
    |> tx_out_inline_datum(True, datum)
    |> required_signer_hash(is_owner_signed, redeemer.sender_pkh)
    |> complete()
}

test test_ppbl_faucet_fail_wrong_sender_pkh() fail {
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let access_token_symbol = mock_policy_id(0)
  let faucet_token_symbol = mock_policy_id(1)
  let datum =
    FaucetDatum {
      withdrawal_amount: 100,
      faucet_token_name: "faucet_token_name",
    }
  let redeemer =
    FaucetRedeemer {
      sender_pkh: mock_pub_key_hash(97),
      access_token_name: "access_token_name",
    }
  let output_reference = mock_utxo_ref(1, 0)
  let tx =
    mock_tx_wrong_sender_pkh(
      True,
      datum,
      redeemer,
      wallet_address,
      script_address,
      access_token_symbol,
      faucet_token_symbol,
    )

  ppbl_faucet.spend(
    access_token_symbol,
    faucet_token_symbol,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}
