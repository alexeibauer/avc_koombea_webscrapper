# AvcKoombeaWebscraper

This is the coding exercise by Alejandro Valdes Calderon as part of the recruitment process by Koombea.

# Build steps to deploy in local

* Pre-requisite: You must have elixir and mix installed an in your PATH.

* Clone this repository into your local environment: git clone https://github.com/alexeibauer/avc_koombea_webscrapper.git .

* Run `mix setup` to install and setup dependencies. This will also create a local database. For simplicity, the exercise uses SQLite, so a "dev.db" file will be created in your "priv/data" path. For a real-life project this could be easily changed by changing the Ecto repo to use another adapter (e.g, PostgreSQL or MySQL), and then configure in config/dev.exs accordingly, as every interaction with the database has been implemented through Ecto. The Ecto migrations run as part of `mix setup`, so no need to do anything else.

* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


# Usage notes

* You will need to create a new account to start. The auth process was created automatically by the Phoenix Auth module, and just tweaked to adapt to this exercise flow.

* Once you create an account (only an email is needed), you can go to "/dev/mailbox" to read the email that was sent (this is for dev purposes only). You will get a blue message to redirect you to that page anyway.

* You can then click the email that was sent (you will see emails "sent" in "/dev/mailbox") and you will be inside the scrape application

* You can go to settings and assign a password to your user for subsequent log ins.

* Just add a new site with the protocol like: "https://cnn.com" and you will go to the scrape single page. All scraping is done asynchronously.

* Both the scrape single page, and the scrape home page (that lists all sites) have LiveViews implemented so that no reloading or polling is needed to update both the scraped links or the scrape progress, respectively.

* IMPORTANT:You can go to `liv/avc_koombea_webscraper/scrapes/site_scraper.ex`, line 56, and uncomment the "Process.sleep/1" there to EMULATE that a site scrape takes more time. This will be useful to make evident the LIVE VIEW functionality, as many sites are scraped very quickly so is hard to see the LIVE VIEW process.


# Technical notes

Here are some useful notes on some key components to understand the structure of the exercise.

* `lib/avc_koombea_webscraper_web/router.ex`: This file has the routes of the application. Note specially line 22, that is the root ("/") path and directs traffic to the "RedirectController" (`lib/avc_koombea_webscraper_web/controllers/redirect_controller.ex`), this redirect controller has no UI and is only logic to determine if the user should be sent to the registration/login process (if the user is not logged in) or to the scrape home (if the user is already logged in)

* `lib/avc_koombea_webscraper_web/controllers/scrape_home_html`: Is the home page where all sites are displayed. When adding a new site to be scraped then the scrape_home_controller gets invoked. That controller (`lib/avc_koombea_webscraper_web/scrape_home_controller.ex`) retrieves or inserts the site to the database and kicks off the scraping in an async process (Task)

* `lib/avc_koombea_webscraper/scrapes/site_scraper.ex`: Contains the ACTUAL logic that does the scraping. This module is invoked from a separate Task orchestrated from the scrape home controller. Once a web page is requested via get then a pre-compiled regular expression (line 11 of site_scraper.ex at constant "@anchor_regex") is used to obtain anchor tags and the inner HTML of each anchor tag. The href is used as URL and the inner HTML is used as link name (the url is used as name is there is no inner HTML for an anchor tag). *IMPORTANT*: In line 56 you can uncomment the "Process.sleep/1" there to EMULATE that a site scrape takes more time. The extraction of links is notified to a Topic in the function "notify_links_updated" (line 136) so that the LiveView components subscribed to it get a notification and can update both scrape home and scrape single pages.

* `lib/avc_koombea_webscraper_web/live/scrape_single_live.ex`: Is a full LIVE component that is subscribed to the site topic (each site has a separate topic identified by each site id). Once it receives an update, it renders content of links scraped in the page table.

* `lib/avc_koombea_webscraper_web/live/site_progress_live.ex`: Is a live view component that ONLY updates a piece of the Scrape Home Controller. Specifically, is used in "`lib/avc_koombea_webscraper_web/scrape_home_html/index.html`.heex line 46" by invoking the "live_render" function, so that the controller strategy can co-exist with a live view component that takes care of rendering "In progress..." if the scrape is still in progress, or renders the number of links if the scrape has finished.
