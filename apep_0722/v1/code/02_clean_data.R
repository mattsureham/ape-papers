# 02_clean_data.R — Clean and prepare CPI data for analysis
# apep_0722: Japan's Split-Rate Consumption Tax

source("00_packages.R")

data_dir <- "../data"

# ===================================================================
# LOAD RAW DATA
# ===================================================================

raw <- readRDS(file.path(data_dir, "oecd_cpi_japan.rds"))
cat(sprintf("Raw data: %d obs, %d categories\n", nrow(raw), length(unique(raw$coicop))))
cat(sprintf("Categories: %s\n", paste(sort(unique(raw$coicop)), collapse = ", ")))
cat(sprintf("Time range: %s to %s\n", min(raw$time_period), max(raw$time_period)))

# ===================================================================
# CREATE ANALYSIS VARIABLES
# ===================================================================

df <- raw %>%
  mutate(
    # Treatment indicators
    # CP01 = Food (reduced 8% rate); all others at full 10% rate
    treated_cat = ifelse(coicop == "CP01", 0L,
                  ifelse(coicop == "_T", NA_integer_, 1L)),
    # Restaurant (CP11) indicator for main specification
    restaurant = ifelse(coicop == "CP11", 1L, 0L),

    # Post-treatment indicators
    # 2019 tax hike: Oct 2019, clean window through Jan 2020 (COVID ~Feb 2020)
    post_2019 = ifelse((year == 2019 & month >= 10) | (year == 2020 & month <= 1), 1L, 0L),
    # 2014 tax hike: April 2014 (uniform 5% -> 8%, no reduced rate)
    # Placebo window: April-July 2014
    post_2014 = ifelse(year == 2014 & month >= 4, 1L,
               ifelse(year >= 2015, 1L, 0L)),

    # Log CPI
    log_cpi = log(cpi)
  )

cat(sprintf("\nVariables created. Total obs: %d\n", nrow(df)))

# ===================================================================
# CREATE ANALYSIS WINDOWS
# ===================================================================

# 2019 window: Jan 2018 to Jan 2020
df_2019 <- df %>%
  filter(
    (year >= 2018 & year <= 2019) |
    (year == 2020 & month <= 1)
  )

# 2014 window: Jan 2013 to Dec 2014
df_2014 <- df %>%
  filter(year >= 2013 & year <= 2014)

cat(sprintf("\n2019 analysis window: %d obs (%s to %s)\n",
            nrow(df_2019), min(df_2019$time_period), max(df_2019$time_period)))
cat(sprintf("2014 placebo window: %d obs (%s to %s)\n",
            nrow(df_2014), min(df_2014$time_period), max(df_2014$time_period)))

# ===================================================================
# SUMMARY STATISTICS
# ===================================================================

cat("\n=== Summary Statistics: 2019 Window ===\n")

# Pre-period means (Jan 2018 to Sep 2019)
pre_2019 <- df_2019 %>%
  filter(post_2019 == 0) %>%
  group_by(coicop) %>%
  summarise(
    n_months = n(),
    mean_cpi = mean(cpi, na.rm = TRUE),
    sd_cpi = sd(cpi, na.rm = TRUE),
    mean_log_cpi = mean(log_cpi, na.rm = TRUE),
    sd_log_cpi = sd(log_cpi, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-period (Jan 2018 - Sep 2019) CPI by category:\n")
print(pre_2019 %>% arrange(coicop), n = 20)

# Post-period means (Oct 2019 to Jan 2020)
post_2019_stats <- df_2019 %>%
  filter(post_2019 == 1) %>%
  group_by(coicop) %>%
  summarise(
    n_months = n(),
    mean_cpi = mean(cpi, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPost-period (Oct 2019 - Jan 2020) CPI by category:\n")
print(post_2019_stats %>% arrange(coicop), n = 20)

# Treatment/control breakdown
cat("\n=== Treatment Assignment ===\n")
df_2019 %>%
  filter(!is.na(treated_cat)) %>%
  group_by(treated_cat) %>%
  summarise(
    n_categories = n_distinct(coicop),
    categories = paste(unique(coicop), collapse = ", "),
    .groups = "drop"
  ) %>%
  print()

# Category counts
cat(sprintf("\nN treated categories (10%% rate): %d\n",
            n_distinct(df_2019$coicop[df_2019$treated_cat == 1 & !is.na(df_2019$treated_cat)])))
cat(sprintf("N control categories (8%% rate): %d\n",
            n_distinct(df_2019$coicop[df_2019$treated_cat == 0 & !is.na(df_2019$treated_cat)])))
cat(sprintf("N pre-period months (2019 window): %d\n",
            n_distinct(df_2019$time_period[df_2019$post_2019 == 0])))
cat(sprintf("N post-period months (2019 window): %d\n",
            n_distinct(df_2019$time_period[df_2019$post_2019 == 1])))

# ===================================================================
# SAVE
# ===================================================================

# Combine into a single list for convenience, but also save the full panel
analysis_data <- list(
  full = df,
  window_2019 = df_2019,
  window_2014 = df_2014
)

saveRDS(analysis_data, file.path(data_dir, "cpi_analysis.rds"))
cat("\nAnalysis data saved to ../data/cpi_analysis.rds\n")
