## 03_main_analysis.R — Main regressions
## apep_0906: Panama Canal Expansion and Port Labor Markets

library(tidyverse)
library(fixest)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# Focus on transport/warehousing (NAICS 48-49)
transport <- panel %>%
  filter(industry == "48-49", !is.na(Emp), Emp > 0)

cat("Transport panel:", nrow(transport), "obs,", n_distinct(transport$county_id), "counties\n")

# ============================================================
# 1. BASELINE DiD: Binary treatment
# ============================================================

# Simple 2x2 DiD: East/Gulf vs West, pre vs post
m1 <- feols(log_emp ~ treated:post | county_id + time_q,
            data = transport, cluster = "county_id")

cat("\n=== Model 1: Binary DiD ===\n")
summary(m1)

# ============================================================
# 2. CONTINUOUS TREATMENT: Intensity × Post
# ============================================================

m2 <- feols(log_emp ~ intensity:post | county_id + time_q,
            data = transport, cluster = "county_id")

cat("\n=== Model 2: Continuous Intensity DiD ===\n")
summary(m2)

# ============================================================
# 3. EVENT STUDY
# ============================================================

# Event study with quarterly leads and lags
# Reference period: event_time = -1 (2016 Q2)
transport_es <- transport %>%
  mutate(event_time_f = factor(event_time_binned))

m3 <- feols(log_emp ~ i(event_time_binned, treated, ref = -1) | county_id + time_q,
            data = transport_es, cluster = "county_id")

cat("\n=== Model 3: Event Study ===\n")
summary(m3)

# ============================================================
# 4. WHOLESALE TRADE (NAICS 42) — Secondary outcome
# ============================================================

wholesale <- panel %>%
  filter(industry == "42", !is.na(Emp), Emp > 0)

m4 <- feols(log_emp ~ treated:post | county_id + time_q,
            data = wholesale, cluster = "county_id")

cat("\n=== Model 4: Wholesale Trade DiD ===\n")
summary(m4)

# ============================================================
# 5. HIRING (NEW HIRES) — Worker flow outcome
# ============================================================

m5 <- feols(log(HirN) ~ treated:post | county_id + time_q,
            data = transport %>% filter(HirN > 0), cluster = "county_id")

cat("\n=== Model 5: New Hires DiD ===\n")
summary(m5)

# ============================================================
# 6. EARNINGS — Wage effects
# ============================================================

m6 <- feols(log_earn ~ treated:post | county_id + time_q,
            data = transport, cluster = "county_id")

cat("\n=== Model 6: Earnings DiD ===\n")
summary(m6)

# ============================================================
# 7. SAVE DIAGNOSTICS
# ============================================================

diagnostics <- list(
  n_treated = n_distinct(transport$county_id[transport$treated == 1]),
  n_control = n_distinct(transport$county_id[transport$treated == 0]),
  n_pre = length(unique(transport$time_q[transport$post == 0])),
  n_post = length(unique(transport$time_q[transport$post == 1])),
  n_obs = nrow(transport),
  mean_emp_pre_treated = round(mean(transport$Emp[transport$treated == 1 & transport$post == 0], na.rm = TRUE)),
  mean_emp_pre_control = round(mean(transport$Emp[transport$treated == 0 & transport$post == 0], na.rm = TRUE)),
  sd_log_emp = round(sd(transport$log_emp, na.rm = TRUE), 4)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved\n")

# Save models for table generation
save(m1, m2, m3, m4, m5, m6, transport, wholesale,
     file = file.path(data_dir, "models.RData"))
cat("Models saved\n")
