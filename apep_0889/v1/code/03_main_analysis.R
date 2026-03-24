# 03_main_analysis.R — Staggered DiD: USPS establishment losses → voter turnout
# APEP-0889: Slower Mail, Fewer Voters

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Panel: %d obs, %d counties, years: %s\n",
            nrow(panel), uniqueN(panel$fips),
            paste(sort(unique(panel$year)), collapse=", ")))

# ============================================================================
# 1. Balance the panel (keep only counties observed in all 7 election years)
# ============================================================================
county_counts <- panel[, .N, by = fips]
balanced_fips <- county_counts[N == 7, fips]
bp <- panel[fips %in% balanced_fips]
cat(sprintf("Balanced panel: %d counties, %d obs\n", length(balanced_fips), nrow(bp)))

# Verify treatment cohort distribution in balanced panel
cat("Treatment cohorts (balanced):\n")
print(bp[year == 2016, .N, by = first_treat])

# ============================================================================
# 2. Callaway-Sant'Anna staggered DiD
# ============================================================================
cat("\n=== Callaway-Sant'Anna Estimation ===\n")

# Primary outcome: log total votes
# Recode first_treat for the `did` package (0 = never-treated)
bp[, first_treat_cs := first_treat]

# Ensure the panel is complete and sorted
setorder(bp, fips, year)

# CS-DiD: log(total_votes)
cs_log <- att_gt(
  yname = "log_votes",
  tname = "year",
  idname = "fips",
  gname = "first_treat_cs",
  data = as.data.frame(bp[!is.na(log_votes)]),
  control_group = "nevertreated",
  est_method = "dr",  # Doubly robust
  base_period = "universal"
)

cat("CS-DiD group-time ATTs:\n")
summary(cs_log)

# Aggregate to event study
es_log <- aggte(cs_log, type = "dynamic", min_e = -4, max_e = 3)
cat("\nEvent study (log votes):\n")
summary(es_log)

# Aggregate to overall ATT
att_log <- aggte(cs_log, type = "simple")
cat("\nOverall ATT (log votes):\n")
summary(att_log)

# ============================================================================
# 3. Callaway-Sant'Anna: Turnout rate
# ============================================================================
cat("\n=== CS-DiD: Turnout Rate ===\n")

if ("turnout_rate" %in% names(bp) && sum(!is.na(bp$turnout_rate)) > 1000) {
  cs_turnout <- att_gt(
    yname = "turnout_rate",
    tname = "year",
    idname = "fips",
    gname = "first_treat_cs",
    data = as.data.frame(bp[!is.na(turnout_rate)]),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal"
  )

  es_turnout <- aggte(cs_turnout, type = "dynamic", min_e = -4, max_e = 3)
  att_turnout <- aggte(cs_turnout, type = "simple")
  cat("Event study (turnout rate):\n")
  summary(es_turnout)
  cat("\nOverall ATT (turnout rate):\n")
  summary(att_turnout)
} else {
  cat("Insufficient turnout rate data — skipping.\n")
  cs_turnout <- NULL
}

# ============================================================================
# 4. TWFE as comparison
# ============================================================================
cat("\n=== TWFE Comparison ===\n")

# Standard TWFE
twfe_log <- feols(log_votes ~ post | fips + year,
                   data = bp, cluster = ~state_fips)
cat("TWFE (log votes):\n")
print(summary(twfe_log))

# TWFE with continuous treatment intensity
bp[, post_intensity := fifelse(year >= first_treat & first_treat > 0,
                                loss_by_2018, 0)]
twfe_intensity <- feols(log_votes ~ post_intensity | fips + year,
                         data = bp, cluster = ~state_fips)
cat("\nTWFE with treatment intensity:\n")
print(summary(twfe_intensity))

# Sun-Abraham event study (robust to heterogeneous effects)
bp[, cohort_sa := fifelse(first_treat == 0, 10000L, first_treat)]  # sunab needs large value for never-treated
sa_log <- feols(log_votes ~ sunab(cohort_sa, year) | fips + year,
                 data = bp, cluster = ~state_fips)
cat("\nSun-Abraham event study:\n")
print(summary(sa_log))

# ============================================================================
# 5. Continuous treatment: baseline USPS density × post
# ============================================================================
cat("\n=== Continuous Treatment: Baseline USPS Density ===\n")

if ("estabs_per_10k" %in% names(bp)) {
  # Shift-share: baseline postal density × national RAOI policy
  bp[, post_2016 := as.integer(year >= 2016)]
  bp[estabs_per_10k > quantile(estabs_per_10k, 0.99, na.rm = TRUE),
     estabs_per_10k := quantile(estabs_per_10k, 0.99, na.rm = TRUE)]

  density_did <- feols(log_votes ~ estabs_per_10k:post_2016 | fips + year,
                        data = bp[!is.na(estabs_per_10k)],
                        cluster = ~state_fips)
  cat("Density × Post DiD:\n")
  print(summary(density_did))
}

# ============================================================================
# 6. Cross-sectional mechanism test: mail ballot share (2024 only)
# ============================================================================
cat("\n=== Mechanism: Mail Ballot Share (2024 cross-section) ===\n")

mail_2024 <- bp[year == 2024 & has_mode_data == TRUE & !is.na(mail_share)]
cat(sprintf("2024 counties with mail data: %d (treated: %d)\n",
            nrow(mail_2024), sum(mail_2024$treated)))

if (nrow(mail_2024) > 50) {
  mail_ols <- feols(mail_share ~ treated + log(pop_2015) + income_2015 + pct_white_2015,
                     data = mail_2024[!is.na(pop_2015)])
  cat("Mail share ~ treated (2024 cross-section):\n")
  print(summary(mail_ols))

  mail_intensity <- feols(mail_share ~ loss_by_2018 + log(pop_2015) + income_2015 + pct_white_2015,
                           data = mail_2024[!is.na(pop_2015)])
  cat("\nMail share ~ treatment intensity:\n")
  print(summary(mail_intensity))
}

# ============================================================================
# 7. Save estimation objects
# ============================================================================
save(cs_log, es_log, att_log,
     cs_turnout, twfe_log, twfe_intensity, sa_log,
     file = file.path(data_dir, "estimation_results.RData"))

cat("\n=== Main Analysis Complete ===\n")
cat(sprintf("CS-DiD ATT (log votes): %.4f (SE: %.4f)\n",
            att_log$overall.att, att_log$overall.se))
if (!is.null(cs_turnout)) {
  cat(sprintf("CS-DiD ATT (turnout rate): %.4f (SE: %.4f)\n",
              att_turnout$overall.att, att_turnout$overall.se))
}
