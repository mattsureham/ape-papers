## ============================================================================
## 04_robustness.R — Robustness checks for apep_1126
## Prohibition-state sample only (drop MI, WA, VT, ME)
## ============================================================================

source("00_packages.R")

DATA <- "../data"

## ---- Load panel (prohibition states) ----
panel <- as.data.table(read_parquet(file.path(DATA, "county_quarter_panel.parquet")))
drop_states <- c("MI", "WA", "VT", "ME")
panel <- panel[!(state_abb %in% drop_states)]
panel_hc <- panel[high_coverage == TRUE & !is.na(drug_rate)]
panel_hc[, state_yq := paste0(state_abb, "_", year_quarter)]
panel_hc[, border := as.numeric(is_border)]
panel_hc[, border_post   := border * post_legal]
panel_hc[, border_covid  := border * covid_closed]
panel_hc[, border_reopen := border * post_reopen]

prohib_states <- sort(unique(panel_hc$state_abb))
cat(sprintf("Prohibition states: %s\n", paste(prohib_states, collapse = ", ")))
cat(sprintf("Panel: %s obs, %d counties (%d border)\n",
            format(nrow(panel_hc), big.mark = ","),
            uniqueN(panel_hc$fips),
            uniqueN(panel_hc[is_border == TRUE, fips])))

## ---- 1. Fake-date placebos ----
cat("\n=== Fake-Date Placebos ===\n")

fake_dates <- c(2015.75, 2016.75)  # Oct 2015, Oct 2016
panel_pre <- panel_hc[regime == "pre"]

fake_results <- list()
for (fd in fake_dates) {
  panel_pre[, fake_post := as.integer(year_q >= fd)]
  panel_pre[, fake_border_post := border * fake_post]

  fake_spec <- feols(
    drug_rate ~ fake_border_post | fips + state_yq,
    data = panel_pre,
    cluster = ~state_abb
  )

  fake_coef <- coef(fake_spec)["fake_border_post"]
  fake_se   <- se(fake_spec)["fake_border_post"]
  fake_pval <- pvalue(fake_spec)["fake_border_post"]

  fake_results[[as.character(fd)]] <- list(
    fake_date = fd,
    estimate  = unname(fake_coef),
    se        = unname(fake_se),
    pval      = unname(fake_pval)
  )
  cat(sprintf("  Fake date %.2f: beta = %.3f (SE: %.3f, p = %.3f)\n",
              fd, fake_coef, fake_se, fake_pval))
}

## ---- 2. Constant-coverage subsample ----
cat("\n=== Constant-Coverage Subsample ===\n")

full_coverage <- panel_hc[, .(n_q = .N), by = fips]
max_q <- max(full_coverage$n_q)
always_report <- full_coverage[n_q == max_q, fips]
cat(sprintf("Counties reporting in all %d quarters: %d (%d border)\n",
            max_q, length(always_report),
            sum(always_report %in% panel_hc[is_border == TRUE, unique(fips)])))

panel_const <- panel_hc[fips %in% always_report]

spec_const <- feols(
  drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_const,
  cluster = ~state_abb
)
cat("Constant-coverage specification (unweighted):\n")
summary(spec_const)

## ---- 3. Leave-One-State-Out (LOSO) ----
cat("\n=== Leave-One-State-Out ===\n")

loso_results <- list()
for (drop_st in prohib_states) {
  sub <- panel_hc[state_abb != drop_st]

  ## Need at least 2 states for clustering
  n_clusters <- uniqueN(sub$state_abb)
  if (n_clusters < 2) {
    cat(sprintf("  Drop %s: skipped (only %d cluster)\n", drop_st, n_clusters))
    next
  }

  tryCatch({
    loso_spec <- feols(
      drug_rate ~ border_post + border_covid + border_reopen |
        fips + state_yq,
      data = sub,
      cluster = ~state_abb
    )
    loso_results[[drop_st]] <- list(
      dropped     = drop_st,
      beta_post   = unname(coef(loso_spec)["border_post"]),
      se_post     = unname(se(loso_spec)["border_post"]),
      pval_post   = unname(pvalue(loso_spec)["border_post"]),
      beta_covid  = unname(coef(loso_spec)["border_covid"]),
      se_covid    = unname(se(loso_spec)["border_covid"]),
      beta_reopen = unname(coef(loso_spec)["border_reopen"]),
      se_reopen   = unname(se(loso_spec)["border_reopen"]),
      n_obs       = nobs(loso_spec),
      n_counties  = uniqueN(sub$fips),
      n_border    = uniqueN(sub[is_border == TRUE, fips])
    )
    cat(sprintf("  Drop %s: beta_post = %7.3f (SE: %.3f, p = %.3f), N = %d, border = %d\n",
                drop_st,
                loso_results[[drop_st]]$beta_post,
                loso_results[[drop_st]]$se_post,
                loso_results[[drop_st]]$pval_post,
                loso_results[[drop_st]]$n_obs,
                loso_results[[drop_st]]$n_border))
  }, error = function(e) {
    cat(sprintf("  Drop %s: ERROR — %s\n", drop_st, e$message))
  })
}

## ---- 4. High-exposure border counties ----
cat("\n=== Alternative: High-Exposure Border ===\n")

border_exposure <- unique(panel_hc[is_border == TRUE, .(fips, crossing_exposure)])
med_exposure <- median(border_exposure$crossing_exposure)
panel_hc[, high_exposure := as.numeric(is_border & crossing_exposure > med_exposure)]
panel_hc[, highexp_post   := high_exposure * post_legal]
panel_hc[, highexp_covid  := high_exposure * covid_closed]
panel_hc[, highexp_reopen := high_exposure * post_reopen]

spec_high <- feols(
  drug_rate ~ highexp_post + highexp_covid + highexp_reopen |
    fips + state_yq,
  data = panel_hc,
  cluster = ~state_abb
)
cat("High-exposure border specification (unweighted):\n")
summary(spec_high)

## ---- 5. Log outcome ----
cat("\n=== Log Outcome ===\n")
panel_hc[, log_drug_rate := log(drug_rate + 1)]

spec_log <- feols(
  log_drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_hc,
  cluster = ~state_abb
)
cat("Log outcome specification (unweighted):\n")
summary(spec_log)

## ---- 6. Save all robustness results ----
robustness <- list(
  fake_date_placebos = fake_results,
  constant_coverage = list(
    n_counties = length(always_report),
    n_border   = sum(always_report %in% panel_hc[is_border == TRUE, unique(fips)]),
    beta_post  = unname(coef(spec_const)["border_post"]),
    se_post    = unname(se(spec_const)["border_post"]),
    pval_post  = unname(pvalue(spec_const)["border_post"]),
    beta_covid = unname(coef(spec_const)["border_covid"]),
    se_covid   = unname(se(spec_const)["border_covid"]),
    beta_reopen = unname(coef(spec_const)["border_reopen"]),
    se_reopen   = unname(se(spec_const)["border_reopen"])
  ),
  loso = loso_results,
  high_exposure = list(
    beta_post  = unname(coef(spec_high)["highexp_post"]),
    se_post    = unname(se(spec_high)["highexp_post"]),
    beta_covid = unname(coef(spec_high)["highexp_covid"]),
    se_covid   = unname(se(spec_high)["highexp_covid"])
  ),
  log_outcome = list(
    beta_post  = unname(coef(spec_log)["border_post"]),
    se_post    = unname(se(spec_log)["border_post"]),
    beta_covid = unname(coef(spec_log)["border_covid"]),
    se_covid   = unname(se(spec_log)["border_covid"])
  )
)

jsonlite::write_json(robustness, file.path(DATA, "robustness_results.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Robustness checks complete ===\n")
