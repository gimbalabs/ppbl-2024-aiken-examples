// introduce-datum.ak
// unlock utxo after a certain time

type PaymentDatum {
  description: ByteArray,
}

validator {
  fn reference_token_pair(
    datum: PaymentDatum,
    _redeemer: Data,
    _context: Data,
  ) -> Bool {
    let PaymentDatum { description } = datum

    description == "hello"
  }
}
