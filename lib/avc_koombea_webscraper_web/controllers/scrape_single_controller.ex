defmodule AvcKoombeaWebscraperWeb.ScrapeSingleController do
  use AvcKoombeaWebscraperWeb, :controller

  alias AvcKoombeaWebscraper.Scrapes

  def index(conn, %{"id" => id}) do
    case fetch_site(id) do
      {:ok, site} ->
        links = Scrapes.list_links_for_site(site.id)
        render(conn, :index, site: site, links: links)

      :error ->
        conn
        |> put_flash(:error, "Site not found")
        |> redirect(to: ~p"/scrape-home")
    end
  end

  def index(conn, _params) do
    conn
    |> put_flash(:error, "Site not specified")
    |> redirect(to: ~p"/scrape-home")
  end

  defp fetch_site(id) do
    id
    |> normalize_id()
    |> case do
      :error -> :error
      normalized -> safe_get_site(normalized)
    end
  end

  defp normalize_id(id) when is_integer(id), do: id

  defp normalize_id(id) do
    id
    |> to_string()
    |> Integer.parse()
    |> case do
      {int, ""} -> int
      _ -> :error
    end
  end

  defp safe_get_site(:error), do: :error
  defp safe_get_site(id) do
    {:ok, Scrapes.get_site!(id)}
  rescue
    Ecto.NoResultsError -> :error
  end
end
