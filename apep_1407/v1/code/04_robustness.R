## 04_robustness.R — Robustness checks and placebos
## apep_1407: The Insurance Denominator

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "fema_analysis.rds"))

## ============================================================
## A. Placebo: X-zone (non-SFHA) properties
## ============================================================

## X-zone properties should NOT be differentially affected by RR2.0
df_xzone <- df |> filter(floodZoneCurrent %in% c("X", "B", "C"))

if (nrow(df_xzone) > 100) {
  m_placebo_x <- feols(log_premium_w ~ grandfathered:post_rr2 | county_fe + yq,
                       data = df_xzone, cluster = ~county_fe)
  cat("=== Placebo: X-zone ===\n")
  summary(m_placebo_x)
} else {
  cat("X-zone sample too small for placebo test.\n")
  m_placebo_x <- NULL
}

## ============================================================
## B. Placebo: Pre-period fake treatment (2020Q4 as fake RR2.0)
## ============================================================

df_pre <- df |> filter(post_rr2 == 0)
df_pre <- df_pre |>
  mutate(fake_post = as.integer(eff_date >= as.Date("2020-10-01")))

m_placebo_time <- feols(log_premium_w ~ grandfathered:fake_post | county_fe + yq,
                        data = df_pre, cluster = ~county_fe)
cat("\n=== Placebo: Fake treatment at 2020Q4 ===\n")
summary(m_placebo_time)

## ============================================================
## C. Alternative clustering: State level
## ============================================================

m_state_cluster <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                         data = df, cluster = ~propertyState)
cat("\n=== State-clustered SEs ===\n")
summary(m_state_cluster)

## ============================================================
## D. Continuous treatment dose: premium change magnitude
## ============================================================

## Construct dose = premium in first post period - premium in last pre period
## Use median premium by county × grandfathered status as a proxy for dose
dose_df <- df |>
  group_by(county_fe, grandfathered) |>
  summarise(
    prem_pre = median(premium[post_rr2 == 0], na.rm = TRUE),
    prem_post = median(premium[post_rr2 == 1], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(prem_change = prem_post - prem_pre,
         prem_change_pct = (prem_post - prem_pre) / prem_pre)

cat("\n=== Premium change by group ===\n")
dose_df |>
  group_by(grandfathered) |>
  summarise(
    mean_change = mean(prem_change, na.rm = TRUE),
    median_change = median(prem_change, na.rm = TRUE),
    mean_change_pct = mean(prem_change_pct, na.rm = TRUE)
  ) |>
  print()

## Merge dose back
df <- df |>
  left_join(dose_df |> select(county_fe, grandfathered, prem_change_pct),
            by = c("county_fe", "grandfathered"))

m_dose <- feols(lapsed ~ prem_change_pct:post_rr2 | county_fe + yq,
                data = df |> filter(grandfathered == 1),
                cluster = ~county_fe)
cat("\n=== Dose-response (among grandfathered) ===\n")
summary(m_dose)

## ============================================================
## E. Dropping top 2 states (FL, TX) to check not driven by them
## ============================================================

m_no_fl_tx <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                    data = df |> filter(!propertyState %in% c("FL", "TX")),
                    cluster = ~county_fe)
cat("\n=== Excluding FL and TX ===\n")
summary(m_no_fl_tx)

## ============================================================
## F. Save robustness objects
## ============================================================

rob_models <- list(
  placebo_xzone = m_placebo_x,
  placebo_time = m_placebo_time,
  state_cluster = m_state_cluster,
  dose_response = m_dose,
  no_fl_tx = m_no_fl_tx
)

saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))
saveRDS(df, file.path(data_dir, "fema_analysis.rds"))  # updated with dose

cat("\n=== Robustness checks complete ===\n")
