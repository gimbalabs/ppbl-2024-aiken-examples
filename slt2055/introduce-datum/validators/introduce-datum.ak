use aiken/interval.{Finite}
use cardano/address.{Address}
use cardano/assets.{from_lovelace}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx
use mocktail.{
  complete, invalid_before, mocktail_tx, tx_in, tx_in_inline_datum, tx_out,
}
use mocktail/virgin_address.{mock_pub_key_address, mock_script_address}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

// introduce-datum.ak
// Allow unlock time to be specified for each UTxO

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

validator introduce_datum {
  spend(
    datum_opt: Option<Int>,
    _redeemer: Option<Int>,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { validity_range, .. } = tx

    when datum_opt is {
      Some(datum_int) -> {
        let is_valid = must_start_after(validity_range, datum_int)

        trace @"Not a valid expiration time"
        is_valid?
      }

      // otherwise if datum is not present
      // See Live Coding 2024-10-30
      _ -> True
    }
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
  let datum = 1730301165000
  let redeemer = 1
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_datum.spend(Some(datum), Some(redeemer), output_reference, tx)
}

/// at lock time
test test_unlock_at_lock_time_success() {
  let now_time = 1730301165000
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum = 1730301165000
  let redeemer = 1
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_datum.spend(Some(datum), Some(redeemer), output_reference, tx)
}

/// before lock time
test test_unlock_before_lock_time_fail() fail {
  let now_time = 1730301164999
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let datum = 1730301165000
  let redeemer = 1
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_unlock(now_time, datum, wallet_address, script_address)

  introduce_datum.spend(Some(datum), Some(redeemer), output_reference, tx)
}
