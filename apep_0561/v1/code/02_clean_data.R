## 02_clean_data.R — Clean ZRR classification and election data, build analysis panel
## apep_0561: ZRR reclassification and RN voting

source("00_packages.R")

data_dir <- "../data"

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(readxl)

# ============================================================
# 1) Read ZRR Historical Classification
# ============================================================
cat("=== Reading ZRR historical classification ===\n")

# Historical file has sheets for each reform year: 2018, 2017, 2014, ...
# Sheet "2018" = post-reform (arrêté 22 feb 2018, modifying 16 mars 2017)
# Sheet "2014" or earlier = pre-reform classification
sheets <- excel_sheets(file.path(data_dir, "zrr_historique.xls"))
cat("Historical ZRR sheets:", paste(sheets, collapse = ", "), "\n")

# Read post-reform sheet (2018 = latest classification after reform)
zrr_post <- read_excel(file.path(data_dir, "zrr_historique.xls"),
                        sheet = "2018", skip = 4)
cat("Post-reform (2018 sheet):", nrow(zrr_post), "rows,", ncol(zrr_post), "cols\n")
cat("Columns:", paste(names(zrr_post), collapse = ", "), "\n")
cat("First rows:\n")
print(head(zrr_post, 5))

# Read pre-reform sheet (2014 = last classification before reform)
zrr_pre <- read_excel(file.path(data_dir, "zrr_historique.xls"),
                       sheet = "2014", skip = 4)
cat("\nPre-reform (2014 sheet):", nrow(zrr_pre), "rows,", ncol(zrr_pre), "cols\n")
cat("Columns:", paste(names(zrr_pre), collapse = ", "), "\n")
cat("First rows:\n")
print(head(zrr_pre, 5))

# Also read 2017 sheet (may represent the transition)
zrr_2017 <- read_excel(file.path(data_dir, "zrr_historique.xls"),
                        sheet = "2017", skip = 4)
cat("\n2017 sheet:", nrow(zrr_2017), "rows,", ncol(zrr_2017), "cols\n")
cat("Columns:", paste(names(zrr_2017), collapse = ", "), "\n")

# ============================================================
# 2) Also read current classification (COG 2021)
# ============================================================
cat("\n=== Reading current ZRR classification (COG 2021) ===\n")

sheets_curr <- excel_sheets(file.path(data_dir, "zrr_cog2021.xls"))
cat("Current ZRR sheets:", paste(sheets_curr, collapse = ", "), "\n")

# Read the main classification sheet
zrr_curr <- read_excel(file.path(data_dir, "zrr_cog2021.xls"),
                        sheet = "Classement ZRR (COG 2021)", skip = 4)
cat("Current (COG 2021):", nrow(zrr_curr), "rows,", ncol(zrr_curr), "cols\n")
cat("Columns:", paste(names(zrr_curr), collapse = ", "), "\n")
cat("First rows:\n")
print(head(zrr_curr, 5))

# Also read COG 2017 sheet if available
zrr_cog2017 <- read_excel(file.path(data_dir, "zrr_cog2021.xls"),
                           sheet = "Classement ZRR (COG 2017)", skip = 4)
cat("\nCOG 2017 sheet:", nrow(zrr_cog2017), "rows,", ncol(zrr_cog2017), "cols\n")
cat("Columns:", paste(names(zrr_cog2017), collapse = ", "), "\n")

# Print unique ZRR status values
for (df_name in c("zrr_post", "zrr_pre", "zrr_2017", "zrr_curr", "zrr_cog2017")) {
  df <- get(df_name)
  zrr_col <- names(df)[grep("zrr|class|zonage", tolower(names(df)))]
  if (length(zrr_col) > 0) {
    for (col in zrr_col) {
      cat("\n", df_name, "$", col, ": ",
          paste(unique(df[[col]]), collapse = ", "), "\n")
    }
  }
}

# ============================================================
# 3) Build ZRR Treatment Groups
# ============================================================
cat("\n=== Building ZRR treatment groups ===\n")

# Standardize commune code column name
standardize_zrr <- function(df) {
  names(df) <- trimws(names(df))
  # Find commune code column
  code_col <- names(df)[grep("codgeo|code.*geo|code_insee|code.insee",
                              tolower(names(df)))][1]
  if (is.na(code_col)) code_col <- names(df)[1]  # fallback to first column

  # Find ZRR status column
  zrr_col <- names(df)[grep("zrr|class|zonage", tolower(names(df)))][1]

  # Find commune name column
  lib_col <- names(df)[grep("libgeo|lib.*geo|nom|libelle",
                             tolower(names(df)))][1]

  data.table(
    codgeo = as.character(df[[code_col]]),
    libgeo = if (!is.na(lib_col)) as.character(df[[lib_col]]) else NA_character_,
    zrr_status = as.character(df[[zrr_col]])
  )
}

dt_pre <- standardize_zrr(zrr_pre)
dt_post <- standardize_zrr(zrr_post)
dt_cog2017 <- standardize_zrr(zrr_cog2017)

cat("Pre-reform communes:", nrow(dt_pre), "\n")
cat("Post-reform communes:", nrow(dt_post), "\n")
cat("COG 2017 communes:", nrow(dt_cog2017), "\n")

cat("\nPre-reform ZRR statuses:", paste(unique(dt_pre$zrr_status), collapse = ", "), "\n")
cat("Post-reform ZRR statuses:", paste(unique(dt_post$zrr_status), collapse = ", "), "\n")
cat("COG 2017 ZRR statuses:", paste(unique(dt_cog2017$zrr_status), collapse = ", "), "\n")

# Remove header rows and NA commune codes
dt_pre <- dt_pre[!is.na(codgeo) & codgeo != "" & !grepl("^CODGEO$", codgeo)]
dt_post <- dt_post[!is.na(codgeo) & codgeo != "" & !grepl("^CODGEO$", codgeo)]
dt_cog2017 <- dt_cog2017[!is.na(codgeo) & codgeo != "" & !grepl("^CODGEO$", codgeo)]

# Also remove header from zrr_status
dt_pre <- dt_pre[!grepl("^ZRR_", zrr_status)]
dt_post <- dt_post[!grepl("^ZRR_", zrr_status)]
dt_cog2017 <- dt_cog2017[!grepl("^ZRR_", zrr_status)]

# Pad commune codes to 5 characters (preserve Corsica 2A/2B)
dt_pre[, codgeo := str_pad(codgeo, 5, pad = "0")]
dt_post[, codgeo := str_pad(codgeo, 5, pad = "0")]
dt_cog2017[, codgeo := str_pad(codgeo, 5, pad = "0")]

# Determine ZRR = TRUE/FALSE for each period
# ZRR status might be coded as "1"/"0", "oui"/"non", "classée"/"non classée", etc.
# Let's detect
cat("\nDetecting ZRR coding...\n")

detect_zrr <- function(status_vec) {
  # ZRR status codes from official data:
  # "C - Classée" = in ZRR
  # "D - Classée en ZRR au titre de la baisse de population" = in ZRR
  # "P - Partiellement classée en ZRR" = in ZRR (partially)
  # "NC - Non classée" / "NC - Commune non classée" = NOT in ZRR
  # "M - Sortante en 2017..." = LEFT ZRR (transition)
  # "A - Sortante en 2017..." = LEFT ZRR (transition)
  # Header rows like "ZRR_2018" should be excluded

  status_clean <- toupper(trimws(status_vec))
  unique_vals <- unique(status_clean)
  cat("  Unique values:", paste(unique_vals, collapse = " | "), "\n")

  # Match on the leading code letter BEFORE the dash
  # C, D, P = in ZRR; NC, M, A = not in ZRR
  is_zrr <- grepl("^C\\s*-|^D\\s*-|^P\\s*-", status_clean) &
            !grepl("^NC\\s*-", status_clean)

  # Exclude header rows
  is_zrr[grepl("^ZRR_|^CODGEO|^LIBGEO", status_clean)] <- NA

  cat("  ZRR count:", sum(is_zrr, na.rm = TRUE), "/", sum(!is.na(is_zrr)), "\n")
  return(is_zrr)
}

cat("Pre-reform:\n")
dt_pre[, is_zrr_pre := detect_zrr(zrr_status)]
cat("Post-reform:\n")
dt_post[, is_zrr_post := detect_zrr(zrr_status)]

cat("\nPre-reform: ", sum(dt_pre$is_zrr_pre, na.rm = TRUE), "communes in ZRR\n")
cat("Post-reform:", sum(dt_post$is_zrr_post, na.rm = TRUE), "communes in ZRR\n")

# Merge pre and post to classify
# Use COG 2017 version if available (better commune code consistency)
# First try: use the post-reform file which should have same COG as pre-reform (both in historical file)

zrr_merged <- merge(
  dt_pre[, .(codgeo, is_zrr_pre)],
  dt_post[, .(codgeo, is_zrr_post)],
  by = "codgeo", all = TRUE
)

# Fill NAs: if a commune doesn't appear, it's not in ZRR for that period
zrr_merged[is.na(is_zrr_pre), is_zrr_pre := FALSE]
zrr_merged[is.na(is_zrr_post), is_zrr_post := FALSE]

# Classify
zrr_merged[, treatment_group := fcase(
  is_zrr_pre & !is_zrr_post, "loser",
  !is_zrr_pre & is_zrr_post, "gainer",
  is_zrr_pre & is_zrr_post, "stayer",
  !is_zrr_pre & !is_zrr_post, "never"
)]

cat("\n=== ZRR Treatment Groups ===\n")
print(table(zrr_merged$treatment_group))

# Add commune names from post data
zrr_merged <- merge(zrr_merged, dt_post[, .(codgeo, libgeo)],
                     by = "codgeo", all.x = TRUE)

# ============================================================
# 4) Read additional ZRR info (EPCI, density) from COG 2017 file
# ============================================================
cat("\n=== Extracting EPCI info from ZRR data ===\n")

# The COG 2021 file might have more columns (ZONAGE_MODALITES)
zrr_full <- read_excel(file.path(data_dir, "zrr_cog2021.xls"),
                        sheet = "Classement ZRR (COG 2017)", skip = 4)
cat("Full COG 2017 columns:", paste(names(zrr_full), collapse = ", "), "\n")
cat("Full data sample:\n")
print(head(zrr_full, 5))
cat("Number of columns:", ncol(zrr_full), "\n")

# Check if there's EPCI info
epci_cols <- names(zrr_full)[grep("epci|interco|siren|groupement",
                                   tolower(names(zrr_full)))]
cat("EPCI-related columns:", paste(epci_cols, collapse = ", "), "\n")

# ============================================================
# 5) Process Election Data from Parquet
# ============================================================
cat("\n=== Processing election data ===\n")

target_elections <- c("2002_pres_t1", "2007_pres_t1", "2012_pres_t1",
                      "2017_pres_t1", "2022_pres_t1", "2019_euro_t1")

cand_ds <- arrow::open_dataset(file.path(data_dir, "candidats_results.parquet"))
cand_filtered <- cand_ds |>
  filter(id_election %in% target_elections) |>
  select(id_election, code_departement, code_commune, code_bv,
         nom, prenom, voix, nuance, liste, libelle_abrege_liste) |>
  collect()

cat("Filtered candidate results:", nrow(cand_filtered), "rows\n")

gen_ds <- arrow::open_dataset(file.path(data_dir, "general_results.parquet"))
gen_filtered <- gen_ds |>
  filter(id_election %in% target_elections) |>
  select(id_election, code_departement, code_commune, code_bv,
         libelle_commune, inscrits, votants, exprimes, abstentions, blancs, nuls) |>
  collect()

cat("Filtered general results:", nrow(gen_filtered), "rows\n")

# ============================================================
# 6) Identify FN/RN candidates
# ============================================================
cat("\n=== Identifying FN/RN candidates ===\n")

# Quick summary to identify candidate names and nuances
for (elec in target_elections) {
  cat("\n--- ", elec, " ---\n")
  sub <- cand_filtered[cand_filtered$id_election == elec, ]
  if (grepl("euro", elec)) {
    # For European elections, show liste/libelle columns
    cand_agg <- sub |>
      group_by(liste, libelle_abrege_liste, nuance) |>
      summarise(total_voix = sum(voix, na.rm = TRUE), .groups = "drop") |>
      arrange(desc(total_voix)) |>
      head(10)
  } else {
    cand_agg <- sub |>
      group_by(nom, prenom, nuance) |>
      summarise(total_voix = sum(voix, na.rm = TRUE), .groups = "drop") |>
      arrange(desc(total_voix)) |>
      head(5)
  }
  print(cand_agg)
}

# Tag FN/RN votes
cand_filtered <- cand_filtered |>
  mutate(
    is_fn_rn = case_when(
      id_election %in% c("2002_pres_t1", "2007_pres_t1") &
        toupper(trimws(nom)) == "LE PEN" &
        grepl("JEAN", toupper(trimws(prenom))) ~ TRUE,
      id_election %in% c("2012_pres_t1", "2017_pres_t1", "2022_pres_t1") &
        toupper(trimws(nom)) == "LE PEN" &
        grepl("MARINE", toupper(trimws(prenom))) ~ TRUE,
      id_election == "2019_euro_t1" &
        (grepl("RN|RASSEMBLEMENT.NATIONAL|BARDELLA|PRENEZ.LE.POUVOIR",
               toupper(paste0(
                 ifelse(is.na(nuance), "", nuance), " ",
                 ifelse(is.na(liste), "", liste), " ",
                 ifelse(is.na(libelle_abrege_liste), "", libelle_abrege_liste), " ",
                 ifelse(is.na(nom), "", nom)
               )))) ~ TRUE,
      TRUE ~ FALSE
    )
  )

# Verify
fn_check <- cand_filtered |>
  filter(is_fn_rn) |>
  group_by(id_election, nom, prenom, nuance) |>
  summarise(total_voix = sum(voix, na.rm = TRUE), .groups = "drop")
cat("\nFN/RN identified:\n")
print(fn_check)

# ============================================================
# 7) Aggregate to Commune Level
# ============================================================
cat("\n=== Aggregating to commune level ===\n")

# Debug: check format of election commune codes
cat("Election data sample code_commune (first 10):\n")
print(head(gen_filtered$code_commune, 10))
cat("ZRR sample commune codes (first 10):\n")
print(head(dt_pre$codgeo, 10))
cat("Election code_commune nchar:", paste(unique(nchar(gen_filtered$code_commune[1:100])), collapse=", "), "\n")
cat("ZRR codgeo nchar:", paste(unique(nchar(dt_pre$codgeo[1:100])), collapse=", "), "\n")

# code_commune in the Parquet already contains the full 5-digit INSEE code
# (e.g., "01001" for L'Abergement-Clémenciat in department 01)
# So use it directly — do NOT concatenate with code_departement
cand_filtered$commune_code <- trimws(cand_filtered$code_commune)
gen_filtered$commune_code <- trimws(gen_filtered$code_commune)

# FN/RN votes by commune
fn_rn_commune <- cand_filtered |>
  filter(is_fn_rn) |>
  group_by(id_election, commune_code) |>
  summarise(fn_rn_voix = sum(voix, na.rm = TRUE), .groups = "drop")

# Total votes by commune
turnout_commune <- gen_filtered |>
  group_by(id_election, commune_code, libelle_commune) |>
  summarise(
    inscrits = sum(inscrits, na.rm = TRUE),
    votants = sum(votants, na.rm = TRUE),
    exprimes = sum(exprimes, na.rm = TRUE),
    abstentions = sum(abstentions, na.rm = TRUE),
    blancs = sum(blancs, na.rm = TRUE),
    .groups = "drop"
  )

# Merge
election_commune <- turnout_commune |>
  left_join(fn_rn_commune, by = c("id_election", "commune_code")) |>
  mutate(
    fn_rn_voix = replace_na(fn_rn_voix, 0),
    fn_rn_pct_exprimes = fn_rn_voix / exprimes * 100,
    fn_rn_pct_inscrits = fn_rn_voix / inscrits * 100,
    turnout_pct = votants / inscrits * 100,
    year = as.integer(str_extract(id_election, "^\\d{4}")),
    election_type = ifelse(grepl("pres", id_election), "presidential", "european")
  )

cat("Commune-election panel:", nrow(election_commune), "rows\n")
cat("Communes per election:\n")
print(table(election_commune$id_election))

# National sanity check
national <- election_commune |>
  group_by(id_election, year) |>
  summarise(
    fn_rn_national_pct = sum(fn_rn_voix) / sum(exprimes) * 100,
    n_communes = n(),
    total_inscrits = sum(inscrits),
    .groups = "drop"
  )
cat("\nNational FN/RN vote share:\n")
print(national)

# ============================================================
# 8) Merge ZRR Treatment with Election Panel
# ============================================================
cat("\n=== Merging ZRR treatment with election panel ===\n")

# Merge on commune_code = codgeo
panel <- election_commune |>
  left_join(zrr_merged[, .(codgeo, is_zrr_pre, is_zrr_post, treatment_group)],
            by = c("commune_code" = "codgeo"))

# Check merge rate
cat("Total commune-election obs:", nrow(panel), "\n")
cat("Matched to ZRR:", sum(!is.na(panel$treatment_group)), "\n")
cat("Unmatched:", sum(is.na(panel$treatment_group)), "\n")

# For unmatched communes, classify as "never" (they don't appear in ZRR files)
panel$treatment_group[is.na(panel$treatment_group)] <- "never"
panel$is_zrr_pre[is.na(panel$is_zrr_pre)] <- FALSE
panel$is_zrr_post[is.na(panel$is_zrr_post)] <- FALSE

cat("\nTreatment group distribution (all elections combined):\n")
print(table(panel$treatment_group))

# Group counts by election
group_by_election <- panel |>
  group_by(id_election, treatment_group) |>
  summarise(n = n(), .groups = "drop") |>
  pivot_wider(names_from = treatment_group, values_from = n)
cat("\nGroup counts by election:\n")
print(group_by_election)

# ============================================================
# 9) Create Analysis Samples
# ============================================================
cat("\n=== Creating analysis samples ===\n")

# Main DiD sample: losers vs stayers (presidential elections only)
did_sample <- panel |>
  filter(treatment_group %in% c("loser", "stayer"),
         election_type == "presidential") |>
  mutate(
    treated = as.integer(treatment_group == "loser"),
    post = as.integer(year >= 2022),
    post_2019 = as.integer(year >= 2019)  # for 2019 European if included later
  )

cat("DiD sample (losers vs stayers, presidential):", nrow(did_sample), "rows\n")
cat("  Losers:", sum(did_sample$treated == 1) / 5, "communes\n")  # /5 elections
cat("  Stayers:", sum(did_sample$treated == 0) / 5, "communes\n")

# Symmetric test sample: gainers vs never (presidential elections only)
sym_sample <- panel |>
  filter(treatment_group %in% c("gainer", "never"),
         election_type == "presidential") |>
  mutate(
    treated = as.integer(treatment_group == "gainer"),
    post = as.integer(year >= 2022)
  )

cat("Symmetric sample (gainers vs never, presidential):", nrow(sym_sample), "rows\n")

# Full sample for summary statistics
full_sample <- panel |>
  filter(election_type == "presidential")

# ============================================================
# 10) Save Analysis-Ready Data
# ============================================================
cat("\n=== Saving analysis-ready data ===\n")

fwrite(as.data.table(panel), file.path(data_dir, "full_panel.csv"))
fwrite(as.data.table(did_sample), file.path(data_dir, "did_sample.csv"))
fwrite(as.data.table(sym_sample), file.path(data_dir, "sym_sample.csv"))
fwrite(as.data.table(zrr_merged), file.path(data_dir, "zrr_treatment_groups.csv"))

cat("Saved: full_panel.csv, did_sample.csv, sym_sample.csv, zrr_treatment_groups.csv\n")

# === DATA VALIDATION ===
stopifnot("DiD sample must have 5 presidential elections" =
            length(unique(did_sample$year)) == 5)
stopifnot("Must have losers in sample" = sum(did_sample$treated == 1) > 0)
stopifnot("Must have stayers in sample" = sum(did_sample$treated == 0) > 0)
stopifnot("FN/RN vote share must be between 0 and 100" =
            all(did_sample$fn_rn_pct_exprimes >= 0 &
                did_sample$fn_rn_pct_exprimes <= 100, na.rm = TRUE))

cat("\n=== Data cleaning complete ===\n")
cat("DiD sample: ", length(unique(did_sample$commune_code)), "communes x",
    length(unique(did_sample$year)), "elections =", nrow(did_sample), "obs\n")
