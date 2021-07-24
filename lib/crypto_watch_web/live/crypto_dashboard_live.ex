defmodule CryptoWatchWeb.CryptoDashboardLive do
  use CryptoWatchWeb, :live_view
  alias CryptoWatch.Product

  @impl true
  def mount(_params, _session, socket) do
    # list of the products
    products = CryptoWatch.available_products()

    # trade list to a map %{Product.t() => Trade.t()}
    trades =
      products
      |> CryptoWatch.get_last_trades()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&{&1.product, &1})
      |> Enum.into(%{})

    if connected?(socket) do
      Enum.each(products, &CryptoWatch.subscribe_to_trades/1)
    end

    {:ok,
     socket
     |> assign(trades: trades, products: products)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <table>
      <thead>
        <th>Traded at</th>
        <th>Exchange</th>
        <th>Currency</th>
        <th>Price</th>
        <th>Volume</th>
      </thead>
      <tbody>
      <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
        <tr>
          <td><%= trade.traded_at %></td>
          <td><%= trade.product.exchange_name %></td>
          <td><%= trade.product.currency_pair %></td>
          <td><%= trade.price %></td>
          <td><%= trade.volume %></td>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket =
      update(socket, :trades, fn trades ->
        Map.put(trades, trade.product, trade)
      end)

    {:noreply, socket}
  end
end
