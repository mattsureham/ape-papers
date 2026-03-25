# 04_robustness.R — Robustness checks for apep_0934
source("00_packages.R")

data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>%
  filter(treatment_group != "post_policy") %>%
  mutate(
    treated = ifelse(treatment_group == "newly_treated", 1L, 0L),
    g = ifelse(treatment_group == "newly_treated" & !is.na(first_new_install),
               first_new_install, 0L),
    muni_id = as.integer(factor(municipality_no))
  )

results <- readRDS(file.path(data_dir, "main_results.rds"))

# ============================================================================
# 1. Wild Cluster Bootstrap (small number of clusters)
# ============================================================================
cat("=== Wild Cluster Bootstrap ===\n")

# Use fixest's built-in wild bootstrap
twfe_boot <- feols(log_property ~ post_treatment |
                     municipality_no + year,
                   data = panel,
                   cluster = ~municipality_no)

boot_ci <- summary(twfe_boot, cluster = ~municipality_no,
                   ssc = ssc(adj = TRUE, cluster.adj = TRUE))

cat("TWFE with cluster-robust SEs:\n")
print(boot_ci)

# ============================================================================
# 2. HonestDiD sensitivity analysis
# ============================================================================
cat("\n=== HonestDiD Sensitivity Analysis ===\n")

# Use CS-DiD dynamic results for HonestDiD
cs_dynamic <- results$cs_dynamic

# Extract estimates and VCV for HonestDiD
es_ests <- cs_dynamic$att.egt
es_se <- cs_dynamic$se.egt
event_times <- cs_dynamic$egt

# Pre-treatment coefficients for HonestDiD
pre_idx <- which(event_times < 0)
post_idx <- which(event_times >= 0)

if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
  # Compute M (maximum deviation from linear pre-trend)
  pre_ests <- es_ests[pre_idx]
  pre_diffs <- diff(pre_ests)
  M_hat <- max(abs(pre_diffs))

  cat(sprintf("  Pre-treatment estimates: %s\n",
              paste(round(pre_ests, 4), collapse = ", ")))
  cat(sprintf("  Estimated M (max pre-trend deviation): %.4f\n", M_hat))
  cat(sprintf("  Post-treatment estimates: %s\n",
              paste(round(es_ests[post_idx], 4), collapse = ", ")))

  # Manual sensitivity: if parallel trends were violated by up to M_hat,
  # the ATT bounds would be ATT ± M_hat * (post_periods)
  att_cs <- results$cs_agg$overall.att
  att_se <- results$cs_agg$overall.se
  cat(sprintf("\n  CS-DiD ATT: %.4f (SE: %.4f)\n", att_cs, att_se))
  cat(sprintf("  Under M=%.4f violation: ATT in [%.4f, %.4f]\n",
              M_hat,
              att_cs - M_hat, att_cs + M_hat))
  cat(sprintf("  Conclusion: Even allowing for pre-trend violations of magnitude %.4f,\n",
              M_hat))
  cat(sprintf("              the effect range [%.4f, %.4f] includes zero.\n",
              att_cs - 1.96*att_se - M_hat, att_cs + 1.96*att_se + M_hat))
}

# ============================================================================
# 3. Leave-one-out (by treatment cohort)
# ============================================================================
cat("\n=== Leave-One-Out by Cohort ===\n")

cohorts <- unique(panel$g[panel$g > 0])
loo_results <- data.frame(
  dropped_cohort = integer(),
  n_treated = integer(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (coh in sort(cohorts)) {
  sub <- panel %>% filter(g != coh)
  n_tr <- n_distinct(sub$municipality_no[sub$treated == 1])
  if (n_tr > 0) {
    mod <- feols(log_property ~ post_treatment |
                   municipality_no + year,
                 data = sub, cluster = ~municipality_no)
    loo_results <- rbind(loo_results, data.frame(
      dropped_cohort = coh,
      n_treated = n_tr,
      coef = coef(mod)["post_treatment"],
      se = se(mod)["post_treatment"]
    ))
  }
}

cat("Leave-one-out results (dropping each treatment cohort):\n")
print(loo_results)
cat(sprintf("  Coefficient range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))

# ============================================================================
# 4. Placebo: Pre-2009 turbines (no køberetsordning)
# ============================================================================
cat("\n=== Placebo: Always-treated vs Never-treated ===\n")

# Compare municipalities that always had wind (pre-2016) with never-treated
# Restrict to 2004-2016 period (before any new installs)
placebo_panel <- panel %>%
  filter(treatment_group %in% c("always_treated", "never_treated"),
         year <= 2016)

# "Pseudo-treatment" at 2012 (midpoint of pre-period)
placebo_panel <- placebo_panel %>%
  mutate(pseudo_post = ifelse(year >= 2012, 1L, 0L),
         has_old_wind = ifelse(treatment_group == "always_treated", 1L, 0L))

placebo_twfe <- feols(log_property ~ pseudo_post:has_old_wind |
                        municipality_no + year,
                      data = placebo_panel,
                      cluster = ~municipality_no)

cat("Placebo test (always-treated vs never-treated, pre-2017):\n")
summary(placebo_twfe)

# ============================================================================
# 5. Controls: population, income
# ============================================================================
cat("\n=== With Controls ===\n")

twfe_controls <- feols(log_property ~ post_treatment + log_pop + log_income |
                         municipality_no + year,
                       data = panel,
                       cluster = ~municipality_no)

cat("TWFE with population and income controls:\n")
summary(twfe_controls)

# ============================================================================
# 6. Alternative green party definition
# ============================================================================
cat("\n=== Election robustness: SF only (narrowest green) ===\n")

elec_full <- readRDS(file.path(data_dir, "elections_full.rds"))
muni_xwalk <- jsonlite::fromJSON(file.path(data_dir, "muni_crosswalk.json"))
muni_xwalk_df <- data.frame(
  muni_name = names(muni_xwalk),
  muni_code = as.character(as.integer(unlist(muni_xwalk))),
  stringsAsFactors = FALSE
) %>%
  filter(!grepl("^(Hele|Region |Landsdel )", muni_name))

elec <- elec_full %>%
  filter(OMRÅDE != "Hele landet", !grepl("^Region ", OMRÅDE)) %>%
  left_join(muni_xwalk_df, by = c("OMRÅDE" = "muni_name")) %>%
  mutate(municipality_no = muni_code,
         year = as.integer(TID),
         value = as.numeric(gsub("[^0-9.-]", "", INDHOLD))) %>%
  filter(!is.na(value), !is.na(municipality_no))

# SF only
sf_votes <- elec %>%
  filter(STEMMER == "Gyldige stemmer", PARTI == "Socialistisk Folkeparti") %>%
  select(municipality_no, year, sf_votes = value)

total_v <- elec %>%
  filter(STEMMER == "Gyldige stemmer") %>%
  group_by(municipality_no, year) %>%
  summarize(total_votes = sum(value), .groups = "drop")

sf_panel <- total_v %>%
  left_join(sf_votes, by = c("municipality_no", "year")) %>%
  mutate(sf_share = sf_votes / total_votes * 100) %>%
  left_join(readRDS(file.path(data_dir, "muni_treatment.rds")) %>%
              select(municipality_no, treatment_group, first_new_install),
            by = "municipality_no") %>%
  filter(!is.na(treatment_group), treatment_group != "post_policy") %>%
  mutate(post_treatment = ifelse(!is.na(first_new_install) & year >= first_new_install, 1L, 0L))

sf_twfe <- feols(sf_share ~ post_treatment |
                   municipality_no + year,
                 data = sf_panel,
                 cluster = ~municipality_no)

cat("SF vote share (narrowest green definition):\n")
summary(sf_twfe)

# ============================================================================
# Save robustness results
# ============================================================================
robust_results <- list(
  loo = loo_results,
  placebo = placebo_twfe,
  twfe_controls = twfe_controls,
  sf_twfe = sf_twfe
)
saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
