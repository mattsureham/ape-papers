## 02_clean_data.R — Construct analysis dataset
## apep_0796: Swiss Second Home Ban RDD

source("00_packages.R")

data_dir <- "../data"
zwg <- readRDS(file.path(data_dir, "zwg_panel_raw.rds"))

cat("Raw panel:", nrow(zwg), "obs,", n_distinct(zwg$muni_id), "municipalities,",
    n_distinct(zwg$wave), "waves\n")

## ---- 1. Create numeric wave indicator ----
wave_map <- data.frame(
  wave = c("2017", "2018", "2019-03", "2019-10",
           "2020-03", "2020-10", "2021-03", "2021-10",
           "2022-03", "2022-10", "2023-03", "2023-10",
           "2024-03", "2024-10", "2025-03", "2025-10"),
  wave_num = 1:16,
  wave_year = c(2017, 2018, 2019, 2019.5,
                2020, 2020.5, 2021, 2021.5,
                2022, 2022.5, 2023, 2023.5,
                2024, 2024.5, 2025, 2025.5),
  stringsAsFactors = FALSE
)

zwg <- zwg %>%
  left_join(wave_map, by = "wave") %>%
  filter(!is.na(wave_num))

## ---- 2. Identify baseline (earliest wave) for each municipality ----
## Use earliest available observation as baseline running variable
baseline <- zwg %>%
  group_by(muni_id) %>%
  arrange(wave_num) %>%
  slice(1) %>%
  ungroup() %>%
  select(muni_id, baseline_secondary_pct = secondary_pct,
         baseline_primary_pct = primary_pct,
         baseline_total = total_dwellings,
         baseline_wave = wave)

cat("Baseline wave distribution:\n")
print(table(baseline$baseline_wave))

## ---- 3. Treatment assignment ----
## Municipalities above 20% second-home share face construction ban
baseline <- baseline %>%
  mutate(
    treated = as.integer(baseline_secondary_pct > 20),
    running_var = baseline_secondary_pct - 20  # centered at cutoff
  )

cat("\nTreatment assignment (baseline):\n")
cat("  Treated (>20%):", sum(baseline$treated == 1), "\n")
cat("  Control (<=20%):", sum(baseline$treated == 0), "\n")

## ---- 4. Merge baseline treatment to panel ----
zwg_analysis <- zwg %>%
  inner_join(baseline %>% select(muni_id, treated, running_var,
                                  baseline_secondary_pct, baseline_primary_pct,
                                  baseline_total),
             by = "muni_id")

## ---- 5. Create outcome variables ----
## Primary outcome: change in primary home share from baseline
zwg_analysis <- zwg_analysis %>%
  group_by(muni_id) %>%
  arrange(wave_num) %>%
  mutate(
    delta_primary = primary_pct - first(primary_pct),
    delta_secondary = secondary_pct - first(secondary_pct),
    log_total = log(total_dwellings),
    pct_change_total = (total_dwellings - first(total_dwellings)) / first(total_dwellings) * 100
  ) %>%
  ungroup()

## ---- 6. Create cross-section for main RDD ----
## Latest wave vs baseline
latest_wave <- max(zwg_analysis$wave_num)

rdd_cross <- zwg_analysis %>%
  filter(wave_num == latest_wave) %>%
  select(muni_id, muni_name, canton, treated, running_var,
         baseline_secondary_pct, baseline_primary_pct, baseline_total,
         latest_primary_pct = primary_pct,
         latest_secondary_pct = secondary_pct,
         latest_total = total_dwellings,
         delta_primary, delta_secondary, pct_change_total) %>%
  filter(!is.na(running_var), !is.na(delta_primary))

cat("\nRDD cross-section:", nrow(rdd_cross), "municipalities\n")
cat("  Running var range: [", min(rdd_cross$running_var), ",",
    max(rdd_cross$running_var), "]\n")

## ---- 7. Add population data if available ----
if (file.exists(file.path(data_dir, "population_2020.rds"))) {
  pop <- readRDS(file.path(data_dir, "population_2020.rds"))
  rdd_cross <- rdd_cross %>%
    left_join(pop %>% select(muni_id_num, population_2020),
              by = c("muni_id" = "muni_id_num"))
  cat("Population data merged:", sum(!is.na(rdd_cross$population_2020)), "matched\n")
} else {
  rdd_cross$population_2020 <- NA_real_
  cat("No population data available — proceeding without.\n")
}

## ---- 8. Language region proxy (from canton) ----
german_cantons <- c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG",
                    "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG")
french_cantons <- c("GE", "VD", "NE", "JU")
italian_cantons <- c("TI")
bilingual_cantons <- c("FR", "VS", "BE")  # BE is in both

rdd_cross <- rdd_cross %>%
  mutate(
    lang_german = as.integer(canton %in% german_cantons),
    lang_french = as.integer(canton %in% french_cantons),
    lang_italian = as.integer(canton %in% italian_cantons),
    alpine = as.integer(canton %in% c("GR", "VS", "TI", "UR", "OW", "NW", "GL", "BE", "SZ"))
  )

## ---- 9. Summary statistics ----
cat("\n=== Summary Statistics ===\n")
cat("\nBaseline secondary home share (%):\n")
print(summary(rdd_cross$baseline_secondary_pct))

cat("\nChange in primary home share (pp) from baseline to latest:\n")
cat("  Overall:", round(mean(rdd_cross$delta_primary, na.rm = TRUE), 3), "pp\n")
cat("  Treated:", round(mean(rdd_cross$delta_primary[rdd_cross$treated == 1], na.rm = TRUE), 3), "pp\n")
cat("  Control:", round(mean(rdd_cross$delta_primary[rdd_cross$treated == 0], na.rm = TRUE), 3), "pp\n")

cat("\nMunicipalities within 5pp bandwidth (15-25%):",
    sum(abs(rdd_cross$running_var) <= 5), "\n")
cat("Municipalities within 2pp bandwidth (18-22%):",
    sum(abs(rdd_cross$running_var) <= 2), "\n")

## ---- 10. Save analysis datasets ----
saveRDS(rdd_cross, file.path(data_dir, "rdd_cross_section.rds"))
saveRDS(zwg_analysis, file.path(data_dir, "zwg_panel_analysis.rds"))

cat("\nSaved rdd_cross_section.rds and zwg_panel_analysis.rds\n")
