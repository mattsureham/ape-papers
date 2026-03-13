## 04_robustness.R — Robustness checks and placebo tests
## apep_0610: The Marginal Birth

library(data.table)
library(fixest)
library(did)

panel <- fread("data/analysis_panel.csv")

main_outcomes <- c("unmarried_share", "lbw_share", "preterm_share", "teen_share")

# ====================================================================
# 1. TEMPORAL PLACEBO: Assign fake treatment in 2019
# ====================================================================
cat("=== TEMPORAL PLACEBO (fake treatment 2019) ===\n\n")

pre_panel <- panel[year <= 2021]
pre_panel[, first_treat_placebo := 0L]
pre_panel[first_treat > 0, first_treat_placebo := 2019L]
pre_panel[, treated_placebo := as.integer(first_treat_placebo > 0 & year >= first_treat_placebo)]

placebo_results <- list()
for (yvar in main_outcomes) {
  df <- pre_panel[!is.na(get(yvar))]
  fml <- as.formula(paste0(yvar, " ~ treated_placebo | state_id + year"))
  fit <- feols(fml, data = df, cluster = ~state_id)
  placebo_results[[yvar]] <- fit
  cat(sprintf("  %s: Placebo coef = %.4f (SE = %.4f, p = %.3f)\n",
              yvar, coef(fit)[1], se(fit)[1], pvalue(fit)[1]))
}

saveRDS(placebo_results, "data/placebo_results.rds")

# ====================================================================
# 2. DROP TEXAS (pre-Dobbs SB8 exposure since Sept 2021)
# ====================================================================
cat("\n=== ROBUSTNESS: Drop Texas ===\n\n")

panel_notx <- panel[state_abbr != "TX"]

notx_results <- list()
for (yvar in main_outcomes) {
  df <- panel_notx[!is.na(get(yvar))]
  fml <- as.formula(paste0(yvar, " ~ treated | state_id + year"))
  fit <- feols(fml, data = df, cluster = ~state_id)
  notx_results[[yvar]] <- fit
  cat(sprintf("  %s (no TX): Coef = %.4f (SE = %.4f)\n",
              yvar, coef(fit)[1], se(fit)[1]))
}

saveRDS(notx_results, "data/notx_results.rds")

# ====================================================================
# 3. NARROW TREATMENT: Total bans only (drop gestational limits)
# ====================================================================
cat("\n=== ROBUSTNESS: Total bans only ===\n\n")

panel_narrow <- panel[ban_type %in% c("total_ban", "none")]
panel_narrow[, treated_narrow := as.integer(first_treat_narrow > 0 & year >= first_treat_narrow)]

narrow_results <- list()
for (yvar in main_outcomes) {
  df <- panel_narrow[!is.na(get(yvar))]
  fml <- as.formula(paste0(yvar, " ~ treated_narrow | state_id + year"))
  fit <- feols(fml, data = df, cluster = ~state_id)
  narrow_results[[yvar]] <- fit
  cat(sprintf("  %s (total ban only): Coef = %.4f (SE = %.4f)\n",
              yvar, coef(fit)[1], se(fit)[1]))
}

saveRDS(narrow_results, "data/narrow_results.rds")

# ====================================================================
# 4. DROP COVID YEARS (2020-2021)
# ====================================================================
cat("\n=== ROBUSTNESS: Drop COVID years ===\n\n")

panel_nocovid <- panel[!(year %in% c(2020, 2021))]

nocovid_results <- list()
for (yvar in main_outcomes) {
  df <- panel_nocovid[!is.na(get(yvar))]
  fml <- as.formula(paste0(yvar, " ~ treated | state_id + year"))
  fit <- feols(fml, data = df, cluster = ~state_id)
  nocovid_results[[yvar]] <- fit
  cat(sprintf("  %s (no COVID): Coef = %.4f (SE = %.4f)\n",
              yvar, coef(fit)[1], se(fit)[1]))
}

saveRDS(nocovid_results, "data/nocovid_results.rds")

# ====================================================================
# 5. HONESTDID SENSITIVITY (for main outcomes)
# ====================================================================
cat("\n=== HonestDiD Sensitivity Analysis ===\n\n")

library(HonestDiD)

cs_results <- readRDS("data/cs_results.rds")

honest_results <- list()

for (yvar in c("unmarried_share", "lbw_share")) {
  cat(sprintf("HonestDiD: %s\n", yvar))

  tryCatch({
    cs_out <- cs_results[[yvar]]$cs_out
    es <- aggte(cs_out, type = "dynamic")

    pre_idx <- which(es$egt < 0)
    post_idx <- which(es$egt >= 0)

    if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
      betahat <- es$att.egt
      sigma <- es$se.egt^2 * diag(length(es$se.egt))

      honest_out <- createSensitivityResults_relativeMagnitudes(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mbarvec = seq(0, 2, by = 0.5)
      )

      honest_results[[yvar]] <- honest_out
      cat(sprintf("  Mbar=0: [%.4f, %.4f]\n", honest_out$lb[1], honest_out$ub[1]))
      cat(sprintf("  Mbar=1: [%.4f, %.4f]\n", honest_out$lb[3], honest_out$ub[3]))
    } else {
      cat("  Insufficient pre/post periods for HonestDiD\n")
    }
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
  })
}

saveRDS(honest_results, "data/honest_results.rds")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
