defmodule Stellar.Base.Network do
  defstruct _network_passphrase: nil

  @type t() :: %__MODULE__{
          _network_passphrase: String.t()
        }

  def networks,
    do: %{
      public: "Public Global Stellar Network ; September 2015",
      testnet: "Test SDF Network ; September 2015",
      local: "Integration Test Network ; zulucrypto"
    }

  def new(passphrase) do
    %__MODULE__{
      _network_passphrase: passphrase
    }
  end

  def use_public_network() do
    __MODULE__.new(networks().public)
  end

  def use_local_network() do
    __MODULE__.new(networks().local)
  end

  def use_test_network() do
    __MODULE__.new(networks().testnet)
  end

  @spec network_passphrase(t()) :: binary()
  def network_passphrase(this) do
    this._network_passphrase
  end

  def network_id(this) do
    :crypto.hash(:sha256, __MODULE__.network_passphrase(this))
  end
end
