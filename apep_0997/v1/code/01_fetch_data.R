## 01_fetch_data.R — Fetch Romanian sector-level employment and wage data
## apep_0997: Romania Construction Tax Holiday
##
## Primary: Eurostat (reliable SDMX API)
##   - nama_10_a64_e: Employment by NACE sector (annual, persons)
##   - earn_ses_annual: Earnings data
##   - lc_lci_r2_q: Labour cost index (quarterly)
##   - sts_copr_q: Construction production index (demand control)
##
## Secondary: INS Tempo (Romanian National Statistics)
##   - SOM101E: Average gross wages by sector (quarterly)

source("00_packages.R")

cat("=== Fetching Eurostat Data ===\n")

# ----------------------------------------------------------------
# 1. Employment by NACE sector (annual) — nama_10_a64_e
# ----------------------------------------------------------------
cat("Fetching employment by NACE sector (nama_10_a64_e)...\n")

emp_raw <- get_eurostat("nama_10_a64_e",
                        filters = list(geo = "RO",
                                       unit = "THS_PER",
                                       na_item = "EMP_DC"),
                        time_format = "num")

if (is.null(emp_raw) || nrow(emp_raw) == 0) {
  stop("FATAL: Eurostat employment data (nama_10_a64_e) returned empty for Romania.")
}

cat(sprintf("  Employment data: %d rows, years %d-%d\n",
            nrow(emp_raw), min(emp_raw$time), max(emp_raw$time)))

# Keep relevant NACE sectors
# F = Construction, C = Manufacturing, G = Trade, H = Transport,
# I = Accommodation, J = ICT, M = Professional, N = Admin
keep_nace <- c("F", "C", "G", "H", "I", "J", "M", "N", "K", "L")
emp <- emp_raw %>%
  filter(nace_r2 %in% keep_nace) %>%
  select(nace_r2, year = time, employment_ths = values) %>%
  arrange(nace_r2, year)

cat(sprintf("  Filtered to %d sector-years across %d sectors\n",
            nrow(emp), n_distinct(emp$nace_r2)))

# ----------------------------------------------------------------
# 2. Labour cost index (quarterly) — lc_lci_r2_q
# ----------------------------------------------------------------
cat("Fetching labour cost index (lc_lci_r2_q)...\n")

lci_raw <- tryCatch({
  get_eurostat("lc_lci_r2_q",
               filters = list(geo = "RO",
                              s_adj = "NSA",
                              lcstruct = "D1_D4_MD5",
                              unit = "I20"),
               time_format = "date")
}, error = function(e) {
  cat("  Warning: lc_lci_r2_q fetch failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(lci_raw) && nrow(lci_raw) > 0) {
  lci <- lci_raw %>%
    filter(nace_r2 %in% keep_nace) %>%
    mutate(year = as.integer(format(time, "%Y")),
           quarter = as.integer(format(time, "%m")) %/% 3 +
                     ifelse(as.integer(format(time, "%m")) %% 3 == 0, 0, 1),
           quarter = ceiling(as.integer(format(time, "%m")) / 3)) %>%
    select(nace_r2, year, quarter, lci = values) %>%
    arrange(nace_r2, year, quarter)
  cat(sprintf("  LCI data: %d sector-quarters\n", nrow(lci)))
} else {
  lci <- NULL
  cat("  LCI data not available — will proceed without.\n")
}

# ----------------------------------------------------------------
# 3. Construction production index (quarterly demand control)
# ----------------------------------------------------------------
cat("Fetching construction production index (sts_copr_q)...\n")

copr_raw <- tryCatch({
  get_eurostat("sts_copr_q",
               filters = list(geo = "RO",
                              s_adj = "SCA",
                              nace_r2 = "F",
                              unit = "I15"),
               time_format = "date")
}, error = function(e) {
  cat("  Warning: sts_copr_q fetch failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(copr_raw) && nrow(copr_raw) > 0) {
  copr <- copr_raw %>%
    mutate(year = as.integer(format(time, "%Y")),
           quarter = ceiling(as.integer(format(time, "%m")) / 3)) %>%
    select(year, quarter, construction_prod_idx = values) %>%
    arrange(year, quarter)
  cat(sprintf("  Construction production index: %d quarters\n", nrow(copr)))
} else {
  copr <- NULL
  cat("  Construction production index not available.\n")
}

# ----------------------------------------------------------------
# 4. Quarterly employment by NACE (LFS) — lfsq_egan2
# ----------------------------------------------------------------
cat("Fetching quarterly LFS employment (lfsq_egan2)...\n")

lfs_raw <- tryCatch({
  get_eurostat("lfsq_egan2",
               filters = list(geo = "RO",
                              sex = "T",
                              age = "Y15-64",
                              unit = "THS_PER"),
               time_format = "date")
}, error = function(e) {
  cat("  Warning: lfsq_egan2 fetch failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(lfs_raw) && nrow(lfs_raw) > 0) {
  lfs <- lfs_raw %>%
    filter(nace_r2 %in% keep_nace) %>%
    mutate(year = as.integer(format(time, "%Y")),
           quarter = ceiling(as.integer(format(time, "%m")) / 3)) %>%
    select(nace_r2, year, quarter, lfs_emp_ths = values) %>%
    filter(!is.na(lfs_emp_ths)) %>%
    arrange(nace_r2, year, quarter)
  cat(sprintf("  LFS quarterly employment: %d sector-quarters\n", nrow(lfs)))
} else {
  lfs <- NULL
  cat("  LFS quarterly employment not available.\n")
}

# ----------------------------------------------------------------
# 5. Annual earnings by NACE — earn_ses_annual or earn_ses18_46
# ----------------------------------------------------------------
cat("Fetching annual earnings data...\n")

earn_raw <- tryCatch({
  get_eurostat("earn_ses18_46",
               filters = list(geo = "RO",
                              isco08 = "TOTAL",
                              unit = "EUR"),
               time_format = "num")
}, error = function(e) {
  cat("  earn_ses18_46 failed, trying earn_gre_ges...\n")
  tryCatch({
    get_eurostat("earn_gre_ges",
                 filters = list(geo = "RO"),
                 time_format = "num")
  }, error = function(e2) {
    cat("  Annual earnings fetch failed:", conditionMessage(e2), "\n")
    NULL
  })
})

if (!is.null(earn_raw) && nrow(earn_raw) > 0) {
  cat(sprintf("  Annual earnings data: %d rows\n", nrow(earn_raw)))
} else {
  cat("  Annual earnings not directly available from Eurostat.\n")
}

# ----------------------------------------------------------------
# 6. INS Tempo — Average gross wages by sector (backup/primary wage)
# ----------------------------------------------------------------
cat("\n=== Fetching INS Tempo Wage Data ===\n")

# INS Tempo REST API for SOM101E (average gross wages by CAEN sector)
# The API structure: statistici.insse.ro:8077/tempo-ins/matrix/SOM101E
ins_base <- "https://statistici.insse.ro:8077/tempo-ins/matrix/SOM101E"

ins_wages <- tryCatch({
  # First get metadata
  meta_resp <- httr::GET(ins_base, httr::timeout(30))
  if (httr::status_code(meta_resp) == 200) {
    cat("  INS Tempo SOM101E metadata accessible.\n")

    # Try to get the data via CSV download
    # INS Tempo provides data downloads; we'll construct the query
    # For now, try JSON
    data_url <- paste0(ins_base, "?lang=en")
    data_resp <- httr::GET(data_url, httr::timeout(60))

    if (httr::status_code(data_resp) == 200) {
      content_text <- httr::content(data_resp, "text", encoding = "UTF-8")
      cat(sprintf("  Response length: %d chars\n", nchar(content_text)))
      # Parse if JSON
      tryCatch({
        ins_json <- jsonlite::fromJSON(content_text)
        cat("  Successfully parsed INS Tempo metadata.\n")
        ins_json
      }, error = function(e) {
        cat("  INS Tempo response not JSON, trying alternative approach.\n")
        NULL
      })
    } else {
      cat(sprintf("  INS Tempo returned status %d\n", httr::status_code(data_resp)))
      NULL
    }
  } else {
    cat(sprintf("  INS Tempo metadata returned status %d\n", httr::status_code(meta_resp)))
    NULL
  }
}, error = function(e) {
  cat("  INS Tempo connection failed:", conditionMessage(e), "\n")
  NULL
})

# ----------------------------------------------------------------
# 7. Alternative: Eurostat quarterly earnings — earn_rt_q
# ----------------------------------------------------------------
cat("\nFetching Eurostat quarterly earnings index (lc_lci_r2_q already tried)...\n")

# Try nominal wages/compensation per employee from national accounts
cat("Fetching compensation per employee (nama_10_a64)...\n")

comp_raw <- tryCatch({
  get_eurostat("nama_10_a64",
               filters = list(geo = "RO",
                              unit = "MIO_NAC",
                              na_item = "D1"),
               time_format = "num")
}, error = function(e) {
  cat("  nama_10_a64 failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(comp_raw) && nrow(comp_raw) > 0) {
  comp <- comp_raw %>%
    filter(nace_r2 %in% keep_nace) %>%
    select(nace_r2, year = time, compensation_mio = values) %>%
    arrange(nace_r2, year)
  cat(sprintf("  Compensation data: %d sector-years\n", nrow(comp)))
} else {
  comp <- NULL
  cat("  Compensation data not available.\n")
}

# ----------------------------------------------------------------
# 8. Build analysis dataset
# ----------------------------------------------------------------
cat("\n=== Building Analysis Dataset ===\n")

# Core: employment panel (annual)
analysis_annual <- emp %>%
  mutate(
    construction = ifelse(nace_r2 == "F", 1L, 0L),
    post = ifelse(year >= 2019, 1L, 0L),
    treat = construction * post,
    sector_label = case_when(
      nace_r2 == "F" ~ "Construction",
      nace_r2 == "C" ~ "Manufacturing",
      nace_r2 == "G" ~ "Wholesale/Retail",
      nace_r2 == "H" ~ "Transportation",
      nace_r2 == "I" ~ "Accommodation/Food",
      nace_r2 == "J" ~ "ICT",
      nace_r2 == "K" ~ "Finance/Insurance",
      nace_r2 == "L" ~ "Real Estate",
      nace_r2 == "M" ~ "Professional/Scientific",
      nace_r2 == "N" ~ "Admin/Support",
      TRUE ~ nace_r2
    )
  )

# Add compensation if available
if (!is.null(comp)) {
  analysis_annual <- analysis_annual %>%
    left_join(comp, by = c("nace_r2", "year")) %>%
    mutate(
      wage_per_emp = ifelse(employment_ths > 0,
                            compensation_mio / employment_ths,
                            NA_real_)
    )
}

cat(sprintf("  Annual panel: %d obs, %d sectors, years %d-%d\n",
            nrow(analysis_annual),
            n_distinct(analysis_annual$nace_r2),
            min(analysis_annual$year),
            max(analysis_annual$year)))

# Quarterly panel if LFS available
if (!is.null(lfs)) {
  analysis_quarterly <- lfs %>%
    mutate(
      construction = ifelse(nace_r2 == "F", 1L, 0L),
      post = ifelse(year >= 2019 | (year == 2019 & quarter >= 1), 1L, 0L),
      post = ifelse(year >= 2019, 1L, 0L),
      treat = construction * post,
      time_q = year + (quarter - 1) / 4,
      sector_label = case_when(
        nace_r2 == "F" ~ "Construction",
        nace_r2 == "C" ~ "Manufacturing",
        nace_r2 == "G" ~ "Wholesale/Retail",
        nace_r2 == "H" ~ "Transportation",
        nace_r2 == "I" ~ "Accommodation/Food",
        nace_r2 == "J" ~ "ICT",
        nace_r2 == "K" ~ "Finance/Insurance",
        nace_r2 == "L" ~ "Real Estate",
        nace_r2 == "M" ~ "Professional/Scientific",
        nace_r2 == "N" ~ "Admin/Support",
        TRUE ~ nace_r2
      )
    )

  # Merge construction production index
  if (!is.null(copr)) {
    analysis_quarterly <- analysis_quarterly %>%
      left_join(copr, by = c("year", "quarter"))
  }

  # Merge LCI
  if (!is.null(lci)) {
    analysis_quarterly <- analysis_quarterly %>%
      left_join(lci, by = c("nace_r2", "year", "quarter"))
  }

  cat(sprintf("  Quarterly panel: %d obs, %d sectors, %d-%d\n",
              nrow(analysis_quarterly),
              n_distinct(analysis_quarterly$nace_r2),
              min(analysis_quarterly$year),
              max(analysis_quarterly$year)))
}

# ----------------------------------------------------------------
# 9. Save datasets
# ----------------------------------------------------------------
saveRDS(analysis_annual, "../data/analysis_annual.rds")
cat("  Saved: data/analysis_annual.rds\n")

if (!is.null(lfs)) {
  saveRDS(analysis_quarterly, "../data/analysis_quarterly.rds")
  cat("  Saved: data/analysis_quarterly.rds\n")
}

if (!is.null(lci)) {
  saveRDS(lci, "../data/lci_raw.rds")
}
if (!is.null(copr)) {
  saveRDS(copr, "../data/construction_prod.rds")
}

# Print summary for validation
cat("\n=== Data Summary ===\n")
cat("Annual employment panel:\n")
analysis_annual %>%
  group_by(construction) %>%
  summarise(
    n_sectors = n_distinct(nace_r2),
    n_years = n_distinct(year),
    mean_emp = mean(employment_ths, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nConstruction employment over time:\n")
analysis_annual %>%
  filter(nace_r2 == "F") %>%
  select(year, employment_ths) %>%
  print(n = 20)

cat("\n01_fetch_data.R complete.\n")
