defmodule CryptoWatch.Exchanges.BitstampClient do
  use GenServer
  alias CryptoWatch.{Trade, Product}
  @exchange_name "bitstamp"

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

  def server_host, do: 'ws.bitstamp.net'
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

  def handle_ws_message(%{"event" => "trade"} = msg, state) do
    # map a message to a Trade struct
    msg
    |> message_to_trade()
    |> IO.inspect(label: "Trade")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(%{"data" => data, "channel" => "live_trades_" <> currency_pair})
      when is_map(data) do
    with :ok <- validate_required(data, ["amount_str", "price_str", "timestamp"]),
         {:ok, traded_at} <- timestamp_to_datetime(data["timestamp"]) do
      {:ok,
       Trade.new(
         product: Product.new(@exchange_name, currency_pair),
         price: data["price_str"],
         volume: data["amount_str"],
         traded_at: traded_at
       )}
    else
      {:error, _reason} = error -> error
    end
  end

  def message_to_trade(_msg), do: {:error, :invalid_trade_message}

  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    required_key = Enum.find(keys, fn key -> is_nil(msg[key]) end)

    if is_nil(required_key),
      do: :ok,
      else: {:error, {required_key, :required}}
  end

  defp subscribe(state) do
    # subscription frames
    # send subscription frames to coinbase
    subscription_frames(state.currency_pairs)
    |> Enum.each(&:gun.ws_send(state.connection, &1))
  end

  defp subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame/1)
  end

  defp subscription_frame(currency_pair) do
    msg =
      %{
        "event" => "bts:subscribe",
        "data" => %{
          "channel" => "live_trades_#{currency_pair}"
        }
      }
      |> Jason.encode!()

    {:text, msg}
  end

  @spec timestamp_to_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, atom()}
  defp timestamp_to_datetime(ts) do
    case Integer.parse(ts) do
      {timestamp, _} ->
        DateTime.from_unix(timestamp)

      :error ->
        {:error, :invalid_timestamp_string}
    end
  end
end
