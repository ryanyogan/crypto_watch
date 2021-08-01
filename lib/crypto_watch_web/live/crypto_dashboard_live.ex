defmodule CryptoWatchWeb.CryptoDashboardLive do
  use CryptoWatchWeb, :live_view
  alias CryptoWatch.Product

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CryptoWatch.PubSub, "navbar-actions")
    end

    {:ok,
     socket
     |> assign(trades: %{}, products: [])
     |> assign(timezone: get_timezone_from_connection(socket))}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 lg:gap-6">
      <%= for product <- @products do %>
        <%= live_component @socket, CryptoWatchWeb.ProductComponent, id: product, timezone: @timezone %>
      <% end %>
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
  def handle_info({:add_product, product_id}, socket) do
    product = product_from_string(product_id)

    socket =
      socket
      |> maybe_add_product(product)
      |> update_product_params()

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, :trades, %{})}
  end

  @impl true
  def handle_event("remove-product", %{"product-id" => product_id}, socket) do
    product = product_from_string(product_id)

    socket =
      socket
      |> update(:products, &List.delete(&1, product))
      |> update_product_params()

    {:noreply, socket}
  end

  @impl true
  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  defp update_product_params(socket) do
    product_ids = Enum.map(socket.assigns.products, &to_string/1)
    push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))
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

  # defp grouped_products_by_exchange_name do
  #   CryptoWatch.available_products()
  #   |> Enum.group_by(& &1.exchange_name)
  # end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
