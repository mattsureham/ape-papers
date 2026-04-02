## 01b_fetch_wwii.R — Scrape WWII airfield data from Wikipedia categories
## Each state category lists individual airfield articles
## Each article has coordinates in its infobox
source("00_packages.R")

data_dir <- "../data"
wwii_file <- file.path(data_dir, "wwii_airfields_v2.csv")

if (file.exists(wwii_file)) {
  cat("WWII v2 data already exists, skipping scrape.\n")
  wwii <- fread(wwii_file)
  cat("Loaded:", nrow(wwii), "airfields\n")
  q("no")
}

## State category URLs from the parent category
state_cats <- c(
  "Alabama", "Alaska", "Arizona", "Arkansas", "California",
  "Colorado", "Connecticut", "Delaware", "Florida",
  "Georgia_(U.S._state)", "Hawaii", "Idaho", "Illinois", "Indiana",
  "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
  "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
  "Montana", "Nebraska", "Nevada", "New_Jersey", "New_Mexico",
  "New_York_(state)", "North_Dakota", "North_Carolina", "Ohio",
  "Oklahoma", "Oregon", "Pennsylvania", "Rhode_Island",
  "South_Carolina", "South_Dakota", "Tennessee", "Texas", "Utah",
  "Virginia", "Washington_(state)", "Wisconsin", "Wyoming"
)

all_airfields <- list()

for (st in state_cats) {
  cat_url <- paste0(
    "https://en.wikipedia.org/wiki/Category:Airfields_of_the_United_States_Army_Air_Forces_in_",
    st
  )
  st_clean <- gsub("_\\(.*\\)", "", gsub("_", " ", st))
  cat("Processing:", st_clean, "\n")

  tryCatch({
    resp <- httr::GET(cat_url, httr::user_agent("Mozilla/5.0 (APEP)"), httr::timeout(15))
    if (httr::status_code(resp) != 200) {
      cat("  Skipping (status", httr::status_code(resp), ")\n")
      next
    }
    page <- rvest::read_html(httr::content(resp, "text"))

    ## Get all article links in the category
    ## Category pages list articles under div.mw-category
    cat_div <- rvest::html_nodes(page, "div.mw-category a, #mw-pages a")
    if (length(cat_div) == 0) {
      ## Fallback: get all links that look like airfield articles
      cat_div <- rvest::html_nodes(page, "#mw-pages li a")
    }

    article_hrefs <- rvest::html_attr(cat_div, "href")
    article_names <- rvest::html_text(cat_div)

    ## Filter to actual article links (not category links)
    mask <- grepl("^/wiki/[^:]+$", article_hrefs) &
            !grepl("Category:", article_hrefs) &
            !grepl("^/wiki/$", article_hrefs)
    article_hrefs <- article_hrefs[mask]
    article_names <- article_names[mask]
    article_hrefs <- unique(article_hrefs)
    article_names <- article_names[!duplicated(article_hrefs)]

    cat("  Found", length(article_hrefs), "airfield articles\n")

    ## For each airfield article, get coordinates via Wikipedia API
    for (i in seq_along(article_hrefs)) {
      title <- gsub("^/wiki/", "", article_hrefs[i])
      ## Use Wikipedia API to get coordinates
      api_url <- paste0(
        "https://en.wikipedia.org/w/api.php?action=query&titles=",
        title,
        "&prop=coordinates&format=json"
      )

      tryCatch({
        api_resp <- httr::GET(api_url, httr::user_agent("Mozilla/5.0 (APEP)"),
                              httr::timeout(10))
        if (httr::status_code(api_resp) == 200) {
          json <- jsonlite::fromJSON(httr::content(api_resp, "text", encoding = "UTF-8"))
          pages <- json$query$pages
          page_data <- pages[[1]]

          lat <- NA_real_
          lon <- NA_real_
          if (!is.null(page_data$coordinates)) {
            lat <- page_data$coordinates$lat[1]
            lon <- page_data$coordinates$lon[1]
          }

          all_airfields[[length(all_airfields) + 1]] <- data.table(
            name = article_names[min(i, length(article_names))],
            wiki_title = gsub("_", " ", title),
            state = st_clean,
            lat = lat,
            lon = lon
          )
        }
      }, error = function(e) {
        cat("    Error for", title, ":", e$message, "\n")
      })
      Sys.sleep(0.1) # Rate limit
    }
  }, error = function(e) {
    cat("  Error:", e$message, "\n")
  })
  Sys.sleep(0.3)
}

wwii <- rbindlist(all_airfields, fill = TRUE)
cat("\n=== WWII Airfield Summary ===\n")
cat("Total airfields:", nrow(wwii), "\n")
cat("With coordinates:", sum(!is.na(wwii$lat)), "\n")
cat("States:", uniqueN(wwii$state), "\n")

## Show by state
state_counts <- wwii[, .N, by = state][order(-N)]
print(state_counts)

fwrite(wwii, wwii_file)
cat("Saved to:", wwii_file, "\n")
