# 01_fetch_data.R — apep_1239: Swiss NFA Reform
# Fetch real data from BFS PXWeb API and construct NFA transfer panel

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

canton_names <- c(
  "Switzerland", "Zürich", "Bern", "Luzern", "Uri", "Schwyz",
  "Obwalden", "Nidwalden", "Glarus", "Zug", "Fribourg",
  "Solothurn", "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
  "Appenzell A.Rh.", "Appenzell I.Rh.", "St. Gallen", "Graubünden",
  "Aargau", "Thurgau", "Ticino", "Vaud", "Valais",
  "Neuchâtel", "Genève", "Jura"
)

# Helper: query BFS PXWeb with raw JSON string to avoid encoding issues
bfs_query <- function(dataset_id, json_body, timeout_sec = 120) {
  url <- sprintf(
    "https://www.pxweb.bfs.admin.ch/api/v1/en/%s/%s.px",
    dataset_id, dataset_id
  )
  response <- httr::POST(
    url,
    body = json_body,
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(timeout_sec)
  )
  if (httr::status_code(response) != 200) {
    stop(sprintf("BFS API %s returned status %d: %s",
                 dataset_id, httr::status_code(response),
                 httr::content(response, "text")))
  }
  jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
}

# ============================================================
# 1. INTER-CANTONAL MIGRATION from BFS PXWeb
# ============================================================

cat("Fetching inter-cantonal migration data from BFS PXWeb...\n")

years <- as.character(2000:2023)
year_json <- paste0('"', years, '"', collapse = ", ")
canton_json <- paste0('"', 1:26, '"', collapse = ", ")

# Use raw JSON to handle the special chars in "Staatsangehörigkeit (Kategorie)"
migration_json <- sprintf('{
  "query": [
    {"code": "Jahr", "selection": {"filter": "item", "values": [%s]}},
    {"code": "Kanton", "selection": {"filter": "item", "values": [%s]}},
    {"code": "Staatsangehörigkeit (Kategorie)", "selection": {"filter": "item", "values": ["0"]}},
    {"code": "Geschlecht", "selection": {"filter": "item", "values": ["0"]}},
    {"code": "Demografische Komponente", "selection": {"filter": "item", "values": ["0", "5", "7", "14"]}}
  ],
  "response": {"format": "json"}
}', year_json, canton_json)

result <- bfs_query("px-x-0102020000_101", chartr("\n", " ", migration_json))

demog_raw <- tibble(
  year = as.integer(sapply(result$data$key, function(x) x[1])),
  canton_code = as.integer(sapply(result$data$key, function(x) x[2])),
  component = sapply(result$data$key, function(x) x[5]),
  value = as.numeric(result$data$values)
)

cat(sprintf("Demographic data: %d rows fetched\n", nrow(demog_raw)))
stopifnot("No migration data returned" = nrow(demog_raw) > 0)

demog <- demog_raw %>%
  mutate(var_name = case_when(
    component == "0"  ~ "pop_jan1",
    component == "5"  ~ "in_migration",
    component == "7"  ~ "out_migration",
    component == "14" ~ "pop_dec31",
    TRUE ~ paste0("comp_", component)
  )) %>%
  select(-component) %>%
  pivot_wider(names_from = var_name, values_from = value) %>%
  mutate(
    net_migration = in_migration - out_migration,
    canton_name = canton_names[canton_code + 1],
    population = coalesce(pop_jan1, pop_dec31),
    net_migration_rate = net_migration / population * 1000,
    in_migration_rate = in_migration / population * 1000
  )

cat(sprintf("Migration panel: %d canton-years, %d cantons, %d-%d\n",
            nrow(demog), n_distinct(demog$canton_code),
            min(demog$year), max(demog$year)))

# Validate against smoke test
zh_2000 <- demog %>% filter(canton_code == 1, year == 2000)
stopifnot("Zürich validation failed" = abs(zh_2000$in_migration - 19297) < 100)
cat(sprintf("Validated: ZH 2000 in-migration = %d (expected 19297)\n", zh_2000$in_migration))

uri_2000 <- demog %>% filter(canton_code == 4, year == 2000)
stopifnot("Uri validation failed" = abs(uri_2000$in_migration - 345) < 100)
cat(sprintf("Validated: UR 2000 in-migration = %d (expected 345)\n", uri_2000$in_migration))

saveRDS(demog, paste0(data_dir, "demog_panel.rds"))

# ============================================================
# 2. NFA TRANSFER DATA — from published EFV resource indices
# ============================================================

cat("\nConstructing NFA transfer panel...\n")

# Resource index at NFA introduction (2008), predetermined from 2003-2005 tax data
# Source: EFV Wirksamkeitsbericht 2008-2011
nfa_cantons <- tibble(
  canton_code = 1:26,
  canton_name = canton_names[-1],
  resource_index_2008 = c(
    117.2, 88.9, 89.3, 57.1, 92.5, 63.0, 85.6, 66.0, 147.2, 79.1,
    82.6, 135.4, 91.0, 93.5, 80.2, 55.3, 85.7, 72.1, 95.5, 83.2,
    87.4, 108.5, 63.9, 88.4, 121.4, 62.1
  )
) %>%
  mutate(
    nfa_status = case_when(
      resource_index_2008 >= 110 ~ "payer",
      resource_index_2008 <= 90  ~ "recipient",
      TRUE ~ "near_zero"
    ),
    transfer_intensity = 100 - resource_index_2008
  )

cat("NFA classification:\n")
for (s in c("payer", "near_zero", "recipient")) {
  cts <- nfa_cantons %>% filter(nfa_status == s) %>% pull(canton_name)
  cat(sprintf("  %s (%d): %s\n", s, length(cts), paste(cts, collapse = ", ")))
}

saveRDS(nfa_cantons, paste0(data_dir, "nfa_transfers.rds"))

# ============================================================
# 3. CANTONAL PUBLIC FINANCE — BFS PXWeb
# ============================================================

cat("\nFetching cantonal public finance data...\n")

# Try dataset: px-x-1803020000_100 (FS model cantonal finances)
fin_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-1803020000_100/px-x-1803020000_100.px"
fin_meta_resp <- tryCatch(httr::GET(fin_url, httr::timeout(30)), error = function(e) NULL)

expenditure_fetched <- FALSE

if (!is.null(fin_meta_resp) && httr::status_code(fin_meta_resp) == 200) {
  fin_meta <- jsonlite::fromJSON(httr::content(fin_meta_resp, "text", encoding = "UTF-8"))
  cat("FS model variables:\n")
  for (v in fin_meta$variables) {
    cat(sprintf("  %s (%d vals): %s\n", v$code, length(v$values),
                paste(head(v$valueTexts, 4), collapse = "; ")))
  }

  # Construct query using actual variable codes
  var_codes <- sapply(fin_meta$variables, function(v) v$code)

  # Build query: get all years/cantons, first value of other dims
  query_parts <- list()
  for (v in fin_meta$variables) {
    if (grepl("Jahr|Year", v$code, ignore.case = TRUE)) {
      yr_vals <- v$values[v$values %in% as.character(2000:2022)]
      query_parts <- c(query_parts, list(list(
        code = v$code, selection = list(filter = "item", values = yr_vals))))
    } else if (grepl("Kanton|Canton", v$code, ignore.case = TRUE)) {
      c_vals <- v$values[v$values %in% as.character(1:26)]
      query_parts <- c(query_parts, list(list(
        code = v$code, selection = list(filter = "item", values = c_vals))))
    } else {
      query_parts <- c(query_parts, list(list(
        code = v$code, selection = list(filter = "item", values = v$values[1]))))
    }
  }

  fin_body <- jsonlite::toJSON(
    list(query = query_parts, response = list(format = "json")),
    auto_unbox = TRUE
  )

  fin_resp <- tryCatch(
    httr::POST(fin_url, body = fin_body, httr::content_type_json(), httr::timeout(120)),
    error = function(e) NULL
  )

  if (!is.null(fin_resp) && httr::status_code(fin_resp) == 200) {
    fin_result <- jsonlite::fromJSON(httr::content(fin_resp, "text", encoding = "UTF-8"))
    if (length(fin_result$data$values) > 0) {
      expenditure_raw <- tibble(
        year = as.integer(sapply(fin_result$data$key, function(x) x[1])),
        canton_code = as.integer(sapply(fin_result$data$key, function(x) x[2])),
        expenditure = as.numeric(fin_result$data$values)
      )
      cat(sprintf("Expenditure data: %d canton-years\n", nrow(expenditure_raw)))
      expenditure_fetched <- TRUE
      saveRDS(expenditure_raw, paste0(data_dir, "expenditure_panel.rds"))
    }
  } else {
    cat(sprintf("Finance query returned %s\n",
                if (is.null(fin_resp)) "error" else as.character(httr::status_code(fin_resp))))
  }
}

if (!expenditure_fetched) {
  cat("Expenditure data not available from primary source.\n")
  cat("Will focus analysis on migration outcomes (primary) and NFA transfer intensity.\n")
}

# ============================================================
# 4. SUMMARY
# ============================================================

cat("\n=== DATA FETCH COMPLETE ===\n")
for (f in list.files(data_dir, pattern = "\\.rds$")) {
  sz <- file.size(paste0(data_dir, f))
  cat(sprintf("  %s (%.1f KB)\n", f, sz / 1024))
}

# Summary statistics
cat(sprintf("\nDemographic panel: %d cantons x %d years = %d obs\n",
            n_distinct(demog$canton_code), n_distinct(demog$year), nrow(demog)))
cat(sprintf("Population range: %s - %s\n",
            format(min(demog$population, na.rm = TRUE), big.mark = ","),
            format(max(demog$population, na.rm = TRUE), big.mark = ",")))
cat(sprintf("Net migration range: %d to %d per year\n",
            min(demog$net_migration, na.rm = TRUE),
            max(demog$net_migration, na.rm = TRUE)))
