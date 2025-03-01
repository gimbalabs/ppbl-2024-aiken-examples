use aiken/interval.{Finite}
use cardano/address.{Address}
use cardano/assets.{from_lovelace}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx
use mocktail.{
  complete, invalid_before, mocktail_tx, tx_in, tx_in_inline_datum, tx_out,
}
use mocktail/virgin_address.{mock_pub_key_address, mock_script_address}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

// introduce-traces.ak
// unlock utxo after a certain time

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

// SLT 205.4: I can use traces to diagnose validation errors.
// Datum and Redeemer must match - but which error is stopping validation?

validator introduce_traces_with_datum_and_redeemer {
  spend(
    datum: Option<Int>,
    redeemer: Option<Int>,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { validity_range, .. } = tx

    // Change this number:
    let lock_until = 1730301165000

    // Learn more about traces:
    // https://aiken-lang.org/language-tour/troubleshooting#traces
    // Note that traces are removed by default with aiken build. Instead, use:
    // aiken build --trace-level verbose
    // Try this:
    // 1. Note that addresses are different with or without --trace-level verbose
    // 2. How much does it impact minUTxO to include --trace-level verbose
    (datum == redeemer)? && must_start_after(validity_range, lock_until)?
  }

  else(_) {
    fail
  }
}

fn must_start_after(range: ValidityRange, lock_expiration_time: Int) -> Bool {
  expect Finite(tx_earliest_time) = range.lower_bound.bound_type
  lock_expiration_time <= tx_earliest_time
}

fn mock_tx_unlock(
  now_time: Int,
  datum: Int,
  wallet_address: Address,
  script_address: Address,
) -> Transaction {
  let locked_value = from_lovelace(2_000_000)

  mocktail_tx()
    |> invalid_before(True, now_time)
    |> tx_in(True, mock_tx_hash(0), 0, locked_value, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(True, wallet_address, locked_value)
    |> complete()
}

/// after lock time
test test_unlock_after_lock_time_success() {
  let now_time = 1730301165001
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum = 1
  let redeemer = 1
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_traces_with_datum_and_redeemer.spend(
    Some(datum),
    Some(redeemer),
    output_reference,
    tx,
  )
}

/// at lock time
test test_unlock_at_lock_time_success() {
  let now_time = 1730301165000
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum = 1
  let redeemer = 1
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_traces_with_datum_and_redeemer.spend(
    Some(datum),
    Some(redeemer),
    output_reference,
    tx,
  )
}

/// before lock time
test test_unlock_before_lock_time_fail() fail {
  let now_time = 1730301164999
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum = 1
  let redeemer = 1
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_traces_with_datum_and_redeemer.spend(
    Some(datum),
    Some(redeemer),
    output_reference,
    tx,
  )
}

/// after lock time but wrong redeemer
test test_unlock_after_lock_time_wrong_redeemer_fail() fail {
  let now_time = 1730301165001
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum = 1
  let redeemer = 2
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_traces_with_datum_and_redeemer.spend(
    Some(datum),
    Some(redeemer),
    output_reference,
    tx,
  )
}
