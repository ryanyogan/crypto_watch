defmodule CryptoWatchWeb.ProductComponent do
  use CryptoWatchWeb, :live_component
  import CryptoWatchWeb.ProductHelpers

  @impl true
  def update(assigns, socket) do
    product = assigns.id

    socket =
      assign(socket,
        product: product,
        trade: CryptoWatch.get_last_trade(product)
      )

    {:ok, socket}
  end

  @impl true
  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <tr>
      <td class="w-1/4 px-6 py-4 whitespace-nowrap">
        <div class="flex items-center">
          <div class="flex-shrink-0 h-10 w-10">
            <img
              class="h-10 w-10 rounded-full"
              src="<%= crypto_icon(@socket, @product) %>"
              alt=""
            />
          </div>
          <div class="ml-4">
            <div class="text-sm font-medium text-gray-900">
              <span class="text-indigo-500 mr-1"><%= fiat_character(@product) %></span><%= to_price(@trade.price) %>
            </div>
            <div class="text-sm text-gray-500">
              <span class="text-indigo-500"><%= @trade.product.exchange_name %></span>
            </div>
          </div>
        </div>
      </td>
      <td class=" font-medium text-sm text-gray-700 px-6 py-6 whitespace-nowrap">
        <%= human_datetime(@trade.traded_at) %>
      </td>
      <td class="font-bold text-md text-indigo-900 px-6 py-6 whitespace-nowrap text-right">
        <button class="remove"
                phx-click="remove-product"
                phx-value-product-id="<%= to_string(@product) %>"
        >X</button>
      </td>
    </tr>
    """
  end

  @impl true
  def render(assigns) do
    ~L"""
    <tr>
      <td class="w-1/4 px-6 py-4 whitespace-nowrap">
        <div class="flex items-center">
          <div class="flex-shrink-0 h-10 w-10">
            <img
              class="h-10 w-10 rounded-full"
              src="<%= crypto_icon(@socket, @product) %>"
              alt=""
            />
          </div>
          <div class="ml-4">
            <div class="text-sm font-medium text-gray-900">
              <%= fiat_character(@product) %><span class="px-2 text-gray-400 font-medium font-xs">...</span>
            </div>
            <div class="text-sm text-gray-500">
              <span class="text-indigo-500"><%= @product.exchange_name %></span>
            </div>
          </div>
        </div>
      </td>
      <td class="font-medium text-gray-900 sm:inline-block px-6 py-6 whitespace-nowrap">
        <span class="px-2 text-gray-400 font-medium font-xs">awaiting updates...</span>
      </td>
    </tr>
    """
  end
end
