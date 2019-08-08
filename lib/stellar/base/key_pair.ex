defmodule Stellar.Base.KeyPair do
  @moduledoc """
  Operations for dealing with key pairs
  """
  alias Stellar.Base.{StrKey, Signer}
  alias Stellar.XDR.Types.Transaction.DecoratedSignature

  defstruct type: nil,
            _secret_seed: nil,
            _public_key: nil

  def new(%{type: :ed25519, secret_key: secret_key}) when byte_size(secret_key) != 32,
    do: {:error, "secret_key length is invalid"}

  def new(%{type: :ed25519, secret_key: secret_key} = keys) do
    public_key = Ed25519.derive_public_key(secret_key)

    cond do
      keys |> Map.get(:public_key, public_key) != public_key ->
        {:error, "secret_key does not match public_key"}

      true ->
        %__MODULE__{
          type: :ed25519,
          _secret_seed: secret_key,
          _public_key: public_key
        }
    end
  end

  def new(%{type: :ed25519, public_key: public_key}) when byte_size(public_key) !== 32,
    do: {:error, "invalid public key"}

  def new(%{type: :ed25519, public_key: public_key}) do
    %__MODULE__{
      type: :ed25519,
      _public_key: public_key
    }
  end

  def new(_), do: {:error, "invalid keys type"}

  def raw_public_key(this) do
    this._public_key
  end

  def public_key(this) do
    StrKey.encode_ed25519_public_key(this._public_key)
  end

  def raw_secret_key(this) do
    this._secret_seed
  end

  def secret(%__MODULE__{type: type}) when type != :ed25519,
    do: {:error, "invalid keypair type"}

  def secret(%__MODULE__{type: :ed25519, _secret_seed: secret_seed}) do
    secret_seed |> StrKey.encode_ed25519_secret_seed()
  end

  @doc """
  Generates a key pair from the given secret
  """
  def from_secret(secret) do
    with decoded_secret when is_binary(decoded_secret) <-
           secret |> StrKey.decode_ed25519_secret_seed(),
         keypair <- __MODULE__.from_raw_ed25519_seed(decoded_secret) do
      keypair
    else
      err -> err
    end
  end

  @doc """
  Generates a key pair from public key
  """
  def from_public_key(nil), do: {:error, "invalid public key"}
  def from_public_key(""), do: {:error, "invalid public key"}

  def from_public_key(public_key) do
    decoded_key = StrKey.decode_check(:ed25519PublicKey, public_key)

    if is_binary(decoded_key) and byte_size(decoded_key) == 32,
      do: __MODULE__.new(%{type: :ed25519, public_key: decoded_key}),
      else: {:error, "invalid public key"}
  end

  def from_raw_ed25519_seed(raw_seed) do
    __MODULE__.new(%{type: :ed25519, secret_key: raw_seed})
  end

  def signature_hint(this) do
    with {:ok, a} <- this |> __MODULE__.to_xdr_accountid(),
         {:ok, key} <- a |> Stellar.XDR.Types.PublicKey.encode(),
         keylength <- byte_size(key) do
      key |> String.slice((keylength - 5)..keylength)
    end
  end

  def verify(this, data, signature) do
    Signer.verify(data, signature, this._public_key)
  end

  def sign_decorated(this, data) do
    with signature <- Signer.sign(data, this |> __MODULE__.raw_secret_key()),
         hint <- this |> __MODULE__.signature_hint(),
         {:ok, dec_sign} <-
           %DecoratedSignature{hint: hint, signature: signature} |> DecoratedSignature.new() do
      dec_sign
    else
      err -> err
    end
  end

  def master() do
    __MODULE__.from_raw_ed25519_seed(Stellar.current_network_id())
  end

  @doc """
  Generates a new keypair
  """
  def random() do
    :crypto.strong_rand_bytes(32) |> __MODULE__.from_raw_ed25519_seed()
  end

  def to_xdr_accountid(this) do
    Stellar.XDR.Types.PublicKey.new({:PUBLIC_KEY_TYPE_ED25519, this._public_key})
  end
end
