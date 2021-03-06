defmodule CryptoWatch do
  @moduledoc """
  CryptoWatch keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defdelegate subscribe_to_trades(product), to: CryptoWatch.Exchanges, as: :subscribe
  defdelegate unsubscribe_to_trades(product), to: CryptoWatch.Exchanges, as: :unsubscribe
  defdelegate get_last_trade(product), to: CryptoWatch.Historical
  defdelegate get_last_trades(product), to: CryptoWatch.Historical
  defdelegate available_products(), to: CryptoWatch.Exchanges
end
