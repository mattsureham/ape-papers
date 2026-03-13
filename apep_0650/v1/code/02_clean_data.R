## 02_clean_data.R — Construct analysis dataset
## Merge QWI with MW data, build county-pair panel

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))
source("code/00_packages.R")

cat("=== Loading saved data ===\n")
border_pairs <- readRDS("data/border_pairs.rds")
mw_panel     <- readRDS("data/mw_panel.rds")
qwi_raw      <- readRDS("data/qwi_border.rds")

cat("Border pairs:", nrow(border_pairs), "\n")
cat("MW panel:", nrow(mw_panel), "\n")
cat("QWI raw:", nrow(qwi_raw), "\n")

cat("\n=== Step 1: Merge QWI with MW ===\n")
# Add state FIPS to QWI
qwi <- qwi_raw |>
  mutate(state_fips = substr(fips, 1, 2))

# Merge with MW
qwi <- qwi |>
  inner_join(
    mw_panel |> select(state_fips, year, quarter, eff_mw, log_mw),
    by = c("state_fips", "year", "quarter")
  )

cat("QWI after MW merge:", nrow(qwi), "\n")
stopifnot("MW merge produced empty dataset" = nrow(qwi) > 0)

cat("\n=== Step 2: Build county-pair panel ===\n")
# For each border pair, create a long panel with both counties
# Each observation = pair × quarter × industry × age group × county side

# County A observations
pair_a <- border_pairs |>
  select(pair_id, fips_a, fips_b, state_a, state_b) |>
  inner_join(qwi, by = c("fips_a" = "fips"), relationship = "many-to-many") |>
  rename(fips = fips_a) |>
  mutate(side = "A")

# County B observations
pair_b <- border_pairs |>
  select(pair_id, fips_a, fips_b, state_a, state_b) |>
  inner_join(qwi, by = c("fips_b" = "fips"), relationship = "many-to-many") |>
  rename(fips = fips_b) |>
  mutate(side = "B")

pair_panel <- bind_rows(pair_a, pair_b) |>
  arrange(pair_id, year, quarter, industry, agegrp, side)

cat("Pair panel rows:", nrow(pair_panel), "\n")
cat("Unique pairs:", n_distinct(pair_panel$pair_id), "\n")
cat("Industries:", paste(sort(unique(pair_panel$industry)), collapse = ", "), "\n")

cat("\n=== Step 3: Construct rate variables ===\n")
# Normalize firm dynamics by employment base
pair_panel <- pair_panel |>
  mutate(
    # Firm dynamics rates (per 100 jobs)
    jc_rate = ifelse(Emp > 0, (FrmJbGn / Emp) * 100, NA_real_),
    jd_rate = ifelse(Emp > 0, (FrmJbLs / Emp) * 100, NA_real_),
    net_jc_rate = jc_rate - jd_rate,
    # Hiring/separation rates
    hire_rate = ifelse(Emp > 0, (HirA / Emp) * 100, NA_real_),
    new_hire_rate = ifelse(Emp > 0, (HirN / Emp) * 100, NA_real_),
    sep_rate = ifelse(Emp > 0, (Sep / Emp) * 100, NA_real_),
    # Log employment and earnings
    log_emp = log(pmax(Emp, 1)),
    log_earn = log(pmax(EarnS, 1)),
    # Time index
    time_index = (year - 2001) * 4 + quarter
  )

# Drop observations with zero employment (no meaningful rates)
pair_panel <- pair_panel |>
  filter(Emp > 0, !is.na(eff_mw))

cat("Panel after cleaning:", nrow(pair_panel), "\n")

cat("\n=== Step 4: Summary statistics ===\n")

# All-industry, all-age summary
summ_all <- pair_panel |>
  filter(industry == "00", agegrp == "A00") |>
  summarise(
    n_obs = n(),
    n_pairs = n_distinct(pair_id),
    n_counties = n_distinct(fips),
    mean_emp = mean(Emp, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    mean_mw = mean(eff_mw, na.rm = TRUE),
    sd_mw = sd(eff_mw, na.rm = TRUE),
    mean_jc_rate = mean(jc_rate, na.rm = TRUE),
    mean_jd_rate = mean(jd_rate, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE)
  )

cat("Summary (all industries, all ages):\n")
print(summ_all)

# MW differential across pairs
mw_diffs <- pair_panel |>
  filter(industry == "00", agegrp == "A00") |>
  group_by(pair_id, year, quarter) |>
  summarise(
    mw_diff = max(eff_mw) - min(eff_mw),
    .groups = "drop"
  )

cat("\nMW differential distribution:\n")
cat("  Mean:", round(mean(mw_diffs$mw_diff), 2), "\n")
cat("  Median:", round(median(mw_diffs$mw_diff), 2), "\n")
cat("  Max:", round(max(mw_diffs$mw_diff), 2), "\n")
cat("  Pairs with diff > $2:", sum(mw_diffs$mw_diff > 2) / nrow(mw_diffs) * 100, "%\n")

# Save summary stats for table generation
summary_stats <- pair_panel |>
  filter(industry == "00", agegrp == "A00") |>
  summarise(
    across(c(Emp, EarnS, eff_mw, jc_rate, jd_rate, hire_rate, sep_rate, log_emp, log_earn),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

saveRDS(summary_stats, "data/summary_stats.rds")

cat("\n=== Step 5: Save analysis dataset ===\n")
saveRDS(pair_panel, "data/pair_panel.rds")
cat("Saved data/pair_panel.rds:", nrow(pair_panel), "rows\n")

cat("\n=== Cleaning Complete ===\n")
