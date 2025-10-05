defmodule AvcKoombeaWebscraper.Scrapes do
  @moduledoc """
  Context for scraped sites and their links.
  """
  import Ecto.Query, warn: false
  alias AvcKoombeaWebscraper.Repo

  alias AvcKoombeaWebscraper.Scrapes.{Site, Link}

  # ===== Sites =====

  def list_sites(opts \\ []) do
    query = from s in Site, order_by: [desc: s.inserted_at]
    query = maybe_paginate(query, opts)
    Repo.all(query)
  end

  def list_sites_with_link_counts(opts \\ []) do
    query =
      from s in Site,
        left_join: l in assoc(s, :links),
        group_by: s.id,
        order_by: [desc: s.inserted_at],
        select: {s, count(l.id)}

    query
    |> maybe_paginate(opts)
    |> Repo.all()
  end

  def count_sites, do: Repo.aggregate(Site, :count)

  def get_site!(id), do: Repo.get!(Site, id)
  def get_site_by_url(url), do: Repo.get_by(Site, url: url)

  def create_site(attrs \\ %{}) do
    %Site{}
    |> Site.changeset(attrs)
    |> Repo.insert()
  end

  def update_site(%Site{} = site, attrs) do
    site
    |> Site.changeset(attrs)
    |> Repo.update()
  end

  def delete_site(%Site{} = site), do: Repo.delete(site)

  def change_site(%Site{} = site, attrs \\ %{}), do: Site.changeset(site, attrs)

  # Convenience helpers to stamp times
  def mark_site_started(%Site{} = site, started_at \\ DateTime.utc_now()) do
    update_site(site, %{scrape_started_at: started_at})
  end

  def mark_site_finished(%Site{} = site, finished_at \\ DateTime.utc_now()) do
    update_site(site, %{scrape_finished_at: finished_at})
  end

  # ===== Links =====

  def list_links_for_site(site_id) do
    Repo.all(from l in Link, where: l.site_id == ^site_id, order_by: [asc: l.inserted_at])
  end

  def count_links_for_site(site_id) do
    Repo.aggregate(from(l in Link, where: l.site_id == ^site_id), :count)
  end

  def get_link!(id), do: Repo.get!(Link, id)

  def create_link(%Site{} = site, attrs) do
    %Link{}
    |> Link.changeset(Map.put(attrs, :site_id, site.id))
    |> Repo.insert()
  end

  def create_links(%Site{} = site, links) when is_list(links) do
    links
    |> Enum.map(&prepare_link_attrs(site, &1))
    |> Enum.map(&Link.changeset(%Link{}, &1))
    |> Enum.reduce(Ecto.Multi.new(), fn changeset, multi ->
      Ecto.Multi.insert(multi, {:link, Ecto.UUID.generate()}, changeset, on_conflict: :nothing)
    end)
    |> Repo.transaction()
  end

  def update_link(%Link{} = link, attrs) do
    link
    |> Link.changeset(attrs)
    |> Repo.update()
  end

  def delete_link(%Link{} = link), do: Repo.delete(link)

  def delete_links_for_site(site_id) do
    from(l in Link, where: l.site_id == ^site_id) |> Repo.delete_all()
  end

  # ===== Helpers =====

  defp prepare_link_attrs(site, %{url: _url} = attrs) do
    attrs
    |> Map.take([:url, :name])
    |> Map.put(:site_id, site.id)
    |> ensure_link_name()
  end

  defp prepare_link_attrs(site, url) when is_binary(url) do
    %{url: url, site_id: site.id, name: url}
  end

  defp ensure_link_name(%{url: url} = attrs) do
    name = Map.get(attrs, :name)

    sanitized_name =
      case name do
        nil -> url
        "" -> url
        value -> value
      end

    Map.put(attrs, :name, sanitized_name)
  end

  defp maybe_paginate(query, opts) do
    page = opts[:page] || 1
    page_size = opts[:page_size] || 20
    offset = (page - 1) * page_size
    query |> offset(^offset) |> limit(^page_size)
  end
end
