## 04_robustness.R — Robustness checks and placebo tests
## apep_0718: Tornado Paths and Manufactured Housing

source("00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("../data/analysis_dataset.rds")

# ============================================================================
# TABLE 4: Robustness — Bandwidth sensitivity and placebo tests
# ============================================================================

cat("\n=== Bandwidth Sensitivity ===\n")

# Test RDD at multiple bandwidths for mobile home share
bandwidths <- c(0.5, 1.0, 1.5, 2.0, 3.0, 5.0)
bw_results <- list()

y <- df$delta_mobile_pct
x <- df$dist_mi
valid <- !is.na(y) & !is.na(x)

for (bw in bandwidths) {
  in_bw <- valid & abs(x) <= bw
  if (sum(in_bw) < 50) {
    cat(sprintf("  BW=%.1f: insufficient obs (%d)\n", bw, sum(in_bw)))
    next
  }

  rd <- rdrobust(y = y[in_bw], x = x[in_bw], c = 0,
                 kernel = "triangular", p = 1, h = bw,
                 cluster = df$COUNTYFP[in_bw])

  bw_results[[as.character(bw)]] <- list(
    bw = bw,
    coef = rd$coef[1],
    se = rd$se[3],
    ci_lower = rd$ci[3, 1],
    ci_upper = rd$ci[3, 2],
    n = sum(in_bw),
    pv = rd$pv[3]
  )
  cat(sprintf("  BW=%.1f: coef=%.4f (SE=%.4f), N=%d\n",
              bw, rd$coef[1], rd$se[3], sum(in_bw)))
}

# ============================================================================
# Placebo 1: Pre-tornado balance (outcomes measured BEFORE tornado)
# ============================================================================
cat("\n=== Placebo: Pre-tornado levels at path boundary ===\n")

placebo_vars <- c("mobile_pct_pre", "poverty_rate_pre", "log_value_pre")
placebo_labels <- c("Pre Mobile Home %", "Pre Poverty Rate", "Pre Log Value")

placebo_results <- list()

for (i in seq_along(placebo_vars)) {
  y_p <- df[[placebo_vars[i]]]
  x_p <- df$dist_mi
  valid_p <- !is.na(y_p) & !is.na(x_p)

  if (sum(valid_p) < 100) next

  rd_p <- rdrobust(y = y_p[valid_p], x = x_p[valid_p], c = 0,
                   kernel = "triangular", p = 1, bwselect = "mserd",
                   cluster = df$COUNTYFP[valid_p])

  placebo_results[[placebo_vars[i]]] <- list(
    outcome = placebo_labels[i],
    coef = rd_p$coef[1],
    se = rd_p$se[3],
    pv = rd_p$pv[3],
    bw = rd_p$bws[1, 1]
  )
  cat(sprintf("  %s: coef=%.4f (SE=%.4f, p=%.3f)\n",
              placebo_labels[i], rd_p$coef[1], rd_p$se[3], rd_p$pv[3]))
}

# ============================================================================
# Placebo 2: EF0-1 tornadoes (weak damage — should show no effect)
# ============================================================================
cat("\n=== Placebo: EF0-1 Tornadoes ===\n")

# Load the full tornado data and create EF0-1 placebo paths
tornadoes <- readRDS("../data/tornadoes_ef2plus.rds")

# We need the original full dataset for EF0-1 events
# Re-read and filter
torn_all <- read_csv("../data/tornadoes_raw.csv", show_col_types = FALSE)
torn_ef01 <- torn_all %>%
  filter(
    mag %in% c(0, 1),
    yr >= 2000, yr <= 2015,
    slat != 0, slon != 0,
    elat != 0, elon != 0,
    wid > 0
  ) %>%
  # Sample to make computation manageable
  slice_sample(n = min(nrow(.), 2000))

cat(sprintf("EF0-1 placebo tornadoes: %d\n", nrow(torn_ef01)))

# Create placebo path polygons
torn_ef01_lines <- torn_ef01 %>%
  rowwise() %>%
  mutate(
    geometry = list(st_linestring(matrix(c(slon, slat, elon, elat), ncol = 2, byrow = TRUE)))
  ) %>%
  ungroup() %>%
  st_as_sf(crs = 4326) %>%
  st_transform(5070)

torn_ef01_paths <- torn_ef01_lines %>%
  mutate(buffer_m = (wid / 2) * 0.9144) %>%
  rowwise() %>%
  mutate(geometry = st_buffer(geometry, dist = max(buffer_m, 50))) %>%
  ungroup()

# Load census tracts and compute placebo distances
tracts_all <- readRDS("../data/census_tracts.rds")

# Which tracts intersect EF0-1 paths?
ef01_intersect <- st_intersects(tracts_all, torn_ef01_paths, sparse = TRUE)
tracts_all$in_ef01_path <- lengths(ef01_intersect) > 0

# Create outer buffer for near-path tracts
torn_ef01_outer <- torn_ef01_lines %>%
  mutate(outer_m = (wid / 2) * 0.9144 + 3218.69) %>%
  rowwise() %>%
  mutate(geometry = st_buffer(geometry, dist = max(outer_m, 3500))) %>%
  ungroup()

ef01_near <- st_intersects(tracts_all, torn_ef01_outer, sparse = TRUE)
tracts_all$near_ef01 <- lengths(ef01_near) > 0

# Get near-path tracts and compute distances
ef01_near_tracts <- tracts_all %>% filter(near_ef01)
ef01_centroids <- st_centroid(ef01_near_tracts)

cat(sprintf("Computing distances for %d EF0-1 near-path tracts...\n", nrow(ef01_near_tracts)))

ef01_distances <- numeric(nrow(ef01_near_tracts))
for (j in seq_len(nrow(ef01_near_tracts))) {
  if (j %% 500 == 0) cat(sprintf("  %d / %d\n", j, nrow(ef01_near_tracts)))
  d <- min(as.numeric(st_distance(ef01_centroids[j, ], torn_ef01_paths)))
  ef01_distances[j] <- ifelse(ef01_near_tracts$in_ef01_path[j], -d, d)
}
ef01_near_tracts$dist_m <- ef01_distances
ef01_near_tracts$dist_mi <- ef01_distances / 1609.34

# Merge with ACS data
acs_combined <- readRDS("../data/acs_combined.rds")
acs_pre <- acs_combined %>% filter(period == "pre") %>%
  select(GEOID, mobile_homesE = mobile_homesE, total_unitsE = total_unitsE) %>%
  rename(mobile_pre = mobile_homesE, units_pre = total_unitsE)
acs_post <- acs_combined %>% filter(period == "post") %>%
  select(GEOID, mobile_homesE = mobile_homesE, total_unitsE = total_unitsE) %>%
  rename(mobile_post = mobile_homesE, units_post = total_unitsE)

ef01_df <- ef01_near_tracts %>%
  st_drop_geometry() %>%
  inner_join(acs_pre, by = "GEOID") %>%
  inner_join(acs_post, by = "GEOID") %>%
  mutate(
    delta_mobile_pct = (mobile_post / units_post - mobile_pre / units_pre) * 100
  ) %>%
  filter(!is.na(delta_mobile_pct), abs(dist_mi) <= 5, units_pre >= 50)

if (nrow(ef01_df) >= 100) {
  rd_ef01 <- rdrobust(y = ef01_df$delta_mobile_pct, x = ef01_df$dist_mi, c = 0,
                       kernel = "triangular", p = 1, bwselect = "mserd",
                       cluster = ef01_df$COUNTYFP)
  cat(sprintf("EF0-1 placebo: coef=%.4f (SE=%.4f, p=%.3f)\n",
              rd_ef01$coef[1], rd_ef01$se[3], rd_ef01$pv[3]))

  placebo_results[["ef01_mobile"]] <- list(
    outcome = "EF0-1 Placebo: Mobile Home %",
    coef = rd_ef01$coef[1],
    se = rd_ef01$se[3],
    pv = rd_ef01$pv[3],
    bw = rd_ef01$bws[1, 1]
  )
} else {
  cat("Insufficient EF0-1 placebo observations.\n")
}

# ============================================================================
# McCrary density test
# ============================================================================
cat("\n=== McCrary Density Test ===\n")

dens_test <- rddensity(X = df$dist_mi, c = 0)
cat(sprintf("McCrary test p-value: %.4f\n", dens_test$test$p_jk))
cat("(p > 0.05 => no manipulation at boundary — expected for tornado paths)\n")

# ============================================================================
# TABLE 5: Heterogeneity by pre-tornado mobile home share
# ============================================================================
cat("\n=== Heterogeneity: High vs Low pre-tornado mobile home share ===\n")

median_mobile <- median(df$pre_mobile_share, na.rm = TRUE)
df_high <- df %>% filter(pre_mobile_share >= median_mobile)
df_low  <- df %>% filter(pre_mobile_share < median_mobile)

het_results <- list()

for (subgroup in c("high", "low")) {
  sub_df <- if (subgroup == "high") df_high else df_low
  y_h <- sub_df$delta_mobile_pct
  x_h <- sub_df$dist_mi
  valid_h <- !is.na(y_h) & !is.na(x_h)

  if (sum(valid_h) < 80) {
    cat(sprintf("  %s mobile share: insufficient obs\n", subgroup))
    next
  }

  rd_h <- rdrobust(y = y_h[valid_h], x = x_h[valid_h], c = 0,
                   kernel = "triangular", p = 1, bwselect = "mserd",
                   cluster = sub_df$COUNTYFP[valid_h])

  het_results[[subgroup]] <- list(
    coef = rd_h$coef[1], se = rd_h$se[3], pv = rd_h$pv[3],
    n = sum(valid_h), bw = rd_h$bws[1, 1]
  )
  cat(sprintf("  %s mobile share: coef=%.4f (SE=%.4f, p=%.3f, N=%d)\n",
              subgroup, rd_h$coef[1], rd_h$se[3], rd_h$pv[3], sum(valid_h)))
}

# Save all robustness results
saveRDS(list(
  bw_sensitivity = bw_results,
  placebo = placebo_results,
  mccrary_pv = dens_test$test$p_jk,
  heterogeneity = het_results
), "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
