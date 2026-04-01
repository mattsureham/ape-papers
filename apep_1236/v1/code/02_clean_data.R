# 02_clean_data.R — Clean data, assign provinces, construct treatment variables

library(tidyverse)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

# ============================================================
# 1. Load data
# ============================================================
housing <- readRDS("data/housing_monthly.rds")
gm_meta <- readRDS("data/gm_metadata.rds")

cat("Housing obs:", nrow(housing), "\n")
cat("Municipality metadata:", nrow(gm_meta), "\n")

# ============================================================
# 2. Fix province assignments using CBS geo mapping
# ============================================================
cat("\nFixing province assignments...\n")

if (file.exists("data/geo_mapping_raw.rds")) {
  geo <- readRDS("data/geo_mapping_raw.rds")
  # CBS 84992NED: Woonplaatsen → Gemeenten (Code_3) → Provinciën (Code_5)
  gem_prov <- geo %>%
    mutate(
      gem_code = trimws(Code_3),
      province_name = trimws(Naam_4)
    ) %>%
    filter(grepl("^GM", gem_code)) %>%
    select(gem_code, province_name) %>%
    distinct()

  # Some gems appear multiple times if they have multiple woonplaatsen
  # Take first province (they should all be the same for a given gem)
  gem_prov <- gem_prov %>%
    group_by(gem_code) %>%
    slice(1) %>%
    ungroup()

  cat("  CBS geo mapping covers:", nrow(gem_prov), "municipalities\n")

  # Merge into gm_meta
  gm_meta <- gm_meta %>%
    left_join(gem_prov %>% rename(cbs_province = province_name),
              by = "gem_code")

  # Use CBS mapping where available
  gm_meta$province <- ifelse(
    !is.na(gm_meta$cbs_province),
    gm_meta$cbs_province,
    gm_meta$province
  )
  gm_meta$cbs_province <- NULL
}

cat("Province distribution after fix:\n")
print(table(gm_meta$province, useNA = "always"))

# Remaining unknowns
unknown <- gm_meta %>% filter(province == "Unknown" | is.na(province))
if (nrow(unknown) > 0) {
  cat("\nStill unknown:", nrow(unknown), "municipalities\n")
  cat("  Codes:", paste(unknown$gem_code, collapse = ", "), "\n")
}

# ============================================================
# 3. Merge province info into housing data
# ============================================================
panel <- housing %>%
  left_join(
    gm_meta %>% select(gem_code, gem_name, province, high_pfas),
    by = c("region" = "gem_code")
  )

cat("\nPanel after merge:", nrow(panel), "obs\n")
cat("Missing province:", sum(is.na(panel$province)), "\n")

# Drop municipalities with unknown province
panel <- panel %>% filter(!is.na(province) & province != "Unknown")
cat("After dropping unknowns:", nrow(panel), "obs\n")

# ============================================================
# 4. Construct treatment variables
# ============================================================
cat("\nConstructing treatment variables...\n")

# PFAS freeze: July 2019; Partial relaxation: November 2019
# Treatment = high PFAS exposure (Zuid-Holland + Noord-Brabant)
# These provinces contain the Chemours factory and are downstream

panel <- panel %>%
  mutate(
    # Time indicators
    post_freeze = date >= as.Date("2019-07-01"),
    freeze_period = date >= as.Date("2019-07-01") & date < as.Date("2019-12-01"),
    post_relax = date >= as.Date("2019-12-01"),

    # Treatment × time
    treat_post = as.integer(high_pfas) * as.integer(post_freeze),
    treat_freeze = as.integer(high_pfas) * as.integer(freeze_period),
    treat_postrelax = as.integer(high_pfas) * as.integer(post_relax),

    # Event time (months since July 2019)
    event_time = as.integer(difftime(date, as.Date("2019-07-01"), units = "days")) %/% 30,

    # Year-month numeric for time trends
    ym = year * 12 + month,
    ym_factor = factor(paste0(year, sprintf("%02d", month))),

    # Log outcome (add 1 for zeros)
    log_new = log(new_construction + 1)
  )

cat("  Treatment group (high PFAS):", n_distinct(panel$region[panel$high_pfas]), "municipalities\n")
cat("  Control group:", n_distinct(panel$region[!panel$high_pfas]), "municipalities\n")
cat("  Pre-freeze months:", sum(panel$date < as.Date("2019-07-01")) / n_distinct(panel$region), "\n")
cat("  Freeze months:", sum(panel$freeze_period) / n_distinct(panel$region), "\n")
cat("  Post-relax months:", sum(panel$post_relax) / n_distinct(panel$region), "\n")

# ============================================================
# 5. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")
panel %>%
  group_by(high_pfas) %>%
  summarise(
    n_muni = n_distinct(region),
    mean_new = mean(new_construction, na.rm = TRUE),
    sd_new = sd(new_construction, na.rm = TRUE),
    median_new = median(new_construction, na.rm = TRUE),
    pct_zero = mean(new_construction == 0, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Pre-period means by group
cat("\nPre-period (2015-2019H1) means:\n")
panel %>%
  filter(year >= 2015 & date < as.Date("2019-07-01")) %>%
  group_by(high_pfas) %>%
  summarise(
    mean_new = mean(new_construction, na.rm = TRUE),
    sd_new = sd(new_construction, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ============================================================
# 6. Province-level trends for visual check
# ============================================================
prov_trends <- panel %>%
  group_by(province, year) %>%
  summarise(
    total_new = sum(new_construction, na.rm = TRUE),
    n_muni = n_distinct(region),
    .groups = "drop"
  ) %>%
  mutate(avg_new = total_new / n_muni)

cat("\nZuid-Holland annual totals:\n")
print(prov_trends %>% filter(province == "Zuid-Holland") %>% as.data.frame())

cat("\nNoord-Brabant annual totals:\n")
print(prov_trends %>% filter(province == "Noord-Brabant") %>% as.data.frame())

# ============================================================
# 7. Save
# ============================================================
saveRDS(panel, "data/panel.rds")
saveRDS(gm_meta, "data/gm_metadata_final.rds")

cat("\n=== Panel data saved ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Municipalities:", n_distinct(panel$region), "\n")
cat("Time periods:", n_distinct(panel$date), "\n")
