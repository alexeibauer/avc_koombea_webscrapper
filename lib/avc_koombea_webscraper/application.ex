defmodule AvcKoombeaWebscraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AvcKoombeaWebscraperWeb.Telemetry,
      AvcKoombeaWebscraper.Repo,
      {DNSCluster, query: Application.get_env(:avc_koombea_webscraper, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AvcKoombeaWebscraper.PubSub},
      # Start a worker by calling: AvcKoombeaWebscraper.Worker.start_link(arg)
      # {AvcKoombeaWebscraper.Worker, arg},
      # Start to serve requests, typically the last entry
      AvcKoombeaWebscraperWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AvcKoombeaWebscraper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AvcKoombeaWebscraperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
