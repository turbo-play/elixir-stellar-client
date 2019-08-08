defmodule StellarTest do
  use ExUnit.Case, async: true
  doctest Stellar

  test "shows current network" do
    Application.put_env(:stellar, :network, :test)

    assert Stellar.current_network() |> Stellar.Network.Base.network_passphrase() =~
             "Test SDF Network ; September 2015"
  end
end
