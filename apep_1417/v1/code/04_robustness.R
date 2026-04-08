## 04_robustness.R — Robustness and additional analyses
## apep_1417: Singapore ABSD and Housing Markets

source("00_packages.R")

data_dir <- "../data"
panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)
panel$segment_f <- factor(panel$segment, levels = c("OCR", "RCR", "CCR"))

# ============================================================
# 1. Pre-trend test: interaction of CCR × pre-ABSD quarters
# ============================================================
cat("=== Pre-trend tests ===\n")

# Pre-ABSD period: 2004-Q1 to 2011-Q3
pre_data <- panel |>
  filter(date < as.Date("2011-12-01")) |>
  mutate(trend = as.integer(factor(quarter)))

m_pretrend <- fixest::feols(
  log_price ~ treated:trend | segment_f + quarter,
  data = pre_data,
  vcov = DK(4) ~ quarter
)
cat("Pre-trend test (CCR × linear trend):\n")
print(summary(m_pretrend))

# ============================================================
# 2. RCR as alternative control
# ============================================================
cat("\n=== RCR as alternative control ===\n")

# RCR has intermediate foreign exposure (~8%)
panel_ccr_rcr <- panel |> filter(segment %in% c("CCR", "RCR"))
panel_ccr_rcr$treated_ccr <- as.integer(panel_ccr_rcr$segment == "CCR")

m_alt_control <- fixest::feols(
  log_price ~ treated_ccr:post_any | segment_f + quarter,
  data = panel_ccr_rcr,
  vcov = DK(4) ~ quarter
)
cat("CCR vs RCR:\n")
print(summary(m_alt_control))

# ============================================================
# 3. Placebo timing test
# ============================================================
cat("\n=== Placebo timing (fake treatment 2009-Q1) ===\n")

pre_only <- panel |> filter(date < as.Date("2011-12-01"))
pre_only$fake_post <- as.integer(pre_only$date >= as.Date("2009-01-01"))

m_placebo_time <- fixest::feols(
  log_price ~ treated:fake_post | segment_f + quarter,
  data = pre_only,
  vcov = DK(4) ~ quarter
)
cat("Placebo timing:\n")
print(summary(m_placebo_time))

# ============================================================
# 4. Asymmetry test: price vs rental
# ============================================================
cat("\n=== Asymmetry: Ownership vs Rental response ===\n")

rental_panel <- panel |> filter(!is.na(rental_index))

# Stack price and rental in long format for DDD
price_long <- panel |>
  filter(!is.na(price_index), !is.na(rental_index)) |>
  select(segment, segment_f, quarter, treated, post_any, date, price_index, rental_index) |>
  pivot_longer(cols = c(price_index, rental_index),
               names_to = "market", values_to = "index") |>
  mutate(
    log_index = log(index),
    is_price = as.integer(market == "price_index")
  )

m_asymmetry <- fixest::feols(
  log_index ~ treated:post_any:is_price + treated:post_any + is_price:post_any |
    segment_f + quarter,
  data = price_long,
  vcov = DK(4) ~ quarter
)
cat("Triple diff (price vs rental):\n")
print(summary(m_asymmetry))

# ============================================================
# 5. Save robustness results
# ============================================================
rob_results <- list(
  m_pretrend = m_pretrend,
  m_alt_control = m_alt_control,
  m_placebo_time = m_placebo_time,
  m_asymmetry = m_asymmetry
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness analysis complete ===\n")
