defmodule Stellar.Base.TransactionBuilder do
  alias Stellar.Base.{Memo, Account, KeyPair, Operation, Transaction}
  require Logger

  def timeout_infinite, do: 0
  def base_fee, do: 100

  # https://github.com/stellar/js-stellar-base/blob/master/src/transaction_builder.js
  defstruct source_account: nil,
            memo: nil,
            operations: [],
            base_fee: 100,
            time_bounds: nil,
            timeout_set: false

  def new(source_account, opts \\ [])

  def new(%Stellar.Base.Account{} = source_account, opts) do
    %__MODULE__{
      source_account: source_account,
      base_fee: Keyword.get(opts, :fee, __MODULE__.base_fee()),
      memo: Keyword.get(opts, :memo, Memo.none()),
      time_bounds: Keyword.get(opts, :time_bounds),
      operations: [],
      timeout_set: false
    }
  end

  def new(nil, _), do: {:error, "must specify source account for the transaction"}

  def add_memo(this, memo) do
    %{this | memo: memo}
  end

  def add_operation(this, operation) do
    %{this | operations: this.operations ++ [operation]}
  end

  def set_timeout(_, timeout) when timeout < 0,
    do: {:error, "timeout cannot be negative"}

  def set_timeout(%{time_bounds: %{maxTime: mt}}, _) when mt > 0,
    do: {:error, "timeout has been already set - setting timeout would overwrite it"}

  def set_timeout(this, 0) do
    this
    |> Map.merge(%{timeout_set: true})
  end

  def set_timeout(this, timeout) do
    this
    |> Map.merge(%{timeout_set: true})

    timeoutTimestamp = DateTime.to_unix(DateTime.utc_now()) + timeout

    this =
      case this.time_bounds do
        nil ->
          %{this | time_bounds: %{minTime: 0, maxTime: timeoutTimestamp}}

        tb ->
          %{
            this
            | time_bounds: %{minTime: tb.minTime, maxTime: timeoutTimestamp}
          }
      end

    this
  end

  def build(%{time_bounds: nil, timeout_set: false}),
    do: {:error, "TimeBounds has to be set or you must call set_timeout(timeout_infinite)."}

  def build(%{time_bounds: %{maxTime: 0}, timeout_set: false}),
    do: {:error, "TimeBounds has to be set or you must call set_timeout(timeout_infinite)."}

  def build(this) do
    with updated_source_account <- Account.increment_sequence_number(this.source_account),
         {:ok, xdr_transaction} <- build_transaction_xdr(this, updated_source_account),
         {:ok, xenv} <- build_transaction_envelope(xdr_transaction),
         %Transaction{} = tx <- Transaction.new(xenv) do
      {:ok, tx, updated_source_account}
    end
  end

  def build(_, _),
    do: {:error, "TimeBounds has to be set or you must call set_timeout(timeout_infinite)."}

  defp build_transaction_xdr(this, source_account) do
    with {:ok, sourceAccountXDR} <- get_source_account_xdr(source_account),
         {:ok, ext} <- Stellar.XDR.Types.DefaultExt.new({0, nil}) do
      %Stellar.XDR.Types.Transaction.Transaction{
        sourceAccount: sourceAccountXDR,
        fee: calculate_transaction_fee(this),
        seqNum: source_account |> Account.sequence_number(),
        memo: this.memo |> Memo.to_xdr(),
        operations: this.operations |> Enum.map(fn op -> op |> Operation.to_xdr() end),
        ext: ext
      }
      |> Map.merge(extract_time_bounds(this))
      |> Stellar.XDR.Types.Transaction.Transaction.new()
    end
  end

  defp build_transaction_envelope(xdr_transaction) do
    %Stellar.XDR.Types.Transaction.TransactionEnvelope{tx: xdr_transaction, signatures: []}
    |> Stellar.XDR.Types.Transaction.TransactionEnvelope.new()
  end

  defp extract_time_bounds(%{time_bounds: %{minTime: minTime, maxTime: maxTime}}) do
    with {:ok, mintime} <- process_time(minTime),
         {:ok, maxtime} <- process_time(maxTime),
         {:ok, timebounds} <-
           %Stellar.XDR.Types.Transaction.TimeBounds{minTime: mintime, maxTime: maxtime}
           |> Stellar.XDR.Types.Transaction.TimeBounds.new() do
      %{timeBounds: timebounds}
    end
  end

  defp extract_time_bounds(_), do: %{}

  defp calculate_transaction_fee(this) do
    this.base_fee * (this.operations |> Enum.count())
  end

  defp process_time(time) do
    case time do
      %DateTime{} = t -> DateTime.to_unix(t)
      t -> t
    end
    |> Stellar.XDR.Types.UInt64.new()
  end

  defp get_source_account_xdr(source_account) do
    source_account
    |> Account.accountId()
    |> KeyPair.from_public_key()
    |> KeyPair.to_xdr_accountid()
  end
end
