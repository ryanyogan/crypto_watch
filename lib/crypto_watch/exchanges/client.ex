defmodule CryptoWatch.Exchanges.Client do
  use GenServer

  @type t() :: %__MODULE__{
          module: module(),
          connection: pid(),
          connection_reference: reference(),
          currency_pairs: [String.t()]
        }

  defstruct [
    :module,
    :connection,
    :connection_reference,
    :currency_pairs
  ]

  @callback exchange_name() :: String.t()
  @callback server_host() :: list()
  @callback server_port() :: integer()
  @callback subscription_frames([String.t()]) :: [{:text, String.t()}]
  @callback handle_ws_message(map(), any()) :: any()

  defmacro defclient(options) do
    exchange_name = Keyword.fetch!(options, :exchange_name)
    host = Keyword.fetch!(options, :host)
    port = Keyword.fetch!(options, :port)
    currency_pairs = Keyword.fetch!(options, :currency_pairs)
    client_module = __MODULE__

    quote do
      @behaviour unquote(client_module)
      import unquote(client_module), only: [validate_required: 2]
      require Logger

      @spec available_currency_pairs() :: [String.t()]
      def available_currency_pairs, do: unquote(currency_pairs)
      def exchange_name, do: unquote(exchange_name)
      def server_host, do: unquote(host)
      def server_port, do: unquote(port)

      def handle_ws_message(msg, state) do
        Logger.debug("handle_ws_message: #{inspect(msg)}")
        {:noreply, state}
      end

      def child_spec(opts) do
        {currency_pairs, opts} = Keyword.pop(opts, :currency_pairs, available_currency_pairs())

        %{
          id: __MODULE__,
          start: {unquote(__MODULE__), :start_link, [__MODULE__, currency_pairs, opts]}
        }
      end

      defoverridable handle_ws_message: 2
    end
  end

  @spec start_link(module(), [String.t()], Keyword.t()) :: GenServer.on_start()
  def start_link(module, currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, {module, currency_pairs}, options)
  end

  @impl true
  def init({module, currency_pairs}) do
    client = %__MODULE__{
      module: module,
      currency_pairs: currency_pairs
    }

    {:ok, client, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, client) do
    {:noreply, connect(client)}
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

  @spec connect(t()) :: t()
  def connect(client) do
    host = server_host(client.module)
    port = server_port(client.module)
    {:ok, connection} = :gun.open(host, port, %{protocols: [:http]})
    # Since we aren't spawning a GenServer, we need to monitor the process
    connection_reference = Process.monitor(connection)

    %{client | connection: connection, connection_reference: connection_reference}
  end

  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    required_key = Enum.find(keys, fn key -> is_nil(msg[key]) end)

    if is_nil(required_key),
      do: :ok,
      else: {:error, {required_key, :required}}
  end

  @spec server_host(module()) :: list()
  defp server_host(module), do: module.server_host()

  @spec server_port(module()) :: integer()
  defp server_port(module), do: module.server_port()

  @spec subscribe(t()) :: any()
  defp subscribe(client) do
    subscription_frames(client.module, client.currency_pairs)
    |> Enum.each(&:gun.ws_send(client.connection, &1))
  end

  @spec subscription_frames(module(), [String.t()]) :: [{:text, String.t()}]
  defp subscription_frames(module, currency_pairs) do
    module.subscription_frames(currency_pairs)
  end

  @spec handle_ws_message(map(), t()) :: {:noreply, t()}
  defp handle_ws_message(msg, client) do
    module = client.module
    module.handle_ws_message(msg, client)
  end
end
