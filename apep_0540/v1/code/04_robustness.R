# 04_robustness.R — Robustness checks and placebo tests
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

source("00_packages.R")

cat("=== PHASE 4: ROBUSTNESS AND PLACEBOS ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, date := as.Date(date)]
milestones <- fread(file.path(DATA_DIR, "gpe_milestones.csv"))

# ──────────────────────────────────────────────────────────────────
# 1. PLACEBO: DELAYED LINES (opening 2028+)
# ──────────────────────────────────────────────────────────────────

cat("=== 1. Placebo: Delayed lines ===\n")

# Lines with late opening (L15O, L15E) should show no opening premium
# but may show construction effects
delayed_lines <- c("L15O", "L15E")
early_lines <- c("L14S", "L15S", "L16")

panel[, delayed_line := nearest_line %in% delayed_lines]
panel[, early_line := nearest_line %in% early_lines]

# Among properties near delayed lines, test for post-construction effects
delayed_sample <- panel[(ring_1km & delayed_line) | control]
delayed_sample[, treated_delayed := ring_1km & delayed_line & post_construction]

placebo_delayed <- feols(
  log_price_m2 ~ treated_delayed +
    surface + I(surface^2) + rooms + i(prop_type) |
    commune + year_quarter,
  data = delayed_sample,
  cluster = ~commune
)

cat("Placebo (delayed lines, construction phase only):\n")
summary(placebo_delayed)

# Properties near delayed lines should NOT show an opening premium
# (because they haven't opened yet in our sample period)
delayed_opening <- panel[(ring_1km & delayed_line) | control]
delayed_opening[, treated_opening_placebo := ring_1km & delayed_line & post_opening]

if (sum(delayed_opening$treated_opening_placebo, na.rm = TRUE) > 0) {
  placebo_opening <- feols(
    log_price_m2 ~ treated_opening_placebo +
      surface + I(surface^2) + rooms + i(prop_type) |
      commune + year_quarter,
    data = delayed_opening,
    cluster = ~commune
  )
  cat("Placebo (delayed lines, opening phase — should be zero or NA):\n")
  summary(placebo_opening)
} else {
  cat("No opening events for delayed lines in sample period (as expected).\n")
}

# ──────────────────────────────────────────────────────────────────
# 2. SUN & ABRAHAM INTERACTION-WEIGHTED ESTIMATOR
# ──────────────────────────────────────────────────────────────────

cat("\n=== 2. Sun & Abraham estimator ===\n")

es_sample <- panel[ring_1km | control]
es_sample <- es_sample[!is.na(event_quarter)]
es_sample <- es_sample[event_quarter >= -16 & event_quarter <= 20]

# Cohort variable for Sun-Abraham
es_sample[, cohort := fifelse(ring_1km, cohort_yq, "never")]

tryCatch({
  sa_model <- feols(
    log_price_m2 ~ sunab(cohort, event_quarter) +
      surface + I(surface^2) + rooms + i(prop_type) |
      commune + year_quarter,
    data = es_sample,
    cluster = ~commune
  )

  cat("Sun & Abraham event study:\n")
  sa_coefs <- coeftable(sa_model)
  sa_rows <- grepl("event_quarter", rownames(sa_coefs))

  sa_dt <- data.table(
    event_quarter = as.integer(str_extract(rownames(sa_coefs)[sa_rows], "-?\\d+$")),
    estimate = sa_coefs[sa_rows, "Estimate"],
    se = sa_coefs[sa_rows, "Std. Error"]
  )
  sa_dt[, ci_low := estimate - 1.96 * se]
  sa_dt[, ci_high := estimate + 1.96 * se]
  sa_dt <- sa_dt[order(event_quarter)]

  fwrite(sa_dt, file.path(DATA_DIR, "sun_abraham_event_study.csv"))
  cat("Sun & Abraham coefficients saved.\n")
}, error = function(e) {
  cat(sprintf("Sun & Abraham failed: %s\n", e$message))
})

# ──────────────────────────────────────────────────────────────────
# 3. APARTMENTS ONLY (composition control)
# ──────────────────────────────────────────────────────────────────

cat("\n=== 3. Apartments only ===\n")

apt_sample <- panel[(ring_1km | control) & prop_type == "apartment"]

apt_did <- feols(
  log_price_m2 ~ treated_construction +
    surface + I(surface^2) + rooms |
    commune + year_quarter,
  data = apt_sample,
  cluster = ~commune
)

cat("Apartments only:\n")
summary(apt_did)

# ──────────────────────────────────────────────────────────────────
# 4. HETEROGENEITY BY LINE
# ──────────────────────────────────────────────────────────────────

cat("\n=== 4. Heterogeneity by line ===\n")

line_results <- list()
for (ln in unique(panel$nearest_line[panel$ring_1km])) {
  if (is.na(ln)) next
  line_sample <- panel[(ring_1km & nearest_line == ln) | control]
  line_sample[, treated_line := ring_1km & nearest_line == ln & post_construction]

  mod <- tryCatch({
    feols(
      log_price_m2 ~ treated_line +
        surface + I(surface^2) + rooms + i(prop_type) |
        commune + year_quarter,
      data = line_sample,
      cluster = ~commune
    )
  }, error = function(e) NULL)

  if (!is.null(mod)) {
    line_results[[ln]] <- data.table(
      line = ln,
      estimate = coef(mod)["treated_lineTRUE"],
      se = se(mod)["treated_lineTRUE"],
      n = nobs(mod)
    )
  }
}

line_het <- rbindlist(line_results)
line_het[, ci_low := estimate - 1.96 * se]
line_het[, ci_high := estimate + 1.96 * se]
fwrite(line_het, file.path(DATA_DIR, "heterogeneity_by_line.csv"))
cat("Heterogeneity by line:\n")
print(line_het)

# ──────────────────────────────────────────────────────────────────
# 5. LEAVE-ONE-LINE-OUT
# ──────────────────────────────────────────────────────────────────

cat("\n=== 5. Leave-one-line-out ===\n")

lolo_results <- list()
for (drop_line in unique(panel$nearest_line[panel$ring_1km])) {
  if (is.na(drop_line)) next
  lolo_sample <- panel[(ring_1km & nearest_line != drop_line) | control]
  lolo_sample[, treated_lolo := ring_1km & post_construction]

  mod <- tryCatch({
    feols(
      log_price_m2 ~ treated_lolo +
        surface + I(surface^2) + rooms + i(prop_type) |
        commune + year_quarter,
      data = lolo_sample,
      cluster = ~commune
    )
  }, error = function(e) NULL)

  if (!is.null(mod)) {
    lolo_results[[drop_line]] <- data.table(
      dropped_line = drop_line,
      estimate = coef(mod)["treated_loloTRUE"],
      se = se(mod)["treated_loloTRUE"],
      n = nobs(mod)
    )
  }
}

lolo_dt <- rbindlist(lolo_results)
lolo_dt[, ci_low := estimate - 1.96 * se]
lolo_dt[, ci_high := estimate + 1.96 * se]
fwrite(lolo_dt, file.path(DATA_DIR, "leave_one_line_out.csv"))
cat("Leave-one-line-out:\n")
print(lolo_dt)

# ──────────────────────────────────────────────────────────────────
# 6. COMPOSITION TEST
# ──────────────────────────────────────────────────────────────────

cat("\n=== 6. Composition test ===\n")

# Test whether property characteristics change near stations after construction
comp_sample <- panel[ring_1km | control]

comp_surface <- feols(
  surface ~ treated_construction | commune + year_quarter,
  data = comp_sample, cluster = ~commune
)

comp_rooms <- feols(
  rooms ~ treated_construction | commune + year_quarter,
  data = comp_sample[!is.na(rooms)], cluster = ~commune
)

comp_type <- feols(
  I(prop_type == "apartment") ~ treated_construction | commune + year_quarter,
  data = comp_sample, cluster = ~commune
)

comp_results <- data.table(
  outcome = c("Surface (m2)", "Rooms", "Apartment share"),
  estimate = c(coef(comp_surface)["treated_constructionTRUE"],
               coef(comp_rooms)["treated_constructionTRUE"],
               coef(comp_type)["treated_constructionTRUE"]),
  se = c(se(comp_surface)["treated_constructionTRUE"],
         se(comp_rooms)["treated_constructionTRUE"],
         se(comp_type)["treated_constructionTRUE"])
)
comp_results[, pval := 2 * pnorm(-abs(estimate / se))]
fwrite(comp_results, file.path(DATA_DIR, "composition_test.csv"))
cat("Composition test:\n")
print(comp_results)

# ──────────────────────────────────────────────────────────────────
# 7. HONESTDID SENSITIVITY
# ──────────────────────────────────────────────────────────────────

cat("\n=== 7. HonestDiD sensitivity ===\n")

tryCatch({
  # Use the TWFE event study for HonestDiD
  es_for_honest <- feols(
    log_price_m2 ~ i(ring_1km:i(event_quarter), ref = -1) +
      surface + I(surface^2) + rooms + i(prop_type) |
      commune + year_quarter,
    data = panel[(ring_1km | control) & !is.na(event_quarter) &
                   event_quarter >= -8 & event_quarter <= 12],
    cluster = ~commune
  )

  # Extract pre-period coefficients and vcov
  all_coefs <- coef(es_for_honest)
  es_names <- names(all_coefs)[grepl("event_quarter", names(all_coefs))]
  es_nums <- as.integer(str_extract(es_names, "-?\\d+$"))

  pre_idx <- which(es_nums < -1)
  post_idx <- which(es_nums >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    beta_hat <- all_coefs[c(pre_idx, post_idx)]
    sigma_hat <- vcov(es_for_honest)[c(pre_idx, post_idx), c(pre_idx, post_idx)]

    honest_result <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )

    honest_dt <- as.data.table(honest_result)
    fwrite(honest_dt, file.path(DATA_DIR, "honestdid_sensitivity.csv"))
    cat("HonestDiD sensitivity saved.\n")
  } else {
    cat("Not enough pre/post periods for HonestDiD.\n")
  }
}, error = function(e) {
  cat(sprintf("HonestDiD failed: %s\n", e$message))
})

# ──────────────────────────────────────────────────────────────────
# 8. WILD CLUSTER BOOTSTRAP
# ──────────────────────────────────────────────────────────────────

cat("\n=== 8. Wild cluster bootstrap ===\n")

tryCatch({
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    library(fwildclusterboot)

    wcb_sample <- panel[(ring_1km | control)]
    wcb_sample[, treated := treated_construction]

    wcb_model <- feols(
      log_price_m2 ~ treated +
        surface + I(surface^2) + rooms + i(prop_type) |
        commune + year_quarter,
      data = wcb_sample,
      cluster = ~commune
    )

    set.seed(2024)
    boot_result <- boottest(
      wcb_model,
      param = "treatedTRUE",
      clustid = "commune",
      B = 999,
      type = "mammen"
    )

    cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
    cat("WCB 95% CI:", boot_result$conf_int, "\n")

    fwrite(data.table(
      method = "Wild Cluster Bootstrap",
      p_value = boot_result$p_val,
      ci_low = boot_result$conf_int[1],
      ci_high = boot_result$conf_int[2]
    ), file.path(DATA_DIR, "wild_cluster_bootstrap.csv"))
  } else {
    cat("fwildclusterboot not available. Skipping.\n")
  }
}, error = function(e) {
  cat(sprintf("WCB failed: %s\nContinuing without.\n", e$message))
})

cat("\n=== ROBUSTNESS COMPLETE ===\n")
