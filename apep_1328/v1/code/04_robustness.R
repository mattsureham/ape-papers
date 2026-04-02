## 04_robustness.R — Placebo tests, leave-one-out, alternative outcomes

source("00_packages.R")

panel  <- readRDS("../data/panel_clean.rds")
baltic <- readRDS("../data/baltic_clean.rds")

# ──────────────────────────────────────────────────────────────────────────────
# A. PLACEBO TREATMENT DATES (Baltic DiD)
# ──────────────────────────────────────────────────────────────────────────────

cat("=== A. Placebo treatment dates ===\n")

placebo_years <- c(2010, 2011, 2012, 2013)
placebo_results <- list()

for (py in placebo_years) {
  baltic_temp <- baltic %>%
    mutate(placebo_post = as.integer(year >= py),
           placebo_tp = treated * placebo_post) %>%
    filter(year <= 2014)  # only pre-treatment data

  fit <- feols(biz_density ~ placebo_tp | iso3 + year,
               data = baltic_temp, cluster = ~iso3)

  placebo_results[[as.character(py)]] <- data.frame(
    placebo_year = py,
    coef = coef(fit)["placebo_tp"],
    se = sqrt(diag(vcov(fit)))["placebo_tp"],
    pval = fixest::pvalue(fit)["placebo_tp"]
  )
  cat(sprintf("  Placebo %d: coef=%.3f, se=%.3f, p=%.3f\n",
              py, coef(fit)["placebo_tp"],
              sqrt(diag(vcov(fit)))["placebo_tp"],
              fixest::pvalue(fit)["placebo_tp"]))
}

placebo_df <- bind_rows(placebo_results)
cat("\nAll placebos should be insignificant (p > 0.10):\n")
print(placebo_df)

# ──────────────────────────────────────────────────────────────────────────────
# B. LEAVE-ONE-OUT DONOR (Full panel)
# ──────────────────────────────────────────────────────────────────────────────

cat("\n=== B. Leave-one-out ===\n")

donors <- setdiff(unique(panel$iso3), "EST")
loo_results <- list()

for (d in donors) {
  panel_loo <- panel %>%
    filter(iso3 != d, !is.na(biz_density))

  fit <- feols(biz_density ~ treat_post | iso3 + year,
               data = panel_loo, cluster = ~iso3)

  loo_results[[d]] <- data.frame(
    dropped = d,
    coef = coef(fit)["treat_post"],
    se = sqrt(diag(vcov(fit)))["treat_post"]
  )
}

loo_df <- bind_rows(loo_results)
cat("Leave-one-out sensitivity (dropping each donor):\n")
print(loo_df)

# ──────────────────────────────────────────────────────────────────────────────
# C. ALTERNATIVE OUTCOMES (GDP per capita — should show smaller effect)
# ──────────────────────────────────────────────────────────────────────────────

cat("\n=== C. Alternative outcomes ===\n")

# GDP per capita (Baltic DiD) — e-Residency firms are often shell-like,
# so GDP effect should be much smaller
did_gdp <- feols(
  ln_gdp_pc ~ treat_post | iso3 + year,
  data = baltic %>% filter(!is.na(ln_gdp_pc)),
  cluster = ~iso3
)
cat("GDP per capita (log) — Baltic DiD:\n")
print(summary(did_gdp))

# Trade openness — could increase if e-Resident firms trade
did_trade <- feols(
  trade_open ~ treat_post | iso3 + year,
  data = baltic %>% filter(!is.na(trade_open)),
  cluster = ~iso3
)
cat("\nTrade openness — Baltic DiD:\n")
print(summary(did_trade))

# Internet users — should be null (pre-existing digital infrastructure)
did_internet <- feols(
  internet ~ treat_post | iso3 + year,
  data = baltic %>% filter(!is.na(internet)),
  cluster = ~iso3
)
cat("\nInternet users — Baltic DiD:\n")
print(summary(did_internet))

# ──────────────────────────────────────────────────────────────────────────────
# D. PLACEBO SCM — reassign treatment to each donor
# ──────────────────────────────────────────────────────────────────────────────

cat("\n=== D. Placebo SCM (in-space placebos) ===\n")

# We run the full-panel DiD treating each country as if it were Estonia
scm_data <- panel %>% filter(!is.na(biz_density))

placebo_scm <- list()
for (c in unique(scm_data$iso3)) {
  temp <- scm_data %>%
    mutate(placebo_treat = as.integer(iso3 == c),
           placebo_tp = placebo_treat * post)

  fit <- feols(biz_density ~ placebo_tp | iso3 + year,
               data = temp, cluster = ~iso3)

  placebo_scm[[c]] <- data.frame(
    country = c,
    coef = coef(fit)["placebo_tp"],
    se = sqrt(diag(vcov(fit)))["placebo_tp"],
    pval = fixest::pvalue(fit)["placebo_tp"]
  )
}

placebo_scm_df <- bind_rows(placebo_scm) %>% arrange(desc(abs(coef)))
cat("In-space placebo (Estonia should have the largest effect):\n")
print(placebo_scm_df)

# ── Save ──────────────────────────────────────────────────────────────────────
saveRDS(placebo_df, "../data/placebo_time.rds")
saveRDS(loo_df, "../data/loo_results.rds")
saveRDS(did_gdp, "../data/did_gdp.rds")
saveRDS(did_trade, "../data/did_trade.rds")
saveRDS(did_internet, "../data/did_internet.rds")
saveRDS(placebo_scm_df, "../data/placebo_scm.rds")

cat("\nRobustness results saved.\n")
