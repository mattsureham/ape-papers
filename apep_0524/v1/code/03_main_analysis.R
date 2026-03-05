## ============================================================
## 03_main_analysis.R — Main DiD and Triple-Diff Analysis
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
bw_gap <- fread(file.path(DATA_DIR, "bw_gap_panel.csv"))
triple_diff <- fread(file.path(DATA_DIR, "triple_diff_panel.csv"))
crown_dates <- fread(file.path(DATA_DIR, "crown_act_dates.csv"))

cat("Gap panel:", nrow(bw_gap), "rows,", n_distinct(bw_gap$state_fips), "states,",
    n_distinct(bw_gap$year), "years\n")
cat("Treated states:", sum(bw_gap$first_treat > 0) / n_distinct(bw_gap$year), "\n")

## ============================================================
## 1. CALLAWAY-SANT'ANNA: GROUP-TIME ATTs
## ============================================================

cat("\n=== CS-DiD ESTIMATION ===\n")

run_cs <- function(yvar, data, label) {
  cat("\n--- CS-DiD:", label, "---\n")
  out <- att_gt(
    yname = yvar, tname = "year", idname = "state_id",
    gname = "first_treat",
    data = data %>% filter(!is.na(.data[[yvar]])),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal"
  )
  cat("Group-time ATTs computed.\n")
  return(out)
}

cs_emp <- run_cs("emp_gap", bw_gap, "Employment gap")
cs_earn <- run_cs("earn_gap", bw_gap, "Earnings gap")
cs_prof <- run_cs("prof_gap", bw_gap, "Professional occ gap")
cs_cust <- run_cs("cust_gap", bw_gap, "Customer-facing occ gap")

## Event studies
es_emp <- aggte(cs_emp, type = "dynamic", min_e = -4, max_e = 3)
es_earn <- aggte(cs_earn, type = "dynamic", min_e = -4, max_e = 3)
es_prof <- aggte(cs_prof, type = "dynamic", min_e = -4, max_e = 3)
es_cust <- aggte(cs_cust, type = "dynamic", min_e = -4, max_e = 3)

## Save event study data
save_es <- function(es, name) {
  df <- data.frame(
    event_time = es$egt,
    estimate = es$att.egt,
    se = es$se.egt,
    ci_lower = es$att.egt - 1.96 * es$se.egt,
    ci_upper = es$att.egt + 1.96 * es$se.egt
  )
  fwrite(df, file.path(DATA_DIR, paste0("es_", name, ".csv")))
  return(df)
}

es_emp_df <- save_es(es_emp, "employment_gap")
es_earn_df <- save_es(es_earn, "earnings_gap")
es_prof_df <- save_es(es_prof, "professional_gap")
es_cust_df <- save_es(es_cust, "customer_facing_gap")

## Aggregate ATTs
agg_emp <- aggte(cs_emp, type = "simple")
agg_earn <- aggte(cs_earn, type = "simple")
agg_prof <- aggte(cs_prof, type = "simple")
agg_cust <- aggte(cs_cust, type = "simple")

cat("\n=== AGGREGATE ATTs ===\n")
cat("Employment gap:", round(agg_emp$overall.att, 4), "(SE:", round(agg_emp$overall.se, 4), ")\n")
cat("Earnings gap:", round(agg_earn$overall.att, 4), "(SE:", round(agg_earn$overall.se, 4), ")\n")
cat("Professional gap:", round(agg_prof$overall.att, 4), "(SE:", round(agg_prof$overall.se, 4), ")\n")
cat("Customer-facing gap:", round(agg_cust$overall.att, 4), "(SE:", round(agg_cust$overall.se, 4), ")\n")

agg_results <- data.frame(
  outcome = c("Employment gap", "Log earnings gap",
              "Professional share gap", "Customer-facing share gap"),
  att = c(agg_emp$overall.att, agg_earn$overall.att,
          agg_prof$overall.att, agg_cust$overall.att),
  se = c(agg_emp$overall.se, agg_earn$overall.se,
         agg_prof$overall.se, agg_cust$overall.se),
  n_groups = c(length(unique(cs_emp$group)), length(unique(cs_earn$group)),
               length(unique(cs_prof$group)), length(unique(cs_cust$group))),
  n_states = n_distinct(bw_gap$state_fips)
)
agg_results$ci_lower <- agg_results$att - 1.96 * agg_results$se
agg_results$ci_upper <- agg_results$att + 1.96 * agg_results$se
agg_results$pval <- 2 * pnorm(-abs(agg_results$att / agg_results$se))
fwrite(agg_results, file.path(DATA_DIR, "aggregate_atts.csv"))

## ============================================================
## 2. TWFE TRIPLE-DIFF
## ============================================================

cat("\n=== TWFE TRIPLE-DIFF ===\n")

twfe_emp <- feols(
  emp_rate ~ treated_triple | state_fips^year + state_fips^race_group + race_group^year,
  data = triple_diff, cluster = ~state_fips
)

twfe_earn <- feols(
  log_median_earn ~ treated_triple | state_fips^year + state_fips^race_group + race_group^year,
  data = triple_diff %>% filter(!is.na(log_median_earn)),
  cluster = ~state_fips
)

twfe_prof <- feols(
  share_professional ~ treated_triple | state_fips^year + state_fips^race_group + race_group^year,
  data = triple_diff %>% filter(!is.na(share_professional)),
  cluster = ~state_fips
)

twfe_cust <- feols(
  share_customer_facing ~ treated_triple | state_fips^year + state_fips^race_group + race_group^year,
  data = triple_diff %>% filter(!is.na(share_customer_facing)),
  cluster = ~state_fips
)

etable(twfe_emp, twfe_earn, twfe_prof, twfe_cust,
       headers = c("Employment", "Earnings", "Professional", "Customer-Facing"),
       se.below = TRUE, fitstat = c("n", "r2"))

twfe_results <- data.frame(
  outcome = c("Employment rate", "Log median earnings",
              "Professional share", "Customer-facing share"),
  coef = c(coef(twfe_emp)["treated_triple"],
           coef(twfe_earn)["treated_triple"],
           coef(twfe_prof)["treated_triple"],
           coef(twfe_cust)["treated_triple"]),
  se = c(se(twfe_emp)["treated_triple"],
         se(twfe_earn)["treated_triple"],
         se(twfe_prof)["treated_triple"],
         se(twfe_cust)["treated_triple"]),
  n_obs = c(nobs(twfe_emp), nobs(twfe_earn), nobs(twfe_prof), nobs(twfe_cust)),
  r2 = c(r2(twfe_emp, "ar2"), r2(twfe_earn, "ar2"),
         r2(twfe_prof, "ar2"), r2(twfe_cust, "ar2"))
)
twfe_results$ci_lower <- twfe_results$coef - 1.96 * twfe_results$se
twfe_results$ci_upper <- twfe_results$coef + 1.96 * twfe_results$se
twfe_results$pval <- 2 * pnorm(-abs(twfe_results$coef / twfe_results$se))
fwrite(twfe_results, file.path(DATA_DIR, "twfe_results.csv"))

## ============================================================
## 3. SEX HETEROGENEITY
## ============================================================

cat("\n=== SEX HETEROGENEITY ===\n")

## Female employment gap
bw_gap_sex <- bw_gap %>%
  mutate(
    female_emp_gap = female_emp_rate_Black - female_emp_rate_White,
    male_emp_gap = male_emp_rate_Black - male_emp_rate_White
  )

cs_fem <- run_cs("female_emp_gap", bw_gap_sex, "Female employment gap")
cs_mal <- run_cs("male_emp_gap", bw_gap_sex, "Male employment gap")

agg_fem <- aggte(cs_fem, type = "simple")
agg_mal <- aggte(cs_mal, type = "simple")

cat("Female employment gap ATT:", round(agg_fem$overall.att, 4),
    "(SE:", round(agg_fem$overall.se, 4), ")\n")
cat("Male employment gap ATT:", round(agg_mal$overall.att, 4),
    "(SE:", round(agg_mal$overall.se, 4), ")\n")

## Save female-specific event studies
es_fem <- aggte(cs_fem, type = "dynamic", min_e = -4, max_e = 3)
es_mal <- aggte(cs_mal, type = "dynamic", min_e = -4, max_e = 3)
save_es(es_fem, "female_employment_gap")
save_es(es_mal, "male_employment_gap")

sex_results <- data.frame(
  outcome = c("Employment gap", "Employment gap"),
  subsample = c("Women", "Men"),
  att = c(agg_fem$overall.att, agg_mal$overall.att),
  se = c(agg_fem$overall.se, agg_mal$overall.se),
  n_groups = c(length(unique(cs_fem$group)), length(unique(cs_mal$group)))
)
sex_results$ci_lower <- sex_results$att - 1.96 * sex_results$se
sex_results$ci_upper <- sex_results$att + 1.96 * sex_results$se
sex_results$pval <- 2 * pnorm(-abs(sex_results$att / sex_results$se))
fwrite(sex_results, file.path(DATA_DIR, "sex_heterogeneity.csv"))

## ============================================================
## 4. BACON DECOMPOSITION
## ============================================================

cat("\n=== BACON DECOMPOSITION ===\n")

## Balance the panel for Bacon decomposition
balanced_states <- bw_gap %>%
  filter(!is.na(emp_gap)) %>%
  count(state_id) %>%
  filter(n == max(n)) %>%
  pull(state_id)

bacon_emp <- bacon(
  emp_gap ~ crown_active,
  data = bw_gap %>% filter(!is.na(emp_gap), state_id %in% balanced_states),
  id_var = "state_id",
  time_var = "year"
)

cat("Bacon decomposition columns:", paste(names(bacon_emp), collapse = ", "), "\n")
cat("Bacon decomposition:\n")
print(head(bacon_emp, 10))

fwrite(bacon_emp, file.path(DATA_DIR, "bacon_decomposition.csv"))

## ============================================================
## 5. WELFARE CALCULATION
## ============================================================

cat("\n=== WELFARE ===\n")

## Use ACS data for welfare calculation
pre_crown_black <- triple_diff %>%
  filter(black == 1, crown_active == 0)

avg_black_median_earn <- mean(pre_crown_black$median_earnings, na.rm = TRUE)
avg_black_pop <- mean(pre_crown_black$pop_16_64, na.rm = TRUE)

welfare <- data.frame(
  component = c("Employment gap ATT (pp)", "CS-DiD aggregate",
                "Avg Black median earnings (pre-CROWN)",
                "Avg Black working-age pop per state"),
  value = c(agg_emp$overall.att, agg_emp$overall.att,
            avg_black_median_earn, avg_black_pop)
)
fwrite(welfare, file.path(DATA_DIR, "welfare_calculation.csv"))

cat("Employment gap ATT:", round(agg_emp$overall.att, 4), "pp\n")
cat("Avg Black median earnings:", round(avg_black_median_earn), "\n")

## Save R objects for robustness
save(cs_emp, cs_earn, cs_prof, cs_cust,
     es_emp, es_earn, es_prof, es_cust,
     agg_emp, agg_earn, agg_prof, agg_cust,
     cs_fem, cs_mal, agg_fem, agg_mal,
     twfe_emp, twfe_earn, twfe_prof, twfe_cust,
     file = file.path(DATA_DIR, "main_analysis_objects.RData"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
