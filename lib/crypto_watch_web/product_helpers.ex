defmodule CryptoWatchWeb.ProductHelpers do
  def crypto_symbol(product),
    do: crypto_and_fiat_symbols(product).crypto_symbol

  def fiat_symbol(product),
    do: crypto_and_fiat_symbols(product).fiat_symbol

  def fiat_symbols,
    do: ["eur", "usd"]

  def crypto_name(product) do
    case crypto_and_fiat_symbols(product) do
      %{crypto_symbol: "btc"} -> "Bitcoin"
      %{crypto_symbol: "eth"} -> "Ethereum"
      %{crypto_symbol: "ltc"} -> "Litecoin"
    end
  end

  def fiat_character(product) do
    case crypto_and_fiat_symbols(product) do
      %{fiat_symbol: "usd"} -> "$"
      %{fiat_symbol: "eur"} -> "€"
    end
  end

  def to_price(price) do
    {price, _} = Float.parse(price)

    :erlang.float_to_binary(price, decimals: 2)
  end

  def crypto_icon(conn, product) do
    crypto_symbol = crypto_symbol(product)
    relative_path = Path.join("/images/cryptos", "#{crypto_symbol}.svg")
    CryptoWatchWeb.Router.Helpers.static_path(conn, relative_path)
  end

  def human_datetime(datetime, timezone \\ "UTC") do
    datetime
    |> DateTime.shift_zone!(timezone)
    |> Calendar.strftime("%I:%M:%S %p")
  end

  defp crypto_and_fiat_symbols(%{exchange_name: "coinbase"} = product) do
    [crypto_symbol, fiat_symbol] =
      product.currency_pair
      |> String.split("-")
      |> Enum.map(&String.downcase/1)

    %{crypto_symbol: crypto_symbol, fiat_symbol: fiat_symbol}
  end

  defp crypto_and_fiat_symbols(%{exchange_name: "bitstamp"} = product) do
    crypto_symbol = String.slice(product.currency_pair, 0..2)
    fiat_symbol = String.slice(product.currency_pair, 3..6)
    %{crypto_symbol: crypto_symbol, fiat_symbol: fiat_symbol}
  end
end
