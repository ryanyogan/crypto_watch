defmodule CryptoWatch.Exchanges.CoinbaseClient do
  use GenServer
  alias CryptoWatch.{Trade, Product}
  @exchange_name "coinbase"

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
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "time", "price", "last_size"]),
         {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]

      {:ok,
       Trade.new(
         product: Product.new(@exchange_name, currency_pair),
         price: msg["price"],
         volume: msg["last_size"],
         traded_at: traded_at
       )}
    else
      {:error, _reason} = error -> error
    end
  end

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
