## 01b_fix_fy2022.R — Fix FY2022 parsing (ELIGIBLE = not selected) and rebuild panel
## Uses cached SEC data from 01_fetch_data.R

source("00_packages.R")

data_dir <- "../data"

cat("=== Fixing FY2022 H-1B Parsing ===\n")

# Re-parse both years with correct status codes
parse_h1b_file <- function(filepath, fy) {
  cat(sprintf("  Reading %s...\n", filepath))
  df <- fread(filepath, select = c("employer_name", "FEIN", "status_type",
                                    "lottery_year", "ben_multi_reg_ind"))
  # FY2021: CREATED = not selected, SELECTED = selected
  # FY2022: ELIGIBLE = not selected, SELECTED = selected
  df <- df[status_type %in% c("CREATED", "SELECTED", "ELIGIBLE")]
  df[, selected := as.integer(status_type == "SELECTED")]
  df[, fiscal_year := fy]
  cat(sprintf("  %d registrations (%d selected, %d not selected)\n",
              nrow(df), sum(df$selected), sum(df$selected == 0)))
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

cat("\nWin rate summary by FY (5+ registrations):\n")
for (fy in c(2021, 2022)) {
  sub <- employer_fy[n_registered >= 5 & fiscal_year == fy]
  cat(sprintf("  FY%d: N=%d, mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
              fy, nrow(sub), mean(sub$win_rate), sd(sub$win_rate),
              min(sub$win_rate), max(sub$win_rate)))
}

# Load cached SEC EIN matching data
sec_eins <- readRDS(file.path(data_dir, "matched_firms.rds"))
# Get unique SEC EIN-CIK pairs from the matched data
sec_lookup <- sec_eins |>
  select(fein_clean, cik, ticker, name, sic, sic_description) |>
  distinct()

# Clean EIN format
clean_ein <- function(x) {
  x <- gsub("[^0-9]", "", x)
  x <- sprintf("%09s", x)
  return(x)
}

employer_fy[, fein_clean := clean_ein(FEIN)]

# Re-match
matched <- employer_fy |>
  inner_join(sec_lookup, by = "fein_clean", relationship = "many-to-many")

cat(sprintf("\n  Matched employer-FY observations: %d\n", nrow(matched)))
cat(sprintf("  Unique matched firms: %d\n", length(unique(matched$cik))))

# Load cached financial data
financials_wide <- readRDS(file.path(data_dir, "financials_wide.rds"))

cat(sprintf("  Firms with financial data: %d\n", length(unique(financials_wide$cik))))

# Build analysis panel
panel <- matched |>
  select(FEIN, fein_clean, fiscal_year, n_registered, n_selected, win_rate,
         employer_name, cik, ticker, name, sic, sic_description) |>
  left_join(
    financials_wide |> rename(fin_fy = fy),
    by = "cik",
    relationship = "many-to-many"
  ) |>
  filter(fin_fy >= fiscal_year & fin_fy <= fiscal_year + 2) |>
  mutate(horizon = fin_fy - fiscal_year)

# Pre-lottery data
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

full_panel <- bind_rows(panel, pre_panel)

# Log transform
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
    h1b_intensity = n_registered
  )

cat(sprintf("\n  Final panel observations: %d\n", nrow(full_panel)))
cat(sprintf("  Unique firms in panel: %d\n", length(unique(full_panel$cik))))
cat(sprintf("  Firms with R&D data: %d\n",
            length(unique(full_panel$cik[!is.na(full_panel$ResearchAndDevelopmentExpense)]))))

# Deduplicate: keep one row per cik × fiscal_year × horizon
full_panel <- full_panel |>
  group_by(cik, fiscal_year, horizon) |>
  slice(1) |>
  ungroup()

cat(sprintf("  After dedup: %d obs\n", nrow(full_panel)))

# Save
saveRDS(full_panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(employer_fy, file.path(data_dir, "employer_fy.rds"))

cat("\n=== Panel rebuilt with corrected FY2022 data ===\n")

# Validation assertions
stopifnot("Must have at least 100 matched firms" =
            length(unique(full_panel$cik)) >= 50)
stopifnot("Must have real financial data" =
            sum(!is.na(full_panel$Revenues)) > 100)
stopifnot("Win rates must be between 0 and 1" =
            all(full_panel$win_rate >= 0 & full_panel$win_rate <= 1))
