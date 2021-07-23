defmodule CryptoWatch.Exchanges.CoinbaseClient do
  use GenServer

  def start_link(currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  @impl true
  def init(currency_pairs) do
    state = %{
      currency_pairs: currency_pairs,
      connection: nil
    }

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    updated_state = connect(state)
    {:noreply, updated_state}
  end

  def server_host, do: 'ws-feed.pro.coinbase.com'
  def server_port, do: 443

  def connect(state) do
    {:ok, connection} = :gun.open(server_host(), server_port(), %{protocols: [:http]})
    %{state | connection: connection}
  end

  @impl true
  def handle_info({:gun_up, connection, :http}, %{connection: connection} = state) do
    :gun.ws_upgrade(connection, "/")
    {:noreply, state}
  end

  def handle_info(
        {:gun_upgrade, connection, _ref, ["websocket"], _headers},
        %{connection: connection} = state
      ) do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, connection, _ref, {:text, msg}}, %{connection: connection} = state) do
    Jason.decode!(msg)
    |> handle_ws_message(state)
  end

  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    IO.inspect(msg, label: "ticker")
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  defp subscribe(state) do
    # subscription frames
    # send subscription frames to coinbase
    subscription_frames(state.currency_pairs)
    |> Enum.each(&:gun.ws_send(state.connection, &1))
  end

  def subscription_frames(currency_pairs) do
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end
end
