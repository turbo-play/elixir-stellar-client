# Elixir SDK for Stellar

An improved [Stellar](https://stellar.org) SDK for [Elixir](https://elixir-lang.org/). This SDK was prepared by the [TurboPlay](https://turboplay.com) dev team as part of our contribution to the Stellar blockchain community. TurboPlay is developing the world's first personalized videogames marketplace with a rewarding loyalty system for players.

Elixir - now with Stellar transaction signing capability!

The SDK includes an XDR generator, which is used to encode/decode all communication with Stellar. We’re using an XDR elixir library, though with a few fixes (https://github.com/sunny-g/xdr). We hope XDR will also accept our changes upstream! We also have custom objects within the stellar sdk specific for all things stellar.

Please help us by taking a look at our SDK and let us know if you find any issues!

## Installation

The package can be installed
by adding `stellar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stellar, "~> 0.3.0"}
  ]
end
```

Add the following to your configuration:

```elixir
config :stellar, network: :public # Default is `:public`. To use test network, use `:test`
config :stellar, hackney_options: [] # Options to pass to Hackney
```

Quick example on how to create a transaction, sign it and post it to the Stellar Network.
```
    memo = Stellar.Base.Memo.text("100")

    account =
      Stellar.Base.Account.new(
        "GAPLA4LXBR3ABZBCXLMWKVWIST4TMVIGXMKNB6RG3E3STZ356V2WIE6X",
        "5737230198898695"
      )

    signer =
      Stellar.Base.KeyPair.from_secret("SA37TRR27NHLZJKWXOFNEBCNP5ZLKCGCDV7D565WBXYWDH3ACMHVIHMK")

    envelope =
      account
      |> Stellar.Base.TransactionBuilder.new(memo: memo)
      |> Stellar.Base.TransactionBuilder.add_operation(
        Stellar.Base.Operation.payment(%{
          destination: "GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW",
          asset: Asset.native(),
          amount: 600
        })
      )
      |> Stellar.Base.TransactionBuilder.set_timeout(100)
      |> Stellar.Base.TransactionBuilder.build()
      |> Stellar.Transaction.sign(signer)
      |> Stellar.Transaction.to_envelope()

    with {:ok, xdr_envelope} <-
           envelope |> Stellar.XDR.Types.Transaction.TransactionEnvelope.encode(),
         base64_envelope <- xdr_envelope |> Base.encode64(),
         {:ok, result} <- Stellar.Network.Transactions.post(base64_envelope) do
      {:ok, result}
    else
      err -> err
    end
```

Example result of a successful transaction:
```
{:ok,
 %{
   "_links" => %{
     "transaction" => %{
       "href" => "https://horizon-testnet.stellar.org/transactions/e77f2743c5c3322612c2315755f1f5828098a5c021c1ed8b21c63f2ad770184e"
     }
   },
   "envelope_xdr" => "AAAAAB6wcXcMdgDkIrrZZVbIlPk2VQa7FND6Jtk3Ked99XVkAAAAZAAUYfsAAAAIAAAAAQAAAAAAAAAAAAAAAF0451UAAAABAAAAAzEwMAAAAAABAAAAAAAAAAEAAAAAJOE07WrwVrBpxDdysR8ODocIttmSR1ovIZWpjeaZtE4AAAAAAAAAAAAAAlgAAAAAAAAAAX31dWQAAABAHmmmkMGnHWL0ND7LKIvLnGALnMeFquFJIyiJU/RUlk4AOkLEs0W4wQeQTYCtm3fBVzuwWTxvlMuI05e5UdXuAg==",
   "hash" => "e77f2743c5c3322612c2315755f1f5828098a5c021c1ed8b21c63f2ad770184e",
   "ledger" => 1461560,
   "result_meta_xdr" => "AAAAAQAAAAIAAAADABZNOAAAAAAAAAAAHrBxdwx2AOQiutllVsiU+TZVBrsU0Pom2Tcp5331dWQAAAAXSHbXmAAUYfsAAAAHAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAABABZNOAAAAAAAAAAAHrBxdwx2AOQiutllVsiU+TZVBrsU0Pom2Tcp5331dWQAAAAXSHbXmAAUYfsAAAAIAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAABAAAABAAAAAMAFk0hAAAAAAAAAAAk4TTtavBWsGnEN3KxHw4Ohwi22ZJHWi8hlamN5pm0TgAAABeEEb9IABRiWAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAFk04AAAAAAAAAAAk4TTtavBWsGnEN3KxHw4Ohwi22ZJHWi8hlamN5pm0TgAAABeEEcGgABRiWAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAMAFk04AAAAAAAAAAAesHF3DHYA5CK62WVWyJT5NlUGuxTQ+ibZNynnffV1ZAAAABdIdteYABRh+wAAAAgAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAFk04AAAAAAAAAAAesHF3DHYA5CK62WVWyJT5NlUGuxTQ+ibZNynnffV1ZAAAABdIdtVAABRh+wAAAAgAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
   "result_xdr" => "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA="
 }}
```
