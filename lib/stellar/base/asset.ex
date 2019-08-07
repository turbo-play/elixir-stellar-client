defmodule Stellar.Base.Asset do
  # https://github.com/stellar/js-stellar-base/blob/master/src/asset.js

  alias Stellar.XDR.Types.LedgerEntries.{
    AssetTypeCreditAlphaNum4,
    AssetTypeCreditAlphaNum12,
    Asset
  }

  alias Stellar.Base.{KeyPair, StrKey}

  defstruct code: nil, issuer: nil

  def native() do
    %__MODULE__{code: "XLM"}
  end

  def new(code, nil) when code != "xlm", do: {:error, "Issuer cannot be nil"}
  def new(_, nil), do: {:error, "Issuer cannot be nil"}

  def new(code, issuer) do
    cond do
      !String.match?(code, ~r/^[a-zA-Z0-9]{1,12}$/) ->
        {:error, "Asset code is invalid (maximum alphanumeric, 12 characters at max)"}

      !Stellar.Base.StrKey.is_valid_ed25519_public_key(issuer) ->
        {:error, "Issuer is invalid"}

      true ->
        %__MODULE__{code: code, issuer: issuer}
    end
  end

  def asset_type(%__MODULE__{issuer: nil}) do
    "native"
  end

  def asset_type(%__MODULE__{code: code}) when byte_size(code) >= 1 and byte_size(code) <= 4 do
    "credit_alphanum4"
  end

  def asset_type(_) do
    "credit_alphanum12"
  end

  def get_code(this) do
    this.code
  end

  def get_issuer(this) do
    this.issuer
  end

  def from_xdr({:ASSET_TYPE_NATIVE, _}), do: native()

  def from_xdr({_, %{assetCode: code, issuer: issuer}}),
    do: new(code |> String.trim_leading("\0"), issuer |> account_id_to_address())

  def to_xdr(asset) do
    asset_params =
      case asset_type(asset) do
        "native" ->
          {:ASSET_TYPE_NATIVE, nil}

        "credit_alphanum4" ->
          with {:ok, issuer} <-
                 asset.issuer |> KeyPair.from_public_key() |> KeyPair.to_xdr_accountid(),
               {:ok, asset_details} <-
                 %AssetTypeCreditAlphaNum4{
                   assetCode: asset.code |> String.pad_leading(4, "\0"),
                   issuer: issuer
                 }
                 |> AssetTypeCreditAlphaNum4.new() do
            {:ASSET_TYPE_CREDIT_ALPHANUM4, asset_details}
          end

        "credit_alphanum12" ->
          with {:ok, asset_details} <-
                 %AssetTypeCreditAlphaNum12{
                   assetCode: asset.code |> String.pad_leading(12, "\0"),
                   issuer: asset.issuer
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

  defp account_id_to_address({_, nil}), do: nil

  defp account_id_to_address({:PUBLIC_KEY_TYPE_ED25519, sourceaccount}) do
    sourceaccount |> StrKey.encode_ed25519_public_key()
  end
end
