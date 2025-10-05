defmodule AvcKoombeaWebscraper.Scrapes.Link do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scrape_links" do
    field :name, :string
    field :url, :string
    field :created_at, :utc_datetime

    belongs_to :site, AvcKoombeaWebscraper.Scrapes.Site,
      foreign_key: :site_id,
      references: :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:name, :url, :site_id])
    |> validate_required([:url, :site_id])
    |> validate_length(:url, max: 2048)
    |> foreign_key_constraint(:site_id)
    |> unique_constraint([:site_id])
  end
end
