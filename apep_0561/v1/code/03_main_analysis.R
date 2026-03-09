## 03_main_analysis.R — Main econometric analysis
## apep_0561: ZRR reclassification and RN voting in France
##
## Estimands:
##   Main DiD: effect of losing ZRR status on FN/RN vote share (losers vs stayers)
##   Symmetric test: effect of gaining ZRR status on FN/RN vote share (gainers vs never)
##   Event study: dynamic treatment effects with parallel trends test
##   Alternative outcomes: turnout, abstention rate

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 0) Load Analysis Samples
# ============================================================
cat("=== Loading analysis samples ===\n")

did_dt <- fread(file.path(data_dir, "did_sample.csv"))
sym_dt <- fread(file.path(data_dir, "sym_sample.csv"))
full_dt <- fread(file.path(data_dir, "full_panel.csv"))
zrr_groups <- fread(file.path(data_dir, "zrr_treatment_groups.csv"))

cat("DiD sample:", nrow(did_dt), "obs,",
    length(unique(did_dt$commune_code)), "communes,",
    length(unique(did_dt$year)), "election years\n")
cat("Symmetric sample:", nrow(sym_dt), "obs,",
    length(unique(sym_dt$commune_code)), "communes\n")
cat("Full panel:", nrow(full_dt), "obs\n")

# Verify panel structure
cat("\nElection years in DiD sample:", paste(sort(unique(did_dt$year)), collapse = ", "), "\n")
cat("Treatment groups in DiD sample:", paste(unique(did_dt$treatment_group), collapse = ", "), "\n")
cat("Treatment groups in symmetric sample:", paste(unique(sym_dt$treatment_group), collapse = ", "), "\n")

# Ensure factor types for fixest
did_dt[, commune_code := as.factor(commune_code)]
did_dt[, year := as.integer(year)]
sym_dt[, commune_code := as.factor(commune_code)]
sym_dt[, year := as.integer(year)]

# Create additional outcome variables
did_dt[, abstention_pct := 100 - turnout_pct]
did_dt[, exprimes_inscrits := exprimes / inscrits * 100]
sym_dt[, abstention_pct := 100 - turnout_pct]
sym_dt[, exprimes_inscrits := exprimes / inscrits * 100]


# ============================================================
# 1) Summary Statistics (Table 1)
# ============================================================
cat("\n=== Table 1: Summary Statistics (Pre-Treatment, 2012) ===\n")

# Use 2012 as the last clean pre-treatment year
# All four groups from the full panel
full_dt[, abstention_pct := 100 - turnout_pct]
full_dt[, exprimes_inscrits := exprimes / inscrits * 100]

pre_2012 <- full_dt[year == 2012 & election_type == "presidential"]

cat("Observations in 2012 by treatment group:\n")
print(table(pre_2012$treatment_group))

# Compute summary statistics by group
summ_vars <- c("fn_rn_pct_exprimes", "turnout_pct", "inscrits", "exprimes_inscrits")
summ_labels <- c("FN/RN Vote Share (%)", "Turnout (%)",
                 "Registered Voters", "Valid Votes/Registered (%)")

summ_list <- list()
for (grp in c("loser", "stayer", "gainer", "never")) {
  sub <- pre_2012[treatment_group == grp]
  row_list <- list()
  for (j in seq_along(summ_vars)) {
    v <- summ_vars[j]
    vals <- sub[[v]]
    vals <- vals[!is.na(vals)]
    row_list[[j]] <- data.table(
      variable = summ_labels[j],
      group = grp,
      mean = mean(vals),
      sd = sd(vals),
      median = median(vals),
      min = min(vals),
      max = max(vals),
      n = length(vals)
    )
  }
  summ_list[[grp]] <- rbindlist(row_list)
}

summ_stats <- rbindlist(summ_list)

# Print summary table
cat("\nPre-treatment (2012) summary statistics:\n")
summ_wide <- dcast(summ_stats, variable ~ group,
                   value.var = c("mean", "sd", "n"),
                   sep = "_")
print(summ_wide)

# Detailed print by variable
for (v in summ_labels) {
  cat("\n", v, ":\n")
  sub <- summ_stats[variable == v]
  for (i in seq_len(nrow(sub))) {
    cat(sprintf("  %-8s: mean = %7.2f, sd = %7.2f, median = %7.2f, n = %d\n",
                sub$group[i], sub$mean[i], sub$sd[i], sub$median[i], sub$n[i]))
  }
}

# Test for balance: loser vs stayer means (t-tests)
cat("\n--- Balance tests (loser vs stayer, 2012) ---\n")
balance_tests <- list()
losers_2012 <- pre_2012[treatment_group == "loser"]
stayers_2012 <- pre_2012[treatment_group == "stayer"]

for (j in seq_along(summ_vars)) {
  v <- summ_vars[j]
  tt <- t.test(losers_2012[[v]], stayers_2012[[v]])
  cat(sprintf("  %-30s: diff = %7.3f, t = %6.3f, p = %.4f\n",
              summ_labels[j],
              tt$estimate[1] - tt$estimate[2],
              tt$statistic, tt$p.value))
  balance_tests[[j]] <- data.table(
    variable = summ_labels[j],
    loser_mean = tt$estimate[1],
    stayer_mean = tt$estimate[2],
    diff = tt$estimate[1] - tt$estimate[2],
    t_stat = as.numeric(tt$statistic),
    p_value = tt$p.value
  )
}
balance_dt <- rbindlist(balance_tests)

# Save summary statistics
fwrite(summ_stats, file.path(data_dir, "summary_stats_2012.csv"))
fwrite(balance_dt, file.path(data_dir, "balance_tests.csv"))
cat("Saved: summary_stats_2012.csv, balance_tests.csv\n")


# ============================================================
# 2) Main DiD Specification
# ============================================================
cat("\n\n=== Main DiD Regressions ===\n")

# --- Model 1: Basic DiD (post = year >= 2022) ---
# Y_ct = alpha_c + gamma_t + delta * (Loser_c x Post_t) + eps_ct
cat("\n--- Model 1: Two-period DiD (Post = 2022) ---\n")
m1 <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
            data = did_dt, cluster = ~commune_code)
cat("\nMain DiD result:\n")
summary(m1)

# Extract key results
m1_coef <- coeftable(m1)
cat(sprintf("\nATT estimate: %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
            m1_coef[1, "Estimate"], m1_coef[1, "Std. Error"],
            m1_coef[1, "t value"], m1_coef[1, "Pr(>|t|)"]))

# --- Model 2: Including 2019 European elections if available ---
# Check if 2019 data is in did_sample via the post_2019 indicator
if ("post_2019" %in% names(did_dt)) {
  cat("\n--- Model 2: Extended post (Post = 2019+, includes transition) ---\n")
  m2 <- feols(fn_rn_pct_exprimes ~ treated:post_2019 | commune_code + year,
              data = did_dt, cluster = ~commune_code)
  summary(m2)
  m2_coef <- coeftable(m2)
  cat(sprintf("\nExtended ATT estimate: %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
              m2_coef[1, "Estimate"], m2_coef[1, "Std. Error"],
              m2_coef[1, "t value"], m2_coef[1, "Pr(>|t|)"]))
} else {
  cat("\nNo post_2019 indicator found; skipping extended post model.\n")
  m2 <- NULL
}

# --- Model 3: Population-weighted DiD ---
cat("\n--- Model 3: Population-weighted DiD ---\n")
m3 <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
            data = did_dt, cluster = ~commune_code,
            weights = ~inscrits)
summary(m3)
m3_coef <- coeftable(m3)
cat(sprintf("\nWeighted ATT estimate: %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
            m3_coef[1, "Estimate"], m3_coef[1, "Std. Error"],
            m3_coef[1, "t value"], m3_coef[1, "Pr(>|t|)"]))

# --- Model 4: Log vote share ---
cat("\n--- Model 4: Log(FN/RN vote share) ---\n")
did_dt[, log_fn_rn := log(fn_rn_pct_exprimes + 1)]
m4 <- feols(log_fn_rn ~ treated:post | commune_code + year,
            data = did_dt, cluster = ~commune_code)
summary(m4)
m4_coef <- coeftable(m4)
cat(sprintf("\nLog ATT estimate: %.4f (SE = %.4f, t = %.3f, p = %.4f)\n",
            m4_coef[1, "Estimate"], m4_coef[1, "Std. Error"],
            m4_coef[1, "t value"], m4_coef[1, "Pr(>|t|)"]))

# Collect main regression results
main_results <- data.table(
  model = c("Baseline DiD",
            if (!is.null(m2)) "Extended Post (2019+)" else NULL,
            "Population-Weighted",
            "Log(Vote Share + 1)"),
  outcome = c("FN/RN % Expressed",
              if (!is.null(m2)) "FN/RN % Expressed" else NULL,
              "FN/RN % Expressed",
              "log(FN/RN % + 1)"),
  coef = c(m1_coef[1, "Estimate"],
           if (!is.null(m2)) m2_coef[1, "Estimate"] else NULL,
           m3_coef[1, "Estimate"],
           m4_coef[1, "Estimate"]),
  se = c(m1_coef[1, "Std. Error"],
         if (!is.null(m2)) m2_coef[1, "Std. Error"] else NULL,
         m3_coef[1, "Std. Error"],
         m4_coef[1, "Std. Error"]),
  t_stat = c(m1_coef[1, "t value"],
             if (!is.null(m2)) m2_coef[1, "t value"] else NULL,
             m3_coef[1, "t value"],
             m4_coef[1, "t value"]),
  p_value = c(m1_coef[1, "Pr(>|t|)"],
              if (!is.null(m2)) m2_coef[1, "Pr(>|t|)"] else NULL,
              m3_coef[1, "Pr(>|t|)"],
              m4_coef[1, "Pr(>|t|)"]),
  n_obs = c(nobs(m1),
            if (!is.null(m2)) nobs(m2) else NULL,
            nobs(m3),
            nobs(m4)),
  n_communes = c(length(unique(did_dt$commune_code)),
                 if (!is.null(m2)) length(unique(did_dt$commune_code)) else NULL,
                 length(unique(did_dt$commune_code)),
                 length(unique(did_dt$commune_code))),
  r2_within = c(fitstat(m1, "wr2")[[1]],
                if (!is.null(m2)) fitstat(m2, "wr2")[[1]] else NULL,
                fitstat(m3, "wr2")[[1]],
                fitstat(m4, "wr2")[[1]]),
  weighted = c("No", if (!is.null(m2)) "No" else NULL, "Yes", "No")
)

fwrite(main_results, file.path(data_dir, "main_did_results.csv"))
cat("\nSaved: main_did_results.csv\n")

# Print summary table
cat("\n=== Main Results Summary ===\n")
print(main_results[, .(model, coef = round(coef, 3), se = round(se, 3),
                        t_stat = round(t_stat, 3), p_value = round(p_value, 4),
                        n_obs, weighted)])


# ============================================================
# 3) Event Study
# ============================================================
cat("\n\n=== Event Study ===\n")

# Create year factor with 2012 as omitted base year (last clean pre-treatment)
# This shows 2002, 2007 as pre-treatment relative to 2012;
# 2017 as potential anticipation/partial-treatment; 2022 as post-full-effect.
election_years <- sort(unique(did_dt$year))
cat("Election years:", paste(election_years, collapse = ", "), "\n")
cat("Base year (omitted): 2012\n")

# Interaction of treated with year dummies (fixest i() syntax)
es_model <- feols(fn_rn_pct_exprimes ~ i(year, treated, ref = 2012) |
                    commune_code + year,
                  data = did_dt, cluster = ~commune_code)

cat("\nEvent study coefficients:\n")
summary(es_model)

# Extract event study coefficients
es_coefs <- coeftable(es_model)
es_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(es_coefs))),
  coef = es_coefs[, "Estimate"],
  se = es_coefs[, "Std. Error"],
  t_stat = es_coefs[, "t value"],
  p_value = es_coefs[, "Pr(>|t|)"]
)

# Add the base year (2012) with zero coefficient
es_dt <- rbind(es_dt,
               data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(es_dt, year)

# Compute 95% confidence intervals
es_dt[, ci_lower := coef - 1.96 * se]
es_dt[, ci_upper := coef + 1.96 * se]

cat("\nEvent study estimates:\n")
print(es_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3),
                p_value = round(p_value, 4))])

# Parallel trends test: joint F-test of pre-treatment coefficients
# With ref=2012, pre-treatment coefficients are 2002 and 2007
pre_years <- es_dt[year < 2012 & !is.na(t_stat)]$year
if (length(pre_years) > 0) {
  pre_coef_names <- paste0("year::", pre_years, ":treated")
  cat("\nPre-trend coefficient names for Wald test:", paste(pre_coef_names, collapse = ", "), "\n")

  # Joint Wald test of pre-treatment coefficients = 0
  wald_result <- tryCatch({
    wald(es_model, keep = "year::(2002|2007):treated")
  }, error = function(e) {
    cat("Wald test error:", conditionMessage(e), "\n")
    # Manual F-test as fallback
    pre_coefs <- es_dt[year %in% pre_years]
    cat("Manual pre-trend check:\n")
    cat(sprintf("  Max |pre-coef| = %.3f\n", max(abs(pre_coefs$coef))))
    cat(sprintf("  Any pre-coef significant at 5%%: %s\n",
                any(pre_coefs$p_value < 0.05, na.rm = TRUE)))
    NULL
  })

  if (!is.null(wald_result)) {
    cat("\nWald test for pre-trends (H0: all pre-2012 coefficients = 0):\n")
    print(wald_result)
  }
}

# Save event study data
fwrite(es_dt, file.path(data_dir, "event_study_coefs.csv"))
cat("Saved: event_study_coefs.csv\n")

# --- Population-weighted event study ---
cat("\n--- Weighted Event Study ---\n")
es_weighted <- feols(fn_rn_pct_exprimes ~ i(year, treated, ref = 2012) |
                       commune_code + year,
                     data = did_dt, cluster = ~commune_code,
                     weights = ~inscrits)

es_w_coefs <- coeftable(es_weighted)
es_w_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(es_w_coefs))),
  coef = es_w_coefs[, "Estimate"],
  se = es_w_coefs[, "Std. Error"],
  t_stat = es_w_coefs[, "t value"],
  p_value = es_w_coefs[, "Pr(>|t|)"]
)
es_w_dt <- rbind(es_w_dt,
                 data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(es_w_dt, year)
es_w_dt[, ci_lower := coef - 1.96 * se]
es_w_dt[, ci_upper := coef + 1.96 * se]

cat("\nWeighted event study estimates:\n")
print(es_w_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                   ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3))])

fwrite(es_w_dt, file.path(data_dir, "event_study_weighted_coefs.csv"))
cat("Saved: event_study_weighted_coefs.csv\n")


# ============================================================
# 4) Symmetric Test: Gainers vs Never-Treated
# ============================================================
cat("\n\n=== Symmetric Test: Gainers vs Never-Treated ===\n")

# In the symmetric sample, treated=1 for gainers, treated=0 for never
sym_dt[, abstention_pct := 100 - turnout_pct]

# Create post indicator if not present
if (!"post" %in% names(sym_dt)) {
  sym_dt[, post := as.integer(year >= 2022)]
}

cat("Symmetric sample: ", length(unique(sym_dt[treated == 1]$commune_code)), "gainers,",
    length(unique(sym_dt[treated == 0]$commune_code)), "never-treated\n")
cat("Election years:", paste(sort(unique(sym_dt$year)), collapse = ", "), "\n")

# --- Symmetric DiD ---
cat("\n--- Symmetric DiD (Gainers vs Never) ---\n")
sym_m1 <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                data = sym_dt, cluster = ~commune_code)
summary(sym_m1)

sym_coef <- coeftable(sym_m1)
cat(sprintf("\nSymmetric ATT: %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
            sym_coef[1, "Estimate"], sym_coef[1, "Std. Error"],
            sym_coef[1, "t value"], sym_coef[1, "Pr(>|t|)"]))
cat("Expected sign: NEGATIVE (gaining ZRR should reduce RN support)\n")

# --- Symmetric event study ---
cat("\n--- Symmetric Event Study ---\n")
sym_es <- feols(fn_rn_pct_exprimes ~ i(year, treated, ref = 2012) |
                  commune_code + year,
                data = sym_dt, cluster = ~commune_code)
summary(sym_es)

sym_es_coefs <- coeftable(sym_es)
sym_es_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(sym_es_coefs))),
  coef = sym_es_coefs[, "Estimate"],
  se = sym_es_coefs[, "Std. Error"],
  t_stat = sym_es_coefs[, "t value"],
  p_value = sym_es_coefs[, "Pr(>|t|)"]
)
sym_es_dt <- rbind(sym_es_dt,
                   data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(sym_es_dt, year)
sym_es_dt[, ci_lower := coef - 1.96 * se]
sym_es_dt[, ci_upper := coef + 1.96 * se]

cat("\nSymmetric event study estimates:\n")
print(sym_es_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                     ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3))])

# Collect symmetric results
sym_results <- data.table(
  model = "Symmetric DiD (Gainers vs Never)",
  outcome = "FN/RN % Expressed",
  coef = sym_coef[1, "Estimate"],
  se = sym_coef[1, "Std. Error"],
  t_stat = sym_coef[1, "t value"],
  p_value = sym_coef[1, "Pr(>|t|)"],
  n_obs = nobs(sym_m1),
  n_communes = length(unique(sym_dt$commune_code)),
  r2_within = fitstat(sym_m1, "wr2")[[1]],
  weighted = "No"
)

fwrite(sym_results, file.path(data_dir, "symmetric_did_results.csv"))
fwrite(sym_es_dt, file.path(data_dir, "symmetric_event_study_coefs.csv"))
cat("Saved: symmetric_did_results.csv, symmetric_event_study_coefs.csv\n")


# ============================================================
# 5) Alternative Outcomes
# ============================================================
cat("\n\n=== Alternative Outcomes ===\n")

# --- 5a) Turnout ---
cat("\n--- Turnout as outcome ---\n")
m_turnout <- feols(turnout_pct ~ treated:post | commune_code + year,
                   data = did_dt, cluster = ~commune_code)
summary(m_turnout)
turn_coef <- coeftable(m_turnout)
cat(sprintf("\nTurnout ATT: %.3f pp (SE = %.3f, p = %.4f)\n",
            turn_coef[1, "Estimate"], turn_coef[1, "Std. Error"],
            turn_coef[1, "Pr(>|t|)"]))

# Turnout event study
es_turnout <- feols(turnout_pct ~ i(year, treated, ref = 2012) |
                      commune_code + year,
                    data = did_dt, cluster = ~commune_code)
es_turn_coefs <- coeftable(es_turnout)
es_turn_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(es_turn_coefs))),
  coef = es_turn_coefs[, "Estimate"],
  se = es_turn_coefs[, "Std. Error"],
  t_stat = es_turn_coefs[, "t value"],
  p_value = es_turn_coefs[, "Pr(>|t|)"]
)
es_turn_dt <- rbind(es_turn_dt,
                    data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(es_turn_dt, year)
es_turn_dt[, ci_lower := coef - 1.96 * se]
es_turn_dt[, ci_upper := coef + 1.96 * se]

cat("\nTurnout event study:\n")
print(es_turn_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                      ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3))])

# --- 5b) Abstention Rate ---
cat("\n--- Abstention rate as outcome ---\n")
m_abstention <- feols(abstention_pct ~ treated:post | commune_code + year,
                      data = did_dt, cluster = ~commune_code)
summary(m_abstention)
abst_coef <- coeftable(m_abstention)
cat(sprintf("\nAbstention ATT: %.3f pp (SE = %.3f, p = %.4f)\n",
            abst_coef[1, "Estimate"], abst_coef[1, "Std. Error"],
            abst_coef[1, "Pr(>|t|)"]))

# Abstention event study
es_abstention <- feols(abstention_pct ~ i(year, treated, ref = 2012) |
                         commune_code + year,
                       data = did_dt, cluster = ~commune_code)
es_abst_coefs <- coeftable(es_abstention)
es_abst_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(es_abst_coefs))),
  coef = es_abst_coefs[, "Estimate"],
  se = es_abst_coefs[, "Std. Error"],
  t_stat = es_abst_coefs[, "t value"],
  p_value = es_abst_coefs[, "Pr(>|t|)"]
)
es_abst_dt <- rbind(es_abst_dt,
                    data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(es_abst_dt, year)
es_abst_dt[, ci_lower := coef - 1.96 * se]
es_abst_dt[, ci_upper := coef + 1.96 * se]

cat("\nAbstention event study:\n")
print(es_abst_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                      ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3))])

# --- 5c) FN/RN raw votes (extensive margin) ---
cat("\n--- FN/RN raw vote count as outcome ---\n")
m_votes <- feols(fn_rn_voix ~ treated:post | commune_code + year,
                 data = did_dt, cluster = ~commune_code)
summary(m_votes)
votes_coef <- coeftable(m_votes)
cat(sprintf("\nFN/RN votes ATT: %.3f (SE = %.3f, p = %.4f)\n",
            votes_coef[1, "Estimate"], votes_coef[1, "Std. Error"],
            votes_coef[1, "Pr(>|t|)"]))

# --- 5d) Denominator outcomes (registered voters, valid votes, turnout count) ---
# Test whether ZRR loss changed the composition of the electorate (denominator effects)
cat("\n--- Denominator outcomes: inscrits (registered voters) ---\n")
m_inscrits <- feols(inscrits ~ treated:post | commune_code + year,
                    data = did_dt, cluster = ~commune_code)
summary(m_inscrits)
inscrits_coef <- coeftable(m_inscrits)
cat(sprintf("\nInscrits ATT: %.3f (SE = %.3f, p = %.4f)\n",
            inscrits_coef[1, "Estimate"], inscrits_coef[1, "Std. Error"],
            inscrits_coef[1, "Pr(>|t|)"]))

cat("\n--- Denominator outcomes: exprimes (valid votes cast) ---\n")
m_exprimes <- feols(exprimes ~ treated:post | commune_code + year,
                    data = did_dt, cluster = ~commune_code)
summary(m_exprimes)
exprimes_coef <- coeftable(m_exprimes)
cat(sprintf("\nExprimes ATT: %.3f (SE = %.3f, p = %.4f)\n",
            exprimes_coef[1, "Estimate"], exprimes_coef[1, "Std. Error"],
            exprimes_coef[1, "Pr(>|t|)"]))

cat("\n--- Denominator outcomes: votants (number who voted) ---\n")
m_votants <- feols(votants ~ treated:post | commune_code + year,
                   data = did_dt, cluster = ~commune_code)
summary(m_votants)
votants_coef <- coeftable(m_votants)
cat(sprintf("\nVotants ATT: %.3f (SE = %.3f, p = %.4f)\n",
            votants_coef[1, "Estimate"], votants_coef[1, "Std. Error"],
            votants_coef[1, "Pr(>|t|)"]))

# Event study for inscrits (base year = 2012)
cat("\n--- Event study: inscrits ---\n")
es_inscrits <- feols(inscrits ~ i(year, treated, ref = 2012) |
                       commune_code + year,
                     data = did_dt, cluster = ~commune_code)
es_insc_coefs <- coeftable(es_inscrits)
es_insc_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(es_insc_coefs))),
  coef = es_insc_coefs[, "Estimate"],
  se = es_insc_coefs[, "Std. Error"],
  t_stat = es_insc_coefs[, "t value"],
  p_value = es_insc_coefs[, "Pr(>|t|)"]
)
es_insc_dt <- rbind(es_insc_dt,
                    data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(es_insc_dt, year)
es_insc_dt[, ci_lower := coef - 1.96 * se]
es_insc_dt[, ci_upper := coef + 1.96 * se]

cat("\nInscrits event study:\n")
print(es_insc_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                      ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3))])

# Event study for exprimes (base year = 2012)
cat("\n--- Event study: exprimes ---\n")
es_exprimes <- feols(exprimes ~ i(year, treated, ref = 2012) |
                       commune_code + year,
                     data = did_dt, cluster = ~commune_code)
es_expr_coefs <- coeftable(es_exprimes)
es_expr_dt <- data.table(
  year = as.integer(gsub("year::(\\d+):treated", "\\1", rownames(es_expr_coefs))),
  coef = es_expr_coefs[, "Estimate"],
  se = es_expr_coefs[, "Std. Error"],
  t_stat = es_expr_coefs[, "t value"],
  p_value = es_expr_coefs[, "Pr(>|t|)"]
)
es_expr_dt <- rbind(es_expr_dt,
                    data.table(year = 2012, coef = 0, se = 0, t_stat = NA, p_value = NA))
setorder(es_expr_dt, year)
es_expr_dt[, ci_lower := coef - 1.96 * se]
es_expr_dt[, ci_upper := coef + 1.96 * se]

cat("\nExprimes event study:\n")
print(es_expr_dt[, .(year, coef = round(coef, 3), se = round(se, 3),
                      ci_lower = round(ci_lower, 3), ci_upper = round(ci_upper, 3))])

# Collect denominator outcome results
denom_results <- data.table(
  model = c("Inscrits (Registered Voters)", "Exprimes (Valid Votes Cast)",
            "Votants (Number Who Voted)"),
  outcome = c("Inscrits (count)", "Exprimes (count)", "Votants (count)"),
  coef = c(inscrits_coef[1, "Estimate"],
           exprimes_coef[1, "Estimate"],
           votants_coef[1, "Estimate"]),
  se = c(inscrits_coef[1, "Std. Error"],
         exprimes_coef[1, "Std. Error"],
         votants_coef[1, "Std. Error"]),
  t_stat = c(inscrits_coef[1, "t value"],
             exprimes_coef[1, "t value"],
             votants_coef[1, "t value"]),
  p_value = c(inscrits_coef[1, "Pr(>|t|)"],
              exprimes_coef[1, "Pr(>|t|)"],
              votants_coef[1, "Pr(>|t|)"]),
  n_obs = c(nobs(m_inscrits), nobs(m_exprimes), nobs(m_votants)),
  r2_within = c(fitstat(m_inscrits, "wr2")[[1]],
                fitstat(m_exprimes, "wr2")[[1]],
                fitstat(m_votants, "wr2")[[1]])
)

fwrite(denom_results, file.path(data_dir, "denominator_outcomes_results.csv"))
fwrite(es_insc_dt, file.path(data_dir, "event_study_inscrits_coefs.csv"))
fwrite(es_expr_dt, file.path(data_dir, "event_study_exprimes_coefs.csv"))
cat("\nSaved: denominator_outcomes_results.csv, event_study_inscrits_coefs.csv, event_study_exprimes_coefs.csv\n")

# --- Collect all alternative outcome results ---
alt_results <- data.table(
  model = c("Turnout", "Abstention Rate", "FN/RN Raw Votes"),
  outcome = c("Turnout (%)", "Abstention (%)", "FN/RN Votes (count)"),
  coef = c(turn_coef[1, "Estimate"],
           abst_coef[1, "Estimate"],
           votes_coef[1, "Estimate"]),
  se = c(turn_coef[1, "Std. Error"],
         abst_coef[1, "Std. Error"],
         votes_coef[1, "Std. Error"]),
  t_stat = c(turn_coef[1, "t value"],
             abst_coef[1, "t value"],
             votes_coef[1, "t value"]),
  p_value = c(turn_coef[1, "Pr(>|t|)"],
              abst_coef[1, "Pr(>|t|)"],
              votes_coef[1, "Pr(>|t|)"]),
  n_obs = c(nobs(m_turnout), nobs(m_abstention), nobs(m_votes)),
  r2_within = c(fitstat(m_turnout, "wr2")[[1]],
                fitstat(m_abstention, "wr2")[[1]],
                fitstat(m_votes, "wr2")[[1]])
)

fwrite(alt_results, file.path(data_dir, "alternative_outcomes_results.csv"))
fwrite(es_turn_dt, file.path(data_dir, "event_study_turnout_coefs.csv"))
fwrite(es_abst_dt, file.path(data_dir, "event_study_abstention_coefs.csv"))
cat("\nSaved: alternative_outcomes_results.csv, event_study_turnout_coefs.csv, event_study_abstention_coefs.csv\n")


# ============================================================
# 6) Group Means Over Time (for descriptive plots)
# ============================================================
cat("\n\n=== Group Means Over Time ===\n")

# DiD sample group means
did_means <- did_dt[, .(
  fn_rn_mean = mean(fn_rn_pct_exprimes, na.rm = TRUE),
  fn_rn_sd = sd(fn_rn_pct_exprimes, na.rm = TRUE),
  turnout_mean = mean(turnout_pct, na.rm = TRUE),
  turnout_sd = sd(turnout_pct, na.rm = TRUE),
  n = .N
), by = .(year, treatment_group)]
setorder(did_means, treatment_group, year)

cat("\nFN/RN vote share by group and year:\n")
print(dcast(did_means, year ~ treatment_group, value.var = "fn_rn_mean"))

cat("\nTurnout by group and year:\n")
print(dcast(did_means, year ~ treatment_group, value.var = "turnout_mean"))

# Full panel group means (all 4 groups)
full_means <- full_dt[election_type == "presidential", .(
  fn_rn_mean = mean(fn_rn_pct_exprimes, na.rm = TRUE),
  fn_rn_sd = sd(fn_rn_pct_exprimes, na.rm = TRUE),
  turnout_mean = mean(turnout_pct, na.rm = TRUE),
  n = .N
), by = .(year, treatment_group)]
setorder(full_means, treatment_group, year)

cat("\nFull panel FN/RN vote share by group and year:\n")
print(dcast(full_means, year ~ treatment_group, value.var = "fn_rn_mean"))

fwrite(did_means, file.path(data_dir, "group_means_did.csv"))
fwrite(full_means, file.path(data_dir, "group_means_full.csv"))
cat("Saved: group_means_did.csv, group_means_full.csv\n")


# ============================================================
# 7) Final Summary
# ============================================================
cat("\n\n")
cat("================================================================\n")
cat("  RESULTS SUMMARY: ZRR Reclassification and RN Voting\n")
cat("================================================================\n\n")

cat("1. MAIN DiD (Losers vs Stayers):\n")
cat(sprintf("   ATT = %.3f pp (SE = %.3f, p = %.4f)\n",
            m1_coef[1, "Estimate"], m1_coef[1, "Std. Error"], m1_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Interpretation: Communes that lost ZRR status saw a %.1f pp\n",
            abs(m1_coef[1, "Estimate"])))
if (m1_coef[1, "Estimate"] > 0) {
  cat("   INCREASE in FN/RN vote share relative to stayers.\n")
} else {
  cat("   DECREASE in FN/RN vote share relative to stayers.\n")
}

cat("\n2. EVENT STUDY (Parallel Trends, base year = 2012):\n")
pre_coefs <- es_dt[year < 2012 & !is.na(t_stat)]
cat(sprintf("   Pre-treatment coefficients (2002, 2007): max |coef| = %.3f\n",
            max(abs(pre_coefs$coef))))
cat(sprintf("   Any pre-coef significant at 5%%: %s\n",
            any(pre_coefs$p_value < 0.05, na.rm = TRUE)))
post_coef <- es_dt[year == 2022]
cat(sprintf("   Post-treatment (2022): coef = %.3f (CI: [%.3f, %.3f])\n",
            post_coef$coef, post_coef$ci_lower, post_coef$ci_upper))

cat("\n3. SYMMETRIC TEST (Gainers vs Never):\n")
cat(sprintf("   ATT = %.3f pp (SE = %.3f, p = %.4f)\n",
            sym_coef[1, "Estimate"], sym_coef[1, "Std. Error"], sym_coef[1, "Pr(>|t|)"]))
if (sign(sym_coef[1, "Estimate"]) != sign(m1_coef[1, "Estimate"])) {
  cat("   Sign is OPPOSITE to main effect (consistent with theory).\n")
} else {
  cat("   Sign is SAME as main effect (inconsistent with symmetric prediction).\n")
}

cat("\n4. ALTERNATIVE OUTCOMES:\n")
cat(sprintf("   Turnout: ATT = %.3f pp (p = %.4f)\n",
            turn_coef[1, "Estimate"], turn_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Abstention: ATT = %.3f pp (p = %.4f)\n",
            abst_coef[1, "Estimate"], abst_coef[1, "Pr(>|t|)"]))

cat("\n4b. DENOMINATOR OUTCOMES (electorate composition):\n")
cat(sprintf("   Inscrits (registered voters): ATT = %.3f (p = %.4f)\n",
            inscrits_coef[1, "Estimate"], inscrits_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Exprimes (valid votes cast): ATT = %.3f (p = %.4f)\n",
            exprimes_coef[1, "Estimate"], exprimes_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Votants (number who voted): ATT = %.3f (p = %.4f)\n",
            votants_coef[1, "Estimate"], votants_coef[1, "Pr(>|t|)"]))

cat("\n5. SAMPLE SIZES:\n")
cat(sprintf("   DiD: %d communes (%d losers, %d stayers) x %d elections = %d obs\n",
            length(unique(did_dt$commune_code)),
            length(unique(did_dt[treated == 1]$commune_code)),
            length(unique(did_dt[treated == 0]$commune_code)),
            length(unique(did_dt$year)),
            nrow(did_dt)))
cat(sprintf("   Symmetric: %d communes (%d gainers, %d never) x %d elections = %d obs\n",
            length(unique(sym_dt$commune_code)),
            length(unique(sym_dt[treated == 1]$commune_code)),
            length(unique(sym_dt[treated == 0]$commune_code)),
            length(unique(sym_dt$year)),
            nrow(sym_dt)))

cat("\n=== Output files saved to ../data/ ===\n")
cat("  summary_stats_2012.csv            — Table 1 summary statistics\n")
cat("  balance_tests.csv                 — Balance tests (loser vs stayer)\n")
cat("  main_did_results.csv              — Main DiD regression table\n")
cat("  event_study_coefs.csv             — Event study coefficients (main, base=2012)\n")
cat("  event_study_weighted_coefs.csv    — Event study coefficients (weighted, base=2012)\n")
cat("  symmetric_did_results.csv         — Symmetric DiD results\n")
cat("  symmetric_event_study_coefs.csv   — Symmetric event study coefficients\n")
cat("  alternative_outcomes_results.csv  — Turnout, abstention, raw votes\n")
cat("  event_study_turnout_coefs.csv     — Turnout event study coefficients\n")
cat("  event_study_abstention_coefs.csv  — Abstention event study coefficients\n")
cat("  denominator_outcomes_results.csv  — Denominator outcomes (inscrits, exprimes, votants)\n")
cat("  event_study_inscrits_coefs.csv    — Inscrits event study coefficients\n")
cat("  event_study_exprimes_coefs.csv    — Exprimes event study coefficients\n")
cat("  group_means_did.csv               — Group means over time (DiD sample)\n")
cat("  group_means_full.csv              — Group means over time (full panel)\n")

cat("\n=== 03_main_analysis.R complete ===\n")
