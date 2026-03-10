## 04_robustness.R — Robustness checks for Design 1
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test
## Uses tidysynth (same as 03_main_analysis.R)

source("00_packages.R")
library(tidysynth)

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]
panel[, t := (year - 2015) * 12 + month_num]

# Handle missing values (same as 03_main_analysis.R)
panel[, od_rate := nafill(od_rate, type = "locf"), by = state_name]
panel[, fent_rate := nafill(fent_rate, type = "locf"), by = state_name]
panel[, heroin_rate := nafill(heroin_rate, type = "locf"), by = state_name]
panel[, psycho_rate := nafill(psycho_rate, type = "locf"), by = state_name]
panel[, cocaine_rate := nafill(cocaine_rate, type = "locf"), by = state_name]
panel[, fent_share := fifelse(is.na(fent_share), 0, fent_share)]

# Fill any remaining NAs with 0
for (col in c("od_rate", "fent_rate", "heroin_rate", "psycho_rate", "cocaine_rate")) {
  panel[is.na(get(col)), (col) := 0]
}

# Drop states still missing od_rate
panel <- panel[!is.na(od_rate)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

# Prepare Design 1 panel
panel_d1 <- as.data.frame(panel[date < as.Date("2024-09-01")])
decrim_t <- 74  # Feb 2021 = (2021-2015)*12 + 2

# Load main results for comparison
main_results <- fread(file.path(data_dir, "main_results.csv"))
main_att <- main_results[design == "Decriminalization", att]
main_se <- main_results[design == "Decriminalization", se]

cat(sprintf("Main result (Design 1): ATT = %.3f (SE = %.3f)\n\n", main_att, main_se))

# ============================================================
# 1. Leave-One-Out Donor Stability (Design 1)
# ============================================================
cat("--- 1. Leave-One-Out Stability ---\n")

donor_states <- unique(panel_d1$state_name[panel_d1$state_name != "Oregon"])
loo_results <- list()

set.seed(42)  # Seed for reproducibility (LOO)
for (st in donor_states) {
  cat(sprintf("  Dropping: %s ... ", st))

  panel_loo <- panel_d1[panel_d1$state_name != st, ]

  tryCatch({
    synth_loo <- panel_loo %>%
      synthetic_control(
        outcome = od_rate, unit = state_name, time = t,
        i_unit = "Oregon", i_time = decrim_t,
        generate_placebos = TRUE
      ) %>%
      generate_predictor(time_window = 1:(decrim_t - 1),
                         od_rate_all = mean(od_rate, na.rm = TRUE)) %>%
      generate_predictor(time_window = (decrim_t - 24):(decrim_t - 1),
                         od_rate_recent = mean(od_rate, na.rm = TRUE)) %>%
      generate_predictor(time_window = max(1, decrim_t - 48):(decrim_t - 25),
                         od_rate_early = mean(od_rate, na.rm = TRUE)) %>%
      generate_weights(optimization_window = 1:(decrim_t - 1)) %>%
      generate_control()

    loo_sc <- synth_loo %>% grab_synthetic_control()
    loo_sc$gap <- loo_sc$real_y - loo_sc$synth_y
    loo_post <- loo_sc[loo_sc$time_unit >= decrim_t, ]
    att_loo <- mean(loo_post$gap, na.rm = TRUE)

    # SE from placebo distribution
    loo_all <- synth_loo %>% grab_synthetic_control(placebo = TRUE)
    loo_placebo_atts <- loo_all %>%
      filter(time_unit >= decrim_t) %>%
      group_by(.id) %>%
      summarise(mean_gap = mean(real_y - synth_y, na.rm = TRUE), .groups = "drop")
    se_loo <- sd(loo_placebo_atts$mean_gap, na.rm = TRUE)

    loo_results[[st]] <- data.table(
      dropped_state = st,
      att = att_loo,
      se = se_loo
    )
    cat(sprintf("ATT = %.3f (SE = %.3f)\n", att_loo, se_loo))

  }, error = function(e) {
    cat(sprintf("FAILED: %s\n", e$message))
    loo_results[[st]] <<- data.table(
      dropped_state = st, att = NA_real_, se = NA_real_
    )
  })
}

loo_df <- rbindlist(loo_results)
fwrite(loo_df, file.path(data_dir, "loo_results.csv"))

cat(sprintf("\nLeave-one-out ATT range: [%.3f, %.3f]\n",
            min(loo_df$att, na.rm = TRUE), max(loo_df$att, na.rm = TRUE)))
cat(sprintf("Mean LOO ATT: %.3f (SD: %.3f)\n",
            mean(loo_df$att, na.rm = TRUE), sd(loo_df$att, na.rm = TRUE)))

# ============================================================
# 2. Western States Only Donor Pool
# ============================================================
cat("\n--- 2. Western States Donor Pool ---\n")

western <- c("Washington", "California", "Nevada", "Idaho", "Arizona",
             "Colorado", "Montana", "Utah", "New Mexico", "Wyoming", "Oregon")

panel_west <- panel_d1[panel_d1$state_name %in% western, ]

cat(sprintf("Western donor pool: %d states\n",
            length(unique(panel_west$state_name)) - 1))

set.seed(43)  # Seed for reproducibility (Western)
tryCatch({
  synth_west <- panel_west %>%
    synthetic_control(
      outcome = od_rate, unit = state_name, time = t,
      i_unit = "Oregon", i_time = decrim_t,
      generate_placebos = TRUE
    ) %>%
    generate_predictor(time_window = 1:(decrim_t - 1),
                       od_rate_all = mean(od_rate, na.rm = TRUE)) %>%
    generate_predictor(time_window = (decrim_t - 24):(decrim_t - 1),
                       od_rate_recent = mean(od_rate, na.rm = TRUE)) %>%
    generate_predictor(time_window = max(1, decrim_t - 48):(decrim_t - 25),
                       od_rate_early = mean(od_rate, na.rm = TRUE)) %>%
    generate_weights(optimization_window = 1:(decrim_t - 1)) %>%
    generate_control()

  west_sc <- synth_west %>% grab_synthetic_control()
  west_sc$gap <- west_sc$real_y - west_sc$synth_y
  west_post <- west_sc[west_sc$time_unit >= decrim_t, ]
  att_west <- mean(west_post$gap, na.rm = TRUE)

  # SE from placebo distribution
  west_all <- synth_west %>% grab_synthetic_control(placebo = TRUE)
  west_placebo_atts <- west_all %>%
    filter(time_unit >= decrim_t) %>%
    group_by(.id) %>%
    summarise(mean_gap = mean(real_y - synth_y, na.rm = TRUE), .groups = "drop")
  se_west <- sd(west_placebo_atts$mean_gap, na.rm = TRUE)

  # RMSPE
  west_pre <- west_sc[west_sc$time_unit < decrim_t, ]
  rmspe_west <- sqrt(mean(west_pre$gap^2, na.rm = TRUE))

  cat(sprintf("Western SCM ATT: %.3f (SE: %.3f)\n", att_west, se_west))
  cat(sprintf("Western SCM RMSPE: %.3f\n", rmspe_west))

  # Weights
  west_weights <- synth_west %>% grab_unit_weights()
  cat("Top donor weights (Western):\n")
  print(west_weights %>% filter(weight > 0.01) %>% arrange(desc(weight)))

  # Save time-varying ATT
  att_west_tv <- west_sc %>%
    transmute(time = time_unit, att_est = gap, oregon = real_y, synthetic = synth_y)
  fwrite(as.data.table(att_west_tv), file.path(data_dir, "att_western.csv"))

  west_result <- data.table(
    check = "Western states only",
    att = att_west,
    se = se_west
  )
}, error = function(e) {
  cat(sprintf("Western SCM failed: %s\n", e$message))
  west_result <<- data.table(check = "Western states only",
                              att = NA_real_, se = NA_real_)
})

# ============================================================
# 3. Rolling Pre-Period Windows
# ============================================================
cat("\n--- 3. Rolling Pre-Period Windows ---\n")

pre_starts <- c("2012-01-01", "2013-01-01", "2014-01-01",
                "2016-01-01", "2017-01-01")
roll_results <- list()

set.seed(44)  # Seed for reproducibility (rolling pre-period)
for (start_date in pre_starts) {
  start_yr <- as.integer(substr(start_date, 1, 4))
  cat(sprintf("  Pre-start %s ... ", start_date))

  panel_roll <- panel_d1[panel_d1$date >= as.Date(start_date), ]
  # Re-index time relative to start year
  panel_roll$t_roll <- (panel_roll$year - start_yr) * 12 + panel_roll$month_num
  # Compute treatment time in the new time index
  decrim_t_roll <- (2021 - start_yr) * 12 + 2

  tryCatch({
    synth_roll <- panel_roll %>%
      synthetic_control(
        outcome = od_rate, unit = state_name, time = t_roll,
        i_unit = "Oregon", i_time = decrim_t_roll,
        generate_placebos = TRUE
      ) %>%
      generate_predictor(time_window = 1:(decrim_t_roll - 1),
                         od_rate_all = mean(od_rate, na.rm = TRUE)) %>%
      generate_predictor(time_window = (decrim_t_roll - 24):(decrim_t_roll - 1),
                         od_rate_recent = mean(od_rate, na.rm = TRUE)) %>%
      generate_predictor(time_window = max(1, decrim_t_roll - 48):(decrim_t_roll - 25),
                         od_rate_early = mean(od_rate, na.rm = TRUE)) %>%
      generate_weights(optimization_window = 1:(decrim_t_roll - 1)) %>%
      generate_control()

    roll_sc <- synth_roll %>% grab_synthetic_control()
    roll_sc$gap <- roll_sc$real_y - roll_sc$synth_y
    roll_post <- roll_sc[roll_sc$time_unit >= decrim_t_roll, ]
    att_roll <- mean(roll_post$gap, na.rm = TRUE)

    # SE from placebo distribution
    roll_all <- synth_roll %>% grab_synthetic_control(placebo = TRUE)
    roll_placebo_atts <- roll_all %>%
      filter(time_unit >= decrim_t_roll) %>%
      group_by(.id) %>%
      summarise(mean_gap = mean(real_y - synth_y, na.rm = TRUE), .groups = "drop")
    se_roll <- sd(roll_placebo_atts$mean_gap, na.rm = TRUE)

    roll_results[[start_date]] <- data.table(
      pre_start = start_date,
      att = att_roll,
      se = se_roll
    )

    cat(sprintf("ATT = %.3f (SE = %.3f)\n", att_roll, se_roll))

  }, error = function(e) {
    cat(sprintf("FAILED: %s\n", e$message))
    roll_results[[start_date]] <<- data.table(
      pre_start = start_date, att = NA_real_, se = NA_real_
    )
  })
}

roll_df <- rbindlist(roll_results)
fwrite(roll_df, file.path(data_dir, "rolling_preperiod.csv"))

# ============================================================
# 4. Joint Permutation Test for Symmetric Sum
# ============================================================
cat("\n--- 4. Joint Permutation Test (Symmetric Sum) ---\n")

# For each placebo-treated state, compute both Design 1 and Design 2 ATTs
# and their sum. This gives the permutation distribution of tau_sum.

# Load the main results
main <- fread(file.path(data_dir, "main_results.csv"))
tau_d_main <- main[design == "Decriminalization", att]
tau_r_main <- main[design == "Recriminalization", att]
tau_sum_main <- tau_d_main + tau_r_main

# Load placebo ATTs from both designs
d1_placebos <- fread(file.path(data_dir, "placebo_atts.csv"))
d2_placebos <- fread(file.path(data_dir, "placebo_atts_d2.csv"))

# Merge on state name — only states with valid placebos in BOTH designs
joint <- merge(
  d1_placebos[, .(state, att_d1 = placebo_att)],
  d2_placebos[, .(state, att_d2 = placebo_att)],
  by = "state"
)
joint[, tau_sum := att_d1 + att_d2]

cat(sprintf("  States with both placebos: %d\n", nrow(joint)))
cat(sprintf("  Oregon tau_sum: %.3f\n", tau_sum_main))

# Rank Oregon's tau_sum among all units
# For a two-sided test: how many have |tau_sum| >= |Oregon's tau_sum|?
oregon_sum <- joint[state == "Oregon", tau_sum]
n_extreme <- sum(abs(joint$tau_sum) >= abs(oregon_sum))
joint_ri_pvalue <- n_extreme / nrow(joint)

cat(sprintf("  Joint RI p-value (two-sided): %.4f (%d of %d)\n",
            joint_ri_pvalue, n_extreme, nrow(joint)))

# Also compute correlation between placebo ATTs
rho_hat <- cor(joint[state != "Oregon", att_d1],
               joint[state != "Oregon", att_d2], use = "complete.obs")
cat(sprintf("  Estimated correlation (placebo ATTs): %.3f\n", rho_hat))

# Save joint permutation results
fwrite(joint, file.path(data_dir, "joint_permutation.csv"))

# Sensitivity to assumed correlation for the symmetric sum SE
se_d1_val <- main[design == "Decriminalization", se]
se_d2_val <- main[design == "Recriminalization", se]

rho_grid <- c(-0.5, -0.25, 0, 0.25, 0.5, 0.75, rho_hat)
rho_grid <- sort(unique(round(rho_grid, 3)))

corr_sens <- data.table(
  rho = rho_grid,
  se_sum = sqrt(se_d1_val^2 + se_d2_val^2 + 2 * rho_grid * se_d1_val * se_d2_val),
  z_stat = NA_real_,
  p_value = NA_real_
)
corr_sens[, z_stat := tau_sum_main / se_sum]
corr_sens[, p_value := 2 * pnorm(-abs(z_stat))]

cat("\n  Correlation sensitivity for symmetric sum:\n")
print(corr_sens)
fwrite(corr_sens, file.path(data_dir, "correlation_sensitivity.csv"))

# ============================================================
# 5. Placebo-in-Time Test (Design 1)
# ============================================================
cat("\n--- 5. Placebo-in-Time Test ---\n")

# Use 2019-01 as placebo treatment date (2 years before actual)
placebo_t <- (2019 - 2015) * 12 + 1  # Jan 2019 = t=49
# Restrict to pre-actual-treatment data only
panel_placebo <- as.data.frame(panel[date < as.Date("2021-02-01")])

set.seed(45)
tryCatch({
  synth_placebo <- panel_placebo %>%
    synthetic_control(
      outcome = od_rate, unit = state_name, time = t,
      i_unit = "Oregon", i_time = placebo_t,
      generate_placebos = TRUE
    ) %>%
    generate_predictor(time_window = 1:(placebo_t - 1),
                       od_rate_all = mean(od_rate, na.rm = TRUE)) %>%
    generate_predictor(time_window = (placebo_t - 24):(placebo_t - 1),
                       od_rate_recent = mean(od_rate, na.rm = TRUE)) %>%
    generate_weights(optimization_window = 1:(placebo_t - 1)) %>%
    generate_control()

  plac_sc <- synth_placebo %>% grab_synthetic_control()
  plac_sc$gap <- plac_sc$real_y - plac_sc$synth_y
  plac_post <- plac_sc[plac_sc$time_unit >= placebo_t, ]
  att_placebo <- mean(plac_post$gap, na.rm = TRUE)

  plac_all <- synth_placebo %>% grab_synthetic_control(placebo = TRUE)
  plac_placebo_atts <- plac_all %>%
    filter(time_unit >= placebo_t) %>%
    group_by(.id) %>%
    summarise(mean_gap = mean(real_y - synth_y, na.rm = TRUE), .groups = "drop")
  se_placebo <- sd(plac_placebo_atts$mean_gap[plac_placebo_atts$.id != "Oregon"],
                   na.rm = TRUE)

  # MSPE ratio for RI
  plac_mspe <- plac_all %>%
    mutate(post = time_unit >= placebo_t) %>%
    group_by(.id, post) %>%
    summarise(mspe = mean((real_y - synth_y)^2, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = post, values_from = mspe, names_prefix = "mspe_") %>%
    mutate(mspe_ratio = mspe_TRUE / mspe_FALSE) %>%
    arrange(desc(mspe_ratio))
  plac_rank <- which(plac_mspe$.id == "Oregon")
  plac_ri_p <- plac_rank / nrow(plac_mspe)

  cat(sprintf("  Placebo (Jan 2019): ATT = %.3f (SE: %.3f)\n", att_placebo, se_placebo))
  cat(sprintf("  Placebo RI p-value: %.4f (%d of %d)\n",
              plac_ri_p, plac_rank, nrow(plac_mspe)))

  placebo_result <- data.table(
    check = "Placebo (Jan 2019)", att = att_placebo,
    se = se_placebo, ri_pvalue = plac_ri_p
  )
  fwrite(placebo_result, file.path(data_dir, "placebo_time_test.csv"))

}, error = function(e) {
  cat(sprintf("  Placebo test failed: %s\n", e$message))
  placebo_result <- data.table(
    check = "Placebo (Jan 2019)", att = NA_real_,
    se = NA_real_, ri_pvalue = NA_real_
  )
  fwrite(placebo_result, file.path(data_dir, "placebo_time_test.csv"))
})

# ============================================================
# Compile all robustness results
# ============================================================
cat("\n--- Compiling Robustness Summary ---\n")

robustness_all <- data.table(
  check = "Main (tidysynth SCM)",
  att = main_att,
  se = main_se
)

# Add western states result
if (exists("west_result")) {
  robustness_all <- rbind(robustness_all, west_result)
}

# Add rolling pre-period results
for (i in seq_len(nrow(roll_df))) {
  robustness_all <- rbind(robustness_all,
    data.table(
      check = sprintf("Pre-start: %s", roll_df$pre_start[i]),
      att = roll_df$att[i],
      se = roll_df$se[i]
    ))
}

# Add LOO summary
robustness_all <- rbind(robustness_all,
  data.table(
    check = "LOO mean",
    att = mean(loo_df$att, na.rm = TRUE),
    se = sd(loo_df$att, na.rm = TRUE)
  ))

fwrite(robustness_all, file.path(data_dir, "robustness_summary.csv"))

cat("\nRobustness summary:\n")
print(robustness_all)

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
