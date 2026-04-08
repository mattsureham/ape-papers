## 04_robustness.R — Robustness checks and placebo tests
## apep_1419: UK Auto-Enrollment Contribution Step-Up and Wages

source("00_packages.R")
data_dir <- "../data"
load(file.path(data_dir, "analysis_panel.RData"))
load(file.path(data_dir, "main_results.RData"))

panel_bal$event_year <- relevel(factor(panel_bal$year), ref = "2018")

## ========================================================================
## 1. Alternative treatment intensity: micro-only share
## ========================================================================
cat("=== Robustness: Micro share only ===\n")

m_micro <- feols(log_annual_pay ~ micro_share:post | la_code + year,
                 data = panel_bal, cluster = ~la_code)
summary(m_micro)

## ========================================================================
## 2. Alternative treatment intensity: large-firm share (negative control)
## ========================================================================
cat("\n=== Placebo: Large firm share ===\n")

# Large firms were already above minimum — should show no differential effect
m_large <- feols(log_annual_pay ~ large_share:post | la_code + year,
                 data = panel_bal, cluster = ~la_code)
summary(m_large)

## ========================================================================
## 3. Exclude London (outlier in business structure and pay)
## ========================================================================
cat("\n=== Robustness: Exclude London ===\n")

london_codes <- c("E09000001", "E09000002", "E09000003", "E09000004", "E09000005",
                  "E09000006", "E09000007", "E09000008", "E09000009", "E09000010",
                  "E09000011", "E09000012", "E09000013", "E09000014", "E09000015",
                  "E09000016", "E09000017", "E09000018", "E09000019", "E09000020",
                  "E09000021", "E09000022", "E09000023", "E09000024", "E09000025",
                  "E09000026", "E09000027", "E09000028", "E09000029", "E09000030",
                  "E09000031", "E09000032", "E09000033")

panel_nolon <- panel_bal %>% filter(!la_code %in% london_codes)

m_nolon <- feols(log_annual_pay ~ treat_intensity:post | la_code + year,
                 data = panel_nolon, cluster = ~la_code)
summary(m_nolon)

## ========================================================================
## 4. Exclude COVID years (2020-2021)
## ========================================================================
cat("\n=== Robustness: Exclude COVID ===\n")

panel_nocovid <- panel_bal %>% filter(!year %in% c(2020, 2021))

m_nocovid <- feols(log_annual_pay ~ treat_intensity:post | la_code + year,
                   data = panel_nocovid, cluster = ~la_code)
summary(m_nocovid)

## ========================================================================
## 5. Placebo treatment date: 2017 (pre-step-up)
## ========================================================================
cat("\n=== Placebo: 2017 treatment date ===\n")

panel_pre <- panel_bal %>% filter(year <= 2018)
panel_pre$placebo_post <- as.integer(panel_pre$year >= 2017)

m_placebo <- feols(log_annual_pay ~ treat_intensity:placebo_post | la_code + year,
                   data = panel_pre, cluster = ~la_code)
summary(m_placebo)

## ========================================================================
## 6. Tercile treatment (top vs bottom tercile of small-firm share)
## ========================================================================
cat("\n=== Robustness: Tercile treatment ===\n")

q33 <- quantile(panel_bal$small_share, 1/3, na.rm = TRUE)
q67 <- quantile(panel_bal$small_share, 2/3, na.rm = TRUE)

panel_terc <- panel_bal %>%
  filter(small_share <= q33 | small_share >= q67) %>%
  mutate(high_tercile = as.integer(small_share >= q67))

m_tercile <- feols(log_annual_pay ~ high_tercile:post | la_code + year,
                   data = panel_terc, cluster = ~la_code)
summary(m_tercile)

## ========================================================================
## Save
## ========================================================================

save(m_micro, m_large, m_nolon, m_nocovid, m_placebo, m_tercile,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\nRobustness results saved.\n")
