defmodule Stellar.Base.Account.Test do
  use ExUnit.Case, async: true

  describe "account constructor" do
    test "fails to create Account object from an invalid address" do
      assert {:error, "accountId is invalid"} = Stellar.Base.Account.new("GBBB", 1)
    end

    test "fails to create Account struct from an invalid sequence number" do
      assert {:error, "sequence must be of type integer"} =
               Stellar.Base.Account.new(
                 "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
                 "100"
               )
    end

    test "creates an Account struct" do
      assert (%Stellar.Base.Account{} = account) =
               Stellar.Base.Account.new(
                 "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
                 100
               )

      assert Stellar.Base.Account.accountId(account) ==
               "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"

      assert Stellar.Base.Account.sequence_number(account) == 100
    end
  end

  describe "increments sequence number for Account struct" do
    test "correctly increments the sequence number" do
      account =
        Stellar.Base.Account.new(
          "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
          100
        )
        |> Stellar.Base.Account.increment_sequence_number()

      assert Stellar.Base.Account.sequence_number(account) == 101

      incremented_account =
        account
        |> Stellar.Base.Account.increment_sequence_number()
        |> Stellar.Base.Account.increment_sequence_number()

      assert Stellar.Base.Account.sequence_number(incremented_account) == 103
    end
  end
end
