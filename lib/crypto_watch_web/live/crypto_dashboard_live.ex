defmodule CryptoWatchWeb.CryptoDashboardLive do
  use CryptoWatchWeb, :live_view
  alias CryptoWatch.Product

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(trades: %{}, products: [])}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="flex gap-x-2">
      <form action="#" phx-change="add-product">
        <select name="product_id" class="mt-1 block w-full rounded-sm border-gray-300 shadow-lg focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
          <option selected disabled>Add a Crypto Product</option>
          <%= for product <- CryptoWatch.available_products() do %>
            <option value="<%= to_string(product) %>">
              <%= product.exchange_name %> - <%= product.currency_pair %>
            </option>
          <% end %>
        </select>
      </form>
    </div>

    <div class="mt-2 flex flex-col">
      <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-y">
          <div class="shadow overflow-hidden  shadow-sm sm:rounded-sm">
            <table class="min-w-full divide-y divid-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="w-1/4 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Crypto</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                  <th class=" hidden sm:inline-block px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Volume</th>
                  <th class=" hidden sm:inline-block px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Traded At</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
                <tr>
                  <td class="w-1/4 px-6 py-4 whitespace-nowrap">
                    <%= trade.product.currency_pair %>
                    <%= trade.product.exchange_name %>
                  </td>
                  <td class="w-1/4 px-6 py-4 whitespace-nowrap">
                    <%= trade.price %>
                  </td>
                  <td class="w-1/4 hidden sm:inline-block px-6 py-4 whitespace-nowrap">
                    <%= trade.volume %>
                  </td>
                  <td class="w-1/4 hidden sm:inline-block px-6 py-4 whitespace-nowrap">
                    <%= trade.traded_at %>
                  </td>
                </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
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

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, :trades, %{})}
  end

  @impl true
  def handle_event("add-product", %{"product_id" => product_id}, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      add_product(socket, product)
    else
      socket
    end
  end

  defp add_product(socket, product) do
    CryptoWatch.subscribe_to_trades(product)

    socket
    |> update(:products, fn products -> products ++ [product] end)
    |> update(:trades, fn trades ->
      trade = CryptoWatch.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
  end
end
