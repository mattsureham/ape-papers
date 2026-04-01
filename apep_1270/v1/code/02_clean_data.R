# 02_clean_data.R — Construct canton × year panel from BFS GWS Excel files

source("00_packages.R")
library(readxl)

cat("=== Constructing canton × year panel ===\n")

xlsx_path <- "../data/bfs_wohnungen_heizsystem_kantone.xlsx"

# Canton names in BFS order (rows 8-33 in Excel, after Schweiz total)
canton_codes <- c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
                  "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
                  "TI","VD","VS","NE","GE","JU")

# ─── Parse 2021-2024 sheets ───
parse_modern_sheet <- function(xlsx_path, sheet_name) {
  year <- as.numeric(gsub("\\D", "", sheet_name))
  raw <- read_excel(xlsx_path, sheet = sheet_name, col_names = FALSE)

  # Data rows: 7 = Schweiz (skip), 8-33 = 26 cantons
  # Columns: 2=Total, 3=Wärmepumpe%, 12=Gas%, 13=Heizöl%, 14=Holz%,
  #          15=Elektrizität%, 17=Fernwärme%
  data_rows <- 8:33

  df <- data.frame(
    canton = canton_codes,
    year = year,
    total_dwellings = as.numeric(raw[[2]][data_rows]),
    hp_pct = as.numeric(raw[[3]][data_rows]),     # Wärmepumpe
    boiler_pct = as.numeric(raw[[5]][data_rows]),  # Heizkessel
    stove_pct = as.numeric(raw[[6]][data_rows]),   # Ofen
    elec_heat_pct = as.numeric(raw[[7]][data_rows]), # Elektroheizung
    gas_pct = as.numeric(raw[[12]][data_rows]),    # Gas
    oil_pct = as.numeric(raw[[13]][data_rows]),    # Heizöl
    wood_pct = as.numeric(raw[[14]][data_rows]),   # Holz
    elec_pct = as.numeric(raw[[15]][data_rows]),   # Elektrizität (energy source)
    district_heat_pct = as.numeric(raw[[17]][data_rows]), # Fernwärme
    stringsAsFactors = FALSE
  )
  return(df)
}

# ─── Parse 2000 sheet (different column structure) ───
parse_2000_sheet <- function(xlsx_path) {
  raw <- read_excel(xlsx_path, sheet = "Kantone_2000", col_names = FALSE)

  # 2000 has different heating system categories (Ofen, Zentral, etc.)
  # but the ENERGY SOURCE columns are the key ones
  # Need to check column mapping
  cat("\n2000 sheet column headers:\n")
  for (j in 1:ncol(raw)) {
    val <- as.character(raw[5, j])
    if (!is.na(val)) cat("  Col", j, ":", val, "\n")
  }

  data_rows <- 8:33

  # From the output, 2000 sheet has:
  # Col 2: Total, Col 3-8: Heizsystem (Ofen, Zentralheizung types, Fernwärme, Keine)
  # Col 9+: Energiequelle (need to identify exact columns)

  # Read full row 5 to map columns
  row5 <- as.character(raw[5, ])

  # Find energy source columns
  gas_col <- which(grepl("Gas", row5, ignore.case = TRUE))
  oil_col <- which(grepl("Heizöl", row5, ignore.case = TRUE))
  wood_col <- which(grepl("Holz", row5, ignore.case = TRUE))
  elec_col <- which(grepl("Elektrizität", row5, ignore.case = TRUE))
  fernw_col <- which(grepl("Fernwärme", row5, ignore.case = TRUE))

  cat("\n2000 energy source columns:\n")
  cat("  Gas:", gas_col, "| Oil:", oil_col, "| Wood:", wood_col,
      "| Elec:", elec_col, "| Fernwärme:", fernw_col, "\n")

  # For 2000, heat pump wasn't a separate system category — it was rare
  # Look for Wärmepumpe in row 5
  hp_col <- which(grepl("Wärmepumpe|Wärme", row5, ignore.case = TRUE))
  cat("  Wärmepumpe:", hp_col, "\n")

  df <- data.frame(
    canton = canton_codes,
    year = 2000,
    total_dwellings = as.numeric(raw[[2]][data_rows]),
    hp_pct = NA_real_,  # Will compute if column found
    boiler_pct = NA_real_,
    stove_pct = as.numeric(raw[[3]][data_rows]),  # Ofen in 2000
    elec_heat_pct = NA_real_,
    # 2000 energy source columns: 9=WP, 10=Gas, 11=Heizöl, 12=Kohle, 13=Holz,
    # 14=Elektrizität, 15=Solarthermie, 16=Fernwärme, 17=Andere, 18=Keine
    gas_pct = as.numeric(raw[[10]][data_rows]),
    oil_pct = as.numeric(raw[[11]][data_rows]),
    wood_pct = as.numeric(raw[[13]][data_rows]),
    elec_pct = as.numeric(raw[[14]][data_rows]),
    district_heat_pct = as.numeric(raw[[16]][data_rows]),
    stringsAsFactors = FALSE
  )

  # Col 9 = "Energiequellen für Wärmepumpen" = heat pump energy source share
  df$hp_pct <- as.numeric(raw[[9]][data_rows])

  return(df)
}

# ─── Build panel ───
modern_sheets <- c("Kantone_2021", "Kantone_2022", "Kantone_2023", "Kantone_2024")
panel_modern <- bind_rows(lapply(modern_sheets, function(s) parse_modern_sheet(xlsx_path, s)))

panel_2000 <- parse_2000_sheet(xlsx_path)

panel <- bind_rows(panel_2000, panel_modern)

cat("\nPanel dimensions:", nrow(panel), "rows ×", ncol(panel), "cols\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Cantons:", length(unique(panel$canton)), "\n")

# ─── Merge with CO2 levy schedule ───
levy <- data.frame(
  year = 2000:2024,
  levy_chf_per_ton = c(0, rep(NA, 7), 12, 12, 36, 36, 36, 36, 60, 60, 84, 84, 96, 96, 96, 96, 120, 120, 120)
)
# Keep only years in our panel
levy <- levy %>% filter(year %in% c(2000, 2021, 2022, 2023, 2024))
panel <- panel %>%
  left_join(levy, by = "year")

# ─── Fix 2000 sheet column mapping ───
# For 2000, the energy columns are shifted:
# Col 9=WP energy, 10=Gas, 11=Heizöl, 13=Holz, 14=Elektrizität, 16=Fernwärme
# hp_pct was matched to col 7 (Fernwärme system) and col 9 (WP energy source)
# Need to fix: hp_pct should use col 9 (Energiequellen für Wärmepumpen)
# Oil should use col 11, gas col 10

# ─── Compute baseline oil share from 2000 data ───
baseline <- panel %>%
  filter(year == 2000) %>%
  select(canton, oil_share_2000 = oil_pct) %>%
  mutate(oil_share_2000 = oil_share_2000 / 100)  # Convert to proportion
panel <- panel %>%
  left_join(baseline %>% select(canton, oil_share_2000), by = "canton")

# ─── Construct treatment intensity ───
panel <- panel %>%
  mutate(
    treatment = oil_share_2000 * levy_chf_per_ton,
    # Demeaned for cleaner interpretation
    oil_share_2000_dm = oil_share_2000 - mean(oil_share_2000)
  )

# ─── Summary statistics ───
cat("\n=== Summary statistics ===\n")
cat("\nOil share (%) by year:\n")
panel %>%
  group_by(year) %>%
  summarise(
    mean_oil = mean(oil_pct, na.rm = TRUE),
    sd_oil = sd(oil_pct, na.rm = TRUE),
    mean_hp = mean(hp_pct, na.rm = TRUE),
    mean_gas = mean(gas_pct, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nTreatment intensity range:\n")
cat("  Min:", min(panel$treatment), "| Max:", max(panel$treatment), "\n")
cat("  Oil share 2000: Min:", min(panel$oil_share_2000),
    "Max:", max(panel$oil_share_2000), "\n")

# ─── National trends (for descriptive table) ───
cat("\nNational heating system trends:\n")
national <- read_excel(xlsx_path, sheet = "Kantone_2024", col_names = FALSE)
# Row 7 = Schweiz for 2024
cat("2024 - Oil:", as.numeric(national[[13]][7]), "% | HP:",
    as.numeric(national[[3]][7]), "% | Gas:", as.numeric(national[[12]][7]), "%\n")

# ─── Save panel ───
saveRDS(panel, "../data/panel.rds")
write.csv(panel, "../data/panel.csv", row.names = FALSE)
cat("\nPanel saved:", nrow(panel), "observations\n")

# ─── Validate: no NAs in key variables ───
key_vars <- c("canton", "year", "oil_pct", "levy_chf_per_ton", "oil_share_2000", "treatment")
missing <- panel %>%
  select(all_of(key_vars)) %>%
  summarise(across(everything(), ~sum(is.na(.))))
cat("\nMissing values in key variables:\n")
print(missing)
