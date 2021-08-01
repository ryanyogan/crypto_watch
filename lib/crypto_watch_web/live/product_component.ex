defmodule CryptoWatchWeb.ProductComponent do
  use CryptoWatchWeb, :live_component
  import CryptoWatchWeb.ProductHelpers

  @impl true
  def update(%{trade: trade} = _assigns, socket) when not is_nil(trade) do
    socket = assign(socket, :trade, trade)
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    product = assigns.id

    socket =
      assign(socket,
        product: product,
        trade: CryptoWatch.get_last_trade(product),
        timezone: assigns.timezone
      )

    {:ok, socket}
  end

  @impl true
  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
      <div class="shadow-md m-2 sm:m-2">
        <div class="stat">
          <div class="stat-figure">
            <div class="flex-shrink-0 h-10 w-10">
              <img
                class="h-10 w-10 rounded-full"
                src="<%= crypto_icon(@socket, @product) %>"
                alt=""
              />
            </div>
          </div>
          <div class="stat-title">
            <div class="text-sm font-medium text-gray-900">
              <%= crypto_name(@product) %> on
              <span class="text-indigo-500"><%= @product.exchange_name %></span>
            </div>
          </div>
          <div class="stat-value">
            <div class="text-md font-medium text-gray-900">
              <span class="text-indigo-500 my-1"><%= fiat_character(@product) %></span><%= to_price(@trade.price) %></span>
            </div>
          </div>
          <div class="stat-desc">
            <div class="text-sm font-medium text-gray-800">
              <%= human_datetime(@trade.traded_at, @timezone) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~L"""
      <div class="card shadow-2xl lg:card-side bg-primary text-primary-content m-2">
        <div class="card-body">
          <div class="shadow stats">
            <div class="stat">
              <div class="stat-figure">
                <div class="flex-shrink-0 h-10 w-10">
                  <img
                    class="h-10 w-10 rounded-full"
                    src="<%= crypto_icon(@socket, @product) %>"
                    alt=""
                  />
                </div>
              </div>
              <div class="stat-title">
                <div class="text-sm font-medium text-gray-900">
                  <%= crypto_name(@product) %> on
                  <span class="text-indigo-500"><%= @product.exchange_name %></span>
                </div>
              </div>
              <div class="stat-value">
                <div class="text-md font-medium text-gray-900">
                  <span class="text-indigo-500 my-1">....</span>
                </div>
              </div>
              <div class="stat-desc">
                <div class="text-sm font-medium text-gray-800">
                </div>
              </div>
            </div>
          </div>
          <div class="justify-end">
          </div>
        </div>
      </div>
    """
  end
end
