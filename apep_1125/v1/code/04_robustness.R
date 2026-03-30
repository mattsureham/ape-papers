## 04_robustness.R — Robustness checks for apep_1125
## UK Breathing Space and personal insolvency

source("00_packages.R")

data_dir <- "data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
scot <- readRDS(file.path(data_dir, "scotland_annual.rds"))

# Restrict to analysis sample
df <- panel %>%
  filter(!is.na(insolvency_rate), year >= 2015, year <= 2023) %>%
  mutate(la_id = as.factor(code),
         year_f = as.factor(year))

cat("=== Robustness checks ===\n")

# ============================================================================
# 1. Pre-treatment intensity measure (avoids endogeneity)
# ============================================================================
cat("\n--- R1: Pre-treatment intensity (2015-2019 avg insolvency rate) ---\n")

pre_intensity <- df %>%
  filter(year >= 2015, year <= 2019) %>%
  group_by(code) %>%
  summarize(pre_insolvency = mean(insolvency_rate, na.rm = TRUE),
            pre_claimant = mean(claimant_rate, na.rm = TRUE),
            .groups = "drop")

df <- df %>%
  left_join(pre_intensity, by = "code")

# Use pre-treatment insolvency rate as (exogenous) dose
df$pre_ins_quartile <- ntile(df$pre_insolvency, 4)

mod_pre_dose <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                      data = df, cluster = ~la_id)
cat("Pre-treatment dose-response:\n")
summary(mod_pre_dose)

# Decomposition with pre-treatment dose
mod_pre_bankrupt <- feols(bankruptcy_rate ~ pre_insolvency:post | la_id + year_f,
                          data = df, cluster = ~la_id)
mod_pre_iva <- feols(iva_rate ~ pre_insolvency:post | la_id + year_f,
                     data = df, cluster = ~la_id)
mod_pre_dro <- feols(dro_rate ~ pre_insolvency:post | la_id + year_f,
                     data = df, cluster = ~la_id)

cat("\nPre-treatment dose — Bankruptcies:\n"); summary(mod_pre_bankrupt)
cat("\nPre-treatment dose — IVAs:\n"); summary(mod_pre_iva)
cat("\nPre-treatment dose — DROs:\n"); summary(mod_pre_dro)

# Event study with pre-treatment intensity
df$event_yr <- factor(df$year - 2021)
mod_es_pre <- feols(insolvency_rate ~ i(event_yr, pre_insolvency, ref = "-1") | la_id + year_f,
                    data = df, cluster = ~la_id)
cat("\nEvent study (pre-treatment intensity):\n")
summary(mod_es_pre)

# ============================================================================
# 2. Placebo test at 2018 (pre-Breathing Space)
# ============================================================================
cat("\n--- R2: Placebo test (treatment at 2018) ---\n")

df_placebo <- df %>%
  filter(year <= 2020) %>%
  mutate(post_2018 = as.integer(year >= 2018))

mod_placebo <- feols(insolvency_rate ~ pre_insolvency:post_2018 | la_id + year_f,
                     data = df_placebo, cluster = ~la_id)
cat("Placebo (2018 cutoff):\n"); summary(mod_placebo)

# ============================================================================
# 3. Exclude 2020 (COVID year)
# ============================================================================
cat("\n--- R3: Exclude 2020 ---\n")

df_no2020 <- df %>% filter(year != 2020)
mod_no2020 <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                    data = df_no2020, cluster = ~la_id)
cat("Exclude 2020:\n"); summary(mod_no2020)

mod_no2020_bank <- feols(bankruptcy_rate ~ pre_insolvency:post | la_id + year_f,
                         data = df_no2020, cluster = ~la_id)
mod_no2020_iva <- feols(iva_rate ~ pre_insolvency:post | la_id + year_f,
                        data = df_no2020, cluster = ~la_id)
cat("Exclude 2020 — Bankruptcies:\n"); summary(mod_no2020_bank)
cat("Exclude 2020 — IVAs:\n"); summary(mod_no2020_iva)

# ============================================================================
# 4. Simple pre/post comparison for E/W aggregate
# ============================================================================
cat("\n--- R4: Simple pre/post aggregate comparison ---\n")

agg <- df %>%
  mutate(period = ifelse(year < 2021, "Pre (2015-2020)", "Post (2021-2023)")) %>%
  group_by(period) %>%
  summarize(
    mean_total = mean(insolvency_rate, na.rm = TRUE),
    mean_bankrupt = mean(bankruptcy_rate, na.rm = TRUE),
    mean_dro = mean(dro_rate, na.rm = TRUE),
    mean_iva = mean(iva_rate, na.rm = TRUE),
    .groups = "drop"
  )
cat("E/W aggregate pre/post means (per 10K adults):\n")
print(agg)

cat("\nChanges:\n")
pre_row <- agg %>% filter(grepl("Pre", period))
post_row <- agg %>% filter(grepl("Post", period))
cat("  Total:", round(post_row$mean_total - pre_row$mean_total, 2), "\n")
cat("  Bankruptcy:", round(post_row$mean_bankrupt - pre_row$mean_bankrupt, 2), "\n")
cat("  DRO:", round(post_row$mean_dro - pre_row$mean_dro, 2), "\n")
cat("  IVA:", round(post_row$mean_iva - pre_row$mean_iva, 2), "\n")

# ============================================================================
# 5. Scotland comparison: decomposition
# ============================================================================
cat("\n--- R5: Scotland decomposition ---\n")

# Scotland: bankruptcies (sequestrations + LILA/MAP) and PTDs
scot_comparison <- scot %>%
  filter(year >= 2015, year <= 2023) %>%
  mutate(period = ifelse(year < 2021, "Pre", "Post")) %>%
  group_by(period) %>%
  summarize(
    mean_total = mean(scot_total),
    mean_bankrupt = mean(scot_bankrupt),
    mean_ptds = mean(scot_ptds),
    .groups = "drop"
  )
cat("Scotland pre/post comparison (counts):\n")
print(scot_comparison)

# ============================================================================
# 6. Regional variation check
# ============================================================================
cat("\n--- R6: Regional heterogeneity ---\n")

# Add region from geog hierarchy
# English regions start with E12... We can extract from name patterns
df_london <- df %>% filter(geog_type == "London Borough")
df_metro <- df %>% filter(geog_type == "Metropolitan District")
df_nonmetro <- df %>% filter(geog_type == "Non-metropolitan District")
df_unitary <- df %>% filter(geog_type == "Unitary Authority")

mod_london <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                    data = df_london, cluster = ~la_id)
mod_metro <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                   data = df_metro, cluster = ~la_id)

cat("London Boroughs:\n"); summary(mod_london)
cat("Metropolitan Districts:\n"); summary(mod_metro)

# ============================================================================
# Save all robustness results
# ============================================================================

robustness <- list(
  pre_dose = mod_pre_dose,
  pre_dose_bankrupt = mod_pre_bankrupt,
  pre_dose_iva = mod_pre_iva,
  pre_dose_dro = mod_pre_dro,
  event_study_pre = mod_es_pre,
  placebo = mod_placebo,
  no2020 = mod_no2020,
  no2020_bank = mod_no2020_bank,
  no2020_iva = mod_no2020_iva,
  aggregate = agg,
  scotland_comparison = scot_comparison
)

saveRDS(robustness, file.path(data_dir, "robustness.rds"))
cat("\n=== Robustness results saved ===\n")
