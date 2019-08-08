defmodule Stellar.Base.Transaction do
  alias Stellar.Base.{KeyPair, Operation, StrKey}
  alias Stellar.XDR.Types.Transaction.{TransactionEnvelope, DecoratedSignatures}

  defstruct tx: nil,
            source: nil,
            fee: nil,
            _memo: nil,
            sequence: nil,
            timeBounds: nil,
            operations: nil,
            signatures: nil

  def new(%Stellar.XDR.Types.Transaction.TransactionEnvelope{} = envelope) do
    with {:PUBLIC_KEY_TYPE_ED25519, sourceaccount} <- envelope.tx.sourceAccount do
      %__MODULE__{
        tx: envelope.tx,
        source: sourceaccount |> StrKey.encode_ed25519_public_key(),
        fee: envelope.tx.fee,
        _memo: envelope.tx.memo,
        sequence: envelope.tx.seqNum,
        operations: envelope.tx.operations |> Enum.map(fn op -> op |> Operation.from_xdr() end),
        signatures: envelope.signatures |> Enum.map(fn sigs -> sigs end)
      }
      |> Map.merge(extract_timebounds_from_tx(envelope.tx))
    end
  end

  # extracts timebounds and updates transaction if present
  defp extract_timebounds_from_tx(%{timeBounds: tb}) when not is_nil(tb) do
    %{
      timeBounds: %{
        minTime: tb.minTime,
        maxTime: tb.maxTime
      }
    }
  end

  defp extract_timebounds_from_tx(_), do: %{}

  # Get memo info
  def memo(this) do
    this._memo
  end

  def sign(transaction, keypairs) do
    with keypairs <- List.wrap(keypairs),
         tx_hashed <- transaction |> hash(),
         {:ok, decorated_signatures} <-
           Enum.map(keypairs, fn kp -> KeyPair.sign_decorated(kp, tx_hashed) end)
           |> DecoratedSignatures.new() do
      transaction
      |> Map.merge(%{signatures: decorated_signatures})
    end
  end

  def verify(signature, transaction, secret) do
    Ed25519.valid_signature?(signature, transaction, secret)
  end

  def to_envelope(this) do
    with {:ok, envelope} <-
           %TransactionEnvelope{
             tx: this.tx,
             signatures: this.signatures
           }
           |> TransactionEnvelope.new() do
      envelope
    end
  end

  def hash_string(binary) do
    :crypto.hash(:sha256, binary)
  end

  def hash(this) do
    this
    |> signatureBase()
    |> hash_string()
  end

  def signatureBase(transaction) do
    with {:ok, envelope} <-
           Stellar.XDR.Types.LedgerEntries.EnvelopeType.encode(:ENVELOPE_TYPE_TX),
         {:ok, tx} <- Stellar.XDR.Types.Transaction.Transaction.encode(transaction.tx) do
      Stellar.Network.Base.network_id() <> envelope <> tx
    end
  end
end
