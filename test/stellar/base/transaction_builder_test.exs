defmodule Stellar.Base.TransactionBuilder.Test do
  use ExUnit.Case
  require Logger
  alias Stellar.Base.{TransactionBuilder, Operation, Asset, Memo, Account}

  describe "transaction builder" do
    setup do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)
      destination = "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2"
      amount = 1000
      asset = Asset.native()
      memo = Memo.id(100)

      {:ok, transaction, updated_account} =
        TransactionBuilder.new(source, [{:fee, 100}])
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: destination,
            asset: asset,
            amount: amount
          })
        )
        |> TransactionBuilder.add_memo(memo)
        |> TransactionBuilder.set_timeout(TransactionBuilder.timeout_infinite())
        |> TransactionBuilder.build()

      %{
        source: source,
        destination: destination,
        amount: amount,
        asset: asset,
        memo: memo,
        transaction: transaction,
        updated_account: updated_account
      }
    end

    test "constructs a native payment transaction with one operation", %{
      source: s,
      transaction: t
    } do
      assert t.source == Account.accountId(s)
    end

    test "should have the incremented sequence number", %{
      transaction: t
    } do
      assert t.sequence == 1
    end

    test "should increment the account's sequence number", %{
      updated_account: a
    } do
      assert Account.sequence_number(a) == 1
    end

    test "should have one payment operation", %{
      transaction: t
    } do
      assert t.operations |> Enum.count() == 1
      assert (t.operations |> Enum.at(0)).type == "payment"
    end

    test "should have 100 stroops fee", %{
      transaction: t
    } do
      assert t.fee == 100
    end
  end

  describe "constructs a native payment transaction with custom base fee" do
    setup do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)
      destination1 = "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2"
      destination2 = "GC6ACGSA2NJGD6YWUNX2BYBL3VM4MZRSEU2RLIUZZL35NLV5IAHAX2E2"
      amount1 = 1000
      amount2 = 2000
      asset = Asset.native()
      memo = Memo.id(100)

      {:ok, transaction, _} =
        TransactionBuilder.new(source, [{:fee, 1000}])
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: destination1,
            asset: asset,
            amount: amount1
          })
        )
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: destination2,
            asset: asset,
            amount: amount2
          })
        )
        |> TransactionBuilder.add_memo(memo)
        |> TransactionBuilder.set_timeout(TransactionBuilder.timeout_infinite())
        |> TransactionBuilder.build()

      %{
        source: source,
        destination1: destination1,
        destination2: destination2,
        amount1: amount1,
        amount2: amount2,
        asset: asset,
        memo: memo,
        transaction: transaction
      }
    end

    test "should have 2000 stroops fee", %{transaction: t} do
      assert t.fee == 2000
    end
  end

  describe "constructs a native payment transaction with integer timebounds" do
    setup do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)
      timebounds = %{minTime: 1_455_287_522, maxTime: 1_455_297_545}

      {:ok, transaction, _} =
        TransactionBuilder.new(source, [{:time_bounds, timebounds}, {:fee, 100}])
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
            asset: Asset.native(),
            amount: 1000
          })
        )
        |> TransactionBuilder.build()

      %{
        source: source,
        transaction: transaction,
        timebounds: timebounds
      }
    end

    test "should have have timebounds", %{transaction: t, timebounds: timebounds} do
      assert t.tx.timeBounds.minTime == timebounds.minTime
      assert t.tx.timeBounds.maxTime == timebounds.maxTime
    end
  end

  describe "constructs a native payment transaction with date timebounds" do
    setup do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)

      timebounds = %{
        minTime: 1_528_145_519_000 |> DateTime.from_unix!(:millisecond),
        maxTime: 1_528_231_982_000 |> DateTime.from_unix!(:millisecond)
      }

      {:ok, transaction, _} =
        TransactionBuilder.new(source, [{:time_bounds, timebounds}, {:fee, 100}])
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
            asset: Asset.native(),
            amount: 1000
          })
        )
        |> TransactionBuilder.build()

      %{
        source: source,
        transaction: transaction,
        timebounds: timebounds
      }
    end

    test "timebounds are correct", %{transaction: t, timebounds: timebounds} do
      assert t.tx.timeBounds.minTime == timebounds.minTime |> DateTime.to_unix()
      assert t.tx.timeBounds.maxTime == timebounds.maxTime |> DateTime.to_unix()
    end
  end

  describe "set_timeout" do
    test "fails if not set" do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)

      assert {:error, "TimeBounds has to be set or you must call set_timeout(timeout_infinite)."} =
               TransactionBuilder.new(source, fee: 100)
               |> TransactionBuilder.add_operation(
                 Operation.payment(%{
                   destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
                   asset: Asset.native(),
                   amount: 1000
                 })
               )
               |> TransactionBuilder.build()
    end

    test "timeout negative" do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)

      assert {:error, "timeout cannot be negative"} =
               TransactionBuilder.new(source, fee: 100)
               |> TransactionBuilder.add_operation(
                 Operation.payment(%{
                   destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
                   asset: Asset.native(),
                   amount: 1000
                 })
               )
               |> TransactionBuilder.set_timeout(-1)
    end

    test "sets timebounds" do
      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)

      {:ok, transaction, _} =
        TransactionBuilder.new(source, fee: 100)
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
            asset: Asset.native(),
            amount: 1000
          })
        )
        |> TransactionBuilder.set_timeout(10)
        |> TransactionBuilder.build()

      assert transaction.tx.timeBounds.maxTime == (DateTime.utc_now() |> DateTime.to_unix()) + 10
    end

    test "fails when maxTime already set" do
      timebounds = %{
        minTime: 1_455_287_522 |> DateTime.from_unix!(),
        maxTime: 1_455_297_545 |> DateTime.from_unix!()
      }

      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)

      assert {:error, "timeout has been already set - setting timeout would overwrite it"} =
               TransactionBuilder.new(source, time_bounds: timebounds, fee: 100)
               |> TransactionBuilder.add_operation(
                 Operation.payment(%{
                   destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
                   asset: Asset.native(),
                   amount: 1000
                 })
               )
               |> TransactionBuilder.set_timeout(10)
    end

    test "sets timebounds.maxTime when minTime already set" do
      timebounds = %{
        minTime: 1_455_287_522 |> DateTime.from_unix!(),
        maxTime: 0
      }

      source = Account.new("GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ", 0)

      {:ok, transaction, _} =
        TransactionBuilder.new(source, time_bounds: timebounds, fee: 100)
        |> TransactionBuilder.add_operation(
          Operation.payment(%{
            destination: "GDJJRRMBK4IWLEPJGIE6SXD2LP7REGZODU7WDC3I2D6MR37F4XSHBKX2",
            asset: Asset.native(),
            amount: 1000
          })
        )
        |> TransactionBuilder.set_timeout(10)
        |> TransactionBuilder.build()

      assert transaction.tx.timeBounds.maxTime == (DateTime.utc_now() |> DateTime.to_unix()) + 10
    end
  end

  describe "Construct allow trust operation" do
    setup do
      %{
        source: Account.new("GAYIVSXCNALI3D7P5ROBJ7Q6I4QN6APVRU7CONUP7U6IKJJRPGKYM4EY", 0),
        trustor: "GDDVWKPMJKUH766SMOVKLDTZQCC4B7Q42YRRH7YBBDYDFPI7LWKJP55F"
      }
    end

    test "Build Alphanum12 allow trust", %{source: source, trustor: trustor} do
      asset_code = "DCHHCD"

      {:ok, transaction, _} =
        TransactionBuilder.new(source, [{:fee, 100}])
        |> TransactionBuilder.add_operation(
          Operation.allow_trust(%{
            trustor: trustor,
            asset_code: asset_code,
            authorize: true
          })
        )
        |> TransactionBuilder.set_timeout(10)
        |> TransactionBuilder.build()

      assert List.first(transaction.operations).type == "allowTrust"
      assert List.first(transaction.operations).trustor == trustor
      assert List.first(transaction.operations).assetCode == asset_code
    end

    test "Build Alphanum4 allow trust", %{source: source, trustor: trustor} do
      asset_code = "DCH"

      {:ok, transaction, _} =
        TransactionBuilder.new(source, [{:fee, 100}])
        |> TransactionBuilder.add_operation(
          Operation.allow_trust(%{
            trustor: trustor,
            asset_code: asset_code,
            authorize: true
          })
        )
        |> TransactionBuilder.set_timeout(10)
        |> TransactionBuilder.build()

      assert List.first(transaction.operations).type == "allowTrust"
      assert List.first(transaction.operations).trustor == trustor
      assert List.first(transaction.operations).assetCode == asset_code
    end
  end
end
