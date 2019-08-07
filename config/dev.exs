use Mix.Config

config :stellar, network: :test

config :stellar, :test_account,
  public_key: System.get_env("STELLAR_PUBLIC_KEY"),
  secret: System.get_env("STELLAR_SECRET")
