defmodule Stellar.Base.Memo do
  defstruct type: nil, value: nil

  def new(:none), do: none()
  def new(_), do: {:error, "Invalid memo type"}
  def new(:id, id), do: id(id)
  def new(:text, text), do: text(text)
  def new(:hash, hash), do: hash(hash)
  def new(:return, hash), do: return(hash)
  def new(_, _), do: {:error, "Invalid memo type"}

  def none() do
    %__MODULE__{type: :none}
  end

  def id(id) when is_integer(id) and id >= 0 do
    %__MODULE__{type: :id, value: id}
  end

  def id(_), do: id()
  def id(), do: {:error, "Expects an integer >= 0"}

  def text(text) when is_binary(text) and byte_size(text) <= 28 do
    %__MODULE__{type: :text, value: text}
  end

  def text(_), do: text()
  def text(), do: {:error, "Expects string, array or buffer, max 28 bytes"}

  def hash(hash) do
    %__MODULE__{type: :hash, value: hash}
  end

  def return(hash) do
    %__MODULE__{type: :return, value: hash}
  end

  def to_xdr(%__MODULE__{} = memo) do
    memo_params =
      case memo.type do
        :none -> {:MEMO_NONE, nil}
        :id -> {:MEMO_ID, memo.value}
        :text -> {:MEMO_TEXT, memo.value}
        :hash -> {:MEMO_HASH, memo.value}
        :return -> {:MEMO_RETURN, memo.value}
      end

    with {:ok, result} <- Stellar.XDR.Types.Transaction.Memo.new(memo_params) do
      result
    else
      err -> err
    end
  end

  def to_xdr(nil), do: nil

  def from_xdr({:MEMO_NONE, nil}), do: none()
  def from_xdr({:MEMO_ID, id}), do: id(id)
  def from_xdr({:MEMO_TEXT, text}), do: text(text)
  def from_xdr({:MEMO_HASH, hash}), do: hash(hash)
  def from_xdr({:MEMO_RETURN, hash}), do: return(hash)
  def from_xdr(_), do: {:error, ""}
end
