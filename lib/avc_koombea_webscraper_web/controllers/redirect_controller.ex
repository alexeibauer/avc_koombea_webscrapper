defmodule AvcKoombeaWebscraperWeb.RedirectController do
  use AvcKoombeaWebscraperWeb, :controller

  def root(conn, _params) do
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      redirect(conn, to: ~p"/scrape-home")
    else
      redirect(conn, to: ~p"/users/register")
    end
  end
end
