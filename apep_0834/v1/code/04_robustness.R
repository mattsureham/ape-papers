## 04_robustness.R — Robustness checks for Barrier-Free Act RDD
source("00_packages.R")

data_dir <- "../data"
analysis_all <- readRDS(file.path(data_dir, "analysis_data.rds"))
station_df   <- readRDS(file.path(data_dir, "stations_clean.rds"))
results      <- readRDS(file.path(data_dir, "rdd_results.rds"))

df_post <- analysis_all %>% filter(survey_year >= 2015)

## ===========================================================================
## 1. PLACEBO CUTOFFS — No effect at false thresholds
## ===========================================================================
cat("=== Placebo Cutoff Tests ===\n")

placebo_cutoffs <- c(1500, 2000, 4000, 5000, 6000)
placebo_results <- data.frame()

for (cutoff in placebo_cutoffs) {
  df_placebo <- df_post %>%
    mutate(centered_placebo = nearest_station_users - cutoff)

  rdd_placebo <- rdrobust::rdrobust(
    y = df_placebo$log_price,
    x = df_placebo$centered_placebo,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = df_placebo$nearest_station_name
  )

  placebo_results <- rbind(placebo_results, data.frame(
    cutoff   = cutoff,
    estimate = rdd_placebo$coef[1],
    se       = rdd_placebo$se[3],
    p_value  = rdd_placebo$pv[3],
    n_eff    = sum(rdd_placebo$Nh)
  ))
}

cat("Placebo cutoff results:\n")
print(placebo_results)

## ===========================================================================
## 2. DONUT HOLE RDD — Exclude stations very close to threshold
## ===========================================================================
cat("\n=== Donut Hole RDD ===\n")

donut_sizes <- c(100, 200, 500)
donut_results <- data.frame()

for (hole in donut_sizes) {
  df_donut <- df_post %>%
    filter(abs(centered_users) >= hole)

  rdd_donut <- rdrobust::rdrobust(
    y = df_donut$log_price,
    x = df_donut$centered_users,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = df_donut$nearest_station_name
  )

  donut_results <- rbind(donut_results, data.frame(
    donut_hole = hole,
    estimate   = rdd_donut$coef[1],
    se         = rdd_donut$se[3],
    p_value    = rdd_donut$pv[3],
    n_eff      = sum(rdd_donut$Nh)
  ))
}

cat("Donut hole results:\n")
print(donut_results)

## ===========================================================================
## 3. DIFF-IN-DISC BANDWIDTH SENSITIVITY
## ===========================================================================
cat("\n=== Diff-in-Disc Bandwidth Sensitivity ===\n")

# Re-create matched panel
df_2010 <- analysis_all %>%
  filter(survey_year == 2010) %>%
  mutate(point_id = paste(round(lon, 5), round(lat, 5)))
df_2020 <- analysis_all %>%
  filter(survey_year == 2020) %>%
  mutate(point_id = paste(round(lon, 5), round(lat, 5)))

matched <- inner_join(
  df_2010 %>% select(point_id, log_price_2010 = log_price,
                     centered_users, nearest_station_name,
                     nearest_station_above, station_dist_m),
  df_2020 %>% select(point_id, log_price_2020 = log_price),
  by = "point_id"
) %>%
  mutate(price_change = log_price_2020 - log_price_2010)

# Baseline diff-in-disc
rdd_did_base <- rdrobust::rdrobust(
  y = matched$price_change,
  x = matched$centered_users,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = matched$nearest_station_name
)

bw_opt_did <- rdd_did_base$bws[1, 1]
bw_mults <- c(0.5, 0.75, 1.0, 1.25, 1.5)
did_bw_results <- data.frame()

for (mult in bw_mults) {
  bw <- bw_opt_did * mult
  rdd_did_bw <- rdrobust::rdrobust(
    y = matched$price_change,
    x = matched$centered_users,
    c = 0,
    h = bw,
    kernel = "triangular",
    cluster = matched$nearest_station_name
  )
  did_bw_results <- rbind(did_bw_results, data.frame(
    bw_multiplier = mult,
    bandwidth     = bw,
    estimate      = rdd_did_bw$coef[1],
    se_robust     = rdd_did_bw$se[3],
    p_robust      = rdd_did_bw$pv[3],
    n_eff         = sum(rdd_did_bw$Nh)
  ))
}

cat("Diff-in-disc bandwidth sensitivity:\n")
print(did_bw_results)

## ===========================================================================
## 4. HETEROGENEITY — Residential vs. Commercial
## ===========================================================================
cat("\n=== Heterogeneity: Land Use Type ===\n")

if ("land_use" %in% names(df_post)) {
  df_post$is_residential <- grepl("住宅", df_post$land_use)

  for (ltype in c(TRUE, FALSE)) {
    label <- if (ltype) "Residential" else "Non-residential"
    df_sub <- df_post %>% filter(is_residential == ltype)

    if (nrow(df_sub) > 500) {
      rdd_sub <- rdrobust::rdrobust(
        y = df_sub$log_price,
        x = df_sub$centered_users,
        c = 0,
        kernel = "triangular",
        bwselect = "mserd",
        cluster = df_sub$nearest_station_name
      )
      cat(sprintf("%s: coef=%.4f, se=%.4f, p=%.4f, n=%d\n",
                  label, rdd_sub$coef[1], rdd_sub$se[3], rdd_sub$pv[3],
                  sum(rdd_sub$Nh)))
    }
  }
}

## ===========================================================================
## 5. FORMER 5,000 THRESHOLD AS VALIDATION
## ===========================================================================
cat("\n=== Former 5,000 Threshold (should also show effect) ===\n")

df_post_5k <- df_post %>%
  mutate(centered_5k = nearest_station_users - 5000)

rdd_5k <- rdrobust::rdrobust(
  y = df_post_5k$log_price,
  x = df_post_5k$centered_5k,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = df_post_5k$nearest_station_name
)
cat(sprintf("5,000 threshold: coef=%.4f, se=%.4f, p=%.4f\n",
            rdd_5k$coef[1], rdd_5k$se[3], rdd_5k$pv[3]))

## ===========================================================================
## 6. SAVE ALL ROBUSTNESS RESULTS
## ===========================================================================
robustness <- list(
  placebo_cutoffs    = placebo_results,
  donut_hole         = donut_results,
  did_bw_sensitivity = did_bw_results,
  former_5k          = list(coef = rdd_5k$coef[1], se = rdd_5k$se[3], pv = rdd_5k$pv[3])
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\n=== Robustness checks complete ===\n")
