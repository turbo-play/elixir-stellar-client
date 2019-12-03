defmodule Stellar.Base.AllowTrustAsset.Test do
  use ExUnit.Case, async: true

  alias Stellar.Base.AllowTrustAsset

  test "to xdr with ALPHANUM4" do
    asset_code = "DCH"

    result = AllowTrustAsset.to_xdr(asset_code)

    assert elem(result, 0) == :ASSET_TYPE_CREDIT_ALPHANUM4
    assert is_map(elem(result, 1)) == true
  end

  test "to xdr with ALPHANUM12" do
    asset_code = "DCHHCD"

    result = AllowTrustAsset.to_xdr(asset_code)

    assert elem(result, 0) == :ASSET_TYPE_CREDIT_ALPHANUM12
    assert is_map(elem(result, 1)) == true
  end

  test "from xdr ALPHANUM4" do
    asset_code = "DCH"

    result =
      AllowTrustAsset.to_xdr(asset_code)
      |> AllowTrustAsset.from_xdr()

    assert result == asset_code
  end

  test "from xdr ALPHANUM12" do
    asset_code = "DCHHCD"

    result =
      AllowTrustAsset.to_xdr(asset_code)
      |> AllowTrustAsset.from_xdr()

    assert result == asset_code
  end
end
