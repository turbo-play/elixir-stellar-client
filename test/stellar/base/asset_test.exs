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

  describe "asset to xdr" do
    test "parses a native asset object" do
      asset = Stellar.Base.Asset.native()
      xdr = asset |> Stellar.Base.Asset.to_xdr()
      assert {:ASSET_TYPE_NATIVE, nil} = xdr
    end

    test "parses a 3-alphanum asset object" do
      asset =
        Stellar.Base.Asset.new("USD", "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")

      xdr = asset |> Stellar.Base.Asset.to_xdr()
      assert {:ASSET_TYPE_CREDIT_ALPHANUM4, %{assetCode: asset_code}} = xdr
      assert asset_code == "USD\0"
    end

    test "parses a 4-alphanum asset object" do
      asset =
        Stellar.Base.Asset.new("BART", "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")

      xdr = asset |> Stellar.Base.Asset.to_xdr()
      assert {:ASSET_TYPE_CREDIT_ALPHANUM4, %{assetCode: asset_code}} = xdr
      assert asset_code == "BART"
    end

    test "parses a 5-alphanum asset object" do
      asset =
        Stellar.Base.Asset.new(
          "12345",
          "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        )

      xdr = asset |> Stellar.Base.Asset.to_xdr()
      assert {:ASSET_TYPE_CREDIT_ALPHANUM12, %{assetCode: asset_code}} = xdr
      assert asset_code == "12345\0\0\0\0\0\0\0"
    end

    test "parses a 12-alphanum asset object" do
      asset =
        Stellar.Base.Asset.new(
          "123456789012",
          "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        )

      xdr = asset |> Stellar.Base.Asset.to_xdr()
      assert {:ASSET_TYPE_CREDIT_ALPHANUM12, %{assetCode: asset_code}} = xdr
      assert asset_code == "123456789012"
    end
  end
end
