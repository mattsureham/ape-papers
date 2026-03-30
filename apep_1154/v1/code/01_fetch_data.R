## 01_fetch_data.R — Fetch transposition + firm entry data
## apep_1154: EU Transposition Delay and Firm Entry

source("00_packages.R")

cat("\n=== STEP 1: Fetch EU Directive Transposition Data ===\n")

# ---- 1a. Get directives with transposition deadlines ----
cat("Querying CELLAR for directives with transposition deadlines...\n")

dir_query <- elx_make_query(
  resource_type = "directive",
  include_date_transpos = TRUE,
  include_date = TRUE,
  include_force = TRUE
)

directives_raw <- elx_run_query(dir_query)
cat("Retrieved", nrow(directives_raw), "directive records from CELLAR.\n")

stopifnot("No directives retrieved from CELLAR" = nrow(directives_raw) > 0)

# Columns: work, type, celex, date, datetranspos, force
directives <- directives_raw %>%
  filter(!is.na(datetranspos), !is.na(celex)) %>%
  mutate(
    deadline_date = as.Date(datetranspos),
    deadline_year = year(deadline_date)
  ) %>%
  filter(deadline_year >= 2008, deadline_year <= 2022) %>%
  distinct(celex, .keep_all = TRUE)

cat("Directives with deadlines 2008-2022:", nrow(directives), "\n")
stopifnot("Too few directives" = nrow(directives) >= 50)

# ---- 1b. Get national implementation measures (NIM) via SPARQL ----
cat("\nQuerying CELLAR for national implementation measures...\n")

# Paginate: CELLAR limits to 10K per query
all_nims <- list()
page_size <- 10000
offset <- 0
page <- 1

repeat {
  sparql_query <- sprintf("
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
SELECT DISTINCT ?nim_celex ?parent_celex ?notif_date WHERE {
  ?nim cdm:work_has_resource-type <http://publications.europa.eu/resource/authority/resource-type/MEAS_NATION_IMPL> .
  ?nim cdm:resource_legal_id_celex ?nim_celex .
  ?nim cdm:measure_national_implementing_implements_directive ?parent .
  ?parent cdm:resource_legal_id_celex ?parent_celex .
  OPTIONAL { ?nim cdm:work_date_document ?notif_date . }
}
LIMIT %d OFFSET %d", page_size, offset)

  resp <- httr::GET(
    "https://publications.europa.eu/webapi/rdf/sparql",
    query = list(query = sparql_query, format = "application/json"),
    httr::timeout(180)
  )

  if (httr::status_code(resp) != 200) {
    cat("SPARQL returned status", httr::status_code(resp), "at page", page, "\n")
    break
  }

  json <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  n_results <- length(json$results$bindings$nim_celex$value)
  cat("  Page", page, ":", n_results, "results\n")

  if (n_results == 0) break

  page_df <- tibble(
    nim_celex = json$results$bindings$nim_celex$value,
    parent_celex = json$results$bindings$parent_celex$value,
    notif_date = json$results$bindings$notif_date$value
  )
  all_nims[[page]] <- page_df
  offset <- offset + page_size
  page <- page + 1

  if (n_results < page_size) break
  Sys.sleep(1)  # Rate limiting
}

nims_raw <- bind_rows(all_nims)
cat("Total NIM records:", nrow(nims_raw), "\n")

stopifnot("No NIMs retrieved" = nrow(nims_raw) > 0)

# Parse country from NIM CELEX (e.g., "72013L0044ITA_215993" → "ITA")
nims <- nims_raw %>%
  mutate(
    # Country code is 3 letters before the underscore (or at end)
    country3 = str_extract(nim_celex, "[A-Z]{3}(?=_|$)"),
    country2 = case_when(
      country3 == "AUT" ~ "AT", country3 == "BEL" ~ "BE", country3 == "BGR" ~ "BG",
      country3 == "HRV" ~ "HR", country3 == "CYP" ~ "CY", country3 == "CZE" ~ "CZ",
      country3 == "DNK" ~ "DK", country3 == "EST" ~ "EE", country3 == "FIN" ~ "FI",
      country3 == "FRA" ~ "FR", country3 == "DEU" ~ "DE", country3 == "GRC" ~ "EL",
      country3 == "HUN" ~ "HU", country3 == "IRL" ~ "IE", country3 == "ITA" ~ "IT",
      country3 == "LVA" ~ "LV", country3 == "LTU" ~ "LT", country3 == "LUX" ~ "LU",
      country3 == "MLT" ~ "MT", country3 == "NLD" ~ "NL", country3 == "POL" ~ "PL",
      country3 == "PRT" ~ "PT", country3 == "ROU" ~ "RO", country3 == "SVK" ~ "SK",
      country3 == "SVN" ~ "SI", country3 == "ESP" ~ "ES", country3 == "SWE" ~ "SE",
      TRUE ~ NA_character_
    ),
    notif_date_parsed = as.Date(notif_date)
  ) %>%
  filter(
    !is.na(country2),
    !is.na(parent_celex),
    !is.na(notif_date_parsed),
    notif_date_parsed > as.Date("1990-01-01")  # Drop nonsense dates
  )

cat("Parsed NIMs:", nrow(nims), "\n")
cat("Countries:", paste(sort(unique(nims$country2)), collapse = ", "), "\n")

# First transposition date per country-directive
transposition <- nims %>%
  group_by(country2, parent_celex) %>%
  summarise(
    first_transposition = min(notif_date_parsed, na.rm = TRUE),
    n_measures = n(),
    .groups = "drop"
  )

cat("Country-directive transposition pairs:", nrow(transposition), "\n")

# ---- 1c. Build limbo panel ----
eu27 <- c("AT","BE","BG","CY","CZ","DE","DK","EE","EL","ES","FI","FR",
           "HR","HU","IE","IT","LT","LU","LV","MT","NL","PL","PT","RO",
           "SE","SI","SK")

limbo_panel <- directives %>%
  select(celex, deadline_date, deadline_year) %>%
  crossing(country2 = eu27) %>%
  left_join(transposition, by = c("celex" = "parent_celex", "country2")) %>%
  mutate(
    transposed_date = first_transposition,
    delay_days = as.numeric(difftime(transposed_date, deadline_date, units = "days")),
    was_late = !is.na(delay_days) & delay_days > 0,
    still_not_transposed = is.na(transposed_date),
    delay_days = ifelse(still_not_transposed, NA, delay_days),
    transposed_year = year(transposed_date)
  )

cat("\nLimbo panel rows:", nrow(limbo_panel), "\n")
cat("Late transpositions:", sum(limbo_panel$was_late, na.rm = TRUE), "\n")
cat("Not yet transposed:", sum(limbo_panel$still_not_transposed), "\n")

# Summary by country
late_by_country <- limbo_panel %>%
  group_by(country2) %>%
  summarise(
    n_directives = n(),
    n_late = sum(was_late, na.rm = TRUE),
    pct_late = round(100 * n_late / n_directives, 1),
    avg_delay_days = round(mean(delay_days[was_late], na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  arrange(desc(pct_late))

cat("\n=== Late transposition by country ===\n")
print(as.data.frame(late_by_country), row.names = FALSE)

# ---- 1d. Map directives to sectors via titles ----
cat("\nFetching directive titles for sector classification...\n")

sector_keywords <- tribble(
  ~pattern, ~nace_section, ~sector_label,
  "agricult|food|animal|plant|seed|pesticide|veterinar|phytosanit|feed", "A", "Agriculture",
  "mining|extract|mineral|geological", "B", "Mining",
  "manufactur|product|industr|chemical|machine|vehicle|electric|pharma|cosmetic|textile|toy|construction product", "C", "Manufacturing",
  "energy|electricity|gas|nuclear|renewable|emission|carbon", "D", "Energy",
  "water|waste|recycl|sewage|environment|pollut", "E", "Water/Waste",
  "construct|building", "F", "Construction",
  "trade|retail|wholesale|consumer|market", "G", "Trade",
  "transport|railway|road|maritime|aviation|shipping|port|driver", "H", "Transport",
  "hotel|tourism|accommodat|restaurant", "I", "Hospitality",
  "telecom|broadcast|electronic comm|information|data|privacy|digital|cyber", "J", "ICT",
  "financ|bank|insurance|credit|payment|invest|securities|pension|audit", "K", "Finance",
  "health|medic|pharmaceut|clinic|patient|blood|tissue|organ", "Q", "Health"
)

# Get titles via SPARQL — batch in groups of 100 to avoid URI length limits
celex_list <- directives$celex
batch_size <- 100
all_titles <- list()

for (i in seq(1, length(celex_list), by = batch_size)) {
  batch <- celex_list[i:min(i + batch_size - 1, length(celex_list))]
  values_str <- paste0('"', batch, '"', collapse = " ")
  title_query <- sprintf('
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
SELECT DISTINCT ?celex ?title WHERE {
  ?work cdm:resource_legal_id_celex ?celex .
  ?work cdm:work_has_expression ?expr .
  ?expr cdm:expression_uses_language <http://publications.europa.eu/resource/authority/language/ENG> .
  ?expr cdm:expression_title ?title .
  VALUES ?celex { %s }
}', values_str)

  batch_result <- tryCatch({
    resp <- httr::GET(
      "https://publications.europa.eu/webapi/rdf/sparql",
      query = list(query = title_query, format = "application/json"),
      httr::timeout(120)
    )
    if (httr::status_code(resp) == 200) {
      json <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
      if (length(json$results$bindings$celex$value) > 0) {
        tibble(
          celex = json$results$bindings$celex$value,
          title = tolower(json$results$bindings$title$value)
        )
      } else NULL
    } else NULL
  }, error = function(e) NULL)

  if (!is.null(batch_result)) all_titles[[length(all_titles) + 1]] <- batch_result
  cat("  Title batch", ceiling(i / batch_size), ":",
      ifelse(!is.null(batch_result), nrow(batch_result), 0), "titles\n")
  Sys.sleep(0.5)
}

titles_result <- if (length(all_titles) > 0) bind_rows(all_titles) else NULL

if (!is.null(titles_result) && nrow(titles_result) > 0) {
  cat("Got titles for", n_distinct(titles_result$celex), "directives.\n")

  dir_with_titles <- directives %>%
    select(celex, deadline_date, deadline_year) %>%
    left_join(titles_result %>% distinct(celex, .keep_all = TRUE), by = "celex")

  cat("Matched titles:", sum(!is.na(dir_with_titles$title)), "of", nrow(dir_with_titles), "\n")

  directive_sectors <- dir_with_titles %>%
    crossing(sector_keywords) %>%
    filter(!is.na(title)) %>%
    filter(str_detect(title, pattern)) %>%
    select(celex, deadline_date, deadline_year, nace_section, sector_label) %>%
    distinct(celex, nace_section, .keep_all = TRUE)

  cat("Directive-sector mappings:", nrow(directive_sectors), "\n")
  cat("Unique directives with sector mapping:", n_distinct(directive_sectors$celex), "\n")
} else {
  # Fallback: classify by CELEX directory code (chapters in EU law)
  cat("WARNING: Title query returned no results. Using CELEX directory codes.\n")
  # CELEX structure: 3YYYYL####, where YYYY=year, digits 2-3 encode the EU directory chapter
  directive_sectors <- directives %>%
    select(celex, deadline_date, deadline_year) %>%
    mutate(
      dir_num = as.integer(str_sub(celex, 6, 7))
    ) %>%
    # Assign each directive to ALL plausible sectors (conservative: map broadly)
    # We cannot narrow precisely without titles, so we assign to a general "all-sector" treatment
    # This attenuates the effect but avoids false precision
    crossing(tibble(
      nace_section = c("C", "G", "H", "K"),
      sector_label = c("Manufacturing", "Trade", "Transport", "Finance")
    )) %>%
    select(celex, deadline_date, deadline_year, nace_section, sector_label)
}

cat("\n=== Sector distribution of classified directives ===\n")
print(table(directive_sectors$sector_label))

# ---- 1e. Fetch Eurostat firm birth data ----
cat("\n=== STEP 2: Fetch Eurostat Business Demography Data ===\n")

# Try national-level first (more manageable)
cat("Fetching bd_enace2_r3 (NUTS3 business demography)...\n")

bd_data <- tryCatch({
  eurostat::get_eurostat("bd_enace2_r3", time_format = "num")
}, error = function(e) {
  cat("bd_enace2_r3 error:", e$message, "\n")
  NULL
})

if (is.null(bd_data) || nrow(bd_data) == 0) {
  cat("Trying national-level bd_enace2...\n")
  bd_data <- tryCatch({
    eurostat::get_eurostat("bd_enace2", time_format = "num")
  }, error = function(e) {
    cat("bd_enace2 error:", e$message, "\n")
    NULL
  })
}

stopifnot("FATAL: No Eurostat business demography data" = !is.null(bd_data) && nrow(bd_data) > 0)

cat("Retrieved", nrow(bd_data), "rows.\n")
cat("Variables:", paste(names(bd_data), collapse = ", "), "\n")
cat("Indicators:", paste(unique(bd_data$indic_sb)[1:5], collapse = ", "), "...\n")

# Firm births (V11920) and active enterprises (V11910)
firm_births <- bd_data %>%
  filter(indic_sb == "V11920") %>%
  mutate(
    geo2 = str_sub(geo, 1, 2),
    nace_section = str_sub(nace_r2, 1, 1),
    year = as.integer(TIME_PERIOD)
  ) %>%
  filter(
    geo2 %in% eu27,
    nchar(as.character(geo)) == 2,
    year >= 2008, year <= 2022
  )

active_ent <- bd_data %>%
  filter(indic_sb == "V11910") %>%
  mutate(
    geo2 = str_sub(geo, 1, 2),
    nace_section = str_sub(nace_r2, 1, 1),
    year = as.integer(TIME_PERIOD)
  ) %>%
  filter(
    geo2 %in% eu27,
    nchar(as.character(geo)) == 2,
    year >= 2008, year <= 2022
  ) %>%
  select(geo2, nace_section, year, nace_r2, active_ent = values)

firm_panel <- firm_births %>%
  select(geo2, nace_section, year, nace_r2, births = values) %>%
  left_join(active_ent, by = c("geo2", "nace_section", "year", "nace_r2")) %>%
  mutate(birth_rate = births / active_ent * 100)

cat("\nFirm birth data:\n")
cat("  Rows:", nrow(firm_panel), "\n")
cat("  Countries:", n_distinct(firm_panel$geo2), "\n")
cat("  NACE sections:", paste(sort(unique(firm_panel$nace_section)), collapse = ", "), "\n")
cat("  Years:", paste(range(firm_panel$year), collapse = " - "), "\n")
cat("  Mean birth rate:", round(mean(firm_panel$birth_rate, na.rm = TRUE), 2), "%\n")

stopifnot("Too few firm birth observations" = nrow(firm_panel) >= 100)

# ---- 1f. Save ----
saveRDS(limbo_panel, "../data/limbo_panel.rds")
saveRDS(directive_sectors, "../data/directive_sectors.rds")
saveRDS(firm_panel, "../data/firm_panel.rds")
saveRDS(late_by_country, "../data/late_by_country.rds")

cat("\n=== Data saved ===\n")
cat("  limbo_panel:", nrow(limbo_panel), "rows\n")
cat("  directive_sectors:", nrow(directive_sectors), "rows\n")
cat("  firm_panel:", nrow(firm_panel), "rows\n")
