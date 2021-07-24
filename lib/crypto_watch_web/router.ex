defmodule CryptoWatchWeb.Router do
  use CryptoWatchWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CryptoWatchWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CryptoWatchWeb do
    pipe_through :browser

    live "/", CryptoDashboardLive
    get "/products", ProductController, :index
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CryptoWatchWeb.Telemetry
    end
  end
end
