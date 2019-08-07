defmodule Stellar.Base.Memo.Test do
  use ExUnit.Case, async: true

  alias Stellar.Base.Memo

  describe "memo constructor" do
    test "throws error when type is invalid" do
      assert {:error, "Invalid memo type"} = Memo.new("test")
    end
  end

  describe "memo none" do
    test "converst to/from xdr object" do
      memo = Memo.new(:none) |> Memo.to_xdr()
      assert {:MEMO_NONE, nil} = memo

      base_memo = Memo.from_xdr(memo)
      assert base_memo.type == :none
      assert base_memo.value == nil
    end
  end

  describe "memo text" do
    test "returns a value for a correct argument" do
      assert %Memo{} = Memo.text("test")
      assert utf8_memo = Memo.text("三代之時")

      assert %Memo{} = utf8_memo
      assert utf8_memo |> Memo.to_xdr() |> elem(1) == "三代之時"
    end

    # @TODO: missing array xdr encoding?

    test "converts to/from xdr object" do
      memo = Memo.text("test") |> Memo.to_xdr()
      assert {:MEMO_TEXT, "test"} == memo

      base_memo = Memo.from_xdr(memo)
      assert base_memo.type == :text
      assert base_memo.value == "test"
    end

    test "fails when invalid argument was passed" do
      assert {:error, _} = Memo.text()
      assert {:error, _} = Memo.text(%{})
      assert {:error, _} = Memo.text(10)
    end

    test "fails when string is longer than 28 bytes" do
      assert {:error, _} = Memo.text("12345678901234567890123456789")
      assert {:error, _} = Memo.text("三代之時三代之時三代之時")
    end
  end

  describe "memo id" do
    test "returns a value for a correct argument" do
      assert %Memo{} = Memo.id(1000)
      assert %Memo{} = Memo.id(0)
    end

    test "converts to/from xdr object" do
      memo = Memo.id(1000) |> Memo.to_xdr()
      assert {:MEMO_ID, 1000} == memo

      base_memo = Memo.from_xdr(memo)
      assert base_memo.type == :id
      assert base_memo.value == 1000
    end

    test "fails when invalid argument was passed" do
      assert {:error, _} = Memo.id()
      assert {:error, _} = Memo.id(%{})
      assert {:error, _} = Memo.id("test")
    end
  end

  # @TODO: missing memo's of hash type
end
