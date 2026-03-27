# =============================================================================
# 03_main_analysis.R — Triple-Difference: FTS x HighContam x Post
# =============================================================================
source("00_packages.R")

panel <- read_csv("../data/panel_main.csv", show_col_types = FALSE)
panel_full <- read_csv("../data/panel_full.csv", show_col_types = FALSE)

cat("Panel dimensions:", nrow(panel), "rows,",
    length(unique(panel$state_name)), "states,",
    length(unique(panel$drug_type)), "drug types,",
    length(unique(panel$year)), "years\n")

# =============================================================================
# SPECIFICATION 1: Basic DDD with saturated FE
# =============================================================================
# Y_sdt = beta_1 * (Post_st x HighContam_d) + state_drug FE + drug_year FE + state_year FE + eps
# beta_1 = DDD estimand: differential effect on high-contam vs low-contam drugs

# Create interaction variables for fixest
panel <- panel %>%
  mutate(
    state_drug = paste(state_name, drug_type, sep = "_"),
    drug_year = paste(drug_type, year, sep = "_"),
    state_year = paste(state_name, year, sep = "_"),
    high_contam_f = factor(high_contam)
  )

# Main DDD regression
# post_x_high = Post_st * HighContam_d (the DDD interaction)
# With state*drug, drug*year, and state*year FE

m1 <- feols(death_rate ~ post_x_high |
              state_drug + drug_year + state_year,
            data = panel,
            cluster = ~ state_name)

cat("\n=== MAIN DDD RESULT ===\n")
summary(m1)

# =============================================================================
# SPECIFICATION 2: Separate effects by drug type
# =============================================================================
# Instead of pooling high_contam, estimate effects for each drug type

m2_heroin <- feols(death_rate ~ post_fts |
                     state_name + year,
                   data = filter(panel, drug_type == "Heroin"),
                   cluster = ~ state_name)

m2_cocaine <- feols(death_rate ~ post_fts |
                      state_name + year,
                    data = filter(panel, drug_type == "Cocaine"),
                    cluster = ~ state_name)

m2_methadone <- feols(death_rate ~ post_fts |
                        state_name + year,
                      data = filter(panel, drug_type == "Methadone"),
                      cluster = ~ state_name)

m2_natopi <- feols(death_rate ~ post_fts |
                     state_name + year,
                   data = filter(panel, drug_type == "Natural_opioids"),
                   cluster = ~ state_name)

cat("\n=== DRUG-SPECIFIC EFFECTS ===\n")
cat("Heroin:\n"); print(summary(m2_heroin)$coeftable)
cat("Cocaine:\n"); print(summary(m2_cocaine)$coeftable)
cat("Methadone:\n"); print(summary(m2_methadone)$coeftable)
cat("Natural opioids:\n"); print(summary(m2_natopi)$coeftable)

# =============================================================================
# SPECIFICATION 3: Include synthetic opioids as high-contamination
# =============================================================================
panel_synth <- panel_full %>%
  filter(!is.na(high_contam) | drug_type == "Synthetic_opioids") %>%
  mutate(
    high_contam = ifelse(drug_type == "Synthetic_opioids", 1L, high_contam),
    state_drug = paste(state_name, drug_type, sep = "_"),
    drug_year = paste(drug_type, year, sep = "_"),
    state_year = paste(state_name, year, sep = "_"),
    fts_year = ifelse(is.na(fts_year), 9999L, fts_year),
    post_fts = as.integer(year >= fts_year),
    post_x_high = post_fts * high_contam
  )

m3 <- feols(death_rate ~ post_x_high |
              state_drug + drug_year + state_year,
            data = panel_synth,
            cluster = ~ state_name)

cat("\n=== DDD WITH SYNTHETIC OPIOIDS AS HIGH-CONTAM ===\n")
summary(m3)

# =============================================================================
# SPECIFICATION 4: Event study (leads and lags)
# =============================================================================
# Create event-time indicators for the DDD
panel_es <- panel %>%
  filter(fts_year < 9999) %>%
  mutate(
    rel_year = year - fts_year,
    rel_year_capped = pmax(pmin(rel_year, 3), -4),
    # Interaction with high_contam
    es_term = paste0("rel", rel_year_capped, "_high", high_contam)
  )

# Event study: relative year dummies interacted with high_contam
m4 <- feols(death_rate ~ i(rel_year_capped, high_contam_f, ref = -1) |
              state_drug + drug_year + state_year,
            data = panel_es %>% mutate(high_contam_f = factor(high_contam)),
            cluster = ~ state_name)

cat("\n=== EVENT STUDY ===\n")
summary(m4)

# =============================================================================
# Save results
# =============================================================================
# Extract main coefficient and SE for diagnostics
beta_ddd <- coef(m1)["post_x_high"]
se_ddd <- se(m1)["post_x_high"]

# Compute SD(Y) for SDE calculation
sd_y_high <- sd(panel$death_rate[panel$high_contam == 1], na.rm = TRUE)
sd_y_all <- sd(panel$death_rate, na.rm = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat("DDD coefficient:", round(beta_ddd, 3), "\n")
cat("DDD SE:", round(se_ddd, 3), "\n")
cat("SD(Y) high-contam:", round(sd_y_high, 3), "\n")
cat("SD(Y) all:", round(sd_y_all, 3), "\n")
cat("SDE (beta/SD_Y_all):", round(beta_ddd / sd_y_all, 4), "\n")

# Save models for table generation
save(m1, m2_heroin, m2_cocaine, m2_methadone, m2_natopi, m3, m4,
     file = "../data/models.RData")

# Diagnostics JSON
n_treated <- length(unique(panel$state_name[panel$fts_year < 9999]))
# Median pre-periods across treated cohorts (staggered design)
treated_cohorts <- panel %>%
  filter(fts_year < 9999) %>%
  distinct(state_name, fts_year) %>%
  mutate(n_pre_state = fts_year - 2015)
n_pre <- as.integer(median(treated_cohorts$n_pre_state))
n_obs <- nrow(panel)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    ddd_beta = round(beta_ddd, 4),
    ddd_se = round(se_ddd, 4),
    sd_y = round(sd_y_all, 4)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

message("Main analysis complete. Models saved.")
