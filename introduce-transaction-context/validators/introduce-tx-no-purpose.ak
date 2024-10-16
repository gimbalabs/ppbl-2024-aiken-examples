use aiken/interval.{Finite}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, ValidityRange} as tx

// introduce-context.ak
// unlock utxo after a certain time

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

// Example #1 - a "most general" example
// Any purpose will do!

validator introduce_tx_no_purpose {
  else(context: ScriptContext) {
    let Transaction { validity_range, .. } = context.transaction

    // Change this value
    // Use https://www.epochconverter.com/
    let lock_until = 1728906074000

    must_start_after(validity_range, lock_until)
  }
}

// See https://aiken-lang.org/example--vesting
fn must_start_after(range: ValidityRange, lock_expiration_time: Int) {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> lock_expiration_time <= tx_earliest_time
    _ -> False
  }
}
