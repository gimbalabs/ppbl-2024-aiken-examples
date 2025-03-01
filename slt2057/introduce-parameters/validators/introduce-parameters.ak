use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{Finite}
use cardano/address.{Address}
use cardano/assets.{from_lovelace}
use cardano/transaction.{OutputReference, Transaction, ValidityRange} as tx
use mocktail.{
  complete, invalid_before, mocktail_tx, required_signer_hash, tx_in,
  tx_in_inline_datum, tx_out,
}
use mocktail/virgin_address.{mock_pub_key_address, mock_script_address}
use mocktail/virgin_key_hash.{mock_pub_key_hash}
use mocktail/virgin_output_reference.{mock_tx_hash, mock_utxo_ref}

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

fn must_start_after(range: ValidityRange, lock_expiration_time: Int) -> Bool {
  expect Finite(tx_earliest_time) = range.lower_bound.bound_type
  lock_expiration_time <= tx_earliest_time
}

fn mock_tx_claim(
  now_time: Int,
  datum: SpendingDatum,
  wallet_address: Address,
  script_address: Address,
) -> Transaction {
  let locked_value = from_lovelace(2_000_000)

  mocktail_tx()
    |> invalid_before(True, now_time)
    |> tx_in(True, mock_tx_hash(0), 0, locked_value, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(True, wallet_address, locked_value)
    |> complete()
}

/// unlock after lock time
test test_claim_after_lock_time_success() {
  let now_time = 1730301165001
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let admin_pkh = mock_pub_key_hash(0)
  let datum = SpendingDatum { unlock_time: 1730301165000 }
  let redeemer = Claim
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_claim(now_time, datum, wallet_address, script_address)

  introduce_parameters.spend(
    admin_pkh,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}

/// unlock at lock time
test test_claim_at_lock_time_success() {
  let now_time = 1730301165000
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let admin_pkh = mock_pub_key_hash(0)
  let datum = SpendingDatum { unlock_time: 1730301165000 }
  let redeemer = Claim
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_claim(now_time, datum, wallet_address, script_address)

  introduce_parameters.spend(
    admin_pkh,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}

/// unlock before lock time
test test_claim_before_lock_time_fail() fail {
  let now_time = 1730301164999
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let admin_pkh = mock_pub_key_hash(0)
  let datum = SpendingDatum { unlock_time: 1730301165000 }
  let redeemer = Claim
  let output_reference = mock_utxo_ref(0, 0)
  let tx = mock_tx_claim(now_time, datum, wallet_address, script_address)

  introduce_parameters.spend(
    admin_pkh,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}

fn mock_tx_remove(
  now_time: Int,
  datum: SpendingDatum,
  admin_pkh: VerificationKeyHash,
  wallet_address: Address,
  script_address: Address,
) -> Transaction {
  let locked_value = from_lovelace(2_000_000)

  mocktail_tx()
    |> invalid_before(True, now_time)
    |> tx_in(True, mock_tx_hash(0), 0, locked_value, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(True, wallet_address, locked_value)
    |> required_signer_hash(True, admin_pkh)
    |> complete()
}

/// remove before lock time
test test_remove_before_lock_time_success() {
  let now_time = 1730301164999
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let admin_pkh = mock_pub_key_hash(0)
  let datum = SpendingDatum { unlock_time: 1730301165000 }
  let redeemer = Remove
  let output_reference = mock_utxo_ref(0, 0)
  let tx =
    mock_tx_remove(now_time, datum, admin_pkh, wallet_address, script_address)

  introduce_parameters.spend(
    admin_pkh,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}

fn mock_tx_remove_no_signer(
  now_time: Int,
  datum: SpendingDatum,
  wallet_address: Address,
  script_address: Address,
) -> Transaction {
  let locked_value = from_lovelace(2_000_000)

  mocktail_tx()
    |> invalid_before(True, now_time)
    |> tx_in(True, mock_tx_hash(0), 0, locked_value, script_address)
    |> tx_in_inline_datum(True, datum)
    |> tx_out(True, wallet_address, locked_value)
    |> complete()
}

/// remove before lock time
test test_remove_before_lock_time_no_signer_fail() fail {
  let now_time = 1730301164999
  let wallet_address = mock_pub_key_address(0, None)
  let script_address = mock_script_address(1, None)
  let admin_pkh = mock_pub_key_hash(0)
  let datum = SpendingDatum { unlock_time: 1730301165000 }
  let redeemer = Remove
  let output_reference = mock_utxo_ref(0, 0)
  let tx =
    mock_tx_remove_no_signer(now_time, datum, wallet_address, script_address)

  introduce_parameters.spend(
    admin_pkh,
    Some(datum),
    redeemer,
    output_reference,
    tx,
  )
}
