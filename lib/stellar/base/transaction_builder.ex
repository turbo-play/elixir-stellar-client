defmodule Stellar.Base.TransactionBuilder do
  alias Stellar.{XDR, Transaction}
  alias Stellar.Base.{Memo, Account, KeyPair, Operation}
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
    %{this | timeout_set: true}
  end

  def set_timeout(this, timeout) do
    this = %{this | timeout_set: true}
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
    seq_number =
      Account.increment_sequence_number(this.source_account)
      |> Account.sequence_number()
      |> String.to_integer()

    sourceAccount = KeyPair.from_public_key(this.source_account |> Account.accountId())
    {:ok, sourceAccountXDR} = sourceAccount |> KeyPair.to_xdr_accountid()

    operations = this.operations |> Enum.map(fn op -> op |> Operation.to_xdr() end)

    {:ok, ext} = Stellar.XDR.Types.DefaultExt.new({0, nil})

    attrs = %Stellar.XDR.Types.Transaction.Transaction{
      sourceAccount: sourceAccountXDR,
      fee: this.base_fee * (this.operations |> Enum.count()),
      seqNum: seq_number,
      memo: if(this.memo, do: this.memo |> Memo.to_xdr(), else: nil),
      operations: operations,
      ext: ext
    }

    attrs =
      case this.time_bounds do
        nil ->
          attrs

        _ ->
          mintime =
            case this.time_bounds.minTime do
              %DateTime{} = t -> DateTime.to_unix(t)
              t -> t
            end

          maxtime =
            case this.time_bounds.maxTime do
              %DateTime{} = t -> DateTime.to_unix(t)
              t -> t
            end

          with {:ok, mintime} <- Stellar.XDR.Types.UInt64.new(mintime),
               {:ok, maxtime} <- Stellar.XDR.Types.UInt64.new(maxtime),
               {:ok, timebounds} <-
                 %Stellar.XDR.Types.Transaction.TimeBounds{minTime: mintime, maxTime: maxtime}
                 |> Stellar.XDR.Types.Transaction.TimeBounds.new() do
            %{attrs | timeBounds: timebounds}
          else
            _ -> attrs
          end
      end

    # XDR verify transaction
    {:ok, xdr_transaction} = Stellar.XDR.Types.Transaction.Transaction.new(attrs)

    # create XDR envelope and create a new transaction from the envelope
    {:ok, xenv} =
      %Stellar.XDR.Types.Transaction.TransactionEnvelope{tx: xdr_transaction, signatures: []}
      |> Stellar.XDR.Types.Transaction.TransactionEnvelope.new()

    tx = Transaction.new(xenv)

    # return XDR validated transaction
    tx
  end

  def build(_, _),
    do: {:error, "TimeBounds has to be set or you must call set_timeout(timeout_infinite)."}
end
