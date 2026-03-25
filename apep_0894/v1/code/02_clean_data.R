# =============================================================================
# 02_clean_data.R — Variable construction
# apep_0894: CFPB Payday Lending Rule and Credit-Sector Labor Markets
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
treatment <- readRDS("../data/treatment_intensity.rds")

# --- 1. Create time variables ----------------------------------------------

df <- df %>%
  mutate(
    year = as.integer(year),
    quarter = as.integer(quarter),
    # Calendar quarter index (2014Q1 = 1)
    cal_quarter = (year - 2014) * 4 + quarter,
    # Treatment timing: compliance date Aug 19, 2019 → Q3 2019 = cal_quarter 23
    post_compliance = as.integer(cal_quarter >= 23),  # 2019Q3+
    # Rescission effective Sept 3, 2020 → Q3 2020 = cal_quarter 27
    post_rescission = as.integer(cal_quarter >= 27),  # 2020Q3+
    # Event time relative to compliance quarter (2019Q3 = 0)
    event_time = cal_quarter - 23
  )

# --- 2. Separate NAICS 522 (treatment) and 5221 (placebo) -----------------

df_522 <- df %>% filter(industry == "522")
df_523 <- df %>% filter(industry == "523")

cat(sprintf("NAICS 522 panel: %d obs, %d counties\n",
            nrow(df_522), n_distinct(df_522$fips)))
cat(sprintf("NAICS 523 (placebo) panel: %d obs, %d counties\n",
            nrow(df_523), n_distinct(df_523$fips)))

# --- 3. Treatment quartiles -----------------------------------------------

# Classify counties by payday density quartile
quartiles <- quantile(treatment$payday_density[treatment$payday_density > 0],
                       probs = c(0.25, 0.5, 0.75), na.rm = TRUE)

df_522 <- df_522 %>%
  mutate(
    density_quartile = case_when(
      payday_density == 0 ~ "Q0_none",
      payday_density <= quartiles[1] ~ "Q1_low",
      payday_density <= quartiles[2] ~ "Q2_med",
      payday_density <= quartiles[3] ~ "Q3_high",
      TRUE ~ "Q4_top"
    ),
    high_density = as.integer(density_quartile == "Q4_top"),
    any_payday = as.integer(payday_density > 0)
  )

cat(sprintf("Density quartile cutpoints: Q1=%.3f, Q2=%.3f, Q3=%.3f\n",
            quartiles[1], quartiles[2], quartiles[3]))
cat("Counties by quartile:\n")
print(table(df_522 %>% distinct(fips, density_quartile) %>% pull(density_quartile)))

# --- 4. Outcome winsorization (1st/99th percentile) -----------------------

winsorize <- function(x, p = 0.01) {
  q <- quantile(x, probs = c(p, 1 - p), na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}

df_522 <- df_522 %>%
  mutate(
    across(c(EmpEnd, HirN, Sep, EarnS), ~ winsorize(.x), .names = "{.col}_w")
  )

# --- 5. Log outcomes (for elasticity interpretation) -----------------------

df_522 <- df_522 %>%
  mutate(
    ln_emp = log(pmax(EmpEnd, 1)),
    ln_hire = log(pmax(HirN, 1)),
    ln_sep = log(pmax(Sep, 1)),
    ln_earn = log(pmax(EarnS, 1))
  )

# --- 6. Pre-treatment outcome standard deviations (for SDE) ---------------

pre_sds <- df_522 %>%
  filter(post_compliance == 0) %>%
  summarise(
    sd_emp = sd(EmpEnd, na.rm = TRUE),
    sd_hire = sd(HirN, na.rm = TRUE),
    sd_sep = sd(Sep, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    sd_ln_emp = sd(ln_emp, na.rm = TRUE),
    sd_ln_hire = sd(ln_hire, na.rm = TRUE),
    mean_emp = mean(EmpEnd, na.rm = TRUE),
    mean_hire = mean(HirN, na.rm = TRUE),
    mean_sep = mean(Sep, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE)
  )

cat("\nPre-treatment outcome summary:\n")
print(pre_sds)

# --- 7. Save ---------------------------------------------------------------

saveRDS(df_522, "../data/panel_522.rds")
saveRDS(df_523, "../data/panel_523.rds")
saveRDS(pre_sds, "../data/pre_sds.rds")

cat("\nCleaned panels saved.\n")
