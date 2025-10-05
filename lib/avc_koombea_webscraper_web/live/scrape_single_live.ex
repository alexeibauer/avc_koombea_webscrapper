defmodule AvcKoombeaWebscraperWeb.ScrapeSingleLive do
  use AvcKoombeaWebscraperWeb, :live_view

  alias AvcKoombeaWebscraper.Scrapes
  alias AvcKoombeaWebscraper.Scrapes.Site
  alias AvcKoombeaWebscraperWeb.Endpoint

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    with {:ok, site} <- fetch_site(id) do
      links = Scrapes.list_links_for_site(site.id)
      topic = topic_for(site)

      socket =
        socket
        |> assign_new(:current_scope, fn -> nil end)
        |> assign(:site, site)
        |> assign(:links_empty?, links == [])
        |> assign(:page_title, page_title(site))
        |> stream(:links, links, reset: true)
        |> maybe_subscribe(topic)

      {:ok, socket}
    else
      :error ->
        {:ok,
         socket
         |> put_flash(:error, "Site not found")
         |> push_navigate(to: ~p"/scrape-home")}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "site_links_updated", payload: %{site_id: site_id}},
        %{assigns: %{site: %{id: site_id}}} = socket) do
    site = Scrapes.get_site!(site_id)
    links = Scrapes.list_links_for_site(site_id)

    {:noreply,
     socket
      |> assign(:site, site)
      |> assign(:page_title, page_title(site))
      |> assign(:links_empty?, links == [])
      |> stream(:links, links, reset: true)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp fetch_site(id) do
    case normalize_id(id) do
      :error -> :error
      site_id -> safe_get_site(site_id)
    end
  end

  defp normalize_id(id) when is_integer(id), do: id

  defp normalize_id(id) do
    id
    |> to_string()
    |> Integer.parse()
    |> case do
      {int, ""} when int > 0 -> int
      _ -> :error
    end
  end

  defp safe_get_site(:error), do: :error

  defp safe_get_site(id) do
    {:ok, Scrapes.get_site!(id)}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp topic_for(%Site{id: site_id}), do: "site_scrape:#{site_id}"

  defp page_title(%Site{title: nil, url: url}), do: url
  defp page_title(%Site{title: "", url: url}), do: url
  defp page_title(%Site{title: title}), do: title

  defp maybe_subscribe(socket, topic) do
    if connected?(socket) do
      Endpoint.subscribe(topic)
    end

    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scrape-container">

        <div class="mb-4">
          <.link navigate={~p"/scrape-home"} class="text-sm text-blue-600 underline" id="back-to-scrape-home">
            &larr; Back
          </.link>
        </div>

        <h1 class="text-2xl font-semibold">Scrape Detail</h1>

        <div class="mt-4 space-y-2">
          <p class="text-sm text-slate-600 w-text">
            <span class="font-medium text-slate-800 w-text">Title:</span>
            {page_title(@site)}
          </p>
          <p class="text-sm text-slate-600 w-text">
            <span class="font-medium text-slate-800 w-text">URL:</span>
            {@site.url}
          </p>
        </div>

        <div class="mt-6">
          <table class="min-w-full divide-y divide-slate-200" id="scrape-links-table">
            <thead class="bg-slate-100">
              <tr>
                <th scope="col" class="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">Name</th>
                <th scope="col" class="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">URL</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 bg-white" phx-update="stream" id="links">
              <tr :for={{id, link} <- @streams.links} id={id}>
                <td class="px-4 py-3 text-sm text-slate-800">
                  {link.name || link.url}
                </td>
                <td class="px-4 py-3 text-sm text-blue-600">
                  <.link href={link.url} target="_blank" rel="noopener noreferrer" class="underline">
                    {link.url}
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
          <p :if={@links_empty?} class="mt-3 flex items-center gap-2 text-sm text-slate-500 w-text" id="links-empty">
            <img src={~p"/images/loading.gif"} alt="Loading" class="h-5 w-5" />
            In progress: Discovering links. This page will automatically update when all links for this site are discovered.
          </p>
        </div>

    </div>
    """
  end
end
