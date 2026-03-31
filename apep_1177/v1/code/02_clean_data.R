## 02_clean_data.R — Clean and construct analysis dataset
## apep_1177: The Conviction Lottery

source("./code/00_packages.R")

## ---- Load thin cases ----
thin <- fread("./data/thin_cases.csv")
cat("Loaded", nrow(thin), "thin cases\n")

## ---- Parse filing date ----
thin[, filing_year := as.integer(substr(filing_date, 1, 4))]
thin[, filing_month := as.integer(substr(filing_date, 6, 7))]

## ---- Identify assignment pools ----
# comarca_code is extracted from case number digits 14-17
# Count unique varas per comarca
pool_structure <- thin[, .(
  n_varas = uniqueN(vara_codigo),
  n_cases = .N,
  min_year = min(filing_year, na.rm = TRUE),
  max_year = max(filing_year, na.rm = TRUE)
), by = comarca_code]

# Keep only multi-vara comarcas (≥2 varas handling trafficking cases)
multi_vara_pools <- pool_structure[n_varas >= 2]
cat("Multi-vara pools:", nrow(multi_vara_pools), "comarcas with",
    sum(multi_vara_pools$n_cases), "cases\n")

# Restrict sample
dt <- thin[comarca_code %in% multi_vara_pools$comarca_code]
cat("Analysis sample:", nrow(dt), "cases in multi-vara comarcas\n")

## ---- Load full cases with movements (if available) ----
full_path <- "./data/raw_cases.parquet"
if (file.exists(full_path)) {
  full <- arrow::read_parquet(full_path)
  setDT(full)
  cat("Loaded", nrow(full), "full cases with movements\n")

  # Merge movement data onto analysis sample
  dt <- merge(dt, full[, .(case_id, has_sorteio, has_procedencia,
                            has_improcedencia, has_pretrial_detention,
                            has_denuncia, has_definitivo, has_transito_julgado,
                            has_prescricao, n_movements,
                            date_distribuicao, date_procedencia,
                            date_definitivo, date_transito)],
              by = "case_id", all.x = TRUE)
} else {
  cat("Full cases not yet available — using thin data only\n")
  # Create placeholder columns
  dt[, `:=`(has_sorteio = NA, has_procedencia = NA,
            has_improcedencia = NA, has_pretrial_detention = NA,
            has_denuncia = NA, has_definitivo = NA,
            has_transito_julgado = NA, has_prescricao = NA,
            n_movements = NA, date_distribuicao = NA,
            date_procedencia = NA, date_definitivo = NA,
            date_transito = NA)]
}

## ---- Construct outcome variables ----
if (!is.na(dt$has_procedencia[1])) {
  # Binary conviction
  dt[, convicted := as.integer(has_procedencia == TRUE)]

  # Case duration (filing to last major event)
  dt[, filing_dt := as.Date(substr(filing_date, 1, 10))]
  dt[, definitivo_dt := as.Date(substr(date_definitivo, 1, 10))]
  dt[, transito_dt := as.Date(substr(date_transito, 1, 10))]
  dt[, end_dt := pmin(definitivo_dt, transito_dt, na.rm = TRUE)]
  dt[, case_duration_days := as.integer(end_dt - filing_dt)]

  # Pretrial detention
  dt[, pretrial_detained := as.integer(has_pretrial_detention == TRUE)]
}

## ---- Construct vara leniency instrument ----
if (!is.na(dt$has_procedencia[1])) {
  # Leave-one-out vara conviction rate (full sample, within assignment pool)
  # Z_ijp = (sum of convictions in vara j pool p - convicted_i) / (N_jp - 1)
  dt[, vara_total_conv := sum(convicted, na.rm = TRUE),
     by = .(vara_codigo, comarca_code)]
  dt[, vara_total_n := .N, by = .(vara_codigo, comarca_code)]

  # LOO
  dt[, vara_leniency := (vara_total_conv - convicted) / (vara_total_n - 1)]

  cat("Vara leniency range:",
      round(min(dt$vara_leniency, na.rm = TRUE), 3), "to",
      round(max(dt$vara_leniency, na.rm = TRUE), 3), "\n")
  cat("Vara leniency SD:", round(sd(dt$vara_leniency, na.rm = TRUE), 3), "\n")
}

## ---- Pool × Year FE ----
dt[, pool_year := paste0(comarca_code, "_", filing_year)]

## ---- Save analysis dataset ----
fwrite(dt, "./data/analysis_data.csv")

## ---- Write diagnostics ----
diagnostics <- list(
  n_treated = nrow(dt[convicted == 1]),
  n_pre = 0L,  # Cross-sectional (no pre-periods for IV)
  n_obs = nrow(dt)
)
jsonlite::write_json(diagnostics,
                     "./data/diagnostics.json",
                     auto_unbox = TRUE, pretty = TRUE)

## ---- Summary stats ----
cat("\n--- Analysis Sample Summary ---\n")
cat("Cases:", nrow(dt), "\n")
cat("Unique varas:", uniqueN(dt$vara_codigo), "\n")
cat("Unique comarcas:", uniqueN(dt$comarca_code), "\n")
cat("Pool-year FEs:", uniqueN(dt$pool_year), "\n")
if (!is.na(dt$has_procedencia[1])) {
  cat("Conviction rate:", round(mean(dt$convicted, na.rm = TRUE), 3), "\n")
  cat("Pretrial detention rate:", round(mean(dt$pretrial_detained, na.rm = TRUE), 3), "\n")
  cat("Median case duration:", median(dt$case_duration_days, na.rm = TRUE), "days\n")
}
