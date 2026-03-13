## 02_clean_data.R — Variable construction and sample preparation
## APEP Paper apep_0619: H-1B Visa Lottery and Firm R&D Investment

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
employer_fy <- readRDS(file.path(data_dir, "employer_fy.rds"))

cat("=== Data Cleaning and Variable Construction ===\n")
cat(sprintf("Starting panel: %d obs, %d firms\n", nrow(panel), length(unique(panel$cik))))

# ---- 1. Industry classification ----
# SIC codes for H-1B intensive industries
panel <- panel |>
  mutate(
    sic_2d = as.integer(substr(sic, 1, 2)),
    tech_sector = case_when(
      sic_2d %in% c(35, 36, 37, 38) ~ "Manufacturing (Tech)",
      sic_2d == 73 ~ "Business Services / Software",
      sic_2d == 28 ~ "Chemicals / Pharma",
      sic_2d == 48 ~ "Communications",
      sic_2d == 87 ~ "Engineering / R&D Services",
      TRUE ~ "Other"
    ),
    is_tech = sic_2d %in% c(35, 36, 37, 38, 73, 28, 48, 87)
  )

cat("\nIndustry distribution:\n")
panel |>
  filter(horizon == 0) |>
  distinct(cik, .keep_all = TRUE) |>
  count(tech_sector) |>
  arrange(desc(n)) |>
  print()

# ---- 2. Filter to estimation sample ----
# Keep firms with:
# a) At least 5 registrations (meaningful lottery variation)
# b) Non-missing financial outcomes for at least 1 variable
# c) Valid win rate

est_sample <- panel |>
  filter(n_registered >= 5) |>
  filter(!is.na(Revenues) | !is.na(ResearchAndDevelopmentExpense) |
         !is.na(Assets))

cat(sprintf("\nEstimation sample (5+ registrations): %d obs, %d firms\n",
            nrow(est_sample), length(unique(est_sample$cik))))

# ---- 3. Winsorize extreme values ----
winsorize <- function(x, p = 0.01) {
  if (all(is.na(x))) return(x)
  q <- quantile(x, c(p, 1-p), na.rm = TRUE)
  pmax(pmin(x, q[2]), q[1])
}

est_sample <- est_sample |>
  mutate(
    across(c(rd_millions, rev_millions, assets_millions, opinc_millions, ppe_millions),
           winsorize, .names = "{.col}_w"),
    log_rd_w = log(pmax(rd_millions_w, 0.001)),
    log_rev_w = log(pmax(rev_millions_w, 0.001)),
    log_assets_w = log(pmax(assets_millions_w, 0.001))
  )

# ---- 4. Create lag/change variables ----
# For each firm × lottery year, compute change from pre to post
est_sample <- est_sample |>
  group_by(cik, fiscal_year) |>
  arrange(horizon) |>
  mutate(
    # Pre-period average (horizon < 0)
    pre_rd = mean(rd_millions[horizon < 0], na.rm = TRUE),
    pre_rev = mean(rev_millions[horizon < 0], na.rm = TRUE),
    pre_assets = mean(assets_millions[horizon < 0], na.rm = TRUE),
    # Change relative to pre-period
    rd_change = rd_millions - pre_rd,
    rev_change = rev_millions - pre_rev
  ) |>
  ungroup()

# ---- 5. H-1B dependence measure ----
# registrations per $100M revenue (proxy for H-1B intensity)
est_sample <- est_sample |>
  mutate(
    h1b_per_rev = n_registered / pmax(rev_millions, 1) * 100,  # per $100M
    high_h1b_dependence = h1b_per_rev > median(h1b_per_rev, na.rm = TRUE)
  )

# ---- 6. Summary statistics ----
cat("\n=== Summary Statistics ===\n")

# Concurrent period (horizon = 0) for summary
sum_df <- est_sample |>
  filter(horizon == 0)

cat(sprintf("\nN firms: %d\n", length(unique(sum_df$cik))))
cat(sprintf("N firm-FY obs: %d\n", nrow(sum_df)))

cat("\nLottery variables:\n")
cat(sprintf("  Registrations: mean=%.1f, median=%.0f, sd=%.1f\n",
            mean(sum_df$n_registered), median(sum_df$n_registered),
            sd(sum_df$n_registered)))
cat(sprintf("  Win rate: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
            mean(sum_df$win_rate), sd(sum_df$win_rate),
            min(sum_df$win_rate), max(sum_df$win_rate)))

cat("\nFinancial variables (millions USD):\n")
for (v in c("rd_millions", "rev_millions", "assets_millions")) {
  vals <- sum_df[[v]]
  vals <- vals[!is.na(vals)]
  cat(sprintf("  %s: mean=%.1f, median=%.1f, sd=%.1f, N=%d\n",
              v, mean(vals), median(vals), sd(vals), length(vals)))
}

# Save estimation sample
saveRDS(est_sample, file.path(data_dir, "est_sample.rds"))

cat(sprintf("\n=== Estimation sample saved: %d obs ===\n", nrow(est_sample)))
