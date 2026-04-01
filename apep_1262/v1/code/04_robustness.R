## ============================================================================
## 04_robustness.R — Robustness checks and heterogeneity
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

## ============================================================================
## 1. PLACEBO OUTCOMES
## ============================================================================

cat("\n=== Placebo: Non-FN/RN vote share ===\n")

## Load election data to compute vote shares for other parties
if (!requireNamespace("arrow", quietly = TRUE)) install.packages("arrow")
library(arrow)

cand <- as.data.table(read_parquet(file.path(DATA_DIR, "elections/candidats_results.parquet")))
pres_t1 <- cand[grepl("_pres_t1$", id_election)]
pres_t1[, year := as.integer(substr(id_election, 1, 4))]
pres_t1[, code_commune := trimws(as.character(code_commune))]

## Identify left-wing candidates (PS, PCF, FI, EELV, etc.)
## Use nuance or candidate names for major candidates
## 2002: Jospin (PS), 2007: Royal (PS), 2012: Hollande (PS), 2017: Macron/Hamon, 2022: Mélenchon
pres_t1[, is_left := grepl("JOSPIN|ROYAL|HOLLANDE|HAMON|MELENCHON|HIDALGO",
                            nom, ignore.case = TRUE)]

## Mainstream right: Chirac, Sarkozy, Fillon, Pécresse
pres_t1[, is_right := grepl("CHIRAC|SARKOZY|FILLON|PECRESSE",
                             nom, ignore.case = TRUE)]

## Aggregate left vote share per commune-year
left_votes <- pres_t1[, .(
  total_voix = sum(voix, na.rm = TRUE),
  left_voix = sum(voix[is_left], na.rm = TRUE),
  right_voix = sum(voix[is_right], na.rm = TRUE)
), by = .(year, code_commune)]

left_votes[, left_pct := left_voix / total_voix * 100]
left_votes[, right_pct := right_voix / total_voix * 100]

## Merge with analysis panel
panel_placebo <- merge(panel, left_votes[, .(year, code_commune, left_pct, right_pct)],
                       by = c("year", "code_commune"), all.x = TRUE)

## Placebo 1: Left vote share (should NOT respond to carencee)
p1 <- feols(left_pct ~ treated:post | commune_id + year, data = panel_placebo,
            cluster = ~commune_id)
cat("Placebo 1 (left vote share):\n")
summary(p1)

## Placebo 2: Mainstream right vote share
p2 <- feols(right_pct ~ treated:post | commune_id + year, data = panel_placebo,
            cluster = ~commune_id)
cat("\nPlacebo 2 (mainstream right vote share):\n")
summary(p2)

## Placebo 3: With dept × year FE
panel_placebo[, dept := substr(code_commune, 1, 2)]
panel_placebo[, dept_year := paste0(dept, "_", year)]
p1b <- feols(left_pct ~ treated:post | commune_id + dept_year, data = panel_placebo,
             cluster = ~commune_id)
p2b <- feols(right_pct ~ treated:post | commune_id + dept_year, data = panel_placebo,
             cluster = ~commune_id)
cat("\nPlacebo 1b (left, dept×year FE):", coef(p1b), "SE:", se(p1b), "\n")
cat("Placebo 2b (right, dept×year FE):", coef(p2b), "SE:", se(p2b), "\n")

## ============================================================================
## 2. ALTERNATIVE CONTROL GROUP: INCLUDE COMPLIANT COMMUNES
## ============================================================================

cat("\n=== Alternative control: All SRU communes ===\n")

## Reload full SRU data
sru <- fread(file.path(DATA_DIR, "sru/transparence_sru.csv"))
sru[, code_commune := sprintf("%05s", as.character(code))]
sru[, treated_full := as.integer(carence == TRUE)]
sru[is.na(treated_full), treated_full := 0L]

## Reload election commune totals
commune_elections <- fread(file.path(DATA_DIR, "analysis_panel.csv"))[, .(year, code_commune, fn_rn_pct)] |> unique()

## Actually rebuild from the full parquet
fn_rn_all <- pres_t1[, .(total_voix = sum(voix, na.rm = TRUE)),
                     by = .(year, code_commune)]
fn_rn_votes <- pres_t1[grepl("^LE PEN$", nom, ignore.case = TRUE),
                       .(fn_rn_voix = sum(voix, na.rm = TRUE)),
                       by = .(year, code_commune)]
all_elections <- merge(fn_rn_all, fn_rn_votes, by = c("year", "code_commune"), all.x = TRUE)
all_elections[is.na(fn_rn_voix), fn_rn_voix := 0]
all_elections[, fn_rn_pct := fn_rn_voix / total_voix * 100]

## Merge with full SRU data
full_panel <- merge(all_elections, sru[, .(code_commune, treated_full, habitants)],
                    by = "code_commune")
full_panel[, commune_id := as.integer(factor(code_commune))]
full_panel[, post := as.integer(year >= 2022)]

r1 <- feols(fn_rn_pct ~ treated_full:post | commune_id + year, data = full_panel,
            cluster = ~commune_id)
cat("All SRU communes (carencee vs rest):\n")
summary(r1)

## ============================================================================
## 3. DOSE-RESPONSE: PENALTY INTENSITY
## ============================================================================

cat("\n=== Dose-response: Penalty multiplier ===\n")

## Use taux_majoration as treatment intensity (0-100%)
sru_intensity <- fread(file.path(DATA_DIR, "sru/transparence_sru.csv"))
sru_intensity[, code_commune := sprintf("%05s", as.character(code))]
sru_intensity[is.na(taux_majoration), taux_majoration := 0]

panel_dose <- merge(panel[, !c("taux_majoration"), with = FALSE],
                    sru_intensity[, .(code_commune, taux_maj = taux_majoration)],
                    by = "code_commune", all.x = TRUE)

## Among carencees, higher penalty multiplier = more severe treatment
d1 <- feols(fn_rn_pct ~ taux_maj:post | commune_id + year,
            data = panel_dose[treated == 1], cluster = ~commune_id)
cat("Dose-response (among carencees, penalty multiplier):\n")
summary(d1)

## ============================================================================
## 4. HETEROGENEITY: BY COMMUNE SIZE AND HOUSING GAP
## ============================================================================

cat("\n=== Heterogeneity ===\n")

## Split by median population
med_pop <- median(panel[year == 2017]$habitants, na.rm = TRUE)
panel[, large_commune := as.integer(habitants >= med_pop)]

h1_large <- feols(fn_rn_pct ~ treated:post | commune_id + year,
                  data = panel[large_commune == 1], cluster = ~commune_id)
h1_small <- feols(fn_rn_pct ~ treated:post | commune_id + year,
                  data = panel[large_commune == 0], cluster = ~commune_id)
cat("Large communes (pop >= median):", coef(h1_large), "SE:", se(h1_large), "\n")
cat("Small communes (pop < median):", coef(h1_small), "SE:", se(h1_small), "\n")

## Split by housing gap severity
med_gap <- median(panel[year == 2017]$housing_gap, na.rm = TRUE)
panel[, large_gap := as.integer(housing_gap >= med_gap)]

h2_large <- feols(fn_rn_pct ~ treated:post | commune_id + year,
                  data = panel[large_gap == 1], cluster = ~commune_id)
h2_small <- feols(fn_rn_pct ~ treated:post | commune_id + year,
                  data = panel[large_gap == 0], cluster = ~commune_id)
cat("Large housing gap:", coef(h2_large), "SE:", se(h2_large), "\n")
cat("Small housing gap:", coef(h2_small), "SE:", se(h2_small), "\n")

## ============================================================================
## 5. SAVE ALL ROBUSTNESS RESULTS
## ============================================================================

robustness <- list(
  placebo_left = p1,
  placebo_right = p2,
  placebo_left_dept = p1b,
  placebo_right_dept = p2b,
  all_sru_control = r1,
  dose_response = d1,
  het_large_commune = h1_large,
  het_small_commune = h1_small,
  het_large_gap = h2_large,
  het_small_gap = h2_small,
  panel_placebo = panel_placebo,
  panel_dose = panel_dose
)
saveRDS(robustness, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
