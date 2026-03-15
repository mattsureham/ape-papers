# 04_robustness.R — Robustness checks
# apep_0695: Dominican Republic TC/0168 Denationalization

source("00_packages.R")

data_dir <- "../data"

province_year <- readRDS(file.path(data_dir, "province_year_panel.rds"))
provinces <- readRDS(file.path(data_dir, "province_treatment.rds"))
national <- readRDS(file.path(data_dir, "national_panel.rds"))

# ============================================================================
# 1. Placebo test: Fake treatment date (2010)
# ============================================================================
cat("=== Placebo Tests ===\n")

# Use pre-period only (2005-2013) with fake treatment at 2010
pre_period <- province_year %>%
  filter(year <= 2013) %>%
  mutate(
    fake_post = as.integer(year >= 2010),
    fake_treat_x_post = treatment_intensity * fake_post
  )

placebo_vuln <- feols(
  vuln_employment ~ fake_treat_x_post | province_code + year,
  data = pre_period %>% filter(!is.na(vuln_employment)),
  cluster = ~province_code
)

placebo_self <- feols(
  self_employment ~ fake_treat_x_post | province_code + year,
  data = pre_period %>% filter(!is.na(self_employment)),
  cluster = ~province_code
)

cat("Placebo vuln employment (2010):", coef(placebo_vuln)["fake_treat_x_post"],
    "p=", pvalue(placebo_vuln)["fake_treat_x_post"], "\n")
cat("Placebo self employment (2010):", coef(placebo_self)["fake_treat_x_post"],
    "p=", pvalue(placebo_self)["fake_treat_x_post"], "\n")

# ============================================================================
# 2. Leave-one-out: Drop each province (main 5 border + Santo Domingo)
# ============================================================================
cat("\n=== Leave-One-Out ===\n")

loo_results <- list()
for (drop_code in c(provinces$province_code)) {
  df_loo <- province_year %>%
    filter(province_code != drop_code, !is.na(vuln_employment))
  fit_loo <- feols(
    vuln_employment ~ treatment_x_post | province_code + year,
    data = df_loo, cluster = ~province_code
  )
  loo_results[[as.character(drop_code)]] <- tibble(
    dropped = provinces$province[provinces$province_code == drop_code],
    coef = coef(fit_loo)["treatment_x_post"],
    se = se(fit_loo)["treatment_x_post"],
    pval = pvalue(fit_loo)["treatment_x_post"]
  )
}
loo_df <- bind_rows(loo_results)
cat("LOO range:", round(range(loo_df$coef), 3), "\n")

# ============================================================================
# 3. High-exposure binary treatment (above-median Haitian share)
# ============================================================================
cat("\n=== Alternative Treatment Definitions ===\n")

did_high_exp <- feols(
  vuln_employment ~ high_exposure_x_post | province_code + year,
  data = province_year %>% filter(!is.na(vuln_employment)),
  cluster = ~province_code
)
cat("High-exposure binary DiD:", coef(did_high_exp)["high_exposure_x_post"], "\n")

# ============================================================================
# 4. Gender heterogeneity (national level)
# ============================================================================
cat("\n=== Gender Heterogeneity ===\n")

nat_clean <- national %>% filter(year >= 2005, year <= 2023)

its_lfp_m <- feols(lfp_male ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_clean %>% filter(!is.na(lfp_male)),
                   vcov = NW ~ year)

its_lfp_f <- feols(lfp_female ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_clean %>% filter(!is.na(lfp_female)),
                   vcov = NW ~ year)

cat("Male LFP post-2013:", coef(its_lfp_m)["post_2013"], "\n")
cat("Female LFP post-2013:", coef(its_lfp_f)["post_2013"], "\n")

# ============================================================================
# 5. Youth unemployment
# ============================================================================
cat("\n=== Youth Unemployment ===\n")

its_youth <- feols(youth_unemp_rate ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_clean %>% filter(!is.na(youth_unemp_rate)),
                   vcov = NW ~ year)

cat("Youth unemployment post-2013:", coef(its_youth)["post_2013"], "\n")

# ============================================================================
# 6. Sectoral composition
# ============================================================================
cat("\n=== Sectoral Composition ===\n")

its_agri <- feols(agri_employment ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_clean %>% filter(!is.na(agri_employment)),
                  vcov = NW ~ year)

its_serv <- feols(services_employment ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_clean %>% filter(!is.na(services_employment)),
                  vcov = NW ~ year)

cat("Agriculture post-2013:", coef(its_agri)["post_2013"], "\n")
cat("Services post-2013:", coef(its_serv)["post_2013"], "\n")

# ============================================================================
# Save robustness results
# ============================================================================
robustness_results <- list(
  placebo_vuln = placebo_vuln,
  placebo_self = placebo_self,
  loo_df = loo_df,
  did_high_exp = did_high_exp,
  its_lfp_m = its_lfp_m,
  its_lfp_f = its_lfp_f,
  its_youth = its_youth,
  its_agri = its_agri,
  its_serv = its_serv
)
saveRDS(robustness_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
