# 01_fetch_data.R — Fetch Swiss BFS STATENT and LSE data
source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

HEADERS <- httr::add_headers(
  `User-Agent` = "Mozilla/5.0 (R/httr; APEP research)",
  `Accept` = "application/json",
  `Referer` = "https://www.pxweb.bfs.admin.ch/"
)

parse_jsonstat2 <- function(json_text) {
  j <- jsonlite::fromJSON(json_text)
  dims <- j$dimension
  dim_order <- j$id  # dimension order from the response
  if (is.null(dim_order)) dim_order <- names(dims)

  dim_labels <- lapply(dim_order, function(d) {
    labs <- dims[[d]]$category$label
    if (is.list(labs)) unlist(labs) else labs
  })
  names(dim_labels) <- dim_order

  # JSON-stat2: last dimension varies fastest (row-major)
  # expand.grid: first variable varies fastest
  # So we need to REVERSE the order for expand.grid, then reverse columns back
  rev_labels <- rev(dim_labels)
  grid <- expand.grid(rev_labels, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  # Reverse columns to restore original dimension order
  grid <- grid[, rev(seq_len(ncol(grid))), drop = FALSE]
  names(grid) <- dim_order

  vals <- j$value
  if (is.null(vals)) vals <- j$values
  grid$value <- NA_real_
  if (length(vals) > 0) {
    grid$value[seq_along(vals)] <- as.numeric(vals)
  }
  as.data.table(grid)
}

pxweb_post <- function(url, body_json, retries = 4, wait = 5) {
  for (i in seq_len(retries)) {
    resp <- tryCatch(
      httr::POST(url, body = body_json, httr::content_type_json(), HEADERS, httr::timeout(120)),
      error = function(e) NULL
    )
    if (!is.null(resp) && httr::status_code(resp) == 200) return(resp)
    cat(sprintf("  Retry %d (status %s)\n", i,
                if (!is.null(resp)) httr::status_code(resp) else "error"))
    Sys.sleep(wait * i)
  }
  stop("POST failed after ", retries, " retries")
}

pxweb_meta <- function(table_id) {
  url <- sprintf("https://www.pxweb.bfs.admin.ch/api/v1/de/%s/%s.px", table_id, table_id)
  resp <- httr::GET(url, httr::timeout(30), HEADERS)
  stopifnot(httr::status_code(resp) == 200)
  jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
}

# ============================================================
# 1. LSE: Wages by NOGA x Gender x Year
# ============================================================

cat("=== 1. LSE wages by NOGA x Gender ===\n")
lse_meta <- pxweb_meta("px-x-0304010000_201")

lse_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0304010000_201/px-x-0304010000_201.px"
lse_query <- list(
  query = list(
    list(code = "Jahr", selection = list(filter = "item",
         values = as.list(lse_meta$variables$values[[1]]))),
    list(code = "Grossregion", selection = list(filter = "item",
         values = list("-1"))),  # Switzerland only
    list(code = "Wirtschaftsabteilung", selection = list(filter = "item",
         values = as.list(lse_meta$variables$values[[3]]))),
    list(code = "Berufliche Stellung", selection = list(filter = "item",
         values = list("-1"))),  # Total
    list(code = "Geschlecht", selection = list(filter = "item",
         values = list("-1", "1", "2"))),
    list(code = "Zentralwert und andere Perzentile", selection = list(filter = "item",
         values = list("1")))  # Median
  ),
  response = list(format = "json-stat2")
)

Sys.sleep(3)
lse_resp <- pxweb_post(lse_url, jsonlite::toJSON(lse_query, auto_unbox = TRUE))
lse_dt <- parse_jsonstat2(httr::content(lse_resp, "text", encoding = "UTF-8"))
cat(sprintf("LSE: %d rows\n", nrow(lse_dt)))
print(head(lse_dt, 5))
fwrite(lse_dt, file.path(data_dir, "lse_wages.csv"))

# ============================================================
# 2. STATENT: By Canton x NOGA x Year — chunk by year
# ============================================================

cat("\n=== 2. STATENT by Canton x NOGA ===\n")
statent_meta <- pxweb_meta("px-x-0602010000_101")
Sys.sleep(3)

statent_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_101/px-x-0602010000_101.px"
years <- statent_meta$variables$values[[1]]
cat(sprintf("Years: %s\n", paste(years, collapse = ", ")))

all_statent <- list()
for (yr in years) {
  cat(sprintf("  %s...", yr))
  q <- list(
    query = list(
      list(code = statent_meta$variables$code[1],
           selection = list(filter = "item", values = list(yr))),
      list(code = statent_meta$variables$code[2],
           selection = list(filter = "item",
                            values = as.list(statent_meta$variables$values[[2]]))),
      list(code = statent_meta$variables$code[3],
           selection = list(filter = "item",
                            values = as.list(statent_meta$variables$values[[3]]))),
      list(code = statent_meta$variables$code[4],
           selection = list(filter = "item",
                            values = as.list(statent_meta$variables$values[[4]])))
    ),
    response = list(format = "json-stat2")
  )
  Sys.sleep(3)
  resp <- tryCatch(
    pxweb_post(statent_url, jsonlite::toJSON(q, auto_unbox = TRUE)),
    error = function(e) { cat(" FAILED\n"); NULL }
  )
  if (!is.null(resp)) {
    chunk <- parse_jsonstat2(httr::content(resp, "text", encoding = "UTF-8"))
    all_statent[[length(all_statent) + 1]] <- chunk
    cat(sprintf(" %d rows\n", nrow(chunk)))
  }
}

statent_dt <- rbindlist(all_statent, fill = TRUE)
cat(sprintf("STATENT total: %d rows\n", nrow(statent_dt)))

# Quick validation: Switzerland total establishments should be ~580-650k
swiss_total <- statent_dt[grepl("Schweiz", statent_dt[[2]]) &
                           grepl("Total", statent_dt[[3]]) &
                           grepl("Arbeitsstätten", statent_dt[[4]]), ]
cat("\nValidation — Switzerland total establishments:\n")
print(swiss_total)

fwrite(statent_dt, file.path(data_dir, "statent_canton_noga.csv"))

# ============================================================
# 3. STATENT by Size Class
# ============================================================

cat("\n=== 3. STATENT by Size Class ===\n")
Sys.sleep(3)
size_meta <- pxweb_meta("px-x-0602010000_109")

size_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_109/px-x-0602010000_109.px"
size_query <- list(
  query = lapply(seq_len(nrow(size_meta$variables)), function(i) {
    list(code = size_meta$variables$code[i],
         selection = list(filter = "item",
                          values = as.list(size_meta$variables$values[[i]])))
  }),
  response = list(format = "json-stat2")
)

Sys.sleep(3)
size_resp <- pxweb_post(size_url, jsonlite::toJSON(size_query, auto_unbox = TRUE))
size_dt <- parse_jsonstat2(httr::content(size_resp, "text", encoding = "UTF-8"))
cat(sprintf("Size class: %d rows\n", nrow(size_dt)))

# Validate: Switzerland total should match
cat("\nValidation — Size class totals:\n")
print(head(size_dt[grepl("Schweiz", size_dt[[2]]) & grepl("Total", size_dt[[3]])], 5))

fwrite(size_dt, file.path(data_dir, "statent_sizeclass.csv"))

# ============================================================
# 4. UDEMO: Firm demographics by NOGA x Year
# ============================================================

cat("\n=== 4. UDEMO ===\n")
Sys.sleep(3)
udemo_meta <- pxweb_meta("px-x-0602030000_202")
udemo_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602030000_202/px-x-0602030000_202.px"
udemo_years <- udemo_meta$variables$values[[which(udemo_meta$variables$code == "Jahr")]]

all_udemo <- list()
for (yr in udemo_years) {
  cat(sprintf("  %s...", yr))
  q <- list(
    query = lapply(seq_len(nrow(udemo_meta$variables)), function(i) {
      vals <- if (udemo_meta$variables$code[i] == "Jahr") list(yr) else as.list(udemo_meta$variables$values[[i]])
      list(code = udemo_meta$variables$code[i],
           selection = list(filter = "item", values = vals))
    }),
    response = list(format = "json-stat2")
  )
  Sys.sleep(3)
  resp <- tryCatch(
    pxweb_post(udemo_url, jsonlite::toJSON(q, auto_unbox = TRUE)),
    error = function(e) { cat(" FAILED\n"); NULL }
  )
  if (!is.null(resp)) {
    chunk <- parse_jsonstat2(httr::content(resp, "text", encoding = "UTF-8"))
    all_udemo[[length(all_udemo) + 1]] <- chunk
    cat(sprintf(" %d rows\n", nrow(chunk)))
  }
}

udemo_dt <- rbindlist(all_udemo, fill = TRUE)
cat(sprintf("UDEMO total: %d rows\n", nrow(udemo_dt)))
fwrite(udemo_dt, file.path(data_dir, "udemo_demographics.csv"))

# ============================================================
# Summary
# ============================================================

cat("\n=== DATA FETCH COMPLETE ===\n")
for (f in list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)) {
  info <- file.info(f)
  cat(sprintf("  %s: %s bytes\n", basename(f), format(info$size, big.mark = ",")))
}
