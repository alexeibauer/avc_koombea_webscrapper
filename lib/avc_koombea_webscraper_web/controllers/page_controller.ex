defmodule AvcKoombeaWebscraperWeb.PageController do
  use AvcKoombeaWebscraperWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
