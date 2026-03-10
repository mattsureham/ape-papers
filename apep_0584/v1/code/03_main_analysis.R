## 03_main_analysis.R — Synthetic Control for both policy switches
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test
## Uses tidysynth (Abadie et al. solver)

source("00_packages.R")
library(tidysynth)

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]
panel[, t := (year - 2015) * 12 + month_num]

# Handle missing values
panel[, od_rate := nafill(od_rate, type = "locf"), by = state_name]
panel[, fent_rate := nafill(fent_rate, type = "locf"), by = state_name]
panel[, heroin_rate := nafill(heroin_rate, type = "locf"), by = state_name]
panel[, psycho_rate := nafill(psycho_rate, type = "locf"), by = state_name]
panel[, cocaine_rate := nafill(cocaine_rate, type = "locf"), by = state_name]
panel[, fent_share := fifelse(is.na(fent_share), 0, fent_share)]

# Drop states still missing od_rate
panel <- panel[!is.na(od_rate)]

cat("=== MAIN ANALYSIS: SYNTHETIC CONTROL METHOD ===\n")
cat(sprintf("Panel: %d states, %d months\n\n",
            uniqueN(panel$state_name), uniqueN(panel$t)))

# ============================================================
# Design 1: Decriminalization Effect (Feb 2021)
# ============================================================
cat("--- DESIGN 1: DECRIMINALIZATION (Feb 2021) ---\n")

panel_d1 <- as.data.frame(panel[date < as.Date("2024-09-01")])
decrim_t <- 74  # Feb 2021 = (2021-2015)*12 + 2

set.seed(20210201)  # Seed for reproducibility (Design 1)
cat("Running SCM with placebos (Design 1)...\n")
synth_d1 <- panel_d1 %>%
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

cat("Design 1 complete.\n")

# Extract treated vs synthetic
d1_sc <- synth_d1 %>% grab_synthetic_control()
d1_sc$gap <- d1_sc$real_y - d1_sc$synth_y

# Post-treatment ATT
d1_post <- d1_sc %>% filter(time_unit >= decrim_t)
att_d1 <- mean(d1_post$gap, na.rm = TRUE)

# Pre-treatment fit (RMSPE)
d1_pre <- d1_sc %>% filter(time_unit < decrim_t)
rmspe_d1 <- sqrt(mean(d1_pre$gap^2, na.rm = TRUE))

# Weights
d1_weights <- synth_d1 %>% grab_unit_weights()

cat("\nTop donor weights (Design 1):\n")
print(d1_weights %>% filter(weight > 0.01) %>% arrange(desc(weight)))

# Permutation inference via MSPE ratios
d1_all <- synth_d1 %>% grab_synthetic_control(placebo = TRUE)
mspe_d1 <- d1_all %>%
  mutate(post = time_unit >= decrim_t) %>%
  group_by(.id, post) %>%
  summarise(mspe = mean((real_y - synth_y)^2, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = post, values_from = mspe, names_prefix = "mspe_") %>%
  mutate(mspe_ratio = mspe_TRUE / mspe_FALSE) %>%
  arrange(desc(mspe_ratio))

oregon_rank_d1 <- which(mspe_d1$.id == "Oregon")
ri_pvalue_d1 <- oregon_rank_d1 / nrow(mspe_d1)

# SE from placebo distribution (exclude Oregon — the treated unit)
d1_placebo_atts <- d1_all %>%
  filter(time_unit >= decrim_t) %>%
  group_by(.id) %>%
  summarise(mean_gap = mean(real_y - synth_y, na.rm = TRUE), .groups = "drop")
se_d1 <- sd(d1_placebo_atts$mean_gap[d1_placebo_atts$.id != "Oregon"], na.rm = TRUE)

cat(sprintf("\nDesign 1 Results:\n"))
cat(sprintf("  ATT: %.3f deaths/100K\n", att_d1))
cat(sprintf("  Pre-treatment RMSPE: %.3f\n", rmspe_d1))
cat(sprintf("  SE (placebo SD): %.3f\n", se_d1))
cat(sprintf("  RI p-value (MSPE ratio): %.4f (%d of %d)\n",
            ri_pvalue_d1, oregon_rank_d1, nrow(mspe_d1)))

# Save
d1_att_series <- d1_sc %>%
  transmute(time = time_unit, att_est = gap, oregon = real_y, synthetic = synth_y)
fwrite(as.data.table(d1_att_series), file.path(data_dir, "att_decrim.csv"))
fwrite(as.data.table(d1_weights), file.path(data_dir, "scm_weights_decrim.csv"))
fwrite(as.data.table(mspe_d1), file.path(data_dir, "mspe_ratios_d1.csv"))

# ============================================================
# Design 2: Recriminalization Effect (Sep 2024)
# ============================================================
cat("\n--- DESIGN 2: RECRIMINALIZATION (Sep 2024) ---\n")

panel_d2 <- as.data.frame(panel[date >= as.Date("2021-02-01")])
panel_d2$t2 <- (panel_d2$year - 2021) * 12 + panel_d2$month_num
recrim_t2 <- 45  # Sep 2024 = (2024-2021)*12 + 9

set.seed(20240901)  # Seed for reproducibility (Design 2)
cat("Running SCM with placebos (Design 2)...\n")
synth_d2 <- panel_d2 %>%
  synthetic_control(
    outcome = od_rate, unit = state_name, time = t2,
    i_unit = "Oregon", i_time = recrim_t2,
    generate_placebos = TRUE
  ) %>%
  generate_predictor(time_window = 2:(recrim_t2 - 1),
                     od_rate_all = mean(od_rate, na.rm = TRUE)) %>%
  generate_predictor(time_window = (recrim_t2 - 12):(recrim_t2 - 1),
                     od_rate_recent = mean(od_rate, na.rm = TRUE)) %>%
  generate_predictor(time_window = 2:(max(3, recrim_t2 - 13)),
                     od_rate_early = mean(od_rate, na.rm = TRUE)) %>%
  generate_weights(optimization_window = 2:(recrim_t2 - 1)) %>%
  generate_control()

cat("Design 2 complete.\n")

d2_sc <- synth_d2 %>% grab_synthetic_control()
d2_sc$gap <- d2_sc$real_y - d2_sc$synth_y
d2_post <- d2_sc %>% filter(time_unit >= recrim_t2)
att_d2 <- mean(d2_post$gap, na.rm = TRUE)
rmspe_d2 <- sqrt(mean((d2_sc %>% filter(time_unit < recrim_t2))$gap^2, na.rm = TRUE))

d2_weights <- synth_d2 %>% grab_unit_weights()
cat("\nTop donor weights (Design 2):\n")
print(d2_weights %>% filter(weight > 0.01) %>% arrange(desc(weight)))

d2_all <- synth_d2 %>% grab_synthetic_control(placebo = TRUE)
mspe_d2 <- d2_all %>%
  mutate(post = time_unit >= recrim_t2) %>%
  group_by(.id, post) %>%
  summarise(mspe = mean((real_y - synth_y)^2, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = post, values_from = mspe, names_prefix = "mspe_") %>%
  mutate(mspe_ratio = mspe_TRUE / mspe_FALSE) %>%
  arrange(desc(mspe_ratio))

oregon_rank_d2 <- which(mspe_d2$.id == "Oregon")
ri_pvalue_d2 <- oregon_rank_d2 / nrow(mspe_d2)

# SE from placebo distribution (exclude Oregon — the treated unit)
d2_placebo_atts <- d2_all %>%
  filter(time_unit >= recrim_t2) %>%
  group_by(.id) %>%
  summarise(mean_gap = mean(real_y - synth_y, na.rm = TRUE), .groups = "drop")
se_d2 <- sd(d2_placebo_atts$mean_gap[d2_placebo_atts$.id != "Oregon"], na.rm = TRUE)

cat(sprintf("\nDesign 2 Results:\n"))
cat(sprintf("  ATT: %.3f deaths/100K\n", att_d2))
cat(sprintf("  Pre-treatment RMSPE: %.3f\n", rmspe_d2))
cat(sprintf("  SE (placebo SD): %.3f\n", se_d2))
cat(sprintf("  RI p-value (MSPE ratio): %.4f (%d of %d)\n",
            ri_pvalue_d2, oregon_rank_d2, nrow(mspe_d2)))

d2_att_series <- d2_sc %>%
  transmute(time = time_unit, att_est = gap, oregon = real_y, synthetic = synth_y)
fwrite(as.data.table(d2_att_series), file.path(data_dir, "att_recrim.csv"))
fwrite(as.data.table(d2_weights), file.path(data_dir, "scm_weights_recrim.csv"))
fwrite(as.data.table(mspe_d2), file.path(data_dir, "mspe_ratios_d2.csv"))

# ============================================================
# Design 3: Symmetric Test
# ============================================================
cat("\n--- DESIGN 3: SYMMETRIC TEST ---\n")

tau_d <- att_d1
tau_r <- att_d2
tau_sum <- tau_d + tau_r
se_sum <- sqrt(se_d1^2 + se_d2^2)
z_sum <- tau_sum / se_sum
p_sum <- 2 * pnorm(-abs(z_sum))
reversal_ratio <- ifelse(tau_d != 0, -tau_r / tau_d, NA)

cat(sprintf("  tau_decrim   = %.3f (SE: %.3f)\n", tau_d, se_d1))
cat(sprintf("  tau_recrim   = %.3f (SE: %.3f)\n", tau_r, se_d2))
cat(sprintf("  tau_sum      = %.3f (SE: %.3f)\n", tau_sum, se_sum))
cat(sprintf("  z-stat       = %.3f\n", z_sum))
cat(sprintf("  p-value      = %.4f\n", p_sum))
cat(sprintf("  Reversal ratio: %.2f\n", reversal_ratio))

sym_test <- data.table(
  tau_decrim = tau_d, se_decrim = se_d1,
  tau_recrim = tau_r, se_recrim = se_d2,
  tau_sum = tau_sum, se_sum = se_sum,
  z_stat = z_sum, p_value = p_sum,
  reversal_ratio = reversal_ratio
)
fwrite(sym_test, file.path(data_dir, "symmetric_test.csv"))

# ============================================================
# Drug Decomposition (Mechanism Test)
# ============================================================
cat("\n--- DRUG DECOMPOSITION ---\n")

drug_cols <- c("fent_rate", "heroin_rate", "psycho_rate", "cocaine_rate")
drug_labels <- c("Synthetic Opioids (Fentanyl)", "Heroin",
                 "Psychostimulants", "Cocaine")

decomp_results <- list()

for (i in seq_along(drug_cols)) {
  drug_col <- drug_cols[i]
  label <- drug_labels[i]
  cat(sprintf("\n  Drug: %s\n", label))

  panel_drug <- as.data.frame(as.data.table(panel_d1))
  panel_drug$drug_y <- panel_drug[[drug_col]]
  # Fill remaining NAs with 0 (suppressed counts)
  panel_drug$drug_y[is.na(panel_drug$drug_y)] <- 0

  tryCatch({
    synth_drug <- panel_drug %>%
      synthetic_control(
        outcome = drug_y, unit = state_name, time = t,
        i_unit = "Oregon", i_time = decrim_t,
        generate_placebos = FALSE
      ) %>%
      generate_predictor(time_window = 1:(decrim_t - 1),
                         drug_pre = mean(drug_y, na.rm = TRUE)) %>%
      generate_weights(optimization_window = 1:(decrim_t - 1)) %>%
      generate_control()

    drug_sc <- synth_drug %>% grab_synthetic_control()
    drug_sc$gap <- drug_sc$real_y - drug_sc$synth_y
    drug_post <- drug_sc %>% filter(time_unit >= decrim_t)
    att_drug <- mean(drug_post$gap, na.rm = TRUE)
    drug_pre_sc <- drug_sc %>% filter(time_unit < decrim_t)
    se_drug <- sqrt(mean(drug_pre_sc$gap^2, na.rm = TRUE))

    decomp_results[[label]] <- data.table(
      drug = label, outcome_var = drug_col,
      att = att_drug, se = se_drug,
      p_value = 2 * pnorm(-abs(att_drug / se_drug))
    )
    cat(sprintf("    ATT: %.3f (RMSPE: %.3f)\n", att_drug, se_drug))

    fwrite(as.data.table(drug_sc %>% transmute(time = time_unit, att_est = gap)),
           file.path(data_dir, sprintf("att_drug_%s.csv",
                                        gsub("[^a-z]", "", tolower(label)))))
  }, error = function(e) {
    cat(sprintf("    FAILED: %s\n", e$message))
    decomp_results[[label]] <<- data.table(
      drug = label, outcome_var = drug_col,
      att = NA_real_, se = NA_real_, p_value = NA_real_
    )
  })
}

decomp_df <- rbindlist(decomp_results)
fwrite(decomp_df, file.path(data_dir, "drug_decomposition.csv"))

# ============================================================
# Save placebo data and main results
# ============================================================
fwrite(as.data.table(d1_placebo_atts %>%
  rename(state = .id, placebo_att = mean_gap) %>%
  mutate(is_oregon = state == "Oregon")),
  file.path(data_dir, "placebo_atts.csv"))

fwrite(as.data.table(d2_placebo_atts %>%
  rename(state = .id, placebo_att = mean_gap) %>%
  mutate(is_oregon = state == "Oregon", design = "Recriminalization")),
  file.path(data_dir, "placebo_atts_d2.csv"))

main_results <- data.table(
  design = c("Decriminalization", "Recriminalization", "Symmetric Sum"),
  att = c(tau_d, tau_r, tau_sum),
  se = c(se_d1, se_d2, se_sum),
  p_value = c(2 * pnorm(-abs(tau_d / se_d1)),
              2 * pnorm(-abs(tau_r / se_d2)),
              p_sum),
  ri_pvalue = c(ri_pvalue_d1, ri_pvalue_d2, NA_real_)
)
fwrite(main_results, file.path(data_dir, "main_results.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
