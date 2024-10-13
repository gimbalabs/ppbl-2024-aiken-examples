use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

// introduce-datum.ak
// Allow unlock time to be specified for each UTxO

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

pub type Datum {
  expiration_time: Int,
}

validator introduce_datum {
  spend(
    datum: Option<Datum>,
    _redeemer: Option<Data>,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { validity_range, .. } = tx

    when datum is {
      Some(Datum { expiration_time }) ->
        must_start_after(validity_range, expiration_time)
      _ -> False
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
