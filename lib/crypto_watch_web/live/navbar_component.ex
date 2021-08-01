defmodule CryptoWatchWeb.NavbarComponent do
  use CryptoWatchWeb, :live_component
  import CryptoWatchWeb.ProductHelpers

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(products: products_grouped_by_currency())}
  end

  @impl true
  def render(assigns) do
    ~L"""
      <div class="navbar mb-3 shadow-lg bg-gray-900 text-neutral-content">
        <div class="flex-1 px-2 mx-2">
          <p class="sm:text-2xl text-xl font-bold text-white">Crypto<span class="text-blue-500">Watch</span></p>
        </div>
        <div class="flex justify-end flex-1 px-2">
          <div class="flex items-stretch">
            <div class="dropdown dropdown-end">
              <div tabindex="0" class="btn btn-ghost rounded-btn text-xs sm:text-md">USD</div>
              <ul class="shadow-xl menu dropdown-content bg-base-100 w-40 text-gray-800">
                <%= for product <- @products["usd"] do %>
                  <li class="text-gray-800 font-semibold cursor-pointer text-xs sm:text-md">
                    <a href="#" phx-capture-click="add-product" phx-target="<%= @myself %>" phx-value-product-id="<%= to_string(product) %>"><span class="text-indigo-500 ml-1 mr-1"><%= crypto_short_name(product) %></span>on<span class="text-gray-800 ml-1 mr-1"> <%= product.exchange_name %></a></span>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
            <div class="dropdown dropdown-end">
              <div tabindex="0" class="btn btn-ghost rounded-btn text-xs sm:text-md">EUR</div>
              <ul class="shadow-xl menu dropdown-content bg-base-100 w-40 text-gray-800">
                <%= for product <- @products["eur"] do %>
                  <li class="text-gray-800 font-semibold cursor-pointer text-xs sm:text-md">
                    <a href="#" phx-capture-click="add-product" phx-target="<%= @myself %>" phx-value-product-id="<%= to_string(product) %>"><span class="text-indigo-500 ml-1 mr-1"><%= crypto_short_name(product) %></span>on<span class="text-gray-800 ml-1 mr-1"> <%= product.exchange_name %></a></span>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>
    """
  end

  @impl true
  def handle_event("add-product", %{"product-id" => id}, socket) do
    Phoenix.PubSub.broadcast(
      CryptoWatch.PubSub,
      "navbar-actions",
      {:add_product, id}
    )

    {:noreply, socket}
  end

  def products_grouped_by_currency do
    CryptoWatch.available_products()
    |> Enum.group_by(fn product -> fiat_symbol(product) end)
    |> IO.inspect()
  end
end
