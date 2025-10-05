defmodule AvcKoombeaWebscraperWeb.SiteProgressLive do
  use AvcKoombeaWebscraperWeb, :live_view

  alias AvcKoombeaWebscraper.Scrapes
  alias AvcKoombeaWebscraperWeb.Endpoint

  @impl true
  def mount(_params, %{"site_id" => site_id} = session, socket) do
    initial_link_count = Map.get(session, "initial_link_count")
    finished? = Map.get(session, "finished")

    socket =
      socket
      |> assign_new(:current_scope, fn -> nil end)
      |> assign(:site_id, normalize_site_id(site_id))
      |> assign(:link_count, parse_integer(initial_link_count, 0))
      |> assign(:finished?, parse_boolean(finished?, false))

    socket = maybe_subscribe(socket)

    {:ok, refresh_site(socket)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "site_links_updated", payload: %{site_id: site_id}},
        %{assigns: %{site_id: site_id}} = socket) do
    {:noreply, refresh_site(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @finished? do %>
      {@link_count}
    <% else %>
      <span class="italic text-slate-500">In progress...</span>
    <% end %>
    """
  end

  defp refresh_site(%{assigns: %{site_id: site_id}} = socket) do
    site = Scrapes.get_site!(site_id)
    link_count = Scrapes.count_links_for_site(site_id)

    socket
    |> assign(:link_count, link_count)
    |> assign(:finished?, not is_nil(site.scrape_finished_at))
  end

  defp maybe_subscribe(%{assigns: %{site_id: site_id}} = socket) do
    if connected?(socket) do
      Endpoint.subscribe(topic_for(site_id))
    end

    socket
  end

  defp topic_for(site_id), do: "site_scrape:#{site_id}"

  defp normalize_site_id(site_id) when is_integer(site_id), do: site_id

  defp normalize_site_id(site_id) do
    case Integer.parse(to_string(site_id)) do
      {int, ""} -> int
      _ -> raise ArgumentError, "invalid site id"
    end
  end

  defp parse_integer(nil, default), do: default

  defp parse_integer(value, default) do
    case Integer.parse(to_string(value)) do
      {int, ""} -> int
      _ -> default
    end
  end

  defp parse_boolean(nil, default), do: default
  defp parse_boolean(true, _default), do: true
  defp parse_boolean(false, _default), do: false

  defp parse_boolean(value, default) do
    value
    |> to_string()
    |> String.downcase()
    |> case do
      "true" -> true
      "false" -> false
      _ -> default
    end
  end
end
