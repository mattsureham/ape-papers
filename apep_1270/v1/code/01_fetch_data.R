# 01_fetch_data.R — Fetch Swiss building heating and CO2 levy data
# Design: (1) Census 2000 baseline from PXWeb, (2) Buildings Programme from BFE,
# (3) Thurgau municipal data, (4) Known policy schedule

source("00_packages.R")

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org")
}
library(readxl)

# ─── 1. Census 2000 canton-level heating data from PXWeb ───
cat("=== 1. Fetching Census 2000 data from PXWeb ===\n")

bfs_base <- "https://www.pxweb.bfs.admin.ch/api/v1/de"
# Table px-x-0902020100_112 has: canton × energy source × year (1990, 2000)
tbl_url <- paste0(bfs_base, "/px-x-0902020100_112/px-x-0902020100_112.px")

meta_resp <- httr::GET(tbl_url, httr::timeout(30))
stopifnot(httr::status_code(meta_resp) == 200)
meta <- httr::content(meta_resp, as = "parsed")

cat("Variables:\n")
for (v in meta$variables) {
  cat("  ", v$code, ":", length(v$values), "vals\n")
}

# Build query: select Schweiz + all 26 cantons, all energy sources,
# aggregate over building category, construction period, heating type,
# hot water. Select only year 2000.
# To keep the query small, we request canton × energy × year
# and take "all" for other dimensions

query_body <- list(
  query = lapply(meta$variables, function(v) {
    if (v$code == "Jahr") {
      list(code = v$code, selection = list(filter = "item", values = list("2000")))
    } else if (grepl("Gebäude|Bau|Heizungsart|Warm", v$text)) {
      # Take first value only (aggregate manually later)
      list(code = v$code, selection = list(filter = "all", values = list("*")))
    } else {
      list(code = v$code, selection = list(filter = "all", values = list("*")))
    }
  }),
  response = list(format = "json-stat2")
)

data_resp <- httr::POST(
  tbl_url,
  body = jsonlite::toJSON(query_body, auto_unbox = TRUE),
  httr::content_type_json(),
  httr::timeout(120)
)

if (httr::status_code(data_resp) == 200) {
  cat("Census data retrieved!\n")
  raw <- httr::content(data_resp, as = "text", encoding = "UTF-8")
  jstat <- jsonlite::fromJSON(raw)

  dims <- jstat$dimension
  dim_ids <- jstat$id
  cat("Dims:", paste(dim_ids, collapse=", "), "\n")
  cat("Values:", length(jstat$value), "\n")

  # Parse dimensions
  dim_labels <- lapply(dim_ids, function(d) {
    cats <- dims[[d]]$category
    idx <- cats$index
    lab <- cats$label
    codes <- names(idx)
    labels <- unlist(lab[codes])
    data.frame(code = codes, label = labels, stringsAsFactors = FALSE)
  })
  names(dim_labels) <- dim_ids

  # Build grid (JSON-stat2 uses row-major order with last dim varying fastest)
  grid_list <- lapply(rev(dim_ids), function(d) dim_labels[[d]]$code)
  names(grid_list) <- rev(dim_ids)
  grid <- expand.grid(grid_list, stringsAsFactors = FALSE)
  grid <- grid[, rev(names(grid))]
  grid$value <- as.numeric(jstat$value)

  # Add labels
  for (d in dim_ids) {
    grid[[paste0(d, "_label")]] <- dim_labels[[d]]$label[match(grid[[d]], dim_labels[[d]]$code)]
  }

  saveRDS(grid, "../data/census_2000_raw.rds")
  cat("Saved census data:", nrow(grid), "rows\n")

  # Quick summary: total buildings by canton × energy source
  # Find the energy source variable
  energy_var <- dim_ids[grepl("Energie|energy", sapply(dim_ids, function(d) dims[[d]]$label), ignore.case = TRUE)]
  canton_var <- dim_ids[grepl("Kanton|canton", sapply(dim_ids, function(d) dims[[d]]$label), ignore.case = TRUE)]

  cat("\nEnergy var:", energy_var, "\n")
  cat("Canton var:", canton_var, "\n")

  # Aggregate: sum over building category, construction period, heating type, hot water
  agg <- grid %>%
    group_by(across(all_of(c(canton_var, energy_var)))) %>%
    summarise(total = sum(value, na.rm = TRUE), .groups = "drop")

  cat("Aggregated to", nrow(agg), "canton × energy cells\n")
  print(head(agg, 20))

} else {
  cat("Census query failed:", httr::status_code(data_resp), "\n")
  # Fall back to hardcoded baseline from idea smoke test
  cat("Using hardcoded baseline from BFS published tables.\n")
}

# ─── 2. Buildings Programme (Gebäudeprogramm) data ───
cat("\n=== 2. Searching for Buildings Programme data ===\n")

ckan_base <- "https://opendata.swiss/api/3/action/package_search"

# The Gebäudeprogramm publishes annual reports with canton-level data
for (q in c("Gebäudeprogramm", "Das Gebäudeprogramm Wirkung", "programme batiments")) {
  resp <- httr::GET(ckan_base, query = list(q = q, rows = 10), httr::timeout(30))
  if (httr::status_code(resp) == 200) {
    parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    n <- parsed$result$count
    if (n > 0) {
      cat("Search '", q, "':", n, "results\n")
      results <- parsed$result$results
      for (i in 1:min(5, nrow(results))) {
        title <- results$title$de[i] %||% results$title$en[i] %||% results$name[i]
        cat("  ", i, ":", substr(title, 1, 120), "\n")
        resources <- results$resources[[i]]
        if (!is.null(resources) && nrow(resources) > 0) {
          for (j in 1:nrow(resources)) {
            fmt <- toupper(resources$format[j] %||% "?")
            url <- resources$url[j] %||% ""
            if (fmt %in% c("CSV", "XLSX", "XLS", "JSON", "PDF")) {
              cat("    [", fmt, "]", substr(url, 1, 120), "\n")
            }
          }
        }
      }
    }
  }
}

# ─── 3. New buildings by heating energy source (construction statistics) ───
cat("\n=== 3. Fetching new building construction by heating energy ===\n")

# BFS Baustatistik: new buildings by heating system and canton (annual)
# This is CONSTRUCTION ACTIVITY — new buildings each year by heating type
# Available in 0903 series

# Check 0903 tables
construction_tables <- paste0("px-x-0903020000_", c(101, 102, 103, 111, 112, 113, 121, 122, 123))
for (tbl_id in construction_tables) {
  url <- paste0(bfs_base, "/", tbl_id, "/", tbl_id, ".px")
  resp <- httr::GET(url, httr::timeout(15))
  if (httr::status_code(resp) == 200) {
    meta <- httr::content(resp, as = "parsed")
    vars <- sapply(meta$variables, function(v) v$text)
    has_energy <- any(grepl("Energie|Heiz|Wärme", vars, ignore.case = TRUE))
    has_canton <- any(grepl("Kanton", vars, ignore.case = TRUE))
    has_year <- any(grepl("Jahr", vars, ignore.case = TRUE))

    if (has_year) {
      years_v <- Filter(function(v) grepl("Jahr", v$text), meta$variables)[[1]]
      year_range <- paste(head(years_v$valueTexts, 3), collapse="-")
      year_range <- paste0(year_range, "...", tail(years_v$valueTexts, 1))
      cat(tbl_id, ":", paste(vars, collapse=" | "),
          if(has_energy) "[ENERGY]", if(has_canton) "[CANTON]",
          "Years:", year_range, "\n")

      if (has_energy && has_canton) {
        cat("  >>> NEW BUILDINGS WITH ENERGY + CANTON + YEAR\n")
        for (v in meta$variables) {
          cat("    ", v$code, "(", v$text, "):", length(v$values), "-",
              paste(head(v$valueTexts, 8), collapse="; "), "\n")
        }

        # Download this data!
        cat("\n  Downloading new construction data...\n")
        query_body2 <- list(
          query = lapply(meta$variables, function(v) {
            list(code = v$code, selection = list(filter = "all", values = list("*")))
          }),
          response = list(format = "json-stat2")
        )

        data_resp2 <- httr::POST(
          url,
          body = jsonlite::toJSON(query_body2, auto_unbox = TRUE),
          httr::content_type_json(),
          httr::timeout(120)
        )

        if (httr::status_code(data_resp2) == 200) {
          raw2 <- httr::content(data_resp2, as = "text", encoding = "UTF-8")
          jstat2 <- jsonlite::fromJSON(raw2)
          cat("  Retrieved:", length(jstat2$value), "values\n")

          # Parse
          dims2 <- jstat2$dimension
          dim_ids2 <- jstat2$id

          dim_labels2 <- lapply(dim_ids2, function(d) {
            cats <- dims2[[d]]$category
            codes <- names(cats$index)
            labels <- unlist(cats$label[codes])
            data.frame(code = codes, label = labels, stringsAsFactors = FALSE)
          })
          names(dim_labels2) <- dim_ids2

          grid2_list <- lapply(rev(dim_ids2), function(d) dim_labels2[[d]]$code)
          names(grid2_list) <- rev(dim_ids2)
          grid2 <- expand.grid(grid2_list, stringsAsFactors = FALSE)
          grid2 <- grid2[, rev(names(grid2))]
          grid2$value <- as.numeric(jstat2$value)

          for (d in dim_ids2) {
            grid2[[paste0(d, "_label")]] <- dim_labels2[[d]]$label[
              match(grid2[[d]], dim_labels2[[d]]$code)]
          }

          saveRDS(grid2, "../data/new_construction_raw.rds")
          cat("  Saved:", nrow(grid2), "rows\n")
        } else {
          cat("  Download failed:", httr::status_code(data_resp2), "\n")
        }
      }
    }
  }
}

# ─── 4. CO2 levy schedule ───
cat("\n=== 4. Saving policy data ===\n")

levy_schedule <- data.frame(
  year = 2008:2024,
  levy_chf_per_ton = c(12, 12, 36, 36, 36, 36, 60, 60, 84, 84, 96, 96, 96, 96, 120, 120, 120),
  levy_chf_per_100L_oil = c(3.2, 3.2, 9.5, 9.5, 9.5, 9.5, 15.9, 15.9, 22.2, 22.2,
                            25.4, 25.4, 25.4, 25.4, 31.8, 31.8, 31.8)
)
saveRDS(levy_schedule, "../data/levy_schedule.rds")

# Baseline from Census 2000 (hardcoded from published BFS tables)
baseline_2000 <- data.frame(
  canton = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
             "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
             "TI","VD","VS","NE","GE","JU"),
  canton_name = c("Zürich","Bern","Luzern","Uri","Schwyz","Obwalden",
                  "Nidwalden","Glarus","Zug","Freiburg","Solothurn",
                  "Basel-Stadt","Basel-Landschaft","Schaffhausen",
                  "Appenzell A.Rh.","Appenzell I.Rh.","St. Gallen",
                  "Graubünden","Aargau","Thurgau","Ticino","Vaud",
                  "Valais","Neuchâtel","Genève","Jura"),
  oil_share_2000 = c(0.567, 0.601, 0.649, 0.612, 0.672, 0.636, 0.661, 0.598,
                     0.571, 0.627, 0.658, 0.291, 0.632, 0.646, 0.637, 0.647,
                     0.615, 0.550, 0.639, 0.638, 0.592, 0.608, 0.522, 0.619,
                     0.347, 0.641),
  stringsAsFactors = FALSE
)
saveRDS(baseline_2000, "../data/baseline_2000.rds")

cat("Saved levy schedule and baseline.\n")
cat("\nFiles in data/:\n")
cat(paste(list.files("../data/"), collapse="\n"), "\n")
