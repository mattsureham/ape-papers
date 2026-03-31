# 04_robustness.R — Robustness checks and placebo tests
# APEP-1194: Positive Train Control and Railroad Accident Prevention

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/cs_results.rds")
twfe_results <- readRDS("../data/twfe_results.rds")

# Balance the panel (same as 03_main_analysis.R)
all_rr <- unique(panel$railroad)
all_years <- min(panel$year):max(panel$year)
full_grid <- expand.grid(railroad = all_rr, year = all_years, stringsAsFactors = FALSE)
rr_info <- panel %>% distinct(railroad, first_treat, railroad_id)

panel <- full_grid %>%
  left_join(panel %>% select(-first_treat, -railroad_id), by = c("railroad", "year")) %>%
  left_join(rr_info, by = "railroad") %>%
  mutate(
    across(c(total_accidents, human_factor_accidents, non_human_accidents,
             track_accidents, equipment_accidents, signal_accidents,
             total_killed, total_injured, total_damage,
             human_killed, human_injured, ptc_accident_count),
           ~replace_na(., 0)),
    first_treat = as.double(first_treat),
    post_ptc = ifelse(first_treat > 0 & year >= first_treat, 1, 0),
    asinh_total = asinh(total_accidents),
    asinh_human = asinh(human_factor_accidents),
    asinh_nonhuman = asinh(non_human_accidents),
    asinh_track = asinh(track_accidents),
    asinh_equip = asinh(equipment_accidents),
    asinh_killed = asinh(total_killed),
    asinh_injured = asinh(total_injured),
    log_damage = log1p(total_damage)
  )

# ---- 1. Wild Cluster Bootstrap for TWFE ----
cat("=== Wild Cluster Bootstrap ===\n")

# Human-factor accidents
twfe_human <- feols(asinh_human ~ post_ptc | railroad_id + year,
                    data = panel, cluster = ~railroad_id)

boot_human <- tryCatch({
  boottest(twfe_human, param = "post_ptc", clustid = ~railroad_id,
           B = 9999, type = "webb")
}, error = function(e) {
  cat("  Bootstrap failed for human-factor:", e$message, "\n")
  NULL
})

if (!is.null(boot_human)) {
  cat(sprintf("  Human-factor: boot p = %.4f, CI = [%.4f, %.4f]\n",
              boot_human$p_val, boot_human$conf_int[1], boot_human$conf_int[2]))
}

# Injuries
twfe_injured <- feols(asinh_injured ~ post_ptc | railroad_id + year,
                      data = panel, cluster = ~railroad_id)

boot_injured <- tryCatch({
  boottest(twfe_injured, param = "post_ptc", clustid = ~railroad_id,
           B = 9999, type = "webb")
}, error = function(e) {
  cat("  Bootstrap failed for injuries:", e$message, "\n")
  NULL
})

if (!is.null(boot_injured)) {
  cat(sprintf("  Injuries: boot p = %.4f, CI = [%.4f, %.4f]\n",
              boot_injured$p_val, boot_injured$conf_int[1], boot_injured$conf_int[2]))
}

# Non-human (placebo)
twfe_nonhuman <- feols(asinh_nonhuman ~ post_ptc | railroad_id + year,
                       data = panel, cluster = ~railroad_id)

boot_nonhuman <- tryCatch({
  boottest(twfe_nonhuman, param = "post_ptc", clustid = ~railroad_id,
           B = 9999, type = "webb")
}, error = function(e) {
  cat("  Bootstrap failed for non-human:", e$message, "\n")
  NULL
})

if (!is.null(boot_nonhuman)) {
  cat(sprintf("  Non-human (placebo): boot p = %.4f, CI = [%.4f, %.4f]\n",
              boot_nonhuman$p_val, boot_nonhuman$conf_int[1], boot_nonhuman$conf_int[2]))
}

# ---- 2. Bacon Decomposition ----
cat("\n=== Bacon Decomposition ===\n")
# Requires binary treatment. Use only treated vs never-treated comparison.
panel_bacon <- panel %>%
  mutate(treat_post = as.numeric(post_ptc))

bacon_result <- tryCatch({
  bacon(asinh_human ~ treat_post,
        data = panel_bacon,
        id_var = "railroad_id",
        time_var = "year")
}, error = function(e) {
  cat("  Bacon decomposition failed:", e$message, "\n")
  NULL
})

if (!is.null(bacon_result)) {
  cat("\nBacon decomposition weights:\n")
  # bacon() returns a data.frame with type, weight, estimate (or avg_est)
  est_col <- intersect(c("estimate", "avg_est"), names(bacon_result))
  if (length(est_col) > 0) {
    bacon_summary <- bacon_result %>%
      group_by(type) %>%
      summarise(
        total_weight = sum(weight),
        avg_estimate = sum(weight * .data[[est_col[1]]]) / sum(weight),
        .groups = "drop"
      )
    print(bacon_summary)
  } else {
    print(bacon_result)
  }
}

# ---- 3. Leave-One-Out: Drop each Class I railroad ----
cat("\n=== Leave-One-Out (Class I Railroads) ===\n")

# Identify Class I railroads (the largest: BNSF, CSX, NS, UP, CN, CP, KCS)
class1_codes <- c("BNSF", "CSX", "NS", "UP", "CN", "CP", "KCS", "CSXT")

# Check which exist in our data
class1_in_data <- intersect(class1_codes, unique(panel$railroad))
cat("Class I railroads in sample:", paste(class1_in_data, collapse = ", "), "\n")

loo_results <- list()
for (rr in class1_in_data) {
  panel_loo <- panel %>% filter(railroad != rr)

  twfe_loo <- tryCatch({
    feols(asinh_human ~ post_ptc | railroad_id + year,
          data = panel_loo, cluster = ~railroad_id)
  }, error = function(e) NULL)

  if (!is.null(twfe_loo)) {
    loo_results[[rr]] <- data.frame(
      dropped = rr,
      estimate = coef(twfe_loo)["post_ptc"],
      se = se(twfe_loo)["post_ptc"],
      stringsAsFactors = FALSE
    )
    cat(sprintf("  Drop %s: β = %.4f (%.4f)\n", rr,
                coef(twfe_loo)["post_ptc"], se(twfe_loo)["post_ptc"]))
  }
}

loo_df <- bind_rows(loo_results)

# ---- 4. Level specification (raw counts) ----
cat("\n=== Level Specification (Raw Counts) ===\n")

twfe_human_level <- feols(human_factor_accidents ~ post_ptc | railroad_id + year,
                          data = panel, cluster = ~railroad_id)
twfe_nonhuman_level <- feols(non_human_accidents ~ post_ptc | railroad_id + year,
                             data = panel, cluster = ~railroad_id)
twfe_total_level <- feols(total_accidents ~ post_ptc | railroad_id + year,
                          data = panel, cluster = ~railroad_id)
twfe_injured_level <- feols(total_injured ~ post_ptc | railroad_id + year,
                            data = panel, cluster = ~railroad_id)

cat("\nLevel specification results:\n")
etable(twfe_human_level, twfe_nonhuman_level, twfe_total_level, twfe_injured_level,
       headers = c("Human", "Non-Human", "Total", "Injured"))

# ---- 5. Poisson specification ----
cat("\n=== Poisson PPML Specification ===\n")

ppml_human <- tryCatch({
  fepois(human_factor_accidents ~ post_ptc | railroad_id + year,
         data = panel, cluster = ~railroad_id)
}, error = function(e) {
  cat("  Poisson failed for human-factor:", e$message, "\n")
  NULL
})

ppml_nonhuman <- tryCatch({
  fepois(non_human_accidents ~ post_ptc | railroad_id + year,
         data = panel, cluster = ~railroad_id)
}, error = function(e) {
  cat("  Poisson failed for non-human:", e$message, "\n")
  NULL
})

ppml_injured <- tryCatch({
  fepois(total_injured ~ post_ptc | railroad_id + year,
         data = panel, cluster = ~railroad_id)
}, error = function(e) {
  cat("  Poisson failed for injuries:", e$message, "\n")
  NULL
})

if (!is.null(ppml_human) && !is.null(ppml_nonhuman)) {
  cat("\nPoisson results:\n")
  models_ppml <- list(ppml_human, ppml_nonhuman)
  if (!is.null(ppml_injured)) models_ppml <- c(models_ppml, list(ppml_injured))
  hdrs <- c("Human (Poisson)", "Non-Human (Poisson)")
  if (!is.null(ppml_injured)) hdrs <- c(hdrs, "Injured (Poisson)")
  etable(models_ppml, headers = hdrs)
}

# ---- 6. Restrict to pre-2020 adoption cohorts (avoid COVID contamination) ----
cat("\n=== Pre-2020 Adoption Cohorts Only ===\n")

panel_pre2020 <- panel %>%
  filter(first_treat == 0 | first_treat <= 2019)

cat(sprintf("Railroads in pre-2020 sample: %d (treated: %d)\n",
            n_distinct(panel_pre2020$railroad),
            n_distinct(panel_pre2020$railroad[panel_pre2020$first_treat > 0])))

twfe_pre2020 <- feols(asinh_human ~ post_ptc | railroad_id + year,
                      data = panel_pre2020, cluster = ~railroad_id)
cat("Pre-2020 cohorts: β =", round(coef(twfe_pre2020)["post_ptc"], 4),
    "SE =", round(se(twfe_pre2020)["post_ptc"], 4), "\n")

# ---- 7. Sub-cause analysis: specific H-codes ----
cat("\n=== Sub-Cause Analysis ===\n")

# Reload raw data to get specific cause codes
raw_df <- readRDS("../data/fra_form54_raw.rds")
raw_df <- raw_df %>%
  mutate(
    accident_date = as.Date(substr(date, 1, 10)),
    accident_year = as.integer(format(accident_date, "%Y")),
    cause_prefix = toupper(substr(accidentcausecode, 1, 1))
  )

# Count specific human-factor subcategories by railroad-year
# H-codes: H000-H099 = brakes, H100-H199 = switches, H200-H299 = signals, H300+ = speed/other
h_subcats <- raw_df %>%
  filter(cause_prefix == "H", accident_year >= 2000) %>%
  mutate(
    h_code_num = as.numeric(gsub("[^0-9]", "", accidentcausecode)),
    h_subcat = case_when(
      h_code_num < 100 ~ "Brakes_Handling",
      h_code_num < 200 ~ "Switches_TrackAuth",
      h_code_num < 300 ~ "Signal_Violations",
      TRUE ~ "Speed_Other"
    )
  ) %>%
  select(reportingrailroadcode, accident_year, h_subcat) %>%
  group_by(reportingrailroadcode, accident_year, h_subcat) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = h_subcat, values_from = n, values_fill = 0) %>%
  rename(railroad = reportingrailroadcode, year = accident_year)

cat("H-code subcategories computed.\n")
cat("Subcategory counts (total across all railroad-years):\n")
colSums(h_subcats %>% select(-railroad, -year)) %>% print()

# ---- Save robustness results ----
robustness <- list(
  boot_human = boot_human,
  boot_injured = boot_injured,
  boot_nonhuman = boot_nonhuman,
  bacon = bacon_result,
  loo = loo_df,
  twfe_level = list(human = twfe_human_level, nonhuman = twfe_nonhuman_level,
                    total = twfe_total_level, injured = twfe_injured_level),
  ppml = list(human = ppml_human, nonhuman = ppml_nonhuman, injured = ppml_injured),
  pre2020 = twfe_pre2020
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nAll robustness results saved.\n")
