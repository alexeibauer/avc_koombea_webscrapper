defmodule AvcKoombeaWebscraperWeb.UserSessionHTML do
  use AvcKoombeaWebscraperWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:avc_koombea_webscraper, AvcKoombeaWebscraper.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
