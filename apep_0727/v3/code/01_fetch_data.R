## 01_fetch_data.R — Load and validate MaStR solar data
## apep_0727 v2: German Solar PV Bunching at 10 kWp Threshold
##
## Data source: Marktstammdatenregister (MaStR) via open-MaStR/Zenodo
## https://zenodo.org/records/14783581
## Snapshot: 2025-02-09 (covers all installations through Feb 2025)

source("00_packages.R")

MASTR_PATH <- "../data/bnetza_mastr_solar_raw.csv"

cat("Loading MaStR solar data...\n")
stopifnot(file.exists(MASTR_PATH))

# Load only required columns for memory efficiency
dt <- fread(MASTR_PATH, select = c(
  "Bruttoleistung",              # Gross capacity (kW)
  "Erzeugungsleistung",          # Generation capacity (kW) — fallback
  "EegInbetriebnahmedatum",      # EEG commissioning date
  "Registrierungsdatum",         # Registration date — fallback
  "AnzahlModule",                # Number of solar modules
  "Lage",                        # Installation type (rooftop, ground-mount, etc.)
  "Bundesland",                  # Federal state
  "Gemeinde",                    # Municipality
  "AnlagenbetreiberMastrNummer", # Operator MaStR ID
  "EinheitBetriebsstatus"        # Operating status
))

cat(sprintf("Raw records loaded: %s\n", format(nrow(dt), big.mark = ",")))

# --- Parse capacity ---
dt[, capacity_kwp := as.numeric(Bruttoleistung)]
dt[is.na(capacity_kwp), capacity_kwp := as.numeric(Erzeugungsleistung)]

# --- Parse date ---
# Prefer EEG commissioning date; fall back to registration date
dt[, date := as.Date(EegInbetriebnahmedatum, format = "%Y-%m-%d")]
dt[is.na(date), date := as.Date(Registrierungsdatum, format = "%Y-%m-%d")]
dt[, year := year(date)]
dt[, month := month(date)]

# --- Parse installation type ---
# Key categories from MaStR Lage field:
# "Bauliche Anlagen (Hausdach, Gebäude und Fassade)" = Rooftop
# "Freifläche" = Ground-mount
# "Steckerfertige Solaranlage (sog. Balkonkraftwerk)" = Balcony/plug-in
# "Bauliche Anlagen (Sonstige)" = Other building-integrated
dt[, install_type := fcase(
  grepl("Hausdach|Fassade", Lage), "rooftop",
  grepl("Freifläche", Lage, ignore.case = TRUE), "ground_mount",
  grepl("Steckerfertig|Balkon", Lage), "balcony",
  grepl("Sonstige", Lage), "other_building",
  default = "unknown"
)]

# --- Parse module count ---
dt[, n_modules := as.integer(AnzahlModule)]

# --- Filter ---
# Keep: valid capacity, valid year, 2008-2025
dt <- dt[!is.na(capacity_kwp) & capacity_kwp > 0]
dt <- dt[!is.na(year) & year >= 2008 & year <= 2025]

cat(sprintf("After basic filtering: %s records\n", format(nrow(dt), big.mark = ",")))

# --- Summary statistics ---
cat("\n=== Data Overview ===\n")
cat(sprintf("Records: %s\n", format(nrow(dt), big.mark = ",")))
cat(sprintf("Years: %d-%d\n", min(dt$year), max(dt$year)))
cat(sprintf("Module count available: %s (%.1f%%)\n",
    format(sum(!is.na(dt$n_modules)), big.mark = ","),
    100 * mean(!is.na(dt$n_modules))))

cat("\nInstallation type:\n")
print(dt[, .N, by = install_type][order(-N)])

cat("\nRecords by period:\n")
cat(sprintf("  2008-2011 (pre-FIT tier):   %s\n", format(dt[year >= 2008 & year <= 2011, .N], big.mark = ",")))
cat(sprintf("  2012-2013 (FIT kink):       %s\n", format(dt[year >= 2012 & year <= 2013, .N], big.mark = ",")))
cat(sprintf("  2014-2020 (surcharge):      %s\n", format(dt[year >= 2014 & year <= 2020, .N], big.mark = ",")))
cat(sprintf("  2021-2025 (post-reform):    %s\n", format(dt[year >= 2021 & year <= 2025, .N], big.mark = ",")))

# --- Save processed dataset ---
# Keep only the columns we need (drop raw German columns)
dt_out <- dt[, .(capacity_kwp, date, year, month, install_type, n_modules,
                 federal_state = Bundesland, municipality = Gemeinde,
                 operator_id = AnlagenbetreiberMastrNummer)]

fwrite(dt_out, "../data/solar_installations.csv")
cat(sprintf("\nSaved %s records to data/solar_installations.csv\n",
    format(nrow(dt_out), big.mark = ",")))

# Save diagnostics
diag <- list(
  data_source = "Marktstammdatenregister (MaStR) via Zenodo (2025-02-09)",
  n_total = nrow(dt_out),
  year_min = min(dt_out$year),
  year_max = max(dt_out$year),
  n_rooftop = dt_out[install_type == "rooftop", .N],
  n_ground_mount = dt_out[install_type == "ground_mount", .N],
  n_balcony = dt_out[install_type == "balcony", .N],
  pct_with_modules = round(100 * mean(!is.na(dt_out$n_modules)), 1)
)
write_json(diag, "../data/raw_summary.json", auto_unbox = TRUE)
cat("Diagnostics saved.\n")
