defmodule AvcKoombeaWebscraperWeb.ScrapeHomeController do
  use AvcKoombeaWebscraperWeb, :controller

  alias AvcKoombeaWebscraper.Scrapes.SiteScraper

  def index(conn, _params) do
    render(conn, :index)
  end

  def create(conn, %{"url" => url}) do
    start_scrape_async(url)
    redirect(conn, to: ~p"/scrape-single")
  end

  defp start_scrape_async(url) when is_binary(url) do
    {:ok, agent} = Agent.start(fn -> %{status: :pending, url: url} end)

    Task.start(fn ->
      do_scrape(url, agent)
    end)

    :ok
  end

  defp do_scrape(url, agent) do
    IO.puts "AGENT STARTED SCRAPING #{url}"
    Agent.update(agent, &Map.put(&1, :status, :running))

    result = SiteScraper.run(url)

    Agent.update(agent, fn state ->
      Map.put(state, :status, if(result == :ok, do: :ok, else: :error))
    end)

    # Optional: read status if needed
    # final_state = Agent.get(agent, & &1)

    Agent.stop(agent)
    result
  end
end
