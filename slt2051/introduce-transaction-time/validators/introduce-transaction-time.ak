use aiken/interval.{Finite}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, ValidityRange} as tx

// introduce-transaction-time.ak
// unlock utxo after a certain time

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

// Example 205.1: I can write a validator that succeeds after a specified time.

// In this example, any purpose will do!
// To learn more about purpose, see Lesson 205.3

validator introduce_transaction_time {
  else(context: ScriptContext) {
    let Transaction { validity_range, .. } = context.transaction

    // Change this value
    // Use https://www.epochconverter.com/
    let lock_until = 1728906075000

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
// Notes
// After the lock_until time has passed, this validator "always succeeds"
