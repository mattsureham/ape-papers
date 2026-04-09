# 02_clean_data.R — Construct analysis dataset
source("00_packages.R")

df <- readRDS("../data/region_consents.rds")

# ---- Define treatment groups ----
# MDRS Tier 1 cities (August 2022):
#   Hamilton (Waikato region), Tauranga (Bay of Plenty), Wellington, Christchurch (Canterbury)
# Auckland: treated EARLIER via AUP (2016) — excluded from main analysis
# Treatment year: "year ended February 2023" is the first full post-treatment year
#   (MDRS operative Aug 2022, so Feb-ending 2023 captures Aug 2022 - Feb 2023)

# Clean region name
df <- df %>% mutate(region = gsub("\\(3\\)$", "", region))

# Treatment assignment
treated_regions <- c("Waikato", "Bay of Plenty", "Wellington", "Canterbury")
excluded_regions <- c("Auckland")  # Treated earlier (AUP 2016)

df <- df %>%
  filter(!region %in% excluded_regions) %>%
  mutate(
    treated = as.integer(region %in% treated_regions),
    # First treatment year: year ended Feb 2023 (captures Aug-Feb post-MDRS)
    # But MDRS was operative Aug 2022, so year_ended_feb 2023 is the first with any post-treatment months
    first_treat = ifelse(treated == 1, 2023L, 0L),
    post = as.integer(year >= 2023),
    treat_post = treated * post,
    region_id = as.integer(factor(region))
  )

cat("Regions in analysis:\n")
cat("  Treated:", paste(unique(df$region[df$treated == 1]), collapse = ", "), "\n")
cat("  Control:", paste(unique(df$region[df$treated == 0]), collapse = ", "), "\n")
cat("  Excluded:", paste(excluded_regions, collapse = ", "), "\n")

cat("\nPanel dimensions:\n")
cat("  Regions:", n_distinct(df$region), "\n")
cat("  Years:", paste(range(df$year), collapse = "-"), "\n")
cat("  Pre-treatment years:", sum(unique(df$year) < 2023), "\n")
cat("  Post-treatment years:", sum(unique(df$year) >= 2023), "\n")
cat("  Total obs:", nrow(df), "\n")

# ---- Summary statistics ----
sumstats <- df %>%
  group_by(treated) %>%
  summarise(
    mean_total = mean(total, na.rm = TRUE),
    sd_total = sd(total, na.rm = TRUE),
    mean_multi_share = mean(multi_unit_share, na.rm = TRUE),
    sd_multi_share = sd(multi_unit_share, na.rm = TRUE),
    mean_houses = mean(houses, na.rm = TRUE),
    mean_multi = mean(multi_unit, na.rm = TRUE),
    n = n()
  )
cat("\nSummary by treatment group:\n")
print(sumstats)

# Pre-treatment means
pre_stats <- df %>%
  filter(year < 2023) %>%
  summarise(
    mean_share = mean(multi_unit_share, na.rm = TRUE),
    sd_share = sd(multi_unit_share, na.rm = TRUE),
    mean_total = mean(total, na.rm = TRUE),
    sd_total = sd(total, na.rm = TRUE)
  )
cat("\nPre-treatment summary (all regions):\n")
print(pre_stats)

saveRDS(df, "../data/analysis_dataset.rds")
cat("\nSaved analysis dataset.\n")
