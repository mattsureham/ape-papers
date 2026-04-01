# =============================================================================
# 04_robustness.R — Robustness checks and mechanism tests
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
panel_industry <- readRDS("../data/panel_industry.rds")
treatment <- readRDS("../data/treatment.rds")

# ---- 1. Sector-level mechanism tests ----
# Education (NAICS 61) — direct HBCU employment channel
did_educ <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_industry %>% filter(industry == "61"),
  cluster = ~state_fips
)

# Accommodation & Food (NAICS 72) — student spending multiplier
did_food <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_industry %>% filter(industry == "72"),
  cluster = ~state_fips
)

# Retail (NAICS 44-45) — local spending channel
did_retail <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_industry %>% filter(industry == "44-45"),
  cluster = ~state_fips
)

# ---- 2. Placebo sectors (no HBCU spending link) ----
# Agriculture (NAICS 11)
did_agri <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_industry %>% filter(industry == "11"),
  cluster = ~state_fips
)

# Mining (NAICS 21)
did_mining <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_industry %>% filter(industry == "21"),
  cluster = ~state_fips
)

# ---- 3. Wild cluster bootstrap (main specification) ----
# Using fwildclusterboot for proper small-sample inference
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}
library(fwildclusterboot)

did_static <- readRDS("../data/did_static.rds")

boot_result <- tryCatch({
  boottest(
    did_static,
    param = "hbcu_share:post",
    clustid = ~state_fips,
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  message("Wild cluster bootstrap error: ", e$message)
  NULL
})

if (!is.null(boot_result)) {
  message(sprintf("Wild cluster bootstrap p-value: %.4f", boot_result$p_val))
  message(sprintf("  95%% CI: [%.4f, %.4f]", boot_result$conf_int[1], boot_result$conf_int[2]))
}

# ---- 4. Leave-one-state-out jackknife ----
hbcu_states <- unique(panel$state_fips[panel$hbcu_county == 1])
jackknife_coefs <- numeric(length(hbcu_states))
names(jackknife_coefs) <- hbcu_states

for (i in seq_along(hbcu_states)) {
  st <- hbcu_states[i]
  panel_loo <- panel %>% filter(state_fips != st)
  fit_loo <- feols(
    log_emp ~ hbcu_share:post |
      county_fips + state_fips^quarter + year^quarter,
    data = panel_loo,
    cluster = ~state_fips
  )
  jackknife_coefs[i] <- coef(fit_loo)["hbcu_share:post"]
}

message("\nLeave-one-state-out range:")
message(sprintf("  Min: %.4f (drop %s)", min(jackknife_coefs), names(which.min(jackknife_coefs))))
message(sprintf("  Max: %.4f (drop %s)", max(jackknife_coefs), names(which.max(jackknife_coefs))))

# ---- 5. Pre-post split: 2012Q3-2014Q2 vs 2014Q3-2016Q4 (reversal test) ----
panel <- panel %>%
  mutate(
    period = case_when(
      yq < 2012.5 ~ "pre",
      yq >= 2012.5 & yq < 2014.5 ~ "shock",
      yq >= 2014.5 ~ "reversal"
    ),
    shock_period = as.integer(period == "shock"),
    reversal_period = as.integer(period == "reversal")
  )

did_reversal <- feols(
  log_emp ~ hbcu_share:shock_period + hbcu_share:reversal_period |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)
summary(did_reversal)

# ---- 6. Restrict control group to HBCU-hosting states ----
hbcu_states <- unique(panel$state_fips[panel$hbcu_county == 1])
message(sprintf("\nHBCU-hosting states: %d", length(hbcu_states)))

panel_hbcu_states <- panel %>% filter(state_fips %in% hbcu_states)
message(sprintf("Panel restricted to HBCU states: %s obs, %d counties",
                format(nrow(panel_hbcu_states), big.mark = ","),
                n_distinct(panel_hbcu_states$county_fips)))

did_hbcu_states <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_hbcu_states,
  cluster = ~state_fips
)
summary(did_hbcu_states)
message(sprintf("HBCU-states-only: coef = %.4f, SE = %.4f, p = %.4f",
                coef(did_hbcu_states)["hbcu_share:post"],
                se(did_hbcu_states)["hbcu_share:post"],
                pvalue(did_hbcu_states)["hbcu_share:post"]))

saveRDS(did_hbcu_states, "../data/did_hbcu_states.rds")

# ---- 7. Employment-weighted regression ----
# Weight by pre-period county employment (average over pre-treatment quarters)
pre_emp <- panel %>%
  filter(event_q < 0) %>%
  group_by(county_fips) %>%
  summarize(emp_weight = mean(Emp, na.rm = TRUE), .groups = "drop")

panel_weighted <- panel %>%
  left_join(pre_emp, by = "county_fips")

did_weighted <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_weighted,
  weights = ~emp_weight,
  cluster = ~state_fips
)
summary(did_weighted)
message(sprintf("Employment-weighted: coef = %.4f, SE = %.4f, p = %.4f",
                coef(did_weighted)["hbcu_share:post"],
                se(did_weighted)["hbcu_share:post"],
                pvalue(did_weighted)["hbcu_share:post"]))

saveRDS(did_weighted, "../data/did_weighted.rds")

# ---- 8. Save results ----
sector_results <- list(
  education = did_educ,
  food = did_food,
  retail = did_retail,
  agriculture = did_agri,
  mining = did_mining
)

saveRDS(sector_results, "../data/sector_results.rds")
saveRDS(boot_result, "../data/boot_result.rds")
saveRDS(jackknife_coefs, "../data/jackknife_coefs.rds")
saveRDS(did_reversal, "../data/did_reversal.rds")

message("Robustness checks complete.")
