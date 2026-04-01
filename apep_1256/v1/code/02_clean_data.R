## ============================================================================
## 02_clean_data.R — apep_1256
## Clean and merge election, campaign finance, and procurement data
## Construct RDD running variable and treatment
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"

## --------------------------------------------------------------------------
## Helper: standardize municipality names (uppercase, remove accents/diacritics)
## --------------------------------------------------------------------------
std_name <- function(x) {
  x <- toupper(trimws(x))
  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x <- gsub("[^A-Z ]", "", x)
  x <- gsub("\\s+", " ", x)
  x
}

# Ensure stringi is available
if (!requireNamespace("stringi", quietly = TRUE)) {
  install.packages("stringi", repos = "https://cloud.r-project.org")
}
library(stringi)

## --------------------------------------------------------------------------
## 1. ELECTION DATA — compute vote margins
## --------------------------------------------------------------------------
cat("=== Processing election data ===\n")

election <- fread(paste0(data_dir, "election_2019_raw.csv"))

# Get top-2 candidates per municipality by votes
election[, votos := as.numeric(votos)]
setorder(election, codmpio, -votos)
election[, rank := seq_len(.N), by = codmpio]

# Keep only top 2 candidates
top2 <- election[rank <= 2]

# Compute vote margin for each municipality
margins <- top2[, .(
  winner_votes   = votos[1],
  runnerup_votes = votos[2],
  winner_name    = paste(nombres[1], primer_apellido[1]),
  runnerup_name  = paste(nombres[2], primer_apellido[2]),
  total_votes    = sum(election[codmpio == codmpio[1], votos]),
  departamento   = departamento[1],
  municipio      = municipio[1]
), by = codmpio]

# Vote margin: positive = winner leads
margins[, margin := (winner_votes - runnerup_votes) / (winner_votes + runnerup_votes)]
margins[, total_valid := winner_votes + runnerup_votes]

# Standardized names for matching
margins[, dept_std := std_name(departamento)]
margins[, muni_std := std_name(municipio)]

cat(sprintf("Municipalities with margins: %d\n", nrow(margins)))
cat(sprintf("Margin range: [%.4f, %.4f]\n", min(margins$margin), max(margins$margin)))
cat(sprintf("Close races (|margin| < 0.10): %d\n", sum(abs(margins$margin) < 0.10)))

## --------------------------------------------------------------------------
## 2. CAMPAIGN FINANCE — compute donor funding intensity per candidate
## --------------------------------------------------------------------------
cat("\n=== Processing campaign finance data ===\n")

finance <- fread(paste0(data_dir, "finance_2019_raw.csv"))
finance[, ing_valor := as.numeric(ing_valor)]

# Classify income sources
# External donors = Donación + Contribución
# Self-financing = Aporte (candidate's own funds)
# Other = Crédito, Donación en especie, NO APLICA
finance[, source_type := fcase(
  tdo_nombre %in% c("Donación", "Contribución"), "external_donor",
  tdo_nombre == "Aporte", "self_financing",
  default = "other"
)]

# Aggregate by candidate
candidate_finance <- finance[, .(
  total_income     = sum(ing_valor, na.rm = TRUE),
  external_donors  = sum(ing_valor[source_type == "external_donor"], na.rm = TRUE),
  self_financing   = sum(ing_valor[source_type == "self_financing"], na.rm = TRUE),
  n_donors         = uniqueN(ing_identificacion[source_type == "external_donor"]),
  n_contributions  = .N
), by = .(can_identificacion, nombre_candidato, dep_nombre, mun_nombre)]

# Donor share = external donors / total income
candidate_finance[, donor_share := fifelse(
  total_income > 0, external_donors / total_income, 0
)]

# Standardized names
candidate_finance[, dept_std := std_name(dep_nombre)]
candidate_finance[, muni_std := std_name(mun_nombre)]

cat(sprintf("Candidates with finance data: %d\n", nrow(candidate_finance)))
cat(sprintf("Donor share: mean=%.3f, median=%.3f\n",
            mean(candidate_finance$donor_share),
            median(candidate_finance$donor_share)))

## --------------------------------------------------------------------------
## 3. MATCH CANDIDATES — link election winners to finance data
## --------------------------------------------------------------------------
cat("\n=== Matching election winners to campaign finance ===\n")

# Match on standardized department + municipality names
# Then fuzzy-match on candidate name within municipality
merged <- merge(
  margins,
  candidate_finance,
  by = c("dept_std", "muni_std"),
  allow.cartesian = TRUE
)

# For each municipality, find the finance record closest to the winner's name
# Use simple string distance
merged[, winner_std := std_name(winner_name)]
merged[, cand_std := std_name(nombre_candidato)]
merged[, name_dist := stringdist::stringdist(winner_std, cand_std, method = "jw")]

# Ensure stringdist is available
if (!requireNamespace("stringdist", quietly = TRUE)) {
  install.packages("stringdist", repos = "https://cloud.r-project.org")
}
library(stringdist)

merged[, name_dist := stringdist(winner_std, cand_std, method = "jw")]

# Best match per municipality
setorder(merged, codmpio, name_dist)
best_match <- merged[, .SD[1], by = codmpio]

# Filter to reasonable matches (Jaro-Winkler distance < 0.3)
good_matches <- best_match[name_dist < 0.3]
cat(sprintf("Good matches (dist < 0.3): %d of %d municipalities\n",
            nrow(good_matches), nrow(margins)))

# Also match runner-up
merged_ru <- merge(
  margins,
  candidate_finance,
  by = c("dept_std", "muni_std"),
  allow.cartesian = TRUE
)
merged_ru[, runnerup_std := std_name(runnerup_name)]
merged_ru[, cand_std := std_name(nombre_candidato)]
merged_ru[, name_dist := stringdist(runnerup_std, cand_std, method = "jw")]
setorder(merged_ru, codmpio, name_dist)
best_match_ru <- merged_ru[, .SD[1], by = codmpio]
ru_matches <- best_match_ru[name_dist < 0.3,
                             .(codmpio,
                               ru_donor_share = donor_share,
                               ru_total_income = total_income,
                               ru_n_donors = n_donors)]

# Merge winner and runner-up finance data
muni_data <- merge(
  good_matches[, .(codmpio, departamento, municipio, margin, total_valid,
                   winner_name, winner_donor_share = donor_share,
                   winner_total_income = total_income,
                   winner_n_donors = n_donors)],
  ru_matches,
  by = "codmpio",
  all.x = TRUE
)

# Treatment: winner has higher donor share than runner-up
# (or above-median donor share if runner-up data unavailable)
median_donor_share <- median(muni_data$winner_donor_share, na.rm = TRUE)
muni_data[, high_donor := fifelse(
  !is.na(ru_donor_share),
  as.integer(winner_donor_share > ru_donor_share),
  as.integer(winner_donor_share > median_donor_share)
)]

cat(sprintf("\nAnalysis sample: %d municipalities\n", nrow(muni_data)))
cat(sprintf("High-donor winners: %d (%.1f%%)\n",
            sum(muni_data$high_donor),
            100 * mean(muni_data$high_donor)))

## --------------------------------------------------------------------------
## 4. SECOP II — quarterly municipality-level procurement shares
## --------------------------------------------------------------------------
cat("\n=== Processing procurement data ===\n")

secop <- fread(paste0(data_dir, "secop_2019_2022_agg.csv"))
secop[, n_contracts := as.numeric(n_contracts)]
secop[, total_value := as.numeric(total_value)]
secop <- secop[yr != "" & !is.na(yr)]
secop[, yr := as.integer(yr)]
secop[, mo := as.integer(mo)]

# Assign quarter
secop[, quarter := ceiling(mo / 3)]
secop[, yq := paste0(yr, "Q", quarter)]

# Classify modalities as discretionary vs competitive
secop[, is_discretionary := as.integer(grepl(
  "directa|m.nima cuant.a",
  modalidad_de_contratacion, ignore.case = TRUE
))]

# Standardize names for matching
secop[, dept_std := std_name(departamento)]
secop[, city_std := std_name(ciudad)]

# Aggregate to municipality-quarter level
muni_quarter <- secop[, .(
  n_total        = sum(n_contracts),
  value_total    = sum(total_value),
  n_discretion   = sum(n_contracts * is_discretionary),
  value_discretion = sum(total_value * is_discretionary)
), by = .(dept_std, city_std, yr, quarter, yq)]

muni_quarter[, disc_share_n := n_discretion / n_total]
muni_quarter[, disc_share_v := value_discretion / value_total]

cat(sprintf("Municipality-quarter observations: %d\n", nrow(muni_quarter)))
cat(sprintf("Unique municipalities in SECOP: %d\n",
            uniqueN(paste(muni_quarter$dept_std, muni_quarter$city_std))))

## --------------------------------------------------------------------------
## 5. MERGE — Create analysis panel
## --------------------------------------------------------------------------
cat("\n=== Merging to create analysis panel ===\n")

# Add standardized names to muni_data
muni_data[, dept_std := std_name(departamento)]
muni_data[, muni_std := std_name(municipio)]

# Merge municipality characteristics with quarterly procurement
panel <- merge(
  muni_quarter,
  muni_data[, .(codmpio, dept_std, muni_std, margin, total_valid,
                high_donor, winner_donor_share, winner_n_donors)],
  by.x = c("dept_std", "city_std"),
  by.y = c("dept_std", "muni_std"),
  allow.cartesian = FALSE
)

# Create time variables
panel[, post := as.integer(yr >= 2020)]
panel[, time_to_treat := (yr - 2020) * 4 + quarter - 1]  # quarters relative to inauguration

# Period index (1-20 for Q1 2018 through Q4 2022)
panel[, period := (yr - 2018) * 4 + quarter]

cat(sprintf("Analysis panel: %d obs, %d municipalities, %d quarters\n",
            nrow(panel), uniqueN(panel$codmpio), uniqueN(panel$yq)))

# Bandwidth subsets
panel[, in_bw10 := abs(margin) < 0.10]
panel[, in_bw15 := abs(margin) < 0.15]
panel[, in_bw05 := abs(margin) < 0.05]

cat(sprintf("Municipalities within ±5pp margin: %d\n",
            uniqueN(panel[in_bw05 == TRUE, codmpio])))
cat(sprintf("Municipalities within ±10pp margin: %d\n",
            uniqueN(panel[in_bw10 == TRUE, codmpio])))
cat(sprintf("Municipalities within ±15pp margin: %d\n",
            uniqueN(panel[in_bw15 == TRUE, codmpio])))

## --------------------------------------------------------------------------
## 6. SAVE
## --------------------------------------------------------------------------
fwrite(muni_data, paste0(data_dir, "muni_characteristics.csv"))
fwrite(panel, paste0(data_dir, "analysis_panel.csv"))

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("Panel saved: %d rows\n", nrow(panel)))
