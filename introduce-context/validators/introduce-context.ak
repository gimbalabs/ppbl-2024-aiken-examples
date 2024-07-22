use aiken/interval.{Finite}
use aiken/time.{PosixTime}
use aiken/transaction.{ScriptContext, Transaction, ValidityRange} as tx

// introduce-context.ak
// unlock utxo after a certain time

// Helpful Docs
// https://aiken-lang.github.io/stdlib/aiken/interval.html

validator {
  fn reference_token_pair(
    datum: Int,
    redeemer: Int,
    context: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = context
    expect tx.Spend(_) = purpose

    let Transaction { validity_range, .. } = transaction

    let lock_until = 1721565497000

    and {
      datum == redeemer,
      must_start_after(validity_range, lock_until),
    }
  }
}

fn must_start_after(range: ValidityRange, lock_expiration_time: PosixTime) {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> lock_expiration_time <= tx_earliest_time
    _ -> False
  }
}
