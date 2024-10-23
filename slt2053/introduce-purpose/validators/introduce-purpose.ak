use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

// introduce-purpose.ak
// Lock UTxO at a validator address. After a specified time, anyone can claim the UTxO.

// SLT 205.3: I can write a validator with a purpose.
// Require spending. For any other script purpose, fail

validator introduce_purpose {
  spend(_datum, _redeemer, _input: OutputReference, tx: Transaction) {
    let Transaction { validity_range, .. } = tx

    // Change this value
    // Use https://www.epochconverter.com/
    let lock_until = 1729700122000

    must_start_after(validity_range, lock_until)
  }

  else(_) {
    fail
  }
}

// See https://aiken-lang.org/example--vesting
fn must_start_after(range: ValidityRange, lock_expiration_time: Int) {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> lock_expiration_time <= tx_earliest_time
    _ -> False
  }
}
