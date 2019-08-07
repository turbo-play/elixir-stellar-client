defmodule Stellar.Base.Signer do
  @type key :: binary
  @type signature :: binary

  @spec sign(binary(), Ed25519.key()) :: signature()
  def sign(data, secret) do
    Ed25519.signature(data, secret)
  end

  def verify(data, signature, public_key) do
    Ed25519.valid_signature?(signature, data, public_key)
  end
end
