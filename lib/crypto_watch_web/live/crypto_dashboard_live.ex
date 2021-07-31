defmodule CryptoWatchWeb.CryptoDashboardLive do
  use CryptoWatchWeb, :live_view
  alias CryptoWatch.Product
  import CryptoWatchWeb.ProductHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(trades: %{}, products: [])
     |> assign(timezone: get_timezone_from_connection(socket))}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="flex flex-wrap justify-center">
      <%= for product <- @products do %>
        <%= live_component @socket, CryptoWatchWeb.ProductComponent, id: product, timezone: @timezone %>
      <% end %>
    </div>

    <div class="shadow-xl bg-white">
      <div class="card-body">
        <form action="#" phx-submit="add-product">
          <select name="product_id" class="mt-1 block w-full rounded-md border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
            <option selected disabled>Currencies</option>
            <%= for {exchange_name, products} <- grouped_products_by_exchange_name() do %>
              <optgroup label="<%= exchange_name %>">
                <%= for product <- products do %>
                  <option value="<%= to_string(product) %>">
                    <%= crypto_name(product) %> - <%= fiat_character(product) %>
                  </option>
                <% end %>
              </optgroup>
            <% end %>
          </select>
          <button type="submit" class="mt-1 shadow-lg hover:bg-indigo-400 text-white font-semibold bg-indigo-500 py-2 block w-full border-gray-900 rounded-md border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">Add</button>
        </form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    send_update(
      CryptoWatchWeb.ProductComponent,
      id: trade.product,
      trade: trade
    )

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

  @impl true
  def handle_event("remove-product", %{"product-id" => product_id}, socket) do
    product = product_from_string(product_id)
    socket = update(socket, :products, &List.delete(&1, product))
    {:noreply, socket}
  end

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
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

  defp grouped_products_by_exchange_name do
    CryptoWatch.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
