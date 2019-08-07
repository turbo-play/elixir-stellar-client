defmodule Stellar.NetworkConfig do
  # https://github.com/stellar/js-stellar-base/blob/master/src/account.js
  alias Stellar.{Account, KeyPair, StrKey, NetworkConfig}

  @networks %{
    public: "Public Global Stellar Network ; September 2015",
    testnet: "Test SDF Network ; September 2015",
    local: "Integration Test Network ; zulucrypto"
  }

  defstruct _network_passphrase: nil

  def new(passphrase) do
    %NetworkConfig{
      _network_passphrase: passphrase
    }
  end

  def current() do
    Application.get_env(:stellar, :network, :public) |> NetworkConfig.use_network()
  end

  def use_public_network() do
    NetworkConfig.new(@networks.public)
  end

  def use_local_network() do
    NetworkConfig.new(@networks.local)
  end

  def use_test_network() do
    NetworkConfig.new(@networks.testnet)
  end

  def use_network(_), do: NetworkConfig.use_test_network()
  def use_network(:local), do: NetworkConfig.use_local_network()
  def use_network(:public), do: NetworkConfig.use_public_network()

  def network_passphrase(this) do
    this._network_passphrase
  end

  def network_id(this) do
    :crypto.hash(:sha256, this |> NetworkConfig.network_passphrase())
  end
end
