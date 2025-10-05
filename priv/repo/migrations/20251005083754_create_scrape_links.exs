defmodule AvcKoombeaWebscraper.Repo.Migrations.CreateScrapeLinks do
  use Ecto.Migration

  def change do
    create table(:scrape_links) do
      add :name, :string, null: false
      add :url, :string, null: false
      add :site_id, references(:scrape_sites, on_delete: :delete_all), null: false
      add :created_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:scrape_links, [:site_id])
  end
end
