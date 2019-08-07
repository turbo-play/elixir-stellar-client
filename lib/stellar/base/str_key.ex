defmodule Stellar.Base.StrKey do
  @moduledoc false

  # Logic copied from https://github.com/stellar/js-stellar-base/blob/master/src/strkey.js

  import Bitwise

  @version_bytes %{
    # G
    ed25519PublicKey: 6 <<< 3,
    # S
    ed25519SecretSeed: 18 <<< 3,
    # T
    preAuthTx: 19 <<< 3,
    # X
    sha256Hash: 23 <<< 3
  }

  def is_valid_ed25519_public_key(public_key) do
    is_valid(:ed25519PublicKey, public_key)
  end

  def encode_ed25519_public_key(data) do
    encode_check(:ed25519PublicKey, data)
  end

  def decode_ed25519_public_key(data) do
    decode_check(:ed25519PublicKey, data)
  end

  def is_valid_ed25519_secret_seed(secret_seed) do
    is_valid(:ed25519SecretSeed, secret_seed)
  end

  def encode_ed25519_secret_seed(data) do
    encode_check(:ed25519SecretSeed, data)
  end

  def decode_ed25519_secret_seed(data) do
    decode_check(:ed25519SecretSeed, data)
  end

  def encode_pre_auth_tx(data) do
    encode_check(:preAuthTx, data)
  end

  def decode_pre_auth_tx(data) do
    decode_check(:preAuthTx, data)
  end

  def encode_sha256_hash(data) do
    encode_check(:sha256Hash, data)
  end

  def decode_sha256_hash(data) do
    decode_check(:sha256Hash, data)
  end

  def is_valid(_, encoded) when byte_size(encoded) != 56, do: false
  def is_valid(_, nil), do: false

  def is_valid(version_byte_name, encoded) do
    case decode_check(version_byte_name, encoded) do
      {:error, _} -> false
      decoded when byte_size(decoded) == 32 -> true
      _ -> false
    end
  end

  def encode_check(_, nil) do
    {:error, "cannot encode nil data"}
  end

  def encode_check(version_byte_name, _)
      when version_byte_name not in [
             :ed25519PublicKey,
             :ed25519SecretSeed,
             :preAuthTx,
             :sha256Hash
           ] do
    {:error,
     "#{version_byte_name} is not a valid version byte name.  expected one of :ed25519PublicKey, :ed25519SecretSeed, :preAuthTx, :sha256Hash"}
  end

  def encode_check(version_byte_name, data) do
    version_byte = @version_bytes[version_byte_name]

    payload = <<version_byte>> <> data
    checksum = CRC.crc(:crc_16_xmodem, payload)
    unencoded = payload <> <<checksum::little-16>>
    Base.encode32(unencoded, padding: false)
  end

  def decode_check(version_byte_name, encoded) do
    case Base.decode32(encoded) do
      {:ok, decoded} ->
        <<version_byte::size(8), data::binary-size(32), checksum::little-integer-size(16)>> =
          decoded

        expected_version = @version_bytes[version_byte_name]

        cond do
          is_nil(expected_version) ->
            {:error, "#{version_byte_name} is not a valid version byte name"}

          version_byte != expected_version ->
            {:error, "invalid version byte. expected #{expected_version}, got #{version_byte}"}

          true ->
            expected_checksum = CRC.crc(:crc_16_xmodem, <<version_byte>> <> data)
            if checksum != expected_checksum, do: {:error, "invalid checksum"}, else: data
        end

      _ ->
        {:error, "invalid encoded string"}
    end
  end
end
