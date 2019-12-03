defmodule Stellar.Signer.Test do
  use ExUnit.Case, async: true
  alias Stellar.Base.Signer

  setup_all do
    with {:ok, seed} <-
           "1123740522f11bfef6b3671f51e159ccf589ccf8965262dd5f97d1721d383dd4"
           |> Base.decode16(case: :lower),
         {:ok, public_key} <-
           "ffbdd7ef9933fe7249dc5ca1e7120b6d7b7b99a7a367e1a2fc6cb062fe420437"
           |> Base.decode16(case: :lower),
         {:ok, sig} <-
           "587d4b472eeef7d07aafcd0b049640b0bb3f39784118c2e2b73a04fa2f64c9c538b4b2d0f5335e968a480021fdc23e98c0ddf424cb15d8131df8cb6c4bb58309"
           |> Base.decode16(case: :lower),
         {:ok, bad_sig} <-
           "687d4b472eeef7d07aafcd0b049640b0bb3f39784118c2e2b73a04fa2f64c9c538b4b2d0f5335e968a480021fdc23e98c0ddf424cb15d8131df8cb6c4bb58309"
           |> Base.decode16(case: :lower) do
      %{
        seed: seed,
        public_key: public_key,
        expected_sig:
          "587d4b472eeef7d07aafcd0b049640b0bb3f39784118c2e2b73a04fa2f64c9c538b4b2d0f5335e968a480021fdc23e98c0ddf424cb15d8131df8cb6c4bb58309",
        sig: sig,
        bad_sig: bad_sig
      }
    end
  end

  describe "signs" do
    test "can sign a string properly", context do
      data = "hello world"
      actual_sig = Signer.sign(data, context[:seed]) |> Base.encode16(case: :lower)
      assert actual_sig == context[:expected_sig]
    end

    test "can sign a binary properly", context do
      data = <<"hello world">>
      actual_sig = Signer.sign(data, context[:seed]) |> Base.encode16(case: :lower)
      assert actual_sig == context[:expected_sig]
    end

    test "can sign a charlist properly", context do
      data = <<104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100>>
      actual_sig = Signer.sign(data, context[:seed]) |> Base.encode16(case: :lower)
      assert actual_sig == context[:expected_sig]
    end
  end

  describe "verifies" do
    test "can verify a string properly", context do
      data = "hello world"
      assert Signer.verify(data, context[:sig], context[:public_key]) == true
      assert Signer.verify("corrupted", context[:sig], context[:public_key]) == false
      assert Signer.verify(data, context[:bad_sig], context[:public_key]) == false
    end

    test "can verify a binary properly", context do
      data = <<"hello world">>
      assert Signer.verify(data, context[:sig], context[:public_key]) == true
      assert Signer.verify("corrupted", context[:sig], context[:public_key]) == false
      assert Signer.verify(data, context[:bad_sig], context[:public_key]) == false
    end

    test "can verify a charlist properly", context do
      data = <<104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100>>
      assert Signer.verify(data, context[:sig], context[:public_key]) == true
      assert Signer.verify("corrupted", context[:sig], context[:public_key]) == false
      assert Signer.verify(data, context[:bad_sig], context[:public_key]) == false
    end
  end

  describe "Signer to XDR" do
    test "parser a signer with an valid weight" do
      result =
        Enum.all?(0..255, fn weight ->
          is_map(
            Signer.to_xdr(%{
              key: "GDDVWKPMJKUH766SMOVKLDTZQCC4B7Q42YRRH7YBBDYDFPI7LWKJP55F",
              weight: weight
            })
          )
        end)

      assert result == true
    end

    test "parse a signer with an invalid weight" do
      {status, result} =
        Signer.to_xdr(%{
          key: "GDDVWKPMJKUH766SMOVKLDTZQCC4B7Q42YRRH7YBBDYDFPI7LWKJP55F",
          weight: 256
        })

      assert status == :error
      assert result == :invalid_weight
    end
  end

  test "Signer from XDR" do
    signer = %Stellar.XDR.Types.LedgerEntries.Signer{
      key:
        {:SIGNER_KEY_TYPE_ED25519,
         <<199, 91, 41, 236, 74, 168, 127, 251, 210, 99, 170, 165, 142, 121, 128, 133, 192, 254,
           28, 214, 35, 19, 255, 1, 8, 240, 50, 189, 31, 93, 148, 151>>},
      weight: 7
    }

    result = Signer.from_xdr(signer)

    assert result.key == "GDDVWKPMJKUH766SMOVKLDTZQCC4B7Q42YRRH7YBBDYDFPI7LWKJP55F"
    assert result.weight == signer.weight
  end
end
