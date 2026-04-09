# 01_fetch_data.R — Fetch Swiss employment and firm data from BFS PXWeb API
# APEP-1441: Swiss cantonal minimum wages

source("00_packages.R")

# ============================================================================
# JSON-stat2 parser for BFS PXWeb responses
# ============================================================================
parse_jsonstat2 <- function(raw_json) {
  jstat <- fromJSON(raw_json, simplifyVector = FALSE)
  dims <- jstat$dimension
  dim_order <- unlist(jstat$id)

  dim_labels <- lapply(dim_order, function(d) {
    cat_idx <- dims[[d]]$category$index
    cat_lab <- dims[[d]]$category$label
    if (is.list(cat_idx)) cat_idx <- unlist(cat_idx)
    if (is.list(cat_lab)) cat_lab <- unlist(cat_lab)
    lab_names <- names(cat_lab)
    idx_vals <- cat_idx[lab_names]
    cat_lab[order(unlist(idx_vals))]
  })
  names(dim_labels) <- dim_order

  grid <- expand.grid(rev(dim_labels), stringsAsFactors = FALSE)
  grid <- grid[, rev(names(grid))]

  raw_values <- jstat$value
  values <- sapply(raw_values, function(x) if (is.null(x)) NA_real_ else as.numeric(x))
  grid$value <- values
  grid
}

# ============================================================================
# 1. STATENT: Employment by canton x industry (2011-2023)
# ============================================================================
cat("Fetching STATENT employment data from BFS PXWeb...\n")

api_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_101/px-x-0602010000_101.px"

# Key NOGA 2-digit sectors:
# High-bite (low-wage): 47=retail, 55=accommodation, 56=food/beverage, 81=building services
# Low-bite (high-wage, placebo): 21=pharma, 62=IT, 64=financial services
# 999=total all sectors

all_data <- list()

for (obs_unit in c("1", "2", "5")) {
  obs_label <- switch(obs_unit, "1" = "establishments", "2" = "employment", "5" = "fte")
  cat("  Fetching", obs_label, "...\n")

  query <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item",
           values = as.list(as.character(2011:2023)))),
      list(code = "Kanton", selection = list(filter = "item",
           values = as.list(c("1","2","3","4","5","6","7","8","9","10",
                              "11","12","13","14","15","16","17","18","19",
                              "20","21","22","23","24","25","26")))),
      list(code = "Wirtschaftsabteilung", selection = list(filter = "item",
           values = as.list(c("999","47","55","56","81","21","62","64")))),
      list(code = "Beobachtungseinheit", selection = list(filter = "item",
           values = as.list(obs_unit)))
    ),
    response = list(format = "json-stat2")
  )

  data_resp <- POST(api_url,
                    body = toJSON(query, auto_unbox = TRUE),
                    content_type_json(), encode = "raw", timeout(120))

  if (status_code(data_resp) != 200) {
    stop("FATAL: BFS STATENT API returned HTTP ", status_code(data_resp), " for ", obs_label)
  }

  raw <- content(data_resp, "text", encoding = "UTF-8")
  grid <- parse_jsonstat2(raw)
  grid$measure <- obs_label
  all_data[[obs_label]] <- grid
  cat("    Rows:", nrow(grid), "\n")
}

statent <- do.call(rbind, all_data)
rownames(statent) <- NULL
write_csv(statent, "../data/statent_raw.csv")
cat("STATENT saved:", nrow(statent), "rows\n\n")

# ============================================================================
# 2. UDEMO: Firm demographics (births/closures) by canton (2013-2023)
# ============================================================================
cat("Fetching UDEMO firm demographics...\n")

udemo_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602030000_203/px-x-0602030000_203.px"

# Get metadata for canton and year codes
resp <- GET(udemo_url, timeout(10))
if (status_code(resp) != 200) stop("FATAL: UDEMO metadata unavailable")
meta <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)

canton_vals <- unlist(meta$variables[[2]]$values)
year_vals <- unlist(meta$variables[[4]]$values)
legal_vals <- unlist(meta$variables[[3]]$values)

# Query: active stock, new firms, closures x all cantons x all legal forms x all years
query <- list(
  query = list(
    list(code = "Beobachtungseinheit", selection = list(filter = "item",
         values = as.list(c("1", "2", "3")))),  # active, births, closures
    list(code = "Kanton", selection = list(filter = "item",
         values = as.list(canton_vals))),
    list(code = "Rechtsform", selection = list(filter = "item",
         values = as.list(legal_vals))),
    list(code = "Jahr", selection = list(filter = "item",
         values = as.list(year_vals)))
  ),
  response = list(format = "json-stat2")
)

data_resp <- POST(udemo_url,
                  body = toJSON(query, auto_unbox = TRUE),
                  content_type_json(), encode = "raw", timeout(120))

if (status_code(data_resp) != 200) {
  stop("FATAL: BFS UDEMO API returned HTTP ", status_code(data_resp))
}

raw <- content(data_resp, "text", encoding = "UTF-8")
udemo <- parse_jsonstat2(raw)
write_csv(udemo, "../data/udemo_raw.csv")
cat("UDEMO saved:", nrow(udemo), "rows\n\n")

# ============================================================================
# Validate data
# ============================================================================
cat("=== Data Validation ===\n")
cat("STATENT: ", nrow(statent), " rows, ", sum(!is.na(statent$value)), " non-missing values\n")
cat("UDEMO:   ", nrow(udemo), " rows, ", sum(!is.na(udemo$value)), " non-missing values\n")

# Check key cantons are present
statent_cantons <- unique(statent$Kanton)
cat("Cantons in STATENT:", length(statent_cantons), "\n")
stopifnot("Genève" %in% statent_cantons || "Gen\u00e8ve" %in% statent_cantons ||
          any(grepl("Gen", statent_cantons)))
stopifnot(any(grepl("Neuch", statent_cantons)))
stopifnot(any(grepl("Ticino|Tessin", statent_cantons)))
cat("All treated cantons present in data.\n")

cat("\n=== Data fetch complete ===\n")
