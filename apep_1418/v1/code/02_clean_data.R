## 02_clean_data.R — Merge IPEDS tables, construct Bartik instrument, build analysis panel
source("00_packages.R")

cat("=== Building analysis panel ===\n")

# Load raw data
hd <- readRDS("../data/ipeds_hd.rds")
tuition <- readRDS("../data/ipeds_tuition.rds")
fin <- readRDS("../data/ipeds_finance.rds")
fte <- readRDS("../data/ipeds_fte.rds")
sfa <- readRDS("../data/ipeds_sfa.rds")
enroll <- readRDS("../data/ipeds_enrollment.rds")
macro <- readRDS("../data/fred_macro.rds")
state_unemp <- readRDS("../data/state_unemp.rds")

# ---------------------------------------------------------------
# 1. Identify public 4-year institutions (sector 1 = public 4-year)
# ---------------------------------------------------------------
# Use most recent year to identify institution type
inst_type <- hd |>
  filter(year == max(year)) |>
  select(unitid, institution_name, state, fips_state, sector,
         carnegie_basic, hbcu, locale_code, size_category) |>
  distinct(unitid, .keep_all = TRUE)

# Sector 1 = public 4-year, sector 4 = public 2-year
pub4yr <- inst_type |> filter(sector == 1)
pub2yr <- inst_type |> filter(sector == 4)
cat(sprintf("Public 4-year: %d institutions\n", nrow(pub4yr)))
cat(sprintf("Public 2-year: %d institutions\n", nrow(pub2yr)))

# ---------------------------------------------------------------
# 2. Merge all IPEDS tables for public 4-year institutions
# ---------------------------------------------------------------
panel <- pub4yr |>
  select(unitid, institution_name, state, fips_state, sector,
         carnegie_basic, hbcu) |>
  cross_join(tibble(year = 2003:2022)) |>
  # Tuition
  left_join(tuition, by = c("unitid", "year")) |>
  # Finance
  left_join(fin, by = c("unitid", "year")) |>
  # FTE
  left_join(fte |> select(unitid, year, fte_ug, fte_grad, fte_total),
            by = c("unitid", "year")) |>
  # SFA (Pell)
  left_join(sfa |> select(unitid, year, pell_n, pell_pct, pell_avg_amt,
                           fed_grant_n, fed_grant_pct, total_pell_recipients),
            by = c("unitid", "year")) |>
  # Enrollment by race
  left_join(enroll |> select(unitid, year, total, black, hispanic, white,
                              asian, nonresident),
            by = c("unitid", "year"))

cat(sprintf("Panel before cleaning: %d obs (%d institutions × %d years)\n",
            nrow(panel), n_distinct(panel$unitid), n_distinct(panel$year)))

# ---------------------------------------------------------------
# 3. Construct key variables
# ---------------------------------------------------------------
panel <- panel |>
  mutate(
    # State appropriations per FTE
    approp_per_fte = state_approp / fte_total,
    # Log tuition
    log_tuition = log(tuition_in_state),
    # Pell share (% of undergrads receiving Pell)
    pell_share = pell_pct,
    # Alternative: compute from counts if pct missing
    pell_share_computed = ifelse(total > 0, pell_n / total * 100, NA),
    pell_share = coalesce(pell_share, pell_share_computed),
    # Race shares
    black_share = ifelse(total > 0, black / total * 100, NA),
    hispanic_share = ifelse(total > 0, hispanic / total * 100, NA),
    white_share = ifelse(total > 0, white / total * 100, NA),
    minority_share = ifelse(total > 0, (black + hispanic) / total * 100, NA),
    # Log enrollment
    log_enroll = log(total),
    # Log FTE
    log_fte = log(fte_total)
  )

# ---------------------------------------------------------------
# 4. Drop observations with missing key variables
# ---------------------------------------------------------------
panel_clean <- panel |>
  filter(
    !is.na(approp_per_fte) & approp_per_fte > 0,
    !is.na(tuition_in_state) & tuition_in_state > 0,
    !is.na(fte_total) & fte_total > 100
  )

cat(sprintf("Panel after cleaning: %d obs (%d institutions)\n",
            nrow(panel_clean), n_distinct(panel_clean$unitid)))

# ---------------------------------------------------------------
# 5. Construct Bartik instrument
# ---------------------------------------------------------------
# Bartik = initial state higher-ed budget share × national shock
# We use two instruments:
# (a) Initial HE share × national unemployment change
# (b) Initial HE share × national GDP growth

# Step 1: Compute initial state higher-ed budget share (2004 — earliest year with FTE)
state_he_share <- panel_clean |>
  filter(year == 2004) |>
  group_by(state) |>
  summarise(
    total_state_approp_init = sum(state_approp, na.rm = TRUE),
    total_fte_init = sum(fte_total, na.rm = TRUE),
    n_institutions_init = n(),
    .groups = "drop"
  ) |>
  filter(total_fte_init > 0)

# Merge state-level initial conditions + macro
panel_clean <- panel_clean |>
  left_join(state_he_share, by = "state") |>
  left_join(macro, by = "year") |>
  left_join(state_unemp, by = c("state", "year"))

# Step 2: Compute Bartik shock
unemp_base <- macro$unemp_rate[macro$year == 2004]
panel_clean <- panel_clean |>
  mutate(
    he_share_init = total_state_approp_init / total_fte_init,
    # Bartik instruments: initial HE exposure × national shock
    bartik_unemp = he_share_init * (unemp_rate - unemp_base),
    bartik_gdp = he_share_init * gdp_growth
  ) |>
  filter(!is.na(bartik_unemp))

cat(sprintf("Final panel: %d obs (%d institutions, %d states)\n",
            nrow(panel_clean), n_distinct(panel_clean$unitid),
            n_distinct(panel_clean$state)))

# ---------------------------------------------------------------
# 6. Define Carnegie classification groups
# ---------------------------------------------------------------
# Carnegie basic classification
panel_clean <- panel_clean |>
  mutate(
    inst_type = case_when(
      carnegie_basic %in% c(15, 16, 17) ~ "Research",
      carnegie_basic %in% c(18, 19, 20) ~ "Masters",
      carnegie_basic %in% c(21, 22, 23) ~ "Baccalaureate",
      TRUE ~ "Other"
    )
  )

cat("\nInstitution types:\n")
print(table(panel_clean$inst_type) / n_distinct(panel_clean$year))

# ---------------------------------------------------------------
# 7. Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")
panel_clean |>
  summarise(
    n = n(),
    n_inst = n_distinct(unitid),
    n_years = n_distinct(year),
    n_states = n_distinct(state),
    mean_tuition = mean(tuition_in_state, na.rm = TRUE),
    sd_tuition = sd(tuition_in_state, na.rm = TRUE),
    mean_approp_fte = mean(approp_per_fte, na.rm = TRUE),
    sd_approp_fte = sd(approp_per_fte, na.rm = TRUE),
    mean_pell = mean(pell_share, na.rm = TRUE),
    sd_pell = sd(pell_share, na.rm = TRUE),
    mean_minority = mean(minority_share, na.rm = TRUE),
    sd_minority = sd(minority_share, na.rm = TRUE)
  ) |>
  pivot_longer(everything()) |>
  print(n = 20)

# ---------------------------------------------------------------
# 8. Save
# ---------------------------------------------------------------
saveRDS(panel_clean, "../data/analysis_panel.rds")
cat("\nSaved analysis panel to data/analysis_panel.rds\n")
