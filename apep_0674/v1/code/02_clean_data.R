## ============================================================
## 02_clean_data.R — Construct analysis panel
## apep_0674: PBF and the Cream-Skimming Margin
## ============================================================

source("00_packages.R")
load("../data/ipeds_raw.RData")

## ============================
## PBF 2.0 Treatment Coding
## ============================
## Sources: NCSL, HCM Strategists (2015), Hillman et al. (2015),
## Dougherty & Natow (2015), state legislative records.

pbf_states <- tribble(
  ~state, ~pbf_year, ~pbf_share_pct,
  "TN",   2010,  85,
  "OH",   2013,  50,
  "IN",   2009,   5,
  "LA",   2010,  15,
  "MS",   2011,   5,
  "NM",   2012,   5,
  "MI",   2012,  10,
  "AZ",   2012,  10,
  "IL",   2012,  10,
  "NV",   2013,  20,
  "ND",   2013,  15,
  "MN",   2014,   5,
  "MT",   2014,   5,
  "FL",   2014,  25,
  "OR",   2014,  10,
  "VA",   2014,  10,
  "CO",   2014,  10,
  "WI",   2014,  10,
  "ME",   2014,   5,
  "AR",   2015,  25,
  "NC",   2016,  10,
  "WY",   2016,  10,
  "KY",   2017,  30,
  "TX",   2019,  10,
  "AL",   2019,   5
)

cat("PBF states:", nrow(pbf_states), "\n")
cat("Treatment years range:", min(pbf_states$pbf_year), "-", max(pbf_states$pbf_year), "\n")

## ============================
## Institutional characteristics — keep latest year per institution
## ============================
inst <- hd |>
  group_by(unitid) |>
  slice_max(order_by = year, n = 1) |>
  ungroup() |>
  select(unitid, institution_name, state, sector, control, carnegie)

cat("Unique institutions:", n_distinct(inst$unitid), "\n")

## ============================
## Completions: total bachelor's by institution-year
## ============================
## cipcode "99" = Grand total across all fields (check if it exists)
cip99 <- comp |> filter(cipcode == "99")
if (nrow(cip99) < 100) {
  ## If no cipcode 99, sum across all CIP codes
  cat("No grand-total CIP code; aggregating across all fields.\n")
  completions <- comp |>
    group_by(unitid, year) |>
    summarise(
      bachelors_total = sum(ctotalt, na.rm = TRUE),
      bachelors_male  = sum(ctotalm, na.rm = TRUE),
      bachelors_female = sum(ctotalw, na.rm = TRUE),
      bachelors_black = sum(cbkaat, na.rm = TRUE),
      bachelors_hispanic = sum(chispt, na.rm = TRUE),
      bachelors_white = sum(cwhitt, na.rm = TRUE),
      .groups = "drop"
    )
} else {
  completions <- cip99 |>
    group_by(unitid, year) |>
    summarise(
      bachelors_total = sum(ctotalt, na.rm = TRUE),
      bachelors_male  = sum(ctotalm, na.rm = TRUE),
      bachelors_female = sum(ctotalw, na.rm = TRUE),
      bachelors_black = sum(cbkaat, na.rm = TRUE),
      bachelors_hispanic = sum(chispt, na.rm = TRUE),
      bachelors_white = sum(cwhitt, na.rm = TRUE),
      .groups = "drop"
    )
}

cat("Completions panel:", nrow(completions), "institution-years\n")

## ============================
## Graduation rates: 6-year (150% time) from gr200
## ============================
## bagr150 = 6-year graduation rate (percentage)
## baac150 = adjusted cohort size
gr_panel <- gr |>
  filter(!is.na(bagr150), bagr150 >= 0, bagr150 <= 100) |>
  rename(grad_rate_150 = bagr150, cohort_total = baac150) |>
  select(unitid, year, grad_rate_150, cohort_total)

cat("Graduation rate panel:", nrow(gr_panel), "institution-years\n")
cat("  Grad rate range:", range(gr_panel$grad_rate_150), "\n")
cat("  Years:", min(gr_panel$year), "-", max(gr_panel$year), "\n")

## ============================
## Pell share
## ============================
## upgrntn = number receiving Pell grants
## scugffn = total undergrads for financial aid purposes
pell_panel <- sfa |>
  filter(!is.na(upgrntn), !is.na(scugffn), scugffn > 0) |>
  mutate(pell_share = upgrntn / scugffn * 100) |>
  select(unitid, year, upgrntn, scugffn, pell_share) |>
  filter(pell_share >= 0, pell_share <= 100)

cat("Pell panel:", nrow(pell_panel), "institution-years\n")

## ============================
## Enrollment by race
## ============================
## efalevel = 1 (all students), line = 29 (grand total)
enroll_race <- efa |>
  filter(efalevel == 1, line == 29) |>
  group_by(unitid, year) |>
  summarise(
    enroll_total = sum(eftotlt, na.rm = TRUE),
    enroll_black = sum(efbkaat, na.rm = TRUE),
    enroll_hispanic = sum(efhispt, na.rm = TRUE),
    enroll_white = sum(efwhitt, na.rm = TRUE),
    enroll_asian = sum(efasiat, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(enroll_total > 0) |>
  mutate(
    pct_black = enroll_black / enroll_total * 100,
    pct_hispanic = enroll_hispanic / enroll_total * 100,
    pct_minority = (enroll_black + enroll_hispanic) / enroll_total * 100
  )

cat("Enrollment race panel:", nrow(enroll_race), "institution-years\n")

## ============================
## Total 12-month enrollment
## ============================
enroll_total <- effy |>
  filter(effylev == 1) |>
  group_by(unitid, year) |>
  summarise(fte_total = sum(efytotlt, na.rm = TRUE), .groups = "drop") |>
  filter(fte_total > 0)

cat("12-month enrollment panel:", nrow(enroll_total), "institution-years\n")

## ============================
## Merge into analysis panel
## ============================

## Get unique years from data
all_years <- sort(unique(c(completions$year, enroll_race$year)))
all_years <- all_years[all_years >= 2003 & all_years <= 2023]

panel <- inst |>
  cross_join(tibble(year = all_years)) |>
  ## Add treatment info
  left_join(pbf_states |> select(state, pbf_year), by = "state") |>
  mutate(
    pbf_treated = !is.na(pbf_year),
    post_pbf = ifelse(pbf_treated, year >= pbf_year, FALSE),
    first_treat = ifelse(pbf_treated, pbf_year, 0L),
    is_public = control == 1,
    is_public_4yr = sector == 1,
    is_private_4yr = sector == 2
  ) |>
  ## Join outcomes
  left_join(completions, by = c("unitid", "year")) |>
  left_join(gr_panel |> select(unitid, year, grad_rate_150, cohort_total),
            by = c("unitid", "year")) |>
  left_join(pell_panel |> select(unitid, year, pell_share, upgrntn, scugffn),
            by = c("unitid", "year")) |>
  left_join(enroll_race, by = c("unitid", "year")) |>
  left_join(enroll_total, by = c("unitid", "year"))

cat("\n=== FULL PANEL ===\n")
cat("Total rows:", nrow(panel), "\n")
cat("Unique institutions:", n_distinct(panel$unitid), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")

## ============================
## Analysis sample: public 4-year institutions
## ============================

analysis_df <- panel |>
  filter(is_public_4yr) |>
  ## Keep institution-years with at least one outcome
  filter(!is.na(bachelors_total) | !is.na(grad_rate_150) | !is.na(enroll_total)) |>
  ## Drop tiny institutions
  group_by(unitid) |>
  filter(max(bachelors_total, na.rm = TRUE) >= 50) |>
  ungroup() |>
  mutate(
    ln_bachelors = log(pmax(bachelors_total, 1)),
    ln_enroll = log(pmax(enroll_total, 1)),
    ln_fte = log(pmax(fte_total, 1))
  )

cat("\n=== PUBLIC 4-YEAR ANALYSIS SAMPLE ===\n")
cat("Rows:", nrow(analysis_df), "\n")
cat("Institutions:", n_distinct(analysis_df$unitid), "\n")
cat("PBF institutions:", n_distinct(analysis_df$unitid[analysis_df$pbf_treated]), "\n")
cat("Control institutions:", n_distinct(analysis_df$unitid[!analysis_df$pbf_treated]), "\n")
cat("\nTreatment cohorts:\n")
cohort_tab <- analysis_df |>
  filter(first_treat > 0) |>
  distinct(unitid, first_treat) |>
  count(first_treat, name = "n_institutions")
print(cohort_tab)

## Placebo sample: private 4-year institutions
placebo_df <- panel |>
  filter(is_private_4yr) |>
  filter(!is.na(bachelors_total) | !is.na(enroll_total)) |>
  group_by(unitid) |>
  filter(max(bachelors_total, na.rm = TRUE) >= 50) |>
  ungroup()

cat("\nPlacebo (private 4yr):", n_distinct(placebo_df$unitid), "institutions\n")

## ============================
## Save
## ============================
save(analysis_df, placebo_df, panel, pbf_states,
     file = "../data/analysis_panel.RData")
cat("\nSaved analysis panel.\n")
