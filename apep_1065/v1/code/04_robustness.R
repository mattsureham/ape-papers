# =============================================================================
# 04_robustness.R — Robustness checks for E-Verify DDD
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
everify_states <- readRDS("../data/everify_states.rds")

panel <- panel |>
  mutate(
    hisp = as.integer(is_hispanic),
    constr = as.integer(is_construction),
    post = as.integer(post_mandate)
  )

# =============================================================================
# 1. PLACEBO ETHNICITY: Non-Hispanic construction DD
# =============================================================================

cat("=== 1. Placebo: Non-Hispanic construction DD ===\n")
nonhisp_constr <- panel |> filter(!is_hispanic & is_construction)

placebo_eth_models <- list()
for (y in c("hire_rate_w", "sep_rate_w", "stability_rate_w")) {
  placebo_eth_models[[y]] <- feols(
    as.formula(paste0(y, " ~ post_mandate | county_fips + yq")),
    data = nonhisp_constr,
    cluster = ~state_id
  )
  cat(sprintf("  %-20s: β = %8.4f (SE = %6.4f)\n", y,
              coef(placebo_eth_models[[y]])["post_mandateTRUE"],
              se(placebo_eth_models[[y]])["post_mandateTRUE"]))
}

# =============================================================================
# 2. PLACEBO INDUSTRY: Hispanic professional services DD
# =============================================================================

cat("\n=== 2. Placebo: Hispanic professional services DD ===\n")
hisp_placebo <- panel |> filter(is_hispanic & !is_construction)

placebo_ind_models <- list()
for (y in c("hire_rate_w", "sep_rate_w", "stability_rate_w")) {
  placebo_ind_models[[y]] <- feols(
    as.formula(paste0(y, " ~ post_mandate | county_fips + yq")),
    data = hisp_placebo,
    cluster = ~state_id
  )
  cat(sprintf("  %-20s: β = %8.4f (SE = %6.4f)\n", y,
              coef(placebo_ind_models[[y]])["post_mandateTRUE"],
              se(placebo_ind_models[[y]])["post_mandateTRUE"]))
}

# =============================================================================
# 3. LEAVE-ONE-STATE-OUT (for DDD)
# =============================================================================

cat("\n=== 3. Leave-one-state-out (DDD hire rate) ===\n")

treat_states <- unique(everify_states$state_fips)
loo_results <- tibble(
  dropped_state = character(),
  coef = numeric(),
  se = numeric()
)

for (s in treat_states) {
  df_loo <- panel |> filter(state_fips != s)
  m <- feols(
    hire_rate_w ~ hisp_x_constr_x_post + hisp_x_post + constr_x_post |
      county_fips^yq + is_hispanic^is_construction^yq,
    data = df_loo,
    cluster = ~state_id
  )
  abbr <- everify_states$state_abbr[everify_states$state_fips == s]
  b <- coef(m)["hisp_x_constr_x_post"]
  s_e <- se(m)["hisp_x_constr_x_post"]
  loo_results <- bind_rows(loo_results,
    tibble(dropped_state = abbr, coef = b, se = s_e))
  cat(sprintf("  Drop %-3s: β = %8.4f (SE = %6.4f)\n", abbr, b, s_e))
}

saveRDS(loo_results, "../data/loo_results.rds")

# =============================================================================
# 4. WILD CLUSTER BOOTSTRAP — Simple DD (Hispanic construction)
# =============================================================================

cat("\n=== 4. Wild cluster bootstrap (Hispanic construction DD) ===\n")

hisp_constr <- panel |> filter(is_hispanic & is_construction)

# Hire rate
dd_hire <- feols(
  hire_rate_w ~ post_mandate | county_fips + yq,
  data = hisp_constr,
  cluster = ~state_id
)

cat("  OLS hire rate DD: β =", round(coef(dd_hire)["post_mandateTRUE"], 4),
    "SE =", round(se(dd_hire)["post_mandateTRUE"], 4), "\n")

# Wild cluster bootstrap
tryCatch({
  boot_hire <- boottest(
    dd_hire,
    param = "post_mandateTRUE",
    clustid = "state_id",
    B = 999,
    type = "webb"
  )
  cat("  WCB p-value (hire):", round(boot_hire$p_val, 4), "\n")
  cat("  WCB 95% CI:", round(boot_hire$conf_int[1], 4), "to",
      round(boot_hire$conf_int[2], 4), "\n")
  saveRDS(boot_hire, "../data/wcb_hire.rds")
}, error = function(e) {
  cat("  WCB failed:", e$message, "\n")
})

# Separation rate
dd_sep <- feols(
  sep_rate_w ~ post_mandate | county_fips + yq,
  data = hisp_constr,
  cluster = ~state_id
)

tryCatch({
  boot_sep <- boottest(
    dd_sep,
    param = "post_mandateTRUE",
    clustid = "state_id",
    B = 999,
    type = "webb"
  )
  cat("  WCB p-value (sep):", round(boot_sep$p_val, 4), "\n")
  cat("  WCB 95% CI:", round(boot_sep$conf_int[1], 4), "to",
      round(boot_sep$conf_int[2], 4), "\n")
  saveRDS(boot_sep, "../data/wcb_sep.rds")
}, error = function(e) {
  cat("  WCB failed:", e$message, "\n")
})

# =============================================================================
# 5. DD DECOMPOSITION: What drives the within-state DD?
# =============================================================================

cat("\n=== 5. DD by ethnicity × industry (what's confounded?) ===\n")
# Run DD for all four groups to show the pattern is state-wide

groups <- list(
  "Hisp-Construction" = panel |> filter(is_hispanic & is_construction),
  "Hisp-Services"     = panel |> filter(is_hispanic & !is_construction),
  "NonH-Construction" = panel |> filter(!is_hispanic & is_construction),
  "NonH-Services"     = panel |> filter(!is_hispanic & !is_construction)
)

dd_decomp <- tibble(
  group = character(),
  outcome = character(),
  coef = numeric(),
  se = numeric()
)

for (g in names(groups)) {
  for (y in c("hire_rate_w", "sep_rate_w")) {
    m <- feols(
      as.formula(paste0(y, " ~ post_mandate | county_fips + yq")),
      data = groups[[g]],
      cluster = ~state_id
    )
    dd_decomp <- bind_rows(dd_decomp,
      tibble(group = g, outcome = y,
             coef = coef(m)["post_mandateTRUE"],
             se = se(m)["post_mandateTRUE"]))
  }
}

cat("DD coefficients by group:\n")
dd_decomp |>
  pivot_wider(names_from = outcome, values_from = c(coef, se)) |>
  mutate(across(where(is.numeric), ~round(.x, 4))) |>
  print()

saveRDS(dd_decomp, "../data/dd_decomp.rds")

# =============================================================================
# 6. ALTERNATIVE EMPLOYMENT THRESHOLD
# =============================================================================

cat("\n=== 6. Alternative Hispanic employment thresholds (DDD hire rate) ===\n")

county_sample <- readRDS("../data/county_sample.rds")
full_panel <- readRDS("../data/qwi_panel.rds") |>
  filter(Emp > 0) |>
  mutate(
    hisp_x_constr_x_post = as.integer(is_hispanic & is_construction & post_mandate),
    hisp_x_post = as.integer(is_hispanic & post_mandate),
    constr_x_post = as.integer(is_construction & post_mandate),
    hire_rate = HirN / pmax(Emp, 1),
    hire_rate_w = pmin(pmax(hire_rate, quantile(hire_rate, 0.01)), quantile(hire_rate, 0.99)),
    yq = year + (quarter - 1) / 4
  )

for (thresh in c(25, 75, 100)) {
  # Recompute county sample with different threshold
  hisp_pre <- full_panel |>
    filter(is_hispanic & is_construction & year <= 2007) |>
    group_by(county_fips, year, quarter) |>
    summarise(emp = sum(Emp, na.rm = TRUE), .groups = "drop") |>
    group_by(county_fips) |>
    summarise(avg = mean(emp), .groups = "drop") |>
    filter(avg >= thresh)

  df_t <- full_panel |> filter(county_fips %in% hisp_pre$county_fips)

  m_t <- feols(
    hire_rate_w ~ hisp_x_constr_x_post + hisp_x_post + constr_x_post |
      county_fips^yq + is_hispanic^is_construction^yq,
    data = df_t,
    cluster = ~state_fips
  )
  cat(sprintf("  Threshold %3d: β = %8.4f (SE = %6.4f), N_counties = %d\n",
              thresh, coef(m_t)["hisp_x_constr_x_post"],
              se(m_t)["hisp_x_constr_x_post"],
              n_distinct(df_t$county_fips)))
}

cat("\nAll robustness checks complete.\n")
