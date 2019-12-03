defmodule Stellar.Base.Operation do
  # https://github.com/stellar/js-stellar-base/tree/master/src/operations
  alias Stellar.Base.{KeyPair, Asset, StrKey, AllowTrustAsset}

  alias Stellar.XDR.Types.Transaction.{
    CreateAccountOp,
    PaymentOp,
    AllowTrustOp,
    ChangeTrustOp,
    BumpSequenceOp,
    PathPaymentOp,
    OperationBody
  }

  alias Stellar.XDR.Types.Transaction.Operation, as: XDROperation

  defstruct type: nil,
            destination: nil,
            startingBalance: nil,
            asset: nil,
            amount: nil,
            sendAsset: nil,
            sendMax: nil,
            destAsset: nil,
            destAmount: nil,
            path: [],
            line: nil,
            limit: nil,
            trustor: nil,
            assetCode: nil,
            authorize: nil,
            inflationDest: nil,
            clearFlags: nil,
            setFlags: nil,
            masterWeight: nil,
            lowThreshold: nil,
            medThreshold: nil,
            highThreshold: nil,
            homeDomain: nil,
            signer: nil,
            selling: nil,
            buying: nil,
            price: nil,
            offerId: nil,
            name: nil,
            value: nil,
            bumpTo: nil,
            sourceAccount: nil

  defmacro type_account_merge, do: quote(do: "accountMerge")
  defmacro type_create_account, do: quote(do: "createAccount")
  defmacro type_payment, do: quote(do: "payment")
  defmacro type_path_payment, do: quote(do: "pathPayment")
  defmacro type_allow_trust, do: quote(do: "allowTrust")
  defmacro type_change_trust, do: quote(do: "changeTrust")
  defmacro type_bump_sequence, do: quote(do: "bumpSequence")

  def unit(), do: 10_000_000

  def account_merge(opts) do
    %__MODULE__{
      type: type_account_merge(),
      destination: Map.get(opts, :destination),
      sourceAccount: Map.get(opts, :source, nil)
    }
  end

  def allow_trust(%{asset_code: asset_code}) when byte_size(asset_code) > 12,
    do: {:error, "Asset code must be 12 characters max"}

  def allow_trust(opts) do
    cond do
      !StrKey.is_valid_ed25519_public_key(opts.trustor) ->
        {:error, "trustor is invalid"}

      true ->
        %__MODULE__{
          type: type_allow_trust(),
          trustor: Map.get(opts, :trustor),
          asset: Map.get(opts, :asset_code),
          authorize: Map.get(opts, :authorize),
          sourceAccount: Map.get(opts, :source, nil)
        }
    end
  end

  def bump_sequence(%{bump_to: bump_to}) when not is_binary(bump_to),
    do: {:error, "bump_to must be a string"}

  def bump_sequence(%{source: source, bump_to: bump_to}) do
    cond do
      !StrKey.is_valid_ed25519_public_key(source) ->
        {:error, "source is invalid"}

      true ->
        %__MODULE__{
          type: type_bump_sequence(),
          bumpTo: bump_to,
          sourceAccount: source
        }
    end
  end

  def bump_sequence(%{bump_to: bump_to}) do
    %__MODULE__{
      type: type_bump_sequence(),
      bumpTo: bump_to
    }
  end

  def change_trust(opts) do
    cond do
      Map.get(opts, :limit) && !is_valid_amount(opts.limit, true) ->
        {:error, "invalid limit"}

      true ->
        %__MODULE__{
          type: type_change_trust(),
          limit: Map.get(opts, :limit, 9_223_372_036_854_775_807),
          line: Map.get(opts, :asset, nil)
        }
    end
  end

  def create_account(opts) do
    cond do
      !StrKey.is_valid_ed25519_public_key(opts.destination) ->
        {:error, "destination is invalid"}

      !is_valid_amount(opts.starting_balance, false) ->
        {:error, "invalid starting_balance"}

      !StrKey.is_valid_ed25519_public_key(opts.source) ->
        {:error, "source is invalid"}

      true ->
        %__MODULE__{
          type: type_create_account(),
          destination: Map.get(opts, :destination),
          startingBalance: Map.get(opts, :starting_balance),
          sourceAccount: Map.get(opts, :source, nil)
        }
    end
  end

  def create_passive_offer(opts) do
    %__MODULE__{
      type: "createPassiveOffer",
      selling: Map.get(opts, :selling),
      buying: Map.get(opts, :buying),
      amount: Map.get(opts, :amount),
      price: Map.get(opts, :price),
      sourceAccount: Map.get(opts, :source, nil)
    }
  end

  def inflation(opts) do
    %__MODULE__{
      type: "inflation",
      sourceAccount: Map.get(opts, :source, nil)
    }
  end

  def manage_data(opts) do
    %__MODULE__{
      type: "manageData",
      name: Map.get(opts, :name),
      value: Map.get(opts, :value),
      sourceAccount: Map.get(opts, :source, nil)
    }
  end

  def manage_offer(opts) do
    %__MODULE__{
      type: "manageOffer",
      selling: Map.get(opts, :selling),
      buying: Map.get(opts, :buying),
      amount: Map.get(opts, :amount),
      price: Map.get(opts, :price),
      offerId: Map.get(opts, :offer_id, "0"),
      sourceAccount: Map.get(opts, :source, nil)
    }
  end

  def path_payment(opts) do
    cond do
      !StrKey.is_valid_ed25519_public_key(opts.destination) ->
        {:error, "destination is invalid"}

      !is_valid_amount(opts.dest_amount, false) ->
        {:error, "invalid dest_amount"}

      !is_valid_amount(opts.send_max, false) ->
        {:error, "invalid send_max"}

      true ->
        %__MODULE__{
          type: type_path_payment(),
          sendAsset: Map.get(opts, :send_asset),
          sendMax: Map.get(opts, :send_max),
          destination: Map.get(opts, :destination),
          destAsset: Map.get(opts, :dest_asset),
          destAmount: Map.get(opts, :dest_amount),
          path: Map.get(opts, :path),
          sourceAccount: Map.get(opts, :source, nil)
        }
    end
  end

  def payment(opts) do
    cond do
      !StrKey.is_valid_ed25519_public_key(opts.destination) ->
        {:error, "destination is invalid"}

      !is_valid_amount(opts.amount, false) ->
        {:error, "invalid amount"}

      true ->
        %__MODULE__{
          type: type_payment(),
          destination: Map.get(opts, :destination),
          asset: Map.get(opts, :asset),
          amount: Map.get(opts, :amount)
        }
    end
  end

  def set_options(opts) do
    %__MODULE__{
      type: "setOptions",
      inflationDest: Map.get(opts, :inflation_dest),
      clearFlags: Map.get(opts, :clear_flags),
      setFlags: Map.get(opts, :set_flags),
      masterWeight: Map.get(opts, :master_weight),
      lowThreshold: Map.get(opts, :low_threshold),
      medThreshold: Map.get(opts, :med_threshold),
      highThreshold: Map.get(opts, :high_threshold),
      signer: Map.get(opts, :signer),
      homeDomain: Map.get(opts, :home_domain)
    }
  end

  def account_id_to_address({_, nil}), do: nil

  def account_id_to_address({:PUBLIC_KEY_TYPE_ED25519, sourceaccount}) do
    sourceaccount |> StrKey.encode_ed25519_public_key()
  end

  def from_xdr(%{
        body: {:PAYMENT, %PaymentOp{} = payment_op}
      }) do
    %__MODULE__{
      type: type_payment(),
      destination: payment_op.destination |> account_id_to_address(),
      asset: payment_op.asset |> Asset.from_xdr(),
      amount: payment_op.amount |> from_xdr_amount()
    }
  end

  def from_xdr(%{
        body: {:CREATE_ACCOUNT, %CreateAccountOp{} = create_account_op}
      }) do
    %__MODULE__{
      type: type_create_account(),
      destination: create_account_op.destination |> account_id_to_address(),
      startingBalance: create_account_op.startingBalance |> from_xdr_amount()
    }
  end

  # @TODO: should there be a from_xdr_object? what's the difference
  # to this one?
  def from_xdr(%{
        body: {:ALLOW_TRUST, %AllowTrustOp{} = allow_trust_op}
      }) do
    %__MODULE__{
      type: type_allow_trust(),
      trustor: allow_trust_op.trustor |> account_id_to_address(),
      assetCode: allow_trust_op.asset |> AllowTrustAsset.from_xdr(),
      authorize: allow_trust_op.authorize
    }
  end

  def from_xdr(%{
        body: {:CHANGE_TRUST, %ChangeTrustOp{} = change_trust_op}
      }) do
    %__MODULE__{
      type: type_change_trust(),
      line: change_trust_op.line |> Asset.from_xdr(),
      limit: change_trust_op.limit
    }
  end

  def from_xdr(%{
        body: {:BUMP_SEQUENCE, %BumpSequenceOp{} = bump_sequence_op}
      }) do
    %__MODULE__{
      type: type_bump_sequence(),
      bumpTo: bump_sequence_op.bumpTo |> Integer.to_string()
    }
  end

  def from_xdr(%{
        body: {:PATH_PAYMENT, %PathPaymentOp{} = path_payment_op}
      }) do
    %__MODULE__{
      type: type_path_payment(),
      sendAsset: path_payment_op.sendAsset |> Asset.from_xdr(),
      sendMax: path_payment_op.sendMax |> from_xdr_amount(),
      destination: path_payment_op.destination |> account_id_to_address(),
      destAmount: path_payment_op.destinationAmount |> from_xdr_amount(),
      path: path_payment_op.path |> Enum.map(fn p -> p |> Asset.from_xdr() end),
      destAsset: path_payment_op.destinationAsset |> Asset.from_xdr()
    }
  end

  def to_xdr(%{type: type} = this) when type == type_payment() do
    with {:ok, destination} <-
           KeyPair.from_public_key(this.destination) |> KeyPair.to_xdr_accountid(),
         {:ok, payment_op} <-
           %PaymentOp{
             amount: this.amount |> to_xdr_amount,
             asset: this.asset |> Asset.to_xdr(),
             destination: destination
           }
           |> PaymentOp.new(),
         {:ok, payment_body} <- OperationBody.new({:PAYMENT, payment_op}),
         {:ok, operation} <-
           %XDROperation{body: payment_body}
           |> XDROperation.new() do
      operation
    else
      err -> err
    end
  end

  def to_xdr(%{type: type} = this) when type == type_create_account() do
    with {:ok, destination} <-
           KeyPair.from_public_key(this.destination) |> KeyPair.to_xdr_accountid(),
         {:ok, payment_op} <-
           %CreateAccountOp{
             destination: destination,
             startingBalance: this.startingBalance |> to_xdr_amount()
           }
           |> CreateAccountOp.new(),
         {:ok, payment_body} <- OperationBody.new({:CREATE_ACCOUNT, payment_op}),
         {:ok, operation} <- %XDROperation{body: payment_body} |> XDROperation.new() do
      operation
    else
      err -> err
    end
  end

  def to_xdr(%{type: type} = this) when type == type_allow_trust() do
    with {:ok, trustor} <- KeyPair.from_public_key(this.trustor) |> KeyPair.to_xdr_accountid(),
         {:ok, allow_trust_op} <-
           %AllowTrustOp{
             trustor: trustor,
             asset: this.asset |> AllowTrustAsset.to_xdr(),
             authorize: this.authorize
           }
           |> AllowTrustOp.new(),
         {:ok, allow_trust_body} <- OperationBody.new({:ALLOW_TRUST, allow_trust_op}),
         {:ok, operation} <- %XDROperation{body: allow_trust_body} |> XDROperation.new() do
      operation
    else
      err -> err
    end
  end

  def to_xdr(%{type: type} = this) when type == type_change_trust() do
    with {:ok, change_trust_op} <-
           %ChangeTrustOp{
             line: this.line |> Asset.to_xdr(),
             limit: this.limit
           }
           |> ChangeTrustOp.new(),
         {:ok, change_trust_body} <- OperationBody.new({:CHANGE_TRUST, change_trust_op}),
         {:ok, operation} <- %XDROperation{body: change_trust_body} |> XDROperation.new() do
      operation
    else
      err -> err
    end
  end

  def to_xdr(%{type: type} = this) when type == type_bump_sequence() do
    with {:ok, bump_to_op} <-
           %BumpSequenceOp{
             bumpTo: this.bumpTo |> String.to_integer()
           }
           |> BumpSequenceOp.new(),
         {:ok, allow_trust_body} <- OperationBody.new({:BUMP_SEQUENCE, bump_to_op}),
         {:ok, operation} <- %XDROperation{body: allow_trust_body} |> XDROperation.new() do
      operation
    else
      err -> err
    end
  end

  def to_xdr(%{type: type} = this) when type == type_path_payment() do
    with {:ok, destination} <-
           KeyPair.from_public_key(this.destination) |> KeyPair.to_xdr_accountid(),
         {:ok, path_payment_op} <-
           %PathPaymentOp{
             sendAsset: this.sendAsset |> Asset.to_xdr(),
             sendMax: this.sendMax |> to_xdr_amount,
             destination: destination,
             destinationAsset: this.destAsset |> Asset.to_xdr(),
             destinationAmount: this.destAmount |> to_xdr_amount,
             path: this.path |> Enum.map(fn p -> p |> Asset.to_xdr() end)
           }
           |> PathPaymentOp.new(),
         {:ok, allow_trust_body} <- OperationBody.new({:PATH_PAYMENT, path_payment_op}),
         {:ok, operation} <- %XDROperation{body: allow_trust_body} |> XDROperation.new() do
      operation
    else
      err -> err
    end
  end

  defp from_xdr_amount(value) do
    (value / unit()) |> Float.round(7)
  end

  defp to_xdr_amount(value) when is_float(value) do
    (value * unit()) |> Kernel.trunc()
  end

  defp to_xdr_amount(value) when is_integer(value) do
    value * unit()
  end

  def is_valid_amount(0, false), do: false
  def is_valid_amount(amount, _) when amount < 0, do: false
  def is_valid_amount(amount, _) when is_integer(amount), do: true

  def is_valid_amount(amount, _) when is_float(amount) do
    ((amount * unit()) |> Kernel.trunc()) / unit() == amount
  end
end
