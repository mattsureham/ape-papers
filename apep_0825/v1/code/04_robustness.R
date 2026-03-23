## 04_robustness.R — Robustness checks and placebos
## apep_0825: Networked Backlash in Sweden

source("00_packages.R")

DATA_DIR <- "../data"
df <- read_csv(file.path(DATA_DIR, "analysis.csv"), show_col_types = FALSE)

## ============================================================================
## 1. PLACEBO: Pre-Bosättningslagen SD change (2010→2014) on treatment
## ============================================================================

cat("\n=== PLACEBO: 2010→2014 (pre-treatment) ===\n")

# If treatment truly comes from 2016 Bosättningslagen, the 2010→2014
# SD change should NOT correlate with the 2014→2017 refugee allocation

p1 <- feols(delta_sd_1014 ~ delta_fnoneu + sd_2014 + fnoneu_2014 + log_pop,
            cluster = ~nuts3, data = df %>% filter(!is.na(delta_sd_1014)))

cat("Placebo own exposure:\n")
summary(p1)

# Network placebo
p2 <- feols(delta_sd_1014 ~ network_exposure + delta_fnoneu +
              sd_2014 + fnoneu_2014 + log_pop,
            cluster = ~nuts3, data = df %>% filter(!is.na(delta_sd_1014)))

cat("\nPlacebo network exposure:\n")
summary(p2)

saveRDS(list(p1 = p1, p2 = p2), file.path(DATA_DIR, "placebo_models.rds"))

## ============================================================================
## 2. ALTERNATIVE TREATMENT: Total foreign-born (not just non-EU)
## ============================================================================

cat("\n=== ALTERNATIVE TREATMENT: Total foreign-born change ===\n")

a1 <- feols(delta_sd_1418 ~ delta_fborn + sd_2014 + fb_2014 + log_pop,
            cluster = ~nuts3, data = df)

cat("Total foreign-born treatment:\n")
summary(a1)

saveRDS(a1, file.path(DATA_DIR, "alt_treatment_model.rds"))

## ============================================================================
## 3. COUNTY FIXED EFFECTS (absorb county-level shocks)
## ============================================================================

cat("\n=== COUNTY FIXED EFFECTS ===\n")

# This tests within-county variation: municipalities in the same county
# with different refugee exposure
fe1 <- feols(delta_sd_1418 ~ delta_fnoneu + sd_2014 + fnoneu_2014 + log_pop |
               nuts3, cluster = ~nuts3, data = df)

cat("County FE (own exposure):\n")
summary(fe1)

saveRDS(fe1, file.path(DATA_DIR, "county_fe_model.rds"))

## ============================================================================
## 4. EXCLUDING MAJOR CITIES (Stockholm, Gothenburg, Malmö)
## ============================================================================

cat("\n=== EXCLUDING MAJOR CITIES ===\n")

big3 <- c("0180", "1480", "1280")  # Stockholm, Gothenburg, Malmö
df_nob3 <- df %>% filter(!(muni_code %in% big3))

e1 <- feols(delta_sd_1418 ~ network_exposure + delta_fnoneu +
              sd_2014 + fnoneu_2014 + log_pop,
            cluster = ~nuts3, data = df_nob3)

cat("Excluding big 3:\n")
summary(e1)

saveRDS(e1, file.path(DATA_DIR, "excl_big3_model.rds"))

## ============================================================================
## 5. POPULATION-WEIGHTED REGRESSIONS
## ============================================================================

cat("\n=== POPULATION-WEIGHTED ===\n")

w1 <- feols(delta_sd_1418 ~ network_exposure + delta_fnoneu +
              sd_2014 + fnoneu_2014 + log_pop,
            weights = ~pop_2014, cluster = ~nuts3, data = df)

cat("Population-weighted:\n")
summary(w1)

saveRDS(w1, file.path(DATA_DIR, "pop_weighted_model.rds"))

## ============================================================================
## 6. NON-LINEAR TREATMENT EFFECTS (quartiles)
## ============================================================================

cat("\n=== NON-LINEAR TREATMENT ===\n")

df <- df %>%
  mutate(
    treat_q = ntile(delta_fnoneu, 4),
    treat_q = factor(treat_q, labels = c("Q1 (low)", "Q2", "Q3", "Q4 (high)"))
  )

q1 <- feols(delta_sd_1418 ~ treat_q + sd_2014 + fnoneu_2014 + log_pop,
            cluster = ~nuts3, data = df)

cat("Treatment quartiles:\n")
summary(q1)

saveRDS(q1, file.path(DATA_DIR, "quartile_model.rds"))

## ============================================================================
## 7. 2018→2022 PERSISTENCE
## ============================================================================

cat("\n=== PERSISTENCE: 2018→2022 ===\n")

# sd_2022 and sd_2018 already in the dataset from 02_clean_data.R
df_persist <- df %>%
  mutate(delta_sd_1822 = as.numeric(sd_2022) - as.numeric(sd_2018))

persist1 <- feols(delta_sd_1822 ~ network_exposure + delta_fnoneu +
                    sd_2014 + fnoneu_2014 + log_pop,
                  cluster = ~nuts3,
                  data = df_persist %>% filter(!is.na(delta_sd_1822)))

cat("Persistence (2018→2022):\n")
summary(persist1)

saveRDS(persist1, file.path(DATA_DIR, "persistence_model.rds"))

cat("\n=== ALL ROBUSTNESS CHECKS COMPLETE ===\n")
