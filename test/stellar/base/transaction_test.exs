defmodule Stellar.Base.Transaction.Test do
  use ExUnit.Case
  require Logger
  alias Stellar.Base.{TransactionBuilder, Transaction, Operation, Asset, Memo, Account, KeyPair}

  test "signs correctly" do
    source = Account.new("GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB", 0)
    destination = "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2"
    asset = Asset.native()
    amount = 2000
    memo = Memo.text("Happy birthday!")

    signer = KeyPair.master()

    {:ok, transaction, _} =
      source
      |> TransactionBuilder.new(memo: memo)
      |> TransactionBuilder.add_operation(
        Operation.payment(%{
          destination: destination,
          asset: asset,
          amount: amount
        })
      )
      |> TransactionBuilder.set_timeout(1000)
      |> TransactionBuilder.build()

    signed_transaction =
      transaction
      |> Transaction.sign(signer)

    env = signed_transaction |> Transaction.to_envelope()
    raw_sig = env.signatures |> Enum.at(0)
    raw_sig_details = raw_sig.signature
    verified = signer |> KeyPair.verify(signed_transaction |> Transaction.hash(), raw_sig_details)
    assert verified == true
  end

  test "signs set_options correctly" do
    source =
      Account.new("GDRSG4KRN6SFM3C7NFRVB5Y3PR6OFEBY4TOP4EHLAAMZXRAWJMRBO4VE", 29_888_677_412_932)

    signer = KeyPair.from_secret("SDHPVJCQEFM5CJ4NDZYGZYOG3DXV35QHR5IQO3VR3BT2YTS2U3DZCJMB")

    {:ok, transaction, _} =
      TransactionBuilder.new(source, [{:fee, 100}])
      |> TransactionBuilder.add_operation(
        Operation.set_options(%{
          master_weight: 3
        })
      )
      |> TransactionBuilder.set_timeout(10)
      |> TransactionBuilder.build()

    signed_transaction =
      transaction
      |> Transaction.sign(signer)

    env = signed_transaction |> Transaction.to_envelope()

    raw_sig = env.signatures |> Enum.at(0)
    raw_sig_details = raw_sig.signature
    verified = signer |> KeyPair.verify(signed_transaction |> Transaction.hash(), raw_sig_details)
    assert verified == true
  end
end
