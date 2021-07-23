defmodule CryptoWatch.Historical do
  use GenServer
  alias CryptoWatch.{Product, Trade, Exchanges}

  @type t() :: %__MODULE__{
          products: [Product.t()],
          trades: %{Product.t() => Trade.t()}
        }

  defstruct [:products, :trades]

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    {products, opts} = Keyword.pop(opts, :products, [])
    GenServer.start_link(__MODULE__, products, opts)
  end

  @spec get_last_trade(pid() | atom(), Product.t()) :: Trade.t() | nil
  def get_last_trade(pid \\ __MODULE__, product) do
    GenServer.call(pid, {:get_last_trade, product})
  end

  @spec get_last_trades(pid() | atom(), [Product.t()]) :: [Trade.t() | nil]
  def get_last_trades(pid \\ __MODULE__, product) do
    GenServer.call(pid, {:get_last_trades, product})
  end

  @impl true
  def init(products) do
    historical = %__MODULE__{products: products, trades: %{}}
    {:ok, historical, {:continue, :subscribe}}
  end

  @impl true
  def handle_continue(:subscribe, historical) do
    Enum.each(historical.products, &Exchanges.subscribe/1)
    {:noreply, historical}
  end

  @impl true
  def handle_info({:new_trade, trade}, historical) do
    updated_trades = Map.put(historical.trades, trade.product, trade)
    updated_historical = %{historical | trades: updated_trades}
    {:noreply, updated_historical}
  end

  @impl true
  def handle_call({:get_last_trade, product}, _from, historical) do
    trade = Map.get(historical.trades, product)
    {:reply, trade, historical}
  end

  @impl true
  def handle_call({:get_last_trades, products}, _from, historical) do
    trades = Enum.map(products, &Map.get(historical.trades, &1))
    {:reply, trades, historical}
  end
end
