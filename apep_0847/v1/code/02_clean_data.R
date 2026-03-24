# 02_clean_data.R — Clean and merge all data for apep_0847
# Stop smoking service austerity and respiratory health in England

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

# ---- 1. Extract grant allocations from 2016/17 XLSX ----
cat("=== Extracting grant allocations ===\n")

# Sheet 2: has 2015/16 baseline and 2016/17 allocation per head by LA
d <- read_xlsx(file.path(data_dir, "grant_2016_17.xlsx"), sheet = 2, skip = 0,
               col_names = FALSE)
names(d) <- paste0("V", seq_len(ncol(d)))

# Find header row (contains "ONS code")
hdr_idx <- which(grepl("ONS code", d$V1, ignore.case = TRUE))
if (length(hdr_idx) == 0) stop("FATAL: Cannot find header row in grant file")
cat(sprintf("Header at row %d\n", hdr_idx))

# Data starts after header
d <- d[(hdr_idx + 1):nrow(d), ]
# Keep only LA rows (ONS codes start with E)
d <- d[grepl("^E0[6-9]|^E10", d$V1), ]

grants_baseline <- data.frame(
  area_code      = d$V1,
  la_name        = d$V2,
  baseline_pc    = as.numeric(d$V4),  # 2015/16 per head (£)
  grant_pc_1617  = as.numeric(d$V7),  # 2016/17 per head (£)
  stringsAsFactors = FALSE
) %>%
  filter(!is.na(baseline_pc))

cat(sprintf("Baseline grants: %d LAs\n", nrow(grants_baseline)))
cat(sprintf("Baseline per-head: mean=%.1f, sd=%.1f, min=%.1f, max=%.1f\n",
            mean(grants_baseline$baseline_pc), sd(grants_baseline$baseline_pc),
            min(grants_baseline$baseline_pc), max(grants_baseline$baseline_pc)))

# ---- 2. Clean Fingertips health outcomes ----
cat("\n=== Cleaning Fingertips data ===\n")

clean_fingertips <- function(rds_file, outcome_name) {
  df <- readRDS(file.path(data_dir, rds_file))
  df <- df %>%
    filter(
      grepl("^E0[6-9]|^E10", `Area Code`),  # upper-tier LAs only
      Sex == "Persons",
      !is.na(Value)
    ) %>%
    mutate(
      area_code = `Area Code`,
      area_name = `Area Name`,
      value = Value,
      lower_ci = `Lower CI 95.0 limit`,
      upper_ci = `Upper CI 95.0 limit`,
      count = Count,
      denominator = Denominator,
      time_period = `Time period`,
      year_start = case_when(
        grepl("^\\d{4}/\\d{2}$", time_period) ~ as.integer(str_sub(time_period, 1, 4)),
        grepl("^\\d{4}$", time_period) ~ as.integer(time_period),
        grepl("^\\d{4} - \\d{2}$", time_period) ~ as.integer(str_sub(time_period, 1, 4)),
        TRUE ~ NA_integer_
      )
    ) %>%
    filter(!is.na(year_start)) %>%
    select(area_code, area_name, time_period, year_start, value, lower_ci,
           upper_ci, count, denominator)

  cat(sprintf("  %s: %d obs, %d LAs, years %d-%d\n", outcome_name, nrow(df),
              n_distinct(df$area_code), min(df$year_start), max(df$year_start)))
  df
}

smoking  <- clean_fingertips("smoking_prev_raw.rds", "Smoking prevalence")
quits    <- clean_fingertips("quit_rate_raw.rds",    "Quit rate")
copd     <- clean_fingertips("copd_admis_raw.rds",   "COPD admissions")
lung_ca  <- clean_fingertips("lung_cancer_raw.rds",  "Lung cancer mortality")
sex_hlth <- clean_fingertips("sexual_health_raw.rds","Sexual health (placebo)")

# ---- 3. Build analysis panels ----
cat("\n=== Building analysis panels ===\n")

# Standardize baseline grant (mean 0, sd 1) for interpretability
baseline_mean <- mean(grants_baseline$baseline_pc)
baseline_sd   <- sd(grants_baseline$baseline_pc)

build_panel <- function(outcome_df, outcome_name, baseline_df = grants_baseline) {
  panel <- outcome_df %>%
    inner_join(baseline_df %>% select(area_code, la_name, baseline_pc),
               by = "area_code") %>%
    mutate(
      post = as.integer(year_start >= 2015),
      # Standardize baseline grant for interpretable coefficients
      baseline_z = (baseline_pc - baseline_mean) / baseline_sd,
      # Interaction: treatment intensity × post
      treat_post = baseline_z * post,
      # Year-specific interactions for event study
      year_factor = factor(year_start)
    )
  cat(sprintf("  %s panel: %d obs, %d LAs, %d years\n", outcome_name,
              nrow(panel), n_distinct(panel$area_code), n_distinct(panel$year_start)))
  panel
}

smoking_panel  <- build_panel(smoking, "Smoking")
quits_panel    <- build_panel(quits, "Quits")
copd_panel     <- build_panel(copd, "COPD")
lung_panel     <- build_panel(lung_ca, "Lung cancer")
placebo_panel  <- build_panel(sex_hlth, "Placebo")

# ---- 4. Summary statistics ----
cat("\n=== Summary Statistics ===\n")

# Pre-period means by high/low baseline grant (median split)
med_grant <- median(grants_baseline$baseline_pc)
cat(sprintf("Median baseline grant per head: £%.1f\n", med_grant))

pre_smoking <- smoking_panel %>%
  filter(year_start < 2015) %>%
  mutate(high_grant = baseline_pc > med_grant)

cat("\nSmoking prevalence (pre-2015), by grant group:\n")
pre_smoking %>%
  group_by(high_grant) %>%
  summarise(
    n_las = n_distinct(area_code),
    mean_smoking = mean(value, na.rm = TRUE),
    sd_smoking = sd(value, na.rm = TRUE),
    mean_grant_pc = mean(baseline_pc),
    .groups = "drop"
  ) %>%
  print()

pre_quits <- quits_panel %>%
  filter(year_start < 2015) %>%
  mutate(high_grant = baseline_pc > med_grant)

cat("\nQuit rate (pre-2015), by grant group:\n")
pre_quits %>%
  group_by(high_grant) %>%
  summarise(
    n_las = n_distinct(area_code),
    mean_quits = mean(value, na.rm = TRUE),
    sd_quits = sd(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ---- Save ----
saveRDS(smoking_panel,  file.path(data_dir, "smoking_panel.rds"))
saveRDS(quits_panel,    file.path(data_dir, "quits_panel.rds"))
saveRDS(copd_panel,     file.path(data_dir, "copd_panel.rds"))
saveRDS(lung_panel,     file.path(data_dir, "lung_panel.rds"))
saveRDS(placebo_panel,  file.path(data_dir, "placebo_panel.rds"))
saveRDS(grants_baseline, file.path(data_dir, "grants_baseline.rds"))

cat("\n=== Cleaning complete ===\n")
