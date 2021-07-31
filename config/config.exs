use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :crypto_watch, CryptoWatchWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SPOB0F2xGU9OYQ/BJ7WEyaikdeIvOXBC6ZBPpordktGUpwju1NDgDhMezcYr+f4c",
  render_errors: [view: CryptoWatchWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: CryptoWatch.PubSub,
  live_view: [signing_salt: "okesrtCC"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"

import_config "appsignal.exs"
