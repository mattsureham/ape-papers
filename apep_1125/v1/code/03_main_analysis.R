## 03_main_analysis.R — Main DiD estimation for apep_1125
## UK Breathing Space moratorium and personal insolvency

source("00_packages.R")

data_dir <- "data"
tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
scot <- readRDS(file.path(data_dir, "scotland_annual.rds"))

# ============================================================================
# Restrict sample: 303 matched LAs, 2015-2023
# ============================================================================
cat("=== Constructing analysis sample ===\n")

df <- panel %>%
  filter(!is.na(insolvency_rate), year >= 2015, year <= 2023) %>%
  mutate(la_id = as.factor(code),
         year_f = as.factor(year))

cat("Analysis sample:", nrow(df), "obs,", n_distinct(df$code), "LAs,",
    length(unique(df$year)), "years\n")

# Pre-treatment standard deviations (for SDE calculation)
pre_sds <- df %>%
  filter(year < 2021) %>%
  summarize(
    sd_insolvency = sd(insolvency_rate, na.rm = TRUE),
    sd_bankruptcy = sd(bankruptcy_rate, na.rm = TRUE),
    sd_dro = sd(dro_rate, na.rm = TRUE),
    sd_iva = sd(iva_rate, na.rm = TRUE),
    mean_insolvency = mean(insolvency_rate, na.rm = TRUE),
    mean_bankruptcy = mean(bankruptcy_rate, na.rm = TRUE),
    mean_dro = mean(dro_rate, na.rm = TRUE),
    mean_iva = mean(iva_rate, na.rm = TRUE)
  )

cat("\nPre-treatment summary (rates per 10K adults):\n")
cat("  Mean insolvency rate:", round(pre_sds$mean_insolvency, 2), "\n")
cat("  SD insolvency rate:", round(pre_sds$sd_insolvency, 2), "\n")
cat("  Mean bankruptcy rate:", round(pre_sds$mean_bankruptcy, 2), "\n")
cat("  Mean DRO rate:", round(pre_sds$mean_dro, 2), "\n")
cat("  Mean IVA rate:", round(pre_sds$mean_iva, 2), "\n")

# ============================================================================
# Design A: National E/W vs Scotland DiD
# ============================================================================
cat("\n=== Design A: National E/W vs Scotland DiD ===\n")

# Aggregate E/W to national level
ew_national <- df %>%
  group_by(year) %>%
  summarize(
    total = sum(total_insolvencies, na.rm = TRUE),
    pop = sum(adult_pop, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(rate = (total / pop) * 10000,
         nation = "ew")

# Scotland national data (need population for rate)
# Scotland adult pop ~4.4M (stable). Use ONS estimate.
scot_pop <- c(4350000, 4370000, 4390000, 4410000, 4420000, 4420000, 4420000, 4430000, 4440000)  # 2015-2023 approx
scot_nat <- scot %>%
  filter(year >= 2015, year <= 2023) %>%
  mutate(pop = scot_pop[1:n()],
         rate = (scot_total / pop) * 10000,
         nation = "scot") %>%
  select(year, total = scot_total, pop, rate, nation)

national <- bind_rows(ew_national, scot_nat) %>%
  mutate(treat = as.integer(nation == "ew"),
         post = as.integer(year >= 2021),
         treat_post = treat * post)

# Simple DiD
did_national <- lm(rate ~ treat + post + treat_post, data = national)
cat("National DiD (E/W vs Scotland):\n")
cat("  Treatment effect (beta):", round(coef(did_national)["treat_post"], 3), "\n")
cat("  SE:", round(summary(did_national)$coefficients["treat_post", "Std. Error"], 3), "\n")
cat("  p-value:", round(summary(did_national)$coefficients["treat_post", "Pr(>|t|)"], 3), "\n")

# ============================================================================
# Design B: Within E/W dose-response DiD
# ============================================================================
cat("\n=== Design B: Dose-response DiD (BS intensity) ===\n")

# Main specification: continuous BS intensity × post
# Y_it = alpha_i + gamma_t + beta * (BS_intensity_i * Post_t) + eps
mod1 <- feols(insolvency_rate ~ bs_intensity:post | la_id + year_f,
              data = df, cluster = ~la_id)

cat("Dose-response DiD (continuous):\n")
summary(mod1)

# Quartile specification: high-BS vs low-BS LAs
# Omit Q1 (lowest BS take-up) as reference
df$bs_q <- factor(df$bs_quartile)
mod2 <- feols(insolvency_rate ~ i(bs_q, post, ref = "1") | la_id + year_f,
              data = df, cluster = ~la_id)

cat("\nDose-response DiD (quartiles):\n")
summary(mod2)

# ============================================================================
# Design C: Event study by BS intensity quartile
# ============================================================================
cat("\n=== Design C: Event study ===\n")

# Event study: interaction of BS quartile with year dummies
# Reference: Q1 (lowest BS) and year 2020 (last pre-treatment)
df$event_yr <- factor(df$event_year)

mod_es <- feols(insolvency_rate ~ i(event_yr, bs_intensity, ref = "-1") | la_id + year_f,
                data = df, cluster = ~la_id)

cat("Event study (BS intensity × event year):\n")
summary(mod_es)

# ============================================================================
# By insolvency type
# ============================================================================
cat("\n=== By insolvency type ===\n")

mod_bankrupt <- feols(bankruptcy_rate ~ bs_intensity:post | la_id + year_f,
                      data = df, cluster = ~la_id)
mod_dro <- feols(dro_rate ~ bs_intensity:post | la_id + year_f,
                 data = df, cluster = ~la_id)
mod_iva <- feols(iva_rate ~ bs_intensity:post | la_id + year_f,
                 data = df, cluster = ~la_id)

cat("Bankruptcies:\n"); print(summary(mod_bankrupt))
cat("DROs:\n"); print(summary(mod_dro))
cat("IVAs:\n"); print(summary(mod_iva))

# ============================================================================
# Save results
# ============================================================================

# Collect key coefficients for tables
results <- list(
  national_did = did_national,
  dose_response = mod1,
  dose_quartile = mod2,
  event_study = mod_es,
  bankruptcy = mod_bankrupt,
  dro = mod_dro,
  iva = mod_iva,
  pre_sds = pre_sds,
  n_la = n_distinct(df$code),
  n_obs = nrow(df),
  national_data = national
)

saveRDS(results, file.path(data_dir, "results.rds"))

# Write diagnostics.json
n_pre_years <- length(unique(df$year[df$year < 2021]))
diagnostics <- list(
  n_treated = n_distinct(df$code),
  n_pre = n_pre_years,
  n_obs = nrow(df),
  n_la = n_distinct(df$code),
  n_years = length(unique(df$year)),
  pre_sd_insolvency = round(pre_sds$sd_insolvency, 4),
  pre_mean_insolvency = round(pre_sds$mean_insolvency, 4)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Results saved ===\n")
cat("diagnostics.json written with n_treated =", diagnostics$n_treated,
    ", n_pre =", diagnostics$n_pre, ", n_obs =", diagnostics$n_obs, "\n")
