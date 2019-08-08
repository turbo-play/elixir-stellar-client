defmodule Stellar.Base.Account do
  # https://github.com/stellar/js-stellar-base/blob/master/src/account.js
  alias Stellar.Base.StrKey

  defstruct _accountId: nil, sequence: nil

  def new(_, sequence) when not is_integer(sequence),
    do: {:error, "sequence must be of type integer"}

  def new(accountId, sequence) do
    if StrKey.is_valid_ed25519_public_key(accountId) do
      %__MODULE__{
        _accountId: accountId,
        sequence: sequence
      }
    else
      {:error, "accountId is invalid"}
    end
  end

  def accountId(this) do
    this._accountId
  end

  def sequence_number(this) do
    this.sequence
  end

  def increment_sequence_number(%__MODULE__{} = this) do
    this
    |> Map.update(:sequence, 1, &(&1 + 1))
  end
end
