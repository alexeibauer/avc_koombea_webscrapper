defmodule AvcKoombeaWebscraper.Repo do
  use Ecto.Repo,
    otp_app: :avc_koombea_webscraper,
    adapter: Ecto.Adapters.SQLite3
end
