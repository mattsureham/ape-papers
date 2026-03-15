## 04_robustness.R — Robustness and additional specifications
## apep_0696: FPM fiscal windfalls and agricultural expansion in Brazil
##
## Tests:
##   1. Panel DiD: municipalities crossing thresholds between 2000-2010 censuses
##   2. OLS with municipality FE (within-municipality variation)
##   3. Density test per threshold (test manipulation individually)
##   4. Heterogeneity by Amazon vs non-Amazon states

library(tidyverse)
library(fixest)
library(rddensity)
library(jsonlite)

# Run from the v1/ directory (e.g., Rscript code/$(basename $0))

cat("=== Robustness Analysis for apep_0696 ===\n")

## ─────────────────────────────────────────────────────────────────────────────
## Load data
## ─────────────────────────────────────────────────────────────────────────────
df_panel   <- read_csv("data/panel_clean.csv",
                       col_types = cols(mun_code = col_character()))
df_cross   <- read_csv("data/cross_section_rdd.csv",
                       col_types = cols(mun_code = col_character()))
df_stacked <- read_csv("data/stacked_multicutoff.csv",
                       col_types = cols(mun_code = col_character()))
fpm_sched  <- read_csv("data/fpm_schedule.csv")
pop_all    <- read_csv("data/population.csv",
                       col_types = cols(mun_code = col_character()))

# Load main results
models <- readRDS("data/models.rds")
h_opt  <- models$h_opt
rdd3_coef <- models$rdd3_coef
rdd3_se   <- models$rdd3_se

fpm_thresholds <- fpm_sched$pop_min[-1]

## ─────────────────────────────────────────────────────────────────────────────
## Helper: assign FPM coefficient from population
## ─────────────────────────────────────────────────────────────────────────────
assign_fpm <- function(pop, fpm_sched) {
  bracket <- findInterval(pop, c(0, fpm_sched$pop_min[-1]))
  fpm_sched$coeff[bracket]
}

## ─────────────────────────────────────────────────────────────────────────────
## 1. Panel DiD: municipalities crossing thresholds between 2000-2010
##    These municipalities received discrete FPM increases
##    Compare vs municipalities that stayed in same bracket
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 1: Panel DiD — Threshold Crossers 2000→2010 ---\n")

# Get pop in both censuses
pop_2000 <- pop_all %>% filter(year == 2000) %>%
  transmute(mun_code, pop_2000 = pop,
            bracket_2000 = findInterval(pop, c(0, fpm_thresholds)),
            coeff_2000 = assign_fpm(pop, fpm_sched))

pop_2010 <- pop_all %>% filter(year == 2010) %>%
  transmute(mun_code, pop_2010 = pop,
            bracket_2010 = findInterval(pop, c(0, fpm_thresholds)),
            coeff_2010 = assign_fpm(pop, fpm_sched))

# Merge to identify crossers
crossers <- pop_2000 %>%
  inner_join(pop_2010, by = "mun_code") %>%
  mutate(
    bracket_change = bracket_2010 - bracket_2000,
    coeff_change   = coeff_2010 - coeff_2000,
    crossed_up     = as.integer(bracket_change > 0),  # moved to higher bracket
    crossed_down   = as.integer(bracket_change < 0),  # moved to lower bracket (rare)
    stayed         = as.integer(bracket_change == 0)
  )

cat("Municipalities crossing UP:", sum(crossers$crossed_up), "\n")
cat("Municipalities staying same:", sum(crossers$stayed), "\n")
cat("Municipalities crossing DOWN:", sum(crossers$crossed_down), "\n")

# Panel: merge crosser information with crop area panel
df_did <- df_panel %>%
  inner_join(crossers, by = "mun_code") %>%
  mutate(
    post_2010 = as.integer(year >= 2010),
    treat     = crossed_up,  # treated = crossed UP to higher bracket
    treat_post = treat * post_2010,
    # How many brackets did they cross? (treatment intensity)
    n_brackets_crossed = pmax(0, bracket_change)
  )

cat("\nPanel DiD observations:", nrow(df_did), "\n")
cat("Treated municipalities:", n_distinct(df_did$mun_code[df_did$treat == 1]), "\n")
cat("Control municipalities:", n_distinct(df_did$mun_code[df_did$treat == 0]), "\n")

# DiD: did municipalities that crossed thresholds expand crop area more?
did1 <- feols(
  log_crop_area ~ treat_post | mun_code + year,
  data = df_did %>% filter(stayed == 1 | crossed_up == 1),
  cluster = ~mun_code
)

cat("\nPanel DiD (crossers vs non-crossers):\n")
print(summary(did1))
did1_coef <- coef(did1)["treat_post"]
did1_se   <- se(did1)["treat_post"]

# Intensive margin: effect per bracket crossed
did2 <- feols(
  log_crop_area ~ I(n_brackets_crossed * post_2010) | mun_code + year,
  data = df_did %>% filter(stayed == 1 | crossed_up == 1),
  cluster = ~mun_code
)
cat("\nPanel DiD (intensive margin):\n")
print(summary(did2))
did2_coef <- coef(did2)[1]
did2_se   <- se(did2)[1]

## ─────────────────────────────────────────────────────────────────────────────
## 2. Density test per threshold
##    Quantify manipulation at each individual FPM threshold
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 2: Density test per threshold ---\n")

density_per_threshold <- list()
for (k in seq_along(fpm_thresholds)) {
  thresh_k <- fpm_thresholds[k]
  pop_k <- pop_all %>%
    filter(year == 2000) %>%
    mutate(run_var = (pop - thresh_k) / thresh_k) %>%
    filter(abs(run_var) <= 0.5)

  dt <- tryCatch({
    rddensity(X = pop_k$run_var, c = 0)$test$p_jk
  }, error = function(e) NA)

  density_per_threshold[[k]] <- data.frame(
    threshold = thresh_k, k = k, p_value = dt
  )
  cat(sprintf("  Threshold %d (pop=%d): p=%.4f\n", k, thresh_k,
              ifelse(is.na(dt), NA, dt)))
}
density_per_threshold_df <- bind_rows(density_per_threshold)

n_sig_density <- sum(density_per_threshold_df$p_value < 0.05, na.rm = TRUE)
cat(sprintf("  %d of 17 thresholds show manipulation (p<0.05)\n", n_sig_density))

## ─────────────────────────────────────────────────────────────────────────────
## 3. Heterogeneity: Amazon states vs other states
##    If FPM drives deforestation, effect should be larger in Amazon biome
##    Amazon states: AC, AM, AP, PA, RO, RR, TO (codes 12,13,14,15,16,11,17)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 3: Heterogeneity by biome (Amazon vs other) ---\n")

amazon_states <- c("11", "12", "13", "14", "15", "16", "17")

df_stacked_bw <- models$df_stacked_bw %>%
  mutate(
    state_code = substr(mun_code, 1, 2),
    amazon = as.integer(state_code %in% amazon_states),
    above_k_num = as.numeric(above_k)
  )

cat("Amazon municipalities in sample:", sum(df_stacked_bw$amazon), "\n")
cat("Non-Amazon municipalities:", sum(1 - df_stacked_bw$amazon), "\n")

# Amazon subgroup
if (sum(df_stacked_bw$amazon) >= 50) {
  rdd_amazon <- feols(
    avg_log_crop ~ above_k_num +
      run_var_k:I(above_k_num == 0) +
      run_var_k:I(above_k_num == 1) | k_index,
    data = df_stacked_bw %>% filter(amazon == 1),
    weights = ~w_tri,
    cluster = ~mun_code
  )
  amazon_coef <- coef(rdd_amazon)["above_k_num"]
  amazon_se   <- se(rdd_amazon)["above_k_num"]
  cat(sprintf("  Amazon: %.4f (SE: %.4f)\n", amazon_coef, amazon_se))
} else {
  amazon_coef <- amazon_se <- NA
}

# Non-Amazon subgroup
rdd_nonamazon <- feols(
  avg_log_crop ~ above_k_num +
    run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = df_stacked_bw %>% filter(amazon == 0),
  weights = ~w_tri,
  cluster = ~mun_code
)
nonamazon_coef <- coef(rdd_nonamazon)["above_k_num"]
nonamazon_se   <- se(rdd_nonamazon)["above_k_num"]
cat(sprintf("  Non-Amazon: %.4f (SE: %.4f)\n", nonamazon_coef, nonamazon_se))

## ─────────────────────────────────────────────────────────────────────────────
## 4. Leave-one-threshold-out sensitivity
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 4: Leave-one-threshold-out ---\n")

loo_results <- list()
for (k_drop in 1:17) {
  df_k <- df_stacked_bw %>%
    filter(k_index != k_drop) %>%
    mutate(above_k_num = as.numeric(above_k))

  fit <- tryCatch(feols(
    avg_log_crop ~ above_k_num +
      run_var_k:I(above_k_num == 0) +
      run_var_k:I(above_k_num == 1) | k_index,
    data = df_k, weights = ~w_tri, cluster = ~mun_code
  ), error = function(e) NULL)

  if (!is.null(fit)) {
    loo_results[[k_drop]] <- data.frame(
      k_dropped = k_drop,
      coef = coef(fit)["above_k_num"],
      se = se(fit)["above_k_num"]
    )
  }
}

loo_df <- bind_rows(loo_results)
cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_df$coef), max(loo_df$coef)))
cat(sprintf("  All negative: %s\n", all(loo_df$coef < 0)))

## ─────────────────────────────────────────────────────────────────────────────
## Save robustness results
## ─────────────────────────────────────────────────────────────────────────────
rob_results <- list(
  did1_coef = did1_coef, did1_se = did1_se,
  did2_coef = did2_coef, did2_se = did2_se,
  n_crossers = sum(crossers$crossed_up),
  n_staying  = sum(crossers$stayed),
  density_per_threshold = density_per_threshold_df,
  n_sig_density = n_sig_density,
  amazon_coef = amazon_coef, amazon_se = amazon_se,
  nonamazon_coef = nonamazon_coef, nonamazon_se = nonamazon_se,
  loo_df = loo_df
)
saveRDS(rob_results, "data/robustness_results.rds")

# Also save model objects for tables
saveRDS(list(did1 = did1, did2 = did2,
             rdd_amazon = if (exists("rdd_amazon")) rdd_amazon else NULL,
             rdd_nonamazon = rdd_nonamazon),
        "data/rob_models.rds")

cat("\nRobustness complete.\n")
cat(sprintf("  Panel DiD (crossers): %.4f (SE=%.4f)\n", did1_coef, did1_se))
cat(sprintf("  Panel DiD (intensive): %.4f (SE=%.4f)\n", did2_coef, did2_se))
cat(sprintf("  Amazon subgroup: %.4f (SE=%.4f)\n", amazon_coef, amazon_se))
cat(sprintf("  %d of 17 thresholds show McCrary manipulation\n", n_sig_density))
