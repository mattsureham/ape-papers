# ==============================================================================
# 02_clean_data.R — Variable construction and sample restrictions
# The Enclave as Insurance and Trap
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_3decade.rds")
county_pops <- readRDS("../data/county_coethnic_1920.rds")
county_totals <- readRDS("../data/county_totals_1920.rds")

# --------------------------------------------------------------------------
# 1. Map BPL codes to nationality labels
# --------------------------------------------------------------------------

bpl_labels <- tribble(
  ~bpl_code, ~nationality,
  410, "England",
  411, "Scotland",
  412, "Wales",
  413, "N. Ireland",
  414, "Ireland",
  420, "France",
  421, "Albania",
  425, "Netherlands",
  426, "Belgium",
  429, "Germany",
  430, "Poland",
  433, "Austria",
  434, "Hungary",
  436, "Czechoslovakia",
  438, "Switzerland",
  440, "Denmark",
  441, "Norway",
  442, "Sweden",
  443, "Finland",
  450, "Italy",
  451, "Portugal",
  452, "Spain",
  453, "Greece",
  454, "Turkey",
  455, "Romania",
  457, "Yugoslavia",
  460, "Russia/USSR",
  461, "Lithuania",
  462, "Latvia",
  463, "Estonia",
  465, "Other USSR"
  # Dropping: 400, 401, 404, 405, 499 (Europe ns/unspecified)
)

# --------------------------------------------------------------------------
# 2. Compute co-ethnic shares and self-employment rates
# --------------------------------------------------------------------------

county_data <- county_pops %>%
  left_join(county_totals, by = c("statefip_1920", "countyicp_1920")) %>%
  mutate(
    coethnic_share = n_coethnic / county_pop,
    selfempl_rate = ifelse(n_coethnic > 0, n_selfemployed / n_coethnic, 0),
    literacy_rate = ifelse(n_coethnic > 0, n_literate / n_coethnic, 0)
  )

# Nationality-level self-employment rates FROM PANEL DATA (not census query)
# Census query had classwkr IN (1,2) bug counting wage workers as self-employed
# Panel classwkr: 0=N/A, 1=Self-employed, 2=Wage worker
natl_selfempl <- panel %>%
  filter(classwkr_1920 > 0) %>%  # exclude N/A
  group_by(bpl_1920) %>%
  summarise(
    natl_selfempl_rate = mean(classwkr_1920 == 1),
    natl_total = n(),
    .groups = "drop"
  )

# County-nationality self-employment rates from panel
county_selfempl <- panel %>%
  filter(classwkr_1920 > 0) %>%
  group_by(statefip_1920, countyicp_1920, bpl_1920) %>%
  summarise(
    selfempl_rate = mean(classwkr_1920 == 1),
    .groups = "drop"
  )

cat("Nationality self-employment rates:\n")
natl_selfempl %>%
  left_join(bpl_labels, by = c("bpl_1920" = "bpl_code")) %>%
  filter(natl_total >= 5000) %>%
  arrange(desc(natl_selfempl_rate)) %>%
  select(nationality, natl_selfempl_rate, natl_total) %>%
  print(n = 30)

# --------------------------------------------------------------------------
# 3. Merge enclave data to individual panel
# --------------------------------------------------------------------------

panel <- panel %>%
  # Merge co-ethnic share from census (correct)
  left_join(
    county_data %>% select(statefip_1920, countyicp_1920, bpl_1920, coethnic_share),
    by = c("statefip_1920", "countyicp_1920", "bpl_1920")
  ) %>%
  # Merge county-level self-employment rate (from panel, correct)
  left_join(county_selfempl, by = c("statefip_1920", "countyicp_1920", "bpl_1920")) %>%
  # Merge nationality-level self-employment rate (from panel, correct)
  left_join(
    natl_selfempl %>% select(bpl_1920, natl_selfempl_rate),
    by = "bpl_1920"
  ) %>%
  left_join(bpl_labels, by = c("bpl_1920" = "bpl_code"))

# --------------------------------------------------------------------------
# 4. Construct outcome variables
# --------------------------------------------------------------------------

panel <- panel %>%
  mutate(
    # Occupational score changes (Depression era)
    delta_occscore_bust = occscore_1940 - occscore_1930,
    delta_sei_bust = sei_1940 - sei_1930,

    # Binary outcomes
    downgrade_bust = as.integer(occscore_1940 < occscore_1930),
    large_downgrade_bust = as.integer((occscore_1930 - occscore_1940) > 10),
    upgrade_bust = as.integer(occscore_1940 > occscore_1930),

    # Homeownership loss (ownershp: 1=owned, 2=rented)
    lost_home = as.integer(ownershp_1930 == 1 & ownershp_1940 != 1),

    # Farm exit (farm: 2=farm)
    farm_exit = as.integer(farm_1930 == 2 & farm_1940 != 2),

    # Geographic mobility (from panel variables)
    moved_county = mover_30_40,

    # Self-employment in 1920 (classwkr: 1=self-employed, 2=employer)
    selfempl_1920 = as.integer(classwkr_1920 %in% c(1, 2)),

    # County identifiers
    county_id = paste0(statefip_1920, "_", countyicp_1920),
    county_natl_id = paste0(county_id, "_", bpl_1920),

    # School attendance in 1920 (proxy for education)
    in_school_1920 = as.integer(school_1920 == 2)
  )

# --------------------------------------------------------------------------
# 5. Filter to valid observations
# --------------------------------------------------------------------------

panel_clean <- panel %>%
  filter(
    !is.na(nationality),  # Drop unspecified Europe codes
    !is.na(occscore_1930) & occscore_1930 > 0,
    !is.na(occscore_1940) & occscore_1940 > 0,
    !is.na(coethnic_share),
    coethnic_share > 0
  )

cat(sprintf("\nSample after cleaning: %s observations\n",
            format(nrow(panel_clean), big.mark = ",")))

# Keep nationalities with N >= 5,000
natl_counts <- panel_clean %>%
  count(nationality) %>%
  filter(n >= 5000)

panel_clean <- panel_clean %>%
  filter(nationality %in% natl_counts$nationality)

cat(sprintf("After nationality filter (N>=5000): %s observations, %d nationalities\n",
            format(nrow(panel_clean), big.mark = ","),
            n_distinct(panel_clean$nationality)))

# --------------------------------------------------------------------------
# 6. Create enclave quintiles within nationality
# --------------------------------------------------------------------------

panel_clean <- panel_clean %>%
  group_by(nationality) %>%
  mutate(
    enclave_quintile = ntile(coethnic_share, 5),
    high_enclave = as.integer(enclave_quintile >= 4)
  ) %>%
  ungroup()

# --------------------------------------------------------------------------
# 7. Summary statistics
# --------------------------------------------------------------------------

cat("\n=== Sample Summary ===\n")
cat(sprintf("Total observations: %s\n", format(nrow(panel_clean), big.mark = ",")))
cat(sprintf("Unique counties: %s\n", format(n_distinct(panel_clean$county_id), big.mark = ",")))
cat(sprintf("Nationalities: %d\n", n_distinct(panel_clean$nationality)))
cat(sprintf("Mean occ score change (bust): %.2f\n", mean(panel_clean$delta_occscore_bust)))
cat(sprintf("SD occ score change (bust): %.2f\n", sd(panel_clean$delta_occscore_bust)))
cat(sprintf("Mean co-ethnic share: %.4f\n", mean(panel_clean$coethnic_share)))
cat(sprintf("SD co-ethnic share: %.4f\n", sd(panel_clean$coethnic_share)))
cat(sprintf("Downgrade rate: %.1f%%\n", 100 * mean(panel_clean$downgrade_bust)))

cat("\n=== By Nationality ===\n")
panel_clean %>%
  group_by(nationality) %>%
  summarise(
    N = n(),
    mean_delta_occ = mean(delta_occscore_bust),
    sd_delta_occ = sd(delta_occscore_bust),
    mean_enclave = mean(coethnic_share),
    selfempl_rate = first(natl_selfempl_rate),
    .groups = "drop"
  ) %>%
  arrange(desc(N)) %>%
  print(n = 30)

# --------------------------------------------------------------------------
# 8. Save
# --------------------------------------------------------------------------

saveRDS(panel_clean, "../data/analysis_sample.rds")
saveRDS(natl_selfempl, "../data/natl_selfempl.rds")

cat("\nCleaned data saved.\n")
