# ==============================================================================
# 02_clean_data.R — Clean and merge all data into analysis panel
# APEP apep_0536: FTTH, Polarization, and Misinformation in France
# ==============================================================================

source("00_packages.R")
library(readxl)

data_dir <- "../data"

# ==============================================================================
# 1. ARCEP FTTH Deployment — Department × Quarter (from observatory Excel)
# ==============================================================================

cat("=== Processing ARCEP FTTH deployment data ===\n")

# Read FttH par Departements sheet
ftth_raw <- read_excel(file.path(data_dir, "arcep_ftth_deployment.xlsx"),
                       sheet = "FttH par Départements", col_names = FALSE)

# Row 5 is the header with quarter labels
header_row <- as.character(ftth_raw[5, ])

# Extract quarter labels from columns 4 onward
# Format: "T4 2017", "T1 2018", etc.
quarter_labels <- header_row[4:length(header_row)]
cat("  Quarter labels:", paste(head(quarter_labels, 5), collapse = ", "), "...",
    paste(tail(quarter_labels, 3), collapse = ", "), "\n")

# Data starts at row 6, every 2 rows = one department
# Row pattern: Locaux Raccordables, Catégorie
data_rows <- ftth_raw[6:nrow(ftth_raw), ]

# Extract "Locaux Raccordables" rows only (odd rows)
raccordables_idx <- seq(1, nrow(data_rows), by = 2)
raccordables <- data_rows[raccordables_idx, ]

# Department codes and total premises
dept_codes <- as.character(raccordables[[1]])
total_premises <- as.numeric(raccordables[[3]])

# Quarterly premises connectable (columns 4 onward)
quarterly_data <- as.data.frame(raccordables[, 4:ncol(raccordables)])
for (j in 1:ncol(quarterly_data)) {
  quarterly_data[[j]] <- as.numeric(quarterly_data[[j]])
}

# Parse quarter labels into year + quarter
parse_quarter <- function(label) {
  parts <- strsplit(trimws(label), " ")[[1]]
  q <- as.integer(gsub("T", "", parts[1]))
  y <- as.integer(parts[2])
  list(year = y, quarter = q)
}

# Build long-format panel
ftth_list <- list()
for (j in 1:length(quarter_labels)) {
  if (is.na(quarter_labels[j]) || quarter_labels[j] == "NA") next
  pq <- tryCatch(parse_quarter(quarter_labels[j]), error = function(e) NULL)
  if (is.null(pq)) next

  ftth_list[[length(ftth_list) + 1]] <- data.table(
    dept_code = dept_codes,
    year = pq$year,
    quarter = pq$quarter,
    premises_connectable = quarterly_data[[j]],
    premises_total = total_premises
  )
}

ftth_dept <- rbindlist(ftth_list)

# Remove NA departments and compute coverage
ftth_dept <- ftth_dept[!is.na(dept_code) & dept_code != ""]
ftth_dept[, ftth_coverage := premises_connectable / premises_total]
ftth_dept[is.nan(ftth_coverage) | is.na(ftth_coverage), ftth_coverage := 0]
ftth_dept[, yq := year + (quarter - 1) / 4]

# Keep metropolitan departments only
metro_depts <- c(sprintf("%02d", 1:19), "2A", "2B", sprintf("%02d", 21:95))
ftth_dept <- ftth_dept[dept_code %in% metro_depts]

cat("  Department-quarter panel:", nrow(ftth_dept), "rows\n")
cat("  Departments:", uniqueN(ftth_dept$dept_code), "\n")
cat("  Year range:", min(ftth_dept$year), "-", max(ftth_dept$year), "\n")
cat("  Quarter range:", min(ftth_dept$quarter), "-", max(ftth_dept$quarter), "\n")
cat("  Coverage summary:\n")
print(summary(ftth_dept$ftth_coverage))

# Save
fwrite(ftth_dept, file.path(data_dir, "ftth_dept_quarter.csv"))
cat("  Saved: ftth_dept_quarter.csv\n")

# ==============================================================================
# 2. Election Results — Aggregate to department × election
# ==============================================================================

cat("\n=== Processing election results ===\n")

# Read candidate results
cat("  Reading candidate results...\n")
elections_cand <- fread(file.path(data_dir, "elections_candidats_results.csv"),
                        encoding = "UTF-8")

# Read general results
cat("  Reading general results...\n")
elections_gen <- fread(file.path(data_dir, "elections_general_results.csv"),
                       encoding = "UTF-8")

# Parse election ID
elections_cand[, `:=`(
  election_year = as.integer(substr(id_election, 1, 4)),
  election_type = sub("^[0-9]+_([a-z]+)_.*$", "\\1", id_election),
  election_round = sub("^.*_(t[0-9])$", "\\1", id_election)
)]
elections_gen[, `:=`(
  election_year = as.integer(substr(id_election, 1, 4)),
  election_type = sub("^[0-9]+_([a-z]+)_.*$", "\\1", id_election),
  election_round = sub("^.*_(t[0-9])$", "\\1", id_election)
)]

# Keep first rounds of presidential, European, legislative elections
# These span 2002-2024 — we need elections overlapping with FTTH data (2017+)
# but also pre-treatment elections for event study
target_types <- c("pres", "euro", "leg")
cand_sub <- elections_cand[election_type %in% target_types & election_round == "t1"]
gen_sub <- elections_gen[election_type %in% target_types & election_round == "t1"]

cat("  Unique elections:", paste(sort(unique(cand_sub$id_election)), collapse = ", "), "\n")

# Use code_departement directly (available in the data)
cand_sub[, dept_code := code_departement]
gen_sub[, dept_code := code_departement]

# Keep metropolitan France
cand_metro <- cand_sub[dept_code %in% metro_depts]
gen_metro <- gen_sub[dept_code %in% metro_depts]

# Define anti-system classification
# Strategy: use candidate NAME for presidential, NUANCE/LIST for European
cand_metro[, nom_upper := toupper(nom)]

# --- Presidential elections: by candidate name ---
# Core: RN/FN (Le Pen) + LFI (Melenchon) + Reconquete (Zemmour)
cand_metro[election_type == "pres", is_antisystem := nom_upper %in% c(
  "LE PEN", "MÉLENCHON", "MELENCHON", "ZEMMOUR"
)]
cand_metro[election_type == "pres", is_antisystem_broad := is_antisystem | nom_upper %in% c(
  "DUPONT-AIGNAN", "ARTHAUD", "POUTOU", "ASSELINEAU",
  "PHILIPPOT", "CHEMINADE", "LASSALLE"
)]

# --- European elections: by nuance code ---
# Anti-system nuances across years:
# FRN (1999) = Front National, MNA (1999) = Mouvement National (Megret split)
# LFN (2004, 2009, 2014) = Liste FN, LEXG = Extreme gauche
# LFG (2014) = Front de Gauche (Melenchon), LRN (2024) = RN
# LFI (2024) = France Insoumise, LREC (2024) = Reconquete
antisystem_nuances <- c("FRN", "MNA", "LFN", "LRN", "LFI", "LFG", "LREC",
                          "LEXG", "EXG", "EXD", "LEXD")
cand_metro[election_type == "euro" & nuance != "", is_antisystem :=
  nuance %in% c("FRN", "MNA", "LFN", "LRN", "LFI", "LFG", "LREC")]
cand_metro[election_type == "euro" & nuance != "", is_antisystem_broad :=
  nuance %in% antisystem_nuances]

# 2019 European: nuance is empty, use list name
cand_metro[id_election == "2019_euro_t1", is_antisystem :=
  grepl("PRENEZ LE POUVOIR|FRANCE INSOUMISE", libelle_abrege_liste, ignore.case = TRUE)]
cand_metro[id_election == "2019_euro_t1", is_antisystem_broad := is_antisystem |
  grepl("DEBOUT LA FRANCE|LUTTE OUVRIERE|PARTI COMMUNISTE|POUR L.EUROPE DES GENS",
        libelle_abrege_liste, ignore.case = TRUE)]

# --- Legislative elections: by nuance ---
# FN, RN, FI, EXG, EXD nuances
cand_metro[election_type == "leg", is_antisystem :=
  nuance %in% c("FN", "RN", "FI", "LFI")]
cand_metro[election_type == "leg", is_antisystem_broad := is_antisystem |
  nuance %in% c("EXG", "EXD", "DLF", "COM")]

# Fill NAs with FALSE
cand_metro[is.na(is_antisystem), is_antisystem := FALSE]
cand_metro[is.na(is_antisystem_broad), is_antisystem_broad := FALSE]

cat("  Anti-system candidates by election:\n")
antisys_summary <- cand_metro[is_antisystem == TRUE,
  .(total_votes = sum(as.numeric(voix), na.rm = TRUE)),
  by = .(id_election)][order(id_election)]
print(antisys_summary)

# Aggregate to department × election
# Sum votes directly at the candidate/list level to avoid grouping issues
# (European elections have list-based data where nom_upper may be missing)
dept_totals <- cand_metro[, .(
  total_votes = sum(as.numeric(voix), na.rm = TRUE),
  antisystem_votes = sum(as.numeric(voix)[is_antisystem], na.rm = TRUE),
  antisystem_broad_votes = sum(as.numeric(voix)[is_antisystem_broad], na.rm = TRUE),
  n_candidates = uniqueN(nom_upper[!is.na(nom_upper) & nom_upper != ""])
), by = .(dept_code, id_election, election_year, election_type)]

# Effective number of parties
# Compute per candidate/list share directly from candidate-level data
cand_dept_votes <- cand_metro[, .(
  votes = sum(as.numeric(voix), na.rm = TRUE)
), by = .(dept_code, id_election, nom_upper)]
cand_dept_votes[, total := sum(votes), by = .(dept_code, id_election)]
cand_dept_votes[, vote_share := votes / total]

enp <- cand_dept_votes[, .(
  eff_n_parties = 1 / sum(vote_share^2, na.rm = TRUE)
), by = .(dept_code, id_election)]

# General results at department level
dept_gen <- gen_metro[, .(
  inscrits = sum(as.numeric(inscrits), na.rm = TRUE),
  votants = sum(as.numeric(votants), na.rm = TRUE),
  blancs = sum(as.numeric(blancs), na.rm = TRUE),
  nuls = sum(as.numeric(nuls), na.rm = TRUE),
  exprimes = sum(as.numeric(exprimes), na.rm = TRUE)
), by = .(dept_code, id_election, election_year, election_type)]

# Merge
dept_elections <- merge(dept_totals, dept_gen,
                        by = c("dept_code", "id_election", "election_year", "election_type"))
dept_elections <- merge(dept_elections, enp, by = c("dept_code", "id_election"), all.x = TRUE)

# Compute outcome variables
dept_elections[, `:=`(
  antisystem_share = antisystem_votes / inscrits,
  antisystem_share_expr = antisystem_votes / exprimes,
  antisystem_broad_share = antisystem_broad_votes / inscrits,
  turnout = votants / inscrits,
  blank_null_share = (blancs + nuls) / inscrits,
  blank_null_share_votants = (blancs + nuls) / votants
)]

# Election timing (quarter of year)
# Presidential: Apr-May → Q2; European: May-Jun → Q2; Legislative: Jun → Q2
dept_elections[, election_quarter := 2L]

cat("\n  Department-election panel:", nrow(dept_elections), "rows\n")
cat("  Departments:", uniqueN(dept_elections$dept_code), "\n")
cat("  Elections:", paste(sort(unique(dept_elections$id_election)), collapse = ", "), "\n")
cat("  Anti-system share (of inscrits) summary:\n")
print(summary(dept_elections$antisystem_share))
cat("  Turnout summary:\n")
print(summary(dept_elections$turnout))
cat("  Effective N parties:\n")
print(summary(dept_elections$eff_n_parties))

fwrite(dept_elections, file.path(data_dir, "elections_dept.csv"))
cat("  Saved: elections_dept.csv\n")

# ==============================================================================
# 3. Unemployment — Parse INSEE Excel
# ==============================================================================

cat("\n=== Processing unemployment controls ===\n")

chomage_file <- file.path(data_dir, "chomage_dept_insee.xls")
if (!file.exists(chomage_file)) {
  cat("  Downloading INSEE unemployment data...\n")
  chomage_url <- "https://www.insee.fr/fr/statistiques/fichier/2012804/sl_etc_2025T3.xls"
  download.file(chomage_url, chomage_file, mode = "wb", quiet = TRUE)
}

chomage_raw <- read_excel(chomage_file, sheet = "Département")
cat("  Unemployment data:", nrow(chomage_raw), "x", ncol(chomage_raw), "\n")

# This is a wide-format file: rows = departments, columns = quarters
# Header typically in row 3-4
# Parse carefully
chomage_dt <- as.data.table(chomage_raw)

# Find the row with department codes (typically starts with "01")
code_col <- 1
header_idx <- which(chomage_dt[[code_col]] == "Code")[1]
if (is.na(header_idx)) {
  # Try to find header by looking for quarter patterns
  for (r in 1:10) {
    vals <- as.character(chomage_dt[r, 3:min(10, ncol(chomage_dt))])
    if (any(grepl("T[1-4]", vals))) {
      header_idx <- r
      break
    }
  }
}

if (!is.na(header_idx)) {
  cat("  Header found at row:", header_idx, "\n")
  # Extract quarter headers from header_idx row
  q_headers <- as.character(chomage_dt[header_idx, ])
  cat("  First quarter headers:", paste(q_headers[3:min(8, length(q_headers))], collapse = ", "), "\n")

  # Data rows are after header
  data_start <- header_idx + 1
  chomage_data <- chomage_dt[data_start:nrow(chomage_dt), ]

  # Build long format
  dept_codes_chomage <- as.character(chomage_data[[1]])
  dept_names_chomage <- as.character(chomage_data[[2]])

  chomage_long <- list()
  for (j in 3:ncol(chomage_data)) {
    q_label <- q_headers[j]
    if (is.na(q_label) || !grepl("T[1-4]", q_label)) next

    # Parse "T1 2012" or "2012T1" format
    if (grepl("^T", q_label)) {
      q <- as.integer(substr(q_label, 2, 2))
      y <- as.integer(trimws(sub("^T[1-4]\\s*", "", q_label)))
    } else {
      y <- as.integer(substr(q_label, 1, 4))
      q <- as.integer(substr(q_label, 6, 6))
    }

    if (is.na(y) || is.na(q)) next

    chomage_long[[length(chomage_long) + 1]] <- data.table(
      dept_code = dept_codes_chomage,
      dept_name = dept_names_chomage,
      year = y,
      quarter = q,
      unemployment_rate = as.numeric(chomage_data[[j]])
    )
  }

  if (length(chomage_long) > 0) {
    chomage_panel <- rbindlist(chomage_long)
    chomage_panel <- chomage_panel[!is.na(dept_code) & dept_code != "" &
                                     dept_code %in% metro_depts]
    cat("  Unemployment panel:", nrow(chomage_panel), "rows\n")
    cat("  Departments:", uniqueN(chomage_panel$dept_code), "\n")
    cat("  Year range:", range(chomage_panel$year, na.rm = TRUE), "\n")
    fwrite(chomage_panel, file.path(data_dir, "unemployment_dept_quarter.csv"))
    cat("  Saved: unemployment_dept_quarter.csv\n")
  }
} else {
  cat("  Could not parse unemployment Excel. Will proceed without.\n")
}

# ==============================================================================
# 4. Construct Treatment Variables and Thresholds
# ==============================================================================

cat("\n=== Constructing treatment variables ===\n")

ftth_dept <- fread(file.path(data_dir, "ftth_dept_quarter.csv"))

# First time each department crosses coverage thresholds
for (thresh in c(0.25, 0.50, 0.75)) {
  col_name <- paste0("first_cross_", thresh * 100)
  cross_dt <- ftth_dept[ftth_coverage >= thresh,
    .(first_yq = min(yq)),
    by = dept_code
  ]
  setnames(cross_dt, "first_yq", col_name)
  ftth_dept <- merge(ftth_dept, cross_dt, by = "dept_code", all.x = TRUE)
}

# Binary treated indicators
ftth_dept[, `:=`(
  treated_25 = as.integer(ftth_coverage >= 0.25),
  treated_50 = as.integer(ftth_coverage >= 0.50),
  treated_75 = as.integer(ftth_coverage >= 0.75)
)]

# Cohort variable for CS-DiD: year-quarter when department first crosses 50%
ftth_dept[, cohort_50 := first_cross_50]

fwrite(ftth_dept, file.path(data_dir, "ftth_dept_quarter.csv"))
cat("  Treatment thresholds computed. Saved.\n")

# Treatment timing summary
cat("\n  Treatment timing (50% threshold):\n")
print(ftth_dept[!is.na(first_cross_50), .N, by = first_cross_50][order(first_cross_50)])

# ==============================================================================
# 5. Merge: FTTH Treatment × Election Outcomes
# ==============================================================================

cat("\n=== Building analysis panel ===\n")

elections <- fread(file.path(data_dir, "elections_dept.csv"))

# For each election, get FTTH coverage at election time
# All target elections are in Q2
elections[, merge_yq := election_year + (election_quarter - 1) / 4]

# Get the closest FTTH quarter for each election
# For elections before 2017 Q4, FTTH was ~0
ftth_at_election <- ftth_dept[quarter == 2,
  .(dept_code, year, ftth_coverage, treated_25, treated_50, treated_75,
    first_cross_25, first_cross_50, first_cross_75, cohort_50,
    premises_connectable, premises_total)]

analysis_panel <- merge(
  elections,
  ftth_at_election,
  by.x = c("dept_code", "election_year"),
  by.y = c("dept_code", "year"),
  all.x = TRUE
)

# Pre-FTTH elections: set coverage to 0
analysis_panel[is.na(ftth_coverage), `:=`(
  ftth_coverage = 0,
  treated_25 = 0L,
  treated_50 = 0L,
  treated_75 = 0L,
  premises_connectable = 0
)]

# Merge unemployment
if (file.exists(file.path(data_dir, "unemployment_dept_quarter.csv"))) {
  unemp <- fread(file.path(data_dir, "unemployment_dept_quarter.csv"))
  unemp_q2 <- unemp[quarter == 2, .(dept_code, year, unemployment_rate)]
  analysis_panel <- merge(analysis_panel, unemp_q2,
                          by.x = c("dept_code", "election_year"),
                          by.y = c("dept_code", "year"),
                          all.x = TRUE)
}

# Numeric department ID for FE
analysis_panel[, dept_id := as.integer(factor(dept_code))]

# Election period ID (numeric)
analysis_panel[, election_id := as.integer(factor(id_election))]

fwrite(analysis_panel, file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# 6. Summary Statistics
# ==============================================================================

cat("\n=== ANALYSIS PANEL SUMMARY ===\n")
cat("  Observations:", nrow(analysis_panel), "\n")
cat("  Departments:", uniqueN(analysis_panel$dept_code), "\n")
cat("  Elections:", uniqueN(analysis_panel$id_election), "\n")
cat("  Election list:\n")
print(analysis_panel[, .(n_depts = uniqueN(dept_code),
                          mean_antisys = mean(antisystem_share, na.rm = TRUE),
                          mean_turnout = mean(turnout, na.rm = TRUE),
                          mean_ftth = mean(ftth_coverage, na.rm = TRUE)),
                      by = .(id_election, election_year)][order(election_year)])

cat("\n  Outcome variables (full panel):\n")
cat("  Anti-system share (inscrits):", sprintf("%.3f (%.3f)",
    mean(analysis_panel$antisystem_share, na.rm = TRUE),
    sd(analysis_panel$antisystem_share, na.rm = TRUE)), "\n")
cat("  Anti-system share (exprimes):", sprintf("%.3f (%.3f)",
    mean(analysis_panel$antisystem_share_expr, na.rm = TRUE),
    sd(analysis_panel$antisystem_share_expr, na.rm = TRUE)), "\n")
cat("  Turnout:", sprintf("%.3f (%.3f)",
    mean(analysis_panel$turnout, na.rm = TRUE),
    sd(analysis_panel$turnout, na.rm = TRUE)), "\n")
cat("  Eff. N parties:", sprintf("%.2f (%.2f)",
    mean(analysis_panel$eff_n_parties, na.rm = TRUE),
    sd(analysis_panel$eff_n_parties, na.rm = TRUE)), "\n")

cat("\n  Treatment variables:\n")
cat("  FTTH coverage:", sprintf("%.3f (%.3f)",
    mean(analysis_panel$ftth_coverage, na.rm = TRUE),
    sd(analysis_panel$ftth_coverage, na.rm = TRUE)), "\n")
cat("  Obs with FTTH > 0:", sum(analysis_panel$ftth_coverage > 0, na.rm = TRUE),
    "of", nrow(analysis_panel), "\n")

# Save summary stats table for paper
sumstats <- data.table(
  Variable = c("Anti-system vote share (% inscrits)", "Anti-system vote share (% exprimes)",
                "Turnout", "Blank/null vote share", "Eff. number of parties",
                "FTTH coverage rate", "Treated (>25%)", "Treated (>50%)"),
  Mean = c(mean(analysis_panel$antisystem_share, na.rm = TRUE),
            mean(analysis_panel$antisystem_share_expr, na.rm = TRUE),
            mean(analysis_panel$turnout, na.rm = TRUE),
            mean(analysis_panel$blank_null_share, na.rm = TRUE),
            mean(analysis_panel$eff_n_parties, na.rm = TRUE),
            mean(analysis_panel$ftth_coverage, na.rm = TRUE),
            mean(analysis_panel$treated_25, na.rm = TRUE),
            mean(analysis_panel$treated_50, na.rm = TRUE)),
  SD = c(sd(analysis_panel$antisystem_share, na.rm = TRUE),
          sd(analysis_panel$antisystem_share_expr, na.rm = TRUE),
          sd(analysis_panel$turnout, na.rm = TRUE),
          sd(analysis_panel$blank_null_share, na.rm = TRUE),
          sd(analysis_panel$eff_n_parties, na.rm = TRUE),
          sd(analysis_panel$ftth_coverage, na.rm = TRUE),
          sd(analysis_panel$treated_25, na.rm = TRUE),
          sd(analysis_panel$treated_50, na.rm = TRUE)),
  N = nrow(analysis_panel)
)
fwrite(sumstats, file.path(data_dir, "summary_statistics.csv"))

cat("\n02_clean_data.R complete.\n")
