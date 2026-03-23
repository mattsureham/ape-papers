# ==============================================================================
# 04_robustness.R — Robustness checks for H-1B dynamics (pre-crisis sample)
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")

# Truncate to pre-crisis period
panel <- panel[yearqtr <= 2007.5]

naics54 <- panel[industry == "54"]

# ==============================================================================
# Robustness 1: Binary treatment (top quartile vs bottom quartile)
# ==============================================================================

cat("=== Robustness 1: Binary Treatment ===\n")

bin_data <- naics54[tech_quartile %in% c("Q1", "Q4")]
bin_data[, treated := as.integer(tech_quartile == "Q4")]

m_bin <- feols(log_emp ~ treated:young:post + treated:post + young:post |
                 county_ind_age + state_quarter + age_quarter,
               data = bin_data, cluster = ~fips_state)
cat("Binary treatment DDD (employment):\n")
print(summary(m_bin))

# ==============================================================================
# Robustness 2: Alternative age groups (35-44 vs 45-54)
# ==============================================================================

cat("\n=== Robustness 2: Alternative Age Groups (35-44 vs 45-54) ===\n")

panel_alt <- panel[industry == "54" & agegrp %in% c("A05", "A06")]
panel_alt[, young := as.integer(agegrp == "A05")]
panel_alt[, county_ind_age := paste(fips_county, industry, agegrp, sep = "_")]

m_alt <- feols(log_emp ~ tech_share:young:post + tech_share:post + young:post |
                 county_ind_age + state_quarter + age_quarter,
               data = panel_alt, cluster = ~fips_state)
cat("Alt age (35-44 vs 45-54):\n")
print(summary(m_alt))

# ==============================================================================
# Robustness 3: Drop top 5 tech hubs
# ==============================================================================

cat("\n=== Robustness 3: Drop Top 5 Tech Hubs ===\n")

tech_hubs <- c("06085", "53033", "48453", "25025", "51059")
no_hubs <- naics54[!(fips_county %in% tech_hubs)]

m_nohub <- feols(log_emp ~ tech_share:young:post + tech_share:post + young:post |
                   county_ind_age + state_quarter + age_quarter,
                 data = no_hubs, cluster = ~fips_state)
cat("Without top 5 tech hubs:\n")
print(summary(m_nohub))

# ==============================================================================
# Robustness 4: Placebo industries (Mining)
# ==============================================================================

cat("\n=== Robustness 4: Placebo Industries ===\n")

for (plac_ind in c("92", "21")) {
  plac_data <- panel[industry == plac_ind & agegrp %in% c("A04", "A06")]
  plac_data[, young := as.integer(agegrp == "A04")]
  plac_data[, county_ind_age := paste(fips_county, industry, agegrp, sep = "_")]

  if (nrow(plac_data) < 500) {
    cat(sprintf("  Skipping NAICS %s: too few obs (%d)\n", plac_ind, nrow(plac_data)))
    next
  }

  m_plac <- feols(log_emp ~ tech_share:young:post + tech_share:post + young:post |
                    county_ind_age + state_quarter + age_quarter,
                  data = plac_data, cluster = ~fips_state)
  ind_label <- ifelse(plac_ind == "92", "Government", "Mining")
  cat(sprintf("  Placebo (%s, NAICS %s):\n", ind_label, plac_ind))
  ct <- coeftable(m_plac)
  triple_row <- grep("tech_share:young:post", rownames(ct))
  if (length(triple_row) > 0) {
    cat(sprintf("    beta=%.4f (se=%.4f, p=%.3f)\n",
                ct[triple_row, 1], ct[triple_row, 2], ct[triple_row, 4]))
  }
}

# ==============================================================================
# Robustness 5: Earnings DDD (binary treatment)
# ==============================================================================

cat("\n=== Robustness 5: Earnings DDD (binary) ===\n")

m_earn_bin <- feols(log_earn ~ treated:young:post + treated:post + young:post |
                      county_ind_age + state_quarter + age_quarter,
                    data = bin_data, cluster = ~fips_state)
cat("Earnings (binary treatment):\n")
print(summary(m_earn_bin))

# ==============================================================================
# Robustness 6: Pre-trend joint test (REVIEWER REQUEST)
# ==============================================================================

cat("\n=== Robustness 6: Pre-Trend Joint Test ===\n")

# Test: are pre-treatment event-study coefficients jointly zero?
# Restrict to pre-period and test TechShare × Young × time interactions
pre_only <- naics54[yearqtr < 2003.75]
pre_only[, et_pre := event_time]

m_pretrend <- feols(log_earn ~ i(et_pre, I(tech_share * young), ref = -1) +
                      i(et_pre, tech_share, ref = -1) |
                      county_ind_age + state_quarter + age_quarter,
                    data = pre_only, cluster = ~fips_state)

# Extract pre-trend coefficients
pt_coefs <- coeftable(m_pretrend)
pt_rows <- grep("tech_share.*young", rownames(pt_coefs))
if (length(pt_rows) > 0) {
  cat("Pre-trend coefficients (earnings, DDD):\n")
  print(pt_coefs[pt_rows, ])
  # Joint F-test
  pt_vals <- pt_coefs[pt_rows, 1]
  pt_ses <- pt_coefs[pt_rows, 2]
  cat(sprintf("\nJoint test: %d pre-period coefficients\n", length(pt_rows)))
  cat(sprintf("Max absolute coefficient: %.4f\n", max(abs(pt_vals))))
}

# Save robustness models
save(m_bin, m_alt, m_nohub, m_earn_bin,
     file = "../data/robustness_models.RData")

cat("\nRobustness checks complete.\n")
