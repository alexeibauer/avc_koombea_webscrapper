defmodule AvcKoombeaWebscraper.Scrapes.Site do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scrape_sites" do
    field :url, :string
    field :title, :string
    field :scrape_started_at, :utc_datetime
    field :scrape_finished_at, :utc_datetime

    has_many :links, AvcKoombeaWebscraper.Scrapes.Link, foreign_key: :site_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:url, :title, :scrape_started_at, :scrape_finished_at])
    |> validate_required([:url])
    |> validate_length(:url, max: 2048)
    |> unique_constraint(:url)
  end
end
