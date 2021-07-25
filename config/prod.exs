use Mix.Config

config :crypto_watch, CryptoWatchWeb.Endpoint,
  url: [host: "leafy-crafty-bellfrog.gigalixirapp.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

import_config "prod.secret.exs"
