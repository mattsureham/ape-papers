## 03_main_analysis.R — Main regression analysis
## apep_1417: Singapore ABSD and Housing Markets
##
## Note: With only 3 market segments, cluster-robust SEs at the segment level
## are unreliable (few-cluster problem). We use Newey-West HAC standard errors
## throughout, which account for serial correlation without requiring many clusters.

source("00_packages.R")

data_dir <- "../data"
panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)
absd_rounds <- readRDS(file.path(data_dir, "absd_rounds.rds"))
hdb_q <- read_csv(file.path(data_dir, "hdb_quarterly.csv"), show_col_types = FALSE)

panel$segment_f <- factor(panel$segment, levels = c("OCR", "RCR", "CCR"))

cat("=== Panel summary ===\n")
cat("  Obs:", nrow(panel), "| Segments:", paste(unique(panel$segment), collapse = ", "), "\n")
cat("  Quarters:", n_distinct(panel$quarter), "| Years:", min(panel$year), "-", max(panel$year), "\n")

# ============================================================
# 1. Baseline DiD: CCR vs OCR+RCR, Pre vs Post-ABSD
# ============================================================
cat("\n=== Baseline DiD ===\n")

# Newey-West with 4-quarter bandwidth
m_price_base <- fixest::feols(
  log_price ~ treated:post_any | segment_f + quarter,
  data = panel, vcov = DK(4) ~ quarter
)

rental_panel <- panel |> filter(!is.na(rental_index))
m_rental_base <- fixest::feols(
  log_rental ~ treated:post_any | segment_f + quarter,
  data = rental_panel, vcov = DK(4) ~ quarter
)

txn_panel <- panel |> filter(!is.na(total_units), segment %in% c("CCR", "OCR"))
m_txn_base <- fixest::feols(
  log_units ~ treated:post_any | segment_f + quarter,
  data = txn_panel, vcov = DK(4) ~ quarter
)

cat("Price:", round(fixest::coeftable(m_price_base)[1,1], 4),
    "SE:", round(fixest::coeftable(m_price_base)[1,2], 4), "\n")
cat("Rental:", round(fixest::coeftable(m_rental_base)[1,1], 4),
    "SE:", round(fixest::coeftable(m_rental_base)[1,2], 4), "\n")
cat("Txn:", round(fixest::coeftable(m_txn_base)[1,1], 4),
    "SE:", round(fixest::coeftable(m_txn_base)[1,2], 4), "\n")

# ============================================================
# 2. Dose-Response: Each ABSD round
# ============================================================
cat("\n=== Dose-response by round ===\n")

m_price_dose <- fixest::feols(
  log_price ~ treated:post_r1 + treated:post_r2 + treated:post_r3 +
    treated:post_r4 + treated:post_r5 | segment_f + quarter,
  data = panel, vcov = DK(4) ~ quarter
)

m_rental_dose <- fixest::feols(
  log_rental ~ treated:post_r1 + treated:post_r2 + treated:post_r3 +
    treated:post_r4 + treated:post_r5 | segment_f + quarter,
  data = rental_panel, vcov = DK(4) ~ quarter
)

print(summary(m_price_dose))

# ============================================================
# 3. Continuous treatment: ABSD rate × CCR
# ============================================================
cat("\n=== Continuous treatment ===\n")

m_price_cont <- fixest::feols(
  log_price ~ treated:absd_rate | segment_f + quarter,
  data = panel, vcov = DK(4) ~ quarter
)

m_rental_cont <- fixest::feols(
  log_rental ~ treated:absd_rate | segment_f + quarter,
  data = rental_panel, vcov = DK(4) ~ quarter
)

cat("Price per pp:", round(fixest::coeftable(m_price_cont)[1,1], 5), "\n")
cat("Rental per pp:", round(fixest::coeftable(m_rental_cont)[1,1], 5), "\n")

# ============================================================
# 4. Event study around Round 5 (60% ABSD)
# ============================================================
cat("\n=== Event study: Round 5 ===\n")

# Use all 3 segments for more variation
panel$rel_q_r5 <- round((panel$time_q - 2023.25) * 4)

es_data <- panel |> filter(abs(rel_q_r5) <= 8)

m_es_r5 <- fixest::feols(
  log_price ~ i(rel_q_r5, treated, ref = -1) | segment_f + quarter,
  data = es_data, vcov = DK(4) ~ quarter
)
cat("Event study coefficients:\n")
print(fixest::coeftable(m_es_r5))

# ============================================================
# 5. HDB Placebo
# ============================================================
cat("\n=== HDB Placebo ===\n")

# Use town-level HDB panel. Since quarter FE absorbs post_r5,
# use a triple-diff approach: compare towns with more vs fewer
# nearby CCR condos (proxy for ABSD exposure)
hdb_q <- hdb_q |>
  mutate(
    log_price = log(mean_price),
    town_f = factor(town),
    # Classify towns by proximity to CCR
    near_ccr = as.integer(town %in% c("BUKIT TIMAH", "BISHAN", "TOA PAYOH",
                                       "QUEENSTOWN", "CENTRAL AREA", "KALLANG/WHAMPOA")),
    post_r5 = as.integer(date >= as.Date("2023-04-01"))
  )

m_hdb_placebo <- fixest::feols(
  log_price ~ near_ccr:post_r5 | town_f + quarter,
  data = hdb_q, vcov = DK(4) ~ quarter
)
cat("HDB placebo (near-CCR towns × post-R5):\n")
print(summary(m_hdb_placebo))

# ============================================================
# 6. Save results
# ============================================================
results <- list(
  m_price_base = m_price_base,
  m_rental_base = m_rental_base,
  m_txn_base = m_txn_base,
  m_price_dose = m_price_dose,
  m_rental_dose = m_rental_dose,
  m_price_cont = m_price_cont,
  m_rental_cont = m_rental_cont,
  m_es_r5 = m_es_r5,
  m_hdb_placebo = m_hdb_placebo
)

saveRDS(results, file.path(data_dir, "regression_results.rds"))

# Diagnostics
# Design uses 3 market segments × 88 quarters; CCR is treated (88 treated obs)
# n_treated counts treated segment-quarter observations, not individual units
n_treated <- sum(panel$treated == 1)  # 88 CCR quarters
n_pre <- length(unique(panel$quarter[panel$year < 2012]))  # 32 pre-treatment quarters
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n  Diagnostics: n_treated =", n_treated, "n_pre =", n_pre, "n_obs =", n_obs, "\n")
cat("=== Main analysis complete ===\n")
