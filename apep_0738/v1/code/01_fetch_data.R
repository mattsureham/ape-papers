## 01_fetch_data.R — Fetch STATENT data from BFS PXWeb API
## Paper: apep_0738 — Franc Shock and Retail Desertification

source("code/00_packages.R")

# ============================================================
# Helper: parse PXWeb JSON response
# ============================================================
parse_pxweb_json <- function(json_text) {
  parsed <- jsonlite::fromJSON(json_text, simplifyVector = FALSE)
  rows <- parsed$data
  if (length(rows) == 0) return(data.table())
  rbindlist(lapply(rows, function(r) {
    as.data.table(c(setNames(r$key, paste0("k", seq_along(r$key))),
                     setNames(r$values, paste0("v", seq_along(r$values)))))
  }))
}

fetch_pxweb <- function(api_url, query_body, desc = "") {
  cat(sprintf("  Fetching %s...", desc))
  resp <- httr::POST(
    api_url,
    body = jsonlite::toJSON(query_body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(180)
  )
  status <- httr::status_code(resp)
  if (status != 200) {
    stop(sprintf("FATAL: BFS API returned HTTP %d for %s. Cannot proceed.", status, desc))
  }
  json_text <- httr::content(resp, "text", encoding = "UTF-8")
  dt <- parse_pxweb_json(json_text)
  cat(sprintf(" %d rows\n", nrow(dt)))
  dt
}

# ============================================================
# 1. Canton x NOGA Division x Year (Table 101)
# ============================================================
cat("=== Fetching STATENT: Canton x NOGA Division x Year ===\n")

meta_url_101 <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_101/px-x-0602010000_101.px"
meta101 <- jsonlite::fromJSON(meta_url_101)

years_101   <- meta101$variables$values[[1]]
cantons_101 <- meta101$variables$values[[2]]
sectors_101 <- meta101$variables$values[[3]]
obs_101     <- meta101$variables$values[[4]]

# Sector labels for later use
sector_labels <- setNames(meta101$variables$valueTexts[[3]], meta101$variables$values[[3]])
canton_labels <- setNames(meta101$variables$valueTexts[[2]], meta101$variables$values[[2]])

cat(sprintf("Available: %d years, %d cantons, %d NOGA divisions, %d observation units\n",
            length(years_101), length(cantons_101), length(sectors_101), length(obs_101)))

# Exclude Swiss total
canton_codes <- cantons_101[cantons_101 != "999"]
# Exclude sector total
sector_codes <- sectors_101[sectors_101 != "999"]

# Fetch establishments (1) and employment (2) — year by year to stay under PXWeb limits
all_101 <- list()
for (yr_idx in seq_along(years_101)) {
  yr <- years_101[yr_idx]

  query_body <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = list(yr))),
      list(code = "Kanton", selection = list(filter = "item", values = as.list(canton_codes))),
      list(code = "Wirtschaftsabteilung", selection = list(filter = "item",
           values = as.list(sector_codes))),
      list(code = "Beobachtungseinheit", selection = list(filter = "item",
           values = list("1", "2", "5")))  # establishments, employees, FTE
    ),
    response = list(format = "json")
  )

  dt <- fetch_pxweb(meta_url_101, query_body, desc = yr)
  if (nrow(dt) > 0) {
    setnames(dt, c("year", "canton", "noga_div", "obs_unit", "value"))
    dt[, year := as.integer(year)]
    dt[, value := as.numeric(value)]
    all_101[[yr_idx]] <- dt
  }
  Sys.sleep(0.5)
}

statent_canton <- rbindlist(all_101, fill = TRUE)
cat(sprintf("\nTotal canton x sector rows: %d\n", nrow(statent_canton)))
stopifnot("No canton-sector data!" = nrow(statent_canton) > 10000)

# Add labels
statent_canton[, canton_name := canton_labels[canton]]
statent_canton[, sector_name := sector_labels[noga_div]]

# Pivot: one row per canton x sector x year
statent_wide <- dcast(statent_canton, year + canton + canton_name + noga_div + sector_name ~ obs_unit,
                      value.var = "value")
setnames(statent_wide, c("1", "2", "5"),
         c("establishments", "employees", "fte"))

cat(sprintf("Canton panel: %d rows, years %d-%d, %d cantons, %d sectors\n",
            nrow(statent_wide), min(statent_wide$year), max(statent_wide$year),
            uniqueN(statent_wide$canton), uniqueN(statent_wide$noga_div)))

fwrite(statent_wide, "data/statent_canton_sector.csv")

# ============================================================
# 2. Municipal x Broad Sector x Year (Table 102)
# ============================================================
cat("\n=== Fetching STATENT: Municipality x Sector x Year ===\n")

meta_url_102 <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_102/px-x-0602010000_102.px"
meta102 <- jsonlite::fromJSON(meta_url_102)

years_102 <- meta102$variables$values[[1]]
gems_102  <- meta102$variables$values[[2]]
secs_102  <- meta102$variables$values[[3]]
obs_102   <- meta102$variables$values[[4]]

gem_labels <- setNames(meta102$variables$valueTexts[[2]], meta102$variables$values[[2]])

# Exclude Swiss total
gem_codes <- gems_102[gems_102 != "99999"]

cat(sprintf("Available: %d years, %d municipalities, %d sectors, %d obs units\n",
            length(years_102), length(gem_codes), length(secs_102), length(obs_102)))

# Fetch year by year, chunking municipalities to stay under 5000 values/call
all_102 <- list()
chunk_size <- 400  # ~400 gems x 4 sectors x 3 obs = 4800 < 5000

for (yr_idx in seq_along(years_102)) {
  yr <- years_102[yr_idx]
  gem_chunks <- split(gem_codes, ceiling(seq_along(gem_codes) / chunk_size))
  yr_data <- list()

  for (ci in seq_along(gem_chunks)) {
    chunk <- gem_chunks[[ci]]
    query_body <- list(
      query = list(
        list(code = "Jahr", selection = list(filter = "item", values = list(yr))),
        list(code = "Gemeinde", selection = list(filter = "item", values = as.list(chunk))),
        list(code = "Wirtschaftssektor", selection = list(filter = "item",
             values = as.list(secs_102))),  # All sectors incl total
        list(code = "Beobachtungseinheit", selection = list(filter = "item",
             values = list("1", "2", "5")))  # establishments, employees, FTE
      ),
      response = list(format = "json")
    )

    dt <- tryCatch({
      resp <- httr::POST(
        meta_url_102,
        body = jsonlite::toJSON(query_body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(180)
      )
      if (httr::status_code(resp) != 200) {
        stop(sprintf("HTTP %d", httr::status_code(resp)))
      }
      parse_pxweb_json(httr::content(resp, "text", encoding = "UTF-8"))
    }, error = function(e) {
      stop(sprintf("FATAL: BFS municipal API failed for year %s chunk %d: %s", yr, ci, e$message))
    })

    if (nrow(dt) > 0) yr_data[[ci]] <- dt
    Sys.sleep(0.3)
  }

  dt_yr <- rbindlist(yr_data, fill = TRUE)
  if (nrow(dt_yr) > 0) {
    setnames(dt_yr, c("year", "gem_id", "sector", "obs_unit", "value"))
    dt_yr[, year := as.integer(year)]
    dt_yr[, value := as.numeric(value)]
    all_102[[yr_idx]] <- dt_yr
    cat(sprintf("  %s: %d rows (%d municipalities)\n", yr, nrow(dt_yr), uniqueN(dt_yr$gem_id)))
  }
}

statent_muni <- rbindlist(all_102, fill = TRUE)
cat(sprintf("\nTotal municipal rows: %d\n", nrow(statent_muni)))
stopifnot("No municipal data!" = nrow(statent_muni) > 50000)

# Add municipality names
statent_muni[, gem_name := gem_labels[gem_id]]

# Pivot observation units to columns
muni_wide <- dcast(statent_muni, year + gem_id + gem_name + sector ~ obs_unit,
                   value.var = "value")
setnames(muni_wide, c("1", "2", "5"),
         c("establishments", "employees", "fte"))

cat(sprintf("Municipal panel: %d rows, years %d-%d, %d municipalities\n",
            nrow(muni_wide), min(muni_wide$year), max(muni_wide$year),
            uniqueN(muni_wide$gem_id)))

fwrite(muni_wide, "data/statent_municipal.csv")

# ============================================================
# 3. Save sector lookups
# ============================================================
sector_lookup <- data.table(
  noga_div = names(sector_labels),
  sector_name = unname(sector_labels)
)
fwrite(sector_lookup, "data/sector_lookup.csv")

canton_lookup <- data.table(
  canton = names(canton_labels),
  canton_name = unname(canton_labels)
)
fwrite(canton_lookup, "data/canton_lookup.csv")

cat("\n=== Data fetch complete ===\n")
