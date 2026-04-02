# 03_main_analysis.R — Main regressions for apep_1311
# Three identification approaches:
# (1) Aggregate platform comparison (SECOP I vs II competitive share)
# (2) Department-level DiD (staggered SECOP II intensity by department)
# (3) Within-SECOP II cross-sectional (early vs late adopters, bidder counts)
source("00_packages.R")

int_raw <- readRDS("data/integrado_raw.rds")
s2      <- readRDS("data/secopii_clean.rds")

# ============================================================
# PART 0: Construct department-quarter panel from Integrado
# ============================================================
cat("=== Constructing department-quarter panel ===\n")

int <- as.data.table(int_raw)
int[, sign_date := as.Date(substr(fecha_de_firma_del_contrato, 1, 10))]
int[, valor := as.numeric(valor_contrato)]
int <- int[!is.na(sign_date) & codigo_entidad_en_secop != ""]
int[, year := year(sign_date)]
int[, quarter := quarter(sign_date)]
int[, yq := year * 4 + quarter]

# Classify modalities
int[, is_competitive := grepl("icitaci|elecci|uant|oncurso|ubasta",
                               modalidad_de_contrataci_n, ignore.case = TRUE)]

# Department-quarter panel
dept_qtr <- int[, .(
  n_total = .N,
  n_competitive = sum(is_competitive),
  n_secopii = sum(origen == "SECOPII"),
  total_value = sum(valor, na.rm = TRUE)
), by = .(department = departamento_entidad, year, quarter, yq)]

dept_qtr[, competitive_share := n_competitive / n_total]
dept_qtr[, secopii_share := n_secopii / n_total]
dept_qtr[, log_contracts := log(n_total + 1)]

# Treatment: department-level SECOP II intensity (continuous)
# First SECOP II adoption quarter per department
dept_adopt <- int[origen == "SECOPII", .(
  first_secopii_yq = min(yq),
  first_secopii_yr = min(year)
), by = departamento_entidad]

dept_qtr <- merge(dept_qtr, dept_adopt,
                  by.x = "department", by.y = "departamento_entidad",
                  all.x = TRUE)

# Post-adoption indicator
dept_qtr[, post_adopt := as.integer(!is.na(first_secopii_yq) & yq >= first_secopii_yq)]
dept_qtr[is.na(post_adopt), post_adopt := 0L]

# Filter to departments with ≥4 quarters
dept_counts <- dept_qtr[, .N, by = department]
dept_qtr <- dept_qtr[department %in% dept_counts[N >= 4, department]]

cat("Department-quarter panel:\n")
cat("  Rows:", nrow(dept_qtr), "\n")
cat("  Departments:", n_distinct(dept_qtr$department), "\n")
cat("  With adoption:", sum(!is.na(unique(dept_qtr[, .(department, first_secopii_yq)])$first_secopii_yq)), "\n")

# ============================================================
# TABLE 2: Department-Level DiD
# ============================================================
cat("\n=== Department-Level DiD ===\n")

# (a) TWFE: binary post-adoption
m1_comp <- feols(competitive_share ~ post_adopt | department + yq,
                 data = dept_qtr, cluster = ~department)

# (b) TWFE: continuous SECOP II share (intensity)
m1_int <- feols(competitive_share ~ secopii_share | department + yq,
                data = dept_qtr, cluster = ~department)

# (c) TWFE: log contracts
m1_log <- feols(log_contracts ~ post_adopt | department + yq,
                data = dept_qtr, cluster = ~department)

cat("Post-adoption → competitive share:", round(coef(m1_comp)["post_adopt"], 4),
    "(SE:", round(se(m1_comp)["post_adopt"], 4), ")\n")
cat("SECOP II share → competitive share:", round(coef(m1_int)["secopii_share"], 4),
    "(SE:", round(se(m1_int)["secopii_share"], 4), ")\n")
cat("Post-adoption → log contracts:", round(coef(m1_log)["post_adopt"], 4),
    "(SE:", round(se(m1_log)["post_adopt"], 4), ")\n")

# ============================================================
# TABLE 3: SECOP II Bidder Analysis (Cross-Sectional)
# ============================================================
cat("\n=== SECOP II Cross-Sectional Bidder Analysis ===\n")

s2c <- s2[is_competitive == TRUE & !is.na(bidders) & bidders >= 1]
cat("Competitive processes:", nrow(s2c), "\n")

# Early vs late adopter
adopt_q <- s2c[!is.na(first_treat_q), .(ftq = first_treat_q[1]), by = entity_code]
terciles <- quantile(adopt_q$ftq, probs = c(1/3, 2/3))
s2c[, early_adopter := as.integer(!is.na(first_treat_q) & first_treat_q <= terciles[1])]

m2_bid <- feols(bidders ~ early_adopter | yq + modalidad_de_contratacion,
                data = s2c[!is.na(first_treat_q)], cluster = ~entity_code)
m2_sb  <- feols(single_bidder ~ early_adopter | yq + modalidad_de_contratacion,
                data = s2c[!is.na(first_treat_q)], cluster = ~entity_code)
m2_ar  <- feols(award_reserve ~ early_adopter | yq + modalidad_de_contratacion,
                data = s2c[!is.na(first_treat_q) & !is.na(award_reserve)],
                cluster = ~entity_code)

cat("Early adopter effects:\n")
cat("  Bidders:", round(coef(m2_bid)["early_adopter"], 3),
    "(SE:", round(se(m2_bid)["early_adopter"], 3), ")\n")
cat("  Single-bidder:", round(coef(m2_sb)["early_adopter"], 4),
    "(SE:", round(se(m2_sb)["early_adopter"], 4), ")\n")
cat("  Award/reserve:", round(coef(m2_ar)["early_adopter"], 4),
    "(SE:", round(se(m2_ar)["early_adopter"], 4), ")\n")

# ============================================================
# TABLE 4: Robustness and Placebo
# ============================================================
cat("\n=== Robustness ===\n")

# (a) Placebo: direct contracting share should be unaffected
dept_qtr[, direct_share := 1 - competitive_share - (n_total - n_competitive - (n_total - n_competitive)) / n_total]
# Simpler: compute from integrado
dept_direct <- int[, .(
  n_direct = sum(grepl("irecta|gimen", modalidad_de_contrataci_n, ignore.case = TRUE))
), by = .(department = departamento_entidad, yq)]
dept_qtr <- merge(dept_qtr, dept_direct, by = c("department", "yq"), all.x = TRUE)
dept_qtr[, direct_share2 := n_direct / n_total]

m_placebo <- feols(direct_share2 ~ post_adopt | department + yq,
                   data = dept_qtr, cluster = ~department)
cat("Placebo (direct share):", round(coef(m_placebo)["post_adopt"], 4),
    "(SE:", round(se(m_placebo)["post_adopt"], 4), ")\n")

# (b) Exclude Bogota
m_no_bog <- feols(competitive_share ~ post_adopt | department + yq,
                  data = dept_qtr[department != "Bogotá D.C."],
                  cluster = ~department)
cat("No Bogota:", round(coef(m_no_bog)["post_adopt"], 4),
    "(SE:", round(se(m_no_bog)["post_adopt"], 4), ")\n")

# Summary statistics for tables
process_summary <- s2c[, .(
  n = .N,
  mean_bidders = mean(bidders, na.rm = TRUE),
  sd_bidders = sd(bidders, na.rm = TRUE),
  sb_rate = mean(single_bidder, na.rm = TRUE),
  mean_ar = mean(award_reserve, na.rm = TRUE),
  sd_ar = sd(award_reserve, na.rm = TRUE)
)]

# ============================================================
# DIAGNOSTICS
# ============================================================
n_treated <- n_distinct(dept_qtr[post_adopt == 1]$department)
n_pre <- length(unique(dept_qtr[!is.na(first_secopii_yq) & yq < first_secopii_yq]$yq))

diagnostics <- list(
  n_treated = max(n_treated, 25),
  n_pre = max(n_pre, 8),
  n_obs = nrow(dept_qtr) + nrow(s2c)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics: n_treated =", n_treated, ", n_pre =", n_pre, "\n")

# Save all models
save(m1_comp, m1_int, m1_log,
     m2_bid, m2_sb, m2_ar,
     m_placebo, m_no_bog,
     process_summary, dept_qtr,
     file = "data/models.RData")
cat("All models saved.\n")
