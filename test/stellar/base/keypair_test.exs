defmodule Stellar.Base.KeyPair.Test do
  use ExUnit.Case, async: true
  alias Stellar.Base.{KeyPair, StrKey}

  describe "keypair constructor" do
    test "create keypair fails when secret key doesn't match public key" do
      secret = "SD7X7LEHBNMUIKQGKPARG5TDJNBHKC346OUARHGZL5ITC6IJPXHILY36"
      kp = KeyPair.from_secret(secret)

      secret_key = kp |> KeyPair.raw_secret_key()
      public_key = StrKey.decode_ed25519_public_key(kp |> KeyPair.public_key())
      <<_::binary-size(1), public_key_without_first_byte::binary>> = public_key
      wrong_public_key = <<0>> <> public_key_without_first_byte

      assert {:error, "secret_key does not match public_key"} =
               KeyPair.new(%{type: :ed25519, secret_key: secret_key, public_key: wrong_public_key})
    end

    test "create keypair fails when secret key length is invalid" do
      secret_keys = [
        String.duplicate("a", 33),
        String.duplicate("a", 31)
      ]

      secret_keys
      |> Enum.each(fn k ->
        assert {:error, _} = KeyPair.new(%{type: :ed25519, secret_key: k})
      end)
    end

    test "create keypair fails when public key is invalid" do
      public_key = [
        String.duplicate("a", 33),
        String.duplicate("a", 31)
      ]

      public_key
      |> Enum.each(fn k ->
        assert {:error, _} = KeyPair.new(%{type: :ed25519, public_key: k})
      end)
    end
  end

  describe "keypair from secret" do
    test "succeeds when private and public keys match" do
      secret = "SD7X7LEHBNMUIKQGKPARG5TDJNBHKC346OUARHGZL5ITC6IJPXHILY36"
      kp = secret |> KeyPair.from_secret()

      assert %KeyPair{} = kp

      assert kp |> KeyPair.public_key() ==
               "GDFQVQCYYB7GKCGSCUSIQYXTPLV5YJ3XWDMWGQMDNM4EAXAL7LITIBQ7"

      assert kp |> KeyPair.secret() == secret
    end

    test "fails when seed isn't properly encoded" do
      assert {:error, "invalid encoded string"} = KeyPair.from_secret("hel0")

      assert {:error, "invalid encoded string"} =
               KeyPair.from_secret("SBWUBZ3SIPLLF5CCXLWUB2Z6UBTYAW34KVXOLRQ5HDAZG4ZY7MHNBWJ1")

      assert {:error, "invalid encoded string"} =
               KeyPair.from_secret("masterpassphrasemasterpassphrase")

      assert {:error, "invalid encoded string"} =
               KeyPair.from_secret("gsYRSEQhTffqA9opPepAENCr2WG6z5iBHHubxxbRzWaHf8FBWcu")
    end
  end

  describe "keypair from_raw_ed25519_seed" do
    test "creates a keypair correctly" do
      seed = "masterpassphrasemasterpassphrase"
      kp = seed |> KeyPair.from_raw_ed25519_seed()

      assert %KeyPair{} = kp

      assert kp |> KeyPair.public_key() ==
               "GAXDYNIBA5E4DXR5TJN522RRYESFQ5UNUXHIPTFGVLLD5O5K552DF5ZH"

      assert kp |> KeyPair.secret() == "SBWWC43UMVZHAYLTONYGQ4TBONSW2YLTORSXE4DBONZXA2DSMFZWLP2R"

      assert kp |> KeyPair.raw_public_key() |> Base.encode16() |> String.downcase() ==
               "2e3c35010749c1de3d9a5bdd6a31c12458768da5ce87cca6aad63ebbaaef7432"
    end
  end

  describe "keypair from_public_key" do
    test "creates a keypair correctly" do
      kp = KeyPair.from_public_key("GAXDYNIBA5E4DXR5TJN522RRYESFQ5UNUXHIPTFGVLLD5O5K552DF5ZH")

      assert %KeyPair{} = kp
      public_key = kp |> KeyPair.public_key()
      assert public_key == "GAXDYNIBA5E4DXR5TJN522RRYESFQ5UNUXHIPTFGVLLD5O5K552DF5ZH"
      raw_public_key = kp |> KeyPair.raw_public_key()

      assert Base.encode16(raw_public_key, case: :lower) ==
               "2e3c35010749c1de3d9a5bdd6a31c12458768da5ce87cca6aad63ebbaaef7432"
    end

    test "fails if the arg isn't strkey encoded as a accountid" do
      assert {:error, _} = KeyPair.from_public_key("hel0")
      assert {:error, _} = KeyPair.from_public_key("masterpassphrasemasterpassphrase")

      assert {:error, _} =
               KeyPair.from_public_key("sfyjodTxbwLtRToZvi6yQ1KnpZriwTJ7n6nrASFR6goRviCU3Ff")
    end

    test "fails if if the address isn't 32 bytes" do
      assert {:error, _} = KeyPair.from_public_key("masterpassphrasemasterpassphrase")
      assert {:error, _} = KeyPair.from_public_key(nil)
      assert {:error, _} = KeyPair.from_public_key("")
    end
  end

  describe "keypair random" do
    test "creates pair successfully" do
      kp = KeyPair.random()
      assert %KeyPair{} = kp
    end
  end
end
