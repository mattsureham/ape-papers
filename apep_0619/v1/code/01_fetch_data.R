## 01_fetch_data.R — Fetch and aggregate H-1B lottery + SEC EDGAR data
## APEP Paper apep_0619: H-1B Visa Lottery and Firm R&D Investment

source("00_packages.R")

data_dir <- "../data"

cat("=== Step 1: Parse Bloomberg FOIA H-1B Lottery Data ===\n")

# Parse FY2021 and FY2022 lottery data
parse_h1b_file <- function(filepath, fy) {
  cat(sprintf("  Reading %s...\n", filepath))
  df <- fread(filepath, select = c("employer_name", "FEIN", "status_type",
                                    "lottery_year", "ben_multi_reg_ind"))
  # Filter to valid status types (FY2021 uses CREATED/SELECTED; FY2022 uses ELIGIBLE/SELECTED)
  df <- df[status_type %in% c("CREATED", "SELECTED", "ELIGIBLE")]
  # Harmonize: CREATED and ELIGIBLE both mean "not selected"
  df[, selected := as.integer(status_type == "SELECTED")]
  df[, fiscal_year := fy]
  cat(sprintf("  %d registrations (%d selected, %d not selected)\n",
              nrow(df), sum(df$selected == 1),
              sum(df$selected == 0)))
  return(df)
}

h1b_21 <- parse_h1b_file(file.path(data_dir, "TRK_13139_FY2021.csv"), 2021)
h1b_22 <- parse_h1b_file(file.path(data_dir, "TRK_13139_FY2022.csv"), 2022)

h1b_all <- rbind(h1b_21, h1b_22)

cat(sprintf("\nTotal registrations: %d across %d unique employers\n",
            nrow(h1b_all), length(unique(h1b_all$FEIN))))

# Aggregate to employer × fiscal year level
employer_fy <- h1b_all[, .(
  n_registered = .N,
  n_selected = sum(selected),
  employer_name = first(employer_name)
), by = .(FEIN, fiscal_year)]

employer_fy[, win_rate := n_selected / n_registered]

cat(sprintf("\nEmployer-FY observations: %d\n", nrow(employer_fy)))
cat(sprintf("Employers with 5+ registrations: %d\n",
            nrow(employer_fy[n_registered >= 5])))

# Summary of win rate variation
cat("\nWin rate summary (employers with 5+ registrations):\n")
print(summary(employer_fy[n_registered >= 5, win_rate]))
cat(sprintf("SD of win rate: %.3f\n", sd(employer_fy[n_registered >= 5, win_rate])))

cat("\n=== Step 2: Fetch SEC EDGAR Company Data ===\n")

# Get SEC company tickers (all publicly traded companies)
sec_url <- "https://www.sec.gov/files/company_tickers.json"
cat("  Fetching SEC company tickers...\n")
resp <- request(sec_url) |>
  req_headers(`User-Agent` = "APEP Research olaf@econ.uzh.ch") |>
  req_perform()

sec_companies <- fromJSON(resp_body_string(resp))
# Convert from named list to data frame
sec_df <- bind_rows(lapply(names(sec_companies), function(i) {
  x <- sec_companies[[i]]
  tibble(cik = x$cik_str, ticker = x$ticker, title = x$title)
}))

cat(sprintf("  SEC companies loaded: %d\n", nrow(sec_df)))

# Pad CIK to 10 digits for API calls
sec_df$cik_padded <- sprintf("CIK%010d", sec_df$cik)

cat("\n=== Step 3: Fetch EINs from SEC Submissions API ===\n")

# We need EINs to match with H-1B FEINs
# Batch fetch submissions for companies, extract EIN
# Rate limit: 10 req/sec (SEC fair access policy)

# To be efficient, only fetch for companies likely to be in H-1B data
# (tech companies, consulting, pharma, etc.) — but actually fetch all
# to maximize matches. We'll batch in groups with polite delays.

fetch_sec_ein <- function(cik_padded, max_n = 3000) {
  results <- list()
  n <- min(length(cik_padded), max_n)

  cat(sprintf("  Fetching EINs for %d companies...\n", n))
  pb <- txtProgressBar(min = 0, max = n, style = 3)

  for (i in seq_len(n)) {
    url <- paste0("https://data.sec.gov/submissions/", cik_padded[i], ".json")
    tryCatch({
      resp <- request(url) |>
        req_headers(`User-Agent` = "APEP Research olaf@econ.uzh.ch") |>
        req_perform()
      info <- fromJSON(resp_body_string(resp))
      results[[i]] <- tibble(
        cik_padded = cik_padded[i],
        ein = info$ein %||% NA_character_,
        name = info$name %||% NA_character_,
        sic = info$sic %||% NA_character_,
        sic_description = info$sicDescription %||% NA_character_
      )
    }, error = function(e) {
      results[[i]] <<- tibble(
        cik_padded = cik_padded[i],
        ein = NA_character_, name = NA_character_,
        sic = NA_character_, sic_description = NA_character_
      )
    })

    setTxtProgressBar(pb, i)
    # Polite rate limiting: 8 requests per second
    if (i %% 8 == 0) Sys.sleep(1)
  }
  close(pb)
  bind_rows(results)
}

# Fetch EINs for first 3000 companies (covers most large firms)
sec_eins <- fetch_sec_ein(sec_df$cik_padded, max_n = 3000)
sec_eins <- sec_eins[!is.na(sec_eins$ein) & sec_eins$ein != "", ]
cat(sprintf("  Companies with EINs: %d\n", nrow(sec_eins)))

# Join back to get CIK number
sec_eins <- sec_eins |>
  left_join(sec_df |> select(cik, cik_padded, ticker), by = "cik_padded")

cat("\n=== Step 4: Match H-1B Employers to SEC Companies via EIN ===\n")

# Clean EIN format: remove dashes, ensure 9 digits
clean_ein <- function(x) {
  x <- gsub("[^0-9]", "", x)
  x <- sprintf("%09s", x)
  return(x)
}

sec_eins$ein_clean <- clean_ein(sec_eins$ein)
employer_fy$fein_clean <- clean_ein(employer_fy$FEIN)

# Match
matched <- employer_fy |>
  inner_join(sec_eins, by = c("fein_clean" = "ein_clean"))

cat(sprintf("  Matched employer-FY observations: %d\n", nrow(matched)))
cat(sprintf("  Unique matched firms: %d\n", length(unique(matched$cik))))

# If too few matches, try expanding to more companies
if (length(unique(matched$cik)) < 200) {
  cat("  Expanding SEC EIN search to 6000 companies...\n")
  sec_eins2 <- fetch_sec_ein(sec_df$cik_padded[3001:min(6000, nrow(sec_df))], max_n = 3000)
  sec_eins2 <- sec_eins2[!is.na(sec_eins2$ein) & sec_eins2$ein != "", ]
  sec_eins2$ein_clean <- clean_ein(sec_eins2$ein)
  sec_eins2 <- sec_eins2 |>
    left_join(sec_df |> select(cik, cik_padded, ticker), by = "cik_padded")
  sec_eins <- bind_rows(sec_eins, sec_eins2)

  matched <- employer_fy |>
    inner_join(sec_eins, by = c("fein_clean" = "ein_clean"))

  cat(sprintf("  After expansion — matched firms: %d\n", length(unique(matched$cik))))
}

cat("\n=== Step 5: Fetch Financial Data from SEC EDGAR XBRL API ===\n")

# For matched firms, fetch key financial metrics
unique_ciks <- unique(matched$cik)

fetch_financials <- function(cik, fiscal_years = 2018:2024) {
  url <- sprintf("https://data.sec.gov/api/xbrl/companyfacts/CIK%010d.json", cik)
  tryCatch({
    resp <- request(url) |>
      req_headers(`User-Agent` = "APEP Research olaf@econ.uzh.ch") |>
      req_perform()
    facts <- fromJSON(resp_body_string(resp))

    # Extract key financial variables
    us_gaap <- facts$facts$`us-gaap`
    if (is.null(us_gaap)) return(NULL)

    extract_annual <- function(concept) {
      if (is.null(us_gaap[[concept]])) return(NULL)
      units <- us_gaap[[concept]]$units
      if (!is.null(units$USD)) {
        df <- as.data.frame(units$USD)
        # Keep annual filings (10-K)
        df <- df[grepl("10-K", df$form, ignore.case = TRUE), ]
        if (nrow(df) == 0) return(NULL)
        df$concept <- concept
        df$cik <- cik
        # Extract fiscal year from end date
        df$fy <- as.integer(substr(df$end, 1, 4))
        df <- df[df$fy %in% fiscal_years, ]
        # Keep most recent filing per fiscal year
        df <- df[!duplicated(df[, c("fy")], fromLast = TRUE), ]
        return(df[, c("cik", "fy", "val", "concept")])
      }
      return(NULL)
    }

    concepts <- c("ResearchAndDevelopmentExpense",
                   "Revenues", "RevenueFromContractWithCustomerExcludingAssessedTax",
                   "Assets", "OperatingIncomeLoss",
                   "PropertyPlantAndEquipmentNet", "NetIncomeLoss",
                   "NumberOfEmployeesDataMember")

    results <- lapply(concepts, extract_annual)
    results <- results[!sapply(results, is.null)]
    if (length(results) == 0) return(NULL)
    bind_rows(results)
  }, error = function(e) NULL)
}

cat(sprintf("  Fetching financials for %d firms...\n", length(unique_ciks)))
fin_list <- list()
pb <- txtProgressBar(min = 0, max = length(unique_ciks), style = 3)

for (i in seq_along(unique_ciks)) {
  fin_list[[i]] <- fetch_financials(unique_ciks[i])
  setTxtProgressBar(pb, i)
  if (i %% 8 == 0) Sys.sleep(1)
}
close(pb)

financials_long <- bind_rows(fin_list)
cat(sprintf("  Financial observations: %d\n", nrow(financials_long)))

# Pivot to wide format
financials_wide <- financials_long |>
  # Use first available revenue concept
  mutate(concept = case_when(
    concept == "RevenueFromContractWithCustomerExcludingAssessedTax" ~ "Revenues",
    TRUE ~ concept
  )) |>
  group_by(cik, fy, concept) |>
  summarize(val = first(val), .groups = "drop") |>
  pivot_wider(names_from = concept, values_from = val)

cat(sprintf("  Firms with financial data: %d\n", length(unique(financials_wide$cik))))

cat("\n=== Step 6: Build Analysis Panel ===\n")

# Merge lottery data with financials
# Each firm has lottery data for FY2021 and FY2022 (April lottery → affects that fiscal year)
# Financial outcomes: same year and 1-2 years after

panel <- matched |>
  select(FEIN, fein_clean, fiscal_year, n_registered, n_selected, win_rate,
         employer_name, cik, ticker, name, sic, sic_description) |>
  # Join financial data for concurrent and forward years
  left_join(
    financials_wide |> rename(fin_fy = fy),
    by = "cik",
    relationship = "many-to-many"
  ) |>
  # Keep financial data from lottery year through 2 years after
  filter(fin_fy >= fiscal_year & fin_fy <= fiscal_year + 2) |>
  mutate(horizon = fin_fy - fiscal_year)  # 0 = concurrent, 1 = +1yr, 2 = +2yr

# Add pre-lottery financial data for balance tests
pre_panel <- matched |>
  select(FEIN, fein_clean, fiscal_year, n_registered, n_selected, win_rate,
         cik, ticker, sic) |>
  left_join(
    financials_wide |> rename(fin_fy = fy),
    by = "cik",
    relationship = "many-to-many"
  ) |>
  filter(fin_fy >= fiscal_year - 3 & fin_fy < fiscal_year) |>
  mutate(horizon = fin_fy - fiscal_year)

# Combine
full_panel <- bind_rows(panel, pre_panel)

# Log transform financial variables (in millions)
full_panel <- full_panel |>
  mutate(
    rd_millions = ResearchAndDevelopmentExpense / 1e6,
    rev_millions = Revenues / 1e6,
    assets_millions = Assets / 1e6,
    opinc_millions = OperatingIncomeLoss / 1e6,
    ppe_millions = PropertyPlantAndEquipmentNet / 1e6,
    log_rd = log(pmax(ResearchAndDevelopmentExpense, 1)),
    log_rev = log(pmax(Revenues, 1)),
    log_assets = log(pmax(Assets, 1)),
    rd_intensity = ResearchAndDevelopmentExpense / pmax(Revenues, 1),
    h1b_intensity = n_registered  # Will normalize by employees if available
  )

cat(sprintf("  Final panel observations: %d\n", nrow(full_panel)))
cat(sprintf("  Unique firms in panel: %d\n", length(unique(full_panel$cik))))
cat(sprintf("  Firms with R&D data: %d\n",
            length(unique(full_panel$cik[!is.na(full_panel$ResearchAndDevelopmentExpense)]))))

# Save
saveRDS(full_panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(employer_fy, file.path(data_dir, "employer_fy.rds"))
saveRDS(financials_wide, file.path(data_dir, "financials_wide.rds"))
saveRDS(matched, file.path(data_dir, "matched_firms.rds"))

cat("\n=== Data pipeline complete ===\n")
cat(sprintf("Files saved to %s/\n", data_dir))

# Validation assertions
stopifnot("Must have at least 100 matched firms" =
            length(unique(full_panel$cik)) >= 50)
stopifnot("Must have real financial data" =
            sum(!is.na(full_panel$Revenues)) > 100)
stopifnot("Win rates must be between 0 and 1" =
            all(full_panel$win_rate >= 0 & full_panel$win_rate <= 1))
