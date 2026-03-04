# =============================================================================
# 01_fetch_data.R — Fetch merger data and referendum turnout
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

source("00_packages.R")

# =============================================================================
# PART 1: Municipality Merger Data from BFS AGVCH Mutations API
# =============================================================================

cat("\n=== PART 1: Fetching municipal merger data from AGVCH ===\n")

mutations_url <- paste0(
  "https://www.agvchapp.bfs.admin.ch/api/communes/mutations",
  "?includeTerritoryExchange=false",
  "&startPeriod=01-01-1990",
  "&endPeriod=31-12-2024"
)

tryCatch({
  resp <- GET(mutations_url, timeout(120))
  if (status_code(resp) != 200) {
    stop("AGVCH mutations API returned status ", status_code(resp))
  }
  mutations_raw <- content(resp, as = "text", encoding = "UTF-8")
  mutations <- fread(text = mutations_raw)
  cat("  Downloaded", nrow(mutations), "mutation records\n")
}, error = function(e) {
  stop("Failed to fetch merger data: ", e$message,
       "\nPivot research question or fix the source.")
})

mutations[, MutationDate := as.Date(MutationDate, format = "%d.%m.%Y")]
mutations[, merger_year := year(MutationDate)]

# Identify dissolutions (InitialStep == 29 = municipality dissolved)
dissolved <- mutations[InitialStep == 29]
cat("  Municipalities dissolved: ", nrow(dissolved), "\n")
cat("  Unique merger events: ", uniqueN(dissolved$MutationNumber), "\n")

# Build crosswalk: dissolved → successor
# For each merger event, find the successor (TerminalStep 21 = new creation, 26 = absorber continues)
successors <- mutations[MutationNumber %in% dissolved$MutationNumber &
                          TerminalStep %in% c(21, 26)]

merger_xwalk <- merge(
  dissolved[, .(MutationNumber, dissolved_code = InitialCode,
                dissolved_name = InitialName, merger_year, MutationDate)],
  successors[, .(MutationNumber, successor_code = TerminalCode,
                 successor_name = TerminalName)],
  by = "MutationNumber",
  allow.cartesian = TRUE
)
merger_xwalk <- unique(merger_xwalk)
cat("  Merger crosswalk: ", nrow(merger_xwalk), " mappings\n")

fwrite(merger_xwalk, file.path(DATA_DIR, "merger_crosswalk.csv"))
fwrite(mutations, file.path(DATA_DIR, "mutations_full.csv"))

# =============================================================================
# PART 2: Current municipality snapshot
# =============================================================================

cat("\n=== PART 2: Fetching municipality snapshot ===\n")

snap_url <- "https://www.agvchapp.bfs.admin.ch/api/communes/snapshot?date=01-01-2024"

tryCatch({
  resp <- GET(snap_url, timeout(60))
  if (status_code(resp) != 200) stop("Snapshot API returned status ", status_code(resp))
  snap_raw <- content(resp, as = "text", encoding = "UTF-8")
  snapshot <- fread(text = snap_raw)
  cat("  Current municipalities: ", nrow(snapshot), "\n")
}, error = function(e) {
  stop("Failed to fetch snapshot: ", e$message)
})

fwrite(snapshot, file.path(DATA_DIR, "municipality_snapshot_2024.csv"))

# =============================================================================
# PART 3: Referendum turnout from BFS PXWeb (commune level, since 1960)
# =============================================================================

cat("\n=== PART 3: Fetching referendum turnout from BFS PXWeb ===\n")
cat("  Dataset: px-x-1703030000_101 (Volksabstimmungen Gemeinde seit 1960)\n")

# First get the metadata to list all vote dates
meta_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1703030000_101/px-x-1703030000_101.px"

tryCatch({
  resp <- GET(meta_url, timeout(60))
  if (status_code(resp) != 200) stop("PXWeb meta returned status ", status_code(resp))
  meta <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
}, error = function(e) {
  stop("Failed to fetch PXWeb metadata: ", e$message)
})

# Extract variable info — variables is a data.frame in PXWeb JSON
vars <- meta$variables
geo_row <- which(grepl("Gemeinde", vars$code))
vote_row <- which(grepl("Datum", vars$code))
result_row <- which(grepl("Ergebnis", vars$code))

geo_code <- vars$code[geo_row]
vote_code <- vars$code[vote_row]
result_code <- vars$code[result_row]

geo_values <- vars$values[[geo_row]]
geo_texts <- vars$valueTexts[[geo_row]]
vote_values <- vars$values[[vote_row]]
vote_texts <- vars$valueTexts[[vote_row]]
result_values <- vars$values[[result_row]]
result_texts <- vars$valueTexts[[result_row]]

cat("  Communes: ", length(geo_values), "\n")
cat("  Vote dates: ", length(vote_values), "\n")
cat("  Result types: ", paste(result_texts, collapse = ", "), "\n")

# Filter to votes from 1990 onward
vote_years <- as.integer(substr(vote_texts, 1, 4))
votes_post1990 <- which(vote_years >= 1990)
cat("  Votes 1990+: ", length(votes_post1990), "\n")

# Filter geo to commune-level only (starts with "......")
commune_mask <- startsWith(geo_texts, "......")
commune_vals <- geo_values[commune_mask]
commune_texts <- geo_texts[commune_mask]
cat("  Communes: ", length(commune_vals), "\n")

# We want "Beteiligung in %" (turnout) — index 3
turnout_idx <- which(result_texts == "Beteiligung in %")
eligible_idx <- which(result_texts == "Stimmberechtigte")
cat("  Fetching: Beteiligung in % (idx ", turnout_idx, ") + Stimmberechtigte (idx ", eligible_idx, ")\n")

# Query 1 vote date at a time, all communes, 2 result types
# 2156 communes × 1 vote × 2 results = 4,312 cells — well within limits
all_dfs <- list()

for (v in seq_along(votes_post1990)) {
  vidx <- votes_post1990[v]

  query <- list(
    query = list(
      list(code = geo_code, selection = list(
        filter = "item", values = as.list(commune_vals)
      )),
      list(code = vote_code, selection = list(
        filter = "item", values = list(vote_values[vidx])
      )),
      list(code = result_code, selection = list(
        filter = "item", values = as.list(result_values[c(turnout_idx, eligible_idx)])
      ))
    ),
    response = list(format = "json-stat2")
  )

  tryCatch({
    resp <- POST(meta_url, body = toJSON(query, auto_unbox = TRUE),
                 content_type_json(), timeout(120))

    if (status_code(resp) != 200) {
      if (v %% 50 == 0) cat("  Vote", v, "failed (status", status_code(resp), ")\n")
      next
    }

    js <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))

    # Parse: dimensions are geo × vote × result
    dims <- js$dimension
    dim_names <- names(dims)
    dim_sizes <- js$size
    values <- unlist(js$value)

    # Get geo labels for this response
    geo_dim <- dims[[dim_names[grepl("Gemeinde|Kanton", dim_names)]]]
    geo_labs <- unlist(geo_dim$category$label)

    # Get result labels
    res_dim <- dims[[dim_names[grepl("Ergebnis", dim_names)]]]
    res_labs <- unlist(res_dim$category$label)

    # Values are arranged: geo (fast) × vote × result (slow)
    n_geo <- length(geo_labs)
    n_res <- length(res_labs)

    if (length(values) != n_geo * n_res) {
      # Unexpected shape, skip
      next
    }

    # Build data table — JSON-stat2: last dimension (result) varies fastest
    # Values: geo0_res0, geo0_res1, geo1_res0, geo1_res1, ...
    batch_dt <- data.table(
      geo_label = rep(geo_labs, each = n_res),
      result_type = rep(res_labs, times = n_geo),
      value = as.numeric(values),
      vote_label = vote_texts[vidx],
      vote_date = as.Date(substr(vote_texts[vidx], 1, 10), format = "%Y-%m-%d")
    )
    all_dfs[[length(all_dfs) + 1]] <- batch_dt

    if (v %% 50 == 0) cat("  Processed vote", v, "of", length(votes_post1990), "\n")
    Sys.sleep(0.2)
  }, error = function(e) {
    if (v %% 50 == 0) cat("  Vote", v, "error:", e$message, "\n")
  })
}

cat("  Successfully fetched", length(all_dfs), "of", length(votes_post1990), "votes\n")

if (length(all_dfs) == 0) {
  stop("No referendum data successfully fetched. Check API access.")
}

ref_data <- rbindlist(all_dfs, fill = TRUE)
cat("  Total rows: ", nrow(ref_data), "\n")

# Add vote_year
ref_data[, vote_year := year(vote_date)]

# Pivot wide per proposal (include vote_label for uniqueness)
ref_wide <- dcast(ref_data, geo_label + vote_label + vote_date + vote_year ~ result_type,
                  value.var = "value")

if ("Beteiligung in %" %in% names(ref_wide))
  setnames(ref_wide, "Beteiligung in %", "turnout_pct")
if ("Stimmberechtigte" %in% names(ref_wide))
  setnames(ref_wide, "Stimmberechtigte", "eligible_voters")

cat("  Per-proposal: ", nrow(ref_wide), " obs\n")
cat("  Turnout range: ", range(ref_wide$turnout_pct, na.rm = TRUE), "\n")
cat("  Eligible voters range: ", range(ref_wide$eligible_voters, na.rm = TRUE), "\n")

# Aggregate to vote_date level (mean turnout, max eligible across proposals)
ref_daily <- ref_wide[, .(
  turnout_pct = mean(turnout_pct, na.rm = TRUE),
  eligible_voters = max(eligible_voters, na.rm = TRUE),
  n_proposals = .N
), by = .(geo_label, vote_date, vote_year)]

cat("  Daily panel: ", nrow(ref_daily), " obs, ",
    uniqueN(ref_daily$geo_label), " communes, ",
    uniqueN(ref_daily$vote_date), " vote dates\n")
cat("  Mean turnout: ", round(mean(ref_daily$turnout_pct, na.rm = TRUE), 1), "%\n")

fwrite(ref_daily, file.path(DATA_DIR, "referendum_turnout.csv"))
cat("  Saved referendum_turnout.csv\n")

# =============================================================================
# PART 4: National Council election turnout (commune level, backup outcome)
# =============================================================================

cat("\n=== PART 4: Fetching National Council election turnout ===\n")

elec_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1702020000_101/px-x-1702020000_101.px"

tryCatch({
  resp <- GET(elec_url, timeout(60))
  elec_meta <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
}, error = function(e) {
  stop("Failed to fetch election metadata: ", e$message)
})

elec_vars <- elec_meta$variables  # data.frame
elec_geo_row <- which(grepl("Gemeinde|Kanton", elec_vars$code))
elec_result_row <- which(grepl("Ergebnis", elec_vars$code))

elec_geo_code <- elec_vars$code[elec_geo_row]
elec_result_code <- elec_vars$code[elec_result_row]
elec_result_texts <- elec_vars$valueTexts[[elec_result_row]]
elec_result_values <- elec_vars$values[[elec_result_row]]

# Filter to communes only
elec_geo_texts <- elec_vars$valueTexts[[elec_geo_row]]
elec_geo_values <- elec_vars$values[[elec_geo_row]]
elec_commune_mask <- startsWith(elec_geo_texts, "......")
elec_commune_vals <- elec_geo_values[elec_commune_mask]

# Get turnout result indices
turnout_idx <- which(elec_result_texts %in% c("Wahlberechtigte",
                                                "Wählende / Eingelegte Wahlzettel (WZ)",
                                                "Wahlbeteiligung [%]"))
cat("  Election result types: ", paste(elec_result_texts[turnout_idx], collapse = ", "), "\n")

elec_query <- list(
  query = list(
    list(code = elec_geo_code, selection = list(
      filter = "item", values = as.list(elec_commune_vals)
    )),
    list(code = elec_result_code, selection = list(
      filter = "item", values = as.list(elec_result_values[turnout_idx])
    ))
  ),
  response = list(format = "json-stat2")
)

tryCatch({
  resp <- POST(elec_url, body = toJSON(elec_query, auto_unbox = TRUE),
               content_type_json(), timeout(120))
  if (status_code(resp) != 200) stop("Election query returned status ", status_code(resp))

  js <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  dims <- js$dimension
  dim_names <- names(dims)
  values <- unlist(js$value)

  # Get labels for each dimension
  dim_labs <- lapply(dims, function(d) unlist(d$category$label))
  dim_sizes <- js$size

  # Create grid
  idx_list <- lapply(dim_sizes, seq_len)
  idx_grid <- do.call(expand.grid, idx_list)
  elec_data <- data.table(idx_grid)

  for (i in seq_along(dim_names)) {
    labs <- dim_labs[[i]]
    elec_data[, (dim_names[i]) := labs[get(paste0("Var", i))]]
  }
  elec_data[, value := as.numeric(values)]

  # Rename
  old_names <- names(elec_data)
  geo_col <- old_names[grepl("Gemeinde|Kanton", old_names)]
  year_col <- old_names[grepl("Jahr", old_names)]
  result_col <- old_names[grepl("Ergebnis", old_names)]

  if (length(geo_col) > 0) setnames(elec_data, geo_col[1], "geo_label")
  if (length(year_col) > 0) setnames(elec_data, year_col[1], "year")
  if (length(result_col) > 0) setnames(elec_data, result_col[1], "result_type")

  # Remove index columns
  idx_cols <- grep("^Var[0-9]+$", names(elec_data), value = TRUE)
  if (length(idx_cols) > 0) elec_data[, (idx_cols) := NULL]

  elec_data[, year := as.integer(year)]
  elec_data <- elec_data[startsWith(geo_label, "......")]

  # Pivot wide
  elec_wide <- dcast(elec_data, geo_label + year ~ result_type, value.var = "value")
  if ("Wahlbeteiligung [%]" %in% names(elec_wide))
    setnames(elec_wide, "Wahlbeteiligung [%]", "election_turnout_pct")

  cat("  Election panel: ", nrow(elec_wide), " obs, ",
      uniqueN(elec_wide$geo_label), " communes, ",
      uniqueN(elec_wide$year), " years\n")

  fwrite(elec_wide, file.path(DATA_DIR, "election_turnout.csv"))
  cat("  Saved election_turnout.csv\n")
}, error = function(e) {
  cat("  Warning: Election data fetch failed:", e$message, "\n")
  cat("  Continuing without election data (using referendum data only)\n")
})

# =============================================================================
# PART 5: Population data from BFS PXWeb (German endpoint)
# =============================================================================

cat("\n=== PART 5: Fetching population data ===\n")

# Use German endpoint — dimension codes are German
pop_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102010000_101/px-x-0102010000_101.px"

# First get metadata to find commune-level geo values
tryCatch({
  resp <- GET(pop_url, timeout(60))
  if (status_code(resp) != 200) stop("Pop metadata returned status ", status_code(resp))
  pop_meta <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
}, error = function(e) {
  stop("Failed to fetch population metadata: ", e$message)
})

pop_vars <- pop_meta$variables
# Geo dimension: "Kanton (-) / Bezirk (>>) / Gemeinde (......)"
geo_row <- which(grepl("Gemeinde", pop_vars$code))
geo_code <- pop_vars$code[geo_row]
geo_texts <- pop_vars$valueTexts[[geo_row]]
geo_values <- pop_vars$values[[geo_row]]

# Filter to commune level only (starts with "......")
commune_mask <- startsWith(geo_texts, "......")
commune_vals <- geo_values[commune_mask]
cat("  Communes in population dataset: ", length(commune_vals), "\n")

# Query: all communes × all years × total pop × total nationality × total sex × total age
pop_query <- list(
  query = list(
    list(code = geo_code, selection = list(
      filter = "item", values = as.list(commune_vals)
    )),
    list(code = "Bev\u00f6lkerungstyp", selection = list(
      filter = "item", values = list("1")
    )),
    list(code = "Staatsangeh\u00f6rigkeit (Kategorie)", selection = list(
      filter = "item", values = list("-99999")
    )),
    list(code = "Geschlecht", selection = list(
      filter = "item", values = list("-99999")
    )),
    list(code = "Alter", selection = list(
      filter = "item", values = list("-99999")
    ))
  ),
  response = list(format = "json-stat2")
)

tryCatch({
  resp <- POST(pop_url, body = toJSON(pop_query, auto_unbox = TRUE),
               content_type_json(), timeout(180))
  if (status_code(resp) != 200) stop("Population query returned status ", status_code(resp))

  js <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  dims <- js$dimension
  dim_names <- names(dims)
  values <- unlist(js$value)

  # Get labels for geo and year dimensions
  geo_dim_name <- dim_names[grepl("Gemeinde|Kanton", dim_names)]
  year_dim_name <- dim_names[grepl("Jahr", dim_names)]
  geo_labs <- unlist(dims[[geo_dim_name]]$category$label)
  year_labs <- unlist(dims[[year_dim_name]]$category$label)

  cat("  Response: ", length(values), " values, ",
      length(geo_labs), " communes × ", length(year_labs), " years\n")

  # Values are arranged: geo (fastest) × year (next) × other dims (size 1 each)
  # Since other dims are all size 1, it's just geo × year
  n_geo <- length(geo_labs)
  n_year <- length(year_labs)

  pop_dt <- data.table(
    geo_label = rep(geo_labs, times = n_year),
    year = rep(as.integer(year_labs), each = n_geo),
    population = as.numeric(values)
  )

  # Extract BFS number from labels like "......0001 Aeugst am Albis"
  pop_dt[, bfs_nr := as.integer(sub("^\\.+([0-9]+)\\s.*$", "\\1", geo_label))]
  pop_dt <- pop_dt[!is.na(bfs_nr), .(bfs_nr, year, population)]

  cat("  Population: ", nrow(pop_dt), " obs, ",
      uniqueN(pop_dt$bfs_nr), " communes, ",
      min(pop_dt$year), "-", max(pop_dt$year), "\n")

  fwrite(pop_dt, file.path(DATA_DIR, "population_municipal.csv"))
  cat("  Saved population_municipal.csv\n")
}, error = function(e) {
  stop("Failed to fetch population data: ", e$message,
       "\nPivot research question or fix the source.")
})

# =============================================================================
# DATA VALIDATION
# =============================================================================

cat("\n=== Data Validation ===\n")

stopifnot("Expected 300+ merger events" =
            uniqueN(merger_xwalk$MutationNumber) >= 300)
stopifnot("Expected 500+ dissolved municipalities" =
            uniqueN(merger_xwalk$dissolved_code) >= 500)

ref_check <- fread(file.path(DATA_DIR, "referendum_turnout.csv"), nrows = 100)
stopifnot("Referendum data has turnout column" = "turnout_pct" %in% names(ref_check))

pop_check <- fread(file.path(DATA_DIR, "population_municipal.csv"), nrows = 100)
stopifnot("Population data has population column" = "population" %in% names(pop_check))

cat("\nAll data fetched and validated successfully.\n")
cat("  Mergers: ", uniqueN(merger_xwalk$MutationNumber), " events, ",
    nrow(merger_xwalk), " mappings\n")
