## 04_robustness.R — Robustness checks and placebo tests
## APEP paper apep_0611: CRA Lookback Cutoff and Midnight Rulemaking

source("00_packages.R")

df <- readRDS("../data/rules_analysis.rds")
results <- readRDS("../data/main_results.rds")

bw_opt <- results$bw_opt

# ═══════════════════════════════════════════════════════════════════════
# 1. BANDWIDTH SENSITIVITY
# ═══════════════════════════════════════════════════════════════════════
cat("\n═══ BANDWIDTH SENSITIVITY ═══\n")

bandwidths <- c(60, 90, 120, 150, 180, 240, 365)
bw_results <- list()

for (bw in bandwidths) {
  df_bw <- df %>% filter(abs(days_from_cutoff) <= bw)

  # Diff-in-disc for significant flag
  fit <- tryCatch({
    feols(
      significant ~ cra_vulnerable * cross_party +
        days_from_cutoff + I(days_from_cutoff * cra_vulnerable) +
        days_from_cutoff:cross_party + I(days_from_cutoff * cra_vulnerable):cross_party,
      data = df_bw,
      vcov = "HC1"
    )
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    coefs <- coef(fit)
    ses <- sqrt(diag(vcov(fit, type = "HC1")))
    # The interaction term is the diff-in-disc
    idx <- grep("cra_vulnerableTRUE:cross_partyTRUE", names(coefs))
    if (length(idx) > 0) {
      bw_results[[as.character(bw)]] <- tibble(
        bandwidth = bw,
        coef = coefs[idx],
        se = ses[idx],
        p_value = 2 * pnorm(-abs(coefs[idx] / ses[idx])),
        n = nrow(df_bw)
      )
      cat(sprintf("  BW ±%d: coef=%.4f (%.4f), p=%.4f, N=%d\n",
                  bw, coefs[idx], ses[idx],
                  2 * pnorm(-abs(coefs[idx] / ses[idx])),
                  nrow(df_bw)))
    }
  }
}

bw_sensitivity <- bind_rows(bw_results)
saveRDS(bw_sensitivity, "../data/bw_sensitivity.rds")

# ═══════════════════════════════════════════════════════════════════════
# 2. PLACEBO CUTOFFS
# ═══════════════════════════════════════════════════════════════════════
# Test for discontinuities at fake cutoffs (±30, ±60, ±90 days from
# true cutoff). No effect expected at placebos.

cat("\n═══ PLACEBO CUTOFFS ═══\n")

placebo_offsets <- c(-90, -60, -30, 30, 60, 90)
placebo_results <- list()

for (offset in placebo_offsets) {
  # Shift the cutoff by 'offset' days
  df_placebo <- df %>%
    filter(cross_party) %>%
    mutate(days_from_placebo = days_from_cutoff - offset)

  rdd_placebo <- tryCatch({
    rdrobust(
      y = as.numeric(df_placebo$significant),
      x = df_placebo$days_from_placebo,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )
  }, error = function(e) NULL)

  if (!is.null(rdd_placebo)) {
    placebo_results[[as.character(offset)]] <- tibble(
      offset = offset,
      coef = rdd_placebo$coef[1],
      se = rdd_placebo$se[3], # Robust SE
      p_value = rdd_placebo$pv[3],
      bw = rdd_placebo$bws[1, 1],
      n_eff = rdd_placebo$N_h[1] + rdd_placebo$N_h[2]
    )
    cat(sprintf("  Placebo %+d days: coef=%.4f, p=%.4f\n",
                offset, rdd_placebo$coef[1], rdd_placebo$pv[3]))
  }
}

# Add the true cutoff result
if (!is.null(results$rdd_sig_cross)) {
  placebo_results[["0"]] <- tibble(
    offset = 0,
    coef = results$rdd_sig_cross$coef[1],
    se = results$rdd_sig_cross$se[3],
    p_value = results$rdd_sig_cross$pv[3],
    bw = results$rdd_sig_cross$bws[1, 1],
    n_eff = results$rdd_sig_cross$N_h[1] + results$rdd_sig_cross$N_h[2]
  )
}

placebo_table <- bind_rows(placebo_results) %>% arrange(offset)
saveRDS(placebo_table, "../data/placebo_results.rds")

cat("\nPlacebo cutoff results:\n")
print(placebo_table)

# ═══════════════════════════════════════════════════════════════════════
# 3. COVARIATE BALANCE AT THE CUTOFF
# ═══════════════════════════════════════════════════════════════════════
# Test whether pre-determined rule characteristics are smooth at cutoff

cat("\n═══ COVARIATE BALANCE ═══\n")

# Test balance on n_cfr_parts (scope of rule) — cross-party
rdd_balance_cfr <- tryCatch({
  sub <- df %>% filter(cross_party, !is.na(n_cfr_parts))
  rdrobust(
    y = sub$n_cfr_parts,
    x = sub$days_from_cutoff,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) NULL)

if (!is.null(rdd_balance_cfr)) {
  cat(sprintf("CFR parts balance (cross): coef=%.3f, p=%.4f\n",
              rdd_balance_cfr$coef[1], rdd_balance_cfr$pv[3]))
}

# ═══════════════════════════════════════════════════════════════════════
# 4. HETEROGENEITY BY AGENCY TYPE
# ═══════════════════════════════════════════════════════════════════════
cat("\n═══ AGENCY HETEROGENEITY ═══\n")

# Top agencies by rule count
top_agencies <- df %>%
  filter(cross_party) %>%
  count(agency_name, sort = TRUE) %>%
  head(10)

cat("Top 10 agencies (cross-party transitions):\n")
print(top_agencies)

# RDD for top 3 agencies
het_results <- list()
for (agency in top_agencies$agency_name[1:min(5, nrow(top_agencies))]) {
  sub <- df %>% filter(cross_party, agency_name == agency)
  if (nrow(sub) > 100) {
    rdd_agency <- tryCatch({
      rdrobust(
        y = as.numeric(sub$significant),
        x = sub$days_from_cutoff,
        c = 0,
        kernel = "triangular",
        bwselect = "mserd"
      )
    }, error = function(e) NULL)

    if (!is.null(rdd_agency)) {
      het_results[[agency]] <- tibble(
        agency = agency,
        coef = rdd_agency$coef[1],
        se = rdd_agency$se[3],
        p_value = rdd_agency$pv[3],
        n_eff = rdd_agency$N_h[1] + rdd_agency$N_h[2]
      )
      cat(sprintf("  %s: coef=%.4f, p=%.4f, N=%d\n",
                  agency, rdd_agency$coef[1], rdd_agency$pv[3],
                  rdd_agency$N_h[1] + rdd_agency$N_h[2]))
    }
  }
}

het_table <- bind_rows(het_results)
saveRDS(het_table, "../data/heterogeneity_results.rds")

# ═══════════════════════════════════════════════════════════════════════
# 5. POLYNOMIAL SENSITIVITY
# ═══════════════════════════════════════════════════════════════════════
cat("\n═══ POLYNOMIAL ORDER SENSITIVITY ═══\n")

poly_results <- list()
for (p in 1:3) {
  rdd_poly <- tryCatch({
    rdrobust(
      y = as.numeric(df$significant[df$cross_party]),
      x = df$days_from_cutoff[df$cross_party],
      c = 0,
      p = p,
      kernel = "triangular",
      bwselect = "mserd"
    )
  }, error = function(e) NULL)

  if (!is.null(rdd_poly)) {
    poly_results[[as.character(p)]] <- tibble(
      poly_order = p,
      coef = rdd_poly$coef[1],
      se = rdd_poly$se[3],
      p_value = rdd_poly$pv[3],
      bw = rdd_poly$bws[1, 1]
    )
    cat(sprintf("  Poly %d: coef=%.4f, p=%.4f, bw=%.0f\n",
                p, rdd_poly$coef[1], rdd_poly$pv[3], rdd_poly$bws[1, 1]))
  }
}

poly_table <- bind_rows(poly_results)
saveRDS(poly_table, "../data/polynomial_results.rds")

# Save all robustness objects
robustness <- list(
  bw_sensitivity = bw_sensitivity,
  placebo = placebo_table,
  heterogeneity = het_table,
  polynomial = poly_table
)
saveRDS(robustness, "../data/robustness_results.rds")

# ═══════════════════════════════════════════════════════════════════════
# 6. BANDWIDTH SENSITIVITY — PAGE LENGTH (diff-in-disc)
# ═══════════════════════════════════════════════════════════════════════
cat("\n═══ BW SENSITIVITY: PAGE LENGTH ═══\n")

bw_pages_results <- list()

for (bw in bandwidths) {
  df_bw <- df %>% filter(abs(days_from_cutoff) <= bw, !is.na(page_length), page_length > 0)

  fit <- tryCatch({
    feols(
      page_length ~ cra_vulnerable * cross_party +
        days_from_cutoff + I(days_from_cutoff * cra_vulnerable) +
        days_from_cutoff:cross_party + I(days_from_cutoff * cra_vulnerable):cross_party,
      data = df_bw,
      vcov = "HC1"
    )
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    coefs <- coef(fit)
    ses <- sqrt(diag(vcov(fit, type = "HC1")))
    idx <- grep("cra_vulnerableTRUE:cross_partyTRUE", names(coefs))
    if (length(idx) > 0) {
      bw_pages_results[[as.character(bw)]] <- tibble(
        bandwidth = bw,
        coef = coefs[idx],
        se = ses[idx],
        p_value = 2 * pnorm(-abs(coefs[idx] / ses[idx])),
        n = nrow(df_bw)
      )
      cat(sprintf("  BW ±%d: coef=%.2f (%.2f), p=%.4f, N=%d\n",
                  bw, coefs[idx], ses[idx],
                  2 * pnorm(-abs(coefs[idx] / ses[idx])),
                  nrow(df_bw)))
    }
  }
}

bw_pages_sensitivity <- bind_rows(bw_pages_results)
saveRDS(bw_pages_sensitivity, "../data/bw_pages_sensitivity.rds")

# ═══════════════════════════════════════════════════════════════════════
# 7. SENSITIVITY: EXCLUDING 2017 AND 2025
# ═══════════════════════════════════════════════════════════════════════
cat("\n═══ SENSITIVITY: EXCLUDING 2017 / 2025 ═══\n")

exclude_results <- list()

for (excl in list(c(2017), c(2025), c(2017, 2025))) {
  label <- paste("Excl.", paste(excl, collapse = "+"))
  df_excl <- df %>%
    filter(!transition_year %in% excl, !is.na(page_length), page_length > 0,
           abs(days_from_cutoff) <= bw_opt)

  fit <- tryCatch({
    feols(
      page_length ~ cra_vulnerable * cross_party +
        days_from_cutoff + I(days_from_cutoff * cra_vulnerable) +
        days_from_cutoff:cross_party + I(days_from_cutoff * cra_vulnerable):cross_party,
      data = df_excl,
      vcov = "HC1"
    )
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    coefs <- coef(fit)
    ses <- sqrt(diag(vcov(fit, type = "HC1")))
    idx <- grep("cra_vulnerableTRUE:cross_partyTRUE", names(coefs))
    if (length(idx) > 0) {
      exclude_results[[label]] <- tibble(
        specification = label,
        coef = coefs[idx],
        se = ses[idx],
        p_value = 2 * pnorm(-abs(coefs[idx] / ses[idx])),
        n = nrow(df_excl)
      )
      cat(sprintf("  %s: coef=%.2f (%.2f), p=%.4f, N=%d\n",
                  label, coefs[idx], ses[idx],
                  2 * pnorm(-abs(coefs[idx] / ses[idx])),
                  nrow(df_excl)))
    }
  }
}

exclude_table <- bind_rows(exclude_results)
saveRDS(exclude_table, "../data/exclude_sensitivity.rds")

# Update robustness object
robustness$bw_pages_sensitivity <- bw_pages_sensitivity
robustness$exclude_sensitivity <- exclude_table
saveRDS(robustness, "../data/robustness_results.rds")

cat("\n04_robustness.R completed successfully.\n")
