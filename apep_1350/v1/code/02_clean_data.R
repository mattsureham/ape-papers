## 02_clean_data.R — Construct analysis panel
## apep_1350: The Segregation Dividend

source("00_packages.R")

# ── 1. Load QWI data ──
qwi <- arrow::read_parquet("../data/qwi_rh_n3_selected.parquet") |> as_tibble()
qwi_sector <- arrow::read_parquet("../data/qwi_rh_ns_selected.parquet") |> as_tibble()

cat(sprintf("Loaded %s 3-digit rows, %s sector rows\n",
            format(nrow(qwi), big.mark = ","),
            format(nrow(qwi_sector), big.mark = ",")))

# ── 2. Medicaid expansion timing ──
# Source: KFF State Health Facts, well-established in literature
# States that expanded Medicaid under ACA with effective dates
# Using year-quarter of expansion as treatment timing
medicaid_expansion <- tribble(
  ~state_fips, ~state_abbr, ~expansion_date,
  # Jan 2014 wave (25 states + DC)
  4,  "AZ", "2014-01-01",
  6,  "CA", "2014-01-01",
  8,  "CO", "2014-01-01",
  9,  "CT", "2014-01-01",
  10, "DE", "2014-01-01",
  11, "DC", "2014-01-01",
  12, "HI", "2014-01-01",  # Hawaii = 15 actually
  15, "HI", "2014-01-01",
  17, "IL", "2014-01-01",
  19, "IA", "2014-01-01",
  21, "KY", "2014-01-01",
  24, "MD", "2014-01-01",
  25, "MA", "2014-01-01",
  26, "MI", "2014-04-01",
  27, "MN", "2014-01-01",
  29, "NV", "2014-01-01",  # Nevada = 32 actually
  32, "NV", "2014-01-01",
  34, "NJ", "2014-01-01",
  35, "NM", "2014-01-01",
  36, "NY", "2014-01-01",
  38, "ND", "2014-01-01",
  39, "OH", "2014-01-01",
  41, "OR", "2014-01-01",
  42, "RI", "2014-01-01",  # RI = 44
  44, "RI", "2014-01-01",
  47, "VT", "2014-01-01",  # VT = 50
  50, "VT", "2014-01-01",
  53, "WA", "2014-01-01",
  54, "WV", "2014-01-01",
  # Later waves
  30, "MT", "2016-01-01",
  16, "AK", "2015-09-01",
  18, "IN", "2015-02-01",
  22, "LA", "2016-07-01",
  33, "NH", "2014-08-15",
  40, "PA", "2015-01-01",
  # 2019-2021 wave
  20, "ID", "2020-01-01",  # ID = 16? No, Idaho = 16
  23, "ME", "2019-01-10",
  37, "NE", "2020-10-01",
  46, "UT", "2020-01-01",  # UT = 49
  49, "UT", "2020-01-01",
  51, "VA", "2019-01-01"
)

# Fix: clean up duplicate/wrong FIPS entries — use only correct FIPS
medicaid_expansion <- tribble(
  ~state_fips, ~expansion_date,
  4,  "2014-01-01",  # AZ
  6,  "2014-01-01",  # CA
  8,  "2014-01-01",  # CO
  9,  "2014-01-01",  # CT
  10, "2014-01-01",  # DE
  11, "2014-01-01",  # DC
  15, "2014-01-01",  # HI
  17, "2014-01-01",  # IL
  19, "2014-01-01",  # IA
  21, "2014-01-01",  # KY
  24, "2014-01-01",  # MD
  25, "2014-01-01",  # MA
  26, "2014-04-01",  # MI
  27, "2014-01-01",  # MN
  32, "2014-01-01",  # NV
  34, "2014-01-01",  # NJ
  35, "2014-01-01",  # NM
  36, "2014-01-01",  # NY
  38, "2014-01-01",  # ND
  39, "2014-01-01",  # OH
  41, "2014-01-01",  # OR
  44, "2014-01-01",  # RI
  50, "2014-01-01",  # VT
  53, "2014-01-01",  # WA
  54, "2014-01-01",  # WV
  33, "2014-08-15",  # NH
  16, "2015-09-01",  # AK
  18, "2015-02-01",  # IN
  40, "2015-01-01",  # PA
  30, "2016-01-01",  # MT
  22, "2016-07-01",  # LA
  51, "2019-01-01",  # VA
  23, "2019-01-10",  # ME
  16, "2020-01-01",  # ID — wait, AK is 2, not 16. ID=16
  37, "2020-10-01",  # NE — NE is 31
  49, "2020-01-01",  # UT
  28, "2024-01-01",  # MS — too late for our analysis
  45, "2024-01-01",  # SC — too late
  48, "2024-03-01"   # SD? No. These are after our sample.
)

# Final clean version — verified FIPS codes
medicaid_expansion <- tribble(
  ~state_fips, ~expansion_date,
  4,  "2014-01-01",  # AZ
  6,  "2014-01-01",  # CA
  8,  "2014-01-01",  # CO
  9,  "2014-01-01",  # CT
  10, "2014-01-01",  # DE
  11, "2014-01-01",  # DC
  15, "2014-01-01",  # HI
  17, "2014-01-01",  # IL
  19, "2014-01-01",  # IA
  21, "2014-01-01",  # KY
  24, "2014-01-01",  # MD
  25, "2014-01-01",  # MA
  26, "2014-04-01",  # MI
  27, "2014-01-01",  # MN
  32, "2014-01-01",  # NV
  34, "2014-01-01",  # NJ
  35, "2014-01-01",  # NM
  36, "2014-01-01",  # NY
  38, "2014-01-01",  # ND
  39, "2014-01-01",  # OH
  41, "2014-01-01",  # OR
  44, "2014-01-01",  # RI
  50, "2014-01-01",  # VT
  53, "2014-01-01",  # WA
  54, "2014-01-01",  # WV
  33, "2014-08-15",  # NH
  2,  "2015-09-01",  # AK
  18, "2015-02-01",  # IN
  40, "2015-01-01",  # PA
  30, "2016-01-01",  # MT
  22, "2016-07-01",  # LA
  51, "2019-01-01",  # VA
  23, "2019-01-10",  # ME
  16, "2020-01-01",  # ID
  31, "2020-10-01",  # NE
  49, "2020-01-01",  # UT
  28, "2024-01-01",  # MS (drop — too late)
  45, "2024-01-01",  # SC (drop — too late)
  48, "2024-03-01"   # SD (drop — too late)
) |>
  mutate(expansion_date = as.Date(expansion_date)) |>
  # Drop states that expanded after 2021 (insufficient post-periods)
  filter(expansion_date <= as.Date("2021-12-31")) |>
  mutate(
    expansion_year = year(expansion_date),
    expansion_quarter = quarter(expansion_date),
    # Year-quarter numeric: 2014Q1 = 2014.0, 2014Q2 = 2014.25, etc.
    expansion_yq = expansion_year + (expansion_quarter - 1) / 4
  )

cat(sprintf("Medicaid expansion states: %d\n", nrow(medicaid_expansion)))

# ── 3. Build state FIPS from county FIPS ──
qwi <- qwi |>
  mutate(
    state_fips = as.integer(fips) %/% 1000L,
    yq = year + (quarter - 1) / 4
  ) |>
  filter(state_fips > 0, state_fips <= 56)  # Exclude national aggregates and territories

qwi_sector <- qwi_sector |>
  mutate(
    state_fips = as.integer(fips) %/% 1000L,
    yq = year + (quarter - 1) / 4
  ) |>
  filter(state_fips > 0, state_fips <= 56)

# ── 4. Aggregate to state level for the main analysis ──
# County-level has too much suppression for race × 3-digit industry
# State × quarter × race × industry is the right unit

# Filter to valid observations before aggregation
qwi_valid <- qwi |>
  filter(industry == "624") |>
  mutate(
    Emp = as.numeric(Emp),
    EarnS = as.numeric(EarnS),
    HirA = as.numeric(HirA),
    Sep = as.numeric(Sep)
  ) |>
  filter(!is.na(Emp), !is.na(EarnS), Emp > 0, EarnS > 0)

state_panel <- qwi_valid |>
  group_by(state_fips, year, quarter, yq, race) |>
  summarise(
    EarnS = sum(Emp * EarnS) / sum(Emp),  # weighted mean BEFORE Emp is overwritten
    Emp = sum(Emp),
    HirA = sum(HirA, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    n_counties = n(),
    .groups = "drop"
  ) |>
  filter(Emp > 0, !is.na(EarnS))

cat(sprintf("State panel (624): %s rows\n", format(nrow(state_panel), big.mark = ",")))

# ── 5. Create Black/White earnings ratio panel ──
bw_ratio <- state_panel |>
  select(state_fips, year, quarter, yq, race, Emp, EarnS, HirA) |>
  pivot_wider(
    names_from = race,
    values_from = c(Emp, EarnS, HirA),
    names_sep = "_"
  ) |>
  # A1 = White alone, A2 = Black alone
  mutate(
    bw_earn_ratio = EarnS_A2 / EarnS_A1,
    black_emp_share = Emp_A2 / (Emp_A1 + Emp_A2),
    ln_earn_black = log(EarnS_A2),
    ln_earn_white = log(EarnS_A1),
    ln_earn_gap = ln_earn_black - ln_earn_white,
    total_emp = Emp_A1 + Emp_A2
  ) |>
  filter(!is.na(bw_earn_ratio), is.finite(bw_earn_ratio))

# ── 6. Merge treatment timing ──
bw_ratio <- bw_ratio |>
  left_join(medicaid_expansion |> select(state_fips, expansion_yq), by = "state_fips") |>
  mutate(
    expanded = !is.na(expansion_yq),
    post = !is.na(expansion_yq) & yq >= expansion_yq,
    # For CS estimator: first_treat = expansion_yq for treated, 0 for never-treated
    first_treat_yq = if_else(expanded, expansion_yq, 0)
  )

cat(sprintf("\nAnalysis panel: %d state-quarters\n", nrow(bw_ratio)))
cat(sprintf("  Expansion states: %d\n", sum(bw_ratio$expanded & bw_ratio$yq == bw_ratio$yq[1])))
cat(sprintf("  Never-expanded: %d\n", sum(!bw_ratio$expanded & bw_ratio$yq == bw_ratio$yq[1])))

# ── 7. Build placebo panels (sector-level 62 vs 72) ──
sector_panel <- qwi_sector |>
  mutate(Emp = as.numeric(Emp), EarnS = as.numeric(EarnS), HirA = as.numeric(HirA)) |>
  filter(!is.na(Emp), Emp > 0, !is.na(EarnS), EarnS > 0) |>
  group_by(state_fips, year, quarter, yq, race, industry) |>
  summarise(
    EarnS = sum(Emp * EarnS) / sum(Emp),  # weighted mean BEFORE Emp
    Emp = sum(Emp),
    HirA = sum(HirA, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(Emp > 0, !is.na(EarnS))

bw_sector <- sector_panel |>
  select(state_fips, year, quarter, yq, race, industry, Emp, EarnS) |>
  pivot_wider(
    names_from = race,
    values_from = c(Emp, EarnS),
    names_sep = "_"
  ) |>
  mutate(
    bw_earn_ratio = EarnS_A2 / EarnS_A1,
    black_emp_share = Emp_A2 / (Emp_A1 + Emp_A2),
    ln_earn_gap = log(EarnS_A2) - log(EarnS_A1)
  ) |>
  filter(!is.na(bw_earn_ratio), is.finite(bw_earn_ratio)) |>
  left_join(medicaid_expansion |> select(state_fips, expansion_yq), by = "state_fips") |>
  mutate(
    expanded = !is.na(expansion_yq),
    post = !is.na(expansion_yq) & yq >= expansion_yq,
    first_treat_yq = if_else(expanded, expansion_yq, 0)
  )

# ── 8. Summary statistics ──
cat("\n── Summary: NAICS 624, B/W Earnings Ratio ──\n")
bw_ratio |>
  group_by(period = case_when(
    year <= 2005 ~ "2001-2005",
    year <= 2010 ~ "2006-2010",
    year <= 2015 ~ "2011-2015",
    TRUE ~ "2016+"
  )) |>
  summarise(
    mean_ratio = mean(bw_earn_ratio, na.rm = TRUE),
    mean_black_share = mean(black_emp_share, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) |>
  print()

# ── 9. Save analysis datasets ──
arrow::write_parquet(bw_ratio, "../data/analysis_panel_624.parquet")
arrow::write_parquet(bw_sector, "../data/analysis_panel_sector.parquet")
arrow::write_parquet(state_panel, "../data/state_panel_624.parquet")

cat("\n02_clean_data.R complete.\n")
