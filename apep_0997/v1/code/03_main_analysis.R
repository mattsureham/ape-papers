## 03_main_analysis.R — Main DiD regressions
## apep_0997: Romania Construction Tax Holiday

source("00_packages.R")

panel_a <- readRDS("../data/panel_annual.rds")
panel_q <- readRDS("../data/panel_quarterly.rds")

cat("=== MAIN ANALYSIS ===\n\n")

# ================================================================
# 1. Primary Specification: Annual DiD on log salaried employment
# ================================================================
cat("--- 1. Log Salaried Employment (Annual) ---\n")

# Baseline TWFE DiD (single treatment date, no staggering)
m1_sal <- feols(log_sal ~ treat | nace_r2 + year,
                data = panel_a,
                cluster = ~nace_r2)

# With COVID year dummies
panel_a <- panel_a %>%
  mutate(covid_2020 = ifelse(year == 2020, 1L, 0L),
         covid_2021 = ifelse(year == 2021, 1L, 0L))

m1_sal_covid <- feols(log_sal ~ treat + covid_2020 + covid_2021 | nace_r2 + year,
                      data = panel_a,
                      cluster = ~nace_r2)

# Pre-2020 only (clean window)
m1_sal_clean <- feols(log_sal ~ treat | nace_r2 + year,
                      data = panel_a %>% filter(year <= 2019),
                      cluster = ~nace_r2)

cat("Full sample:\n")
print(summary(m1_sal))
cat("\nWith COVID controls:\n")
print(summary(m1_sal_covid))
cat("\nClean window (2010-2019):\n")
print(summary(m1_sal_clean))

# ================================================================
# 2. Self-employment share (formalization proxy)
# ================================================================
cat("\n--- 2. Self-Employment Share (Annual) ---\n")

m2_self <- feols(self_emp_share ~ treat | nace_r2 + year,
                 data = panel_a,
                 cluster = ~nace_r2)

m2_self_clean <- feols(self_emp_share ~ treat | nace_r2 + year,
                       data = panel_a %>% filter(year <= 2019),
                       cluster = ~nace_r2)

cat("Full sample:\n")
print(summary(m2_self))
cat("\nClean window (2010-2019):\n")
print(summary(m2_self_clean))

# ================================================================
# 3. Total Employment (less informative but important)
# ================================================================
cat("\n--- 3. Log Total Employment (Annual) ---\n")

m3_emp <- feols(log_emp ~ treat | nace_r2 + year,
                data = panel_a,
                cluster = ~nace_r2)

cat("Full sample:\n")
print(summary(m3_emp))

# ================================================================
# 4. Quarterly LCI (Labour Cost Index) DiD
# ================================================================
cat("\n--- 4. Labour Cost Index (Quarterly) ---\n")

m4_lci <- feols(log_lci ~ treat | nace_r2 + year:quarter,
                data = panel_q %>% filter(!is.na(lci)),
                cluster = ~nace_r2)

m4_lci_clean <- feols(log_lci ~ treat | nace_r2 + year:quarter,
                      data = panel_q %>% filter(!is.na(lci), year <= 2019),
                      cluster = ~nace_r2)

cat("Full sample:\n")
print(summary(m4_lci))
cat("\nClean window (to 2019):\n")
print(summary(m4_lci_clean))

# ================================================================
# 5. Event Study — Annual (key diagnostic)
# ================================================================
cat("\n--- 5. Event Study (Annual) ---\n")

# Create event-time indicators (base period = -1 = 2018)
panel_a <- panel_a %>%
  mutate(et = year - 2019,
         et_factor = factor(et))

# Drop base period (-1)
m5_es <- feols(log_sal ~ i(et, construction, ref = -1) | nace_r2 + year,
               data = panel_a,
               cluster = ~nace_r2)

cat("Event study coefficients:\n")
print(summary(m5_es))

# Self-employment share event study
m5_es_self <- feols(self_emp_share ~ i(et, construction, ref = -1) | nace_r2 + year,
                    data = panel_a,
                    cluster = ~nace_r2)

cat("\nSelf-employment share event study:\n")
print(summary(m5_es_self))

# ================================================================
# 6. Quarterly Event Study (LCI)
# ================================================================
cat("\n--- 6. Quarterly Event Study (LCI) ---\n")

# Base period = 2018Q4 (event_q = -1)
panel_q <- panel_q %>%
  mutate(eq = event_q,
         eq_factor = factor(eq))

m6_es_lci <- feols(log_lci ~ i(eq, construction, ref = -1) | nace_r2 + year:quarter,
                   data = panel_q %>% filter(!is.na(lci), eq >= -16, eq <= 20),
                   cluster = ~nace_r2)

cat("Quarterly LCI event study:\n")
print(summary(m6_es_lci))

# ================================================================
# 7. Save main results
# ================================================================
cat("\n=== Saving Main Results ===\n")

results <- list(
  m1_sal = m1_sal,
  m1_sal_covid = m1_sal_covid,
  m1_sal_clean = m1_sal_clean,
  m2_self = m2_self,
  m2_self_clean = m2_self_clean,
  m3_emp = m3_emp,
  m4_lci = m4_lci,
  m4_lci_clean = m4_lci_clean,
  m5_es = m5_es,
  m5_es_self = m5_es_self,
  m6_es_lci = m6_es_lci
)
saveRDS(results, "../data/main_results.rds")

# ================================================================
# 8. Write diagnostics.json
# ================================================================
cat("\n=== Writing diagnostics.json ===\n")

diag <- list(
  n_treated = 1L,  # 1 sector (construction)
  n_treated_detail = "1 sector (NACE F: Construction), covering ~670K workers pre-treatment",
  n_control = n_distinct(panel_a$nace_r2[panel_a$construction == 0]),
  n_pre = length(unique(panel_a$year[panel_a$year < 2019])),
  n_post = length(unique(panel_a$year[panel_a$year >= 2019])),
  n_obs = nrow(panel_a),
  n_obs_quarterly = nrow(panel_q),
  treatment_year = 2019L,
  did_coef_log_sal = round(coef(m1_sal)["treat"], 4),
  did_coef_self_share = round(coef(m2_self)["treat"], 4),
  did_coef_lci = round(coef(m4_lci)["treat"], 4)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Saved: data/diagnostics.json\n")

# Print key numbers
cat("\n=== KEY RESULTS ===\n")
cat(sprintf("DiD on log(salaried emp): β = %.4f (SE = %.4f)\n",
            coef(m1_sal)["treat"], se(m1_sal)["treat"]))
cat(sprintf("DiD on self-emp share:    β = %.4f (SE = %.4f)\n",
            coef(m2_self)["treat"], se(m2_self)["treat"]))
cat(sprintf("DiD on log(LCI):          β = %.4f (SE = %.4f)\n",
            coef(m4_lci)["treat"], se(m4_lci)["treat"]))

cat("\n03_main_analysis.R complete.\n")
