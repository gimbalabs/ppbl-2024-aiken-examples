use aiken/hash.{Blake2b_224, Hash}
use aiken/interval.{Finite}
use aiken/list
use aiken/time.{PosixTime}
use aiken/transaction.{ScriptContext, Transaction, ValidityRange} as tx
use aiken/transaction/credential.{VerificationKey}

// introduce-redeemer.ak
// unlock utxo before a time specified in datum

type SpendingDatum {
  start_time: PosixTime,
  end_time: PosixTime,
  admin_pkh: VerificationKeyHash,
}

type SpendingRedeemerAction {
  Claim
  Update
}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

validator {
  fn introduce_redeemer(
    datum: SpendingDatum,
    redeemer: SpendingRedeemerAction,
    context: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = context
    expect tx.Spend(_) = purpose

    let Transaction { validity_range, extra_signatories, .. } = transaction

    let SpendingDatum { start_time, end_time, admin_pkh } = datum

    when redeemer is {
      Claim -> and {
          must_start_after(validity_range, start_time),
          must_start_before(validity_range, end_time),
        }
      Update -> list.has(extra_signatories, admin_pkh)
    }
  }
}

// The truth is, this is not secure enough.
// The "admin" can simply claim utxos, and is not required to update them
// At live coding, we will add a rule that says the same amount of lovelace must be returned to the contract utxo
// What are some other rules we could implement?

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
