defmodule Stellar.Network.Accounts.Test do
  use Stellar.HttpCase
  alias Stellar.Network.Accounts

  setup do
    account_response = '''
    {
      "_links": {
        "self": {
          "href": "https://horizon-testnet.stellar.org/accounts/GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS"
        },
        "transactions": {
          "href": "https://horizon-testnet.stellar.org/accounts/GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS/transactions{?cursor,limit,order}",
          "templated": true
        },
        "operations": {
          "href": "https://horizon-testnet.stellar.org/accounts/GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS/operations{?cursor,limit,order}",
          "templated": true
        },
        "payments": {
          "href": "https://horizon-testnet.stellar.org/accounts/GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS/payments{?cursor,limit,order}",
          "templated": true
        },
        "effects": {
          "href": "https://horizon-testnet.stellar.org/accounts/GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS/effects{?cursor,limit,order}",
          "templated": true
        },
        "offers": {
          "href": "https://horizon-testnet.stellar.org/accounts/GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS/offers{?cursor,limit,order}",
          "templated": true
        }
      },
      "id": "GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS",
      "paging_token": "5387216134082561",
      "account_id": "GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS",
      "sequence": "5387216134078475",
      "subentry_count": 5,
      "thresholds": {
        "low_threshold": 0,
        "med_threshold": 0,
        "high_threshold": 0
      },
      "flags": {
        "auth_required": false,
        "auth_revocable": false
      },
      "balances": [
        {
          "balance": "0.0000000",
          "limit": "922337203685.4775807",
          "asset_type": "credit_alphanum4",
          "asset_code": "AAA",
          "asset_issuer": "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
        },
        {
          "balance": "5000.0000000",
          "limit": "922337203685.4775807",
          "asset_type": "credit_alphanum4",
          "asset_code": "MDL",
          "asset_issuer": "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
        },
        {
          "balance": "10000.0000000",
          "limit": "922337203685.4775807",
          "asset_type": "credit_alphanum4",
          "asset_code": "USD",
          "asset_issuer": "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
        },
        {
          "balance": "70.0998900",
          "asset_type": "native"
        }
      ],
      "signers": [
        {
          "public_key": "GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS",
          "weight": 1
        }
      ],
      "data": {}
    }
    '''

    %{
      account_response: account_response,
      pub_key: "GBAH7FQMC3CZJ4WD6GE7G7YXCIU36LC2IHXQ7D5MQAUO4PODOWIVLSFS"
    }
  end

  test "get account details", %{bypass: bypass, account_response: account_response, pub_key: pk} do
    Bypass.expect_once(
      bypass,
      "GET",
      "/accounts/" <> pk,
      fn conn ->
        Plug.Conn.resp(conn, 200, account_response)
      end
    )

    assert {:ok, %{"id" => pk}} = Accounts.get(pk)
  end

  test "get account data", %{bypass: bypass, account_response: account_response, pub_key: pk} do
    Bypass.expect_once(bypass, "GET", "/accounts/" <> pk, fn conn ->
      Plug.Conn.resp(conn, 200, account_response)
    end)

    assert {:ok,
            %{
              "id" => pk,
              "subentry_count" => 5,
              "_links" => %{
                "transactions" => tx,
                "operations" => op,
                "payments" => payments,
                "effects" => effects,
                "offers" => offers
              },
              "sequence" => "5387216134078475"
            }} = Accounts.get(pk)
  end
end
