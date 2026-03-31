## 02_clean_data.R — Parse Fondo Minero PDF, build analysis panel
## apep_1222: When the Mine Money Stops

source("00_packages.R")

data_dir <- "../data"

## ---- 1. Parse Fondo Minero PDF ----
cat("Parsing Fondo Minero PDF...\n")
pdf_text_raw <- pdf_text(file.path(data_dir, "fondo_minero_2017.pdf"))

# Known Mexican state names that appear in the Fondo Minero PDF
state_names <- c("AGUASCALIENTES", "BAJA CALIFORNIA SUR", "BAJA CALIFORNIA",
                 "CAMPECHE", "CHIHUAHUA", "COAHUILA", "COLIMA", "DURANGO",
                 "GUANAJUATO", "GUERRERO", "HIDALGO", "JALISCO",
                 "MÉXICO", "MEXICO", "MICHOACÁN", "MICHOACAN",
                 "MORELOS", "NAYARIT", "NUEVO LEÓN", "NUEVO LEON",
                 "OAXACA", "PUEBLA", "QUERÉTARO", "QUERETARO",
                 "SAN LUIS POTOSÍ", "SAN LUIS POTOSI",
                 "SINALOA", "SONORA", "TAMAULIPAS",
                 "VERACRUZ", "YUCATÁN", "YUCATAN", "ZACATECAS")

# Parse each page
fm_records <- list()
current_state <- NA

for (page_text in pdf_text_raw) {
  lines <- strsplit(page_text, "\n")[[1]]
  lines <- trimws(lines)
  lines <- lines[nchar(lines) > 0]

  for (line in lines) {
    # Skip header lines
    if (grepl("SEDATU|Coeficiente|ENTIDAD FEDERATIVA|COEFICIENTE", line)) next

    # Extract name and amount
    # Pattern: NAME followed by NUMBER (with commas and decimals)
    m <- regmatches(line, regexec("^(.+?)\\s{2,}([0-9,]+\\.\\d+)\\s*$", line))[[1]]
    if (length(m) < 3) next

    name <- trimws(m[2])
    amount <- as.numeric(gsub(",", "", m[3]))

    # Normalize name for comparison
    name_norm <- stri_trans_general(toupper(name), "Latin-ASCII")

    # Check if this is a state header
    is_state <- any(sapply(state_names, function(s) {
      stri_trans_general(s, "Latin-ASCII") == name_norm
    }))

    if (is_state) {
      current_state <- name
      next
    }

    # Skip state government lines and total
    if (grepl("GOBIERNO DEL ESTADO|^TOTAL$", name_norm)) next

    # This is a municipality record
    if (!is.na(current_state)) {
      fm_records[[length(fm_records) + 1]] <- data.frame(
        state = current_state,
        municipality = name,
        allocation_2017 = amount,
        stringsAsFactors = FALSE
      )
    }
  }
}

fm_munis <- bind_rows(fm_records)
cat(sprintf("  Extracted %d Fondo Minero municipalities across %d states\n",
            nrow(fm_munis), length(unique(fm_munis$state))))
stopifnot("Too few FM municipalities extracted" = nrow(fm_munis) >= 200)

## ---- 2. Match to INEGI CVE_MUN codes ----
cat("Matching Fondo Minero municipalities to INEGI codes...\n")

# Load catalogue
catalogue <- fread(file.path(data_dir, "inegi_catalogue.csv"),
                   select = c("CVE_ENT", "NOM_ENT", "CVE_MUN", "NOM_MUN"),
                   colClasses = c(CVE_ENT = "character", CVE_MUN = "character"))
catalogue <- unique(catalogue)
# Ensure proper zero-padding (CVE_ENT = 2 digits, CVE_MUN = 3 digits)
catalogue[, CVE_ENT := sprintf("%02d", as.integer(CVE_ENT))]
catalogue[, CVE_MUN := sprintf("%03d", as.integer(CVE_MUN))]
catalogue[, full_cve := paste0(CVE_ENT, CVE_MUN)]
cat(sprintf("  Sample catalogue codes: %s, %s, %s\n",
            catalogue$full_cve[1], catalogue$full_cve[100], catalogue$full_cve[500]))

# Normalize function: remove accents, uppercase, trim
normalize_name <- function(x) {
  x <- toupper(trimws(x))
  x <- stri_trans_general(x, "Latin-ASCII")
  x <- gsub("[^A-Z ]", "", x)  # keep only letters and spaces
  x <- gsub("\\s+", " ", x)    # collapse multiple spaces
  trimws(x)
}

catalogue[, nom_ent_norm := normalize_name(NOM_ENT)]
catalogue[, nom_mun_norm := normalize_name(NOM_MUN)]

fm_munis$state_norm <- normalize_name(fm_munis$state)
fm_munis$muni_norm <- normalize_name(fm_munis$municipality)

# Merge by normalized state + municipality name
fm_munis_dt <- as.data.table(fm_munis)
matched <- merge(fm_munis_dt, catalogue,
                 by.x = c("state_norm", "muni_norm"),
                 by.y = c("nom_ent_norm", "nom_mun_norm"),
                 all.x = TRUE)

# Check match rate
n_matched <- sum(!is.na(matched$full_cve))
cat(sprintf("  Matched %d / %d municipalities (%.1f%%)\n",
            n_matched, nrow(fm_munis), 100 * n_matched / nrow(fm_munis)))

# Try fuzzy matching for unmatched
unmatched <- matched[is.na(full_cve)]
if (nrow(unmatched) > 0) {
  cat(sprintf("  Attempting fuzzy match for %d unmatched municipalities...\n",
              nrow(unmatched)))
  for (i in seq_len(nrow(unmatched))) {
    st <- unmatched$state_norm[i]
    mn <- unmatched$muni_norm[i]
    # Get all municipalities in the same state
    state_munis <- catalogue[nom_ent_norm == st]
    if (nrow(state_munis) == 0) next
    # Compute string distances
    dists <- stringdist::stringdist(mn, state_munis$nom_mun_norm, method = "jw")
    best_idx <- which.min(dists)
    if (dists[best_idx] < 0.15) {  # threshold for fuzzy match
      matched[state_norm == st & muni_norm == mn,
              `:=`(full_cve = state_munis$full_cve[best_idx],
                   CVE_ENT = state_munis$CVE_ENT[best_idx],
                   CVE_MUN = state_munis$CVE_MUN[best_idx],
                   NOM_ENT = state_munis$NOM_ENT[best_idx],
                   NOM_MUN = state_munis$NOM_MUN[best_idx])]
    }
  }
  n_matched2 <- sum(!is.na(matched$full_cve))
  cat(sprintf("  After fuzzy matching: %d / %d (%.1f%%)\n",
              n_matched2, nrow(fm_munis), 100 * n_matched2 / nrow(fm_munis)))
}

# Final treatment municipality list
treatment_munis <- matched[!is.na(full_cve), .(full_cve, state, municipality, allocation_2017)]
treatment_munis <- unique(treatment_munis, by = "full_cve")
cat(sprintf("  Final treatment set: %d municipalities with CVE_MUN codes\n",
            nrow(treatment_munis)))
stopifnot("Too few treatment municipalities matched" = nrow(treatment_munis) >= 150)

## ---- 3. Build analysis panel ----
cat("Building analysis panel...\n")

# Load SESNSP crime data
crime <- fread(file.path(data_dir, "sesnsp_municipal.csv"))
setnames(crime, c("AÑO", "CVE_MUN", "DELITO", "TOTAL"),
         c("year", "cve_mun", "crime_type", "count"))

# Pad CVE_MUN to 5 digits
crime[, cve_mun := sprintf("%05d", as.integer(cve_mun))]
cat(sprintf("  Sample SESNSP codes: %s, %s, %s\n",
            crime$cve_mun[1], crime$cve_mun[1000], crime$cve_mun[5000]))
cat(sprintf("  Treatment CVE codes sample: %s\n",
            paste(head(treatment_munis$full_cve, 5), collapse = ", ")))

# Classify crime types into categories
crime[, crime_cat := fcase(
  grepl("Homicidio doloso", crime_type, ignore.case = TRUE), "homicide",
  grepl("Extorsi", crime_type, ignore.case = TRUE), "extortion",
  grepl("^Robo", crime_type, ignore.case = TRUE), "robbery",
  grepl("Violencia familiar", crime_type, ignore.case = TRUE), "domestic_violence",
  default = "other"
)]

# Aggregate: total crimes per municipality × year
total_crime <- crime[, .(total_crime = sum(count, na.rm = TRUE)),
                     by = .(cve_mun, year)]

# Aggregate by category
crime_by_cat <- crime[, .(count = sum(count, na.rm = TRUE)),
                      by = .(cve_mun, year, crime_cat)]
crime_wide <- dcast(crime_by_cat, cve_mun + year ~ crime_cat,
                    value.var = "count", fill = 0)

# Merge total and category
panel <- merge(total_crime, crime_wide, by = c("cve_mun", "year"), all.x = TRUE)

# Add treatment indicator
panel[, mining := as.integer(cve_mun %in% treatment_munis$full_cve)]

# Add post indicator (treatment = Nov 2020, so post starts 2021)
panel[, post := as.integer(year >= 2021)]

# Create state variable (first 2 digits of CVE_MUN)
panel[, state_code := substr(cve_mun, 1, 2)]

# Filter to analysis window (2015-2025)
panel <- panel[year >= 2015 & year <= 2025]

# Create outcome variables
panel[, log_total := log(total_crime + 1)]
panel[, log_homicide := log(homicide + 1)]
panel[, log_robbery := log(robbery + 1)]
panel[, log_extortion := log(extortion + 1)]
panel[, log_dv := log(domestic_violence + 1)]

# Add treatment intensity (allocation per municipality)
panel <- merge(panel, treatment_munis[, .(full_cve, allocation_2017)],
               by.x = "cve_mun", by.y = "full_cve", all.x = TRUE)
panel[is.na(allocation_2017), allocation_2017 := 0]
panel[, log_allocation := log(allocation_2017 + 1)]

cat(sprintf("  Panel: %s observations, %d municipalities, %d years\n",
            format(nrow(panel), big.mark = ","),
            length(unique(panel$cve_mun)),
            length(unique(panel$year))))
cat(sprintf("  Treatment: %d mining municipalities, %d control municipalities\n",
            length(unique(panel[mining == 1]$cve_mun)),
            length(unique(panel[mining == 0]$cve_mun))))

## ---- 4. Summary statistics ----
cat("Computing summary statistics...\n")
summary_stats <- panel[, .(
  mean_total = mean(total_crime, na.rm = TRUE),
  sd_total = sd(total_crime, na.rm = TRUE),
  mean_homicide = mean(homicide, na.rm = TRUE),
  sd_homicide = sd(homicide, na.rm = TRUE),
  mean_robbery = mean(robbery, na.rm = TRUE),
  sd_robbery = sd(robbery, na.rm = TRUE),
  mean_extortion = mean(extortion, na.rm = TRUE),
  sd_extortion = sd(extortion, na.rm = TRUE),
  mean_dv = mean(domestic_violence, na.rm = TRUE),
  sd_dv = sd(domestic_violence, na.rm = TRUE),
  n_obs = .N,
  n_munis = uniqueN(cve_mun)
), by = mining]

print(summary_stats)

## ---- 5. Save ----
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
fwrite(treatment_munis, file.path(data_dir, "treatment_municipalities.csv"))
cat("Panel saved to data/analysis_panel.rds\n")
cat("Treatment municipalities saved to data/treatment_municipalities.csv\n")
