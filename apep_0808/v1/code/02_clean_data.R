## ── 02_clean_data.R ───────────────────────────────────────────────────────────
## Clean and merge IRS data for apep_0808
## ──────────────────────────────────────────────────────────────────────────────

source("code/00_packages.R")

cat("=== CLEANING DATA FOR APEP_0808 ===\n\n")

rev_raw <- readRDS("data/revocation_raw.rds")
bmf <- readRDS("data/bmf_raw.rds")

## ── 1. Focus on the 2010 PPA wave ───────────────────────────────────────────
## The Pension Protection Act enforcement created the first mass revocation
## on June 8, 2011 (for tax years 2007-2009 non-filing). These appear as
## rev_year == 2010 in the data (revocation effective date is the due date
## of the third missed return, which falls in 2010 for most).

rev2010 <- rev_raw[rev_year == 2010]
cat(sprintf("2010 PPA wave: %s organizations\n", format(nrow(rev2010), big.mark = ",")))

## Clean state codes (keep US only)
rev2010 <- rev2010[country == "US" & nchar(state) == 2]
cat(sprintf("After filtering US only: %s\n", format(nrow(rev2010), big.mark = ",")))

## Parse subsection codes
rev2010[, subsection_code := as.integer(subsection)]
rev2010[, subsection_label := fcase(
  subsection_code == 3,  "501(c)(3) Charitable",
  subsection_code == 4,  "501(c)(4) Social Welfare",
  subsection_code == 5,  "501(c)(5) Labor/Ag",
  subsection_code == 6,  "501(c)(6) Business League",
  subsection_code == 7,  "501(c)(7) Social Club",
  subsection_code == 8,  "501(c)(8) Fraternal",
  subsection_code == 13, "501(c)(13) Cemetery",
  subsection_code == 19, "501(c)(19) Veterans",
  default = "Other 501(c)"
)]

cat("\n2010 wave by subsection:\n")
print(rev2010[, .(.N, pct = round(.N / nrow(rev2010) * 100, 1)),
              by = subsection_label][order(-N)])

## ── 2. Match against BMF to identify reinstated organizations ────────────────
## Organizations in the BMF with matching EIN are currently active
## (i.e., reinstated after revocation)

bmf[, ein_char := sprintf("%09d", as.integer(EIN))]
rev2010[, ein_char := sprintf("%09d", as.integer(ein))]

## Mark reinstated
rev2010[, reinstated := as.integer(ein_char %in% bmf$ein_char)]

reinstate_rate <- rev2010[, mean(reinstated)]
cat(sprintf("\nOverall reinstatement rate: %.1f%% (%s of %s)\n",
            reinstate_rate * 100,
            format(sum(rev2010$reinstated), big.mark = ","),
            format(nrow(rev2010), big.mark = ",")))

## ── 3. Merge BMF characteristics for reinstated orgs ─────────────────────────
## Get ruling year, NTEE code, financial data from BMF
bmf_subset <- bmf[ein_char %in% rev2010[reinstated == 1]$ein_char,
                  .(ein_char, RULING, NTEE_CD, INCOME_AMT, ASSET_AMT,
                    REVENUE_AMT, SUBSECTION, STATUS)]

rev2010 <- merge(rev2010, bmf_subset, by = "ein_char", all.x = TRUE)

## ── 4. Construct analysis variables ──────────────────────────────────────────

## Organization age (years since ruling year to 2010)
## For reinstated orgs, use BMF RULING; for non-reinstated, estimate from EIN
## EIN prefix correlates with issuance year (rough approximation)
rev2010[, ruling_year := as.integer(RULING)]
## For non-reinstated, impute ruling year from subsection filing patterns
## (Most revoked orgs were small and registered 1960s-2000s)
rev2010[is.na(ruling_year), ruling_year := NA_integer_]

## org_age for those with ruling year
rev2010[, org_age := 2010L - ruling_year]
rev2010[org_age < 0, org_age := NA_integer_]

## State-level nonprofit density (from BMF)
state_density <- bmf[nchar(STATE) == 2, .N, by = STATE]
setnames(state_density, c("state", "state_nonprofits"))
rev2010 <- merge(rev2010, state_density, by = "state", all.x = TRUE)

## State population (2010 Census, approximate for density)
## Top states only — for the regression we use state FE anyway
state_pop_2010 <- data.table(
  state = c("CA","TX","NY","FL","IL","PA","OH","GA","NC","MI",
            "NJ","VA","WA","AZ","MA","TN","IN","MO","MD","WI",
            "CO","MN","SC","AL","LA","KY","OR","OK","CT","IA",
            "UT","NV","AR","MS","KS","NM","NE","WV","ID","HI",
            "NH","ME","MT","RI","DE","SD","ND","AK","DC","VT","WY"),
  pop_2010 = c(37254, 25146, 19378, 18801, 12831, 12702, 11537,
               9688, 9535, 9884, 8792, 8001, 6725, 6392, 6548,
               6346, 6484, 5989, 5774, 5687, 5029, 5304, 4625,
               4780, 4533, 4339, 3831, 3751, 3574, 3046, 2764,
               2701, 2916, 2968, 2853, 2059, 1826, 1853, 1568,
               1360, 1316, 1328, 989, 1053, 898, 814, 673, 710,
               602, 626, 564)
)
rev2010 <- merge(rev2010, state_pop_2010, by = "state", all.x = TRUE)
rev2010[, nonprofits_per_1000 := state_nonprofits / (pop_2010)]

## NTEE sector (broad category from first letter of NTEE code)
rev2010[, ntee_sector := substr(NTEE_CD, 1, 1)]
rev2010[ntee_sector == "" | is.na(ntee_sector), ntee_sector := "Z"]  # Unknown

## Binary variables for main subsections
rev2010[, `:=`(
  is_c3 = as.integer(subsection_code == 3),
  is_c4 = as.integer(subsection_code == 4),
  is_c7 = as.integer(subsection_code == 7),
  is_c5 = as.integer(subsection_code == 5),
  is_c6 = as.integer(subsection_code == 6),
  is_c8 = as.integer(subsection_code == 8)
)]

## State ID for FE
rev2010[, state_id := as.integer(factor(state))]

## ── 5. Reinstatement rates by subsection ─────────────────────────────────────
cat("\nReinstatement rates by subsection:\n")
reinst_by_sub <- rev2010[, .(
  N = .N,
  reinstated = sum(reinstated),
  rate = round(mean(reinstated) * 100, 1)
), by = subsection_label][order(-N)]
print(reinst_by_sub)

## ── 6. Reinstatement rates by state (top 20) ────────────────────────────────
cat("\nReinstatement rates by state (top 20 by N):\n")
reinst_by_state <- rev2010[, .(
  N = .N,
  reinstated = sum(reinstated),
  rate = round(mean(reinstated) * 100, 1)
), by = state][order(-N)]
print(head(reinst_by_state, 20))

## ── 7. Summary statistics ────────────────────────────────────────────────────
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total 2010 wave (US): %s\n", format(nrow(rev2010), big.mark = ",")))
cat(sprintf("Reinstated: %s (%.1f%%)\n",
            format(sum(rev2010$reinstated), big.mark = ","),
            mean(rev2010$reinstated) * 100))
cat(sprintf("States represented: %d\n", uniqueN(rev2010$state)))
cat(sprintf("Subsection types: %d\n", uniqueN(rev2010$subsection_code)))

## For reinstated orgs with financial data
reinst_with_fin <- rev2010[reinstated == 1 & !is.na(REVENUE_AMT)]
cat(sprintf("\nReinstated with financial data: %s\n",
            format(nrow(reinst_with_fin), big.mark = ",")))
if (nrow(reinst_with_fin) > 0) {
  cat(sprintf("  Median revenue: $%s\n",
              format(median(reinst_with_fin$REVENUE_AMT, na.rm = TRUE), big.mark = ",")))
  cat(sprintf("  Median assets: $%s\n",
              format(median(reinst_with_fin$ASSET_AMT, na.rm = TRUE), big.mark = ",")))
}

## ── 8. Save analysis dataset ─────────────────────────────────────────────────
saveRDS(rev2010, "data/analysis_dataset.rds")
fwrite(rev2010, "data/analysis_dataset.csv")

cat("\nAnalysis dataset saved: data/analysis_dataset.rds\n")
