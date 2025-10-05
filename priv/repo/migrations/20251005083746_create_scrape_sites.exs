defmodule AvcKoombeaWebscraper.Repo.Migrations.CreateScrapeSites do
  use Ecto.Migration

  def change do
    create table(:scrape_sites) do
      add :url, :string, null: false
      add :title, :string
      add :scrape_started_at, :utc_datetime
      add :scrape_finished_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scrape_sites, [:url])
  end
end
