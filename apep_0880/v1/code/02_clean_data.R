## 02_clean_data.R — Clean Comtrade data and construct HHI panel
## APEP paper apep_0880

source("00_packages.R")

cat("=== Cleaning Comtrade Data ===\n")

df_raw <- readRDS("../data/comtrade_raw.rds")
minerals <- readRDS("../data/mineral_metadata.rds")

cat(sprintf("Raw records: %d\n", nrow(df_raw)))
cat("Columns:", paste(names(df_raw), collapse = ", "), "\n\n")

# ---------------------------------------------------------------
# Step 1: Standardize columns
# ---------------------------------------------------------------
# The preview API returns: refYear, reporterCode, partnerCode, partner2Code,
# cmdCode, flowCode, primaryValue, etc.

df <- df_raw %>%
  transmute(
    year = as.integer(refYear),
    reporter = as.integer(reporterCode),
    partner = as.integer(partnerCode),
    hs_code = as.character(hs_code),
    mineral = mineral,
    trade_value = as.numeric(primaryValue)
  ) %>%
  filter(
    !is.na(trade_value),
    trade_value > 0,
    partner > 0  # Exclude "World" aggregate (partner=0)
  )

cat(sprintf("After initial filters: %d records\n", nrow(df)))

# ---------------------------------------------------------------
# Step 2: Aggregate EU imports by partner country × mineral × year
# Sum across EU reporter countries to approximate EU-27 total
# ---------------------------------------------------------------
df_eu <- df %>%
  group_by(year, hs_code, mineral, partner) %>%
  summarize(
    eu_import_value = sum(trade_value, na.rm = TRUE),
    n_reporters = n_distinct(reporter),
    .groups = "drop"
  )

cat(sprintf("EU-aggregated records: %d\n", nrow(df_eu)))

# ---------------------------------------------------------------
# Step 3: Calculate HHI for each mineral × year
# HHI = sum(share_i^2) where share_i = import_from_country_i / total_imports
# ---------------------------------------------------------------
mineral_year <- df_eu %>%
  group_by(year, hs_code, mineral) %>%
  mutate(
    total_imports = sum(eu_import_value),
    share = eu_import_value / total_imports
  ) %>%
  summarize(
    hhi = sum(share^2),
    top_share = max(share),
    top_partner = partner[which.max(share)],
    n_sources = n_distinct(partner[share > 0.01]),  # Sources with >1% share
    total_value = sum(eu_import_value),
    n_partners = n_distinct(partner),
    .groups = "drop"
  )

cat(sprintf("\nMineral-year panel: %d observations\n", nrow(mineral_year)))
cat(sprintf("Minerals: %d, Years: %d\n",
            n_distinct(mineral_year$mineral),
            n_distinct(mineral_year$year)))

# ---------------------------------------------------------------
# Step 4: Merge mineral metadata and construct treatment variables
# ---------------------------------------------------------------
panel <- mineral_year %>%
  left_join(minerals, by = c("hs_code", "mineral")) %>%
  mutate(
    # Post-CRMA indicator (proposal March 2023, force May 2024)
    post_crma = as.integer(year >= 2023),
    post_force = as.integer(year >= 2024),

    # Strategic mineral indicator
    strategic = as.integer(crma_status == "strategic"),

    # China dependency indicator
    china_dep = as.integer(china_dep)
  )

# ---------------------------------------------------------------
# Step 5: Calculate pre-CRMA (2022) treatment intensity
# ---------------------------------------------------------------
pre_crma_intensity <- panel %>%
  filter(year == 2022) %>%
  select(hs_code, mineral,
         pre_hhi = hhi,
         pre_top_share = top_share,
         pre_top_partner = top_partner)

# If 2022 data not available, use 2021
if (nrow(pre_crma_intensity) < 5) {
  pre_crma_intensity <- panel %>%
    filter(year == max(year[year <= 2022])) %>%
    select(hs_code, mineral,
           pre_hhi = hhi,
           pre_top_share = top_share,
           pre_top_partner = top_partner)
}

panel <- panel %>%
  left_join(pre_crma_intensity, by = c("hs_code", "mineral")) %>%
  mutate(
    # Continuous treatment: pre-CRMA HHI × post indicator
    treat_continuous = pre_hhi * post_crma,
    treat_force = pre_hhi * post_force,

    # Binary treatment: above/below 65% threshold
    high_concentration = as.integer(pre_top_share > 0.65),
    treat_binary = high_concentration * post_crma,

    # Treatment bins for event study
    concentration_bin = case_when(
      pre_top_share > 0.65 ~ "High (>65%)",
      pre_top_share > 0.50 ~ "Medium (50-65%)",
      TRUE ~ "Low (<50%)"
    ),

    # Log HHI for percentage interpretation
    log_hhi = log(hhi + 0.01)
  )

cat(sprintf("\nFinal panel: %d observations\n", nrow(panel)))
cat("\nConcentration bins:\n")
print(table(panel$concentration_bin))
cat("\nPre-CRMA top shares:\n")
print(panel %>%
        filter(year == 2022) %>%
        select(mineral, pre_top_share, pre_hhi) %>%
        arrange(desc(pre_top_share)))

# ---------------------------------------------------------------
# Save
# ---------------------------------------------------------------
saveRDS(panel, "../data/panel.rds")
cat("\nSaved panel to data/panel.rds\n")

cat("\n=== Data cleaning complete ===\n")
