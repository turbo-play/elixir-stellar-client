defmodule Stellar.Base.StrKey.Test do
  use ExUnit.Case, async: true
  alias Stellar.Base.{StrKey, KeyPair}

  setup_all do
    keypair = KeyPair.master()
    unencoded_bytes = keypair |> KeyPair.raw_public_key()

    %{
      keypair: keypair,
      unencoded_bytes: unencoded_bytes,
      unencoded: unencoded_bytes |> Base.encode16(),
      account_id_encoded: keypair |> KeyPair.public_key(),
      seed_encoded: unencoded_bytes |> StrKey.encode_ed25519_secret_seed()
    }
  end

  describe "decodes" do
    test "it decodes correctly", context do
      assert context[:account_id_encoded] |> StrKey.decode_ed25519_public_key() ==
               context[:unencoded_bytes]

      assert context[:seed_encoded] |> StrKey.decode_ed25519_secret_seed() ==
               context[:unencoded_bytes]
    end

    test "fails when the version byte is wrong" do
      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU"
               )
    end

    test "fails when decoded data encodes to other string" do
      # accountId
      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "GADE5QJ2TY7S5ZB65Q43DFGWYWCPHIYDJ2326KZGAGBN7AE5UY6JVDRRA"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T"
               )

      #  seed
      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYW"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2T"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "SCMB30FQCIQAWZ4WQTS6SVK37LGMAFJGXOZIHTH2PY6EXLP37G46H6DT"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "SAYC2LQ322EEHZYWNSKBEW6N66IRTDREEBUXXU5HPVZGMAXKLIZNM45H++"
               )
    end

    test "fails when checksum doesn't match" do
      assert {:error, _} =
               StrKey.decode_ed25519_public_key(
                 "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVT"
               )

      assert {:error, _} =
               StrKey.decode_ed25519_secret_seed(
                 "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCX"
               )
    end
  end

  describe "encodes" do
    test "encodes a string correctly", context do
      assert context[:unencoded_bytes] |> StrKey.encode_ed25519_public_key() ==
               context[:account_id_encoded]

      assert Regex.match?(~r/^G/, context[:unencoded_bytes] |> StrKey.encode_ed25519_public_key())

      assert context[:unencoded_bytes] |> StrKey.encode_ed25519_secret_seed() ==
               context[:seed_encoded]

      assert Regex.match?(
               ~r/^S/,
               context[:unencoded_bytes] |> StrKey.encode_ed25519_secret_seed()
             )

      strkeyEncoded = context[:unencoded_bytes] |> StrKey.encode_pre_auth_tx()
      assert Regex.match?(~r/^T/, strkeyEncoded)
      assert strkeyEncoded |> StrKey.decode_pre_auth_tx() == context[:unencoded_bytes]

      strkeyEncoded = context[:unencoded_bytes] |> StrKey.encode_sha256_hash()
      assert Regex.match?(~r/^X/, strkeyEncoded)
      assert strkeyEncoded |> StrKey.decode_sha256_hash() == context[:unencoded_bytes]

      assert StrKey.encode_ed25519_secret_seed(context[:unencoded_bytes]) ==
               context[:seed_encoded]

      assert StrKey.encode_ed25519_public_key(context[:unencoded_bytes]) ==
               context[:account_id_encoded]
    end

    test "fails to encode_check with nil data" do
      assert {:error, _} = StrKey.encode_ed25519_public_key(nil)
      assert {:error, _} = StrKey.encode_ed25519_secret_seed(nil)
    end
  end

  describe "is_valid_ed25519_public_key" do
    test "is_valid_ed25519_public_key with valid keys" do
      keys = [
        "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
        "GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT",
        "GD6WVYRVID442Y4JVWFWKWCZKB45UGHJAABBJRS22TUSTWGJYXIUR7N2",
        "GBCG42WTVWPO4Q6OZCYI3D6ZSTFSJIXIS6INCIUF23L6VN3ADE4337AP",
        "GDFX463YPLCO2EY7NGFMI7SXWWDQAMASGYZXCG2LATOF3PP5NQIUKBPT",
        "GBXEODUMM3SJ3QSX2VYUWFU3NRP7BQRC2ERWS7E2LZXDJXL2N66ZQ5PT",
        "GAJHORKJKDDEPYCD6URDFODV7CVLJ5AAOJKR6PG2VQOLWFQOF3X7XLOG",
        "GACXQEAXYBEZLBMQ2XETOBRO4P66FZAJENDHOQRYPUIXZIIXLKMZEXBJ",
        "GDD3XRXU3G4DXHVRUDH7LJM4CD4PDZTVP4QHOO4Q6DELKXUATR657OZV",
        "GDTYVCTAUQVPKEDZIBWEJGKBQHB4UGGXI2SXXUEW7LXMD4B7MK37CWLJ"
      ]

      keys |> Enum.each(fn k -> assert StrKey.is_valid_ed25519_public_key(k) == true end)
    end

    test "is_valid_ed25519_public_key fails with invalid keys" do
      keys = [
        "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T",
        "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2",
        "GADE5QJ2TY7S5ZB65Q43DFGWYWCPHIYDJ2326KZGAGBN7AE5UY6JVDRRA",
        "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++",
        "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL",
        "gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wt",
        # Old network key
        "g4VPBPrHZkfE8CsjuG2S4yBQNd455UWmk",
        "test",
        "GDXIIZTKTLVYCBHURXL2UPMTYXOVNI7BRAEFQCP6EZCY4JLKY4VKFNLT",
        "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY",
        nil
      ]

      keys |> Enum.each(fn k -> assert k |> StrKey.is_valid_ed25519_public_key() == false end)
    end
  end

  describe "is_valid_ed25519_secret_seed" do
    test "is_valid_ed25519_secret_seed with valid keys" do
      keys = [
        "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY",
        "SCZTUEKSEH2VYZQC6VLOTOM4ZDLMAGV4LUMH4AASZ4ORF27V2X64F2S2",
        "SCGNLQKTZ4XCDUGVIADRVOD4DEVNYZ5A7PGLIIZQGH7QEHK6DYODTFEH",
        "SDH6R7PMU4WIUEXSM66LFE4JCUHGYRTLTOXVUV5GUEPITQEO3INRLHER",
        "SC2RDTRNSHXJNCWEUVO7VGUSPNRAWFCQDPP6BGN4JFMWDSEZBRAPANYW",
        "SCEMFYOSFZ5MUXDKTLZ2GC5RTOJO6FGTAJCF3CCPZXSLXA2GX6QUYOA7"
      ]

      keys |> Enum.each(fn k -> assert k |> StrKey.is_valid_ed25519_secret_seed() == true end)
    end

    test "is_valid_ed25519_secret_seed fails with invalid keys" do
      keys = [
        "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
        "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDYT",
        "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEV",
        "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEVIT",
        "test",
        nil
      ]

      keys |> Enum.each(fn k -> assert k |> StrKey.is_valid_ed25519_secret_seed() == false end)
    end
  end
end
