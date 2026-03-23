## 02_clean_data.R — Construct analysis panel for apep_0809
## Merge: posted worker exposure (Bartik) + elections + controls at département level
source("00_packages.R")
if (basename(getwd()) == "code") setwd("..")

data_dir <- "data"

# ============================================================================
# 1. PARSE ELECTION DATA — Extract FN/RN vote share by département × year
# ============================================================================
cat("=== Parsing election data ===\n")

elections_raw <- readRDS(file.path(data_dir, "elections_raw.rds"))

# FN/RN candidate names by election year:
# 1995: Le Pen (Jean-Marie)
# 2002: Le Pen (Jean-Marie)
# 2007: Le Pen (Jean-Marie)
# 2012: Le Pen (Marine)
# 2017: Le Pen (Marine) — column in XLS format
# 2022: Le Pen (Marine) — column in XLSX format

parse_election <- function(df, year) {
  cols <- names(df)

  if (year == 2017) {
    # 2017 XLS: wide format with 6 cols per candidate
    # Header at row 3 (0-indexed from read_excel with col_names), data rows after
    # Le Pen Nom at col 18, % Voix/Exp at col 22, Dept code at col 1
    # Re-read with skip to get proper data
    d <- readxl::read_excel("data/pres_2017.xls",
                            sheet = "Départements Tour 1",
                            col_names = FALSE, skip = 4)
    result <- tibble(
      dept_raw = as.character(d[[1]]),
      fn_vote_share = as.numeric(as.character(d[[22]])),
      year = 2017
    ) |>
      filter(!is.na(fn_vote_share), fn_vote_share > 0, fn_vote_share < 100)
    cat(sprintf("  2017: %d obs, FN mean = %.1f%%\n", nrow(result),
                mean(result$fn_vote_share)))
    return(result)
  }

  if (year == 2022) {
    # 2022 XLSX: has Le Pen_EXP (% expressed votes), DEP_CODE
    lepen_exp_col <- cols[grepl("Le.?Pen.*EXP", cols)][1]
    dept_col <- cols[grepl("(?i)dep.*code", cols)][1]
    if (is.na(dept_col)) dept_col <- cols[grepl("(?i)dep.*nom", cols)][1]
    if (is.na(dept_col)) dept_col <- cols[1]

    result <- tibble(
      dept_raw = as.character(df[[dept_col]]),
      fn_vote_share = as.numeric(df[[lepen_exp_col]]),
      year = 2022
    ) |>
      filter(!is.na(fn_vote_share))
    cat(sprintf("  2022: %d obs, FN mean = %.1f%%\n", nrow(result),
                mean(result$fn_vote_share)))
    return(result)
  }

  # 1995, 2002, 2007, 2012: semicolon-delimited CSVs with Département;...;Le Pen;...
  dept_col <- cols[grepl("(?i)d.part", cols)][1]
  if (is.na(dept_col)) dept_col <- cols[1]
  lepen_col <- cols[grepl("(?i)le.?pen", cols)][1]

  if (is.na(lepen_col)) {
    cat(sprintf("    WARNING: No Le Pen column in %d\n", year))
    return(NULL)
  }

  result <- tibble(
    dept_raw = as.character(df[[dept_col]]),
    fn_vote_share = as.numeric(gsub(",", ".", as.character(df[[lepen_col]]))),
    year = year
  ) |>
    filter(!is.na(fn_vote_share))

  cat(sprintf("  %d: %d obs, FN mean = %.1f%%\n", year, nrow(result),
              mean(result$fn_vote_share)))
  result
}

elections_parsed <- bind_rows(lapply(names(elections_raw), function(yr) {
  parse_election(elections_raw[[yr]], as.integer(yr))
}))

cat(sprintf("  Total election obs: %d\n", nrow(elections_parsed)))

# Clean département names/codes to get a standard département code (01-95, 2A, 2B)
# The CSV files use département names, the XLSX files may use codes
elections_parsed <- elections_parsed |>
  mutate(
    dept_raw = as.character(dept_raw),
    # Remove leading/trailing whitespace
    dept_raw = trimws(dept_raw)
  )

# Create a département name → code crosswalk
dept_crosswalk <- tibble(
  dept_name = c(
    "Ain", "Aisne", "Allier", "Alpes-de-Haute-Provence", "Hautes-Alpes",
    "Alpes-Maritimes", "Ardèche", "Ardennes", "Ariège", "Aube",
    "Aude", "Aveyron", "Bouches-du-Rhône", "Calvados", "Cantal",
    "Charente", "Charente-Maritime", "Cher", "Corrèze", "Corse-du-Sud",
    "Haute-Corse", "Côte-d'Or", "Côtes-d'Armor", "Creuse", "Dordogne",
    "Doubs", "Drôme", "Eure", "Eure-et-Loir", "Finistère",
    "Gard", "Haute-Garonne", "Gers", "Gironde", "Hérault",
    "Ille-et-Vilaine", "Indre", "Indre-et-Loire", "Isère", "Jura",
    "Landes", "Loir-et-Cher", "Loire", "Haute-Loire", "Loire-Atlantique",
    "Loiret", "Lot", "Lot-et-Garonne", "Lozère", "Maine-et-Loire",
    "Manche", "Marne", "Haute-Marne", "Mayenne", "Meurthe-et-Moselle",
    "Meuse", "Morbihan", "Moselle", "Nièvre", "Nord",
    "Oise", "Orne", "Pas-de-Calais", "Puy-de-Dôme", "Pyrénées-Atlantiques",
    "Hautes-Pyrénées", "Pyrénées-Orientales", "Bas-Rhin", "Haut-Rhin", "Rhône",
    "Haute-Saône", "Saône-et-Loire", "Sarthe", "Savoie", "Haute-Savoie",
    "Paris", "Seine-Maritime", "Seine-et-Marne", "Yvelines", "Deux-Sèvres",
    "Somme", "Tarn", "Tarn-et-Garonne", "Var", "Vaucluse",
    "Vendée", "Vienne", "Haute-Vienne", "Vosges", "Yonne",
    "Territoire de Belfort", "Essonne", "Hauts-de-Seine", "Seine-Saint-Denis",
    "Val-de-Marne", "Val-d'Oise"
  ),
  dept_code = c(
    "01", "02", "03", "04", "05", "06", "07", "08", "09", "10",
    "11", "12", "13", "14", "15", "16", "17", "18", "19", "2A",
    "2B", "21", "22", "23", "24", "25", "26", "27", "28", "29",
    "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
    "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
    "50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
    "60", "61", "62", "63", "64", "65", "66", "67", "68", "69",
    "70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
    "80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
    "90", "91", "92", "93", "94", "95"
  )
)

# Try to match — first check if dept_raw looks like a code (2-digit number or 2A/2B)
elections_parsed <- elections_parsed |>
  mutate(
    is_code = grepl("^[0-9]{1,3}[AB]?$", dept_raw),
    dept_code = case_when(
      is_code & nchar(dept_raw) == 1 ~ paste0("0", dept_raw),
      is_code ~ dept_raw,
      TRUE ~ NA_character_
    )
  )

# For name-based entries, match to crosswalk (fuzzy matching for accent issues)
name_rows <- which(is.na(elections_parsed$dept_code))
if (length(name_rows) > 0) {
  # Normalize accents for matching
  normalize_fr <- function(x) {
    x <- tolower(x)
    x <- gsub("[éèêë]", "e", x)
    x <- gsub("[àâä]", "a", x)
    x <- gsub("[ùûü]", "u", x)
    x <- gsub("[ôö]", "o", x)
    x <- gsub("[îï]", "i", x)
    x <- gsub("[ç]", "c", x)
    x <- gsub("[-' ]", "", x)
    x
  }

  dept_crosswalk$norm <- normalize_fr(dept_crosswalk$dept_name)

  for (i in name_rows) {
    raw_norm <- normalize_fr(elections_parsed$dept_raw[i])
    match_idx <- which(dept_crosswalk$norm == raw_norm)
    if (length(match_idx) == 1) {
      elections_parsed$dept_code[i] <- dept_crosswalk$dept_code[match_idx]
    } else {
      # Try partial match
      match_idx <- which(startsWith(dept_crosswalk$norm, substr(raw_norm, 1, 6)))
      if (length(match_idx) == 1) {
        elections_parsed$dept_code[i] <- dept_crosswalk$dept_code[match_idx]
      }
    }
  }
}

# Filter to metropolitan France (01-95, 2A, 2B)
elections_clean <- elections_parsed |>
  filter(!is.na(dept_code)) |>
  filter(dept_code %in% dept_crosswalk$dept_code) |>
  select(dept_code, year, fn_vote_share, any_of("participation"))

cat(sprintf("  Matched elections: %d obs across %d départements × %d years\n",
            nrow(elections_clean), n_distinct(elections_clean$dept_code),
            n_distinct(elections_clean$year)))

# ============================================================================
# 2. CONSTRUCT BARTIK SHARES — Pre-enlargement sectoral employment
# ============================================================================
cat("\n=== Constructing Bartik shares ===\n")

emp_data <- readRDS(file.path(data_dir, "eurostat_employment.rds"))

# NUTS2→département mapping
# Each NUTS2 region contains multiple départements
# We need to map NUTS2 regions to départements
# Use 2016+ NUTS2 codes (post-merger, no duplicates)
nuts2_to_dept <- tribble(
  ~nuts2, ~dept_codes,
  "FR10", list(c("75", "77", "78", "91", "92", "93", "94", "95")),  # Île-de-France
  "FRB0", list(c("18", "28", "36", "37", "41", "45")),  # Centre-Val de Loire
  "FRC1", list(c("21", "58", "71", "89")),  # Bourgogne
  "FRC2", list(c("25", "39", "70", "90")),  # Franche-Comté
  "FRD1", list(c("14", "50", "61")),  # Basse-Normandie
  "FRD2", list(c("27", "76")),  # Haute-Normandie
  "FRE1", list(c("59", "62")),  # Nord-Pas-de-Calais
  "FRE2", list(c("02", "60", "80")),  # Picardie
  "FRF1", list(c("67", "68")),  # Alsace
  "FRF2", list(c("54", "55", "57", "88")),  # Lorraine
  "FRF3", list(c("08", "10", "51", "52")),  # Champagne-Ardenne
  "FRG0", list(c("44", "49", "53", "72", "85")),  # Pays de la Loire
  "FRH0", list(c("22", "29", "35", "56")),  # Bretagne
  "FRI1", list(c("16", "17", "79", "86")),  # Poitou-Charentes
  "FRI2", list(c("19", "23", "87")),  # Limousin
  "FRI3", list(c("24", "33", "40", "47", "64")),  # Aquitaine
  "FRJ1", list(c("09", "12", "31", "32", "46", "65", "81", "82")),  # Midi-Pyrénées
  "FRJ2", list(c("11", "30", "34", "48", "66")),  # Languedoc-Roussillon
  "FRK1", list(c("01", "03", "07", "15", "26", "38", "42", "43", "63", "69", "73", "74")),  # Auvergne-Rhône-Alpes
  "FRL0", list(c("04", "05", "06", "13", "83", "84")),  # PACA
  "FRM0", list(c("2A", "2B"))  # Corse
)

# Compute NUTS2-level sector shares (average 2000-2003)
sector_shares_nuts2 <- emp_data |>
  filter(
    nace_r2 != "TOTAL",
    as.numeric(as.character(TIME_PERIOD)) <= 2003
  ) |>
  mutate(year = as.numeric(as.character(TIME_PERIOD))) |>
  group_by(geo, nace_r2) |>
  summarise(emp = mean(values, na.rm = TRUE), .groups = "drop")

total_emp_nuts2 <- emp_data |>
  filter(
    nace_r2 == "TOTAL",
    as.numeric(as.character(TIME_PERIOD)) <= 2003
  ) |>
  mutate(year = as.numeric(as.character(TIME_PERIOD))) |>
  group_by(geo) |>
  summarise(total_emp = mean(values, na.rm = TRUE), .groups = "drop")

sector_shares_nuts2 <- sector_shares_nuts2 |>
  left_join(total_emp_nuts2, by = "geo") |>
  mutate(share = emp / total_emp)

cat("  NUTS2 sector shares computed (2000-2003 avg):\n")
sector_shares_nuts2 |>
  group_by(nace_r2) |>
  summarise(mean_share = mean(share, na.rm = TRUE)) |>
  print()

# Map NUTS2 shares to départements
# Each département inherits its NUTS2 region's sector shares
dept_shares <- nuts2_to_dept |>
  unnest(dept_codes) |>
  unnest(dept_codes) |>
  rename(dept_code = dept_codes) |>
  left_join(
    sector_shares_nuts2 |> select(geo, nace_r2, share),
    by = c("nuts2" = "geo")
  ) |>
  # Some départements appear in multiple NUTS2 entries (due to region mergers)
  # Keep the first match
  group_by(dept_code, nace_r2) |>
  slice(1) |>
  ungroup()

# Pivot to wide: one row per département with construction/agriculture/industry shares
dept_shares_wide <- dept_shares |>
  select(dept_code, nace_r2, share) |>
  pivot_wider(names_from = nace_r2, values_from = share, names_prefix = "share_") |>
  rename_with(~ case_when(
    . == "share_F" ~ "share_construction",
    . == "share_A" ~ "share_agriculture",
    . == "share_C" ~ "share_manufacturing",
    . == "share_B-E" ~ "share_industry",
    TRUE ~ .
  ))

cat(sprintf("  Département shares: %d départements\n", nrow(dept_shares_wide)))

# ============================================================================
# 3. CONSTRUCT BARTIK INSTRUMENT
# ============================================================================
cat("\n=== Constructing Bartik instrument ===\n")

posted_workers <- readRDS(file.path(data_dir, "posted_workers_national.rds"))

# Bartik predicted exposure for each département × year:
# Z_{d,t} = share_construction_{d,2000} × ΔPW_construction_{national,t}
#          + share_agriculture_{d,2000} × ΔPW_agriculture_{national,t}
#          + share_industry_{d,2000} × ΔPW_industry_{national,t}

# Compute national posted worker changes relative to 2003 (pre-A8 baseline)
pw_2003 <- posted_workers |> filter(year == 2003)
posted_workers <- posted_workers |>
  mutate(
    delta_pw_construction = pw_construction - pw_2003$pw_construction,
    delta_pw_agriculture  = pw_agriculture - pw_2003$pw_agriculture,
    delta_pw_industry     = pw_industry - pw_2003$pw_industry,
    delta_pw_services     = pw_services - pw_2003$pw_services,
    delta_pw_total        = total_pw - pw_2003$total_pw
  )

# Map election years to the closest posted worker year
election_year_map <- tibble(
  year = c(1995, 2002, 2007, 2012, 2017, 2022),
  pw_year = c(2000, 2002, 2007, 2012, 2017, 2022)
)

# Create panel: département × election year
panel <- expand_grid(
  dept_code = dept_crosswalk$dept_code,
  year = c(1995, 2002, 2007, 2012, 2017, 2022)
) |>
  left_join(dept_shares_wide, by = "dept_code") |>
  left_join(election_year_map, by = "year") |>
  left_join(
    posted_workers |> select(year, starts_with("delta_pw_")),
    by = c("pw_year" = "year")
  )

# Compute Bartik instrument
panel <- panel |>
  mutate(
    bartik_exposure = share_construction * delta_pw_construction +
                      share_agriculture * delta_pw_agriculture +
                      coalesce(share_manufacturing, share_industry, 0) * delta_pw_industry,
    # Also construct total exposure (simpler version)
    total_pw_exposure = delta_pw_total * (
      coalesce(share_construction, 0) + coalesce(share_agriculture, 0) +
      coalesce(share_manufacturing, share_industry, 0)
    )
  )

cat("  Bartik instrument summary:\n")
panel |>
  group_by(year) |>
  summarise(
    mean_exposure = mean(bartik_exposure, na.rm = TRUE),
    sd_exposure = sd(bartik_exposure, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# ============================================================================
# 4. MERGE WITH ELECTION DATA
# ============================================================================
cat("\n=== Merging panel ===\n")

panel <- panel |>
  left_join(elections_clean, by = c("dept_code", "year"))

cat(sprintf("  Panel before merge: %d obs\n", nrow(panel)))
cat(sprintf("  With FN vote data: %d obs\n", sum(!is.na(panel$fn_vote_share))))

# ============================================================================
# 5. ADD CONTROLS
# ============================================================================
cat("\n=== Adding controls ===\n")

# China import shock × manufacturing share
china_imports <- readRDS(file.path(data_dir, "china_imports.rds"))
panel <- panel |>
  left_join(
    china_imports |> rename(pw_year = year),
    by = "pw_year"
  ) |>
  mutate(
    china_shock = china_import_pct_gdp * coalesce(share_manufacturing, share_industry, 0)
  )

# Unemployment (NUTS2 level → département via crosswalk)
if (file.exists(file.path(data_dir, "eurostat_unemployment.rds"))) {
  unemp <- readRDS(file.path(data_dir, "eurostat_unemployment.rds"))

  # Get total unemployment rate (all ages, both sexes)
  unemp_clean <- unemp |>
    filter(
      age == "Y15-74",
      sex == "T",
      unit == "PC"
    ) |>
    mutate(year = as.numeric(as.character(TIME_PERIOD))) |>
    group_by(geo, year) |>
    summarise(unemp_rate = mean(values, na.rm = TRUE), .groups = "drop") |>
    rename(nuts2 = geo)

  # Map to election years (use closest available year)
  nuts2_dept_map <- nuts2_to_dept |>
    unnest(dept_codes) |>
    unnest(dept_codes) |>
    rename(dept_code = dept_codes) |>
    group_by(dept_code) |>
    slice(1) |>
    ungroup()

  panel <- panel |>
    left_join(nuts2_dept_map |> select(dept_code, nuts2), by = "dept_code",
              relationship = "many-to-one") |>
    left_join(unemp_clean, by = c("nuts2", "pw_year" = "year"),
              relationship = "many-to-one")

  cat(sprintf("  Unemployment merged: %d non-missing\n", sum(!is.na(panel$unemp_rate))))
}

# ============================================================================
# 6. FINAL PANEL
# ============================================================================
cat("\n=== Final panel ===\n")

# Keep metropolitan France with complete data
analysis_panel <- panel |>
  filter(
    !is.na(fn_vote_share),
    !is.na(bartik_exposure),
    dept_code %in% dept_crosswalk$dept_code
  )

cat(sprintf("  Analysis panel: %d obs (%d départements × %d elections)\n",
            nrow(analysis_panel),
            n_distinct(analysis_panel$dept_code),
            n_distinct(analysis_panel$year)))

# Post-enlargement indicator
analysis_panel <- analysis_panel |>
  mutate(
    post_2004 = as.integer(year >= 2007),
    post_2007 = as.integer(year >= 2012),
    period = case_when(
      year <= 2002 ~ "Pre-enlargement",
      year <= 2007 ~ "Post-A8",
      TRUE ~ "Post-A8+A2"
    )
  )

cat("  FN vote share by period:\n")
analysis_panel |>
  group_by(period) |>
  summarise(
    mean_fn = mean(fn_vote_share, na.rm = TRUE),
    sd_fn = sd(fn_vote_share, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) |>
  print()

saveRDS(analysis_panel, file.path(data_dir, "analysis_panel.rds"))
cat("  Panel saved to data/analysis_panel.rds\n")
