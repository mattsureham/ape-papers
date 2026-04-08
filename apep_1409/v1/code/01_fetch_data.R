# =============================================================================
# 01_fetch_data.R — Fetch BFS municipal demographic data via PXWeb API
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

source("00_packages.R")

api_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102020000_201/px-x-0102020000_201.px"

# --- Get metadata ---
cat("Fetching metadata...\n")
meta <- GET(api_url) |> content(as = "text", encoding = "UTF-8") |> fromJSON()
vars <- meta$variables

# Variable structure:
# 1 (Jahr): Year (1981-2024)
# 2 (Geo): Canton / District / Commune (2305 units)
# 3 (Citizenship): total(0), Swiss(1), Foreign(2)
# 4 (Sex): total(0), Male(1), Female(2)
# 5 (Component): 0=Pop Jan 1, 12=Naturalizations, etc.

geo_values <- vars$values[[2]]
geo_texts <- vars$valueTexts[[2]]
year_values <- vars$values[[1]]

# Identify commune codes (format: "......XXXX Name")
commune_mask <- grepl("^\\.\\.\\.\\.\\.\\.", geo_texts)
commune_codes <- geo_values[commune_mask]
commune_names <- geo_texts[commune_mask]
cat(sprintf("Communes identified: %d\n", length(commune_codes)))

# --- Fetch naturalizations (component 12, citizenship total, sex total) ---
# And foreign population (component 0, citizenship foreign, sex total)
# API limit: ~100k cells. We have ~1700 communes × 44 years = ~75k per query. Should fit.

fetch_component <- function(component_code, citizenship_code, label) {
  cat(sprintf("\nFetching %s (component=%s, citizenship=%s)...\n",
              label, component_code, citizenship_code))

  # Batch communes to stay under API limits
  batch_size <- 500
  n_batches <- ceiling(length(commune_codes) / batch_size)
  all_batches <- list()

  for (b in seq_len(n_batches)) {
    start <- (b - 1) * batch_size + 1
    end <- min(b * batch_size, length(commune_codes))
    geo_batch <- commune_codes[start:end]

    query_body <- list(
      query = list(
        list(code = vars$code[2],
             selection = list(filter = "item", values = geo_batch)),
        list(code = vars$code[3],
             selection = list(filter = "item", values = list(citizenship_code))),
        list(code = vars$code[4],
             selection = list(filter = "item", values = list("0"))),  # total sex
        list(code = vars$code[5],
             selection = list(filter = "item", values = list(component_code)))
      ),
      response = list(format = "json")
    )

    resp <- POST(api_url,
                 body = toJSON(query_body, auto_unbox = TRUE),
                 content_type_json(),
                 timeout(180))

    if (status_code(resp) != 200) {
      cat(sprintf("  ERROR batch %d: HTTP %d\n", b, status_code(resp)))
      # Try with smaller batch
      cat("  Response:", content(resp, as = "text", encoding = "UTF-8") |> substr(1, 200), "\n")
      next
    }

    batch_json <- content(resp, as = "text", encoding = "UTF-8") |> fromJSON()

    if (!is.null(batch_json$data) && nrow(batch_json$data) > 0) {
      # data is a data.frame with list columns: key (list of char vectors), values (list of char vectors)
      keys_mat <- do.call(rbind, batch_json$data$key)
      vals_vec <- sapply(batch_json$data$values, `[`, 1)

      batch_df <- data.frame(
        year = as.integer(keys_mat[, 1]),
        geo_code = keys_mat[, 2],
        value = as.numeric(vals_vec),
        stringsAsFactors = FALSE
      )
      all_batches[[b]] <- batch_df
      cat(sprintf("  Batch %d/%d: %d rows\n", b, n_batches, nrow(batch_df)))
    }

    Sys.sleep(1)
  }

  result <- bind_rows(all_batches)
  result$variable <- label
  cat(sprintf("  Total %s rows: %d\n", label, nrow(result)))
  return(result)
}

# Fetch naturalizations (component 12, Swiss citizenship = gain from naturalization)
# BFS codes naturalization as: Swiss(1) = +N (gained citizens), Foreign(2) = -N, Total(0) = 0
nat_data <- fetch_component("12", "1", "naturalizations")

# Fetch foreign population on Jan 1 (component 0, citizenship = foreign)
fpop_data <- fetch_component("0", "2", "foreign_pop")

# Fetch total population on Jan 1 (component 0, citizenship = total)
tpop_data <- fetch_component("0", "0", "total_pop")

# --- Combine and reshape ---
all_data <- bind_rows(nat_data, fpop_data, tpop_data)

# Add commune names and BFS numbers
geo_df <- data.frame(
  geo_code = geo_values,
  geo_text = geo_texts,
  stringsAsFactors = FALSE
) |>
  filter(grepl("^\\.\\.\\.\\.\\.\\.", geo_text)) |>
  mutate(
    bfs_nr = as.integer(gsub("^\\.*([0-9]+)\\s.*", "\\1", geo_text)),
    commune_name = gsub("^\\.*[0-9]+\\s+", "", geo_text)
  )

panel <- all_data |>
  left_join(geo_df, by = "geo_code") |>
  select(bfs_nr, commune_name, year, variable, value) |>
  pivot_wider(names_from = variable, values_from = value)

cat(sprintf("\n=== PANEL SUMMARY ===\n"))
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Unique communes: %d\n", n_distinct(panel$bfs_nr)))
cat(sprintf("Year range: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("Naturalization obs (non-NA): %d\n", sum(!is.na(panel$naturalizations))))
cat(sprintf("Foreign pop obs (non-NA): %d\n", sum(!is.na(panel$foreign_pop))))

# --- Validation ---
stopifnot("No data fetched" = nrow(panel) > 0)
stopifnot("No naturalization data" = sum(!is.na(panel$naturalizations)) > 0)

# Quick check: total naturalizations by year
yearly_nat <- panel |>
  group_by(year) |>
  summarize(total_nat = sum(naturalizations, na.rm = TRUE),
            total_fpop = sum(foreign_pop, na.rm = TRUE),
            n_communes = n()) |>
  mutate(nat_rate = total_nat / total_fpop * 100)

cat("\nYearly naturalization totals (sample):\n")
print(yearly_nat |> filter(year %in% c(1990, 2000, 2002, 2003, 2004, 2005, 2010, 2020)))

# Save
saveRDS(panel, "../data/bfs_commune_panel.rds")
saveRDS(geo_df, "../data/geo_lookup.rds")

cat("\nData saved successfully.\n")
cat("01_fetch_data.R complete.\n")
