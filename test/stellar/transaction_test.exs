# defmodule Stellar.Transaction.Test do
#   use ExUnit.Case
#   require Logger
#   alias Stellar.{TransactionBuilder, Transaction, Operation, Asset, Memo, Account, KeyPair}

#   test "signs correctly" do
#     source = Account.new("GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB", "0")
#     destination = "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2"
#     asset = Asset.native()
#     amount = 2000
#     memo = Memo.text("Happy birthday!")

#     signer = KeyPair.master

#     transaction = source
#       |> TransactionBuilder.new(memo: memo)
#       |> TransactionBuilder.add_operation(
#         Operation.payment(%{
#           destination: destination,
#           asset: asset,
#           amount: amount
#         })
#       )
#       |> TransactionBuilder.set_timeout(1000)
#       |> TransactionBuilder.build
#       |> Transaction.sign(signer)

#     env = transaction |> Transaction.to_envelope
#     raw_sig = env.signatures |> Enum.at(0) 
#     raw_sig_details = raw_sig.signature
#     verified = signer |> KeyPair.verify(transaction |> Transaction.hash, raw_sig_details)
#     assert verified == true
#   end

# end
