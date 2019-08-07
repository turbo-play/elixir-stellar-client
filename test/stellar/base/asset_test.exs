defmodule Stellar.Base.Asset.Test do
  use ExUnit.Case, async: true

  describe "asset constructor" do
    test "fails when there's no issuer for non XLM type asset" do
      assert {:error, "Issuer cannot be nil"} = Stellar.Base.Asset.new("USD", nil)
    end

    test "fails when code is invalid" do
      assert {:error, "Asset code is invalid (maximum alphanumeric, 12 characters at max)"} =
               Stellar.Base.Asset.new(
                 "",
                 "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
               )

      assert {:error, "Asset code is invalid (maximum alphanumeric, 12 characters at max)"} =
               Stellar.Base.Asset.new(
                 "1234567890123",
                 "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
               )

      assert {:error, "Asset code is invalid (maximum alphanumeric, 12 characters at max)"} =
               Stellar.Base.Asset.new(
                 "ab_",
                 "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
               )
    end
  end

  test "fails when issuer is invalid" do
    assert {:error, "Issuer is invalid"} = Stellar.Base.Asset.new("USD", "GCEZWKCA5")
  end
end
