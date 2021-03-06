defmodule CryptoWatchWeb.CryptoDashboardLive do
  use CryptoWatchWeb, :live_view
  alias CryptoWatch.Product
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CryptoWatch.PubSub, "navbar-actions")
    end

    {:ok,
     socket
     |> assign(products: [])
     |> assign(timezone: get_timezone_from_connection(socket))}
  end

  @impl true
  def handle_params(%{"products" => product_ids}, _uri, socket) do
    new_products = Enum.map(product_ids, &product_from_string/1)
    diff = List.myers_difference(socket.assigns.products, new_products)
    products_to_remove = diff |> Keyword.get_values(:del) |> List.flatten()
    products_to_insert = diff |> Keyword.get_values(:ins) |> List.flatten()

    socket =
      Enum.reduce(products_to_remove, socket, fn product, socket ->
        remove_product(socket, product)
      end)

    socket =
      Enum.reduce(products_to_insert, socket, fn product, socket ->
        add_product(socket, product)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    Logger.debug("Unhandled paramss: #{inspect(params)}")
    {:noreply, socket}
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
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.++([product_id])
      |> Enum.uniq()

    socket =
      push_patch(
        socket,
        to: Routes.live_path(socket, __MODULE__, products: product_ids)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, :trades, %{})}
  end

  @impl true
  def handle_event("remove-product", %{"product-id" => product_id}, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.--([product_id])
      |> Enum.uniq()

    socket =
      push_patch(
        socket,
        to: Routes.live_path(socket, __MODULE__, products: product_ids)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  defp add_product(socket, product) do
    CryptoWatch.subscribe_to_trades(product)

    case product in socket.assigns.products do
      true ->
        socket

      _ ->
        socket
        |> update(:products, &(&1 ++ [product]))
    end
  end

  defp remove_product(socket, product) do
    CryptoWatch.unsubscribe_to_trades(product)

    socket
    |> update(:products, &(&1 -- [product]))
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
