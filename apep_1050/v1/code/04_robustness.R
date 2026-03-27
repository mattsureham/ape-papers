## 04_robustness.R — Robustness and placebo tests
## apep_1050: Swiss EV Tax Exemptions
source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- read_csv("../data/panel_analysis.csv", show_col_types = FALSE)
panel_long <- read_csv("../data/panel_long_analysis.csv", show_col_types = FALSE)

# Add intensity groups
panel <- panel %>%
  mutate(
    intensity_group = case_when(
      ev_tax_discount_pct == 100 ~ "Full (100%)",
      ev_tax_discount_pct > 0 ~ "Partial (50-75%)",
      TRUE ~ "None (0%)"
    ),
    intensity_group = factor(intensity_group,
                             levels = c("None (0%)", "Partial (50-75%)", "Full (100%)"))
  )

# -------------------------------------------------------------------
# 1. Placebo: Effect on ICE registrations (should be null)
# -------------------------------------------------------------------
cat("\n--- Placebo: ICE Registrations ---\n")

panel <- panel %>%
  mutate(ice_share = ifelse(total_regs > 0, ice_regs / total_regs, NA_real_))

m_placebo_ice <- feols(ice_share ~ tax_discount | muni_id + year,
                       data = panel, cluster = ~canton_abbr)

m_placebo_ice_int <- feols(ice_share ~ i(intensity_group, ref = "None (0%)") | muni_id + year,
                           data = panel, cluster = ~canton_abbr)

cat("Placebo test (ICE share):\n")
etable(m_placebo_ice, m_placebo_ice_int,
       headers = c("Continuous", "Intensity"))

# -------------------------------------------------------------------
# 2. Placebo: Effect on Hybrid registrations (should be smaller/null)
# -------------------------------------------------------------------
cat("\n--- Placebo: Hybrid Share ---\n")

panel <- panel %>%
  mutate(hybrid_share = ifelse(total_regs > 0, Hybrid / total_regs, NA_real_))

m_placebo_hybrid <- feols(hybrid_share ~ tax_discount | muni_id + year,
                          data = panel, cluster = ~canton_abbr)

cat("Placebo test (Hybrid share):\n")
etable(m_placebo_hybrid)

# -------------------------------------------------------------------
# 3. Broad EV definition (BEV + PHEV)
# -------------------------------------------------------------------
cat("\n--- Robustness: BEV + PHEV ---\n")

m_broad <- feols(ev_share_broad ~ tax_discount | muni_id + year,
                 data = panel, cluster = ~canton_abbr)

m_broad_int <- feols(ev_share_broad ~ i(intensity_group, ref = "None (0%)") | muni_id + year,
                     data = panel, cluster = ~canton_abbr)

cat("Broad EV (BEV + PHEV):\n")
etable(m_broad, m_broad_int)

# -------------------------------------------------------------------
# 4. Exclude early adopters (ZH, SO, NW, ZG, GE — all from 2012)
# -------------------------------------------------------------------
cat("\n--- Robustness: Exclude 2012 Adopters ---\n")

early_cantons <- c("ZH", "SO", "NW", "ZG", "GE")
panel_no_early <- panel %>% filter(!canton_abbr %in% early_cantons)

m_no_early <- feols(ev_share ~ tax_discount | muni_id + year,
                    data = panel_no_early, cluster = ~canton_abbr)

m_no_early_int <- feols(ev_share ~ i(intensity_group, ref = "None (0%)") | muni_id + year,
                        data = panel_no_early, cluster = ~canton_abbr)

cat("Excluding early adopters:\n")
etable(m_no_early, m_no_early_int)

# -------------------------------------------------------------------
# 5. Exclude COVID period (2020-2021)
# -------------------------------------------------------------------
cat("\n--- Robustness: Exclude COVID Years ---\n")

panel_no_covid <- panel %>% filter(!year %in% c(2020, 2021))

m_no_covid <- feols(ev_share ~ tax_discount | muni_id + year,
                    data = panel_no_covid, cluster = ~canton_abbr)

m_no_covid_int <- feols(ev_share ~ i(intensity_group, ref = "None (0%)") | muni_id + year,
                        data = panel_no_covid, cluster = ~canton_abbr)

cat("Excluding 2020-2021:\n")
etable(m_no_covid, m_no_covid_int)

# -------------------------------------------------------------------
# 6. Pre-2019 sample (before EV adoption accelerated nationally)
# -------------------------------------------------------------------
cat("\n--- Robustness: Pre-2019 Sample ---\n")

panel_pre2019 <- panel %>% filter(year <= 2018)

m_pre2019 <- feols(ev_share ~ tax_discount | muni_id + year,
                   data = panel_pre2019, cluster = ~canton_abbr)

m_pre2019_int <- feols(ev_share ~ i(intensity_group, ref = "None (0%)") | muni_id + year,
                       data = panel_pre2019, cluster = ~canton_abbr)

cat("Pre-2019 only:\n")
etable(m_pre2019, m_pre2019_int)

# -------------------------------------------------------------------
# 7. Canton-level aggregation (26 clusters)
# -------------------------------------------------------------------
cat("\n--- Robustness: Canton-Level Aggregation ---\n")

canton_panel <- panel %>%
  group_by(canton_abbr, year) %>%
  summarise(
    ev_regs = sum(ev_regs, na.rm = TRUE),
    ice_regs = sum(ice_regs, na.rm = TRUE),
    total_regs = sum(total_regs, na.rm = TRUE),
    ev_share = ev_regs / total_regs,
    tax_discount = first(tax_discount),
    ev_tax_discount_pct = first(ev_tax_discount_pct),
    treated = first(treated),
    ever_treated = first(ever_treated),
    first_treat_year = first(first_treat_year),
    .groups = "drop"
  ) %>%
  mutate(
    intensity_group = case_when(
      ev_tax_discount_pct == 100 ~ "Full (100%)",
      ev_tax_discount_pct > 0 ~ "Partial (50-75%)",
      TRUE ~ "None (0%)"
    ),
    intensity_group = factor(intensity_group,
                             levels = c("None (0%)", "Partial (50-75%)", "Full (100%)"))
  )

m_canton <- feols(ev_share ~ tax_discount | canton_abbr + year,
                  data = canton_panel, cluster = ~canton_abbr)

m_canton_int <- feols(ev_share ~ i(intensity_group, ref = "None (0%)") | canton_abbr + year,
                      data = canton_panel, cluster = ~canton_abbr)

cat("Canton-level:\n")
etable(m_canton, m_canton_int)

# -------------------------------------------------------------------
# 8. Save robustness results
# -------------------------------------------------------------------
robustness_models <- list(
  placebo_ice = m_placebo_ice,
  placebo_ice_int = m_placebo_ice_int,
  placebo_hybrid = m_placebo_hybrid,
  broad_ev = m_broad,
  broad_ev_int = m_broad_int,
  no_early = m_no_early,
  no_early_int = m_no_early_int,
  no_covid = m_no_covid,
  no_covid_int = m_no_covid_int,
  pre2019 = m_pre2019,
  pre2019_int = m_pre2019_int,
  canton_agg = m_canton,
  canton_agg_int = m_canton_int
)

saveRDS(robustness_models, "../data/robustness_results.rds")

cat("\n=== Robustness Complete ===\n")
