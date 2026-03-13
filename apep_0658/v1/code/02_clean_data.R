## 02_clean_data.R — Construct municipality-year analysis panel
## apep_0658
##
## Norway underwent a major municipal merger reform effective January 1, 2020.
## Many municipalities were merged into larger units. SSB data contains both
## old (pre-2020) and new (post-2020) municipality codes.
##
## Strategy: Build a panel of municipalities that exist in both 2021 (pre-reform)
## and 2022 (post-reform) across ALL outcome datasets. This captures the
## post-merger geography consistently.

source("00_packages.R")

## =====================================================
## 1. WEALTH TAX — first-stage validation
## =====================================================
wt <- readRDS("../data/wealth_tax_raw.rds")
cat("Wealth tax:", nrow(wt), "rows\n")

# Keep 4-digit municipality codes
wt_muni <- wt %>%
  filter(nchar(Region) == 4) %>%
  mutate(year = as.integer(Tid)) %>%
  select(muni_code = Region, year, contents = ContentsCode, value)

# Pivot wider
wt_wide <- wt_muni %>%
  pivot_wider(names_from = contents, values_from = value, values_fn = first)

# Verify national-level first stage
cat("\nNational avg wealth tax (from table 10333):\n")
nat <- wt %>%
  filter(Region == "0", ContentsCode == "GjsnittFormuesskatt") %>%
  mutate(year = as.integer(Tid)) %>%
  arrange(year)
for (i in seq_len(nrow(nat))) {
  cat(sprintf("  %d: %s NOK\n", nat$year[i], format(nat$value[i], big.mark = ",")))
}

# Municipality-level avg wealth tax
wt_clean <- wt_wide %>%
  select(muni_code, year,
         n_persons = Personer,
         avg_wealth_tax = GjsnittFormuesskatt,
         wealth_tax_muni = FormuesskattKomm)

cat("Municipalities in wealth tax:", n_distinct(wt_clean$muni_code), "\n")

## =====================================================
## 2. SECONDARY DWELLINGS — treatment intensity
## =====================================================
dw <- readRDS("../data/dwellings_raw.rds")
cat("\nDwellings:", nrow(dw), "rows\n")

dw_muni <- dw %>%
  filter(nchar(Region) == 4) %>%
  mutate(year = as.integer(Tid)) %>%
  select(muni_code = Region, year,
         dwelling_type = PrimarSekundar,
         contents = ContentsCode, value)

# Use total assessed tax value (Ligningsverdi)
dw_val <- dw_muni %>%
  filter(contents == "Ligningsverdi") %>%
  pivot_wider(names_from = dwelling_type, values_from = value, values_fn = first) %>%
  rename(primary_taxval = `01`, secondary_taxval = `02`) %>%
  select(muni_code, year, primary_taxval, secondary_taxval) %>%
  mutate(
    total_taxval = coalesce(primary_taxval, 0) + coalesce(secondary_taxval, 0),
    secondary_share = ifelse(total_taxval > 0,
                            coalesce(secondary_taxval, 0) / total_taxval, NA_real_)
  )

# Treatment intensity: use 2021 secondary taxval as % of total
treat_2021 <- dw_val %>%
  filter(year == 2021, !is.na(secondary_share)) %>%
  select(muni_code,
         sec_share_2021 = secondary_share,
         sec_taxval_2021 = secondary_taxval)

cat("Municipalities with secondary dwelling data (2021):", nrow(treat_2021), "\n")
cat("Secondary share (2021) summary:\n")
print(summary(treat_2021$sec_share_2021))

## =====================================================
## 3. BUILDING PERMITS — primary outcome
## =====================================================
bp <- readRDS("../data/permits_raw.rds")

bp_muni <- bp %>%
  filter(nchar(Region) == 4) %>%
  mutate(year = as.integer(Tid)) %>%
  select(muni_code = Region, year,
         building_type = Byggeareal,
         contents = ContentsCode, value)

# Aggregate all residential types
bp_agg <- bp_muni %>%
  group_by(muni_code, year, contents) %>%
  summarise(total = sum(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = contents, values_from = total, values_fn = first) %>%
  rename(permits_started = Igangsatte, permits_completed = Fullforte)

cat("\nBuilding permits municipalities:", n_distinct(bp_agg$muni_code), "\n")

## =====================================================
## 4. NEW ENTERPRISES — secondary outcome
## =====================================================
ent <- readRDS("../data/enterprises_raw.rds")

ent_clean <- ent %>%
  filter(nchar(Region) == 4) %>%
  mutate(year = as.integer(Tid)) %>%
  select(muni_code = Region, year, new_enterprises = value)

cat("Enterprise municipalities:", n_distinct(ent_clean$muni_code), "\n")

## =====================================================
## 5. MIGRATION — secondary outcome
## =====================================================
mig <- readRDS("../data/migration_raw.rds")

mig_clean <- mig %>%
  filter(nchar(Region) == 4) %>%
  mutate(year = as.integer(Tid)) %>%
  select(muni_code = Region, year, contents = ContentsCode, value) %>%
  pivot_wider(names_from = contents, values_from = value, values_fn = first) %>%
  rename(in_migration = Innflytting, out_migration = Utflytting, net_migration = Netto)

cat("Migration municipalities:", n_distinct(mig_clean$muni_code), "\n")

## =====================================================
## 6. IDENTIFY BALANCED PANEL MUNICIPALITIES
## =====================================================
## Find municipalities with data in the post-merger period (2020-2024)
## across all key datasets

# Municipalities with building permit data in 2020-2024
bp_post <- bp_agg %>%
  filter(year >= 2020, year <= 2024) %>%
  group_by(muni_code) %>%
  summarise(n_bp_years = sum(!is.na(permits_started)), .groups = "drop") %>%
  filter(n_bp_years >= 4)

# Municipalities with enterprise data in 2020-2024
ent_post <- ent_clean %>%
  filter(year >= 2020, year <= 2024) %>%
  group_by(muni_code) %>%
  summarise(n_ent_years = sum(!is.na(new_enterprises)), .groups = "drop") %>%
  filter(n_ent_years >= 4)

# Municipalities with migration data in 2020-2024
mig_post <- mig_clean %>%
  filter(year >= 2020, year <= 2024) %>%
  group_by(muni_code) %>%
  summarise(n_mig_years = sum(!is.na(net_migration)), .groups = "drop") %>%
  filter(n_mig_years >= 4)

# Municipalities with treatment data
balanced_munis <- Reduce(intersect, list(
  bp_post$muni_code,
  ent_post$muni_code,
  mig_post$muni_code,
  treat_2021$muni_code
))

cat("\n=== BALANCED PANEL CONSTRUCTION ===\n")
cat("Munis with permits (2020-2024):", nrow(bp_post), "\n")
cat("Munis with enterprises (2020-2024):", nrow(ent_post), "\n")
cat("Munis with migration (2020-2024):", nrow(mig_post), "\n")
cat("Munis with treatment (2021):", nrow(treat_2021), "\n")
cat("INTERSECTION:", length(balanced_munis), "\n")

## =====================================================
## 7. ALSO BUILD EXTENDED PANEL using pre-2020 data where available
## =====================================================
## Many post-2020 municipality codes also appear in pre-2020 data
## (municipalities that didn't merge). We can extend the panel back
## for these municipalities.

# Check how far back each balanced municipality has building permit data
bp_extended <- bp_agg %>%
  filter(muni_code %in% balanced_munis) %>%
  group_by(muni_code) %>%
  summarise(min_year = min(year[!is.na(permits_started)]),
            max_year = max(year[!is.na(permits_started)]),
            n_years = sum(!is.na(permits_started)),
            .groups = "drop")

cat("\nExtended panel coverage:\n")
cat("Municipalities with data from 2010:", sum(bp_extended$min_year <= 2010), "\n")
cat("Municipalities with data from 2015:", sum(bp_extended$min_year <= 2015), "\n")
cat("Municipalities with data from 2018:", sum(bp_extended$min_year <= 2018), "\n")

## =====================================================
## 8. MERGE FINAL PANEL
## =====================================================

# Use all years where data exists for balanced municipalities
panel <- bp_agg %>%
  filter(muni_code %in% balanced_munis) %>%
  full_join(ent_clean %>% filter(muni_code %in% balanced_munis),
            by = c("muni_code", "year")) %>%
  full_join(mig_clean %>% filter(muni_code %in% balanced_munis),
            by = c("muni_code", "year")) %>%
  left_join(wt_clean %>% filter(muni_code %in% balanced_munis),
            by = c("muni_code", "year")) %>%
  inner_join(treat_2021, by = "muni_code") %>%
  filter(year >= 2010, year <= 2024)

# Treatment variables
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2022),
    # Binary: above-median exposure
    high_exposure = as.integer(sec_share_2021 > median(sec_share_2021, na.rm = TRUE)),
    # Continuous (standardized)
    treat_z = (sec_share_2021 - mean(sec_share_2021, na.rm = TRUE)) /
              sd(sec_share_2021, na.rm = TRUE),
    treat_x_post = sec_share_2021 * post,
    treat_z_x_post = treat_z * post,
    # Municipality FE
    muni_id = as.integer(factor(muni_code)),
    # Log outcomes
    log_permits = log(permits_started + 1),
    log_enterprises = log(new_enterprises + 1),
    log_out_migration = log(pmax(out_migration, 0) + 1)
  )

cat("\n=== FINAL PANEL ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Municipalities:", n_distinct(panel$muni_code), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Pre-period obs:", sum(panel$post == 0), "\n")
cat("Post-period obs:", sum(panel$post == 1), "\n")
cat("High-exposure munis:", sum(panel$high_exposure == 1 & panel$year == 2022), "\n")
cat("Low-exposure munis:", sum(panel$high_exposure == 0 & panel$year == 2022), "\n")

# Summary statistics
cat("\n=== OUTCOME MEANS BY PERIOD ===\n")
panel %>%
  group_by(post) %>%
  summarise(
    permits = mean(permits_started, na.rm = TRUE),
    enterprises = mean(new_enterprises, na.rm = TRUE),
    out_mig = mean(out_migration, na.rm = TRUE),
    avg_wt = mean(avg_wealth_tax, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  print()

# First-stage: wealth tax change by exposure group
cat("\n=== FIRST STAGE: WEALTH TAX BY EXPOSURE ===\n")
panel %>%
  filter(year %in% c(2021, 2022)) %>%
  group_by(high_exposure, year) %>%
  summarise(avg_wt = mean(avg_wealth_tax, na.rm = TRUE),
            n = n(), .groups = "drop") %>%
  pivot_wider(names_from = year, values_from = c(avg_wt, n)) %>%
  mutate(change = avg_wt_2022 - avg_wt_2021,
         pct_change = change / avg_wt_2021 * 100) %>%
  print()

# Treatment variable distribution
cat("\n=== TREATMENT DISTRIBUTION ===\n")
cat("Secondary share (2021) by quartile:\n")
print(quantile(treat_2021$sec_share_2021, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE))

# Save
saveRDS(panel, "../data/panel.rds")
cat("\n=== Panel saved ===\n")
