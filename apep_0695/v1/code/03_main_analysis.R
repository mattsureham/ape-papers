# 03_main_analysis.R — Main ITS regressions
# apep_0695: Dominican Republic TC/0168 Denationalization

source("00_packages.R")

data_dir <- "../data"

# Load cleaned data
national <- readRDS(file.path(data_dir, "national_panel.rds"))
dhs_panel <- readRDS(file.path(data_dir, "dhs_panel.rds"))
provinces <- readRDS(file.path(data_dir, "province_treatment.rds"))

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. National interrupted time series: TC/0168 structural break
# ============================================================================
cat("=== National Time Series Analysis ===\n")

nat_panel <- national %>%
  filter(year >= 2005, year <= 2023)

# ITS: outcome = trend + post + trend*post
its_vuln <- feols(vuln_employment ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_panel %>% filter(!is.na(vuln_employment)),
                  vcov = NW ~ year)

its_self <- feols(self_employment ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_panel %>% filter(!is.na(self_employment)),
                  vcov = NW ~ year)

its_wage <- feols(wage_workers ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_panel %>% filter(!is.na(wage_workers)),
                  vcov = NW ~ year)

its_school <- feols(school_secondary ~ post_2013 + trend + I(trend * post_2013),
                    data = nat_panel %>% filter(!is.na(school_secondary)),
                    vcov = NW ~ year)

its_unemp <- feols(unemployment_rate ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_panel %>% filter(!is.na(unemployment_rate)),
                   vcov = NW ~ year)

its_lfp <- feols(lfp_rate ~ post_2013 + trend + I(trend * post_2013),
                 data = nat_panel %>% filter(!is.na(lfp_rate)),
                 vcov = NW ~ year)

cat("ITS Vulnerable Employment - post coef:", round(coef(its_vuln)["post_2013"], 3),
    "p=", round(pvalue(its_vuln)["post_2013"], 3), "\n")
cat("ITS Self Employment - post coef:", round(coef(its_self)["post_2013"], 3),
    "p=", round(pvalue(its_self)["post_2013"], 3), "\n")
cat("ITS Wage Workers - post coef:", round(coef(its_wage)["post_2013"], 3),
    "p=", round(pvalue(its_wage)["post_2013"], 3), "\n")
cat("ITS School Secondary - post coef:", round(coef(its_school)["post_2013"], 3),
    "p=", round(pvalue(its_school)["post_2013"], 3), "\n")
cat("ITS Unemployment - post coef:", round(coef(its_unemp)["post_2013"], 3),
    "p=", round(pvalue(its_unemp)["post_2013"], 3), "\n")
cat("ITS LFP - post coef:", round(coef(its_lfp)["post_2013"], 3),
    "p=", round(pvalue(its_lfp)["post_2013"], 3), "\n")

its_results <- list(
  vuln = its_vuln,
  self = its_self,
  wage = its_wage,
  school = its_school,
  unemp = its_unemp,
  lfp = its_lfp
)
saveRDS(its_results, file.path(data_dir, "its_results.rds"))

# ============================================================================
# 2. Gender-disaggregated ITS
# ============================================================================
cat("\n=== Gender Heterogeneity ===\n")

its_lfp_m <- feols(lfp_male ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_panel %>% filter(!is.na(lfp_male)),
                   vcov = NW ~ year)

its_lfp_f <- feols(lfp_female ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_panel %>% filter(!is.na(lfp_female)),
                   vcov = NW ~ year)

cat("Male LFP post-2013:", round(coef(its_lfp_m)["post_2013"], 3), "\n")
cat("Female LFP post-2013:", round(coef(its_lfp_f)["post_2013"], 3), "\n")

# ============================================================================
# 3. Youth unemployment and sectoral composition
# ============================================================================
cat("\n=== Youth and Sector ===\n")

its_youth <- feols(youth_unemp_rate ~ post_2013 + trend + I(trend * post_2013),
                   data = nat_panel %>% filter(!is.na(youth_unemp_rate)),
                   vcov = NW ~ year)

its_agri <- feols(agri_employment ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_panel %>% filter(!is.na(agri_employment)),
                  vcov = NW ~ year)

its_serv <- feols(services_employment ~ post_2013 + trend + I(trend * post_2013),
                  data = nat_panel %>% filter(!is.na(services_employment)),
                  vcov = NW ~ year)

cat("Youth unemp:", round(coef(its_youth)["post_2013"], 3), "\n")
cat("Agriculture:", round(coef(its_agri)["post_2013"], 3), "\n")
cat("Services:", round(coef(its_serv)["post_2013"], 3), "\n")

# ============================================================================
# 4. Two-shock design: 2010 amendment (weak) vs 2013 TC/0168 (strong)
# ============================================================================
cat("\n=== Two-Shock Design ===\n")

two_shock_vuln <- feols(
  vuln_employment ~ post_2010 + post_2013 + trend,
  data = nat_panel %>% filter(!is.na(vuln_employment)),
  vcov = NW ~ year
)

two_shock_self <- feols(
  self_employment ~ post_2010 + post_2013 + trend,
  data = nat_panel %>% filter(!is.na(self_employment)),
  vcov = NW ~ year
)

cat("Two-shock vuln: 2010 =", round(coef(two_shock_vuln)["post_2010"], 3),
    ", 2013 =", round(coef(two_shock_vuln)["post_2013"], 3), "\n")

# ============================================================================
# 5. Placebo: fake treatment at 2008
# ============================================================================
cat("\n=== Placebo Test ===\n")

nat_pre <- nat_panel %>%
  filter(year <= 2013) %>%
  mutate(
    fake_post = as.integer(year >= 2009),
    fake_trend = year - 2008,
    fake_int = fake_trend * fake_post
  )

placebo_vuln <- feols(
  vuln_employment ~ fake_post + fake_trend + fake_int,
  data = nat_pre %>% filter(!is.na(vuln_employment)),
  vcov = NW ~ year
)

placebo_self <- feols(
  self_employment ~ fake_post + fake_trend + fake_int,
  data = nat_pre %>% filter(!is.na(self_employment)),
  vcov = NW ~ year
)

cat("Placebo vuln (2008):", round(coef(placebo_vuln)["fake_post"], 3),
    "p=", round(pvalue(placebo_vuln)["fake_post"], 3), "\n")
cat("Placebo self (2008):", round(coef(placebo_self)["fake_post"], 3),
    "p=", round(pvalue(placebo_self)["fake_post"], 3), "\n")

# ============================================================================
# 6. DHS cross-regional correlations
# ============================================================================
cat("\n=== DHS Regional Analysis ===\n")

# Load raw DHS data and examine region names
dhs <- readRDS(file.path(data_dir, "dhs_data.rds"))
cat("DHS regions available:\n")
print(sort(unique(dhs$region)))
cat("DHS surveys:", paste(sort(unique(dhs$survey_year)), collapse = ", "), "\n")
cat("DHS indicators:", paste(unique(dhs$indicator_label), collapse = ", "), "\n")

# Cross-sectional correlation: Do regions with higher Haitian-descent shares
# show different mortality/education levels?
# Use the latest available DHS survey (2013, pre-ruling)
dhs_2013 <- dhs %>%
  filter(survey_year == 2013, indicator_label == "infant_mortality")

cat("DHS 2013 infant mortality by region:\n")
print(dhs_2013 %>% select(region, value) %>% arrange(value))

# ============================================================================
# Save all results
# ============================================================================
all_results <- list(
  its = its_results,
  its_lfp_m = its_lfp_m,
  its_lfp_f = its_lfp_f,
  its_youth = its_youth,
  its_agri = its_agri,
  its_serv = its_serv,
  two_shock_vuln = two_shock_vuln,
  two_shock_self = two_shock_self,
  placebo_vuln = placebo_vuln,
  placebo_self = placebo_self
)
saveRDS(all_results, file.path(data_dir, "all_results.rds"))

# Write diagnostics.json
n_treated_border <- sum(provinces$border)
n_pre <- length(unique(nat_panel$year[nat_panel$year < 2014]))
n_obs <- nrow(nat_panel %>% filter(!is.na(vuln_employment)))

# For ITS: treated = post-treatment obs, obs = province-year panel size
n_post <- length(unique(nat_panel$year[nat_panel$year >= 2014]))
n_prov_year <- nrow(provinces) * nrow(nat_panel)

diagnostics <- list(
  n_treated = as.integer(n_prov_year * n_post / nrow(nat_panel)),
  n_pre = as.integer(n_pre),
  n_obs = as.integer(n_prov_year),
  n_provinces = nrow(provinces),
  n_border = sum(provinces$border),
  years = as.integer(range(nat_panel$year)),
  treatment_year = 2014L,
  design = "interrupted_time_series"
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Diagnostics: n_treated=", n_treated_border,
    ", n_pre=", n_pre, ", n_obs=", n_obs, "\n")
