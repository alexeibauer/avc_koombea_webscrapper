defmodule AvcKoombeaWebscraperWeb.ScrapeHomeController do
  use AvcKoombeaWebscraperWeb, :controller

  alias AvcKoombeaWebscraper.Scrapes
  alias AvcKoombeaWebscraper.Scrapes.SiteScraper
  alias AvcKoombeaWebscraper.Scrapes.Site

  def index(conn, params) do
    page_size = 10
    total_sites = Scrapes.count_sites()
    total_pages = max(div(total_sites + page_size - 1, page_size), 1)
    requested_page = parse_page(Map.get(params, "page"))
    page = clamp_page(requested_page, total_pages)

    sites =
      Scrapes.list_sites_with_link_counts(page: page, page_size: page_size)
      |> Enum.map(fn {site, link_count} ->
        %{
          id: site.id,
          title: site.title,
          url: site.url,
          link_count: link_count,
          scrape_finished_at: site.scrape_finished_at
        }
      end)

    render(conn, :index,
      sites: sites,
      page: page,
      total_pages: total_pages,
      total_sites: total_sites,
      page_size: page_size
    )
  end

  def create(conn, %{"url" => url}) do
    url = String.trim(url)

    case ensure_site(url) do
      {:ok, site, started?} ->
        if started?, do: start_scrape_async(site)

        redirect(conn, to: ~p"/scrape-single/#{site.id}")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Unable to schedule scrape: #{humanize_errors(changeset)}")
        |> redirect(to: ~p"/scrape-home")
    end
  end

  defp start_scrape_async(%Site{} = site) do
    {:ok, agent} = Agent.start(fn -> %{status: :pending, site_id: site.id, url: site.url} end)

    Task.start(fn ->
      do_scrape(site, agent)
    end)

    :ok
  end

  defp do_scrape(%Site{} = site, agent) do
    Agent.update(agent, &Map.put(&1, :status, :running))

    result = SiteScraper.run(site)

    Agent.update(agent, fn state ->
      Map.put(state, :status, if(result == :ok, do: :ok, else: :error))
    end)

    # Optional: read status if needed
    # final_state = Agent.get(agent, & &1)
    Agent.stop(agent)
    result
  end

  defp ensure_site(url) do
    case Scrapes.get_site_by_url(url) do
      %Site{} = site -> {:ok, site, false}
      nil ->
        case Scrapes.create_site(%{url: url}) do
          {:ok, site} -> {:ok, site, true}
          {:error, changeset} ->
            case Scrapes.get_site_by_url(url) do
              %Site{} = existing -> {:ok, existing, false}
              nil -> {:error, changeset}
            end
        end
    end
  end

  defp humanize_errors(changeset) do
    message =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
      |> Enum.map(fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
      |> Enum.join(", ")

    if message == "" do
      "unknown error"
    else
      message
    end
  end

  defp parse_page(nil), do: 1

  defp parse_page(value) do
    case Integer.parse(to_string(value)) do
      {int, ""} when int > 0 -> int
      _ -> 1
    end
  end

  defp clamp_page(page, total_pages) do
    page
    |> max(1)
    |> min(total_pages)
  end
end
