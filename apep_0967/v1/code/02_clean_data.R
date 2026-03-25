# 02_clean_data.R — Clean election data and merge with treatment intensity
# apep_0967: CSE Reform and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. PARSE 2012 ELECTION DATA
# ============================================================================
cat("Parsing 2012 election data...\n")
d12 <- read_csv(file.path(data_dir, "presidentielle_2012_T1_communes.csv"),
                show_col_types = FALSE)

# CodeInsee is 5-digit commune code
# Le Pen votes in "LePen" column
elec_2012 <- d12 |>
  transmute(
    code_commune = sprintf("%05d", as.integer(CodeInsee)),
    year = 2012L,
    inscrits = as.numeric(Inscrits),
    exprimes = as.numeric(`Exprimés`),
    votants = as.numeric(Votants),
    lepen_voix = as.numeric(LePen),
    melenchon_voix = as.numeric(`Mélenchon`)
  ) |>
  filter(!is.na(inscrits), inscrits > 0, !is.na(exprimes), exprimes > 0) |>
  mutate(
    lepen_share = lepen_voix / exprimes,
    melenchon_share = melenchon_voix / exprimes,
    turnout = votants / inscrits,
    dep_code = substr(code_commune, 1, 2)
  )

cat("  2012:", nrow(elec_2012), "communes\n")

# ============================================================================
# 2. PARSE 2017 ELECTION DATA (XLS wide format)
# ============================================================================
cat("Parsing 2017 election data...\n")

# Read with headers from row 4
d17 <- read_xls(file.path(data_dir, "presidentielle_2017_T1_communes.xls"),
                skip = 3, col_names = FALSE)

# Columns 1-18: commune info. Then 7 columns per candidate (11 candidates = 77 cols)
# Col 1: Code du département, Col 3: Code de la commune
# Col 5: Inscrits, Col 8: Votants, Col 16: Exprimés
# For each candidate block starting at col 19: N°Panneau, Sexe, Nom, Prénom, Voix, %Voix/Ins, %Voix/Exp

# Find Le Pen's Voix column by searching for "LE PEN" in Nom columns (every 7th starting at col 21)
header_row <- d17[1, ]  # This is the actual header row
nom_cols <- seq(21, ncol(d17), by = 7)  # Nom is the 3rd col in each candidate block (19+2=21, 26+2=28, etc.)

lepen_block_start <- NA
for (nc in nom_cols) {
  if (nc <= ncol(d17) && !is.na(header_row[[nc]])) {
    if (grepl("LE PEN", toupper(header_row[[nc]]))) {
      lepen_block_start <- nc - 2  # Go back to N°Panneau
      break
    }
  }
}

# If not found in row 1, search in data rows
if (is.na(lepen_block_start)) {
  for (nc in nom_cols) {
    if (nc <= ncol(d17)) {
      vals <- d17[2:min(10, nrow(d17)), nc] |> pull()
      if (any(grepl("LE PEN", toupper(vals), fixed = TRUE), na.rm = TRUE)) {
        lepen_block_start <- nc - 2
        break
      }
    }
  }
}

stopifnot(!is.na(lepen_block_start))
lepen_voix_col <- lepen_block_start + 4  # Voix is 5th in block
cat("  Le Pen voix column:", lepen_voix_col, "\n")

# Also find Mélenchon
melenchon_block_start <- NA
for (nc in nom_cols) {
  if (nc <= ncol(d17)) {
    vals <- d17[2:min(10, nrow(d17)), nc] |> pull()
    if (any(grepl("LENCHON", toupper(vals), fixed = TRUE), na.rm = TRUE)) {
      melenchon_block_start <- nc - 2
      break
    }
  }
}

melenchon_voix_col <- if (!is.na(melenchon_block_start)) melenchon_block_start + 4 else NA

elec_2017 <- d17 |>
  slice(-1) |>  # Remove header row (already skipped 3 rows)
  transmute(
    dep = as.character(pull(d17[-1, 1])),
    commune_raw = as.character(pull(d17[-1, 3])),
    code_commune = paste0(sprintf("%02s", dep), sprintf("%03s", commune_raw)),
    year = 2017L,
    inscrits = as.numeric(pull(d17[-1, 5])),
    votants = as.numeric(pull(d17[-1, 8])),
    exprimes = as.numeric(pull(d17[-1, 16])),
    lepen_voix = as.numeric(pull(d17[-1, lepen_voix_col])),
    melenchon_voix = if (!is.na(melenchon_voix_col)) as.numeric(pull(d17[-1, melenchon_voix_col])) else NA_real_
  ) |>
  filter(!is.na(inscrits), inscrits > 0, !is.na(exprimes), exprimes > 0) |>
  mutate(
    # Fix commune codes: pad département to 2 chars, commune to 3 chars
    code_commune = paste0(
      str_pad(str_trim(dep), 2, pad = "0"),
      str_pad(str_trim(commune_raw), 3, pad = "0")
    ),
    lepen_share = lepen_voix / exprimes,
    melenchon_share = melenchon_voix / exprimes,
    turnout = votants / inscrits,
    dep_code = str_pad(str_trim(dep), 2, pad = "0")
  ) |>
  select(-dep, -commune_raw)

cat("  2017:", nrow(elec_2017), "communes\n")

# ============================================================================
# 3. PARSE 2022 ELECTION DATA (long format CSV)
# ============================================================================
cat("Parsing 2022 election data...\n")
d22 <- read_csv(file.path(data_dir, "presidentielle_2022_T1_communes.csv"),
                show_col_types = FALSE)

# Long format: one row per candidate per commune
# Construct code_commune from dep_code (2 chars) + commune_code (3 chars)
# Le Pen: cand_nom == "LE PEN"

# Get commune-level aggregates (same for all candidates in a commune)
commune_info_22 <- d22 |>
  distinct(dep_code, commune_code, .keep_all = TRUE) |>
  transmute(
    code_commune = paste0(
      str_pad(as.character(dep_code), 2, pad = "0"),
      str_pad(as.character(commune_code), 3, pad = "0")
    ),
    inscrits = inscrits_nb,
    exprimes = exprimes_nb,
    votants = votants_nb
  )

lepen_22 <- d22 |>
  filter(toupper(cand_nom) == "LE PEN") |>
  transmute(
    code_commune = paste0(
      str_pad(as.character(dep_code), 2, pad = "0"),
      str_pad(as.character(commune_code), 3, pad = "0")
    ),
    lepen_voix = cand_nb_voix
  )

melenchon_22 <- d22 |>
  filter(grepl("LENCHON", toupper(cand_nom))) |>
  transmute(
    code_commune = paste0(
      str_pad(as.character(dep_code), 2, pad = "0"),
      str_pad(as.character(commune_code), 3, pad = "0")
    ),
    melenchon_voix = cand_nb_voix
  )

elec_2022 <- commune_info_22 |>
  left_join(lepen_22, by = "code_commune") |>
  left_join(melenchon_22, by = "code_commune") |>
  mutate(
    year = 2022L,
    lepen_share = lepen_voix / exprimes,
    melenchon_share = melenchon_voix / exprimes,
    turnout = votants / inscrits,
    dep_code = substr(code_commune, 1, 2)
  ) |>
  filter(!is.na(inscrits), inscrits > 0, !is.na(exprimes), exprimes > 0)

cat("  2022:", nrow(elec_2022), "communes\n")

# ============================================================================
# 4. STACK ELECTION PANELS
# ============================================================================
cat("Stacking election panels...\n")

common_cols <- c("code_commune", "year", "dep_code", "inscrits", "exprimes",
                 "votants", "lepen_voix", "melenchon_voix",
                 "lepen_share", "melenchon_share", "turnout")

elections <- bind_rows(
  elec_2012 |> select(any_of(common_cols)),
  elec_2017 |> select(any_of(common_cols)),
  elec_2022 |> select(any_of(common_cols))
)

cat("  Total election obs:", nrow(elections), "\n")
cat("  Communes per year:\n")
elections |> count(year) |> print()

# ============================================================================
# 5. MERGE WITH TREATMENT INTENSITY
# ============================================================================
cat("Merging with treatment intensity...\n")

treatment <- read_csv(file.path(data_dir, "commune_treatment.csv"),
                      show_col_types = FALSE)

# Keep only communes that appear in all 3 elections (balanced panel)
commune_counts <- elections |>
  group_by(code_commune) |>
  summarise(n_years = n_distinct(year), .groups = "drop") |>
  filter(n_years == 3)

cat("  Communes in all 3 elections:", nrow(commune_counts), "\n")

panel <- elections |>
  inner_join(commune_counts |> select(code_commune), by = "code_commune") |>
  left_join(treatment, by = "code_commune") |>
  mutate(
    post = as.integer(year == 2022),
    # Standardize treatment for easier interpretation
    share_50plus_std = (share_50plus - mean(share_50plus, na.rm = TRUE)) /
      sd(share_50plus, na.rm = TRUE),
    # Create département-level clustering variable
    dep_code = substr(code_commune, 1, 2)
  ) |>
  # Drop overseas territories (dept codes 97x) for cleaner identification
  filter(!grepl("^97", dep_code))

cat("  Final panel (metropolitan France):", nrow(panel), "obs\n")
cat("  Communes:", n_distinct(panel$code_commune), "\n")
cat("  Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")

# ============================================================================
# 6. SUMMARY STATISTICS
# ============================================================================
cat("\n=== Summary Statistics ===\n")
cat("\nLe Pen vote share by year:\n")
panel |>
  group_by(year) |>
  summarise(
    mean_lepen = mean(lepen_share, na.rm = TRUE),
    sd_lepen = sd(lepen_share, na.rm = TRUE),
    median_lepen = median(lepen_share, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

cat("\nTreatment intensity (share_50plus):\n")
panel |>
  filter(year == 2017) |>
  summarise(
    mean = mean(share_50plus, na.rm = TRUE),
    sd = sd(share_50plus, na.rm = TRUE),
    p10 = quantile(share_50plus, 0.10, na.rm = TRUE),
    p50 = quantile(share_50plus, 0.50, na.rm = TRUE),
    p90 = quantile(share_50plus, 0.90, na.rm = TRUE),
    pct_zero = mean(share_50plus == 0 | is.na(share_50plus), na.rm = TRUE)
  ) |>
  print()

cat("\nCorrelation between treatment and 2017 Le Pen share:\n")
pre <- panel |> filter(year == 2017)
cat("  r =", round(cor(pre$share_50plus, pre$lepen_share,
                       use = "complete.obs"), 4), "\n")

# Save panel
write_csv(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nPanel saved to data/analysis_panel.csv\n")
