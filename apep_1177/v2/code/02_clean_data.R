## 02_clean_data.R — Clean and construct analysis dataset (3 offenses)
## apep_1177 v2: The Conviction Lottery

source("./code/00_packages.R")

## ---- Load all three offense datasets ----
offenses <- c("trafficking", "robbery", "theft")
dfs <- list()

for (off in offenses) {
  path <- paste0("./data/central_", off, ".parquet")
  if (!file.exists(path)) {
    cat("WARNING:", path, "not found\n")
    next
  }
  tmp <- as.data.table(read_parquet(path))
  cat("Loaded", nrow(tmp), off, "cases\n")
  dfs[[off]] <- tmp
}

dt <- rbindlist(dfs, fill = TRUE)
cat("\nCombined dataset:", nrow(dt), "cases across", length(dfs), "offenses\n")

## ---- Parse dates ----
dt[, filing_year := as.integer(substr(filing_date, 1, 4))]
dt[, filing_month := as.integer(substr(filing_date, 6, 7))]
dt[, filing_dow := wday(as.Date(filing_date))]  # day of week for balance

## ---- Assign comarcas ----
central_varas <- c(10522, 10525, 10523, 10521, 10533, 10512, 10527, 10529,
                   10517, 10509, 10531, 10515, 10536, 10532, 10508, 10513,
                   10524, 10514, 10803, 10537, 10534, 10528, 10526, 10520,
                   10535, 10530, 10519, 59222, 10511, 10510, 10518)
campinas_varas <- c(9615, 9464, 10112, 9670, 9671, 13675)
ribeirao_varas <- c(10130, 9736, 16271, 9923)

dt[, comarca := fifelse(vara_codigo %in% central_varas, "CENTRAL",
                fifelse(vara_codigo %in% campinas_varas, "CAMPINAS",
                fifelse(vara_codigo %in% ribeirao_varas, "RIBEIRAO_PRETO",
                        "OTHER")))]

cat("\nCases by comarca:\n")
print(dt[, .N, by = comarca])

## ---- Outcome variables ----
dt[, convicted := as.integer(convicted == TRUE)]
dt[, pretrial_detained := as.integer(pretrial_detained == TRUE)]
dt[, acquitted := as.integer(acquitted == TRUE)]

# Case duration
dt[, filing_dt := as.Date(substr(filing_date, 1, 10))]
dt[, resolved_dt := as.Date(substr(date_resolved, 1, 10))]
dt[, case_duration_days := as.integer(resolved_dt - filing_dt)]

## ---- Construct vara leniency instrument (by offense type) ----
# LOO leniency: within offense type and comarca
dt[, vara_total_conv := sum(convicted, na.rm = TRUE),
   by = .(vara_codigo, comarca, offense_type)]
dt[, vara_total_n := .N,
   by = .(vara_codigo, comarca, offense_type)]

# LOO: exclude own case
dt[, vara_leniency := (vara_total_conv - convicted) / (vara_total_n - 1)]
# Drop if only 1 case in vara-offense cell
dt[vara_total_n <= 1, vara_leniency := NA]

cat("\nVara leniency by offense:\n")
for (off in offenses) {
  sub <- dt[offense_type == off & !is.na(vara_leniency)]
  cat("  ", off, ": mean =", round(mean(sub$vara_leniency), 3),
      ", SD =", round(sd(sub$vara_leniency), 3),
      ", N =", nrow(sub), "\n")
}

## ---- Pool × Year FE ----
dt[, pool_year := paste0(comarca, "_", filing_year)]

## ---- Overlap matrix: varas × offenses ----
overlap <- dt[, .(n_cases = .N, conv_rate = mean(convicted, na.rm = TRUE)),
              by = .(vara_codigo, comarca, offense_type)]

# Common varas: those that handle all three offenses
vara_offense_count <- overlap[, .(n_offenses = uniqueN(offense_type)),
                              by = vara_codigo]
common_varas <- vara_offense_count[n_offenses == 3, vara_codigo]
cat("\nCommon varas (all 3 offenses):", length(common_varas),
    "out of", uniqueN(dt$vara_codigo), "\n")

# Flag common varas
dt[, is_common_vara := vara_codigo %in% common_varas]

## ---- Vara-level stats by offense ----
vara_stats <- dt[is_common_vara == TRUE,
                 .(n_cases = .N,
                   conv_rate = mean(convicted, na.rm = TRUE),
                   pretrial_rate = mean(pretrial_detained, na.rm = TRUE)),
                 by = .(vara_codigo, comarca, offense_type)]

cat("\nVara-level conviction rate distribution (common varas, min 20 cases):\n")
for (off in offenses) {
  sub <- vara_stats[offense_type == off & n_cases >= 20]
  if (nrow(sub) > 0) {
    cat("  ", off, ":\n")
    cat("    N varas:", nrow(sub), "\n")
    cat("    Mean:", round(mean(sub$conv_rate), 3), "\n")
    cat("    SD:", round(sd(sub$conv_rate), 3), "\n")
    cat("    P10:", round(quantile(sub$conv_rate, 0.10), 3), "\n")
    cat("    P90:", round(quantile(sub$conv_rate, 0.90), 3), "\n")
    cat("    P90-P10:", round(quantile(sub$conv_rate, 0.90) -
                             quantile(sub$conv_rate, 0.10), 3), "\n")
  }
}

## ---- Save ----
fwrite(dt, "./data/analysis_data_v2.csv")
fwrite(vara_stats, "./data/vara_stats_v2.csv")
fwrite(overlap, "./data/overlap_matrix.csv")

# Write diagnostics
diag <- list(
  n_total = nrow(dt),
  n_trafficking = nrow(dt[offense_type == "trafficking"]),
  n_robbery = nrow(dt[offense_type == "robbery"]),
  n_theft = nrow(dt[offense_type == "theft"]),
  n_common_varas = length(common_varas),
  n_varas_total = uniqueN(dt$vara_codigo),
  comarcas = unique(dt$comarca)
)
write_json(diag, "./data/diagnostics_v2.json",
           auto_unbox = TRUE, pretty = TRUE)

cat("\n--- Analysis data saved ---\n")
cat("Total cases:", nrow(dt), "\n")
cat("Common varas:", length(common_varas), "\n")
