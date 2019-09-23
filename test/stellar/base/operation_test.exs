defmodule Stellar.Base.Operation.Test do
  use ExUnit.Case, async: true
  alias Stellar.Base.{Operation, Asset}

  describe "operation account create" do
    setup do
      %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        starting_balance: 1000,
        source: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
      }
    end

    test "create_account successfully creates an operation", %{
      destination: destination,
      starting_balance: sb,
      source: source
    } do
      operation =
        Operation.create_account(%{
          destination: destination,
          starting_balance: sb,
          source: source
        })
        |> Operation.to_xdr()

      obj =
        operation
        |> Stellar.Base.Operation.from_xdr()

      assert obj.type == "createAccount"
      assert obj.destination == destination
      assert obj.startingBalance == sb

      assert %{body: {:CREATE_ACCOUNT, %{startingBalance: sb_response}}} = operation
      assert sb_response = 10_000_000_000
    end

    test "fails create_account with invalid destination address" do
      attrs = %{
        destination: "GCEZW",
        starting_balance: 20,
        source: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
      }

      assert {:error, "destination is invalid"} = Operation.create_account(attrs)
    end

    test "fails create_account with 0 starting_balance" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        starting_balance: 0,
        source: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
      }

      assert {:error, _} = Operation.create_account(attrs)
    end

    test "fails create_account with negative starting_balance" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        starting_balance: -1,
        source: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
      }

      assert {:error, _} = Operation.create_account(attrs)
    end

    test "fails create_account with starting_balance with too many decimals" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        starting_balance: 0.00000001,
        source: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
      }

      assert {:error, _} = Operation.create_account(attrs)
    end

    test "fails create_account with invalid source address" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        starting_balance: 20,
        source: "GCEZ"
      }

      assert {:error, _} = Operation.create_account(attrs)
    end
  end

  describe "operation payment" do
    test "it creates a paymentOp" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        amount: 1000.0,
        # @TODO: test w/ asset 'USDUSD','GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7'
        # asset: Asset.new("USDUSD", "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7")
        asset: Asset.native()
      }

      operation =
        attrs
        |> Operation.payment()
        |> Operation.to_xdr()

      obj =
        operation
        |> Stellar.Base.Operation.from_xdr()

      assert obj.type == "payment"
      assert obj.destination == "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
      assert %{body: {:PAYMENT, %{amount: amount_response}}} = operation
      assert amount_response == 10_000_000_000
      assert obj.amount == 1000.0
    end

    test "fails to create payment operation with an invalid destination address" do
      attrs = %{
        destination: "GCEZW",
        asset: Asset.native(),
        amount: 20
      }

      assert {:error, _} = Operation.payment(attrs)
    end

    test "fails to create payment operation with an invalid amount" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        asset: Asset.native(),
        amount: -20
      }

      assert {:error, _} = Operation.payment(attrs)
    end
  end

  describe "operation path payment" do
    test "creates a pathPaymentOp sucessfully" do
      send_asset = Asset.native()
      send_max = 3.0070000
      destination = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"

      dest_asset =
        Asset.new(
          "USD",
          "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7"
        )

      dest_amount = 3.1415000

      path = [
        Asset.new(
          "USD",
          "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        ),
        Asset.new(
          "EUR",
          "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL"
        )
      ]

      obj =
        Operation.path_payment(%{
          send_asset: send_asset,
          send_max: send_max,
          destination: destination,
          dest_asset: dest_asset,
          dest_amount: dest_amount,
          path: path
        })
        |> Operation.to_xdr()
        |> Operation.from_xdr()

      assert obj.type == "pathPayment"
      assert obj.sendAsset == send_asset
      assert obj.sendMax == send_max
      assert obj.destination == destination
      assert obj.destAmount == dest_amount
      path1 = obj.path |> Enum.at(0)
      assert path1 |> Asset.get_code() == "USD"

      assert path1 |> Asset.get_issuer() ==
               "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"

      path2 = obj.path |> Enum.at(1)
      assert path2 |> Asset.get_code() == "EUR"

      assert path2 |> Asset.get_issuer() ==
               "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL"
    end

    test "fails to create path payment operation with an invalid destination address" do
      attrs = %{
        destination: "GCEZW",
        send_max: 20,
        dest_amount: 50,
        send_asset: Asset.native(),
        dest_asset: Asset.new("USD", "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7")
      }

      assert {:error, _} = Operation.path_payment(attrs)
    end

    test "fails to create path payment operation with an invalid send_max" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        send_max: -1,
        dest_amount: 50,
        send_asset: Asset.native(),
        dest_asset: Asset.new("USD", "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7")
      }

      assert {:error, _} = Operation.path_payment(attrs)
    end

    test "fails to create path payment operation with an invalid dest_amount" do
      attrs = %{
        destination: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
        send_max: 20,
        dest_amount: -1,
        send_asset: Asset.native(),
        dest_asset: Asset.new("USD", "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7")
      }

      assert {:error, _} = Operation.path_payment(attrs)
    end
  end

  describe "allow trust" do
    test "creates an allowTrustOp" do
      trustor = "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7"
      asset_code = "USD"
      authorize = true
      issuer = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"

      op =
        Operation.allow_trust(%{
          trustor: trustor,
          asset_code: asset_code,
          issuer: issuer,
          authorize: authorize
        })

      xdr = op |> Operation.to_xdr()
      obj = xdr |> Operation.from_xdr()
      assert obj.type == "allowTrust"
      assert obj.trustor == trustor
      assert obj.assetCode == asset_code
      assert obj.authorize == authorize
    end

    test "fails to create allow_trust operation with an invalid trustor address" do
      attrs = %{
        trustor: "GCEZW"
      }

      assert {:error, _} = Operation.allow_trust(attrs)
    end
  end

  describe "change trust" do
    test "create op" do
      asset =
        Asset.new(
          "USD",
          "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7"
        )

      op =
        Operation.change_trust(%{
          asset: asset
        })

      xdr = op |> Operation.to_xdr()
      obj = xdr |> Operation.from_xdr()
      assert obj.type == "changeTrust"
      assert asset == obj.line
      assert obj.limit == 9_223_372_036_854_775_807
    end

    test "creates op with limit" do
      asset =
        Asset.new(
          "USD",
          "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7"
        )

      op =
        Operation.change_trust(%{
          asset: asset,
          limit: 50
        })

      xdr = op |> Operation.to_xdr()
      obj = xdr |> Operation.from_xdr()
      assert obj.type == "changeTrust"
      assert obj.limit == 50
    end

    test "deletes trustline" do
      asset =
        Asset.new(
          "USD",
          "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7"
        )

      op =
        Operation.change_trust(%{
          asset: asset,
          limit: 0
        })

      xdr = op |> Operation.to_xdr()
      obj = xdr |> Operation.from_xdr()
      assert obj.type == "changeTrust"
      assert asset == obj.line
      assert obj.limit == 0
    end
  end

  describe "bump sequence" do
    test "creates a bumpSequence" do
      attrs = %{
        bump_to: "77833036561510299"
      }

      obj =
        Operation.bump_sequence(attrs)
        |> Operation.to_xdr()
        |> Operation.from_xdr()

      assert obj.type == "bumpSequence"
      assert obj.bumpTo == attrs.bump_to
    end

    test "fails when `bump_to` is not string" do
      assert {:error, _} = Operation.bump_sequence(%{bump_to: 100})
    end
  end
end
