use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/time.{PosixTime}
use aiken/transaction.{ScriptContext, Transaction} as tx
use aiken/transaction/credential.{VerificationKey}
// At this step, we add sidan_utils -- let's take a look!

// Todo: build tx and confirm this works

use sidan_utils/validity_range.{valid_after, valid_before}

// introduce-parameters.ak
// compare to introduce-redeemer.ak

type SpendingDatum {
  start_time: PosixTime,
  end_time: PosixTime,
}

type SpendingRedeemerAction {
  Claim
  Update
}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

validator(admin_pkh: VerificationKeyHash) {
  fn introduce_parameters(
    datum: SpendingDatum,
    redeemer: SpendingRedeemerAction,
    context: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = context
    expect tx.Spend(_) = purpose

    let Transaction { validity_range, extra_signatories, .. } = transaction

    let SpendingDatum { start_time, end_time } = datum

    when redeemer is {
      Claim -> and {
          valid_after(validity_range, start_time),
          valid_before(validity_range, end_time),
        }
      Update -> list.has(extra_signatories, admin_pkh)
    }
  }
}
// The truth is, this is not secure enough.
// The "admin" can simply claim utxos, and is not required to update them
// At live coding, we will add a rule that says the same amount of lovelace must be returned to the contract utxo
// What are some other rules we could implement?
