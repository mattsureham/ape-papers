## 02_clean_data.R — Merge registrations with tax panel, construct analysis variables
## apep_1050: Swiss EV Tax Exemptions
source("00_packages.R")

cat("=== Loading Raw Data ===\n")
regs <- read_csv("../data/bfs_registrations_raw.csv", show_col_types = FALSE)
tax <- read_csv("../data/cantonal_ev_tax_exemptions.csv", show_col_types = FALSE)
xwalk <- read_csv("../data/muni_canton_crosswalk.csv", show_col_types = FALSE)

cat(sprintf("Registrations: %d rows\n", nrow(regs)))
cat(sprintf("Tax panel: %d rows\n", nrow(tax)))
cat(sprintf("Crosswalk: %d municipalities\n", nrow(xwalk)))

# -------------------------------------------------------------------
# 1. Merge municipalities with cantons
# -------------------------------------------------------------------
regs <- regs %>%
  left_join(xwalk, by = "muni_id")

unmapped <- regs %>% filter(is.na(canton_abbr))
if (nrow(unmapped) > 0) {
  cat(sprintf("WARNING: %d rows (%d munis) without canton mapping\n",
              nrow(unmapped), n_distinct(unmapped$muni_id)))
  # Drop unmapped
  regs <- regs %>% filter(!is.na(canton_abbr))
}

# -------------------------------------------------------------------
# 2. Create wide format: EV vs ICE registrations per municipality-year
# -------------------------------------------------------------------

# Classify fuel types into broad categories
regs <- regs %>%
  mutate(fuel_category = case_when(
    fuel_type == "Elektrisch" ~ "BEV",
    fuel_type == "Wasserstoff" ~ "FCEV",
    fuel_type %in% c("Benzin-elektrisch: Plug-in-Hybrid",
                     "Diesel-elektrisch: Plug-in-Hybrid") ~ "PHEV",
    fuel_type %in% c("Benzin-elektrisch: Normal-Hybrid",
                     "Diesel-elektrisch: Normal-Hybrid") ~ "Hybrid",
    fuel_type %in% c("Benzin", "Diesel") ~ "ICE",
    fuel_type == "Gas (mono- und bivalent)" ~ "Gas",
    TRUE ~ "Other"
  ))

# Aggregate to municipality-year-category
muni_year <- regs %>%
  group_by(muni_id, muni_name, canton_abbr, year, fuel_category) %>%
  summarise(registrations = sum(registrations, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = fuel_category, values_from = registrations,
              values_fill = 0)

# Ensure all columns exist
for (col in c("BEV", "PHEV", "ICE", "Hybrid", "FCEV", "Gas", "Other")) {
  if (!col %in% names(muni_year)) muni_year[[col]] <- 0L
}

# Compute key variables
muni_year <- muni_year %>%
  mutate(
    total_regs = BEV + PHEV + ICE + Hybrid + FCEV + Gas + Other,
    ev_regs = BEV,  # Pure BEV only for main outcome
    ev_broad = BEV + PHEV,  # BEV + Plug-in for robustness
    ice_regs = ICE,
    ev_share = ifelse(total_regs > 0, ev_regs / total_regs, NA_real_),
    ev_share_broad = ifelse(total_regs > 0, ev_broad / total_regs, NA_real_),
    ice_share = ifelse(total_regs > 0, ice_regs / total_regs, NA_real_),
    log_ev = log(ev_regs + 1),
    log_ice = log(ice_regs + 1),
    log_total = log(total_regs + 1)
  )

# -------------------------------------------------------------------
# 3. Merge with cantonal tax exemption panel
# -------------------------------------------------------------------
tax_slim <- tax %>%
  select(canton_abbr, year, ev_tax_discount_pct, ever_treated,
         first_treat_year, first_treat_cs, canton_name) %>%
  distinct()

panel <- muni_year %>%
  left_join(tax_slim, by = c("canton_abbr", "year"))

# Verify merge
n_unmerged <- sum(is.na(panel$ev_tax_discount_pct))
if (n_unmerged > 0) {
  cat(sprintf("WARNING: %d rows without tax data\n", n_unmerged))
}

# -------------------------------------------------------------------
# 4. Create analysis variables
# -------------------------------------------------------------------
panel <- panel %>%
  mutate(
    # Binary treatment: any tax discount in this canton-year
    treated = as.integer(ev_tax_discount_pct > 0),
    # Continuous treatment intensity (0-1 scale)
    tax_discount = ev_tax_discount_pct / 100,
    # Post indicator (for simple pre/post)
    post = as.integer(year >= first_treat_year & ever_treated),
    # Relative time to treatment
    rel_year = ifelse(ever_treated, year - first_treat_year, NA_integer_),
    # Treatment groups for C&S
    first_treat_g = ifelse(ever_treated, first_treat_year, 0)
  )

# -------------------------------------------------------------------
# 5. Create stacked long format for triple-diff (EV vs ICE)
# -------------------------------------------------------------------
panel_long <- panel %>%
  select(muni_id, muni_name, canton_abbr, year, ev_regs, ice_regs,
         total_regs, ev_tax_discount_pct, treated, tax_discount,
         ever_treated, first_treat_year, first_treat_g) %>%
  pivot_longer(cols = c(ev_regs, ice_regs),
               names_to = "vehicle_type",
               values_to = "registrations") %>%
  mutate(
    is_ev = as.integer(vehicle_type == "ev_regs"),
    treated_ev = treated * is_ev,  # Triple-diff interaction
    log_regs = log(registrations + 1)
  )

# -------------------------------------------------------------------
# 6. Summary Statistics
# -------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %d municipality-years\n", nrow(panel)))
cat(sprintf("Municipalities: %d\n", n_distinct(panel$muni_id)))
cat(sprintf("Cantons: %d\n", n_distinct(panel$canton_abbr)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Treated cantons: %d\n",
            n_distinct(panel$canton_abbr[panel$ever_treated])))
cat(sprintf("Control cantons: %d\n",
            n_distinct(panel$canton_abbr[!panel$ever_treated])))

cat("\nMean EV share by treatment status:\n")
panel %>%
  filter(!is.na(ev_share)) %>%
  group_by(treated = ifelse(treated == 1, "Treated", "Control")) %>%
  summarise(
    mean_ev_share = mean(ev_share, na.rm = TRUE),
    mean_ev_regs = mean(ev_regs, na.rm = TRUE),
    mean_total_regs = mean(total_regs, na.rm = TRUE),
    n = n()
  ) %>%
  print()

cat("\nEV share over time (national):\n")
panel %>%
  group_by(year) %>%
  summarise(
    total_ev = sum(ev_regs, na.rm = TRUE),
    total_all = sum(total_regs, na.rm = TRUE),
    ev_share = total_ev / total_all
  ) %>%
  print(n = 20)

# -------------------------------------------------------------------
# 7. Filter to analysis sample
# -------------------------------------------------------------------
# Drop municipalities with very few registrations (< 5 total per year on average)
muni_avg <- panel %>%
  group_by(muni_id) %>%
  summarise(avg_total = mean(total_regs, na.rm = TRUE))

small_munis <- muni_avg %>% filter(avg_total < 5) %>% pull(muni_id)
cat(sprintf("\nDropping %d municipalities with avg < 5 annual registrations\n",
            length(small_munis)))

panel_analysis <- panel %>%
  filter(!muni_id %in% small_munis)

panel_long_analysis <- panel_long %>%
  filter(!muni_id %in% small_munis)

cat(sprintf("Analysis sample: %d municipality-years, %d municipalities\n",
            nrow(panel_analysis), n_distinct(panel_analysis$muni_id)))

# -------------------------------------------------------------------
# 8. Save
# -------------------------------------------------------------------
write_csv(panel_analysis, "../data/panel_analysis.csv")
write_csv(panel_long_analysis, "../data/panel_long_analysis.csv")
write_csv(panel, "../data/panel_full.csv")

cat("\nSaved analysis datasets to data/\n")
cat("=== Cleaning Complete ===\n")
