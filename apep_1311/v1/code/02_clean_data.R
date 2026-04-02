# 02_clean_data.R — Clean and construct analysis panels
source("00_packages.R")

integrado_raw <- readRDS("data/integrado_raw.rds")
secopii_raw   <- readRDS("data/secopii_raw.rds")

# ============================================================
# PART 1: Clean Integrado → Entity-quarter panel
# ============================================================
cat("=== Cleaning Integrado data ===\n")

int <- as.data.table(integrado_raw)

# Parse date
int[, sign_date := as.Date(substr(fecha_de_firma_del_contrato, 1, 10))]
int[, valor := as.numeric(valor_contrato)]

# Drop missing
int <- int[!is.na(sign_date) & !is.na(codigo_entidad_en_secop) &
           codigo_entidad_en_secop != ""]

# Time variables
int[, year := year(sign_date)]
int[, quarter := quarter(sign_date)]
int[, yq := year * 4 + quarter]

# Classify modalities
int[, is_competitive := grepl("icitaci|elecci|uant|oncurso|ubasta",
                               modalidad_de_contrataci_n, ignore.case = TRUE)]
int[, is_direct := grepl("irecta|gimen", modalidad_de_contrataci_n, ignore.case = TRUE)]

# Entity adoption: first SECOPII record date
adoption <- int[origen == "SECOPII", .(
  first_secopii_date = min(sign_date)
), by = codigo_entidad_en_secop]
adoption[, adopt_year := year(first_secopii_date)]
adoption[, adopt_quarter := quarter(first_secopii_date)]
adoption[, first_treat_q := adopt_year * 4 + adopt_quarter]

cat("Entities with SECOP II:", nrow(adoption), "\n")

# Entity-quarter panel
panel <- int[, .(
  n_contracts = .N,
  total_value = sum(valor, na.rm = TRUE),
  n_competitive = sum(is_competitive),
  n_direct = sum(is_direct)
), by = .(entity_code = codigo_entidad_en_secop,
          department = departamento_entidad,
          year, quarter)]

panel[, yq := year * 4 + quarter]

# Merge adoption
panel <- merge(panel, adoption,
               by.x = "entity_code", by.y = "codigo_entidad_en_secop",
               all.x = TRUE)

# Treatment indicator
panel[, post_secopii := as.integer(!is.na(first_secopii_date) &
        (year * 4 + quarter) >= first_treat_q)]
panel[is.na(post_secopii), post_secopii := 0L]

# Key variables
panel[, competitive_share := n_competitive / n_contracts]
panel[n_contracts == 0, competitive_share := NA]
panel[, direct_share := n_direct / n_contracts]
panel[n_contracts == 0, direct_share := NA]
panel[, log_contracts := log(n_contracts + 1)]

# For CS estimator: gname = first_treat_q (0 for never-treated)
panel[, gname := fifelse(is.na(first_treat_q), 0L, first_treat_q)]

# Filter: entities with ≥8 contracts and ≥3 quarters
entity_stats <- panel[, .(
  total_contracts = sum(n_contracts),
  n_quarters = .N
), by = entity_code]
active <- entity_stats[total_contracts >= 8 & n_quarters >= 3, entity_code]
panel <- panel[entity_code %in% active]

# Numeric entity ID for CS
panel[, entity_id := as.numeric(as.factor(entity_code))]

cat("\n=== Entity-quarter panel ===\n")
cat("  Rows:", nrow(panel), "\n")
cat("  Entities:", n_distinct(panel$entity_code), "\n")
cat("  Adopters:", sum(!is.na(unique(panel[, .(entity_code, first_secopii_date)])$first_secopii_date)), "\n")
cat("  Year range:", range(panel$year), "\n")
cat("  Mean competitive share:", round(mean(panel$competitive_share, na.rm = TRUE), 3), "\n")

# ============================================================
# PART 2: Clean SECOP II → Process-level data
# ============================================================
cat("\n=== Cleaning SECOP II data ===\n")

s2 <- as.data.table(secopii_raw)

# Parse fields
s2[, pub_date := as.Date(substr(fecha_de_publicacion_del, 1, 10))]
s2[, award_date := as.Date(substr(fecha_adjudicacion, 1, 10))]
s2[, precio_base := as.numeric(precio_base)]
s2[, award_value := as.numeric(valor_total_adjudicacion)]
s2[, n_bidders := as.numeric(respuestas_al_procedimiento)]
s2[, n_unique_bidders := as.numeric(proveedores_unicos_con)]
s2[, entity_code := as.character(codigo_entidad)]

# Drop missing
s2 <- s2[!is.na(pub_date) & entity_code != ""]

# Classify as competitive
s2[, is_competitive := grepl("cuant|icitaci|elecci|oncurso|ubasta",
                              modalidad_de_contratacion, ignore.case = TRUE)]
s2[, is_direct := grepl("irecta", modalidad_de_contratacion, ignore.case = TRUE)]

# Time variables
s2[, year := year(pub_date)]
s2[, quarter := quarter(pub_date)]
s2[, yq := year * 4 + quarter]

# Best bidder measure
s2[, bidders := fifelse(!is.na(n_unique_bidders) & n_unique_bidders > 0,
                         n_unique_bidders, n_bidders)]

# Single-bidder indicator (for competitive processes with valid bidder data)
s2[, single_bidder := fifelse(is_competitive & !is.na(bidders) & bidders >= 1,
                               as.integer(bidders == 1), NA_integer_)]

# Award-to-reserve ratio
s2[, award_reserve := fifelse(
  !is.na(precio_base) & precio_base > 1000 &
  !is.na(award_value) & award_value > 1000,
  award_value / precio_base, NA_real_)]

# Winsorize extreme ratios
if (sum(!is.na(s2$award_reserve)) > 100) {
  q01 <- quantile(s2$award_reserve, 0.01, na.rm = TRUE)
  q99 <- quantile(s2$award_reserve, 0.99, na.rm = TRUE)
  s2[!is.na(award_reserve) & (award_reserve < q01 | award_reserve > q99),
     award_reserve := NA]
}

# Merge adoption dates
s2 <- merge(s2, adoption,
            by.x = "entity_code", by.y = "codigo_entidad_en_secop",
            all.x = TRUE)

# Quarters since adoption
s2[, quarters_since := yq - first_treat_q]

cat("  Rows:", nrow(s2), "\n")
cat("  Competitive processes:", sum(s2$is_competitive), "\n")
cat("  With bidder count:", sum(!is.na(s2$bidders) & s2$is_competitive), "\n")
cat("  Mean bidders (competitive):",
    round(mean(s2[is_competitive == TRUE]$bidders, na.rm = TRUE), 2), "\n")
cat("  Single-bidder rate:",
    round(mean(s2$single_bidder, na.rm = TRUE), 3), "\n")

# ============================================================
# PART 3: Save
# ============================================================
saveRDS(panel, "data/panel.rds")
saveRDS(s2, "data/secopii_clean.rds")

cat("\nAll cleaned datasets saved.\n")
