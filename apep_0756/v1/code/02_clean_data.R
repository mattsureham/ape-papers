# 02_clean_data.R — Construct analysis panel
# apep_0756: Fair Workweek, Unfair Turnover?

source("00_packages.R")

df_all <- readRDS("../data/qwi_raw.rds")
treatment_df <- readRDS("../data/treatment_assignment.rds")

# ── Construct time variable ──────────────────────────────────────────────────
# QWI uses year + quarter columns; create a numeric quarter index
df <- df_all %>%
  mutate(
    geography = as.character(geography),
    # Pad FIPS to 5 digits
    fips = str_pad(geography, 5, pad = "0"),
    # Create numeric time index: year + (quarter-1)/4
    time_num = year + (quarter - 1) / 4,
    # Create character quarter label
    yq = paste0(year, "Q", quarter)
  )

cat("Unique counties:", n_distinct(df$fips), "\n")
cat("Unique industries:", unique(df$industry), "\n")
cat("Time range:", range(df$time_num), "\n")

# ── Merge treatment status ───────────────────────────────────────────────────
treated_fips <- unique(treatment_df$fips)
treat_timing <- treatment_df %>%
  distinct(fips, treat_quarter) %>%
  mutate(
    treat_year = as.numeric(str_extract(treat_quarter, "^\\d{4}")),
    treat_q = as.numeric(str_extract(treat_quarter, "\\d$")),
    first_treat_num = treat_year + (treat_q - 1) / 4
  )

df <- df %>%
  left_join(treat_timing, by = "fips") %>%
  mutate(
    treated_county = as.integer(fips %in% treated_fips),
    treated_industry = as.integer(industry %in% c("72", "44-45")),
    post = as.integer(!is.na(first_treat_num) & time_num >= first_treat_num),
    # DDD interaction
    ddd = treated_county * treated_industry * post,
    # DD interactions (for the two-way terms)
    dd_county_post = treated_county * post,
    dd_ind_post = treated_industry * post,
    dd_county_ind = treated_county * treated_industry
  )

# ── Construct outcome variables ──────────────────────────────────────────────
# Key: Sep/Emp = separation rate, HirN/Emp = new hire rate, EarnS = avg earnings
df <- df %>%
  filter(Emp > 0) %>%
  mutate(
    sep_rate = Sep / Emp,
    hire_rate = HirN / Emp,
    all_hire_rate = HirA / Emp,
    earn_avg = EarnS,
    turnover_rate = TurnOvrS / Emp,
    log_emp = log(Emp),
    log_earn = ifelse(EarnS > 0, log(EarnS), NA_real_)
  )

# ── Create county-industry panel ID ─────────────────────────────────────────
df <- df %>%
  mutate(
    county_ind = paste0(fips, "_", industry),
    # For CS estimator: first_treat as integer quarter index
    # Map time_num to integer: (year - 2012) * 4 + quarter
    t_int = (year - 2012) * 4 + quarter,
    # first_treat for CS: 0 for never-treated
    first_treat_int = ifelse(
      is.na(first_treat_num),
      0,
      (treat_year - 2012) * 4 + treat_q
    )
  )

# ── Trim to pre-COVID for main analysis ──────────────────────────────────────
# Main sample: 2013Q1 - 2019Q4 (exclude COVID period)
df_main <- df %>%
  filter(year >= 2013, year <= 2019) %>%
  # Drop observations with missing key variables
  filter(!is.na(sep_rate), !is.na(hire_rate))

cat("\n=== Panel summary ===\n")
cat("Main sample (2013-2019):\n")
cat("  Observations:", nrow(df_main), "\n")
cat("  County-industries:", n_distinct(df_main$county_ind), "\n")
cat("  Treated counties:", sum(df_main$treated_county == 1 & df_main$treated_industry == 1) /
    n_distinct(df_main$time_num[df_main$treated_county == 1 & df_main$treated_industry == 1]), "\n")
cat("  Quarters:", n_distinct(df_main$t_int), "\n")

# Summary stats by treatment group
cat("\n=== Pre-treatment means (treated industries) ===\n")
df_main %>%
  filter(treated_industry == 1, post == 0 | treated_county == 0) %>%
  group_by(treated_county) %>%
  summarise(
    n_counties = n_distinct(fips),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    mean_earn = mean(earn_avg, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ── Save analysis panel ─────────────────────────────────────────────────────
saveRDS(df_main, "../data/panel_main.rds")
saveRDS(df, "../data/panel_full.rds")

cat("\nPanel saved. Main sample:", nrow(df_main), "rows\n")
