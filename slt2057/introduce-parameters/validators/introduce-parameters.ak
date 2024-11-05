use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{Finite}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx

// 205.7: Intro to parameters
// Suppose that we want to define a single admin_pkh for all UTxOs locked in this validator
// What are some implications?
// 1. No longer need admin_pkh in datum
// 2. Anyone can create an instance of this contract by applying their pkh to params --> each a different address

// Question for students: How to make this more real and relevant?

pub type SpendingDatum {
  unlock_time: Int,
}

pub type SpendingRedeemerAction {
  Claim
  Remove
}

validator introduce_parameters(admin_pkh: VerificationKeyHash) {
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
      Remove -> list.has(extra_signatories, admin_pkh)
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
