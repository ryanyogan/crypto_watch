defmodule CryptoWatchWeb.ProductController do
  use CryptoWatchWeb, :controller

  def index(conn, _params) do
    trades =
      CryptoWatch.available_products()
      |> CryptoWatch.get_last_trades()

    render(conn, "index.html", trades: trades)
  end
end
