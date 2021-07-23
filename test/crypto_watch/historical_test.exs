defmodule CryptoWatch.HistoricalTest do
  use ExUnit.Case, async: true
  alias CryptoWatch.{Historical, Exchanges, Product, Trade}

  setup :start_historical_with_trades_for_all_products

  describe "get_last_trades/2" do
    test "given a list of products, returns a list of most recent trades", %{
      hist_with_trades: historical
    } do
      products =
        Exchanges.available_products()
        |> Enum.shuffle()

      assert products ==
               historical
               |> Historical.get_last_trades(products)
               |> Enum.map(fn %Trade{product: p} -> p end)
    end

    test "nil in the returned list when the Historical doesn't have a trade for product",
         %{hist_with_trades: historical} do
      products = [
        Product.new("coinbase", "BTC-USD"),
        Product.new("coinbase", "invalid_pair"),
        Product.new("bitstamp", "btcusd")
      ]

      assert [%Trade{}, nil, %Trade{}] = Historical.get_last_trades(historical, products)
    end
  end

  defp all_products, do: Exchanges.available_products()

  defp build_valid_trade(product) do
    %Trade{
      product: product,
      traded_at: DateTime.utc_now(),
      price: "1000.00",
      volume: "0.10000"
    }
  end

  defp start_historical_with_trades_for_all_products(_ctx) do
    products = all_products()
    {:ok, hist} = Historical.start_link(products: products)
    Enum.each(products, &send(hist, {:new_trade, build_valid_trade(&1)}))
    [hist_with_trades: hist]
  end
end
