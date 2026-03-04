## 01_fetch_data.R — Fetch Swiss commune-level referendum data and merger timeline
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# Helper: read PXWeb CSV response (Windows-1252 encoded)
read_pxweb_csv <- function(resp) {
  raw <- content(resp, "raw")
  txt <- iconv(rawToChar(raw), from = "Windows-1252", to = "UTF-8")
  fread(text = txt, header = TRUE)
}

# =============================================================================
# 1. FETCH COMMUNE-LEVEL REFERENDUM DATA FROM BFS PXWEB (CSV FORMAT)
# =============================================================================

cat("=== Fetching commune-level referendum data from BFS PXWeb ===\n")

pxweb_base <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1703030000_101/px-x-1703030000_101.px"

# Get table metadata (always needed for commune code mapping)
meta_resp <- GET(pxweb_base, timeout(60))
stopifnot("BFS API unavailable" = meta_resp$status_code == 200)
meta <- content(meta_resp, "parsed")
dims <- meta$variables

commune_codes <- dims[[1]]$values
vote_codes <- dims[[2]]$values

cat(sprintf("Communes: %d, Votes: %d\n", length(commune_codes), length(vote_codes)))

# Check for cached raw data to avoid re-fetching
raw_cache <- file.path(DATA_DIR, "referendum_raw.csv")
if (file.exists(raw_cache) && file.size(raw_cache) > 1e6) {
  cat("Found cached referendum_raw.csv, loading...\n")
  referendum_raw <- fread(raw_cache)
  # Re-standardize column names if needed (from original German names)
  cn <- names(referendum_raw)
  if (any(grepl("Kanton", cn))) {
    setnames(referendum_raw, cn, c("commune_label", "vote_label", "eligible", "ballots",
                                     "turnout_pct", "valid", "yes_votes", "no_votes", "yes_pct")[seq_along(cn)])
  }
  cat(sprintf("Loaded %s rows from cache\n", format(nrow(referendum_raw), big.mark = ",")))
} else {

# CSV format returns all result columns directly (no need for result dimension selection)
# Columns: commune_label, vote_label, Stimmberechtigte, Abgegebene Stimmen,
#           Beteiligung in %, Gültige Stimmzettel, Ja, Nein, Ja in %

# Fetch in batches: 100 communes × 100 votes (larger batches = fewer API calls)
commune_batch_size <- 100
vote_batch_size <- 100
n_cb <- ceiling(length(commune_codes) / commune_batch_size)
n_vb <- ceiling(length(vote_codes) / vote_batch_size)

cat(sprintf("Fetching %d × %d = %d API calls (CSV format)...\n", n_cb, n_vb, n_cb * n_vb))

all_chunks <- list()
errors <- 0

for (ci in seq_len(n_cb)) {
  c_s <- (ci - 1) * commune_batch_size + 1
  c_e <- min(ci * commune_batch_size, length(commune_codes))

  for (vi in seq_len(n_vb)) {
    v_s <- (vi - 1) * vote_batch_size + 1
    v_e <- min(vi * vote_batch_size, length(vote_codes))

    query_body <- list(
      query = list(
        list(code = dims[[1]]$code,
             selection = list(filter = "item", values = as.list(commune_codes[c_s:c_e]))),
        list(code = dims[[2]]$code,
             selection = list(filter = "item", values = as.list(vote_codes[v_s:v_e])))
      ),
      response = list(format = "csv")
    )

    resp <- tryCatch({
      POST(pxweb_base,
           body = toJSON(query_body, auto_unbox = TRUE),
           content_type_json(),
           timeout(120))
    }, error = function(e) { errors <<- errors + 1; NULL })

    if (!is.null(resp) && resp$status_code == 200) {
      chunk <- tryCatch({
        dt <- read_pxweb_csv(resp)
        # Standardize column names to ensure consistent binding
        if (ncol(dt) == 9) {
          setnames(dt, c("commune_label", "vote_label", "eligible", "ballots",
                         "turnout_pct", "valid", "yes_votes", "no_votes", "yes_pct"))
        }
        dt
      }, error = function(e) NULL)
      if (!is.null(chunk) && nrow(chunk) > 0) {
        all_chunks[[length(all_chunks) + 1]] <- chunk
      }
    } else {
      errors <- errors + 1
    }
    Sys.sleep(0.05)
  }

  if (ci %% 5 == 0) {
    total_rows <- sum(vapply(all_chunks, nrow, integer(1)))
    cat(sprintf("  Batch %d/%d: %s rows, %d errors\n",
                ci, n_cb, format(total_rows, big.mark = ","), errors))
  }
}

cat(sprintf("API complete: %d chunks, %d errors\n", length(all_chunks), errors))
stopifnot("No data returned from BFS API" = length(all_chunks) > 0)

# Combine all chunks
referendum_raw <- rbindlist(all_chunks, fill = TRUE)
cat(sprintf("Raw referendum data: %s rows, %d columns\n",
            format(nrow(referendum_raw), big.mark = ","), ncol(referendum_raw)))
cat("Column names:\n")
print(names(referendum_raw))

# Save raw data immediately
fwrite(referendum_raw, file.path(DATA_DIR, "referendum_raw.csv"))
cat("Saved referendum_raw.csv\n")

}  # end of cache check else block

# =============================================================================
# 2. STANDARDIZE COLUMNS
# =============================================================================

cat("\n=== Standardizing referendum data ===\n")

# Columns already renamed during batch loop to:
# commune_label, vote_label, eligible, ballots, turnout_pct, valid, yes_votes, no_votes, yes_pct
cat("Columns:", paste(names(referendum_raw), collapse = " | "), "\n")

# Extract commune code from label
# Labels look like: "......Zürich" for communes, "- Zürich" for cantons, ">> Bezirk" for districts
# Commune labels start with "......" (6 dots)
# But the code info is in the metadata, not the label — use position in commune_codes
# Actually, the API returns rows for the exact communes we requested
# The commune_codes list has the BFS numbers — we need to map labels to codes

# Build commune label → code mapping from metadata
commune_labels_meta <- unlist(dims[[1]]$valueTexts)
commune_codes_meta <- unlist(dims[[1]]$values)
commune_mapping <- data.table(
  commune_label = commune_labels_meta,
  commune_code = commune_codes_meta
)

# Merge to get commune codes
referendum_raw <- merge(referendum_raw, commune_mapping, by = "commune_label", all.x = TRUE)
cat(sprintf("After commune code merge: %s rows\n", format(nrow(referendum_raw), big.mark = ",")))
cat(sprintf("  Missing commune codes: %d\n", sum(is.na(referendum_raw$commune_code))))

# Parse vote date from label (format: "YYYY-MM-DD Vorlage text")
referendum_raw[, date_str := str_extract(vote_label, "^\\d{4}-\\d{2}-\\d{2}")]
referendum_raw[, vote_date := as.Date(date_str)]
referendum_raw[, vote_year := year(vote_date)]

cat(sprintf("  Missing vote dates: %d\n", sum(is.na(referendum_raw$vote_date))))

# Keep only commune-level rows (have valid commune codes and dates)
referendum_panel <- referendum_raw[!is.na(commune_code) & !is.na(vote_date)]

cat(sprintf("Referendum panel: %s commune-vote observations\n",
            format(nrow(referendum_panel), big.mark = ",")))
cat(sprintf("  Unique communes: %d\n", uniqueN(referendum_panel$commune_code)))
cat(sprintf("  Unique vote dates: %d\n", uniqueN(referendum_panel$vote_date)))
cat(sprintf("  Year range: %d to %d\n",
            min(referendum_panel$vote_year), max(referendum_panel$vote_year)))

fwrite(referendum_panel, file.path(DATA_DIR, "referendum_panel.csv"))
cat("Saved referendum_panel.csv\n")

# =============================================================================
# 3. FETCH COMMUNE MERGER TIMELINE FROM BFS MUTATIONS API
# =============================================================================

cat("\n=== Fetching commune merger timeline from BFS ===\n")

mutations_url <- "https://www.agvchapp.bfs.admin.ch/api/communes/mutations?includeTerritoryExchange=true&startPeriod=01-01-1960&endPeriod=01-01-2026"
mutations_resp <- GET(mutations_url, timeout(120))
stopifnot("BFS mutations API failed" = mutations_resp$status_code == 200)

mutations_txt <- content(mutations_resp, "text", encoding = "UTF-8")
mutations <- fread(text = mutations_txt, header = TRUE)
cat(sprintf("Total mutations: %d\n", nrow(mutations)))

# Parse mutation dates
mutations[, mutation_date := as.Date(MutationDate, format = "%d.%m.%Y")]
mutations[, mutation_year := as.integer(format(mutation_date, "%Y"))]

# Identify MERGER events: commune code changes where multiple initial codes → fewer terminal codes
# TerminalStep 21 = Vereinigung (fusion), 26 = Eingemeindung (incorporation)
merger_mutations <- mutations[InitialCode != TerminalCode]

# Group by MutationNumber to identify actual mergers
mutation_groups <- merger_mutations[, .(
  n_initial = uniqueN(InitialCode),
  n_terminal = uniqueN(TerminalCode),
  initial_codes = list(unique(InitialCode)),
  terminal_codes = list(unique(TerminalCode)),
  initial_names = list(unique(InitialName)),
  terminal_names = list(unique(TerminalName)),
  year = first(mutation_year),
  date = first(mutation_date)
), by = MutationNumber]

# Keep only genuine mergers (multiple originals or code actually changed)
mergers <- mutation_groups[n_initial >= 2 | n_terminal == 1]
cat(sprintf("Merger events: %d\n", nrow(mergers)))

# For each merger, identify the SUCCESSOR commune (terminal code)
# This is the commune in our current-boundary referendum data
merger_list <- list()
for (i in seq_len(nrow(mergers))) {
  terminal <- unlist(mergers$terminal_codes[[i]])
  initial <- unlist(mergers$initial_codes[[i]])
  initial_names <- unlist(mergers$initial_names[[i]])
  for (tc in terminal) {
    merger_list[[length(merger_list) + 1]] <- data.table(
      successor_code = as.character(tc),
      merger_year = mergers$year[i],
      merger_date = mergers$date[i],
      n_absorbed = length(initial),
      absorbed_codes = paste(initial, collapse = ";"),
      absorbed_names = paste(initial_names, collapse = ";"),
      mutation_number = mergers$MutationNumber[i]
    )
  }
}

merger_timeline <- rbindlist(merger_list)
cat(sprintf("Successor communes: %d\n", uniqueN(merger_timeline$successor_code)))

# For communes with multiple mergers, keep the first one (treatment year)
first_merger <- merger_timeline[, .(
  first_merger_year = min(merger_year),
  total_absorbed = sum(n_absorbed),
  n_merger_events = .N
), by = successor_code]

cat(sprintf("Unique treated communes: %d\n", nrow(first_merger)))

# Save
fwrite(merger_timeline, file.path(DATA_DIR, "merger_timeline.csv"))
fwrite(first_merger, file.path(DATA_DIR, "first_merger.csv"))
fwrite(mutations, file.path(DATA_DIR, "commune_mutations.csv"))

# Show merger timeline
merger_by_year <- merger_timeline[, .N, by = merger_year][order(merger_year)]
cat("\nMerger events by year:\n")
print(merger_by_year[merger_year >= 2000])

# Save vote dates lookup
vote_dates <- unique(referendum_panel[, .(vote_label, vote_date, vote_year)])
fwrite(vote_dates, file.path(DATA_DIR, "vote_dates.csv"))

# =============================================================================
# 4. SWISSVOTES METADATA
# =============================================================================

cat("\n=== Fetching Swissvotes metadata ===\n")

tryCatch({
  download.file("https://swissvotes.ch/storage/votes/swissvotes_dataset.csv",
                file.path(DATA_DIR, "swissvotes_dataset.csv"), mode = "wb", quiet = TRUE)
  sv <- fread(file.path(DATA_DIR, "swissvotes_dataset.csv"), encoding = "UTF-8")
  cat(sprintf("Swissvotes: %d votes\n", nrow(sv)))
}, error = function(e) {
  cat("Warning: Swissvotes download failed:", e$message, "\n")
  cat("Continuing without Swissvotes metadata.\n")
})

# =============================================================================
# 5. POPULATION DATA
# =============================================================================

cat("\n=== Fetching population data ===\n")

pop_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102010000_101/px-x-0102010000_101.px"
pop_meta_resp <- GET(pop_url, timeout(60))

if (pop_meta_resp$status_code == 200) {
  pop_meta <- content(pop_meta_resp, "parsed")
  pop_dims <- pop_meta$variables
  pop_commune_codes <- pop_dims[[1]]$values

  # Build query for total population: select totals for classification dims
  query_sels <- list()
  for (i in 2:length(pop_dims)) {
    d <- pop_dims[[i]]
    if (i == length(pop_dims)) {
      # Year dimension — take all
      query_sels[[length(query_sels) + 1]] <- list(
        code = d$code,
        selection = list(filter = "item", values = as.list(d$values)))
    } else {
      total_val <- d$values[1]
      tidx <- which(d$values == "-99999")
      if (length(tidx) > 0) total_val <- "-99999"
      query_sels[[length(query_sels) + 1]] <- list(
        code = d$code,
        selection = list(filter = "item", values = list(total_val)))
    }
  }

  pop_chunks <- list()
  pop_bs <- 200
  for (b in seq_len(ceiling(length(pop_commune_codes) / pop_bs))) {
    s <- (b - 1) * pop_bs + 1
    e <- min(b * pop_bs, length(pop_commune_codes))
    full_query <- list(
      query = c(list(list(code = pop_dims[[1]]$code,
                          selection = list(filter = "item",
                                          values = as.list(pop_commune_codes[s:e])))),
                query_sels),
      response = list(format = "csv"))

    resp <- tryCatch(POST(pop_url, body = toJSON(full_query, auto_unbox = TRUE),
                          content_type_json(), timeout(120)), error = function(e) NULL)
    if (!is.null(resp) && resp$status_code == 200) {
      chunk <- tryCatch(read_pxweb_csv(resp), error = function(e) NULL)
      if (!is.null(chunk) && nrow(chunk) > 0) pop_chunks[[length(pop_chunks) + 1]] <- chunk
    }
    Sys.sleep(0.05)
  }

  if (length(pop_chunks) > 0) {
    population <- rbindlist(pop_chunks, fill = TRUE)
    fwrite(population, file.path(DATA_DIR, "population_raw.csv"))
    cat(sprintf("Population data: %s rows saved\n", format(nrow(population), big.mark = ",")))
  }
} else {
  cat("Population API unavailable, continuing.\n")
}

# =============================================================================
# VALIDATION
# =============================================================================

cat("\n=== DATA VALIDATION ===\n")

stopifnot("Expected 100K+ referendum observations" = nrow(referendum_panel) >= 100000)
stopifnot("Expected 1000+ unique communes" = uniqueN(referendum_panel$commune_code) >= 1000)
stopifnot("Expected 100+ vote dates" = uniqueN(referendum_panel$vote_date) >= 100)
stopifnot("Expected merger events" = nrow(first_merger) >= 20)

cat(sprintf("VALIDATION PASSED:\n"))
cat(sprintf("  Observations: %s\n", format(nrow(referendum_panel), big.mark = ",")))
cat(sprintf("  Communes: %d\n", uniqueN(referendum_panel$commune_code)))
cat(sprintf("  Vote dates: %d\n", uniqueN(referendum_panel$vote_date)))
cat(sprintf("  Merger successor communes: %d\n", nrow(first_merger)))
cat("\nData fetch complete.\n")
