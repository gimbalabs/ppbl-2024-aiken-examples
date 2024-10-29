use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

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
    let lock_until = 1730198005000

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

// See https://aiken-lang.org/example--vesting
fn must_start_after(range: ValidityRange, lock_expiration_time: Int) {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> lock_expiration_time <= tx_earliest_time
    _ -> False
  }
}
