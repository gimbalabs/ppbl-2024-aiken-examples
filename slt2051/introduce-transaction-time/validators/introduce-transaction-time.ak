use aiken/interval.{Finite}
use cardano/address.{Address}
use cardano/assets.{from_lovelace}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx
use mocktail.{
  complete, invalid_before, mocktail_tx, tx_in, tx_in_inline_datum, tx_out,
}
use mocktail/virgin_address.{mock_pub_key_address, mock_script_address}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

// introduce-transaction-time.ak
// unlock utxo after a certain time

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

// Example 205.1: I can write a validator that succeeds after a specified time.

validator introduce_transaction_time {
  spend(
    _datum_opt: Option<Data>,
    _redeemer: Data,
    _oref: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { validity_range, .. } = tx
    // Change this value
    // Use https://www.epochconverter.com/
    let lock_until = 1729697422000

    must_start_after(validity_range, lock_until)
  }

  else(_) {
    trace @"tx purpose not supported"
    fail
  }
}

fn must_start_after(range: ValidityRange, lock_expiration_time: Int) -> Bool {
  expect Finite(tx_earliest_time) = range.lower_bound.bound_type
  lock_expiration_time <= tx_earliest_time
}

// Notes
// After the lock_until time has passed, this validator "always succeeds"

fn mock_tx_unlock(
  now_time: Int,
  datum: Data,
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
  let now_time = 1729697422001
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum: Data = []
  let redeemer: Data = []
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_transaction_time.spend(Some(datum), redeemer, output_reference, tx)
}

/// at lock time
test test_unlock_at_lock_time_success() {
  let now_time = 1729697422000
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum: Data = []
  let redeemer: Data = []
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_transaction_time.spend(Some(datum), redeemer, output_reference, tx)
}

/// before lock time
test test_unlock_before_lock_time_fail() fail {
  let now_time = 1729697421999
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum: Data = []
  let redeemer: Data = []
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_transaction_time.spend(Some(datum), redeemer, output_reference, tx)
}
