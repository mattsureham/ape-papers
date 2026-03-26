# 04_robustness.R — Robustness checks and additional specifications
# Czech EET and Business Dynamics (apep_0989)

source("00_packages.R")

# Reload panel
sbs_ind <- readRDS("../data/eurostat_sbs_na_ind_r2.rds")
sbs_svc <- readRDS("../data/eurostat_sbs_na_1a_se_r2.rds")
sbs_con <- readRDS("../data/eurostat_sbs_na_con_r2.rds")
sbs_trd <- readRDS("../data/eurostat_sbs_na_dt_r2.rds")
sbs_all <- bind_rows(sbs_ind, sbs_svc, sbs_con, sbs_trd)

eet_section_map <- c("I" = 2017, "G" = 2017, "H" = 2018, "M" = 2018, "C" = 2018)

enterprises_2d <- sbs_all %>%
  filter(indic_sb == "V11110", !is.na(values),
         grepl("^[A-Z][0-9]{2}$", nace_r2)) %>%
  mutate(section = substr(nace_r2, 1, 1), year = time) %>%
  select(geo, nace_r2, section, year, n_enterprises = values) %>%
  filter(year >= 2008, year <= 2020)

panel_full <- enterprises_2d %>%
  mutate(
    treatment_year = ifelse(geo == "CZ", eet_section_map[section], NA_real_),
    treated = ifelse(!is.na(treatment_year) & year >= treatment_year, 1, 0),
    cohort_year = ifelse(!is.na(treatment_year), treatment_year, 0),
    unit_id = paste(geo, nace_r2, sep = "_"),
    ln_enterprises = log(n_enterprises)
  )

# Balance panel
unit_counts <- panel_full %>% group_by(unit_id) %>% summarize(n = n())
panel_bal <- panel_full %>%
  filter(unit_id %in% unit_counts$unit_id[unit_counts$n == 13])

# ===================================================================
# R1: CZ vs Slovakia only (most comparable economy)
# ===================================================================
cat("=== R1: CZ vs SK only ===\n")
panel_czsk <- panel_bal %>% filter(geo %in% c("CZ", "SK"))
est_czsk <- feols(ln_enterprises ~ treated | unit_id + year,
                  data = panel_czsk, cluster = ~unit_id)
cat("CZ vs SK TWFE:\n")
print(summary(est_czsk))

# ===================================================================
# R2: Unit-specific linear trends
# ===================================================================
cat("\n=== R2: Unit-specific linear trends ===\n")
panel_bal$trend <- panel_bal$year - 2008
est_trends <- feols(ln_enterprises ~ treated | unit_id[trend] + year,
                    data = panel_bal, cluster = ~unit_id)
cat("With unit-specific trends:\n")
print(summary(est_trends))

# ===================================================================
# R3: Shorter pre-period (2013-2020 only)
# ===================================================================
cat("\n=== R3: Shorter pre-period (2013+) ===\n")
panel_short <- panel_bal %>% filter(year >= 2013)
est_short <- feols(ln_enterprises ~ treated | unit_id + year,
                   data = panel_short, cluster = ~unit_id)
cat("Short pre-period TWFE:\n")
print(summary(est_short))

# Sun-Abraham with short pre-period
panel_short <- panel_short %>%
  mutate(event_time = ifelse(cohort_year > 0, year - cohort_year, NA_integer_))
est_short_sunab <- feols(ln_enterprises ~ sunab(cohort_year, year) | unit_id + year,
                         data = panel_short, cluster = ~unit_id)
cat("Short pre-period Sun-Abraham:\n")
print(summary(est_short_sunab))

# ===================================================================
# R4: Triple difference — CZ × EET-sector × post
# ===================================================================
cat("\n=== R4: Triple Difference ===\n")
panel_bal$eet_sector <- ifelse(!is.na(panel_bal$treatment_year), 1, 0)
panel_bal$cz <- ifelse(panel_bal$geo == "CZ", 1, 0)
panel_bal$post <- ifelse(panel_bal$year >= 2017, 1, 0)

est_ddd <- feols(ln_enterprises ~ cz:eet_sector:post + cz:post + eet_sector:post | unit_id + year,
                 data = panel_bal, cluster = ~unit_id)
cat("Triple Difference (CZ × EET-sector × post):\n")
print(summary(est_ddd))

# ===================================================================
# R5: Permutation inference (randomize treatment across units)
# ===================================================================
cat("\n=== R5: Permutation Inference ===\n")

# Get actual treatment effect
actual_coef <- coef(feols(ln_enterprises ~ treated | unit_id + year,
                          data = panel_bal))["treated"]

set.seed(42)
n_perms <- 1000
perm_coefs <- numeric(n_perms)

# Get CZ units and their treatment status
cz_units <- unique(panel_bal$unit_id[panel_bal$geo == "CZ"])
n_treated_cz <- sum(unique(panel_bal$treatment_year[panel_bal$geo == "CZ" & !is.na(panel_bal$treatment_year)]) > 0)

for (i in 1:n_perms) {
  # Randomly reassign which CZ divisions are "treated"
  perm_data <- panel_bal
  # Randomly select same number of CZ divisions to be "treated"
  treated_units <- sample(cz_units, n_treated_cz)
  perm_data$perm_treated <- ifelse(perm_data$unit_id %in% treated_units & perm_data$post == 1, 1, 0)

  perm_est <- tryCatch(
    coef(feols(ln_enterprises ~ perm_treated | unit_id + year, data = perm_data))["perm_treated"],
    error = function(e) NA
  )
  perm_coefs[i] <- perm_est
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Actual coefficient:", actual_coef, "\n")
cat("Permutation p-value:", perm_p, "(", sum(!is.na(perm_coefs)), "permutations)\n")
cat("Permutation distribution: mean =", mean(perm_coefs),
    "sd =", sd(perm_coefs), "\n")

# ===================================================================
# R6: Placebo test — non-EET sectors only
# ===================================================================
cat("\n=== R6: Placebo — Effect in non-EET sectors ===\n")

# Create a fake "treatment" for non-EET CZ sectors at 2017
panel_placebo <- panel_bal %>%
  filter(is.na(treatment_year)) %>%
  mutate(
    placebo_treated = ifelse(geo == "CZ" & year >= 2017, 1, 0)
  )

est_placebo <- feols(ln_enterprises ~ placebo_treated | unit_id + year,
                     data = panel_placebo, cluster = ~unit_id)
cat("Placebo (non-EET CZ sectors):\n")
print(summary(est_placebo))

# ===================================================================
# R7: CZSO abolition test (2022-2025)
# ===================================================================
cat("\n=== R7: Abolition Reversal Test (2023) ===\n")

czso_panel <- readRDS("../data/panel_czso_abolition.rds")

# Aggregate to sector × quarter level (across territories)
czso_agg <- czso_panel %>%
  group_by(nace_letter, year, quarter, was_eet_sector, post_abolition) %>%
  summarize(n_entities = sum(n_entities, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    ln_entities = log(n_entities),
    unit_id = nace_letter,
    # Reversal: EET sector × post-abolition
    reversal = was_eet_sector * post_abolition
  )

cat("CZSO abolition panel:", nrow(czso_agg), "obs\n")
cat("Sectors:", paste(sort(unique(czso_agg$nace_letter)), collapse = ", "), "\n")
cat("Time range:", range(czso_agg$yq), "\n")

est_abolition <- feols(ln_entities ~ reversal | unit_id + yq,
                       data = czso_agg,
                       cluster = ~unit_id)
cat("Abolition reversal (EET-sector × post-2023):\n")
print(summary(est_abolition))

# ===================================================================
# Save robustness results
# ===================================================================
robust_results <- list(
  czsk = est_czsk,
  trends = est_trends,
  short = est_short,
  short_sunab = est_short_sunab,
  ddd = est_ddd,
  perm_p = perm_p,
  perm_coefs = perm_coefs,
  actual_coef = actual_coef,
  placebo = est_placebo,
  abolition = est_abolition
)
saveRDS(robust_results, "../data/robust_results.rds")

cat("\n=== All robustness checks complete ===\n")
