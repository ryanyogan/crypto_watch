defmodule CryptoWatchWeb.ProductLive do
  use CryptoWatchWeb, :live_view
  import CryptoWatchWeb.ProductHelpers

  @impl true
  def mount(%{"id" => product_id}, _session, socket) do
    product = product_from_string(product_id)
    trade = CryptoWatch.get_last_trade(product)

    socket =
      assign(socket,
        product: product,
        product_id: product_id,
        trade: trade,
        page_title: page_title_from_trade(trade)
      )

    if connected?(socket) do
      CryptoWatch.subscribe_to_trades(product)
    end

    {:ok, socket}
  end

  @impl true
  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> - <%= @trade.price %></h1>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> ...</h1>
    </div>
    """
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
      |> assign(:page_title, page_title_from_trade(trade))

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{trade.price}"
  end
end
