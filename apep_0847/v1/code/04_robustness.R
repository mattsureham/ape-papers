# 04_robustness.R — Robustness checks for apep_0847

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

smoking_panel <- readRDS(file.path(data_dir, "smoking_panel.rds"))
quits_panel   <- readRDS(file.path(data_dir, "quits_panel.rds"))
copd_panel    <- readRDS(file.path(data_dir, "copd_panel.rds"))
baseline      <- readRDS(file.path(data_dir, "grants_baseline.rds"))

cat("=== Robustness Checks ===\n")

# ---- 1. Control for baseline smoking × linear trend ----
# Key concern: convergence in smoking rates (high-smoking areas declining faster)
# regardless of policy

# Get baseline (2011-2013) smoking prevalence by LA
baseline_smoking <- smoking_panel %>%
  filter(year_start <= 2013) %>%
  group_by(area_code) %>%
  summarise(baseline_smoking = mean(value, na.rm = TRUE), .groups = "drop")

smoking_robust <- smoking_panel %>%
  left_join(baseline_smoking, by = "area_code") %>%
  mutate(
    baseline_smoking_z = (baseline_smoking - mean(baseline_smoking, na.rm = TRUE)) /
      sd(baseline_smoking, na.rm = TRUE),
    smoke_trend = baseline_smoking_z * (year_start - 2014)
  )

cat("\n--- 1. Controlling for baseline smoking × trend ---\n")
m_smoke_r1 <- feols(value ~ treat_post + smoke_trend | area_code + year_start,
                    data = smoking_robust, cluster = ~area_code)
cat("Smoking with baseline smoking × trend control:\n")
summary(m_smoke_r1)

# Correlation between baseline grant and baseline smoking
cor_grant_smoking <- cor(
  baseline %>% filter(area_code %in% baseline_smoking$area_code) %>%
    arrange(area_code) %>% pull(baseline_pc),
  baseline_smoking %>%
    filter(area_code %in% baseline$area_code) %>%
    arrange(area_code) %>% pull(baseline_smoking),
  use = "complete.obs"
)
cat(sprintf("\nCorr(baseline grant PC, baseline smoking): %.3f\n", cor_grant_smoking))

# ---- 2. LA-specific linear trends ----
cat("\n--- 2. LA-specific linear trends ---\n")
m_smoke_r2 <- feols(value ~ treat_post | area_code[year_start],
                    data = smoking_panel, cluster = ~area_code)
cat("Smoking with LA-specific linear trends:\n")
summary(m_smoke_r2)

# Same for quits
m_quit_r2 <- feols(value ~ treat_post | area_code[year_start],
                   data = quits_panel, cluster = ~area_code)
cat("\nQuit rate with LA-specific linear trends:\n")
summary(m_quit_r2)

# ---- 3. Tercile analysis (robustness to linearity) ----
cat("\n--- 3. Tercile analysis ---\n")
tercile_breaks <- quantile(baseline$baseline_pc, probs = c(1/3, 2/3))

smoking_tercile <- smoking_panel %>%
  mutate(
    grant_tercile = case_when(
      baseline_pc <= tercile_breaks[1] ~ "Low",
      baseline_pc <= tercile_breaks[2] ~ "Medium",
      TRUE ~ "High"
    ),
    grant_tercile = factor(grant_tercile, levels = c("Low", "Medium", "High"))
  )

m_smoke_tercile <- feols(value ~ i(grant_tercile, post, ref = "Low") |
                           area_code + year_start,
                         data = smoking_tercile, cluster = ~area_code)
cat("Smoking by grant tercile × post:\n")
summary(m_smoke_tercile)

# ---- 4. Pre-2015 only (falsification) ----
cat("\n--- 4. Placebo: Pre-2015 trend test ---\n")
# If baseline_z × trend is significant pre-2015, we have convergence concerns
smoking_pre <- smoking_panel %>%
  filter(year_start <= 2014) %>%
  mutate(time_trend = year_start - 2011)

m_pre_trend <- feols(value ~ baseline_z:time_trend | area_code + year_start,
                     data = smoking_pre, cluster = ~area_code)
cat("Pre-2015 trend × baseline_z:\n")
summary(m_pre_trend)

# ---- 5. Exclude COVID years (2020-2021) ----
cat("\n--- 5. Excluding COVID years ---\n")
m_smoke_nocovid <- feols(value ~ treat_post | area_code + year_start,
                         data = smoking_panel %>% filter(year_start <= 2019),
                         cluster = ~area_code)
cat("Smoking (2011-2019 only):\n")
summary(m_smoke_nocovid)

m_quit_nocovid <- feols(value ~ treat_post | area_code + year_start,
                        data = quits_panel %>% filter(year_start <= 2019),
                        cluster = ~area_code)
cat("\nQuit rate (2013-2019 only):\n")
summary(m_quit_nocovid)

# ---- 6. Dose-response: above/below median ----
cat("\n--- 6. Dose-response: above vs below median grant ---\n")
med_grant <- median(baseline$baseline_pc)

smoking_dose <- smoking_panel %>%
  mutate(high_grant = as.integer(baseline_pc > med_grant))

m_smoke_dose <- feols(value ~ i(year_start, high_grant, ref = 2014) |
                        area_code + year_start,
                      data = smoking_dose, cluster = ~area_code)
cat("Smoking event study (binary high/low grant):\n")
print(coeftable(m_smoke_dose))

# ---- 7. Quit rate dose-response (binary) ----
quits_dose <- quits_panel %>%
  mutate(high_grant = as.integer(baseline_pc > med_grant))

m_quit_dose <- feols(value ~ i(year_start, high_grant, ref = 2014) |
                       area_code + year_start,
                     data = quits_dose, cluster = ~area_code)
cat("\nQuit rate event study (binary high/low grant):\n")
print(coeftable(m_quit_dose))

# ---- Save ----
robust_results <- list(
  smoke_baseline_control = m_smoke_r1,
  smoke_la_trends        = m_smoke_r2,
  quit_la_trends         = m_quit_r2,
  smoke_tercile          = m_smoke_tercile,
  pre_trend_test         = m_pre_trend,
  smoke_nocovid          = m_smoke_nocovid,
  quit_nocovid           = m_quit_nocovid,
  smoke_dose_es          = m_smoke_dose,
  quit_dose_es           = m_quit_dose,
  cor_grant_smoking      = cor_grant_smoking
)
saveRDS(robust_results, file.path(data_dir, "robust_results.rds"))

cat("\n=== Robustness checks complete ===\n")
