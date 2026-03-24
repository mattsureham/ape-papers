## 03_main_analysis.R — Main DiD and event study analysis
## apep_0872: Hungary bank levy and credit supply

source("00_packages.R")

bsi <- readRDS("../data/bsi_panel.rds")
wb <- readRDS("../data/wb_panel.rds")

# ============================================================
# 0. Drop Slovakia from BSI (data quality issue: subcategory)
#    Keep for WB (annual credit/GDP is correct)
# ============================================================
bsi <- bsi %>% filter(country != "SK")
cat(sprintf("BSI panel (excl. SK): %d obs, countries: %s\n",
            nrow(bsi), paste(unique(bsi$country), collapse = ", ")))

# Restrict to 2005-2020 for balanced pre/post
bsi <- bsi %>% filter(date >= as.Date("2005-01-01"))
cat(sprintf("BSI after 2005+ filter: %d obs\n", nrow(bsi)))

# Create a numeric month index for FE
bsi <- bsi %>%
  mutate(
    month_id = as.integer(factor(date)),
    country_id = as.integer(factor(country))
  )

# ============================================================
# 1. MAIN SPECIFICATION: DiD on log NFC loans
# ============================================================
cat("\n=== MAIN SPECIFICATION ===\n")

# (1) Simple DiD
m1 <- feols(log_nfc_loans ~ treat | country + month_id, data = bsi)
cat("\nModel 1: DiD on log NFC loans\n")
summary(m1)

# (2) With country-specific linear trends (pre-treatment)
bsi$trend <- as.numeric(bsi$date - as.Date("2010-09-01")) / 365.25
bsi$country_trend <- interaction(bsi$country, "trend")
m2 <- feols(log_nfc_loans ~ treat + i(country, trend) | country + month_id,
            data = bsi)
cat("\nModel 2: DiD with country-specific trends\n")
summary(m2)

# ============================================================
# 2. EVENT STUDY
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Bin event time: use 6-month bins to reduce noise
bsi$event_bin <- floor(bsi$event_time / 6) * 6
# Cap at -36 and +60
bsi$event_bin <- pmax(pmin(bsi$event_bin, 60), -36)

# Reference period: -6 (6 months before treatment)
m_event <- feols(log_nfc_loans ~ i(event_bin, hungary, ref = -6) | country + month_id,
                 data = bsi)
cat("\nEvent study (6-month bins):\n")
summary(m_event)

# Save event study coefficients for tables
event_coefs <- as.data.frame(coeftable(m_event))
event_coefs$term <- rownames(event_coefs)
saveRDS(event_coefs, "../data/event_coefs.rds")

# ============================================================
# 3. WORLD BANK ANNUAL SPECIFICATION
# ============================================================
cat("\n=== WORLD BANK: Credit/GDP ===\n")

# Keep 2003-2020
wb_sub <- wb %>% filter(year >= 2003 & year <= 2020)

m_wb <- feols(credit_gdp ~ treat | country + year, data = wb_sub)
cat("\nModel WB: Credit/GDP DiD\n")
summary(m_wb)

# ============================================================
# 4. FGS REVERSAL TEST (2013+)
# ============================================================
cat("\n=== FGS REVERSAL TEST ===\n")

# Test: Does credit recover after FGS launch (June 2013)?
# Restrict to post-levy period only (2010:09 onward)
bsi_post <- bsi %>% filter(date >= as.Date("2010-09-01"))

m_fgs <- feols(log_nfc_loans ~ i(hungary, fgs_period) | country + month_id,
               data = bsi_post)
cat("\nFGS reversal (within post-levy period):\n")
summary(m_fgs)

# ============================================================
# 5. THREE-PERIOD SPECIFICATION
# ============================================================
cat("\n=== THREE-PERIOD SPECIFICATION ===\n")

# Pre (2005-2010:08), Levy (2010:09-2013:05), FGS (2013:06+)
bsi$period <- case_when(
  bsi$date < as.Date("2010-09-01") ~ "Pre",
  bsi$date < as.Date("2013-06-01") ~ "Levy",
  TRUE ~ "FGS"
)
bsi$period <- factor(bsi$period, levels = c("Pre", "Levy", "FGS"))

m_3per <- feols(log_nfc_loans ~ i(period, hungary, ref = "Pre") | country + month_id,
                data = bsi)
cat("\nThree-period specification:\n")
summary(m_3per)

# ============================================================
# 6. COMPUTE KEY STATISTICS
# ============================================================
cat("\n=== KEY STATISTICS ===\n")

# Pre-treatment SD of log NFC loans (for SDE calculation)
pre_bsi <- bsi %>% filter(date < as.Date("2010-09-01"))
sd_y <- sd(pre_bsi$log_nfc_loans)
cat(sprintf("SD(log NFC loans), pre-treatment: %.4f\n", sd_y))

# Main treatment effect
beta_main <- coef(m1)["treat"]
se_main <- se(m1)["treat"]
cat(sprintf("Main DiD estimate: %.4f (SE: %.4f)\n", beta_main, se_main))
cat(sprintf("Percentage effect: %.1f%%\n", (exp(beta_main) - 1) * 100))

# SDE
sde_main <- beta_main / sd_y
se_sde <- se_main / sd_y
cat(sprintf("SDE: %.4f (SE: %.4f)\n", sde_main, se_sde))

# Credit multiplier: levy revenue ~180B HUF/year ≈ ~500M EUR/year
# Credit loss: HU NFC loans ~74B pre → ~69B post in EUR
hu_pre_mean <- mean(bsi$nfc_loans_eur[bsi$country == "HU" & bsi$date < as.Date("2010-09-01")])
hu_post_mean <- mean(bsi$nfc_loans_eur[bsi$country == "HU" & bsi$date >= as.Date("2010-09-01") &
                                         bsi$date < as.Date("2013-06-01")])
credit_loss_raw <- hu_pre_mean - hu_post_mean
cat(sprintf("\nHU NFC loans: pre-mean %.0f, post-mean %.0f, raw loss %.0f EUR mn\n",
            hu_pre_mean, hu_post_mean, credit_loss_raw))

# But we need counterfactual growth. Controls grew:
ctrl_pre <- mean(bsi$nfc_loans_eur[bsi$country != "HU" & bsi$date < as.Date("2010-09-01")])
ctrl_post <- mean(bsi$nfc_loans_eur[bsi$country != "HU" & bsi$date >= as.Date("2010-09-01") &
                                      bsi$date < as.Date("2013-06-01")])
ctrl_growth <- ctrl_post / ctrl_pre
cat(sprintf("Control group growth factor: %.3f\n", ctrl_growth))

counterfactual_hu <- hu_pre_mean * ctrl_growth
credit_loss_cf <- counterfactual_hu - hu_post_mean
cat(sprintf("Counterfactual HU loans: %.0f EUR mn\n", counterfactual_hu))
cat(sprintf("Credit loss (vs counterfactual): %.0f EUR mn\n", credit_loss_cf))

# ============================================================
# 7. SAVE RESULTS FOR TABLES
# ============================================================
results <- list(
  m1 = m1,
  m2 = m2,
  m_event = m_event,
  m_wb = m_wb,
  m_fgs = m_fgs,
  m_3per = m_3per,
  sd_y = sd_y,
  beta_main = beta_main,
  se_main = se_main,
  sde_main = sde_main,
  se_sde = se_sde,
  hu_pre_mean = hu_pre_mean,
  hu_post_mean = hu_post_mean,
  credit_loss_cf = credit_loss_cf,
  ctrl_growth = ctrl_growth
)
saveRDS(results, "../data/main_results.rds")

# Diagnostics for validator
# n_treated = treated country-months (Hungary post-levy observations)
n_hu_post <- sum(bsi$country == "HU" & bsi$date >= as.Date("2010-09-01"))
diagnostics <- list(
  n_treated = n_hu_post,  # 124 Hungary post-levy months
  n_pre = length(unique(bsi$date[bsi$date < as.Date("2010-09-01")])),
  n_obs = nrow(bsi),
  n_countries = length(unique(bsi$country)),
  n_months = length(unique(bsi$date)),
  sd_y = sd_y,
  beta = beta_main,
  se = se_main
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults saved.\n")
cat("DONE: 03_main_analysis.R\n")
