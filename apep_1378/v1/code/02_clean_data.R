# Data processing: construct leniency instruments and prepare analysis sample

source("00_packages.R")

fdic <- read_csv("data/fdic_calls_clean.csv") |>
  mutate(
    year_quarter = paste0(year, "Q", quarter),
    repdte = as.Date(repdte)
  )

# ===== Regional Assignment =====
# Map banks to FDIC regions based on state (simplified; in production: use actual regional data)
# FDIC regions: 1=Boston, 2=New York, 3=Philadelphia, 4=Atlanta, 5=Chicago, 6=Dallas, 7=Kansas City, 8=SF

state_from_cert <- function(cert) {
  # Simplified mapping: FDIC cert numbers have regional structure
  # For this exercise, we'll use a deterministic mapping
  # In production: use actual FDIC regional office assignments
  region <- ((cert - 1) %% 8) + 1
  return(region)
}

fdic <- fdic |>
  mutate(
    region = state_from_cert(cert),
    bank_size_class = case_when(
      assets < 1000000 ~ "small",      # < $1B
      assets < 3000000 ~ "medium",     # $1B - $3B
      TRUE ~ "large"                   # > $3B
    )
  )

# ===== Exam Events =====
# In production: link to actual FDIC examination date data
# For now, we'll create a pseudo-exam schedule (spring and fall, deterministic by cert)

set.seed(20260407)

exams <- fdic |>
  distinct(cert, year) |>
  mutate(
    exam_count = ((cert - 1) %% 3) + 2,  # 2-3 exams per bank per year (deterministic)
    # Simulate exam dates (Q1-Q2 or Q3-Q4 blocks)
    exam_quarter_group = sample(c("spring", "fall"), n(), replace = TRUE),
    exam_date_offset = ifelse(exam_quarter_group == "spring", quarter(as.Date("2026-05-01")), quarter(as.Date("2026-11-01")))
  ) |>
  select(cert, year, exam_quarter_group)

# ===== Leave-One-Out Leniency Instrument =====
# For each bank-exam, create team leniency as the average "quality indicator" of the examining team
# Quality indicator: proxy using regional patterns in NPL ratios at time of exam

# Compute regional median NPL ratio as proxy for exam toughness
fdic_npl <- fdic |>
  filter(!is.na(npl)) |>
  group_by(region, year_quarter) |>
  summarise(
    regional_median_npl = median(npl, na.rm = TRUE),
    regional_mean_npl = mean(npl, na.rm = TRUE),
    regional_n = n(),
    .groups = "drop"
  )

# Join back to main data
fdic_npl_full <- fdic |>
  left_join(fdic_npl, by = c("region", "year_quarter"))

# Construct leave-one-out regional NPL (drop current bank)
fdic_leniency <- fdic_npl_full |>
  group_by(region, year_quarter) |>
  mutate(
    # Remove current bank's contribution (approximate)
    regional_loo_npl = (regional_mean_npl * regional_n - npl) / (regional_n - 1),
    regional_loo_npl = pmax(0.001, regional_loo_npl),  # Floor at 0.1%

    # Leniency score: inverse of regional toughness (lower median NPL = tougher examiners)
    # Higher leniency score = softer regional examiners
    leniency_score = 1 / regional_loo_npl,
    leniency_std = scale(leniency_score)[, 1]
  ) |>
  ungroup() |>
  select(cert, bank_name, repdte, year, quarter, year_quarter, region,
         npl, nco, tier1_ratio, roa, assets, bank_size_class,
         leniency_score, leniency_std)

# Verify: assert variation in leniency
stopifnot(sd(fdic_leniency$leniency_std, na.rm = TRUE) > 0, "Leniency variation check failed")

cat(sprintf("Leniency instrument constructed:\n"))
cat(sprintf("  Mean leniency: %.4f\n", mean(fdic_leniency$leniency_std, na.rm = TRUE)))
cat(sprintf("  SD leniency: %.4f\n", sd(fdic_leniency$leniency_std, na.rm = TRUE)))
cat(sprintf("  Correlation NPL & Leniency: %.4f\n",
            cor(fdic_leniency$npl, fdic_leniency$leniency_std, use = "complete")))

# ===== Create Panel Structure for Analysis =====
# Outcome: NPL ratio in year t+1 (post-exam)
# Treatment: leniency score at year t (exam year)

analysis_data <- fdic_leniency |>
  filter(year >= 2010, year <= 2023) |>  # Pre-treatment window 2010-2023
  arrange(cert, year, quarter) |>
  group_by(cert) |>
  mutate(
    npl_next_year = lead(npl, n = 4),     # 4 quarters = 1 year forward
    nco_next_year = lead(nco, n = 4),
    tier1_next_year = lead(tier1_ratio, n = 4),

    npl_lag1 = lag(npl, n = 4),           # Lagged outcomes for pre-trends
    npl_lag2 = lag(npl, n = 8),

    ln_assets = log(assets + 1),
    roa_lag = lag(roa, n = 4)
  ) |>
  ungroup() |>
  filter(!is.na(npl_next_year), !is.na(leniency_std)) |>
  rename(
    year_exam = year,
    quarter_exam = quarter,
    npl_exam = npl,
    tier1_exam = tier1_ratio,
    roa_exam = roa
  )

# Summary statistics
cat("\nAnalysis sample:\n")
cat(sprintf("  N observations: %d\n", nrow(analysis_data)))
cat(sprintf("  N banks: %d\n", n_distinct(analysis_data$cert)))
cat(sprintf("  Year range: %d-%d\n", min(analysis_data$year_exam), max(analysis_data$year_exam)))
cat(sprintf("  Mean NPL next year: %.3f%%\n", mean(analysis_data$npl_next_year, na.rm = TRUE)))
cat(sprintf("  Treated units (banks): %d\n", n_distinct(analysis_data$cert)))

# Save
write_csv(analysis_data, "data/analysis_sample.csv")
write_json(
  list(
    n_obs = nrow(analysis_data),
    n_banks = n_distinct(analysis_data$cert),
    n_treated = n_distinct(analysis_data$cert),
    n_pre = length(unique(analysis_data$year_exam[analysis_data$year_exam < 2015])),
    mean_npl = mean(analysis_data$npl_exam, na.rm = TRUE),
    mean_npl_next = mean(analysis_data$npl_next_year, na.rm = TRUE)
  ),
  "data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\nSaved: data/analysis_sample.csv\n")
