## 04_robustness.R — Robustness checks and placebos
## apep_1345: The Inspector Lottery

source("00_packages.R")
setwd(here::here("output", "apep_1345", "v1"))

## ── 1. Load Data ─────────────────────────────────────────────────────────────

panel <- fread("data/analysis_panel.csv")
ofsted <- fread("data/ofsted_clean.csv")
load("data/models.RData")

panel[, event_month := as.integer(event_month)]
panel[, bad_rating := as.integer(rating >= 3)]
panel[, post := as.integer(event_month >= 0)]
panel[, txn_yq := paste0(year(txn_month), "Q", quarter(txn_month))]

panel_est <- panel[!is.na(log_mean_price)]

## ── 2. Placebo: Pre-Trends Test ─────────────────────────────────────────────

cat("=== Placebo 1: Pre-Trends ===\n")

# Restrict to pre-period only. Test if bad_rating predicts trends
pre_panel <- panel_est[event_month < 0]
pre_panel[, trend_month := event_month + 24]  # Positive trend variable

pre_trend_model <- feols(
  log_mean_price ~ trend_month:bad_rating |
    urn + txn_month,
  data = pre_panel,
  cluster = ~pc_district
)

cat("Pre-trend test (interaction of time trend x bad_rating):\n")
summary(pre_trend_model)
cat("Pre-trend coefficient:", round(coef(pre_trend_model)[1], 6),
    "| p-value:", round(pvalue(pre_trend_model)[1], 4), "\n")

## ── 3. Placebo: Fake Inspection Dates ────────────────────────────────────────

cat("\n=== Placebo 2: Randomized Inspection Dates ===\n")

# Randomly reassign publication dates across schools (permutation test)
set.seed(42)
n_perms <- 500
placebo_coefs <- numeric(n_perms)

school_dates <- unique(panel_est[, .(urn, pub_date, bad_rating)])

for (p in 1:n_perms) {
  # Shuffle pub_date across schools
  shuffled <- copy(school_dates)
  shuffled[, pub_date_fake := sample(pub_date)]

  # Recompute event_month with fake dates
  panel_fake <- merge(panel_est[, .(urn, txn_month, log_mean_price, pc_district)],
                      shuffled[, .(urn, pub_date_fake, bad_rating)],
                      by = "urn")
  panel_fake[, event_month_fake := as.integer(
    difftime(txn_month, pub_date_fake, units = "days") / 30.44
  )]
  panel_fake <- panel_fake[abs(event_month_fake) <= 24]
  panel_fake[, post_fake := as.integer(event_month_fake >= 0)]

  tryCatch({
    m <- feols(log_mean_price ~ post_fake:bad_rating | urn + txn_month,
               data = panel_fake, cluster = ~pc_district)
    placebo_coefs[p] <- coef(m)["post_fake:bad_rating"]
  }, error = function(e) {
    placebo_coefs[p] <<- NA
  })

  if (p %% 100 == 0) cat("  Permutation", p, "/", n_perms, "\n")
}

actual_coef <- coef(did_model)["post:bad_rating"]
ri_pvalue <- mean(abs(placebo_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("Randomization inference p-value:", round(ri_pvalue, 4), "\n")
cat("Actual coefficient:", round(actual_coef, 5), "\n")
cat("Placebo distribution: mean =", round(mean(placebo_coefs, na.rm=TRUE), 5),
    "| sd =", round(sd(placebo_coefs, na.rm=TRUE), 5), "\n")

## ── 4. Alternative Windows ───────────────────────────────────────────────────

cat("\n=== Window Robustness ===\n")

windows <- c(6, 12, 18, 24)
window_results <- list()

for (w in windows) {
  p_w <- panel_est[abs(event_month) <= w]
  p_w[, post_w := as.integer(event_month >= 0)]

  m_w <- feols(log_mean_price ~ post_w:bad_rating | urn + txn_month,
               data = p_w, cluster = ~pc_district)

  window_results[[as.character(w)]] <- data.table(
    window = w,
    coef = coef(m_w)["post_w:bad_rating"],
    se = se(m_w)["post_w:bad_rating"],
    pval = pvalue(m_w)["post_w:bad_rating"],
    n_obs = nrow(p_w)
  )
  cat("Window +/-", w, "months: coef =",
      round(coef(m_w)["post_w:bad_rating"], 4),
      "| SE =", round(se(m_w)["post_w:bad_rating"], 4),
      "| p =", round(pvalue(m_w)["post_w:bad_rating"], 4), "\n")
}

window_dt <- rbindlist(window_results)

## ── 5. Property Type Robustness ──────────────────────────────────────────────

cat("\n=== Property Type Robustness ===\n")

# Re-read land registry to split by property type
lr <- arrow::read_parquet("data/land_registry_2015_2024.parquet")
setDT(lr)
lr[, txn_date := as.Date(date)]
lr[, txn_month := floor_date(txn_date, "month")]
lr[, pc_district := str_extract(postcode, "^[A-Z]{1,2}[0-9][A-Z0-9]?")]
lr <- lr[ppd_cat == "A" & price > 10000 & price < 5000000]
lr[, log_price := log(price)]

# Aggregate by property type
for (ptype in c("D", "S", "T", "F")) {
  lr_sub <- lr[prop_type == ptype, .(
    log_mean_price = mean(log_price, na.rm = TRUE),
    n_txns = .N
  ), by = .(pc_district, txn_month)]

  # Merge with panel
  panel_ptype <- merge(
    panel_est[, .(urn, event_month, pc_district, txn_month, bad_rating, post)],
    lr_sub,
    by = c("pc_district", "txn_month"),
    all.x = TRUE
  )
  panel_ptype <- panel_ptype[!is.na(log_mean_price)]

  tryCatch({
    m_ptype <- feols(log_mean_price ~ post:bad_rating | urn + txn_month,
                     data = panel_ptype, cluster = ~pc_district)
    ptype_label <- switch(ptype, D = "Detached", S = "Semi-detached",
                          T = "Terraced", F = "Flat")
    cat(ptype_label, ": coef =",
        round(coef(m_ptype)["post:bad_rating"], 4),
        "| SE =", round(se(m_ptype)["post:bad_rating"], 4),
        "| N =", nrow(panel_ptype), "\n")
  }, error = function(e) {
    cat(ptype, ": insufficient data\n")
  })
}

rm(lr)
gc()

## ── 6. Phase Heterogeneity (Primary vs Secondary) ───────────────────────────

cat("\n=== Phase Heterogeneity ===\n")

panel_est <- merge(panel_est,
                   ofsted[, .(urn, phase)],
                   by = "urn", all.x = TRUE, suffixes = c("", ".y"))
if ("phase.y" %in% names(panel_est)) {
  panel_est[is.na(phase), phase := phase.y]
  panel_est[, phase.y := NULL]
}

for (ph in c("Primary", "Secondary")) {
  p_ph <- panel_est[phase == ph]
  if (nrow(p_ph) > 100) {
    m_ph <- feols(log_mean_price ~ post:bad_rating | urn + txn_month,
                  data = p_ph, cluster = ~pc_district)
    cat(ph, ": coef =",
        round(coef(m_ph)["post:bad_rating"], 4),
        "| SE =", round(se(m_ph)["post:bad_rating"], 4),
        "| N_schools =", uniqueN(p_ph$urn), "\n")
  }
}

## ── 7. Save Robustness Results ───────────────────────────────────────────────

save(pre_trend_model, placebo_coefs, actual_coef, ri_pvalue,
     window_dt, file = "data/robustness.RData")

cat("\n=== Robustness checks complete ===\n")
