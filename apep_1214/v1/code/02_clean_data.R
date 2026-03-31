## 02_clean_data.R — Construct municipality-wave panel for MCMV-IDEB analysis
## apep_1214: MCMV Housing and School Quality

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# Step 1: Load and clean MCMV OGU project data
# ============================================================
cat("=== Step 1: Clean MCMV OGU data ===\n")

mcmv <- fread(file.path(data_dir, "view_dados_abertos_ogu_202603201556.csv"),
              sep = ";", encoding = "Latin-1")
cat(sprintf("MCMV OGU raw: %d projects\n", nrow(mcmv)))

# Parse contract date and extract year
mcmv[, contract_date := as.Date(dt_assinatura, format = "%d/%m/%Y")]
mcmv[, contract_year := year(contract_date)]

# MCMV uses 6-digit IBGE codes (no check digit)
# IDEB uses 7-digit codes (with check digit)
# Match on 6-digit codes throughout
mcmv[, mun_id := as.character(cod_ibge)]

# Key variables: units contracted and delivered
mcmv[, units_contracted := as.numeric(qtd_uh)]
mcmv[, units_delivered := as.numeric(qtd_uh_entregues)]

cat(sprintf("Contract years: %d to %d\n",
            min(mcmv$contract_year, na.rm = TRUE),
            max(mcmv$contract_year, na.rm = TRUE)))
cat(sprintf("Total units contracted: %s\n",
            format(sum(mcmv$units_contracted, na.rm = TRUE), big.mark = ",")))
cat(sprintf("Total units delivered: %s\n",
            format(sum(mcmv$units_delivered, na.rm = TRUE), big.mark = ",")))

# Status breakdown
cat("\nProject status:\n")
print(mcmv[, .N, by = txt_situacao_empreendimento][order(-N)])

# Modality breakdown (FAR = fully subsidized Faixa 1)
cat("\nModality:\n")
print(mcmv[, .N, by = txt_modalidade][order(-N)])

# ============================================================
# Step 2: Construct municipality-level treatment variable
# ============================================================
cat("\n=== Step 2: Construct treatment variable ===\n")

# Focus on FAR modality (Faixa 1 — lowest income, lottery-allocated)
# FAR = Fundo de Arrendamento Residencial
mcmv_far <- mcmv[txt_modalidade == "FAR"]
cat(sprintf("FAR projects: %d (out of %d total)\n", nrow(mcmv_far), nrow(mcmv)))
cat(sprintf("FAR units contracted: %s\n",
            format(sum(mcmv_far$units_contracted, na.rm = TRUE), big.mark = ",")))

# Aggregate to municipality-year level
mun_year <- mcmv_far[!is.na(contract_year),
                      .(n_projects = .N,
                        total_units = sum(units_contracted, na.rm = TRUE),
                        delivered_units = sum(units_delivered, na.rm = TRUE)),
                      by = .(mun_id, contract_year)]

cat(sprintf("Municipality-years with FAR projects: %d\n", nrow(mun_year)))
cat(sprintf("Municipalities with any FAR project: %d\n", uniqueN(mun_year$mun_id)))

# Treatment: first year municipality received a FAR contract
first_treatment <- mun_year[, .(first_year = min(contract_year),
                                 cumul_units = sum(total_units)),
                             by = mun_id]

cat(sprintf("\nFirst treatment year distribution:\n"))
print(first_treatment[, .N, by = first_year][order(first_year)])

# Cumulative units at municipality level (for dose-response)
mun_cumul <- mcmv_far[!is.na(contract_year),
                       .(total_units_ever = sum(units_contracted, na.rm = TRUE)),
                       by = mun_id]

# ============================================================
# Step 3: Load and clean IDEB data
# ============================================================
cat("\n=== Step 3: Clean IDEB data ===\n")

ideb <- fread(file.path(data_dir, "ideb_municipality.csv"))
cat(sprintf("IDEB raw: %d rows\n", nrow(ideb)))

# Convert 7-digit IBGE codes to 6-digit (drop check digit) to match MCMV
ideb[, mun_id := substr(as.character(municipality_id), 1, 6)]

cat("Network types:\n")
print(ideb[, .N, by = network][order(-N)])

# "Pública" is the aggregate (all public), "Municipal"/"Estadual" are breakdowns
# Use "Pública" as the main public school panel (avoids double-counting)
# Use "Municipal" separately for mechanism tests (municipal schools bear the
# enrollment burden from MCMV residents more than state schools)
ideb_public <- ideb[network == "Pública",
                    .(ideb_score = mean(ideb, na.rm = TRUE),
                      n_schools = .N),
                    by = .(mun_id, year, stage)]

# Municipal-only panel (mechanism: municipal schools absorb MCMV residents)
ideb_municipal <- ideb[network == "Municipal",
                       .(ideb_score = mean(ideb, na.rm = TRUE),
                         n_schools = .N),
                       by = .(mun_id, year, stage)]

# State-only panel (placebo: state schools less affected by local MCMV)
ideb_state <- ideb[network == "Estadual",
                   .(ideb_score = mean(ideb, na.rm = TRUE),
                     n_schools = .N),
                   by = .(mun_id, year, stage)]

cat(sprintf("Public aggregate panel: %d obs, %d municipalities\n",
            nrow(ideb_public), uniqueN(ideb_public$mun_id)))
cat(sprintf("Municipal-only panel: %d obs, %d municipalities\n",
            nrow(ideb_municipal), uniqueN(ideb_municipal$mun_id)))
cat(sprintf("State-only panel: %d obs, %d municipalities\n",
            nrow(ideb_state), uniqueN(ideb_state$mun_id)))

# ============================================================
# Step 4: Merge IDEB with MCMV treatment
# ============================================================
cat("\n=== Step 4: Merge panels ===\n")

# Merge treatment timing
ideb_public <- merge(ideb_public, first_treatment, by = "mun_id", all.x = TRUE)
ideb_public <- merge(ideb_public, mun_cumul, by = "mun_id", all.x = TRUE)

# Treatment indicator: post-MCMV for treated municipalities
# Map IDEB biennial years to treatment timing
# A municipality is treated in IDEB year t if first_year <= t
ideb_public[, treated := fifelse(!is.na(first_year) & year >= first_year, 1L, 0L)]

# Never-treated municipalities (no MCMV FAR project)
ideb_public[is.na(first_year), first_year := 0L]  # Callaway-Sant'Anna convention

# Dose: log cumulative units (for treated municipalities)
ideb_public[, log_units := fifelse(total_units_ever > 0,
                                    log(total_units_ever), 0)]

# Time to treatment (for event study)
ideb_public[first_year > 0, rel_time := year - first_year]
ideb_public[first_year == 0, rel_time := NA_integer_]

cat(sprintf("Merged panel: %d obs\n", nrow(ideb_public)))
cat(sprintf("Treated municipalities: %d\n",
            uniqueN(ideb_public[first_year > 0]$mun_id)))
cat(sprintf("Never-treated municipalities: %d\n",
            uniqueN(ideb_public[first_year == 0]$mun_id)))

# Treatment timing distribution (mapped to IDEB waves)
cat("\nTreatment timing mapped to IDEB waves:\n")
treated_muns <- ideb_public[first_year > 0, .(first_year = first_year[1]), by = mun_id]
# Map first_year to nearest IDEB wave
ideb_waves <- c(2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023)
treated_muns[, first_wave := ideb_waves[findInterval(first_year, ideb_waves)]]
# For years before 2005, use 2005
treated_muns[first_wave < 2005 | is.na(first_wave), first_wave := 2005]
print(treated_muns[, .N, by = first_wave][order(first_wave)])

# Municipal-only panel (mechanism)
ideb_municipal <- merge(ideb_municipal, first_treatment, by = "mun_id", all.x = TRUE)
ideb_municipal <- merge(ideb_municipal, mun_cumul, by = "mun_id", all.x = TRUE)
ideb_municipal[, treated := fifelse(!is.na(first_year) & year >= first_year, 1L, 0L)]
ideb_municipal[is.na(first_year), first_year := 0L]
ideb_municipal[, log_units := fifelse(total_units_ever > 0, log(total_units_ever), 0)]

# State-only panel (placebo)
ideb_state <- merge(ideb_state, first_treatment, by = "mun_id", all.x = TRUE)
ideb_state <- merge(ideb_state, mun_cumul, by = "mun_id", all.x = TRUE)
ideb_state[, treated := fifelse(!is.na(first_year) & year >= first_year, 1L, 0L)]
ideb_state[is.na(first_year), first_year := 0L]

# ============================================================
# Step 5: Summary statistics
# ============================================================
cat("\n=== Step 5: Summary statistics ===\n")

cat("\nIDEB scores by treatment status (all years pooled):\n")
print(ideb_public[, .(mean_ideb = mean(ideb_score, na.rm = TRUE),
                       sd_ideb = sd(ideb_score, na.rm = TRUE),
                       n = .N),
                   by = .(treated)])

cat("\nIDEB scores by year and treatment status:\n")
print(ideb_public[, .(mean_ideb = round(mean(ideb_score, na.rm = TRUE), 2)),
                   by = .(year, treated)][order(year, treated)])

cat("\nIDEB scores by stage:\n")
print(ideb_public[, .(mean_ideb = round(mean(ideb_score, na.rm = TRUE), 2),
                       n = .N),
                   by = stage])

# ============================================================
# Save analysis datasets
# ============================================================
cat("\n=== Saving analysis datasets ===\n")

fwrite(ideb_public, file.path(data_dir, "panel_public.csv"))
fwrite(ideb_municipal, file.path(data_dir, "panel_municipal.csv"))
fwrite(ideb_state, file.path(data_dir, "panel_state.csv"))
fwrite(first_treatment, file.path(data_dir, "treatment_timing.csv"))
fwrite(mun_cumul, file.path(data_dir, "treatment_dosage.csv"))

cat("Saved: panel_public.csv, panel_municipal.csv, panel_state.csv, treatment_timing.csv, treatment_dosage.csv\n")
cat("Data cleaning complete.\n")
