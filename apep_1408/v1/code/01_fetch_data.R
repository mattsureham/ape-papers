## 01_fetch_data.R — Fetch all datasets from datos.gov.co
## apep_1408: PNIS coca substitution in Colombia

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ─────────────────────────────────────────────────
## 1. Coca cultivation panel (SIMCI) — resource acs4-3wgp
## Municipality × year coca hectares, 2001–2023
## ─────────────────────────────────────────────────

cat("Fetching coca cultivation panel...\n")
coca_url <- "https://www.datos.gov.co/resource/acs4-3wgp.json?$limit=50000"
coca_resp <- GET(coca_url, timeout(120))
stopifnot("Coca data fetch failed" = status_code(coca_resp) == 200)
coca_raw <- content(coca_resp, as = "text", encoding = "UTF-8")
coca_df <- fromJSON(coca_raw) %>% as_tibble()

cat("Coca panel raw rows:", nrow(coca_df), "\n")
cat("Coca panel columns:", paste(names(coca_df), collapse = ", "), "\n")

saveRDS(coca_df, file.path(data_dir, "coca_raw.rds"))

## ─────────────────────────────────────────────────
## 2. PNIS enrollment — resource v4pt-rnn9
## Municipality-level enrollment counts
## ─────────────────────────────────────────────────

cat("Fetching PNIS enrollment data...\n")
pnis_url <- "https://www.datos.gov.co/resource/v4pt-rnn9.json?$limit=50000"
pnis_resp <- GET(pnis_url, timeout(120))
stopifnot("PNIS data fetch failed" = status_code(pnis_resp) == 200)
pnis_raw <- content(pnis_resp, as = "text", encoding = "UTF-8")
pnis_df <- fromJSON(pnis_raw) %>% as_tibble()

cat("PNIS enrollment rows:", nrow(pnis_df), "\n")
cat("PNIS columns:", paste(names(pnis_df), collapse = ", "), "\n")

saveRDS(pnis_df, file.path(data_dir, "pnis_raw.rds"))

## ─────────────────────────────────────────────────
## 3. Eradication events — resource p72f-qcvk
## 145K+ events with method, municipality, date
## ─────────────────────────────────────────────────

cat("Fetching eradication events...\n")

# Fetch in batches (large dataset)
erad_all <- list()
offset <- 0
batch_size <- 50000
repeat {
  erad_url <- sprintf(
    "https://www.datos.gov.co/resource/p72f-qcvk.json?$limit=%d&$offset=%d&$order=:id",
    batch_size, offset
  )
  erad_resp <- GET(erad_url, timeout(180))
  stopifnot("Eradication data fetch failed" = status_code(erad_resp) == 200)
  erad_raw <- content(erad_resp, as = "text", encoding = "UTF-8")
  batch <- fromJSON(erad_raw) %>% as_tibble()
  if (nrow(batch) == 0) break
  erad_all <- c(erad_all, list(batch))
  offset <- offset + batch_size
  cat("  Fetched", offset, "eradication rows so far...\n")
  if (nrow(batch) < batch_size) break
}
erad_df <- bind_rows(erad_all)
cat("Total eradication events:", nrow(erad_df), "\n")
cat("Eradication columns:", paste(names(erad_df), collapse = ", "), "\n")

saveRDS(erad_df, file.path(data_dir, "eradication_raw.rds"))

## ─────────────────────────────────────────────────
## 4. Quick validation
## ─────────────────────────────────────────────────

cat("\n=== DATA VALIDATION ===\n")
cat("Coca panel:", nrow(coca_df), "rows\n")
cat("PNIS enrollment:", nrow(pnis_df), "rows\n")
cat("Eradication events:", nrow(erad_df), "rows\n")

if (nrow(coca_df) < 100) stop("FATAL: Coca panel too small — API may have changed")
if (nrow(pnis_df) < 30) stop("FATAL: PNIS enrollment too small — API may have changed")
if (nrow(erad_df) < 1000) stop("FATAL: Eradication data too small — API may have changed")

cat("All data fetched successfully.\n")
