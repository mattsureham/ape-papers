## 03_main_analysis.R — Main DiD estimates
## apep_0575: BRRD Bail-In Risk and Household Deposit Structure

source("00_packages.R")

data_dir <- "../data/"
hh <- fread(paste0(data_dir, "hh_panel.csv"))
nfc <- fread(paste0(data_dir, "nfc_panel.csv"))
full <- fread(paste0(data_dir, "full_panel.csv"))

# Convert dates
hh[, date := as.Date(date)]
nfc[, date := as.Date(date)]

# ===========================================================================
# 1. TWFE BASELINE (for comparison; not the main estimator)
# ===========================================================================

cat("=== TWFE BASELINE ===\n")

# Overnight share — main outcome
twfe_overnight <- feols(share_overnight ~ post_brrd | country + time_period,
                        data = hh, cluster = ~country)

# Agreed maturity share — expected to decrease (mirror of overnight)
twfe_agreed <- feols(share_agreed ~ post_brrd | country + time_period,
                     data = hh, cluster = ~country)

# Redeemable at notice share
twfe_redeemable <- feols(share_redeemable ~ post_brrd | country + time_period,
                         data = hh, cluster = ~country)

# Log total deposits (extensive margin)
twfe_total <- feols(log_total_dep ~ post_brrd | country + time_period,
                    data = hh[!is.na(log_total_dep)], cluster = ~country)

cat("TWFE Results:\n")
cat(sprintf("  Overnight share:    %+.4f (SE: %.4f)\n",
            coef(twfe_overnight)["post_brrd"], se(twfe_overnight)["post_brrd"]))
cat(sprintf("  Agreed share:       %+.4f (SE: %.4f)\n",
            coef(twfe_agreed)["post_brrd"], se(twfe_agreed)["post_brrd"]))
cat(sprintf("  Redeemable share:   %+.4f (SE: %.4f)\n",
            coef(twfe_redeemable)["post_brrd"], se(twfe_redeemable)["post_brrd"]))
cat(sprintf("  Log total deposits: %+.4f (SE: %.4f)\n",
            coef(twfe_total)["post_brrd"], se(twfe_total)["post_brrd"]))

# ===========================================================================
# 2. CALLAWAY-SANT'ANNA (MAIN ESTIMATOR)
# ===========================================================================

cat("\n=== CALLAWAY-SANT'ANNA DiD ===\n")

# Prepare data for did::att_gt()
# Need: numeric group variable (first treatment period as integer)
# Convert transposition_ym to numeric period
hh[, first_treat := as.integer(factor(transposition_ym,
  levels = sort(unique(transposition_ym))))]

# Create a numeric time variable (months since start)
time_periods <- sort(unique(hh$time_period))
hh[, time_id := match(time_period, time_periods)]

# Map cohorts: everyone eventually treated (staggered timing)
# For CS estimator, use month_num as time and first_treat_month as group
hh[, first_treat_month := (as.integer(substr(transposition_ym, 1, 4)) - 2012) * 12 +
     as.integer(substr(transposition_ym, 6, 7))]

# Ensure panel is balanced
hh_balanced <- hh[, .N, by = country]
cat("  Country obs counts:\n")
print(hh_balanced)

# CS-DiD: Overnight share
cs_overnight <- tryCatch({
  att_gt(
    yname = "share_overnight",
    tname = "month_num",
    idname = "country_id",
    gname = "first_treat_month",
    data = as.data.frame(hh),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("  CS-DiD error (overnight):", e$message, "\n")
  cat("  Falling back to Sun-Abraham via fixest::sunab()\n")
  NULL
})

if (!is.null(cs_overnight)) {
  cat("  CS-DiD overnight share:\n")
  cs_agg <- aggte(cs_overnight, type = "simple")
  cat(sprintf("    ATT: %+.4f (SE: %.4f, p: %.4f)\n",
              cs_agg$overall.att, cs_agg$overall.se,
              2 * pnorm(-abs(cs_agg$overall.att / cs_agg$overall.se))))

  # Dynamic effects (event study)
  cs_dynamic <- aggte(cs_overnight, type = "dynamic", min_e = -24, max_e = 24)

  # Save CS results
  cs_dynamic_dt <- data.table(
    rel_time = cs_dynamic$egt,
    att = cs_dynamic$att.egt,
    se = cs_dynamic$se.egt,
    ci_lower = cs_dynamic$att.egt - 1.96 * cs_dynamic$se.egt,
    ci_upper = cs_dynamic$att.egt + 1.96 * cs_dynamic$se.egt
  )
  fwrite(cs_dynamic_dt, paste0(data_dir, "cs_event_study_overnight.csv"))
}

# CS-DiD: Agreed maturity share
cs_agreed <- tryCatch({
  att_gt(
    yname = "share_agreed",
    tname = "month_num",
    idname = "country_id",
    gname = "first_treat_month",
    data = as.data.frame(hh),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("  CS-DiD error (agreed):", e$message, "\n")
  NULL
})

if (!is.null(cs_agreed)) {
  cs_agg_agreed <- aggte(cs_agreed, type = "simple")
  cat(sprintf("  CS-DiD agreed maturity: %+.4f (SE: %.4f)\n",
              cs_agg_agreed$overall.att, cs_agg_agreed$overall.se))

  cs_dynamic_agreed <- aggte(cs_agreed, type = "dynamic", min_e = -24, max_e = 24)
  cs_dynamic_agreed_dt <- data.table(
    rel_time = cs_dynamic_agreed$egt,
    att = cs_dynamic_agreed$att.egt,
    se = cs_dynamic_agreed$se.egt,
    ci_lower = cs_dynamic_agreed$att.egt - 1.96 * cs_dynamic_agreed$se.egt,
    ci_upper = cs_dynamic_agreed$att.egt + 1.96 * cs_dynamic_agreed$se.egt
  )
  fwrite(cs_dynamic_agreed_dt, paste0(data_dir, "cs_event_study_agreed.csv"))
}

# ===========================================================================
# 3. SUN-ABRAHAM (ALTERNATIVE ROBUST ESTIMATOR)
# ===========================================================================

cat("\n=== SUN-Abraham (fixest::sunab) ===\n")

# Sun-Abraham interaction-weighted estimator via fixest
sa_overnight <- feols(share_overnight ~ sunab(first_treat_month, month_num) |
                        country + time_period,
                      data = hh, cluster = ~country)

sa_agreed <- feols(share_agreed ~ sunab(first_treat_month, month_num) |
                     country + time_period,
                   data = hh, cluster = ~country)

# Extract aggregate ATT
sa_ov_sum <- summary(sa_overnight, agg = "ATT")
sa_ag_sum <- summary(sa_agreed, agg = "ATT")
cat("  Sun-Abraham overnight ATT:\n")
print(sa_ov_sum)
cat("  Sun-Abraham agreed ATT:\n")
print(sa_ag_sum)

# Extract aggregate ATT estimates and save to CSV
sa_ov_coef <- coef(sa_ov_sum)
sa_ov_se   <- se(sa_ov_sum)
sa_ov_pv   <- fixest::pvalue(sa_ov_sum)
sa_ag_coef <- coef(sa_ag_sum)
sa_ag_se   <- se(sa_ag_sum)
sa_ag_pv   <- fixest::pvalue(sa_ag_sum)

stars_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

sa_att_dt <- data.table(
  specification = c("Sun-Abraham overnight", "Sun-Abraham agreed"),
  estimate      = c(sa_ov_coef, sa_ag_coef),
  se            = c(sa_ov_se,   sa_ag_se),
  p_value       = c(sa_ov_pv,   sa_ag_pv),
  stars         = c(stars_fn(sa_ov_pv), stars_fn(sa_ag_pv))
)
fwrite(sa_att_dt, paste0(data_dir, "sa_att_results.csv"))
cat("  SA ATT results saved to sa_att_results.csv\n")

# Save SA event study coefficients
sa_es <- data.table(
  rel_time = as.integer(gsub(".*::", "", names(coef(sa_overnight)))),
  att_overnight = coef(sa_overnight),
  se_overnight = se(sa_overnight),
  att_agreed = coef(sa_agreed),
  se_agreed = se(sa_agreed)
)
fwrite(sa_es, paste0(data_dir, "sa_event_study.csv"))

# ===========================================================================
# 4. TRIPLE DIFFERENCE: POST × UNINSURED SHARE
# ===========================================================================

cat("\n=== TRIPLE DIFFERENCE (Treatment Intensity) ===\n")

# Countries with higher pre-BRRD uninsured deposit shares should show
# stronger restructuring toward overnight deposits

td_overnight <- feols(share_overnight ~ post_brrd + post_x_uninsured |
                        country + time_period,
                      data = hh, cluster = ~country)

td_agreed <- feols(share_agreed ~ post_brrd + post_x_uninsured |
                     country + time_period,
                   data = hh, cluster = ~country)

cat(sprintf("  Triple-diff overnight: post_x_uninsured = %+.4f (SE: %.4f)\n",
            coef(td_overnight)["post_x_uninsured"],
            se(td_overnight)["post_x_uninsured"]))
cat(sprintf("  Triple-diff agreed: post_x_uninsured = %+.4f (SE: %.4f)\n",
            coef(td_agreed)["post_x_uninsured"],
            se(td_agreed)["post_x_uninsured"]))

# ===========================================================================
# 5. CORPORATE DEPOSITS PLACEBO
# ===========================================================================

cat("\n=== CORPORATE DEPOSIT PLACEBO ===\n")

# Merge BRRD treatment into NFC panel
nfc <- merge(nfc,
             unique(hh[, .(country, transposition_ym, first_treat_month,
                           uninsured_share, post_brrd)]),
             by = c("country", "post_brrd"), all.x = TRUE)

nfc[, month_num := (year - 2012) * 12 + month]
nfc[, country_id := as.integer(factor(country))]

# TWFE on corporate deposits
placebo_overnight <- feols(share_overnight ~ post_brrd | country + time_period,
                           data = nfc, cluster = ~country)

placebo_agreed <- feols(share_agreed ~ post_brrd | country + time_period,
                        data = nfc, cluster = ~country)

cat(sprintf("  Corporate overnight: %+.4f (SE: %.4f, p: %.4f)\n",
            coef(placebo_overnight)["post_brrd"],
            se(placebo_overnight)["post_brrd"],
            fixest::pvalue(placebo_overnight)["post_brrd"]))
cat(sprintf("  Corporate agreed: %+.4f (SE: %.4f, p: %.4f)\n",
            coef(placebo_agreed)["post_brrd"],
            se(placebo_agreed)["post_brrd"],
            fixest::pvalue(placebo_agreed)["post_brrd"]))

# ===========================================================================
# 6. SECTOR DIFFERENCE-IN-DIFFERENCES
# ===========================================================================

cat("\n=== SECTOR DDD (Household vs Corporate) ===\n")

# Is the effect stronger for households than corporations?
full[, is_household := fifelse(sector == "2250", 1L, 0L)]
full[, post_x_hh := post_brrd * is_household]

sector_did <- feols(share_overnight ~ post_brrd + post_x_hh + is_household |
                      country + time_period,
                    data = full, cluster = ~country)

cat(sprintf("  Sector DDD (post_x_hh): %+.4f (SE: %.4f)\n",
            coef(sector_did)["post_x_hh"], se(sector_did)["post_x_hh"]))

# ===========================================================================
# 7. SAVE ALL RESULTS
# ===========================================================================

cat("\nSaving results...\n")

# Collect all main results into one table
results <- data.table(
  specification = c(
    "TWFE Overnight", "TWFE Agreed", "TWFE Redeemable", "TWFE Log Total",
    "Triple-diff Overnight (post_x_uninsured)",
    "Triple-diff Agreed (post_x_uninsured)",
    "Triple-diff Overnight (post_brrd)",
    "Triple-diff Agreed (post_brrd)",
    "Placebo: Corporate Overnight", "Placebo: Corporate Agreed",
    "Sector DDD (post_x_hh)",
    "Sector DDD (post_brrd)"
  ),
  estimate = c(
    coef(twfe_overnight)["post_brrd"],
    coef(twfe_agreed)["post_brrd"],
    coef(twfe_redeemable)["post_brrd"],
    coef(twfe_total)["post_brrd"],
    coef(td_overnight)["post_x_uninsured"],
    coef(td_agreed)["post_x_uninsured"],
    coef(td_overnight)["post_brrd"],
    coef(td_agreed)["post_brrd"],
    coef(placebo_overnight)["post_brrd"],
    coef(placebo_agreed)["post_brrd"],
    coef(sector_did)["post_x_hh"],
    coef(sector_did)["post_brrd"]
  ),
  se = c(
    se(twfe_overnight)["post_brrd"],
    se(twfe_agreed)["post_brrd"],
    se(twfe_redeemable)["post_brrd"],
    se(twfe_total)["post_brrd"],
    se(td_overnight)["post_x_uninsured"],
    se(td_agreed)["post_x_uninsured"],
    se(td_overnight)["post_brrd"],
    se(td_agreed)["post_brrd"],
    se(placebo_overnight)["post_brrd"],
    se(placebo_agreed)["post_brrd"],
    se(sector_did)["post_x_hh"],
    se(sector_did)["post_brrd"]
  )
)

results[, t_stat := estimate / se]
results[, p_value := 2 * pnorm(-abs(t_stat))]
results[, ci_lower := estimate - 1.96 * se]
results[, ci_upper := estimate + 1.96 * se]
results[, stars := fifelse(p_value < 0.01, "***",
                    fifelse(p_value < 0.05, "**",
                    fifelse(p_value < 0.10, "*", "")))]

fwrite(results, paste0(data_dir, "main_results.csv"))

cat("\n=== MAIN RESULTS SUMMARY ===\n")
print(results[, .(specification, estimate = round(estimate, 4),
                   se = round(se, 4), p_value = round(p_value, 4), stars)])

# Add CS-DiD results if available
if (!is.null(cs_overnight)) {
  cs_results <- data.table(
    specification = c("CS-DiD Overnight (ATT)", "CS-DiD Agreed (ATT)"),
    estimate = c(cs_agg$overall.att,
                 if (!is.null(cs_agreed)) aggte(cs_agreed, type = "simple")$overall.att else NA),
    se = c(cs_agg$overall.se,
           if (!is.null(cs_agreed)) aggte(cs_agreed, type = "simple")$overall.se else NA)
  )
  cs_results[, t_stat := estimate / se]
  cs_results[, p_value := 2 * pnorm(-abs(t_stat))]
  cs_results[, ci_lower := estimate - 1.96 * se]
  cs_results[, ci_upper := estimate + 1.96 * se]
  cs_results[, stars := fifelse(p_value < 0.01, "***",
                          fifelse(p_value < 0.05, "**",
                          fifelse(p_value < 0.10, "*", "")))]
  fwrite(cs_results, paste0(data_dir, "cs_results.csv"))
  cat("\nCS-DiD Results:\n")
  print(cs_results[, .(specification, estimate = round(estimate, 4),
                        se = round(se, 4), p_value = round(p_value, 4))])
}

cat("\nMain analysis complete.\n")
