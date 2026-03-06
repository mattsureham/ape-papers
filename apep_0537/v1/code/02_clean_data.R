## 02_clean_data.R — Construct analysis datasets for apep_0537
## GenAI as Seniority-Biased Technological Change

source("00_packages.R")
data_dir <- "../data/"

# ===========================================================================
# 1. Construct industry-level GenAI treatment measures
# ===========================================================================
cat("\n=== Constructing GenAI treatment measures ===\n")

## 1A. AIOE-based industry exposure (primary treatment: Felten-Raj-Seamans)
aioe_occ <- fread(file.path(data_dir, "aioe_scores.csv"))
names(aioe_occ) <- c("soc_code", "occ_title", "aioe_score")
aioe_occ[, soc_code := gsub("-", "", soc_code)]
cat(sprintf("  AIOE: %d occupations, score range [%.2f, %.2f]\n",
            nrow(aioe_occ), min(aioe_occ$aioe_score), max(aioe_occ$aioe_score)))

## 1B. SEC EDGAR filing-based measure (secondary treatment)
edgar_df <- fread(file.path(data_dir, "edgar_genai_filings.csv"))
cat(sprintf("  EDGAR: %d filings from %d unique firms\n",
            nrow(edgar_df), n_distinct(edgar_df$cik)))

# Map SIC 2-digit to NAICS 2-digit (approximate)
sic_to_naics <- data.table(
  sic_2d = c("01","02","07","08","09","10","12","13","14","15","16","17",
             "20","21","22","23","24","25","26","27","28","29","30","31",
             "32","33","34","35","36","37","38","39",
             "40","41","42","43","44","45","46","47","48","49",
             "50","51","52","53","54","55","56","57","58","59",
             "60","61","62","63","64","65","67",
             "70","72","73","75","76","78","79","80","81","82","83","84","86","87","89",
             "91","92","93","94","95","96","97","99"),
  naics_2d = c("11","11","11","11","11","21","21","21","21","23","23","23",
               "31","31","31","31","31","31","31","51","32","32","32","31",
               "32","33","33","33","33","33","33","33",
               "48","48","48","48","48","48","48","48","48","22",
               "42","42","44","44","44","44","44","44","72","44",
               "52","52","52","52","52","53","52",
               "72","81","54","81","81","71","71","62","81","61","62","81","81","54","54",
               "92","92","92","92","92","92","92","99")
)

edgar_df[, sic_2d := as.character(sic_2d)]
edgar_industry <- edgar_df %>%
  left_join(sic_to_naics, by = "sic_2d") %>%
  group_by(naics_2d, filing_year) %>%
  summarise(n_genai_filings = n(), .groups = "drop")

cat("  EDGAR filings by NAICS 2-digit:\n")
print(edgar_industry %>% filter(n_genai_filings > 1) %>% arrange(desc(n_genai_filings)))

# ===========================================================================
# 2. Clean O*NET Job Zones → seniority classification
# ===========================================================================
cat("\n=== Constructing seniority classification ===\n")

job_zones <- fread(file.path(data_dir, "onet_job_zones.csv"))

# Standardize O*NET-SOC to 6-digit SOC
jz_cols <- names(job_zones)
cat(sprintf("  Job Zone columns: %s\n", paste(jz_cols, collapse = ", ")))

# The file should have columns like: O*NET-SOC Code, Title, Job Zone
# Rename based on what we see
soc_col <- jz_cols[grepl("Code|SOC", jz_cols, ignore.case = TRUE)][1]
jz_col <- jz_cols[grepl("Zone", jz_cols, ignore.case = TRUE)][1]
title_col <- jz_cols[grepl("Title|Name", jz_cols, ignore.case = TRUE)][1]

if (is.na(soc_col) || is.na(jz_col)) {
  # Try numeric columns
  cat("  Falling back to positional columns\n")
  soc_col <- jz_cols[1]
  title_col <- jz_cols[2]
  jz_col <- jz_cols[3]
}

if (is.na(title_col)) {
  jz_clean <- job_zones[, .(
    onet_soc = get(soc_col),
    title = NA_character_,
    job_zone = as.numeric(get(jz_col))
  )]
} else {
  jz_clean <- job_zones[, .(
    onet_soc = get(soc_col),
    title = get(title_col),
    job_zone = as.numeric(get(jz_col))
  )]
}

# Extract 6-digit SOC from O*NET-SOC (e.g., "11-1011.00" -> "111011")
jz_clean[, soc_6d := gsub("-|\\.", "", substr(onet_soc, 1, 7))]

# Seniority classification
jz_clean[, seniority := fcase(
  job_zone %in% c(1, 2), "Entry-Level",
  job_zone == 3, "Mid-Level",
  job_zone %in% c(4, 5), "Senior"
)]

cat(sprintf("  Job Zones by seniority:\n"))
print(jz_clean[, .N, by = seniority])

fwrite(jz_clean, file.path(data_dir, "onet_seniority.csv"))

# ===========================================================================
# 3. Merge AIOE with Job Zones
# ===========================================================================
cat("\n=== Merging AIOE with Job Zones ===\n")

# Match on 6-digit SOC
aioe_occ[, soc_6d := gsub("-", "", substr(soc_code, 1, 6))]
jz_clean[, soc_6d_short := substr(soc_6d, 1, 6)]

occ_merged <- merge(jz_clean, aioe_occ[, .(soc_6d, aioe_score)],
                     by.x = "soc_6d_short", by.y = "soc_6d", all.x = TRUE)

# Fill missing AIOE with SOC family median
occ_merged[, soc_2d := substr(soc_6d, 1, 2)]
occ_merged[, aioe_median_2d := median(aioe_score, na.rm = TRUE), by = soc_2d]
occ_merged[is.na(aioe_score), aioe_score := aioe_median_2d]

cat(sprintf("  Merged: %d occupations with both Job Zone and AIOE\n",
            sum(!is.na(occ_merged$aioe_score) & !is.na(occ_merged$job_zone))))

# Classify AI exposure
occ_merged[, ai_exposure := fcase(
  aioe_score >= quantile(aioe_score, 0.75, na.rm = TRUE), "High",
  aioe_score >= quantile(aioe_score, 0.25, na.rm = TRUE), "Medium",
  default = "Low"
)]

fwrite(occ_merged, file.path(data_dir, "occupation_classification.csv"))

# ===========================================================================
# 4. Clean OEWS: occupation × industry × state × year panel
# ===========================================================================
cat("\n=== Cleaning OEWS data ===\n")

oews_raw <- fread(file.path(data_dir, "oews_raw.csv"), showProgress = FALSE)

# Standardize: there are BOTH lowercase and UPPERCASE columns from different years
# e.g., "occ_code" (2015-2019) and "OCC_CODE" (2020-2024)
# Also "occ code" (with space) variants
# Strategy: find all variants and coalesce

coalesce_variants <- function(dt, target_name) {
  # Find all columns that match (case-insensitive, with/without spaces/underscores)
  pattern <- gsub("_", "[ _]?", target_name)
  matches <- grep(pattern, names(dt), ignore.case = TRUE, value = TRUE)
  matches <- unique(matches)

  if (length(matches) == 0) return(invisible(NULL))
  if (length(matches) == 1) {
    if (matches != target_name) setnames(dt, matches, target_name)
    return(invisible(NULL))
  }

  # Coalesce: create new column from all variants
  # Start with the first match that IS the target name, or the first match
  if (target_name %in% matches) {
    # Start with existing target, fill NAs from others
    for (m in setdiff(matches, target_name)) {
      dt[is.na(get(target_name)) | get(target_name) == "",
         (target_name) := as.character(get(m))]
    }
  } else {
    # Rename first match to target, then fill
    setnames(dt, matches[1], target_name)
    for (m in matches[-1]) {
      dt[is.na(get(target_name)) | get(target_name) == "",
         (target_name) := as.character(get(m))]
    }
  }
  # Remove variant columns (keep target)
  to_remove <- setdiff(matches, target_name)
  to_remove <- to_remove[to_remove %in% names(dt)]
  if (length(to_remove) > 0) dt[, (to_remove) := NULL]
}

coalesce_variants(oews_raw, "occ_code")
coalesce_variants(oews_raw, "occ_title")
coalesce_variants(oews_raw, "naics")
coalesce_variants(oews_raw, "tot_emp")
coalesce_variants(oews_raw, "area")
coalesce_variants(oews_raw, "area_title")

# Lowercase remaining names
names(oews_raw) <- tolower(names(oews_raw))

cat(sprintf("  OEWS: occ_code non-empty: %d / %d\n",
            sum(!is.na(oews_raw$occ_code) & oews_raw$occ_code != ""), nrow(oews_raw)))

# Key columns vary by year - find them
soc_candidates <- c("occ_code", "soc", "soc_code", "o_group")
naics_candidates <- c("naics", "industry_code", "i_group", "naics_code")
emp_candidates <- c("tot_emp", "employment", "emp")
state_candidates <- c("area", "st", "state", "prim_state", "area_title")

find_col <- function(df, candidates) {
  for (c in candidates) {
    if (c %in% names(df)) return(c)
  }
  # Partial match
  for (c in candidates) {
    matches <- grep(c, names(df), value = TRUE, ignore.case = TRUE)
    if (length(matches) > 0) return(matches[1])
  }
  return(NA)
}

soc_col <- find_col(oews_raw, soc_candidates)
naics_col <- find_col(oews_raw, naics_candidates)
emp_col <- find_col(oews_raw, emp_candidates)

cat(sprintf("  OEWS columns found: SOC=%s, NAICS=%s, Employment=%s\n",
            soc_col, naics_col, emp_col))

if (is.na(soc_col) || is.na(naics_col) || is.na(emp_col)) {
  cat("  Available columns: ", paste(names(oews_raw)[1:20], collapse = ", "), "\n")
  stop("Cannot find required OEWS columns")
}

# Clean employment field
oews_raw[, emp_clean := as.numeric(gsub(",|\\*|\\*\\*", "", get(emp_col)))]

# Get 6-digit SOC and 3-digit NAICS
oews_raw[, soc_6d := gsub("-", "", substr(get(soc_col), 1, 7))]
oews_raw[, naics_3d := substr(get(naics_col), 1, 3)]
oews_raw[, naics_2d := substr(get(naics_col), 1, 2)]

# Deduplicate occupation classification to one row per SOC
occ_unique <- occ_merged[, .(
  seniority = seniority[1],
  job_zone = job_zone[1],
  aioe_score = mean(aioe_score, na.rm = TRUE),
  ai_exposure = ai_exposure[1]
), by = soc_6d_short]

# Merge with occupation classification
oews_panel <- merge(
  oews_raw[!is.na(emp_clean) & emp_clean > 0,
           .(soc_6d, naics_3d, naics_2d, emp = emp_clean, oews_year)],
  occ_unique,
  by.x = "soc_6d", by.y = "soc_6d_short",
  all.x = TRUE
)

# Remove unmatched occupations
oews_panel <- oews_panel[!is.na(seniority)]

cat(sprintf("  OEWS panel: %d obs, %d unique occ × industry cells\n",
            nrow(oews_panel), n_distinct(paste(oews_panel$soc_6d, oews_panel$naics_3d))))

# Compute seniority shares within industry × year
industry_seniority <- oews_panel[,
  .(total_emp = sum(emp, na.rm = TRUE)),
  by = .(naics_3d, naics_2d, seniority, oews_year)
]

industry_totals <- industry_seniority[,
  .(industry_total = sum(total_emp)),
  by = .(naics_3d, oews_year)
]

industry_seniority <- merge(industry_seniority, industry_totals,
                            by = c("naics_3d", "oews_year"))
industry_seniority[, emp_share := total_emp / industry_total]

fwrite(industry_seniority, file.path(data_dir, "oews_industry_seniority.csv"))
cat("  Saved oews_industry_seniority.csv\n")

# Also compute by AI exposure level
industry_ai_seniority <- oews_panel[,
  .(total_emp = sum(emp, na.rm = TRUE)),
  by = .(naics_2d, seniority, ai_exposure, oews_year)
]

fwrite(industry_ai_seniority, file.path(data_dir, "oews_industry_ai_seniority.csv"))
cat("  Saved oews_industry_ai_seniority.csv\n")

# ===========================================================================
# 5. Clean QCEW: quarterly industry employment
# ===========================================================================
cat("\n=== Cleaning QCEW data ===\n")

qcew_raw <- fread(file.path(data_dir, "qcew_raw.csv"), showProgress = FALSE)
qcew_names <- tolower(names(qcew_raw))
names(qcew_raw) <- qcew_names

cat(sprintf("  QCEW columns: %s\n", paste(names(qcew_raw)[1:15], collapse = ", ")))

# Find key columns
ind_col <- find_col(qcew_raw, c("industry_code", "naics", "industry"))
emp_col_q <- find_col(qcew_raw, c("month3_emplvl", "avg_annual_pay", "annual_avg_emplvl",
                                    "month1_emplvl", "total_annual_wages"))
own_col <- find_col(qcew_raw, c("own_code", "ownership_code"))
size_col <- find_col(qcew_raw, c("size_code", "establishment_size"))

# Use month3_emplvl as the quarterly employment measure (end-of-quarter)
emp_candidates_q <- grep("emplvl|empl|employment", names(qcew_raw), value = TRUE)
cat(sprintf("  Employment columns found: %s\n", paste(emp_candidates_q, collapse = ", ")))

# Filter to private sector, all establishment sizes
qcew_clean <- copy(qcew_raw)

if (!is.null(own_col) && !is.na(own_col)) {
  qcew_clean <- qcew_clean[get(own_col) == 5]  # 5 = private
}

if (!is.null(size_col) && !is.na(size_col)) {
  qcew_clean <- qcew_clean[get(size_col) == 0]  # 0 = all sizes
}

# Get employment level
if ("month3_emplvl" %in% names(qcew_clean)) {
  qcew_clean[, emp := as.numeric(month3_emplvl)]
} else if ("annual_avg_emplvl" %in% names(qcew_clean)) {
  qcew_clean[, emp := as.numeric(annual_avg_emplvl)]
} else {
  # Use first numeric column that looks like employment
  for (ec in emp_candidates_q) {
    qcew_clean[, emp := as.numeric(get(ec))]
    if (sum(!is.na(qcew_clean$emp)) > 100) break
  }
}

# Get average weekly wage
wage_cols <- grep("avg.*wkly.*wage|avg_wkly_wage", names(qcew_clean), value = TRUE)
if (length(wage_cols) > 0) {
  qcew_clean[, avg_wage := as.numeric(get(wage_cols[1]))]
}

# Get NAICS code
if (!is.na(ind_col)) {
  qcew_clean[, naics_code := as.character(get(ind_col))]
  qcew_clean[, naics_2d := substr(naics_code, 1, 2)]
  qcew_clean[, naics_3d := substr(naics_code, 1, 3)]
  qcew_clean[, naics_len := nchar(naics_code)]
}

# Time variables
qcew_clean[, yearqtr := year + (quarter - 1) / 4]
qcew_clean[, post_chatgpt := as.integer(yearqtr >= 2023.0)]
qcew_clean[, time_idx := (year - 2015) * 4 + quarter]

# Construct AIOE industry exposure (AIIE)
# Read AIIE from AIOE Appendix B
aioe_file <- file.path(data_dir, "aioe_scores.csv")
aiie_file <- "../../../.." # We'll reconstruct from AIOE

# For now, construct industry AIOE by averaging occupation AIOE weighted by employment
# This requires OEWS data to weight
oews_for_weight <- oews_panel[oews_year == 2019, .(soc_6d, naics_2d, emp, aioe_score)]
industry_aioe <- oews_for_weight[!is.na(aioe_score),
  .(aioe_industry = weighted.mean(aioe_score, emp, na.rm = TRUE),
    n_occs = .N,
    total_emp_2019 = sum(emp, na.rm = TRUE)),
  by = naics_2d
]

cat("  Industry AIOE scores (top 10):\n")
print(industry_aioe[order(-aioe_industry)][1:10])

# Merge industry AIOE into QCEW
qcew_analysis <- merge(qcew_clean[naics_len <= 3 & !is.na(emp) & emp > 0],
                        industry_aioe, by = "naics_2d", all.x = TRUE)

# Create treatment terciles
qcew_analysis[, aioe_tercile := fcase(
  aioe_industry >= quantile(aioe_industry, 0.67, na.rm = TRUE), "High",
  aioe_industry >= quantile(aioe_industry, 0.33, na.rm = TRUE), "Medium",
  default = "Low"
)]

fwrite(qcew_analysis, file.path(data_dir, "qcew_analysis.csv"))
cat(sprintf("  QCEW analysis: %d rows\n", nrow(qcew_analysis)))

# ===========================================================================
# 6. Construct OEWS-based DDD panel
# ===========================================================================
cat("\n=== Constructing DDD panel ===\n")

# Panel: NAICS 2d × Seniority × Year
# For triple-diff: GenAI industry exposure × Junior × Post-2023
ddd_panel <- oews_panel[,
  .(emp = sum(emp, na.rm = TRUE)),
  by = .(naics_2d, seniority, oews_year)
]

# Merge industry AIOE
ddd_panel <- merge(ddd_panel, industry_aioe, by = "naics_2d", all.x = TRUE)

# Create analysis variables
ddd_panel[, `:=`(
  post = as.integer(oews_year >= 2023),
  junior = as.integer(seniority == "Entry-Level"),
  senior = as.integer(seniority == "Senior"),
  ln_emp = log(emp + 1),
  high_aioe = as.integer(aioe_industry >= median(aioe_industry, na.rm = TRUE))
)]

# Industry × seniority fixed effects
ddd_panel[, ind_sen := paste(naics_2d, seniority, sep = "_")]

fwrite(ddd_panel, file.path(data_dir, "ddd_panel.csv"))
cat(sprintf("  DDD panel: %d rows, %d industry-seniority cells\n",
            nrow(ddd_panel), n_distinct(ddd_panel$ind_sen)))

# ===========================================================================
# 7. Summary statistics
# ===========================================================================
cat("\n=== Summary Statistics ===\n")

# OEWS employment by seniority over time
summary_by_seniority <- oews_panel[,
  .(total_emp = sum(emp, na.rm = TRUE)),
  by = .(seniority, oews_year)
]

# Compute shares
summary_totals <- summary_by_seniority[, .(year_total = sum(total_emp)), by = oews_year]
summary_by_seniority <- merge(summary_by_seniority, summary_totals, by = "oews_year")
summary_by_seniority[, emp_share := total_emp / year_total]

cat("  Employment by seniority over time:\n")
print(dcast(summary_by_seniority, oews_year ~ seniority, value.var = "emp_share"))

fwrite(summary_by_seniority, file.path(data_dir, "summary_seniority_trends.csv"))

# QCEW employment trends by AIOE tercile
qcew_trends <- qcew_analysis[!is.na(aioe_tercile),
  .(total_emp = sum(emp, na.rm = TRUE)),
  by = .(aioe_tercile, year, quarter)
]

fwrite(qcew_trends, file.path(data_dir, "qcew_tercile_trends.csv"))

cat("\n=== Data cleaning complete ===\n")
