defmodule Stellar.Base.AllowTrustAsset do
  alias Stellar.XDR.Types.{
    AssetTypeCreditAlphaNum4,
    AssetTypeCreditAlphaNum12,
    Asset
  }

  @doc """
  This function decodes the XDR Asset to String
    ##Parameters
      - code: represents the XDR structure of the asset code
  """
  @spec from_xdr(tuple()) :: String.t()
  def from_xdr({_, %{assetCode4: code}}),
    do: code |> String.trim_trailing("\0")

  @doc """
  This function decodes the XDR Asset to String
    ##Parameters
      - code: represents the XDR structure of the asset code
  """
  @spec from_xdr(tuple()) :: String.t()
  def from_xdr({_, %{assetCode12: code}}),
    do: code |> String.trim_trailing("\0")

  @doc """
  This function gets the case when the asset code value is nil
  returns an error tuple with the description of the error
  """
  @spec to_xdr(nil) :: {:error, String.t()}
  def to_xdr(nil), do: {:error, "Asset code cannot be nil"}

  @doc """
  This function encode the asset that needs the AllowTrust operation, this Asset contains the data required to perform the operation
    ##Parameters
    - asset: Represents the Asset code of the AllowTrust
  returns an Asset structure with the type of the Asset and its details
  """
  @spec to_xdr(asset :: String.t()) :: Asset.t()
  def to_xdr(asset) do
    asset_params =
      case asset_type(asset) do
        "native" ->
          {:ASSET_TYPE_NATIVE, nil}

        "credit_alphanum4" ->
          with {:ok, asset_details} <-
                 %AssetTypeCreditAlphaNum4{
                   assetCode4: asset |> String.pad_trailing(4, "\0")
                 }
                 |> AssetTypeCreditAlphaNum4.new() do
            {:ASSET_TYPE_CREDIT_ALPHANUM4, asset_details}
          end

        "credit_alphanum12" ->
          with {:ok, asset_details} <-
                 %AssetTypeCreditAlphaNum12{
                   assetCode12: asset |> String.pad_trailing(12, "\0")
                 }
                 |> AssetTypeCreditAlphaNum12.new() do
            {:ASSET_TYPE_CREDIT_ALPHANUM12, asset_details}
          end
      end

    with {:ok, result} <- Asset.new(asset_params) do
      result
    else
      err -> err
    end
  end

  @spec asset_type(String.t()) :: String.t()
  defp asset_type("XML") do
    "native"
  end

  @spec asset_type(code :: String.t()) :: String.t()
  defp asset_type(code) when byte_size(code) >= 1 and byte_size(code) <= 4 do
    "credit_alphanum4"
  end

  @spec asset_type(any()) :: String.t()
  defp asset_type(_) do
    "credit_alphanum12"
  end
end
