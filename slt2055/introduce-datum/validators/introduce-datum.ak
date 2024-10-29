use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

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
      // Explore the implications in Lesson 205.3
      _ -> True
    }
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
