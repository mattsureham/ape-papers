## 03_main_analysis.R — Primary DiD and DDD regressions
## apep_0533: Salary History Bans and the Gender Earnings Gap

source("00_packages.R")

df <- fread(file.path(data_dir, "analysis_aggregate.csv"))

cat("=== Main Analysis ===\n")
cat(sprintf("N = %d state-quarters, %d treated states, %d control states\n",
            nrow(df), uniqueN(df[treated == TRUE]$state),
            uniqueN(df[treated == FALSE]$state)))

# ============================================================
# 1. TWFE DiD: Gender earnings ratio (benchmark)
# ============================================================

# 1a. New hire gender earnings ratio
twfe_hir <- feols(log_ratio_hir ~ post | state + period,
                  data = df, cluster = ~state)

# 1b. Continuing worker gender earnings ratio (placebo)
twfe_s <- feols(log_ratio_s ~ post | state + period,
                data = df, cluster = ~state)

# 1c. All workers (beginning-of-quarter)
twfe_beg <- feols(log_ratio_beg ~ post | state + period,
                  data = df, cluster = ~state)

cat("\n--- TWFE Results ---\n")
cat("New Hire Gender Ratio:\n")
print(summary(twfe_hir))
cat("\nContinuing Worker Gender Ratio (placebo):\n")
print(summary(twfe_s))

# ============================================================
# 2. Callaway-Sant'Anna (2021) — Group-Time ATT
# ============================================================

# Prepare data for did package
cs_data <- copy(df)
cs_data[, id := as.integer(factor(state))]
# CS-DiD requires gname = 0 for never-treated
cs_data[, gname := cohort]

# 2a. New hire gender earnings ratio
cat("\n--- CS-DiD: New Hire Gender Earnings Ratio ---\n")
cs_hir <- tryCatch(
  att_gt(yname = "log_ratio_hir",
         tname = "period",
         idname = "id",
         gname = "gname",
         data = as.data.frame(cs_data),
         control_group = "notyettreated",
         est_method = "reg",
         bstrap = TRUE,
         cband = TRUE,
         biters = 1000),
  error = function(e) {
    cat("CS-DiD error:", e$message, "\n")
    NULL
  }
)

# Manual aggregation function (workaround for did 2.3.0 aggte bug)
manual_simple_att <- function(mp) {
  post_idx <- mp$t >= mp$group
  att_post <- mp$att[post_idx]
  se_post <- mp$se[post_idx]
  valid <- !is.na(att_post)
  # Conservative SE: average cell-level SE (NOT divided by sqrt(N_cells))
  # Group-time ATTs share common units, so treating them as independent
  # would dramatically understate uncertainty
  valid_se <- !is.na(se_post[valid])
  se_vals <- se_post[valid][valid_se]
  se_val <- if (length(se_vals) > 0) sqrt(mean(se_vals^2)) else NA_real_
  list(overall.att = mean(att_post[valid]), overall.se = se_val)
}

manual_dynamic_att <- function(mp, min_e = -12, max_e = 12) {
  event_time <- mp$t - mp$group
  dt <- data.table(event_time = event_time, att = mp$att, se = mp$se)
  dt <- dt[!is.na(att) & event_time >= min_e & event_time <= max_e]
  es <- dt[, {
    valid_se <- !is.na(se)
    se_val <- if (sum(valid_se) > 0) sqrt(mean(se[valid_se]^2)) else NA_real_
    list(att = mean(att), se = se_val)
  }, by = event_time]
  es[, ci_lower := att - 1.96 * se]
  es[, ci_upper := att + 1.96 * se]
  setorder(es, event_time)
  es
}

agg_hir <- NULL
es_hir <- NULL
es_hir_data <- NULL
if (!is.null(cs_hir)) {
  agg_hir <- tryCatch(aggte(cs_hir, type = "simple"), error = function(e) NULL)
  if (is.null(agg_hir)) {
    cat("Using manual aggregation for CS-DiD (did 2.3.0 workaround)\n")
    agg_hir <- manual_simple_att(cs_hir)
  }
  cat(sprintf("Simple ATT (new hires): %.4f (SE: %.4f)\n",
              agg_hir$overall.att, agg_hir$overall.se))

  es_hir <- tryCatch(aggte(cs_hir, type = "dynamic", min_e = -12, max_e = 12),
                      error = function(e) NULL)
  if (is.null(es_hir)) {
    es_hir_data <- manual_dynamic_att(cs_hir)
    es_hir_data[, outcome := "New Hires"]
    cat("\nEvent Study (new hires) from manual aggregation:\n")
    print(es_hir_data)
  } else {
    es_hir_data <- data.table(
      event_time = es_hir$egt, att = es_hir$att.egt, se = es_hir$se.egt,
      ci_lower = es_hir$att.egt - 1.96 * es_hir$se.egt,
      ci_upper = es_hir$att.egt + 1.96 * es_hir$se.egt,
      outcome = "New Hires"
    )
  }
}

# 2b. Continuing worker gender earnings ratio (placebo)
cat("\n--- CS-DiD: Continuing Worker Gender Earnings Ratio ---\n")
cs_s <- tryCatch(
  att_gt(yname = "log_ratio_s",
         tname = "period",
         idname = "id",
         gname = "gname",
         data = as.data.frame(cs_data),
         control_group = "notyettreated",
         est_method = "reg",
         bstrap = TRUE,
         cband = TRUE,
         biters = 1000),
  error = function(e) {
    cat("CS-DiD error:", e$message, "\n")
    NULL
  }
)

agg_s <- NULL
es_s <- NULL
es_s_data <- NULL
if (!is.null(cs_s)) {
  agg_s <- tryCatch(aggte(cs_s, type = "simple"), error = function(e) NULL)
  if (is.null(agg_s)) {
    agg_s <- manual_simple_att(cs_s)
  }
  cat(sprintf("Simple ATT (continuing): %.4f (SE: %.4f)\n",
              agg_s$overall.att, agg_s$overall.se))

  es_s <- tryCatch(aggte(cs_s, type = "dynamic", min_e = -12, max_e = 12),
                    error = function(e) NULL)
  if (is.null(es_s)) {
    es_s_data <- manual_dynamic_att(cs_s)
    es_s_data[, outcome := "Continuing Workers"]
  } else {
    es_s_data <- data.table(
      event_time = es_s$egt, att = es_s$att.egt, se = es_s$se.egt,
      ci_lower = es_s$att.egt - 1.96 * es_s$se.egt,
      ci_upper = es_s$att.egt + 1.96 * es_s$se.egt,
      outcome = "Continuing Workers"
    )
  }
}

# ============================================================
# 3. DDD: New Hires vs. Continuing Workers
# ============================================================

# Stack data long: one row per state-quarter-worker_type
ddd_data <- rbindlist(list(
  df[, .(state, period, treated, post, cohort, ban_period,
         log_ratio = log_ratio_hir, worker_type = "new_hire",
         year, qtr, total_emp)],
  df[, .(state, period, treated, post, cohort, ban_period,
         log_ratio = log_ratio_s, worker_type = "continuing",
         year, qtr, total_emp)]
))

ddd_data[, new_hire := as.integer(worker_type == "new_hire")]

# DDD regression
ddd_reg <- feols(log_ratio ~ post * new_hire | state + period + new_hire:period + new_hire:state,
                 data = ddd_data, cluster = ~state)

cat("\n--- DDD: Post x NewHire ---\n")
print(summary(ddd_reg))

# ============================================================
# 4. Male-only placebo
# ============================================================

# Male new hire earnings (should show no/small effect)
twfe_male_hir <- feols(log_earn_m_hir ~ post | state + period,
                       data = df, cluster = ~state)

# Female new hire earnings (should show positive effect)
twfe_female_hir <- feols(log_earn_f_hir ~ post | state + period,
                         data = df, cluster = ~state)

cat("\n--- Male Placebo ---\n")
cat("Male new hire earnings:\n")
print(summary(twfe_male_hir))
cat("\nFemale new hire earnings:\n")
print(summary(twfe_female_hir))

# ============================================================
# 5. Female hire share (composition test)
# ============================================================

twfe_hire_share <- feols(female_hire_share ~ post | state + period,
                         data = df, cluster = ~state)

cat("\n--- Female Hire Share ---\n")
print(summary(twfe_hire_share))

# ============================================================
# Save results for figures and tables
# ============================================================

# Event study data for figures (already computed above)
if (!is.null(es_hir_data)) {
  fwrite(es_hir_data, file.path(data_dir, "event_study_newhires.csv"))
}
if (!is.null(es_s_data)) {
  fwrite(es_s_data, file.path(data_dir, "event_study_continuing.csv"))
}

# Main results for table
results <- data.table(
  model = c("TWFE: New Hire Ratio", "TWFE: Continuing Ratio",
            "TWFE: All Workers Ratio",
            "CS-DiD: New Hire ATT", "CS-DiD: Continuing ATT",
            "DDD: Post x NewHire",
            "Male Placebo (New Hire Earn)", "Female (New Hire Earn)",
            "Female Hire Share"),
  coef = c(coef(twfe_hir)["post"], coef(twfe_s)["post"],
           coef(twfe_beg)["post"],
           if (!is.null(agg_hir)) agg_hir$overall.att else NA,
           if (!is.null(agg_s)) agg_s$overall.att else NA,
           coef(ddd_reg)["post:new_hire"],
           coef(twfe_male_hir)["post"], coef(twfe_female_hir)["post"],
           coef(twfe_hire_share)["post"]),
  se = c(se(twfe_hir)["post"], se(twfe_s)["post"],
         se(twfe_beg)["post"],
         if (!is.null(agg_hir)) agg_hir$overall.se else NA,
         if (!is.null(agg_s)) agg_s$overall.se else NA,
         se(ddd_reg)["post:new_hire"],
         se(twfe_male_hir)["post"], se(twfe_female_hir)["post"],
         se(twfe_hire_share)["post"])
)
results[, stars := fifelse(abs(coef / se) > 2.576, "***",
                  fifelse(abs(coef / se) > 1.96, "**",
                  fifelse(abs(coef / se) > 1.645, "*", "")))]

fwrite(results, file.path(data_dir, "main_results.csv"))

cat("\n=== Main Results Summary ===\n")
print(results)

# Save regression objects for tables
save(twfe_hir, twfe_s, twfe_beg, ddd_reg, twfe_male_hir, twfe_female_hir,
     twfe_hire_share, cs_hir, cs_s,
     file = file.path(data_dir, "regressions.RData"))

cat("\nMain analysis complete.\n")
