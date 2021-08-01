defmodule CryptoWatchWeb.NavbarComponent do
  use CryptoWatchWeb, :live_component
  import CryptoWatchWeb.ProductHelpers

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(products: CryptoWatch.available_products())}
  end

  @impl true
  def render(assigns) do
    ~L"""
      <div class="navbar mb-8 shadow-2xl bg-gray-900 text-neutral-content">
        <div class="flex-1 px-2 mx-2">
          <p class="sm:text-4xl text-xl font-bold text-gray-100">Crypto <span class="text-indigo-400">Watch</span></p>
        </div>
        <div class="flex justify-end flex-1 px-2">
          <div class="flex items-stretch">
            <div class="dropdown dropdown-end">
              <div tabindex="0" class="btn btn-ghost rounded-btn text-xs sm:text-md">Add Currencies</div>
              <ul class="shadow-xl menu dropdown-content bg-base-100 w-52 text-gray-800">
                <%= for product <- @products do %>
                  <li class="text-gray-800 font-semibold cursor-pointer">
                    <a href="#" phx-capture-click="add-product" phx-target="<%= @myself %>" phx-value-product-id="<%= to_string(product) %>"><%= crypto_name(product) %> - <%= fiat_character(product) %></a>
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
end
