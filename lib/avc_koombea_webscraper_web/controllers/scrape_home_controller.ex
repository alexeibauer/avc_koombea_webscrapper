defmodule AvcKoombeaWebscraperWeb.ScrapeHomeController do
  use AvcKoombeaWebscraperWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def create(conn, %{"url" => url}) do
    # your logic here
    IO.puts("Scraping: #{url}")
    redirect(conn, to: ~p"/scrape-single")
  end
end
