## ============================================================
## 04_robustness.R — Robustness Checks
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
bw_gap <- fread(file.path(DATA_DIR, "bw_gap_panel.csv"))
triple_diff <- fread(file.path(DATA_DIR, "triple_diff_panel.csv"))
panel <- fread(file.path(DATA_DIR, "state_year_race_panel.csv"))
load(file.path(DATA_DIR, "main_analysis_objects.RData"))

cat("=== ROBUSTNESS CHECKS ===\n")

## ============================================================
## 1. POST-2020 ADOPTERS ONLY (clean pre-period, no COVID overlap)
## ============================================================

cat("\n--- Robustness 1: Post-2020 adopters ---\n")

bw_late <- bw_gap %>%
  filter(first_treat == 0 | first_treat >= 2021) %>%
  mutate(state_id = as.integer(factor(state_fips)))

cs_late <- att_gt(
  yname = "emp_gap", tname = "year", idname = "state_id",
  gname = "first_treat",
  data = bw_late %>% filter(!is.na(emp_gap)),
  control_group = "nevertreated", est_method = "dr",
  base_period = "universal"
)
agg_late <- aggte(cs_late, type = "simple")
cat("Post-2020 adopters ATT:", round(agg_late$overall.att, 4),
    "(SE:", round(agg_late$overall.se, 4), ")\n")

## ============================================================
## 2. PLACEBO: ASIAN vs WHITE
## ============================================================

cat("\n--- Robustness 2: Placebo (Asian vs White) ---\n")

asian_gap <- panel %>%
  filter(race_group %in% c("Asian", "White")) %>%
  select(year, state_fips, race_group, first_treat, emp_rate, state_id) %>%
  pivot_wider(names_from = race_group, values_from = emp_rate) %>%
  mutate(
    emp_gap = Asian - White,
    crown_active = as.integer(first_treat > 0 & year >= first_treat)
  ) %>%
  filter(!is.na(emp_gap))

cs_placebo <- tryCatch({
  att_gt(
    yname = "emp_gap", tname = "year", idname = "state_id",
    gname = "first_treat",
    data = asian_gap,
    control_group = "nevertreated", est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("  Placebo CS-DiD failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_placebo)) {
  agg_placebo <- aggte(cs_placebo, type = "simple")
  cat("Placebo (Asian-White) ATT:", round(agg_placebo$overall.att, 4),
      "(SE:", round(agg_placebo$overall.se, 4), ")\n")
} else {
  agg_placebo <- list(overall.att = NA, overall.se = NA)
}

## ============================================================
## 3. TWFE TRIPLE-DIFF: CUSTOMER-FACING vs NON-CUSTOMER-FACING
## ============================================================

cat("\n--- Robustness 3: Customer-facing occupation mechanism ---\n")

## The key mechanism test: Is the triple-diff coefficient larger for
## customer-facing occupation shares than for non-customer-facing?

## Customer-facing triple-diff (from main analysis)
cat("Customer-facing share triple-diff (from main):",
    round(coef(twfe_cust)["treated_triple"], 4),
    "(SE:", round(se(twfe_cust)["treated_triple"], 4), ")\n")

## Professional share triple-diff (should be smaller/insignificant if mechanism is appearance-based)
cat("Professional share triple-diff (from main):",
    round(coef(twfe_prof)["treated_triple"], 4),
    "(SE:", round(se(twfe_prof)["treated_triple"], 4), ")\n")

## ============================================================
## 4. RANDOMIZATION INFERENCE
## ============================================================

cat("\n--- Robustness 4: Randomization Inference ---\n")

set.seed(42)
n_perm <- 500
actual_att <- agg_emp$overall.att

actual_treats <- bw_gap %>%
  filter(first_treat > 0) %>%
  distinct(state_fips, first_treat)

all_states <- unique(bw_gap$state_fips)
ri_atts <- numeric(n_perm)

for (i in seq_len(n_perm)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perm, "\n")

  perm_states <- sample(all_states, nrow(actual_treats))
  perm_data <- bw_gap %>%
    mutate(
      first_treat = ifelse(state_fips %in% perm_states,
                            actual_treats$first_treat[match(state_fips, perm_states)],
                            0L),
      crown_active = as.integer(first_treat > 0 & year >= first_treat),
      state_id = as.integer(factor(state_fips))
    ) %>%
    filter(!is.na(emp_gap))

  tryCatch({
    cs_perm <- att_gt(
      yname = "emp_gap", tname = "year", idname = "state_id",
      gname = "first_treat", data = perm_data,
      control_group = "nevertreated", est_method = "dr",
      base_period = "universal"
    )
    ri_atts[i] <- aggte(cs_perm, type = "simple")$overall.att
  }, error = function(e) ri_atts[i] <<- NA)
}

ri_pval <- mean(abs(ri_atts[!is.na(ri_atts)]) >= abs(actual_att), na.rm = TRUE)
cat("RI p-value:", round(ri_pval, 4), "\n")

ri_results <- data.frame(
  actual_att = actual_att,
  ri_pvalue = ri_pval,
  n_permutations = sum(!is.na(ri_atts))
)
fwrite(ri_results, file.path(DATA_DIR, "ri_results.csv"))
fwrite(data.frame(att = ri_atts[!is.na(ri_atts)]),
       file.path(DATA_DIR, "ri_distribution.csv"))

## ============================================================
## 5. SUN-ABRAHAM
## ============================================================

cat("\n--- Robustness 5: Sun-Abraham ---\n")

sa_emp <- feols(
  emp_gap ~ sunab(first_treat, year) | state_id + year,
  data = bw_gap %>% filter(!is.na(emp_gap)),
  cluster = ~state_fips
)
cat("Sun-Abraham aggregate ATT:\n")
print(summary(sa_emp, agg = "ATT"))

sa_results <- tryCatch({
  data.frame(
    event_time = as.numeric(gsub("year::", "", names(coef(sa_emp)))),
    estimate = coef(sa_emp),
    se = se(sa_emp)
  )
}, error = function(e) {
  cat("SA results extraction failed:", e$message, "\n")
  data.frame(event_time = NA, estimate = NA, se = NA)
})
sa_results$ci_lower <- sa_results$estimate - 1.96 * sa_results$se
sa_results$ci_upper <- sa_results$estimate + 1.96 * sa_results$se
fwrite(sa_results, file.path(DATA_DIR, "sun_abraham_results.csv"))

## ============================================================
## COMPILE ROBUSTNESS TABLE
## ============================================================

rob_specs <- c(
  "CS-DiD baseline",
  "Post-2020 adopters only",
  "Placebo: Asian-White gap",
  "TWFE Triple-Diff (employment)",
  "TWFE Triple-Diff (customer-facing)"
)

rob_ests <- c(
  agg_emp$overall.att,
  agg_late$overall.att,
  ifelse(is.null(cs_placebo), NA, agg_placebo$overall.att),
  coef(twfe_emp)["treated_triple"],
  coef(twfe_cust)["treated_triple"]
)

rob_ses <- c(
  agg_emp$overall.se,
  agg_late$overall.se,
  ifelse(is.null(cs_placebo), NA, agg_placebo$overall.se),
  se(twfe_emp)["treated_triple"],
  se(twfe_cust)["treated_triple"]
)

robustness_table <- data.frame(
  specification = rob_specs,
  estimate = rob_ests,
  se = rob_ses
)
robustness_table$pval <- 2 * pnorm(-abs(robustness_table$estimate / robustness_table$se))
robustness_table$stars <- ifelse(robustness_table$pval < 0.01, "***",
                           ifelse(robustness_table$pval < 0.05, "**",
                             ifelse(robustness_table$pval < 0.10, "*", "")))

fwrite(robustness_table, file.path(DATA_DIR, "robustness_table.csv"))
cat("\nRobustness table:\n")
print(robustness_table)

cat("\n=== ALL ROBUSTNESS COMPLETE ===\n")
