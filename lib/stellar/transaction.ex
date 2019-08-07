defmodule Stellar.Transaction do
  alias Stellar.Base.{Asset, Memo, Account, KeyPair, Operation, TransactionBuilder, StrKey}
  alias Stellar.XDR.Types.Transaction.{TransactionEnvelope, DecoratedSignatures}

  defstruct tx: nil,
            source: nil,
            fee: nil,
            _memo: nil,
            sequence: nil,
            time_bounds: nil,
            operations: nil,
            signatures: nil

  def new(envelope) do
    {:PUBLIC_KEY_TYPE_ED25519, sourceaccount} = envelope.tx.sourceAccount

    this = %__MODULE__{
      tx: envelope.tx,
      source: sourceaccount |> StrKey.encode_ed25519_public_key(),
      fee: envelope.tx.fee,
      _memo: envelope.tx.memo,
      sequence: envelope.tx.seqNum,
      operations: envelope.tx.operations || []
    }

    timeBounds = this.tx.timeBounds

    if timeBounds do
      this = %{
        this
        | timeBounds: %{
            minTime: timeBounds.minTime |> Integer.to_string(),
            maxTime: timeBounds.maxTime |> Integer.to_string()
          }
      }
    end

    this = %{
      this
      | operations: this.tx.operations |> Enum.map(fn op -> op |> Operation.from_xdr() end),
        signatures: envelope.signatures |> Enum.map(fn sigs -> sigs end)
    }
  end

  # Get memo info
  def memo(this) do
    this._memo
  end

  def sign(transaction, keypairs) do
    keypairs = List.wrap(keypairs)
    hashed = transaction |> hash()

    {:ok, decorated_signatures} =
      Enum.map(keypairs, fn kp -> KeyPair.sign_decorated(kp, hashed) end)
      |> DecoratedSignatures.new()

    {:ok, encoded_sigs} = decorated_signatures |> DecoratedSignatures.encode()
    %{transaction | signatures: decorated_signatures}
  end

  def verify(signature, transaction, secret) do
    Ed25519.valid_signature?(signature, transaction, secret)
  end

  def to_envelope(this) do
    {:ok, envelope} =
      %TransactionEnvelope{
        tx: this.tx,
        signatures: this.signatures
      }
      |> TransactionEnvelope.new()

    envelope
  end

  def hash_string(binary) do
    :crypto.hash(:sha256, binary)
  end

  def hash(this) do
    sigbase = this |> signatureBase()
    sigbase |> hash_string()
  end

  def signatureBase(transaction) do
    network_id = network_id(Application.get_env(:stellar, :network, :public))
    {:ok, envelope} = Stellar.XDR.Types.LedgerEntries.EnvelopeType.encode(:ENVELOPE_TYPE_TX)
    {:ok, tx} = Stellar.XDR.Types.Transaction.Transaction.encode(transaction.tx)
    network_id <> envelope <> tx
  end

  defp network_id(network) do
    network
    |> network_passphrase()
    |> hash_string()
  end

  defp network_passphrase(:public), do: "Public Global Stellar Network ; September 2015"
  defp network_passphrase(:local), do: "Integration Test Network ; zulucrypto"
  defp network_passphrase(_), do: "Test SDF Network ; September 2015"
end
