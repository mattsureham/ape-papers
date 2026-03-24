## 02_clean_data.R — Clean and construct analysis variables
## apep_0851: Abolishing the Tax Haven Next Door

source("00_packages.R")

hpi <- read_csv("../data/hpi_eurostat.csv", show_col_types = FALSE)
cat("Loaded", nrow(hpi), "HPI observations\n")

# -----------------------------------------------------------------------
# 1. Define treatment and control groups
# -----------------------------------------------------------------------
# Portugal = treated (NHR abolished, announced Sep 2023, effective Jan 2024)
# Controls: Southern/Western European EU members with housing booms
# but NO equivalent expat-tax shock in 2023-2024
control_countries <- c("ES", "IT", "IE", "NL", "BE", "FR", "AT", "FI",
                       "EL", "DE", "CY", "MT", "LU", "SI", "HR")

# Create analysis sample
df <- hpi %>%
  filter(country %in% c("PT", control_countries)) %>%
  mutate(
    treated = as.integer(country == "PT"),
    # Announcement: Sep 6, 2023 → 2023Q3 (yq ~ 2023.5)
    # Effective: Jan 1, 2024 → 2024Q1
    post_announce = as.integer(yq >= 2023.5),  # 2023Q3 onward
    post_effective = as.integer(yq >= 2024.0),  # 2024Q1 onward
    # Event time relative to announcement quarter (2023Q3 = 0)
    event_time = round((yq - 2023.5) * 4)
  )

cat("Analysis sample:", nrow(df), "obs\n")
cat("  Countries:", length(unique(df$country)), "\n")
cat("  Portugal obs:", sum(df$treated), "\n")
cat("  Control obs:", sum(1 - df$treated), "\n")
cat("  Quarters:", length(unique(df$yq)), "\n")

# -----------------------------------------------------------------------
# 2. Normalize HPI to 2023Q2 = 100 for each country (last pre-announcement quarter)
# -----------------------------------------------------------------------
base_vals <- df %>%
  filter(year == 2023, quarter == 2) %>%
  select(country, base_hpi = hpi)

# Some countries may lack 2023Q2 — use closest available
if (nrow(base_vals) < length(unique(df$country))) {
  # Fallback: use 2023Q1
  missing <- setdiff(unique(df$country), base_vals$country)
  base_fallback <- df %>%
    filter(country %in% missing, year == 2023, quarter == 1) %>%
    select(country, base_hpi = hpi)
  base_vals <- bind_rows(base_vals, base_fallback)
}

df <- df %>%
  left_join(base_vals, by = "country") %>%
  mutate(
    hpi_norm = hpi / base_hpi * 100,
    log_hpi_norm = log(hpi_norm)
  )

# Drop countries with no base value
df <- df %>% filter(!is.na(base_hpi))
cat("After normalization:", nrow(df), "obs from", length(unique(df$country)), "countries\n")

# -----------------------------------------------------------------------
# 3. Create synthetic control weight predictors
# -----------------------------------------------------------------------
# Pre-treatment means for matching (2015-2023Q2)
pre_means <- df %>%
  filter(yq < 2023.5) %>%
  group_by(country) %>%
  summarize(
    mean_hpi = mean(hpi, na.rm = TRUE),
    sd_hpi = sd(hpi, na.rm = TRUE),
    growth_2015_2023 = (last(hpi) - first(hpi)) / first(hpi) * 100,
    .groups = "drop"
  )

# -----------------------------------------------------------------------
# 4. Summary statistics
# -----------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

summ <- df %>%
  group_by(Group = ifelse(treated == 1, "Portugal", "Controls")) %>%
  summarize(
    N = n(),
    Countries = n_distinct(country),
    `Mean HPI` = mean(hpi, na.rm = TRUE),
    `SD HPI` = sd(hpi, na.rm = TRUE),
    `Min HPI` = min(hpi, na.rm = TRUE),
    `Max HPI` = max(hpi, na.rm = TRUE),
    `Mean log HPI` = mean(log_hpi, na.rm = TRUE),
    `SD log HPI` = sd(log_hpi, na.rm = TRUE),
    .groups = "drop"
  )
print(summ)

# -----------------------------------------------------------------------
# 5. Save cleaned data
# -----------------------------------------------------------------------
write_csv(df, "../data/analysis_panel.csv")
write_csv(pre_means, "../data/pre_means.csv")

cat("\nCleaned panel saved to data/analysis_panel.csv\n")
cat("Rows:", nrow(df), " | Countries:", length(unique(df$country)), "\n")
