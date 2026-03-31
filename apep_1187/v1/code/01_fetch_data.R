# =============================================================================
# 01_fetch_data.R — Fetch wage data from Statistics Sweden (SCB) PxWeb API
# Paper: apep_1187 — Sweden Pay Equity Audit RDD
# =============================================================================

source("00_packages.R")

# Helper: POST query to PxWeb → data.frame
post_pxweb <- function(url, query_body) {
  body_json <- jsonlite::toJSON(query_body, auto_unbox = TRUE)
  resp <- httr::POST(url, body = body_json, httr::content_type_json(),
                     httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    cat("  POST failed:", httr::status_code(resp), "\n")
    return(NULL)
  }
  raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
  raw <- jsonlite::fromJSON(raw_text, simplifyDataFrame = FALSE)
  if (is.null(raw$data) || length(raw$data) == 0) return(NULL)

  # Column metadata
  col_codes <- sapply(raw$columns, function(c) c$code)
  col_types <- sapply(raw$columns, function(c) c$type)
  col_texts <- sapply(raw$columns, function(c) c$text)
  dim_cols <- col_codes[col_types %in% c("d", "t")]
  val_cols <- col_codes[col_types == "c"]
  val_texts <- col_texts[col_types == "c"]

  # Parse rows
  keys <- do.call(rbind, lapply(raw$data, function(x) x$key))
  vals <- do.call(rbind, lapply(raw$data, function(x) {
    v <- x$values
    v[v == ".." | v == "."] <- NA
    as.numeric(v)
  }))

  df <- as.data.frame(keys, stringsAsFactors = FALSE)
  names(df) <- dim_cols

  if (is.matrix(vals)) {
    for (j in seq_along(val_cols)) df[[val_cols[j]]] <- vals[, j]
  } else {
    df[[val_cols[1]]] <- vals
  }

  cat(sprintf("  → %d rows | dims: %s | values: %s\n",
              nrow(df), paste(dim_cols, collapse=", "),
              paste(val_texts, collapse=", ")))
  return(df)
}

# ============================================================================
# 1. WAGES BY INDUSTRY × SEX × YEAR (AM0110C/LonSNIKon, 2014-2022)
#    Values: Basic salary, Monthly salary, Women's % of men's, Private share
# ============================================================================
cat("=== 1. Wages by industry × sex (2014-2022) ===\n")

url1 <- "https://api.scb.se/OV0104/v1/doris/en/ssd/AM/AM0110/AM0110C/LonSNIKon"
q1 <- list(
  query = list(
    list(code = "SNI2007", selection = list(filter = "all", values = I("*"))),
    list(code = "Kon", selection = list(filter = "item", values = I(c("1", "2"))))
  ),
  response = list(format = "json")
)
df1 <- post_pxweb(url1, q1)
if (is.null(df1)) stop("FATAL: Cannot fetch AM0110C/LonSNIKon")
cat("Sample:\n"); print(head(df1, 6))
saveRDS(df1, "../data/wages_industry_sex.rds")

# ============================================================================
# 2. WAGES BY INDUSTRY × SEX × YEAR (LonSNIKonN, 2023-2024)
# ============================================================================
cat("\n=== 2. Wages by industry × sex (2023-2024) ===\n")

url2 <- "https://api.scb.se/OV0104/v1/doris/en/ssd/AM/AM0110/AM0110C/LonSNIKonN"
q2 <- list(
  query = list(
    list(code = "SNI2007", selection = list(filter = "all", values = I("*"))),
    list(code = "Kon", selection = list(filter = "item", values = I(c("1", "2"))))
  ),
  response = list(format = "json")
)
df2 <- post_pxweb(url2, q2)
if (!is.null(df2)) {
  cat("Sample:\n"); print(head(df2, 4))
  saveRDS(df2, "../data/wages_industry_sex_2023.rds")
}

# ============================================================================
# 3. WAGES BY SECTOR × OCCUPATION × SEX (LoneSpridSektorYrk4A, 2014-2022)
#    Private sector wages by 1-digit SSYK occupation
# ============================================================================
cat("\n=== 3. Wages by sector × occupation × sex (2014-2022) ===\n")

url3 <- "https://api.scb.se/OV0104/v1/doris/en/ssd/AM/AM0110/AM0110A/LoneSpridSektorYrk4A"
meta3 <- jsonlite::fromJSON(
  httr::content(httr::GET(url3, httr::timeout(30)), as = "text", encoding = "UTF-8"),
  simplifyDataFrame = FALSE
)
# Find occupation variable and extract 1-digit codes
occ_var <- NULL
for (v in meta3$variables) {
  if (v$code == "Yrke2012") occ_var <- v
}
occ_codes <- occ_var$values
occ_1digit <- occ_codes[nchar(occ_codes) <= 1]
cat("1-digit occupations:", paste(occ_1digit, collapse=", "), "\n")

q3 <- list(
  query = list(
    list(code = "Sektor", selection = list(filter = "all", values = I("*"))),
    list(code = "Yrke2012", selection = list(filter = "item", values = I(occ_1digit))),
    list(code = "Kon", selection = list(filter = "item", values = I(c("1", "2"))))
  ),
  response = list(format = "json")
)
df3 <- post_pxweb(url3, q3)
if (!is.null(df3)) {
  cat("Sample:\n"); print(head(df3, 5))
  saveRDS(df3, "../data/wages_sector_occ_sex.rds")
}

# ============================================================================
# 4. FIRM COUNTS BY SIZE CLASS × INDUSTRY (FDBR07N, 2008-2025)
#    Use 1-letter SNI codes only (aggregate industries)
# ============================================================================
cat("\n=== 4. Firm counts by size class × industry ===\n")

url4 <- "https://api.scb.se/OV0104/v1/doris/en/ssd/NV/NV0101/FDBR07N"
meta4 <- jsonlite::fromJSON(
  httr::content(httr::GET(url4, httr::timeout(30)), as = "text", encoding = "UTF-8"),
  simplifyDataFrame = FALSE
)
sni_var <- meta4$variables[[1]]
sni_codes <- sni_var$values
# Aggregate: total (A-U) + single letters + 2-digit ranges
sni_agg <- sni_codes[nchar(sni_codes) <= 3]
cat("Aggregate SNI:", paste(head(sni_agg, 25), collapse=", "), "\n")
cat("Count:", length(sni_agg), "\n")

size_var <- meta4$variables[[2]]
cat("Size classes:", paste(size_var$valueTexts, collapse=" | "), "\n")

q4 <- list(
  query = list(
    list(code = sni_var$code, selection = list(filter = "item", values = I(sni_agg))),
    list(code = size_var$code, selection = list(filter = "all", values = I("*")))
  ),
  response = list(format = "json")
)
df4 <- post_pxweb(url4, q4)
if (!is.null(df4)) {
  cat("Sample:\n"); print(head(df4, 10))
  saveRDS(df4, "../data/firm_counts_by_size.rds")
} else {
  # Fallback: just total economy
  q4b <- list(
    query = list(
      list(code = sni_var$code, selection = list(filter = "item", values = I(c("A-U"))))
    ),
    response = list(format = "json")
  )
  df4 <- post_pxweb(url4, q4b)
  if (!is.null(df4)) {
    saveRDS(df4, "../data/firm_counts_by_size.rds")
  }
}

# ============================================================================
# 5. STANDARDIZED GENDER WAGE RATIO BY OCCUPATION (2014-2024)
#    LonStandVagdYrk4A
# ============================================================================
cat("\n=== 5. Standardized gender wage ratio (2014-2024) ===\n")

url5 <- "https://api.scb.se/OV0104/v1/doris/en/ssd/AM/AM0110/AM0110A/LonStandVagdYrk4A"
meta5 <- jsonlite::fromJSON(
  httr::content(httr::GET(url5, httr::timeout(30)), as = "text", encoding = "UTF-8"),
  simplifyDataFrame = FALSE
)
occ5 <- NULL
for (v in meta5$variables) {
  if (v$code == "Yrke2012") occ5 <- v
}
occ_1d5 <- occ5$values[nchar(occ5$values) <= 1]

q5 <- list(
  query = list(
    list(code = "Yrke2012", selection = list(filter = "item", values = I(occ_1d5)))
  ),
  response = list(format = "json")
)
df5 <- post_pxweb(url5, q5)
if (!is.null(df5)) {
  cat("Sample:\n"); print(head(df5, 10))
  saveRDS(df5, "../data/wage_ratio_standardized.rds")
}

# ============================================================================
# SUMMARY
# ============================================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
files <- list.files("../data", pattern = "\\.rds$")
for (f in files) {
  obj <- readRDS(file.path("../data", f))
  if (is.data.frame(obj) && nrow(obj) > 0) {
    cat(sprintf("  ✓ %s: %d rows × %d cols\n", f, nrow(obj), ncol(obj)))
  } else {
    cat(sprintf("  ✗ %s: EMPTY\n", f))
  }
}
