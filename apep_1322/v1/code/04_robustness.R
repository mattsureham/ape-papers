## 04_robustness.R — Robustness checks and heterogeneity
source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
est_df <- panel %>% filter(year >= 2015)

cat("=== Robustness Checks ===\n")

# ============================================================
# R1: Excluding Montana (high baseline, different cohort)
# ============================================================
cat("\n--- R1: Excluding Montana ---\n")

est_no_mt <- est_df %>% filter(state_fips != "30")

r1 <- feols(mm_share ~ post | fips + year, data = est_no_mt,
            cluster = ~state_fips)
cat(sprintf("MM Share (excl. Montana): β = %.5f (SE = %.5f)\n",
            coef(r1)["post"], se(r1)["post"]))

# CS without Montana
cs_no_mt <- est_no_mt %>%
  mutate(county_id = as.integer(factor(fips)),
         g = treat_year)

cs_no_mt_out <- tryCatch(
  att_gt(yname = "mm_share", tname = "year", idname = "county_id",
         gname = "g", data = cs_no_mt, control_group = "nevertreated",
         base_period = "universal"),
  error = function(e) { cat("CS error:", e$message, "\n"); NULL }
)

if (!is.null(cs_no_mt_out)) {
  cs_no_mt_simple <- aggte(cs_no_mt_out, type = "simple")
  cat(sprintf("CS Simple ATT (excl. MT): %.5f (SE: %.5f)\n",
              cs_no_mt_simple$overall.att, cs_no_mt_simple$overall.se))
  cat(sprintf("Pre-test p-value: %.4f\n", cs_no_mt_out$Wpval))
}

# ============================================================
# R2: Log missing middle units (intensive margin)
# ============================================================
cat("\n--- R2: Intensive margin (counties with any MM) ---\n")

est_any_mm <- est_df %>% filter(total_units > 0)
r2 <- feols(mm_share ~ post | fips + year, data = est_any_mm,
            cluster = ~state_fips)
cat(sprintf("MM Share (positive permits only): β = %.5f (SE = %.5f)\n",
            coef(r2)["post"], se(r2)["post"]))

# ============================================================
# R3: Heterogeneity by county size (urban vs rural)
# ============================================================
cat("\n--- R3: Urban vs Rural heterogeneity ---\n")

# Define urban as total permits > median in 2019
median_permits <- median(est_df$total_units[est_df$year == 2019], na.rm = TRUE)
est_df <- est_df %>%
  group_by(fips) %>%
  mutate(urban = as.integer(mean(total_units[year < 2022], na.rm = TRUE) > median_permits)) %>%
  ungroup()

r3_urban <- feols(mm_share ~ post | fips + year,
                  data = filter(est_df, urban == 1), cluster = ~state_fips)
r3_rural <- feols(mm_share ~ post | fips + year,
                  data = filter(est_df, urban == 0), cluster = ~state_fips)

cat(sprintf("Urban counties: β = %.5f (SE = %.5f)\n",
            coef(r3_urban)["post"], se(r3_urban)["post"]))
cat(sprintf("Rural counties: β = %.5f (SE = %.5f)\n",
            coef(r3_rural)["post"], se(r3_rural)["post"]))

# ============================================================
# R4: State-by-state effects
# ============================================================
cat("\n--- R4: State-by-state effects ---\n")

for (st in c("06", "41", "23")) {
  state_df <- est_df %>% filter(state_fips == st | treated == 0)
  r_st <- feols(mm_share ~ post | fips + year, data = state_df,
                cluster = ~state_fips)
  st_name <- c("06" = "California", "41" = "Oregon", "23" = "Maine")[st]
  cat(sprintf("  %s only: β = %.5f (SE = %.5f, p = %.4f)\n",
              st_name, coef(r_st)["post"], se(r_st)["post"],
              pvalue(r_st)["post"]))
}

# ============================================================
# R5: Randomization inference (permute treatment at state level)
# ============================================================
cat("\n--- R5: Randomization Inference ---\n")

# Actual estimate
actual_est <- coef(feols(mm_share ~ post | fips + year, data = est_df,
                         cluster = ~state_fips))["post"]

# Permutation: randomly assign treatment to 4 states (same number as actual)
set.seed(42)
n_perms <- 1000
perm_ests <- numeric(n_perms)

all_states <- unique(est_df$state_fips)
n_treated_states <- 4

for (i in 1:n_perms) {
  fake_treated <- sample(all_states, n_treated_states)
  perm_df <- est_df %>%
    mutate(
      fake_post = as.integer(state_fips %in% fake_treated & year >= 2022)
    )
  perm_fit <- feols(mm_share ~ fake_post | fips + year, data = perm_df,
                    cluster = ~state_fips)
  perm_ests[i] <- coef(perm_fit)["fake_post"]
}

ri_pval <- mean(abs(perm_ests) >= abs(actual_est))
cat(sprintf("Actual estimate: %.5f\n", actual_est))
cat(sprintf("RI p-value (two-sided, 1000 perms): %.4f\n", ri_pval))
cat(sprintf("RI 5th/95th percentile: [%.5f, %.5f]\n",
            quantile(perm_ests, 0.05), quantile(perm_ests, 0.95)))

# ============================================================
# WRITE DIAGNOSTICS
# ============================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(est_df$fips[est_df$treated == 1]),
  n_control = n_distinct(est_df$fips[est_df$treated == 0]),
  n_pre = length(unique(est_df$year[est_df$year < 2022])),
  n_obs = nrow(est_df),
  sd_mm_share_pre = sd(est_df$mm_share[est_df$year < 2022], na.rm = TRUE),
  ri_pval = ri_pval
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save robustness objects
saveRDS(list(r1=r1, r2=r2, r3_urban=r3_urban, r3_rural=r3_rural,
             cs_no_mt_out=cs_no_mt_out,
             perm_ests=perm_ests, actual_est=actual_est),
        "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
