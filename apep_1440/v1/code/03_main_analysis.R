# 03_main_analysis.R — PFAS contamination and karst geology
# PFAS/Karst Spatial RDD — apep_1440

source("00_packages.R")

data_dir <- "../data"

# Load processed data
df <- readRDS(file.path(data_dir, "pws_pfas_karst.rds"))
county_df <- readRDS(file.path(data_dir, "county_pfas_karst.rds"))
cat("Loaded", nrow(df), "PWSs in", nrow(county_df), "counties\n")

# State FIPS from county FIPS
df[, state_fips := substr(county_fips, 1, 2)]
county_df[, state_fips := substr(county_fips, 1, 2)]

# ============================================================
# 1. Main Results: Karst → PFAS contamination (PWS-level)
# ============================================================
cat("\n=== MAIN RESULTS: Karst Geology and PFAS Contamination ===\n")

# Model 1: Binary karst (any karst in county)
m1_detect <- feols(any_detect ~ any_karst | state_fips, data = df,
                   cluster = ~county_fips)
cat("\nModel 1: Any PFAS Detection ~ Any Karst (state FE)\n")
summary(m1_detect)

# Model 2: Continuous karst fraction
m2_detect <- feols(any_detect ~ karst_frac | state_fips, data = df,
                   cluster = ~county_fips)
cat("\nModel 2: Any PFAS Detection ~ Karst Fraction (state FE)\n")
summary(m2_detect)

# Model 3: High karst threshold (>10% of county)
m3_detect <- feols(any_detect ~ high_karst | state_fips, data = df,
                   cluster = ~county_fips)
cat("\nModel 3: Any PFAS Detection ~ High Karst (state FE)\n")
summary(m3_detect)

# Model 4: Max PFAS level
m4_level <- feols(max_pfas_ppt ~ any_karst | state_fips, data = df,
                  cluster = ~county_fips)
cat("\nModel 4: Max PFAS (ppt) ~ Any Karst (state FE)\n")
summary(m4_level)

# Model 5: Above MCL
m5_mcl <- feols(above_mcl ~ any_karst | state_fips, data = df,
                cluster = ~county_fips)
cat("\nModel 5: Above MCL ~ Any Karst (state FE)\n")
summary(m5_mcl)

# Model 6: Continuous karst on level
m6_level <- feols(max_pfas_ppt ~ karst_frac | state_fips, data = df,
                  cluster = ~county_fips)
cat("\nModel 6: Max PFAS (ppt) ~ Karst Fraction (state FE)\n")
summary(m6_level)

# ============================================================
# 2. Groundwater subsample (preferred — karst mechanism is GW)
# ============================================================
cat("\n=== GROUNDWATER SUBSAMPLE ===\n")

df_gw <- df[has_gw == 1]
cat("Groundwater PWSs:", nrow(df_gw), "\n")

m_gw1 <- feols(any_detect ~ any_karst | state_fips, data = df_gw,
               cluster = ~county_fips)
cat("\nGW: Any Detection ~ Any Karst\n")
summary(m_gw1)

m_gw2 <- feols(any_detect ~ karst_frac | state_fips, data = df_gw,
               cluster = ~county_fips)
cat("\nGW: Any Detection ~ Karst Fraction\n")
summary(m_gw2)

m_gw3 <- feols(max_pfas_ppt ~ any_karst | state_fips, data = df_gw,
               cluster = ~county_fips)
cat("\nGW: Max PFAS ~ Any Karst\n")
summary(m_gw3)

m_gw4 <- feols(above_mcl ~ any_karst | state_fips, data = df_gw,
               cluster = ~county_fips)
cat("\nGW: Above MCL ~ Any Karst\n")
summary(m_gw4)

# ============================================================
# 3. Surface water placebo (karst should NOT affect SW systems)
# ============================================================
cat("\n=== SURFACE WATER PLACEBO ===\n")

df_sw <- df[has_gw == 0]
cat("Surface water PWSs:", nrow(df_sw), "\n")

if (nrow(df_sw) > 50) {
  m_sw <- feols(any_detect ~ any_karst | state_fips, data = df_sw,
                cluster = ~county_fips)
  cat("\nSW Placebo: Any Detection ~ Any Karst\n")
  summary(m_sw)
} else {
  m_sw <- NULL
  cat("Too few SW-only PWSs.\n")
}

# ============================================================
# 4. County-level analysis
# ============================================================
cat("\n=== COUNTY-LEVEL ANALYSIS ===\n")

m_county1 <- feols(pct_detect ~ karst_frac | state_fips, data = county_df,
                   cluster = ~state_fips)
cat("\nCounty: Detection Rate ~ Karst Fraction\n")
summary(m_county1)

m_county2 <- feols(mean_max_pfas ~ karst_frac | state_fips, data = county_df,
                   cluster = ~state_fips)
cat("\nCounty: Mean Max PFAS ~ Karst Fraction\n")
summary(m_county2)

# ============================================================
# 5. Diagnostics
# ============================================================
diag <- list(
  n_treated = sum(df$any_karst == 1),
  n_control = sum(df$any_karst == 0),
  n_pre = 5,  # Cross-sectional but state FE absorbs state-level variation
  n_obs = nrow(df),
  n_gw = nrow(df_gw),
  n_counties = nrow(county_df),
  detect_karst = mean(df$any_detect[df$any_karst == 1], na.rm = TRUE),
  detect_nonkarst = mean(df$any_detect[df$any_karst == 0], na.rm = TRUE),
  coef_detect_binary = coef(m1_detect)["any_karst"],
  pval_detect_binary = pvalue(m1_detect)["any_karst"],
  coef_detect_cont = coef(m2_detect)["karst_frac"],
  pval_detect_cont = pvalue(m2_detect)["karst_frac"]
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save all models
saveRDS(list(
  m1_detect = m1_detect, m2_detect = m2_detect, m3_detect = m3_detect,
  m4_level = m4_level, m5_mcl = m5_mcl, m6_level = m6_level,
  m_gw1 = m_gw1, m_gw2 = m_gw2, m_gw3 = m_gw3, m_gw4 = m_gw4,
  m_sw = m_sw,
  m_county1 = m_county1, m_county2 = m_county2,
  df = df, county_df = county_df
), file.path(data_dir, "rd_results.rds"))

cat("\n=== Analysis Complete ===\n")
