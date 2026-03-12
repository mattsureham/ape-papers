# ==============================================================================
# 02_clean_data.R — Construct analysis panels (state-level)
# apep_0609: Wayfair Economic Nexus and Retail-Warehouse Reallocation
# ==============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_raw.rds")
nexus_dates <- readRDS("../data/nexus_dates.rds")
tax_rates <- readRDS("../data/tax_rates.rds")

# --- Create time variable ---
qwi <- qwi %>%
  mutate(
    yq = year * 10L + as.integer(quarter),
    t = (year - 2014L) * 4L + as.integer(quarter)
  )

# --- Merge policy timing and tax rates ---
qwi <- qwi %>%
  left_join(nexus_dates %>% select(state_fips, state_abbr, first_treat_yq, nexus_date),
            by = "state_fips") %>%
  left_join(tax_rates, by = "state_abbr")

# Drop rows without state match
qwi <- qwi %>% filter(!is.na(state_abbr))

cat("After merge:", nrow(qwi), "rows,", n_distinct(qwi$state_abbr), "states\n")

# --- Industry labels ---
qwi <- qwi %>%
  mutate(
    ind_label = case_when(
      industry == "44-45" ~ "Retail",
      industry == "48-49" ~ "Transport_Warehouse",
      industry == "61"    ~ "Education",
      industry == "62"    ~ "Healthcare",
      TRUE ~ "Other"
    ),
    is_retail = industry == "44-45",
    is_warehouse = industry == "48-49",
    treated_sector = is_retail
  )

# --- State-quarter panel (all ages): retail vs warehouse ratio ---
panel_all <- qwi %>%
  filter(agegrp == "A00") %>%
  select(state_fips, state_abbr, year, quarter, yq, t,
         industry, ind_label, is_retail, is_warehouse, treated_sector,
         first_treat_yq, sales_tax_rate,
         Emp, HirA, HirN, Sep, FrmJbGn, FrmJbLs, EarnS)

# Retail/Warehouse ratio panel
retail_emp <- panel_all %>%
  filter(is_retail) %>%
  select(state_fips, state_abbr, yq, t, first_treat_yq, sales_tax_rate,
         retail_emp = Emp, retail_hir = HirA,
         retail_jbgn = FrmJbGn, retail_jbls = FrmJbLs,
         retail_earn = EarnS)

warehouse_emp <- panel_all %>%
  filter(is_warehouse) %>%
  select(state_fips, yq,
         wh_emp = Emp, wh_hir = HirA,
         wh_jbgn = FrmJbGn, wh_jbls = FrmJbLs,
         wh_earn = EarnS)

ratio_panel <- retail_emp %>%
  inner_join(warehouse_emp, by = c("state_fips", "yq")) %>%
  filter(retail_emp > 0 & wh_emp > 0) %>%
  mutate(
    log_ratio = log(retail_emp / wh_emp),
    log_retail = log(retail_emp),
    log_wh = log(wh_emp),
    retail_share = retail_emp / (retail_emp + wh_emp),
    retail_creation_rate = ifelse(retail_emp > 0, retail_jbgn / retail_emp, NA),
    retail_destruction_rate = ifelse(retail_emp > 0, retail_jbls / retail_emp, NA),
    wh_creation_rate = ifelse(wh_emp > 0, wh_jbgn / wh_emp, NA),
    wh_destruction_rate = ifelse(wh_emp > 0, wh_jbls / wh_emp, NA),
    state_id = as.integer(factor(state_abbr))
  )

# --- Triple-diff panel (retail vs placebo sectors) ---
triple_panel <- panel_all %>%
  filter(ind_label %in% c("Retail", "Healthcare", "Education")) %>%
  mutate(
    log_emp = ifelse(Emp > 0, log(Emp), NA),
    creation_rate = ifelse(Emp > 0, FrmJbGn / Emp, NA),
    destruction_rate = ifelse(Emp > 0, FrmJbLs / Emp, NA)
  ) %>%
  filter(!is.na(log_emp))

# --- Age-specific panel (retail only) ---
age_panel <- qwi %>%
  filter(is_retail & agegrp != "A00") %>%
  mutate(
    age_label = case_when(
      agegrp == "A01" ~ "14-18",
      agegrp == "A02" ~ "19-21",
      agegrp == "A03" ~ "22-24",
      agegrp == "A04" ~ "25-34",
      TRUE ~ agegrp
    ),
    young = agegrp %in% c("A01", "A02", "A03"),
    log_emp = ifelse(Emp > 0, log(Emp), NA)
  ) %>%
  filter(!is.na(log_emp))

# --- Pre-COVID subsample ---
ratio_panel_precovid <- ratio_panel %>% filter(yq <= 20194)
triple_panel_precovid <- triple_panel %>% filter(yq <= 20194)

# --- Summary ---
cat("\n=== Panel Summary ===\n")
cat("Ratio panel:", nrow(ratio_panel), "state-quarters,",
    n_distinct(ratio_panel$state_abbr), "states\n")
cat("Triple panel:", nrow(triple_panel), "state-quarter-industry obs\n")
cat("Age panel:", nrow(age_panel), "state-quarter-age obs\n")
cat("Pre-COVID ratio:", nrow(ratio_panel_precovid), "obs\n")

cat("\nNational retail/warehouse ratio over time:\n")
ratio_panel %>%
  group_by(year = floor(yq / 10)) %>%
  summarise(
    mean_ratio = mean(retail_emp / wh_emp),
    mean_log_ratio = mean(log_ratio),
    .groups = "drop"
  ) %>%
  print()

cat("\nTreatment timing:\n")
ratio_panel %>%
  distinct(state_abbr, first_treat_yq) %>%
  count(first_treat_yq) %>%
  arrange(first_treat_yq) %>%
  print()

# --- Save ---
saveRDS(ratio_panel, "../data/ratio_panel.rds")
saveRDS(triple_panel, "../data/triple_panel.rds")
saveRDS(age_panel, "../data/age_panel.rds")
saveRDS(ratio_panel_precovid, "../data/ratio_panel_precovid.rds")
saveRDS(triple_panel_precovid, "../data/triple_panel_precovid.rds")

cat("\nAll panels saved.\n")
