defmodule Stellar.Base.Signer do
  @type key :: binary
  @type signature :: binary

  alias Stellar.XDR.Types.LedgerEntries.{Signer}
  alias Stellar.XDR.Types.{SignerKey, UInt32}
  alias Stellar.Base.{KeyPair, StrKey}

  @doc """
  This function allows the case when the singer to encode is nil
  returns nil
  """
  @spec to_xdr(nil) :: nil
  def to_xdr(nil), do: nil

  @doc """
  This function clause validates the weight of the new signer,this weight can't be greater than 255
    ## Parameters
    - Represents a map that contains the key and the weight of the signer which we need to add on SetOptions
  returns an :error tuple with :invalid_weight atom
  """
  @spec to_xdr(map()) :: {:error, :invalid_weight}
  def to_xdr(%{key: _, weight: weight}) when weight > 255, do: {:error, :invalid_weight}

  @doc """
  This function is in charge of encoding the signer to XDR format
    ##Parameters
    Represents a map that contains the key and the weight from the signer
    - key: It is the public key of the signer which is necessary to add into the account
    - weight: represents the weight of the signer to add
  returns a signer in XDR format
  """
  @spec to_xdr(map()) :: Signer.t()
  def to_xdr(%{key: key, weight: weight}) do
    with {:ok, signer_account} <- KeyPair.from_public_key(key) |> to_xdr_accountid(),
         {:ok, signer_weight} <- amount_to_xdr(weight) do
      %Signer{key: signer_account, weight: signer_weight}
    end
  end

  @doc """
  This function gets the case where the signer to decode is nil
  returns nil
  """
  @spec from_xdr(nil) :: nil
  def from_xdr(nil), do: nil

  @doc """
  This function gets the Signer structure and decode from XDR format
    ##Parameters
    - signer: represents a Signer struct with the XDR info regarding the signer
  Returns a map of the signer data in the default data type
  """
  @spec from_xdr(signer :: Signer.t()) :: map()
  def from_xdr(signer) do
    %{key: account_id_to_address(signer.key), weight: signer.weight}
  end

  @spec account_id_to_address(signer_account :: map()) :: String.t()
  defp account_id_to_address({:SIGNER_KEY_TYPE_ED25519, signer_account}) do
    signer_account |> StrKey.encode_ed25519_public_key()
  end

  @spec to_xdr_accountid(this :: map()) :: SignerKey.t()
  defp to_xdr_accountid(this) do
    SignerKey.new({:SIGNER_KEY_TYPE_ED25519, this._public_key})
  end

  @spec amount_to_xdr(amount :: number()) :: UInt32.t()
  defp amount_to_xdr(amount) do
    UInt32.new(amount)
  end

  @spec sign(binary(), Ed25519.key()) :: signature()
  def sign(data, secret) do
    Ed25519.signature(data, secret)
  end

  @spec verify(binary, signature(), Ed25519.key()) :: boolean
  def verify(data, signature, public_key) do
    Ed25519.valid_signature?(signature, data, public_key)
  end
end
