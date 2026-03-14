## 04_robustness.R — Robustness checks
## APEP Paper apep_0669: Capitalization of Reproductive Rights

source("00_packages.R")

cat("=== Robustness Checks ===\n")

stl_panel <- readRDS("../data/stl_panel.rds")
kc_panel <- readRDS("../data/kc_panel.rds")

analysis_df <- stl_panel %>%
  filter(pre_dobbs == 1 | post_dobbs == 1)

# ----------------------------------------------------------------
# 1. Bandwidth sensitivity
# ----------------------------------------------------------------
cat("\n--- Bandwidth Sensitivity ---\n")

bandwidths <- c(10, 15, 20, 30, 50, 75, Inf)
bw_results <- list()

for (bw in bandwidths) {
  bw_df <- analysis_df %>% filter(dist_km <= bw)
  n_zips <- n_distinct(bw_df$zip)

  if (n_zips < 10) {
    cat("  BW =", bw, "km: too few ZIPs (", n_zips, "), skipping\n")
    next
  }

  m <- tryCatch({
    feols(log_zhvi ~ treat_post + signed_dist:post_dobbs |
            zip + ym, data = bw_df, cluster = ~zip)
  }, error = function(e) NULL)

  if (!is.null(m)) {
    bw_label <- if (is.infinite(bw)) "Full" else paste0(bw, "km")
    bw_results[[bw_label]] <- m
    coef_val <- coef(m)["treat_post"]
    se_val <- sqrt(diag(vcov(m)))["treat_post"]
    cat("  BW =", bw_label, ": β =", round(coef_val, 4),
        " (SE =", round(se_val, 4), ") | N ZIPs =", n_zips, "\n")
  }
}

saveRDS(bw_results, "../data/bw_results.rds")

# ----------------------------------------------------------------
# 2. Placebo cutoff test
# ----------------------------------------------------------------
cat("\n--- Placebo Cutoff Test ---\n")

# Shift border 20km east (into Illinois) and 20km west (into Missouri)
placebo_shifts <- c(-20, -10, 10, 20)  # km
placebo_results <- list()

for (shift in placebo_shifts) {
  placebo_df <- analysis_df %>%
    mutate(
      placebo_dist = signed_dist - shift,
      placebo_side = as.integer(placebo_dist > 0),
      placebo_treat = placebo_side * post_dobbs
    )

  m_placebo <- tryCatch({
    feols(log_zhvi ~ placebo_treat + placebo_dist:post_dobbs |
            zip + ym, data = placebo_df, cluster = ~zip)
  }, error = function(e) NULL)

  if (!is.null(m_placebo)) {
    placebo_results[[as.character(shift)]] <- m_placebo
    coef_val <- coef(m_placebo)["placebo_treat"]
    se_val <- sqrt(diag(vcov(m_placebo)))["placebo_treat"]
    cat("  Shift =", shift, "km: β =", round(coef_val, 4),
        " (SE =", round(se_val, 4), ")\n")
  }
}

saveRDS(placebo_results, "../data/placebo_results.rds")

# ----------------------------------------------------------------
# 3. Temporal placebo (fake Dobbs at Jan 2021)
# ----------------------------------------------------------------
cat("\n--- Temporal Placebo ---\n")

pre_only <- stl_panel %>%
  filter(date >= as.Date("2020-01-01") & date < as.Date("2022-06-01")) %>%
  mutate(
    fake_post = as.integer(date >= as.Date("2021-01-01")),
    fake_treat = ban_state * fake_post
  )

m_temporal <- feols(log_zhvi ~ fake_treat + signed_dist:fake_post |
                      zip + ym, data = pre_only, cluster = ~zip)

cat("Temporal placebo (fake Dobbs = Jan 2021):\n")
print(summary(m_temporal))

saveRDS(m_temporal, "../data/temporal_placebo.rds")

# ----------------------------------------------------------------
# 4. Kansas City replication
# ----------------------------------------------------------------
cat("\n--- Kansas City Replication ---\n")

kc_analysis <- kc_panel %>%
  filter(pre_dobbs == 1 | post_dobbs == 1) %>%
  filter(!is.na(signed_dist))

cat("  KC panel:", nrow(kc_analysis), "obs,",
    n_distinct(kc_analysis$zip), "ZIPs\n")
cat("  KC MO ZIPs:", n_distinct(kc_analysis$zip[kc_analysis$ban_state == 1]),
    "| KS ZIPs:", n_distinct(kc_analysis$zip[kc_analysis$ban_state == 0]), "\n")

if (n_distinct(kc_analysis$zip) >= 20) {
  kc_m1 <- feols(log_zhvi ~ treat_post | zip + ym,
                 data = kc_analysis, cluster = ~zip)

  kc_m2 <- feols(log_zhvi ~ treat_post + signed_dist:post_dobbs |
                   zip + ym, data = kc_analysis, cluster = ~zip)

  cat("\nKC Model 1 (Basic DiD):\n")
  print(summary(kc_m1))
  cat("\nKC Model 2 (DiD + distance):\n")
  print(summary(kc_m2))

  saveRDS(list(kc_m1 = kc_m1, kc_m2 = kc_m2), "../data/kc_results.rds")
} else {
  cat("  WARNING: Too few KC ZIPs for reliable estimation\n")
}

# ----------------------------------------------------------------
# 5. May 2022 leak anticipation test
# ----------------------------------------------------------------
cat("\n--- Leak Anticipation Test ---\n")

# Politico leaked the Dobbs draft on May 2, 2022
# Test: is there a discontinuity in May-June 2022?
leak_df <- stl_panel %>%
  filter(date >= as.Date("2021-07-01") & date <= as.Date("2022-06-30")) %>%
  mutate(
    post_leak = as.integer(date >= as.Date("2022-05-01")),
    leak_treat = ban_state * post_leak
  )

m_leak <- feols(log_zhvi ~ leak_treat + signed_dist:post_leak |
                  zip + ym, data = leak_df, cluster = ~zip)

cat("Leak anticipation (May 2022):\n")
print(summary(m_leak))

saveRDS(m_leak, "../data/leak_results.rds")

# ----------------------------------------------------------------
# 6. Heterogeneity: distance gradient
# ----------------------------------------------------------------
cat("\n--- Distance Gradient ---\n")

# Split MO ZIPs into distance bins
mo_df <- analysis_df %>%
  filter(ban_state == 1) %>%
  mutate(
    dist_bin = cut(dist_km, breaks = c(0, 5, 10, 20, 50, Inf),
                   labels = c("0-5km", "5-10km", "10-20km", "20-50km", "50+km"))
  )

# Estimate effect by distance bin
for (bin in levels(mo_df$dist_bin)) {
  bin_df <- bind_rows(
    mo_df %>% filter(dist_bin == bin),
    analysis_df %>% filter(ban_state == 0)  # All IL ZIPs as controls
  )

  if (n_distinct(bin_df$zip[bin_df$ban_state == 1]) < 5) {
    cat("  ", bin, ": too few MO ZIPs, skipping\n")
    next
  }

  m_bin <- tryCatch({
    feols(log_zhvi ~ treat_post | zip + ym, data = bin_df, cluster = ~zip)
  }, error = function(e) NULL)

  if (!is.null(m_bin)) {
    coef_val <- coef(m_bin)["treat_post"]
    se_val <- sqrt(diag(vcov(m_bin)))["treat_post"]
    n_mo <- n_distinct(bin_df$zip[bin_df$ban_state == 1])
    cat("  ", bin, ": β =", round(coef_val, 4),
        " (SE =", round(se_val, 4), ") | N MO ZIPs =", n_mo, "\n")
  }
}

cat("\n=== Robustness checks complete ===\n")
