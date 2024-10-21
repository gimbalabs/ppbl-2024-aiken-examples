use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

// introduce-traces.ak
// unlock utxo after a certain time

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

// SLT 205.4: I can use traces to diagnose validation errors.
// Datum and Redeemer must match - but which error is stopping validation?

validator introduce_context_with_datum_and_redeemer {
  spend(
    datum: Option<Data>,
    redeemer: Option<Data>,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { validity_range, .. } = tx

    // Change this number:
    let lock_until = 1729107050000

    and {
      datum == redeemer,
      must_start_after(validity_range, lock_until),
    }
  }

  // "It's up to you to define the else behavior"
  // Future: open up options
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
