defmodule Stellar.Base.Network.Test do
  use ExUnit.Case, async: true

  describe "network use test" do
    test "switches to the test network" do
      network = Stellar.Base.Network.use_test_network()

      assert Stellar.Base.Network.network_passphrase(network) ==
               Stellar.Base.Network.networks().testnet
    end

    test "switches to the public network" do
      network = Stellar.Base.Network.use_public_network()

      assert Stellar.Base.Network.network_passphrase(network) ==
               Stellar.Base.Network.networks().public
    end

    test "switches to the local network" do
      network = Stellar.Base.Network.use_local_network()

      assert Stellar.Base.Network.network_passphrase(network) ==
               Stellar.Base.Network.networks().local
    end
  end
end
