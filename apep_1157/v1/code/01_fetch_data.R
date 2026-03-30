## 01_fetch_data.R — Fetch INEGI death microdata and construct municipality-year panel
## apep_1157: Seguro Popular and Cause-Specific Infant Mortality

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# PART 1: Download INEGI death microdata (1998-2012)
# ============================================================
# Source: Secretaria de Salud via datos.gob.mx repository
# Each file ~60-120MB CSV with individual death records

base_url <- "https://repodatos.atdt.gob.mx/all_data/secretaria_salud/6fecbbb3-afd9-44a1-8665-679a80ce4a15/defunciones_registradas_"

cat("Downloading and processing INEGI death microdata (1998-2012)...\n")

all_deaths <- list()

for (yr in 1998:2012) {
  fname <- file.path(data_dir, paste0("deaths_", yr, ".csv"))
  url <- paste0(base_url, yr, ".csv")

  # Download if not cached
  if (!file.exists(fname)) {
    cat(sprintf("  Downloading %d...\n", yr))
    resp <- tryCatch(
      download.file(url, fname, mode = "wb", quiet = TRUE),
      error = function(e) stop(sprintf("FATAL: Failed to download %d: %s", yr, e$message))
    )
    if (resp != 0) stop(sprintf("FATAL: Download failed for %d", yr))
  }

  fsize <- file.info(fname)$size
  if (is.na(fsize) || fsize < 1000) {
    stop(sprintf("FATAL: File for %d is empty or corrupt (%s bytes)", yr, fsize))
  }

  # Read CSV — only needed columns
  dt <- fread(fname, select = c("ENT_RESID", "MUN_RESID", "EDAD", "CAUSA_DEF"),
              colClasses = "character", showProgress = FALSE)

  total_n <- nrow(dt)

  # Parse EDAD coding: digit 1 = unit (1=hours, 2=days, 3=months, 4=years, 9=unknown)
  dt[, age_unit := substr(EDAD, 1, 1)]
  dt[, age_val  := as.integer(substr(EDAD, 2, 4))]

  # Infant: age < 1 year
  dt[, is_infant := (age_unit == "1") |
       (age_unit == "2") |
       (age_unit == "3" & age_val < 12) |
       (age_unit == "4" & age_val == 0)]

  # Neonatal: age < 28 days
  dt[, is_neonatal := (age_unit == "1") |
       (age_unit == "2" & age_val < 28)]

  # Municipality ID (5-digit: 2-digit state + 3-digit municipality)
  dt[, mun_id := paste0(
    str_pad(ENT_RESID, 2, pad = "0"),
    str_pad(MUN_RESID, 3, pad = "0")
  )]

  # ICD-10 classification for infant deaths
  dt[, icd3 := substr(CAUSA_DEF, 1, 3)]
  dt[, icd1 := substr(CAUSA_DEF, 1, 1)]

  dt[is_infant == TRUE, cause_group := fcase(
    icd1 == "P", "amenable",
    icd3 >= "A00" & icd3 <= "A09", "amenable",
    icd3 >= "J00" & icd3 <= "J22", "amenable",
    icd3 >= "A33" & icd3 <= "A37", "amenable",
    icd1 == "Q", "non_amenable",
    icd1 %in% c("V", "W", "X", "Y"), "non_amenable",
    default = "other"
  )]

  # Aggregate to municipality-year
  mun_agg <- dt[, .(
    total_deaths = .N,
    infant_deaths = sum(is_infant, na.rm = TRUE),
    neonatal_deaths = sum(is_infant & is_neonatal, na.rm = TRUE),
    amenable_deaths = sum(is_infant & cause_group == "amenable", na.rm = TRUE),
    non_amenable_deaths = sum(is_infant & cause_group == "non_amenable", na.rm = TRUE),
    diarrheal_deaths = sum(is_infant & icd3 >= "A00" & icd3 <= "A09", na.rm = TRUE),
    respiratory_deaths = sum(is_infant & icd3 >= "J00" & icd3 <= "J22", na.rm = TRUE),
    perinatal_deaths = sum(is_infant & icd1 == "P", na.rm = TRUE),
    congenital_deaths = sum(is_infant & icd1 == "Q", na.rm = TRUE)
  ), by = mun_id]

  mun_agg[, year := as.integer(yr)]

  all_deaths[[as.character(yr)]] <- mun_agg

  cat(sprintf("  %d: %d total deaths, %d infant, %d neonatal (%.1f MB)\n",
              yr, total_n, sum(mun_agg$infant_deaths),
              sum(mun_agg$neonatal_deaths), fsize / 1e6))

  rm(dt)
  gc(verbose = FALSE)
}

panel <- rbindlist(all_deaths)

# ============================================================
# PART 2: Population denominators
# ============================================================
# SINAC birth microdata only available from 2008. For 1998-2012 panel,
# we use total deaths as a population proxy and compute infant deaths
# per 1,000 total deaths. This is a standard approach when birth
# registration is incomplete (see Bhalotra & Rawlings 2011; Pfutze 2014).
#
# Rationale: total deaths in a municipality is proportional to its
# population. Municipality and year FE absorb level differences.
# The infant share of mortality is directly policy-relevant.
#
# We also estimate models using log(infant_deaths + 1) as outcome,
# which gives semi-elasticity interpretation with municipality FE.
#
# Additionally, we construct approximate live births using Mexico's
# national crude birth rate (INEGI published) × estimated population.

# National crude birth rate per 1,000 (INEGI Vital Statistics Yearbook)
cbr <- data.table(
  year = 1998:2012,
  cbr_national = c(22.3, 21.5, 21.1, 20.6, 20.1, 19.7, 19.2,
                   18.8, 18.3, 17.9, 17.8, 17.6, 17.4, 17.2, 17.1)
)

# National crude death rate per 1,000 (INEGI)
cdr <- data.table(
  year = 1998:2012,
  cdr_national = c(4.4, 4.4, 4.4, 4.4, 4.5, 4.5, 4.6,
                   4.7, 4.8, 4.9, 5.0, 5.1, 5.2, 5.3, 5.4)
)

# Estimate municipal population from total deaths and national CDR
panel <- merge(panel, cbr, by = "year")
panel <- merge(panel, cdr, by = "year")

# estimated_pop = total_deaths / (CDR / 1000)
panel[, est_pop := total_deaths / (cdr_national / 1000)]

# estimated live births = est_pop * (CBR / 1000)
panel[, est_births := est_pop * (cbr_national / 1000)]

# Construct mortality rates
panel[, imr := (infant_deaths / est_births) * 1000]
panel[, nmr := (neonatal_deaths / est_births) * 1000]
panel[, amenable_mr := (amenable_deaths / est_births) * 1000]
panel[, non_amenable_mr := (non_amenable_deaths / est_births) * 1000]

# Alternative: infant deaths per 1,000 total deaths (no estimation needed)
panel[, infant_share := (infant_deaths / total_deaths) * 1000]
panel[, amenable_share := (amenable_deaths / total_deaths) * 1000]
panel[, non_amenable_share := (non_amenable_deaths / total_deaths) * 1000]

# Log outcomes
panel[, log_infant := log(infant_deaths + 1)]
panel[, log_amenable := log(amenable_deaths + 1)]
panel[, log_non_amenable := log(non_amenable_deaths + 1)]

# ============================================================
# PART 3: Seguro Popular enrollment by state
# ============================================================
# Treatment timing from published SP administrative records:
# CNPSS Annual Reports, Pfutze (2014, World Development),
# King et al. (2009, Lancet), and Frenk et al. (2006, Lancet)

sp_states <- data.table(
  state_code = sprintf("%02d", 1:32),
  sp_first_year = c(
    2002L,  # 01 Aguascalientes (pilot)
    2004L,  # 02 Baja California
    2004L,  # 03 Baja California Sur
    2002L,  # 04 Campeche (pilot)
    2003L,  # 05 Coahuila
    2002L,  # 06 Colima (pilot)
    2003L,  # 07 Chiapas
    2004L,  # 08 Chihuahua
    2005L,  # 09 CDMX
    2004L,  # 10 Durango
    2003L,  # 11 Guanajuato
    2003L,  # 12 Guerrero
    2003L,  # 13 Hidalgo
    2002L,  # 14 Jalisco (pilot)
    2003L,  # 15 Mexico
    2004L,  # 16 Michoacan
    2003L,  # 17 Morelos
    2003L,  # 18 Nayarit
    2004L,  # 19 Nuevo Leon
    2003L,  # 20 Oaxaca
    2004L,  # 21 Puebla
    2003L,  # 22 Queretaro
    2003L,  # 23 Quintana Roo
    2003L,  # 24 San Luis Potosi
    2003L,  # 25 Sinaloa
    2003L,  # 26 Sonora
    2002L,  # 27 Tabasco (pilot)
    2003L,  # 28 Tamaulipas
    2003L,  # 29 Tlaxcala
    2003L,  # 30 Veracruz
    2003L,  # 31 Yucatan
    2004L   # 32 Zacatecas
  )
)

# Add state code to panel
panel[, state_code := substr(mun_id, 1, 2)]

# Merge SP enrollment
panel <- merge(panel, sp_states, by = "state_code", all.x = TRUE)

# Treatment variables for CS-DiD
panel[, first_treat := sp_first_year]
panel[, treated := as.integer(year >= sp_first_year)]

# Numeric IDs for did package
panel[, mun_num := as.integer(factor(mun_id))]

# Drop very small municipalities (< 50 total deaths/year on average)
# These have extremely noisy mortality rates
mun_mean_deaths <- panel[, .(mean_deaths = mean(total_deaths)), by = mun_id]
small_muns <- mun_mean_deaths[mean_deaths < 50, mun_id]
cat(sprintf("Dropping %d municipalities with < 50 mean annual deaths\n",
            length(small_muns)))
panel <- panel[!(mun_id %in% small_muns)]

# ============================================================
# PART 4: Save and validate
# ============================================================
fwrite(panel, file.path(data_dir, "panel.csv"))

cat("\n=== DATA VALIDATION ===\n")
cat(sprintf("Municipality-year observations: %d\n", nrow(panel)))
cat(sprintf("Unique municipalities: %d\n", length(unique(panel$mun_id))))
cat(sprintf("Year range: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Total infant deaths: %s\n", format(sum(panel$infant_deaths), big.mark = ",")))

cat("\nSP cohort distribution (municipalities):\n")
cohort_tab <- panel[year == 2005, .N, by = first_treat][order(first_treat)]
print(cohort_tab)

cat("\nMean outcomes by period:\n")
pre <- panel[year < 2002]
post <- panel[year >= 2005]
cat(sprintf("  Pre-SP  (1998-2001): Mean IMR = %.1f, Mean amenable MR = %.1f, Mean non-amenable MR = %.1f\n",
            mean(pre$imr, na.rm = TRUE), mean(pre$amenable_mr, na.rm = TRUE),
            mean(pre$non_amenable_mr, na.rm = TRUE)))
cat(sprintf("  Post-SP (2005-2012): Mean IMR = %.1f, Mean amenable MR = %.1f, Mean non-amenable MR = %.1f\n",
            mean(post$imr, na.rm = TRUE), mean(post$amenable_mr, na.rm = TRUE),
            mean(post$non_amenable_mr, na.rm = TRUE)))

cat("\nInfant deaths by cause group (all years):\n")
total_inf <- sum(panel$infant_deaths)
cat(sprintf("  Amenable:     %s (%.1f%%)\n",
            format(sum(panel$amenable_deaths), big.mark = ","),
            100 * sum(panel$amenable_deaths) / total_inf))
cat(sprintf("  Non-amenable: %s (%.1f%%)\n",
            format(sum(panel$non_amenable_deaths), big.mark = ","),
            100 * sum(panel$non_amenable_deaths) / total_inf))
cat(sprintf("  Other:        %s (%.1f%%)\n",
            format(total_inf - sum(panel$amenable_deaths) - sum(panel$non_amenable_deaths), big.mark = ","),
            100 * (total_inf - sum(panel$amenable_deaths) - sum(panel$non_amenable_deaths)) / total_inf))

cat("\nData fetch complete.\n")
