defmodule Stellar.Base.Account do
  # https://github.com/stellar/js-stellar-base/blob/master/src/account.js
  alias Stellar.Base.StrKey

  defstruct _accountId: nil, sequence: nil

  def new(_, sequence) when not is_bitstring(sequence),
    do: {:error, "sequence must be of type string"}

  def new(accountId, sequence) do
    case StrKey.is_valid_ed25519_public_key(accountId) do
      true ->
        %__MODULE__{
          _accountId: accountId,
          sequence: sequence |> String.to_integer()
        }

      _ ->
        {:error, "accountId is invalid"}
    end
  end

  def accountId(this) do
    this._accountId
  end

  def sequence_number(this) do
    this.sequence |> Integer.to_string()
  end

  def increment_sequence_number(this) do
    %__MODULE__{this | sequence: this.sequence + 1}
  end
end
