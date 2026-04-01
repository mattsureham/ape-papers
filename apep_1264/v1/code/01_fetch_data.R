# 01_fetch_data.R — Fetch BFS STATENT firm-size data
# Paper: The Growth Ceiling (apep_1264)
source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

bfs_api <- "https://www.pxweb.bfs.admin.ch/api/v1/de"

# Helper: query a PXWeb table and return data.table
fetch_pxweb <- function(table_path, label = "") {
  url <- paste0(bfs_api, "/", table_path)

  # Get metadata
  meta_resp <- httr::GET(url, httr::timeout(30))
  stopifnot(httr::status_code(meta_resp) == 200)
  meta <- httr::content(meta_resp, as = "parsed")

  cat("Fetching:", label, "\n")
  for (v in meta$variables) {
    cat("  ", v$code, ":", v$text, "(", length(v$values), "values)\n")
  }

  # Build query: select all values
  query_list <- lapply(meta$variables, function(v) {
    list(code = v$code,
         selection = list(filter = "item", values = v$values))
  })

  post_resp <- httr::POST(
    url,
    body = jsonlite::toJSON(
      list(query = query_list, response = list(format = "json")),
      auto_unbox = TRUE
    ),
    httr::content_type_json(),
    httr::timeout(120)
  )

  if (httr::status_code(post_resp) != 200) {
    cat("  Query failed:", httr::status_code(post_resp), "\n")
    return(NULL)
  }

  result <- httr::content(post_resp, as = "parsed")
  cat("  Got", length(result$data), "data points\n")

  # Build label lookup for each variable
  var_labels <- lapply(meta$variables, function(v) {
    setNames(v$valueTexts, v$values)
  })
  names(var_labels) <- sapply(meta$variables, function(v) v$code)

  col_codes <- sapply(meta$variables, function(v) v$code)

  rows <- lapply(result$data, function(d) {
    keys <- unlist(d$key)
    val <- as.numeric(d$values[[1]])
    out <- setNames(as.list(keys), col_codes)
    out$value <- val
    out
  })

  df <- data.table::rbindlist(rows, fill = TRUE)

  # Add label columns
  for (v in meta$variables) {
    code <- v$code
    lbl_col <- paste0(code, "_label")
    lookup <- setNames(v$valueTexts, v$values)
    df[[lbl_col]] <- lookup[as.character(df[[code]])]
  }

  cat("  Result:", nrow(df), "rows x", ncol(df), "cols\n")
  df
}

# ===========================================================================
# 1) STATENT: Workplaces and employees by canton and size class (annual 2011-2023)
# ===========================================================================
df_109 <- fetch_pxweb(
  "px-x-0602010000_109/px-x-0602010000_109.px",
  "Table 109: Arbeitsstätten by canton × size class"
)
if (!is.null(df_109)) {
  data.table::fwrite(df_109, file.path(data_dir, "statent_canton_size.csv"))
  cat("\nTable 109 summary:\n")
  cat("Years:", paste(sort(unique(df_109$Jahr)), collapse=", "), "\n")
  cat("Cantons:", length(unique(df_109$Kanton)), "\n")
  cat("Size classes:", paste(unique(df_109$Grössenklasse_label), collapse=" | "), "\n")
  cat("Variables:", paste(unique(df_109$Beobachtungseinheit_label), collapse=" | "), "\n")
}

# ===========================================================================
# 2) STATENT: Enterprises by canton and size class (annual 2011-2023)
# ===========================================================================
df_107 <- fetch_pxweb(
  "px-x-0602010000_107/px-x-0602010000_107.px",
  "Table 107: Institutionelle Einheiten by canton × size class"
)
if (!is.null(df_107)) {
  data.table::fwrite(df_107, file.path(data_dir, "statent_enterprises_size.csv"))
  cat("\nTable 107 summary:\n")
  cat("Years:", paste(sort(unique(df_107$Jahr)), collapse=", "), "\n")
}

# ===========================================================================
# 3) STATENT: Workplaces by canton and industry (annual 2011-2023) — no size
# ===========================================================================
df_101 <- fetch_pxweb(
  "px-x-0602010000_101/px-x-0602010000_101.px",
  "Table 101: Arbeitsstätten by canton × industry (no size)"
)
if (!is.null(df_101)) {
  data.table::fwrite(df_101, file.path(data_dir, "statent_canton_industry.csv"))
  cat("\nTable 101 summary:\n")
  cat("Industries:", length(unique(df_101$Wirtschaftsabteilung)), "\n")
}

# ===========================================================================
# 4) UDEMO: Firm demographics by industry and size class (2013-2023)
# ===========================================================================
df_202 <- fetch_pxweb(
  "px-x-0602030000_202/px-x-0602030000_202.px",
  "Table 202: UDEMO firm demographics by industry × size class"
)
if (!is.null(df_202)) {
  data.table::fwrite(df_202, file.path(data_dir, "udemo_industry_size.csv"))
  cat("\nTable 202 summary:\n")
  cat("Years:", paste(sort(unique(df_202$Jahr)), collapse=", "), "\n")
  cat("Industries:", length(unique(df_202$Wirtschaftsabteilung)), "\n")
  cat("Size classes:", paste(unique(df_202$Grössenklasse_label), collapse=" | "), "\n")
}

# ===========================================================================
# 5) UDEMO: Firm demographics by canton, sector and size class
# ===========================================================================
df_204 <- fetch_pxweb(
  "px-x-0602030000_204/px-x-0602030000_204.px",
  "Table 204: UDEMO by canton × sector × size class"
)
if (!is.null(df_204)) {
  data.table::fwrite(df_204, file.path(data_dir, "udemo_canton_size.csv"))
  cat("\nTable 204 summary:\n")
  cat("Years:", paste(sort(unique(df_204$Jahr)), collapse=", "), "\n")
  cat("Size classes:", paste(unique(df_204$Grössenklasse_label), collapse=" | "), "\n")
}

# ===========================================================================
# 6) Regulation dates (verified from legal research)
# ===========================================================================
cat("\n=== Saving regulation dates ===\n")
reg_dates <- data.frame(
  threshold = c(20, 50, 100, 250),
  regulation = c(
    "Collective dismissal notification",
    "Employee participation rights",
    "Gender pay equity audits (GEA)",
    "Ordinary audit requirement"
  ),
  legal_basis = c("OR Art. 335d", "Mitwirkungsgesetz SR 822.14",
                  "Gleichstellungsgesetz SR 151.1", "OR Art. 727"),
  date_entry = c("1993-01-01", "1994-01-01", "2020-07-01", "1992-01-01"),
  stringsAsFactors = FALSE
)
write.csv(reg_dates, file.path(data_dir, "regulation_dates.csv"), row.names = FALSE)

# ===========================================================================
# 7) Summary
# ===========================================================================
cat("\n=== Final Data Inventory ===\n")
for (f in list.files(data_dir, pattern = "*.csv")) {
  fpath <- file.path(data_dir, f)
  df <- data.table::fread(fpath, nrows = 1)
  n <- nrow(data.table::fread(fpath))
  cat(sprintf("  %-35s %6d rows × %2d cols\n", f, n, ncol(df)))
}
