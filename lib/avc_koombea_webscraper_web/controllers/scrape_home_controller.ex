defmodule AvcKoombeaWebscraperWeb.ScrapeHomeController do
  use AvcKoombeaWebscraperWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
