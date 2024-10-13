use aiken/interval.{Finite}
use aiken/time.{PosixTime}
use aiken/transaction.{ScriptContext, Transaction, ValidityRange} as tx

// introduce-datum.ak
// unlock utxo before a time specified in datum

type SpendingDatum {
  start_time: PosixTime,
  end_time: PosixTime,
}

validator {
  fn introduce_datum(
    datum: SpendingDatum,
    redeemer: SpendingDatum,
    context: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = context
    expect tx.Spend(_) = purpose

    let Transaction { validity_range, .. } = transaction

    let SpendingDatum { start_time, end_time } = datum

    and {
      datum == redeemer,
      must_start_after(validity_range, start_time),
      must_start_before(validity_range, end_time),
    }
  }
}

// We will reuse this:
// Let's move it to a different file so we can use it often
// See https://aiken-lang.org/example--vesting
fn must_start_after(range: ValidityRange, lock_expiration_time: PosixTime) {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> lock_expiration_time <= tx_earliest_time
    _ -> False
  }
}

fn must_start_before(range: ValidityRange, redeem_expiration_time: PosixTime) {
  when range.upper_bound.bound_type is {
    Finite(tx_latest_time) -> redeem_expiration_time >= tx_latest_time
    _ -> False
  }
}
