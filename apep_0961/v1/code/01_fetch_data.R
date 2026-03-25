# 01_fetch_data.R — Load FOPH OKP data and construct treatment panel
# apep_0961: Swiss tobacco billboard bans and healthcare costs

source("00_packages.R")

# ============================================================================
# 1. Load FOPH OKP healthcare cost data
# ============================================================================
cat("Loading FOPH OKP cantonal cost data...\n")

okp_raw <- as.data.table(readxl::read_excel(
  "../data/02_Kostenmonitoring_Zeitreihe-Jahr_Kanton.xlsx"
))

cat("Raw OKP data:", nrow(okp_raw), "rows,", ncol(okp_raw), "columns\n")
cat("Columns:", paste(names(okp_raw), collapse = ", "), "\n")
cat("Years:", sort(unique(okp_raw$Jahr)), "\n")
cat("Cantons:", length(unique(okp_raw$`Kanton_ISO3166-2`)), "\n")
cat("Cost groups:", unique(okp_raw$Kostengruppe), "\n")

# Validate: must have real data
stopifnot(nrow(okp_raw) > 10000)
stopifnot("Bruttoleistungen_pro_Versicherten" %in% names(okp_raw))

# ============================================================================
# 2. Cantonal tobacco billboard ban treatment dates
# ============================================================================
# Source: Stoller (2026, arXiv:2601.08352) Table 3 + cantonal legislation
# 16 cantons adopted billboard bans at staggered dates; 10 never adopted

treatment_dates <- data.table(
  canton_iso = c(
    # Treated cantons (16) — year of billboard ban adoption
    "CH-GE",  # Geneva — 1997
    "CH-VD",  # Vaud — 2002
    "CH-VS",  # Valais — 2004
    "CH-FR",  # Fribourg — 2005
    "CH-NE",  # Neuchâtel — 2005
    "CH-TI",  # Ticino — 2006
    "CH-BS",  # Basel-Stadt — 2007
    "CH-BL",  # Basel-Landschaft — 2007
    "CH-GR",  # Graubünden — 2008
    "CH-JU",  # Jura — 2009
    "CH-SO",  # Solothurn — 2009
    "CH-BE",  # Bern — 2012
    "CH-SG",  # St. Gallen — 2013
    "CH-ZH",  # Zürich — 2013
    "CH-LU",  # Luzern — 2015
    "CH-AG",  # Aargau — 2017
    # Never-treated cantons (10)
    "CH-AI",  # Appenzell Innerrhoden
    "CH-AR",  # Appenzell Ausserrhoden
    "CH-GL",  # Glarus
    "CH-NW",  # Nidwalden
    "CH-OW",  # Obwalden
    "CH-SH",  # Schaffhausen
    "CH-SZ",  # Schwyz
    "CH-TG",  # Thurgau
    "CH-UR",  # Uri
    "CH-ZG"   # Zug
  ),
  ban_year = c(
    1997, 2002, 2004, 2005, 2005, 2006, 2007, 2007,
    2008, 2009, 2009, 2012, 2013, 2013, 2015, 2017,
    # Never-treated: coded as 0 for CS-DiD
    rep(0, 10)
  ),
  canton_name = c(
    "Geneva", "Vaud", "Valais", "Fribourg", "Neuchâtel", "Ticino",
    "Basel-Stadt", "Basel-Landschaft", "Graubünden", "Jura", "Solothurn",
    "Bern", "St. Gallen", "Zürich", "Luzern", "Aargau",
    "Appenzell I.", "Appenzell A.", "Glarus", "Nidwalden", "Obwalden",
    "Schaffhausen", "Schwyz", "Thurgau", "Uri", "Zug"
  )
)

cat("\nTreatment summary:\n")
cat("  Treated cantons:", sum(treatment_dates$ban_year > 0), "\n")
cat("  Never-treated:", sum(treatment_dates$ban_year == 0), "\n")
cat("  Treatment years:", sort(unique(treatment_dates$ban_year[treatment_dates$ban_year > 0])), "\n")

# ============================================================================
# 3. Save intermediate data
# ============================================================================
fwrite(treatment_dates, "../data/treatment_dates.csv")
saveRDS(okp_raw, "../data/okp_raw.rds")

cat("\nData saved. Ready for cleaning.\n")
