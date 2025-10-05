defmodule AvcKoombeaWebscraper.Scrapes.SiteScraper do
  @moduledoc """
  Orchestrates scraping a site and persisting its discovered links.
  """

  alias AvcKoombeaWebscraper.Scrapes
  alias AvcKoombeaWebscraper.Scrapes.Site
  alias AvcKoombeaWebscraperWeb.Endpoint
  alias Req

  @anchor_regex ~r/<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)<\/a>/is
  @meta_title_patterns [
    {:name, "title"},
    {:name, "og:title"},
    {:property, "og:title"},
    {:name, "twitter:title"},
    {:property, "twitter:title"}
  ]

  @doc """
  Scrapes the given site, fetching its links and page title.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec run(%Site{}) :: :ok | {:error, term()}
  def run(%Site{} = site) do
    with {:ok, site} <- Scrapes.mark_site_started(site),
         {:ok, links, page_title} <- fetch_links(site.url),
         {:ok, site} <- maybe_update_site_title(site, page_title),
         {:ok, _} <- Scrapes.create_links(site, links),
         {:ok, site} <- Scrapes.mark_site_finished(site) do
      notify_links_updated(site)
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_links(url) do
    case Req.get(url: url, redirect: :follow) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, extract_links(body, url), extract_title(body)}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_links(html, base_url) when is_binary(html) do
    base_uri = URI.parse(base_url)
    Process.sleep(5_000)

    html
    |> then(&Regex.scan(@anchor_regex, &1, capture: :all_but_first))
    |> Enum.reduce(%{}, fn [href, inner_html], acc ->
      case normalize_href(href, base_uri) do
        nil -> acc
        normalized ->
          name =
            inner_html
            |> strip_tags()
            |> collapse_whitespace()
            |> blank_to_nil()

          put_link(acc, normalized, name)
      end
    end)
    |> Enum.map(fn {url, name} -> %{url: url, name: name} end)
  end

  defp extract_links(_html, _base_url), do: []

  defp put_link(acc, url, name) do
    case Map.fetch(acc, url) do
      {:ok, existing_name} ->
        cond do
          present?(existing_name) -> acc
          present?(name) -> Map.put(acc, url, name)
          true -> acc
        end

      :error ->
        Map.put(acc, url, name)
    end
  end

  defp extract_title(html) when is_binary(html) do
    extract_title_from_title_tag(html) || extract_title_from_meta_tags(html)
  end

  defp extract_title(_html), do: nil

  defp extract_title_from_title_tag(html) do
    html
    |> then(&Regex.run(~r/<title[^>]*>(.*?)<\/title>/is, &1, capture: :all_but_first))
    |> case do
      [title | _] -> title |> strip_tags() |> collapse_whitespace() |> blank_to_nil()
      _ -> nil
    end
  end

  defp extract_title_from_meta_tags(html) do
    Enum.find_value(@meta_title_patterns, fn {attribute, expected} ->
      extract_meta_content(html, attribute, expected)
    end)
  end

  defp extract_meta_content(html, attribute, expected) do
    attr = Atom.to_string(attribute)
    expected_escaped = Regex.escape(expected)

    regexes = [
      ~r/<meta[^>]*#{attr}=["']#{expected_escaped}["'][^>]*content=["']([^"']+)["'][^>]*>/i,
      ~r/<meta[^>]*content=["']([^"']+)["'][^>]*#{attr}=["']#{expected_escaped}["'][^>]*>/i
    ]

    Enum.find_value(regexes, fn regex ->
      case Regex.run(regex, html, capture: :all_but_first) do
        [content | _] -> content |> strip_tags() |> collapse_whitespace() |> blank_to_nil()
        _ -> nil
      end
    end)
  end

  defp maybe_update_site_title(site, nil), do: {:ok, site}

  defp maybe_update_site_title(site, title) do
    Scrapes.update_site(site, %{title: title})
  end

  defp notify_links_updated(site) do
    Endpoint.broadcast(topic_for(site), "site_links_updated", %{site_id: site.id})
  end

  defp topic_for(%Site{id: site_id}), do: "site_scrape:#{site_id}"

  defp normalize_href(href, base_uri) do
    href = String.trim(href)

    cond do
      href == "" -> nil
      String.starts_with?(href, ["#", "javascript:", "mailto:", "tel:"]) -> nil
      true ->
        case URI.parse(href) do
          %URI{scheme: scheme} = uri when scheme in ["http", "https"] -> URI.to_string(uri)
          %URI{scheme: nil} = uri ->
            base_uri
            |> URI.merge(uri)
            |> URI.to_string()

          _ -> nil
        end
    end
  rescue
    ArgumentError -> nil
  end

  defp strip_tags(value) when is_binary(value), do: Regex.replace(~r/<[^>]*>/, value, " ")
  defp strip_tags(value), do: value

  defp collapse_whitespace(value) when is_binary(value), do: value |> String.replace(~r/\s+/, " ") |> String.trim()
  defp collapse_whitespace(value), do: value

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp present?(value), do: value not in [nil, ""]
end
