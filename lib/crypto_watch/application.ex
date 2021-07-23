defmodule CryptoWatch.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      CryptoWatchWeb.Telemetry,
      {Phoenix.PubSub, name: CryptoWatch.PubSub},
      {CryptoWatch.Historical, name: CryptoWatch.Historical},
      CryptoWatchWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CryptoWatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    CryptoWatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
