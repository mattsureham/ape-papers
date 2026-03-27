## 04_robustness.R — Robustness checks and bootstrap inference
## APEP Working Paper apep_1067

source("00_packages.R")

data_dir <- "../data"
nbi <- fread(file.path(data_dir, "nbi_clean.csv"))

cat(sprintf("Loaded %s bridge-year observations\n", format(nrow(nbi), big.mark = ",")))

# Reuse bunching estimator
estimate_bunching <- function(dt, exclude_lower = 46, exclude_upper = 53,
                              threshold = 50, poly_order = 7,
                              bin_range = c(10, 90)) {
  counts <- dt[sr_int >= bin_range[1] & sr_int <= bin_range[2],
               .(count = .N), by = sr_int][order(sr_int)]
  all_bins <- data.table(sr_int = bin_range[1]:bin_range[2])
  counts <- merge(all_bins, counts, by = "sr_int", all.x = TRUE)
  counts[is.na(count), count := 0]
  counts[, excluded := sr_int >= exclude_lower & sr_int <= exclude_upper]
  fit_data <- counts[excluded == FALSE]
  poly_fit <- lm(count ~ poly(sr_int, poly_order), data = fit_data)
  counts[, counterfactual := predict(poly_fit, newdata = counts)]
  below_50 <- counts[excluded == TRUE & sr_int < threshold]
  excess <- sum(below_50$count) - sum(below_50$counterfactual)
  h0 <- counts[sr_int == threshold, counterfactual]
  b_hat <- excess / h0
  list(b_hat = b_hat, counts = counts, excess = excess, h0 = h0)
}

# Bunching from pre-aggregated counts (for fast bootstrap)
estimate_bunching_from_counts <- function(count_dt, exclude_lower = 46, exclude_upper = 53,
                                          threshold = 50, poly_order = 7,
                                          bin_range = c(10, 90)) {
  counts <- count_dt[sr_int >= bin_range[1] & sr_int <= bin_range[2]]
  counts[, excluded := sr_int >= exclude_lower & sr_int <= exclude_upper]
  fit_data <- counts[excluded == FALSE]
  if (nrow(fit_data) < poly_order + 1) return(list(b_hat = NA_real_))
  poly_fit <- lm(count ~ poly(sr_int, poly_order), data = fit_data)
  counts[, counterfactual := predict(poly_fit, newdata = counts)]
  below_50 <- counts[excluded == TRUE & sr_int < threshold]
  excess <- sum(below_50$count) - sum(below_50$counterfactual)
  h0 <- counts[sr_int == threshold, counterfactual]
  if (h0 <= 0) return(list(b_hat = NA_real_))
  list(b_hat = excess / h0)
}

# ============================================================
# 1. BOOTSTRAP STANDARD ERRORS (Poisson bootstrap — fast)
# ============================================================

cat("\n=== BOOTSTRAP INFERENCE (200 replications, Poisson method) ===\n")

set.seed(42)
n_boot <- 200

# Pre-aggregate: state x year x sr_int counts
# Then resample state-years with Poisson weights (Bayesian bootstrap)
state_year_sr <- nbi[, .(count = .N), by = .(state_code, year, sr_int, post_map21)]

# Get unique state-years
state_years <- unique(state_year_sr[, .(state_code, year)])
n_sy <- nrow(state_years)

boot_full <- numeric(n_boot)
boot_pre <- numeric(n_boot)
boot_post <- numeric(n_boot)

for (b in 1:n_boot) {
  if (b %% 50 == 0) cat(sprintf("  Bootstrap %d/%d\n", b, n_boot))

  # Poisson(1) weights for each state-year (equivalent to multinomial resampling)
  weights <- data.table(state_code = state_years$state_code,
                        year = state_years$year,
                        w = rpois(n_sy, 1))

  boot_dt <- merge(state_year_sr, weights, by = c("state_code", "year"))
  boot_dt[, wcount := count * w]

  # Aggregate to SR bins
  full_counts <- boot_dt[, .(count = sum(wcount)), by = sr_int][order(sr_int)]
  pre_counts <- boot_dt[post_map21 == 0, .(count = sum(wcount)), by = sr_int][order(sr_int)]
  post_counts <- boot_dt[post_map21 == 1, .(count = sum(wcount)), by = sr_int][order(sr_int)]

  boot_full[b] <- estimate_bunching_from_counts(full_counts)$b_hat
  boot_pre[b] <- estimate_bunching_from_counts(pre_counts)$b_hat
  boot_post[b] <- estimate_bunching_from_counts(post_counts)$b_hat
}

# Remove NAs
boot_full <- boot_full[!is.na(boot_full)]
boot_pre <- boot_pre[!is.na(boot_pre)]
boot_post <- boot_post[!is.na(boot_post)]

results <- readRDS(file.path(data_dir, "main_results.rds"))

cat(sprintf("\nFull sample b̂:  %.3f (SE = %.3f) [95%% CI: %.3f, %.3f]\n",
            results$full_bhat, sd(boot_full),
            quantile(boot_full, 0.025), quantile(boot_full, 0.975)))
cat(sprintf("Pre-MAP-21 b̂:   %.3f (SE = %.3f) [95%% CI: %.3f, %.3f]\n",
            results$pre_bhat, sd(boot_pre),
            quantile(boot_pre, 0.025), quantile(boot_pre, 0.975)))
cat(sprintf("Post-MAP-21 b̂:  %.3f (SE = %.3f) [95%% CI: %.3f, %.3f]\n",
            results$post_bhat, sd(boot_post),
            quantile(boot_post, 0.025), quantile(boot_post, 0.975)))

# Diff-in-bunching test
n_diff <- min(length(boot_pre), length(boot_post))
boot_diff <- boot_pre[1:n_diff] - boot_post[1:n_diff]
cat(sprintf("\nDiff-in-bunching: %.3f (SE = %.3f) [95%% CI: %.3f, %.3f]\n",
            results$pre_bhat - results$post_bhat, sd(boot_diff),
            quantile(boot_diff, 0.025), quantile(boot_diff, 0.975)))
cat(sprintf("p-value (one-sided, pre > post): %.4f\n",
            mean(boot_diff <= 0)))

# ============================================================
# 2. POLYNOMIAL ORDER SENSITIVITY
# ============================================================

cat("\n=== POLYNOMIAL ORDER SENSITIVITY ===\n")
for (p in c(5, 6, 7, 8, 9)) {
  b <- estimate_bunching(nbi, poly_order = p)$b_hat
  b_pre <- estimate_bunching(nbi[post_map21 == 0], poly_order = p)$b_hat
  b_post <- estimate_bunching(nbi[post_map21 == 1], poly_order = p)$b_hat
  cat(sprintf("Poly order %d: full b̂ = %.3f | pre = %.3f | post = %.3f | diff = %.3f\n",
              p, b, b_pre, b_post, b_pre - b_post))
}

# ============================================================
# 3. MANIPULATION REGION SENSITIVITY
# ============================================================

cat("\n=== MANIPULATION REGION SENSITIVITY ===\n")
for (window in list(c(47, 52), c(46, 53), c(45, 54), c(44, 55))) {
  b <- estimate_bunching(nbi, exclude_lower = window[1], exclude_upper = window[2])$b_hat
  cat(sprintf("Window [%d, %d]: b̂ = %.3f\n", window[1], window[2], b))
}

# ============================================================
# 4. STATE-LEVEL HETEROGENEITY
# ============================================================

cat("\n=== TOP 10 STATES BY BUNCHING INTENSITY ===\n")
state_bunching <- nbi[, {
  n49 <- sum(sr_int == 49)
  n50 <- sum(sr_int == 50)
  ratio <- n49 / max(n50, 1)
  list(n49 = n49, n50 = n50, ratio = ratio, total = .N)
}, by = state_code][order(-ratio)]

state_names <- data.table(
  state_code = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  state_name = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)
state_bunching[, state_code := as.character(state_code)]
state_bunching <- merge(state_bunching, state_names, by = "state_code", all.x = TRUE)
print(head(state_bunching[order(-ratio)], 10))

# Pre vs Post by state
state_dib <- nbi[, {
  pre_49 <- sum(sr_int == 49 & post_map21 == 0)
  pre_50 <- sum(sr_int == 50 & post_map21 == 0)
  post_49 <- sum(sr_int == 49 & post_map21 == 1)
  post_50 <- sum(sr_int == 50 & post_map21 == 1)
  pre_ratio <- pre_49 / max(pre_50, 1)
  post_ratio <- post_49 / max(post_50, 1)
  list(pre_ratio = pre_ratio, post_ratio = post_ratio,
       change = pre_ratio - post_ratio)
}, by = state_code]
state_dib[, state_code := as.character(state_code)]
state_dib <- merge(state_dib, state_names, by = "state_code", all.x = TRUE)
cat("\n=== TOP 10 STATES BY DIFF-IN-BUNCHING ===\n")
print(head(state_dib[order(-change)], 10))

fwrite(state_bunching, file.path(data_dir, "state_bunching.csv"))

# ============================================================
# 5. BRIDGE AGE AND ADT HETEROGENEITY
# ============================================================

cat("\n=== BUNCHING BY BRIDGE AGE ===\n")
nbi[, age_group := fcase(
  bridge_age < 30, "Young (<30 yrs)",
  bridge_age >= 30 & bridge_age < 60, "Middle (30-60 yrs)",
  bridge_age >= 60, "Old (60+ yrs)",
  default = "Unknown"
)]
for (ag in c("Young (<30 yrs)", "Middle (30-60 yrs)", "Old (60+ yrs)")) {
  sub <- nbi[age_group == ag]
  if (nrow(sub) > 50000) {
    b <- estimate_bunching(sub)$b_hat
    cat(sprintf("%-20s: b̂ = %.3f (N = %s)\n", ag, b, format(nrow(sub), big.mark = ",")))
  }
}

cat("\n=== BUNCHING BY TRAFFIC VOLUME ===\n")
nbi[, adt_group := fcase(
  adt < 500, "Low (<500 ADT)",
  adt >= 500 & adt < 5000, "Medium (500-5K ADT)",
  adt >= 5000, "High (5K+ ADT)",
  default = "Unknown"
)]
for (ag in c("Low (<500 ADT)", "Medium (500-5K ADT)", "High (5K+ ADT)")) {
  sub <- nbi[adt_group == ag]
  if (nrow(sub) > 50000) {
    b <- estimate_bunching(sub)$b_hat
    cat(sprintf("%-20s: b̂ = %.3f (N = %s)\n", ag, b, format(nrow(sub), big.mark = ",")))
  }
}

# ============================================================
# 6. SAVE BOOTSTRAP RESULTS
# ============================================================

boot_results <- list(
  full = list(mean = results$full_bhat, se = sd(boot_full),
              ci = quantile(boot_full, c(0.025, 0.975))),
  pre = list(mean = results$pre_bhat, se = sd(boot_pre),
             ci = quantile(boot_pre, c(0.025, 0.975))),
  post = list(mean = results$post_bhat, se = sd(boot_post),
              ci = quantile(boot_post, c(0.025, 0.975))),
  diff = list(mean = results$pre_bhat - results$post_bhat,
              se = sd(boot_diff),
              ci = quantile(boot_diff, c(0.025, 0.975)),
              p_value = mean(boot_diff <= 0))
)
saveRDS(boot_results, file.path(data_dir, "bootstrap_results.rds"))
cat("\nBootstrap results saved.\n")
