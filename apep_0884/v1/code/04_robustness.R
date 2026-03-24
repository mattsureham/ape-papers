## 04_robustness.R — Robustness checks and placebo tests
## APEP-0884: The World's Highest Minimum Wage

source("00_packages.R")

panel <- readRDS("../data/panel_statent.rds")
results <- readRDS("../data/main_results.rds")

ge_code <- panel %>% filter(grepl("Gen", canton_name)) %>% pull(canton_code) %>% unique()
vd_code <- panel %>% filter(grepl("Vaud", canton_name)) %>% pull(canton_code) %>% unique()

# Prepare analysis data (same as main)
df <- panel %>%
  filter(canton_code %in% c(ge_code, vd_code)) %>%
  filter(!is.na(employment), employment > 0,
         !is.na(establishments), establishments > 0) %>%
  mutate(
    log_emp = log(employment),
    log_est = log(establishments),
    log_fte = log(fte + 1),
    high_bite = as.integer(bite_group == "high_bite"),
    geneva_post_high = geneva * post * high_bite,
    canton_noga = factor(canton_noga),
    canton_year_fe = factor(canton_year),
    noga_year_fe = factor(noga_year),
    event_time = year - 2020,
    ge_high = geneva * high_bite
  )

# ============================================================================
# Robustness 1: Placebo treatment (Finance/Pharma as "placebo high-bite")
# If results were driven by differential canton-level shocks, finance should
# show a similar pattern
# ============================================================================

cat("=== Robustness 1: Placebo High-Bite (Finance/Pharma) ===\n")

df_placebo <- df %>%
  mutate(
    placebo_high = as.integer(bite_group == "low_bite"),
    geneva_post_placebo = geneva * post * placebo_high
  )

placebo_emp <- feols(log_emp ~ geneva_post_placebo |
                       canton_noga + canton_year_fe + noga_year_fe,
                     data = df_placebo,
                     cluster = ~canton_noga)

cat("Placebo DDD (low-bite as treated):\n")
summary(placebo_emp)

# ============================================================================
# Robustness 2: Broader control group (include Fribourg, Valais)
# ============================================================================

cat("\n=== Robustness 2: Broader control group ===\n")

neighbor_codes <- panel %>%
  filter(grepl("Fribourg|Valais", canton_name)) %>%
  pull(canton_code) %>%
  unique()

df_broad <- panel %>%
  filter(canton_code %in% c(ge_code, vd_code, neighbor_codes)) %>%
  filter(!is.na(employment), employment > 0,
         !is.na(establishments), establishments > 0) %>%
  mutate(
    log_emp = log(employment),
    log_est = log(establishments),
    high_bite = as.integer(bite_group == "high_bite"),
    geneva_post_high = geneva * post * high_bite,
    canton_noga = factor(paste0(canton_code, "_", noga2)),
    canton_year_fe = factor(paste0(canton_code, "_", year)),
    noga_year_fe = factor(paste0(noga2, "_", year))
  )

broad_emp <- feols(log_emp ~ geneva_post_high |
                     canton_noga + canton_year_fe + noga_year_fe,
                   data = df_broad,
                   cluster = ~canton_noga)

broad_est <- feols(log_est ~ geneva_post_high |
                     canton_noga + canton_year_fe + noga_year_fe,
                   data = df_broad,
                   cluster = ~canton_noga)

cat("Broader control DDD Employment:\n")
summary(broad_emp)
cat("\nBroader control DDD Establishments:\n")
summary(broad_est)

# ============================================================================
# Robustness 3: Leave-one-sector-out
# Check if results are driven by a single NOGA sector
# ============================================================================

cat("\n=== Robustness 3: Leave-one-sector-out ===\n")

high_bite_sectors <- unique(df$noga2[df$high_bite == 1])
loso_results <- data.frame()

for (drop_sector in high_bite_sectors) {
  df_loso <- df %>% filter(noga2 != drop_sector)
  loso_mod <- feols(log_emp ~ geneva_post_high |
                      canton_noga + canton_year_fe + noga_year_fe,
                    data = df_loso,
                    cluster = ~canton_noga)
  loso_results <- bind_rows(loso_results, data.frame(
    dropped_sector = drop_sector,
    coef = coef(loso_mod)["geneva_post_high"],
    se = se(loso_mod)["geneva_post_high"]
  ))
}

cat("Leave-one-sector-out results:\n")
print(loso_results)

# ============================================================================
# Robustness 4: Different post-period definitions
# ============================================================================

cat("\n=== Robustness 4: Different post-period definitions ===\n")

# Post = 2022+ (excluding COVID year 2020 and transition year 2021)
df_late <- df %>%
  filter(year <= 2019 | year >= 2022) %>%
  mutate(
    post_late = as.integer(year >= 2022),
    gph_late = geneva * post_late * high_bite,
    canton_year_fe = factor(paste0(canton_code, "_", year)),
    noga_year_fe = factor(paste0(noga2, "_", year))
  )

late_emp <- feols(log_emp ~ gph_late |
                    canton_noga + canton_year_fe + noga_year_fe,
                  data = df_late,
                  cluster = ~canton_noga)

cat("Late post (2022+) DDD Employment:\n")
summary(late_emp)

# Post = 2021 only (immediate effect)
df_2021 <- df %>%
  filter(year <= 2019 | year == 2021) %>%
  mutate(
    post_2021 = as.integer(year == 2021),
    gph_2021 = geneva * post_2021 * high_bite,
    canton_year_fe = factor(paste0(canton_code, "_", year)),
    noga_year_fe = factor(paste0(noga2, "_", year))
  )

imm_emp <- feols(log_emp ~ gph_2021 |
                   canton_noga + canton_year_fe + noga_year_fe,
                 data = df_2021,
                 cluster = ~canton_noga)

cat("Immediate (2021 only) DDD Employment:\n")
summary(imm_emp)

# ============================================================================
# Robustness 5: Placebo treatment year (2017)
# ============================================================================

cat("\n=== Robustness 5: Placebo year (2017) ===\n")

df_placebo_yr <- df %>%
  filter(year <= 2019) %>%  # Only pre-treatment years
  mutate(
    post_placebo = as.integer(year >= 2017),
    gph_placebo = geneva * post_placebo * high_bite,
    canton_year_fe = factor(paste0(canton_code, "_", year)),
    noga_year_fe = factor(paste0(noga2, "_", year))
  )

placebo_yr_emp <- feols(log_emp ~ gph_placebo |
                          canton_noga + canton_year_fe + noga_year_fe,
                        data = df_placebo_yr,
                        cluster = ~canton_noga)

cat("Placebo year (2017) DDD Employment:\n")
summary(placebo_yr_emp)

# ============================================================================
# Robustness 6: Levels instead of logs
# ============================================================================

cat("\n=== Robustness 6: Levels specification ===\n")

levels_emp <- feols(employment ~ geneva_post_high |
                      canton_noga + canton_year_fe + noga_year_fe,
                    data = df,
                    cluster = ~canton_noga)

cat("Levels DDD Employment:\n")
summary(levels_emp)

# ============================================================================
# Robustness 7: Randomization Inference (Permutation Test)
# Permute the "Geneva" indicator across all available cantons
# to generate the null distribution of the DDD coefficient
# ============================================================================

cat("\n=== Robustness 7: Randomization Inference ===\n")

# Use the broader panel (6 cantons) for permutation
all_cantons <- unique(panel$canton_code[!is.na(panel$employment) & panel$employment > 0])

# For each permutation, assign one canton as "treated"
set.seed(20260324)
n_perms <- 500
ri_coefs <- numeric(n_perms)
actual_coef <- coef(results$ddd_emp)["geneva_post_high"]

df_ri_base <- panel %>%
  filter(!is.na(employment), employment > 0,
         !is.na(establishments), establishments > 0) %>%
  mutate(
    log_emp = log(employment),
    high_bite = as.integer(bite_group == "high_bite"),
    noga2_num = noga2
  )

# For each permutation, pick 2 random cantons as the "pair" and one as "treated"
for (perm in seq_len(n_perms)) {
  # Randomly select 2 cantons
  pair <- sample(all_cantons, 2)
  treated_canton <- pair[1]

  df_perm <- df_ri_base %>%
    filter(canton_code %in% pair) %>%
    mutate(
      perm_geneva = as.integer(canton_code == treated_canton),
      perm_post = as.integer(year >= 2021),
      perm_gph = perm_geneva * perm_post * high_bite,
      perm_cn = factor(paste0(canton_code, "_", noga2)),
      perm_cy = factor(paste0(canton_code, "_", year)),
      perm_ny = factor(paste0(noga2, "_", year))
    )

  perm_mod <- tryCatch(
    feols(log_emp ~ perm_gph | perm_cn + perm_cy + perm_ny,
          data = df_perm, warn = FALSE, notes = FALSE),
    error = function(e) NULL
  )

  if (!is.null(perm_mod) && "perm_gph" %in% names(coef(perm_mod))) {
    ri_coefs[perm] <- coef(perm_mod)["perm_gph"]
  } else {
    ri_coefs[perm] <- NA
  }
}

ri_coefs_clean <- ri_coefs[!is.na(ri_coefs)]
ri_p_value <- mean(abs(ri_coefs_clean) >= abs(actual_coef))

cat("Randomization Inference Results:\n")
cat("  Actual DDD coefficient:", round(actual_coef, 4), "\n")
cat("  Permutations completed:", length(ri_coefs_clean), "\n")
cat("  RI p-value (two-sided):", round(ri_p_value, 3), "\n")
cat("  Null distribution: mean=", round(mean(ri_coefs_clean), 4),
    ", sd=", round(sd(ri_coefs_clean), 4), "\n")

# Save RI results
ri_results <- list(
  actual_coef = actual_coef,
  ri_p_value = ri_p_value,
  n_perms = length(ri_coefs_clean),
  null_mean = mean(ri_coefs_clean),
  null_sd = sd(ri_coefs_clean)
)

# ============================================================================
# Save robustness results
# ============================================================================

robustness <- list(
  placebo_sector = placebo_emp,
  broad_control_emp = broad_emp,
  broad_control_est = broad_est,
  loso = loso_results,
  late_post = late_emp,
  immediate = imm_emp,
  placebo_year = placebo_yr_emp,
  levels = levels_emp,
  ri = ri_results
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== All robustness checks complete ===\n")
