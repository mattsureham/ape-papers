## 02_clean_data.R — Construct agency-quarter panel
## apep_0942: Dominican Republic MIPYME Procurement Set-Asides

source("00_packages.R")

data_dir <- "../data"
adj <- readRDS(file.path(data_dir, "adjudicaciones.rds"))
proc <- readRDS(file.path(data_dir, "procesos.rds"))
prov <- readRDS(file.path(data_dir, "proveedores.rds"))

## ============================================================
## 1. Clean PROCESOS — extract agency, date, MIPYME flag
## ============================================================

proc[, fecha := as.Date(FECHA_PUBLICACION, format = "%m/%d/%Y")]
# Try alternate date format if first fails
if (sum(is.na(proc$fecha)) > nrow(proc) * 0.5) {
  proc[, fecha := as.Date(FECHA_PUBLICACION, format = "%d/%m/%Y")]
}
proc <- proc[!is.na(fecha)]
proc[, year := year(fecha)]
proc[, quarter := quarter(fecha)]
proc[, yq := paste0(year, "Q", quarter)]

# Agency identifier — use numeric code as character
proc[, agency := as.character(CODIGO_UNIDAD_COMPRA)]

# Extract agency acronym from CODIGO_PROCESO for crosswalk to adjudicaciones
proc[, agency_acronym := sub("(-CCC-|-DAF-|-UC-|-CDEEE-|-UCPR-).*", "", CODIGO_PROCESO)]

# MIPYME directed flag
proc[, mipyme_directed := as.integer(
  toupper(trimws(DIRIGIDO_MIPYMES)) %in% c("SI", "SÍ", "S", "TRUE", "1", "Y")
)]
proc[, mipyme_mujeres := as.integer(
  toupper(trimws(DIRIGIDO_MIPYMES_MUJERES)) %in% c("SI", "SÍ", "S", "TRUE", "1", "Y")
)]

cat("Procesos: date range", as.character(min(proc$fecha)), "to", as.character(max(proc$fecha)), "\n")
cat("MIPYME directed overall:", round(mean(proc$mipyme_directed) * 100, 1), "%\n")

# Filter to 2016Q1-2025Q4
proc <- proc[year >= 2016 & year <= 2025]
cat("Procesos after date filter:", nrow(proc), "\n")

## ============================================================
## 2. Agency-quarter process-level panel
## ============================================================

# Build crosswalk: agency_acronym -> numeric agency code (modal mapping)
crosswalk <- proc[, .(agency = agency[1]), by = agency_acronym]
crosswalk <- crosswalk[!is.na(agency_acronym) & agency_acronym != ""]

agency_q <- proc[, .(
  n_processes = .N,
  n_mipyme = sum(mipyme_directed),
  mipyme_share = mean(mipyme_directed),
  total_monto = sum(as.numeric(MONTO_ESTIMADO), na.rm = TRUE)
), by = .(agency, agency_name = UNIDAD_COMPRA, year, quarter, yq)]

cat("Agency-quarter observations (raw):", nrow(agency_q), "\n")
cat("Unique agencies:", uniqueN(agency_q$agency), "\n")

## ============================================================
## 3. Clean ADJUDICACIONES — extract contracts, suppliers
## ============================================================

adj[, fecha_adj := as.Date(FECHA_ADJUDICACION, format = "%m/%d/%Y")]
if (sum(is.na(adj$fecha_adj)) > nrow(adj) * 0.5) {
  adj[, fecha_adj := as.Date(FECHA_ADJUDICACION, format = "%d/%m/%Y")]
}
adj <- adj[!is.na(fecha_adj)]
adj[, year := year(fecha_adj)]
adj[, quarter := quarter(fecha_adj)]
adj[, yq := paste0(year, "Q", quarter)]

# Extract agency acronym from CODIGO_CONTRATO
# Pattern: "ACRONYM-YYYY-NNNNN" — extract everything before the year segment
adj[, agency_acronym := sub("-\\d{4}-\\d+$", "", CODIGO_CONTRATO)]

# Map to numeric agency code using crosswalk from procesos
adj <- merge(adj, crosswalk, by = "agency_acronym", all.x = TRUE)

# Supplier ID
adj[, supplier_id := RPE]
adj[, valor := as.numeric(gsub("[^0-9.]", "", VALOR_CONTRATADO))]

# Filter to 2016-2025
adj <- adj[year >= 2016 & year <= 2025]
cat("\nAdjudicaciones after date filter:", nrow(adj), "\n")

## ============================================================
## 4. Clean PROVEEDORES — firm-level characteristics
## ============================================================

prov[, mipyme_certified := as.integer(
  toupper(trimws(MIPYME)) %in% c("SI", "SÍ", "S", "TRUE", "1", "Y")
)]
prov[, fecha_creacion := as.Date(FECHA_CREACION_EMPRESA, format = "%m/%d/%Y")]
if (sum(is.na(prov$fecha_creacion)) > nrow(prov) * 0.5) {
  prov[, fecha_creacion := as.Date(FECHA_CREACION_EMPRESA, format = "%d/%m/%Y")]
}

cat("\nProveedores:", nrow(prov), "\n")
cat("MIPYME certified:", sum(prov$mipyme_certified, na.rm = TRUE), "\n")
cat("With firm creation date:", sum(!is.na(prov$fecha_creacion)), "\n")

# Merge supplier characteristics onto awards
adj_prov <- merge(adj, prov[, .(RPE, mipyme_certified, fecha_creacion,
                                 CLASIFICACION_EMPRESARIAL, GENERO, PROVINCIA)],
                  by = "RPE", all.x = TRUE)

## ============================================================
## 5. Construct agency-quarter outcome variables from awards
## ============================================================

# First, identify each supplier's earliest contract to determine "first-time winners"
supplier_first <- adj[, .(first_contract = min(fecha_adj)), by = supplier_id]
adj <- merge(adj, supplier_first, by = "supplier_id", all.x = TRUE)
adj[, is_first_time := as.integer(fecha_adj == first_contract &
                                    year == year(first_contract) &
                                    quarter == quarter(first_contract))]

# Merge MIPYME status onto awards
adj <- merge(adj, prov[, .(RPE, mipyme_certified, fecha_creacion)],
             by.x = "supplier_id", by.y = "RPE", all.x = TRUE)

# New entrant: firm created after 2020-08-16 (Abinader inauguration)
adj[, new_firm := as.integer(!is.na(fecha_creacion) & fecha_creacion >= as.Date("2020-08-16"))]

# Agency-quarter outcomes from awards
award_q <- adj[, .(
  n_awards = .N,
  n_unique_suppliers = uniqueN(supplier_id),
  total_value = sum(valor, na.rm = TRUE),
  hhi = {
    shares <- prop.table(table(supplier_id))
    sum(shares^2)
  },
  share_first_time = mean(is_first_time, na.rm = TRUE),
  n_first_time = sum(is_first_time, na.rm = TRUE),
  share_mipyme_supplier = mean(mipyme_certified, na.rm = TRUE),
  share_new_firm = mean(new_firm, na.rm = TRUE),
  n_new_firm = sum(new_firm, na.rm = TRUE)
), by = .(agency, year, quarter, yq)]

## ============================================================
## 6. Merge process and award panels
## ============================================================

panel <- merge(agency_q, award_q,
               by = c("agency", "year", "quarter", "yq"),
               all.x = TRUE)

# Fill missing award outcomes with zeros (agencies with processes but no awards that quarter)
award_vars <- c("n_awards", "n_unique_suppliers", "total_value", "hhi",
                "share_first_time", "n_first_time", "share_mipyme_supplier",
                "share_new_firm", "n_new_firm")
for (v in award_vars) {
  panel[is.na(get(v)), (v) := 0]
}

## ============================================================
## 7. Compute treatment intensity
## ============================================================

# Pre-period: 2016Q1-2020Q2; Post-period: 2020Q3-2025Q4
panel[, post := as.integer(year > 2020 | (year == 2020 & quarter >= 3))]

# Treatment = change in MIPYME share from pre to post, at agency level
treatment <- panel[, .(
  mipyme_share_pre = mean(mipyme_share[post == 0], na.rm = TRUE),
  mipyme_share_post = mean(mipyme_share[post == 1], na.rm = TRUE),
  n_pre_q = sum(post == 0),
  n_post_q = sum(post == 1)
), by = agency]
treatment[, delta_mipyme := mipyme_share_post - mipyme_share_pre]

panel <- merge(panel, treatment[, .(agency, delta_mipyme, mipyme_share_pre,
                                     n_pre_q, n_post_q)],
               by = "agency", all.x = TRUE)

## ============================================================
## 8. Filter to agencies with sufficient data
## ============================================================

# Require at least 4 pre-period quarters and 4 post-period quarters
sufficient <- treatment[n_pre_q >= 4 & n_post_q >= 4]
cat("\nAgencies with >= 4 pre and 4 post quarters:", nrow(sufficient), "\n")

panel <- panel[agency %in% sufficient$agency]
cat("Panel after filtering:", nrow(panel), "obs across", uniqueN(panel$agency), "agencies\n")

# Create numeric time index for event studies
panel[, time_idx := (year - 2020) * 4 + quarter - 2]  # 0 = 2020Q3

# Log outcomes
panel[, log_suppliers := log(n_unique_suppliers + 1)]
panel[, log_awards := log(n_awards + 1)]
panel[, log_value := log(total_value + 1)]

## ============================================================
## 9. Summary statistics
## ============================================================

cat("\n=== Panel Summary ===\n")
cat("Period:", min(panel$year), "-", max(panel$year), "\n")
cat("Agencies:", uniqueN(panel$agency), "\n")
cat("Total obs:", nrow(panel), "\n")
cat("Pre-period obs:", sum(panel$post == 0), "\n")
cat("Post-period obs:", sum(panel$post == 1), "\n")
cat("Mean MIPYME share (pre):", round(mean(panel$mipyme_share[panel$post == 0], na.rm = TRUE) * 100, 1), "%\n")
cat("Mean MIPYME share (post):", round(mean(panel$mipyme_share[panel$post == 1], na.rm = TRUE) * 100, 1), "%\n")
cat("Mean delta_mipyme:", round(mean(treatment$delta_mipyme[treatment$agency %in% panel$agency], na.rm = TRUE) * 100, 1), "pp\n")
cat("SD delta_mipyme:", round(sd(treatment$delta_mipyme[treatment$agency %in% panel$agency], na.rm = TRUE) * 100, 1), "pp\n")
cat("Mean unique suppliers per agency-quarter:", round(mean(panel$n_unique_suppliers), 1), "\n")
cat("Mean HHI:", round(mean(panel$hhi, na.rm = TRUE), 3), "\n")

## Save cleaned panel
saveRDS(panel, file.path(data_dir, "panel.rds"))
saveRDS(treatment, file.path(data_dir, "treatment.rds"))

# Also save supplier-level data for decomposition
saveRDS(adj, file.path(data_dir, "adj_clean.rds"))
saveRDS(prov, file.path(data_dir, "prov_clean.rds"))

cat("\nCleaned data saved.\n")
