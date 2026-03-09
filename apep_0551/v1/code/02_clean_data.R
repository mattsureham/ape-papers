## ============================================================
## 02_clean_data.R — Parse ARIA, build department-year panel
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

source("00_packages.R")

data_dir <- "../data"

# ----------------------------------------------------------------
# 1. Load raw ARIA data
# ----------------------------------------------------------------
aria <- readRDS(file.path(data_dir, "aria_raw.rds"))

cat("Raw ARIA records:", nrow(aria), "\n")
cat("Column names:", paste(names(aria), collapse = ", "), "\n")

# Identify department column (may be "Départment" with accent)
dept_col <- grep("part", names(aria), ignore.case = TRUE, value = TRUE)[1]
cat("Department column:", dept_col, "\n")

# ----------------------------------------------------------------
# 2. Parse date and extract year
# ----------------------------------------------------------------
aria[, date_parsed := as.Date(get(..dept_col), format = "%Y/%m/%d")]
# The Date column format: YYYY/MM/DD
aria[, date_parsed := as.Date(Date, format = "%Y/%m/%d")]
aria[, year := year(date_parsed)]

cat("Year range:", range(aria$year, na.rm = TRUE), "\n")
cat("Records with valid year:", sum(!is.na(aria$year)), "\n")

# ----------------------------------------------------------------
# 3. Clean department codes
# ----------------------------------------------------------------
aria[, dept := trimws(as.character(get(dept_col)))]

# Standardize department codes: ensure 2-digit (or 2A/2B for Corsica)
aria[, dept := gsub("^0*(\\d+)$", "\\1", dept)]
aria[nchar(dept) == 1, dept := paste0("0", dept)]

# Filter to metropolitan France only (01-95, 2A, 2B) and France
aria <- aria[Pays == "FRANCE" | is.na(Pays)]

# Remove overseas departments
overseas <- c("971", "972", "973", "974", "976", "97")
aria <- aria[!dept %in% overseas & !grepl("^97", dept)]

cat("Records in metropolitan France:", nrow(aria), "\n")
cat("Unique departments:", uniqueN(aria$dept), "\n")

# ----------------------------------------------------------------
# 4. Parse severity scale (Echelle field)
# ----------------------------------------------------------------
# Echelle format: "0H, 0En, 4Ec, 1M" or "6H, 6En, 6Ec, 6M"
# H = Human consequences (0-6)
# En = Environmental (0-6)
# Ec = Economic (0-6)
# M = Material damage (0-6 — this seems to be quantity of dangerous materials released)

aria[, echelle_raw := as.character(Echelle)]

# Extract individual components
aria[, severity_human := as.integer(str_extract(echelle_raw, "(\\d+)H"))]
aria[, severity_human := as.integer(str_extract(str_extract(echelle_raw, "\\d+H"), "\\d+"))]
aria[, severity_env := as.integer(str_extract(str_extract(echelle_raw, "\\d+En"), "\\d+"))]
aria[, severity_econ := as.integer(str_extract(str_extract(echelle_raw, "\\d+Ec"), "\\d+"))]
aria[, severity_mat := as.integer(str_extract(str_extract(echelle_raw, "\\d+M"), "\\d+"))]

# Maximum severity across all dimensions
aria[, severity_max := pmax(severity_human, severity_env, severity_econ, severity_mat,
                             na.rm = TRUE)]

# Classification
aria[, severe := severity_max >= 3]
aria[, fatal := severity_human >= 4]  # Level 4+ typically involves deaths
aria[, moderate := severity_max >= 2 & severity_max < 3]
aria[, minor := severity_max < 2 | is.na(severity_max)]

cat("\nSeverity distribution:\n")
cat("  Fatal (human >= 4):", sum(aria$fatal, na.rm = TRUE), "\n")
cat("  Severe (max >= 3):", sum(aria$severe, na.rm = TRUE), "\n")
cat("  Moderate (max 2):", sum(aria$moderate, na.rm = TRUE), "\n")
cat("  Minor (max < 2):", sum(aria$minor, na.rm = TRUE), "\n")
cat("  Missing severity:", sum(is.na(aria$severity_max)), "\n")

# ----------------------------------------------------------------
# 5. Parse accident type (IC = Installation Classée)
# ----------------------------------------------------------------
type_col <- grep("Type d.accident", names(aria), value = TRUE)[1]
if (!is.null(type_col) && length(type_col) > 0) {
  aria[, is_ic := grepl("IC", get(type_col))]
  cat("\nInstallation Classée accidents:", sum(aria$is_ic, na.rm = TRUE), "\n")
}

# Check for Consequences text for additional severity info
cons_col <- grep("^Cons", names(aria), value = TRUE)[1]
if (!is.null(cons_col) && length(cons_col) > 0) {
  aria[, has_death := grepl("mort|d[ée]c[èe]s|tu[ée]|fatal", get(cons_col), ignore.case = TRUE)]
  aria[, has_injury := grepl("bless[ée]|hospitalis|intoxiqu", get(cons_col), ignore.case = TRUE)]
  cat("Records mentioning deaths:", sum(aria$has_death, na.rm = TRUE), "\n")
  cat("Records mentioning injuries:", sum(aria$has_injury, na.rm = TRUE), "\n")
}

# ----------------------------------------------------------------
# 6. Load Seveso site counts
# ----------------------------------------------------------------
seveso <- fread(file.path(data_dir, "seveso_by_dept.csv"))

# ----------------------------------------------------------------
# 7. Build department-year panel (1992-2010)
# ----------------------------------------------------------------
years <- 1992:2010
depts <- sort(unique(c(seveso$dept_code, unique(aria$dept[aria$year %in% years]))))
# Keep only standard metro departments
depts <- depts[nchar(depts) == 2 | depts %in% c("2A", "2B")]

panel_grid <- CJ(dept = depts, year = years)

# Count outcomes by department-year
aria_panel <- aria[year %in% years, .(
  n_total = .N,
  n_severe = sum(severe, na.rm = TRUE),
  n_fatal = sum(fatal, na.rm = TRUE),
  n_moderate = sum(moderate, na.rm = TRUE),
  n_minor = sum(minor, na.rm = TRUE),
  n_ic = sum(is_ic, na.rm = TRUE),
  n_death_mention = sum(has_death, na.rm = TRUE),
  n_injury_mention = sum(has_injury, na.rm = TRUE),
  mean_severity = mean(severity_max, na.rm = TRUE)
), by = .(dept, year)]

panel <- merge(panel_grid, aria_panel, by = c("dept", "year"), all.x = TRUE)

# Fill NAs with 0 for count variables
count_vars <- c("n_total", "n_severe", "n_fatal", "n_moderate", "n_minor",
                "n_ic", "n_death_mention", "n_injury_mention")
for (v in count_vars) {
  panel[is.na(get(v)), (v) := 0]
}

# Merge Seveso site counts
panel <- merge(panel, seveso[, .(dept = dept_code, seveso_h, seveso_b)],
               by = "dept", all.x = TRUE)
panel[is.na(seveso_h), seveso_h := 0]
panel[is.na(seveso_b), seveso_b := 0]

# Treatment variables
panel[, log_seveso := log(seveso_h + 1)]
panel[, post2003 := as.integer(year >= 2003)]
panel[, treatment := log_seveso * post2003]

# Also create indicator for high vs low Seveso density
panel[, high_seveso := as.integer(seveso_h >= median(seveso_h[seveso_h > 0]))]

# Year relative to AZF (2001 = 0)
panel[, rel_year := year - 2001]

# ----------------------------------------------------------------
# 8. Summary statistics
# ----------------------------------------------------------------
cat("\n=== PANEL SUMMARY ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Departments:", uniqueN(panel$dept), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Depts with Seveso H > 0:", sum(seveso$seveso_h > 0), "\n")

cat("\nPre-period (1992-2002) means:\n")
pre <- panel[year <= 2002]
cat("  Total accidents/dept-year:", round(mean(pre$n_total), 2), "\n")
cat("  Severe accidents/dept-year:", round(mean(pre$n_severe), 2), "\n")
cat("  Fatal accidents/dept-year:", round(mean(pre$n_fatal), 2), "\n")

cat("\nPost-period (2003-2010) means:\n")
post <- panel[year >= 2003]
cat("  Total accidents/dept-year:", round(mean(post$n_total), 2), "\n")
cat("  Severe accidents/dept-year:", round(mean(post$n_severe), 2), "\n")
cat("  Fatal accidents/dept-year:", round(mean(post$n_fatal), 2), "\n")

cat("\nCorrelation: Seveso H count vs. pre-period mean total:\n")
pre_means <- panel[year <= 2002, .(mean_total = mean(n_total)), by = dept]
pre_means <- merge(pre_means, seveso[, .(dept = dept_code, seveso_h)], by = "dept")
cat("  r =", round(cor(pre_means$seveso_h, pre_means$mean_total), 3), "\n")

# ----------------------------------------------------------------
# 9. Also build commune-level panel for robustness
# ----------------------------------------------------------------
cat("\nBuilding commune-level panel...\n")
commune_col <- grep("^Commune$", names(aria), value = TRUE)[1]

if (!is.null(commune_col) && length(commune_col) > 0) {
  aria_commune <- aria[year %in% years & !is.na(get(commune_col)), .(
    n_total = .N,
    n_severe = sum(severe, na.rm = TRUE),
    n_fatal = sum(fatal, na.rm = TRUE)
  ), by = .(dept, commune = get(commune_col), year)]

  fwrite(aria_commune, file.path(data_dir, "aria_commune_panel.csv"))
  cat("Commune-level panel:", nrow(aria_commune), "obs,",
      uniqueN(aria_commune$commune), "communes\n")
}

# ----------------------------------------------------------------
# 10. Save panel
# ----------------------------------------------------------------
fwrite(panel, file.path(data_dir, "panel_dept_year.csv"))
cat("\nDepartment-year panel saved:", nrow(panel), "observations\n")

# Also save extended panel through 2020 for longer horizons
years_ext <- 1992:2020
panel_ext_grid <- CJ(dept = depts, year = years_ext)
aria_panel_ext <- aria[year %in% years_ext, .(
  n_total = .N,
  n_severe = sum(severe, na.rm = TRUE),
  n_fatal = sum(fatal, na.rm = TRUE)
), by = .(dept, year)]
panel_ext <- merge(panel_ext_grid, aria_panel_ext, by = c("dept", "year"), all.x = TRUE)
for (v in c("n_total", "n_severe", "n_fatal")) {
  panel_ext[is.na(get(v)), (v) := 0]
}
panel_ext <- merge(panel_ext, seveso[, .(dept = dept_code, seveso_h)],
                   by = "dept", all.x = TRUE)
panel_ext[is.na(seveso_h), seveso_h := 0]
panel_ext[, log_seveso := log(seveso_h + 1)]
panel_ext[, post2003 := as.integer(year >= 2003)]
panel_ext[, treatment := log_seveso * post2003]
fwrite(panel_ext, file.path(data_dir, "panel_dept_year_extended.csv"))
cat("Extended panel (1992-2020) saved:", nrow(panel_ext), "observations\n")
