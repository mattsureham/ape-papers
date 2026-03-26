## 02_clean_data.R — Build commune × election panel with EPCI merger treatment
## apep_0986: Forced EPCI Mergers and RN Voting

source("00_packages.R")
data_dir <- "../data"

## ============================================================================
## 1. Parse EPCI composition data — identify merger treatment
## ============================================================================
cat("\n=== Building EPCI merger treatment ===\n")

## 2016 pre-reform mapping (columns: reg, dep_com, insee, nom_com, ..., siren_epci, nom_epci, ...)
epci_2016 <- fread(file.path(data_dir, "epcicom2016.csv"), encoding = "Latin-1")
cat("2016 EPCI composition:", nrow(epci_2016), "rows,",
    length(unique(epci_2016$siren_epci)), "unique EPCIs\n")

## 2017 post-reform mapping (columns: CODGEO, LIBGEO, EPCI, LIBEPCI, DEP, REG)
epci_2017 <- fread(file.path(data_dir, "epcicom2017.csv"), encoding = "UTF-8")
cat("2017 EPCI composition:", nrow(epci_2017), "rows,",
    length(unique(epci_2017$EPCI)), "unique EPCIs\n")

## Standardize commune codes (zero-pad to 5 digits, handle Corsica 2A/2B)
pad_commune <- function(x) {
  x <- as.character(x)
  ## Corsica: codes like 2A001, 2B001 — already 5 chars
  ifelse(grepl("^[0-9]+$", x), sprintf("%05d", as.integer(x)), x)
}
epci_2016[, code_commune := pad_commune(insee)]
epci_2017[, code_commune := pad_commune(CODGEO)]

## Standardize EPCI codes to character
epci_2016[, siren_epci := as.character(siren_epci)]
epci_2017[, EPCI := as.character(EPCI)]

## Get EPCI population from the 2016 file (ptot_epci) and 2017 file
## For 2016: ptot_epci is the total population of the EPCI
## We need to compute 2017 EPCI population by aggregating commune populations
epci_pop_2016 <- unique(epci_2016[, .(siren_epci, epci_pop_2016 = as.numeric(ptot_epci))],
                                  by = "siren_epci")

## For 2017, compute EPCI population by summing commune populations
## (since geo API gave same data for both dates, use composition file)
epcis_2017_dt <- fread(file.path(data_dir, "epcis_2017.csv"))
epcis_2017_dt[, code := as.character(code)]

## Get unique 2017 EPCI populations
epci_pop_2017 <- unique(epcis_2017_dt[, .(EPCI = code, epci_pop_2017 = population)],
                        by = "EPCI")

## Build commune-level treatment variable
## Merge 2016 and 2017 EPCI assignments at commune level
merger_dt <- merge(
  epci_2016[, .(code_commune, epci_2016 = siren_epci, epci_name_2016 = nom_epci,
                dep = dep_com, pop_commune = as.numeric(pmun))],
  epci_2017[, .(code_commune, epci_2017 = EPCI, epci_name_2017 = LIBEPCI)],
  by = "code_commune",
  all = FALSE
)

cat("Merged commune data:", nrow(merger_dt), "communes\n")

## Treatment: whether the commune's EPCI changed
merger_dt[, epci_changed := epci_2016 != epci_2017]
cat("Communes with EPCI change:", sum(merger_dt$epci_changed), "\n")
cat("Communes unchanged:", sum(!merger_dt$epci_changed), "\n")

## Treatment intensity: log(post-merger EPCI pop / pre-merger EPCI pop)
## Get EPCI populations
## 2016 EPCI pop from the composition file
epci_16_pop <- epci_2016[, .(epci_pop_2016 = as.numeric(ptot_epci[1])),
                          by = .(siren_epci)]
## 2017 EPCI pop from the geo API data
epci_17_pop <- epcis_2017_dt[, .(epci_pop_2017 = population), by = .(code)]

merger_dt <- merge(merger_dt,
                   epci_pop_2016[, .(epci_2016 = siren_epci, epci_pop_2016)],
                   by = "epci_2016", all.x = TRUE)
merger_dt <- merge(merger_dt,
                   epci_pop_2017,
                   by.x = "epci_2017", by.y = "EPCI", all.x = TRUE)

## Compute treatment intensity
merger_dt[, merger_intensity := fifelse(
  epci_changed & !is.na(epci_pop_2017) & !is.na(epci_pop_2016) &
    epci_pop_2016 > 0 & epci_pop_2017 > 0,
  log(epci_pop_2017 / epci_pop_2016),
  0
)]

cat("\nTreatment intensity distribution (for changed communes):\n")
print(summary(merger_dt[epci_changed == TRUE, merger_intensity]))

## Extract département code (first 2-3 characters of code_commune)
merger_dt[, dep := substr(code_commune, 1, 2)]
merger_dt[substr(code_commune, 1, 2) == "97", dep := substr(code_commune, 1, 3)]

## ============================================================================
## 2. Parse election data — extract FN/RN vote share by commune
## ============================================================================
cat("\n=== Parsing election data ===\n")

## ---------- Helper function for wide-format election files (2007, 2012, 2017) ----------
parse_wide_election <- function(file, year, skip_rows = 0) {
  cat(sprintf("  Parsing %d (%s, skip=%d)...\n", year, basename(file), skip_rows))

  ## Read the full sheet
  if (grepl("\\.xls$", file)) {
    sheet <- ifelse(year == 2017, 1, 1)
    df <- read_xls(file, sheet = sheet, skip = skip_rows, col_names = TRUE,
                   .name_repair = "unique_quiet")
  } else {
    df <- read_xlsx(file, sheet = 1, skip = skip_rows, col_names = TRUE,
                    .name_repair = "unique_quiet")
  }

  ## Standardize column names to lowercase
  cn <- tolower(names(df))

  ## Find department and commune code columns
  dep_col <- which(grepl("code.*(d.p|dep)", cn))[1]
  com_col <- which(grepl("code.*(commune|com)", cn))[1]
  inscrits_col <- which(grepl("^inscrits$", cn))[1]
  exprimes_col <- which(grepl("exprim", cn))[1]

  if (is.na(dep_col) || is.na(com_col)) {
    stop(sprintf("Could not find dept/commune columns in %d file", year))
  }

  ## Find all "Nom" columns (candidate name columns)
  nom_cols <- which(grepl("^nom", cn))

  if (length(nom_cols) == 0) {
    stop(sprintf("Could not find candidate 'Nom' columns in %d file", year))
  }

  ## For each candidate: find Nom, and corresponding Voix column
  ## The Voix column is typically 2 positions after Nom (Nom, Prénom, Voix)
  ## or look for "voix" columns
  voix_cols <- which(grepl("^voix", cn))

  ## Find LE PEN candidate
  le_pen_voix <- NULL
  for (i in seq_along(nom_cols)) {
    nom_col_idx <- nom_cols[i]
    candidate_names <- toupper(as.character(df[[nom_col_idx]]))
    candidate_names <- candidate_names[!is.na(candidate_names)]

    if (any(grepl("LE PEN", candidate_names))) {
      ## The corresponding Voix column should be nearby
      if (i <= length(voix_cols)) {
        le_pen_voix <- voix_cols[i]
      }
      cat(sprintf("    Found LE PEN in column %d (%s), voix in column %d\n",
                  nom_col_idx, cn[nom_col_idx], le_pen_voix))
      break
    }
  }

  if (is.null(le_pen_voix)) {
    stop(sprintf("Could not find LE PEN candidate in %d file", year))
  }

  ## Build output
  result <- data.table(
    dep_code = as.character(df[[dep_col]]),
    com_code = as.character(df[[com_col]]),
    inscrits = as.numeric(df[[inscrits_col]]),
    exprimes = as.numeric(df[[exprimes_col]]),
    fn_voix  = as.numeric(df[[le_pen_voix]])
  )

  ## Build proper commune code (dep + com padded to 3 digits)
  ## Handle Corsica (2A, 2B)
  result[, dep_code := as.character(dep_code)]
  result[, dep_code := ifelse(grepl("^[0-9]+$", dep_code),
                              sprintf("%02d", as.integer(dep_code)), dep_code)]
  result[, com_code := sprintf("%03d", as.integer(com_code))]
  result[, code_commune := paste0(dep_code, com_code)]

  ## Remove rows with missing commune codes or zero expressed
  result <- result[!is.na(exprimes) & exprimes > 0 & !is.na(fn_voix)]
  result[, fn_share := fn_voix / exprimes * 100]
  result[, year := year]

  cat(sprintf("    %d communes, mean FN share: %.1f%%\n", nrow(result), mean(result$fn_share)))
  result[, .(code_commune, year, inscrits, exprimes, fn_voix, fn_share)]
}

## ---------- Parse 2022 (long-format CSV) ----------
parse_2022 <- function(file) {
  cat("  Parsing 2022 (CSV long format)...\n")
  dt <- fread(file, encoding = "UTF-8")

  ## Filter for LE PEN
  le_pen <- dt[toupper(cand_nom) == "LE PEN"]
  cat(sprintf("    LE PEN rows: %d\n", nrow(le_pen)))

  ## Build commune code: dep_code (2-3 chars) + commune_code (3 chars)
  le_pen[, dep_padded := sprintf("%02s", as.character(dep_code_min))]
  le_pen[, code_commune := paste0(dep_padded, sprintf("%03d", as.integer(commune_code)))]

  result <- le_pen[, .(
    code_commune,
    year = 2022L,
    inscrits = as.numeric(inscrits_nb),
    exprimes = as.numeric(exprimes_nb),
    fn_voix = as.numeric(cand_nb_voix),
    fn_share = as.numeric(cand_rapport_exprim)
  )]

  result <- result[!is.na(exprimes) & exprimes > 0]
  cat(sprintf("    %d communes, mean FN share: %.1f%%\n", nrow(result), mean(result$fn_share)))
  result
}

## ---------- Parse all elections ----------
elections <- list()

## 2007
elections[["2007"]] <- parse_wide_election(
  file.path(data_dir, "election_presidentielle_2007.xls"), 2007
)

## 2012
elections[["2012"]] <- parse_wide_election(
  file.path(data_dir, "election_presidentielle_2012.xls"), 2012
)

## 2017 (skip 3 header rows)
elections[["2017"]] <- parse_wide_election(
  file.path(data_dir, "election_presidentielle_2017.xls"), 2017, skip_rows = 3
)

## 2022
elections[["2022"]] <- parse_2022(
  file.path(data_dir, "election_presidentielle_2022.csv")
)

## Combine
election_panel <- rbindlist(elections)
cat(sprintf("\nCombined panel: %d commune-year observations across %d elections\n",
            nrow(election_panel), length(unique(election_panel$year))))

## ============================================================================
## 3. Build analysis panel — merge elections with EPCI merger treatment
## ============================================================================
cat("\n=== Building analysis panel ===\n")

## Merge election data with merger treatment
panel <- merge(
  election_panel,
  merger_dt[, .(code_commune, epci_changed, merger_intensity, dep,
                pop_commune, epci_2016, epci_2017, epci_pop_2016, epci_pop_2017)],
  by = "code_commune",
  all.x = FALSE  # inner join — keep only communes with EPCI data
)

## Treatment indicator: post-reform period × EPCI change
panel[, post := as.integer(year >= 2017)]
panel[, treated := as.integer(epci_changed)]
panel[, treat_post := treated * post]
panel[, intensity_post := merger_intensity * post]

## Create numeric election period for FE
panel[, election_id := match(year, sort(unique(year)))]

cat(sprintf("Analysis panel: %d observations (%d communes × %d elections)\n",
            nrow(panel), length(unique(panel$code_commune)), length(unique(panel$year))))
cat(sprintf("Treated communes: %d\n", length(unique(panel[treated == 1, code_commune]))))
cat(sprintf("Control communes: %d\n", length(unique(panel[treated == 0, code_commune]))))
cat(sprintf("Pre-treatment elections: %s\n", paste(sort(unique(panel[post == 0, year])), collapse = ", ")))
cat(sprintf("Post-treatment elections: %s\n", paste(sort(unique(panel[post == 1, year])), collapse = ", ")))

## ============================================================================
## 4. Summary statistics
## ============================================================================
cat("\n=== Summary Statistics ===\n")

sumstats <- panel[, .(
  mean_fn_share = mean(fn_share, na.rm = TRUE),
  sd_fn_share = sd(fn_share, na.rm = TRUE),
  mean_turnout = mean(exprimes / inscrits * 100, na.rm = TRUE),
  n_obs = .N,
  n_communes = uniqueN(code_commune)
), by = .(treated, post)]

print(sumstats)

cat("\nMerger intensity (treated communes only):\n")
print(summary(panel[treated == 1 & post == 0, merger_intensity]))

## ============================================================================
## 5. Save analysis panel
## ============================================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved:", file.path(data_dir, "analysis_panel.csv"), "\n")

## Also save merger treatment data for reference
fwrite(merger_dt, file.path(data_dir, "merger_treatment.csv"))
cat("Merger treatment data saved:", file.path(data_dir, "merger_treatment.csv"), "\n")
