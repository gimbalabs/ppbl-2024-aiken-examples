use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

// Here is a rather trivial first example
// Your task: what is some business logic that would be more helpful than this?
// Bring your ideas to Lesson 205.6

pub type SpendingDatum {
  unlock_time: Int,
  admin_pkh: VerificationKeyHash,
}

pub type SpendingRedeemerAction {
  Claim
  Remove
}

validator introduce_redeemer {
  spend(
    datum_opt: Option<SpendingDatum>,
    redeemer: SpendingRedeemerAction,
    _input: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { validity_range, extra_signatories, .. } = tx

    expect Some(datum) = datum_opt

    when redeemer is {
      Claim -> must_start_after(validity_range, datum.unlock_time)
      Remove -> list.has(extra_signatories, datum.admin_pkh)
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
