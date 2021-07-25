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
    <div class="flex items-center justify-center bg-gray-900">
      <div class="col-span-12 mt-12">
        <div class="overflow-auto lg:overflow-visible ">
          <form action="#" phx-submit="add-product">
            <select name="product_id">
              <option selected disabled>Add a Crypto Product</option>
              <%= for product <- CryptoWatch.available_products() do %>
                <option value="<%= to_string(product) %>">
                  <%= product.exchange_name %> - <%= product.currency_pair %>
                </option>
              <% end %>
            </select>
            <button class="px-4 py-2 shaddow-lg rounded-lg text-gray-800 bg-gray-100">Add product</button>
          </form>

          <table class="table text-gray-300 border-separate space-y-6 text-sm">
            <thead class="bg-gray-800 text-gray-500">
              <tr>
                <th class="p-3">Crypto</th>
                <th class="p-3 text-left">Price</th>
                <th class="p-3 text-left">Volume</th>
                <th class="p-3 text-left">Status</th>
                <th class="p-3 text-left">Action</th>
              </tr>
            </thead>
            <tbody>
              <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
              <tr class="bg-gray-800">
                <td class="p-3">
                  <div class="flex align-items-center">
                    <img class="rounded-full h-12 w-12 object-cover" src="https://images.unsplash.com/photo-1613588718956-c2e80305bf61?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=634&q=80" alt="unsplash image">
                    <div class="ml-3">
                      <div class=""><%= trade.product.currency_pair %></div>
                      <div class="text-gray-500"><%= trade.product.exchange_name %></div>
                    </div>
                  </div>
                </td>
                <td class="p-3">
                  <%= trade.price %>
                </td>
                <td class="p-3 font-bold">
                  <%= trade.volume %>
                </td>
                <td class="p-3">
                  <span class="bg-green-400 text-gray-50 rounded-md px-2">available</span>
                </td>
                <td class="p-3 ">
                  <a href="#" class="text-gray-400 hover:text-gray-100 mr-2">
                    <i class="material-icons-outlined text-base">visibility</i>
                  </a>
                  <a href="#" class="text-gray-400 hover:text-gray-100  mx-2">
                    <i class="material-icons-outlined text-base">edit</i>
                  </a>
                  <a href="#" class="text-gray-400 hover:text-gray-100  ml-2">
                    <i class="material-icons-round text-base">delete_outline</i>
                  </a>
                </td>
              </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <style>
      .table {
        border-spacing: 0 15px;
      }

      i {
        font-size: 1rem !important;
      }

      .table tr {
        border-radius: 20px;
      }

      tr td:nth-child(n+5),
      tr th:nth-child(n+5) {
        border-radius: 0 .625rem .625rem 0;
      }

      tr td:nth-child(1),
      tr th:nth-child(1) {
        border-radius: .625rem 0 0 .625rem;
      }
    </style>
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