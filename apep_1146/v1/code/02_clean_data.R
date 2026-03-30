# 02_clean_data.R — Variable construction for DiD analysis

source("00_packages.R")

df <- readRDS("../data/nbs_panel_validated.rds")

# ── Parse dates and create time variables ──
df <- df %>%
  mutate(
    date = as.Date(date),
    year = year(date),
    month = month(date),
    year_month = as.numeric(format(date, "%Y")) + (as.numeric(format(date, "%m")) - 1) / 12,
    # Treatment timing: February 2021 reform, effective March 2021
    post = as.integer(date >= as.Date("2021-03-01")),
    # Relative time (months since March 2021)
    rel_month = as.integer(round((date - as.Date("2021-03-01")) / 30.44)),
    # Numeric city ID for FE
    city_id = as.integer(factor(city_en))
  )

# ── Outcome variables ──
# The MoM index is centered at 100 (100 = no change)
# Convert to percentage change: MoM - 100
df <- df %>%
  mutate(
    # New house MoM price change (pct)
    new_mom_pct = new_house_mom - 100,
    # Used house MoM price change (pct)
    used_mom_pct = used_house_mom - 100,
    # Absolute MoM change (volatility proxy)
    new_abs_mom = abs(new_mom_pct),
    used_abs_mom = abs(used_mom_pct),
    # New-used divergence (market segmentation proxy)
    new_used_gap = abs(new_mom_pct - used_mom_pct),
    # Squared MoM change (alternative volatility measure)
    new_mom_sq = new_mom_pct^2,
    used_mom_sq = used_mom_pct^2
  )

# ── Rolling volatility (3-month rolling SD) ──
df <- df %>%
  arrange(city_id, date) %>%
  group_by(city_id) %>%
  mutate(
    new_vol_3m = zoo::rollapply(new_mom_pct, width = 3, FUN = sd,
                                 fill = NA, align = "right"),
    used_vol_3m = zoo::rollapply(used_mom_pct, width = 3, FUN = sd,
                                  fill = NA, align = "right"),
    new_vol_6m = zoo::rollapply(new_mom_pct, width = 6, FUN = sd,
                                 fill = NA, align = "right")
  ) %>%
  ungroup()

# ── City characteristics ──
# Classify city tiers based on treated city composition
tier1 <- c("Beijing", "Shanghai", "Guangzhou", "Shenzhen")

df <- df %>%
  mutate(
    tier1 = as.integer(city_en %in% tier1),
    # Create a numeric time period for FE
    time_id = as.integer(factor(date))
  )

# ── Restrict sample to analysis window ──
# Use Jan 2019 - Dec 2023 (24 pre + 34 post months)
df_analysis <- df %>%
  filter(date >= as.Date("2019-01-01") & date <= as.Date("2023-12-01"))

cat("Analysis sample:\n")
cat("  Observations:", nrow(df_analysis), "\n")
cat("  Cities:", length(unique(df_analysis$city_en)), "\n")
cat("  Pre-treatment months:", sum(df_analysis$post == 0) / length(unique(df_analysis$city_en)), "\n")
cat("  Post-treatment months:", sum(df_analysis$post == 1) / length(unique(df_analysis$city_en)), "\n")
cat("  Treated cities:", length(unique(df_analysis$city_en[df_analysis$treated == 1])), "\n")
cat("  Control cities:", length(unique(df_analysis$city_en[df_analysis$treated == 0])), "\n")

# ── Summary statistics by treatment group ──
summ <- df_analysis %>%
  group_by(treated) %>%
  summarise(
    n_cities = n_distinct(city_en),
    n_obs = n(),
    mean_new_mom = mean(new_mom_pct, na.rm = TRUE),
    sd_new_mom = sd(new_mom_pct, na.rm = TRUE),
    mean_abs_mom = mean(new_abs_mom, na.rm = TRUE),
    sd_abs_mom = sd(new_abs_mom, na.rm = TRUE),
    mean_new_used_gap = mean(new_used_gap, na.rm = TRUE),
    sd_new_used_gap = sd(new_used_gap, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nSummary by treatment group:\n")
print(summ)

# Save analysis dataset
saveRDS(df_analysis, "../data/analysis_panel.rds")
saveRDS(df, "../data/full_panel.rds")

cat("\nSaved analysis panel to data/analysis_panel.rds\n")
