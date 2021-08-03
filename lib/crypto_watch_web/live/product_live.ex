defmodule CryptoWatchWeb.ProductLive do
  use CryptoWatchWeb, :live_view
  import CryptoWatchWeb.ProductHelpers

  # @impl true
  # def mount(_params, _session, socket) do
  #   if connected?(socket) do
  #     :timer.send_interval(1_000, self(), :update)
  #   end

  #   labels = 0..1 |> Enum.to_list()
  #   values = Enum.map(labels, fn _ -> get_reading() end)

  #   {:ok,
  #    socket
  #    |> assign(
  #      chart_data: %{
  #        labels: labels,
  #        values: values
  #      },
  #      current_reading: List.last(labels)
  #    )}
  # end

  @impl true
  def mount(%{"id" => product_id}, _session, socket) do
    product = product_from_string(product_id)
    trade = CryptoWatch.get_last_trade(product)

    socket =
      assign(socket,
        product: product,
        product_id: product_id,
        trade: trade,
        page_title: page_title_from_trade(trade),
        chart_data: %{
          labels: [human_datetime(trade.traded_at)],
          values: [trade.price]
        },
        current_reading: human_datetime(trade.traded_at)
      )

    if connected?(socket) do
      # CryptoWatch.subscribe_to_trades(product)
      :timer.send_interval(1_000, self(), :update)
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
      <div class="shadow-lg m-2 sm:m-2">
        <div class="stat">
          <div id="charting">
            <div phx-update="ignore">
              <canvas id="chart-canvas"
                      phx-hook="LineChart"
                      data-chart-data="<%= Jason.encode!(@chart_data) %>">
              </canvas>
            </div>
            <div class="my-4">
              Total readings: <%= @current_reading %>
            </div>
          </div>
        </div>
      </div>
    """
  end

  @impl true
  def handle_info(:update, socket) do
    {:noreply, add_point(socket)}
  end

  defp add_point(socket) do
    product = product_from_string(socket.assigns.product_id)
    trade = CryptoWatch.get_last_trade(product)

    # socket = update(socket, :current_reading, &(&1 + 1))
    socket = assign(socket, :current_reading, human_datetime(trade.traded_at))

    point = %{
      label: socket.assigns.current_reading,
      value: trade.price
    }

    push_event(socket, "new-point", point)
  end

  defp get_reading do
    Enum.random(70..180)
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
      |> assign(:page_title, page_title_from_trade(trade))
      |> update(:trades, &[trade | &1])

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{trade.price}"
  end

  # defp get_trade_history do
  #   []
  # end
end
