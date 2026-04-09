# 04_robustness.R — Robustness checks
# PFAS/Karst — apep_1440

source("00_packages.R")

data_dir <- "../data"
res <- readRDS(file.path(data_dir, "rd_results.rds"))
df <- res$df
county_df <- res$county_df

df[, state_fips := substr(county_fips, 1, 2)]

# ============================================================
# 1. Alternative functional forms
# ============================================================
cat("=== Alternative Specifications ===\n")

# Log PFAS (adding 1 for zeros)
df[, log_pfas := log(max_pfas_ppt + 1)]

m_log <- feols(log_pfas ~ any_karst | state_fips, data = df,
               cluster = ~county_fips)
cat("Log PFAS ~ Any Karst:\n")
summary(m_log)

# Quadratic karst fraction
df[, karst_frac_sq := karst_frac^2]
m_quad <- feols(any_detect ~ karst_frac + karst_frac_sq | state_fips,
                data = df, cluster = ~county_fips)
cat("\nQuadratic karst:\n")
summary(m_quad)

# ============================================================
# 2. PWS size heterogeneity
# ============================================================
cat("\n=== Size Heterogeneity ===\n")

# Size categories: S, M, L, VL
for (sz in unique(df$pws_size)) {
  df_sub <- df[pws_size == sz]
  if (nrow(df_sub) > 30 && length(unique(df_sub$any_karst)) > 1) {
    m <- feols(any_detect ~ any_karst | state_fips, data = df_sub,
               cluster = ~county_fips)
    cat(sprintf("Size %s (n=%d): coef=%.4f, se=%.4f, p=%.4f\n",
                sz, nrow(df_sub), coef(m)["any_karst"],
                se(m)["any_karst"], pvalue(m)["any_karst"]))
  }
}

# ============================================================
# 3. Placebo: Non-PFAS contaminants from UCMR5
# ============================================================
cat("\n=== Placebo: Non-PFAS Contaminants ===\n")

# Load full UCMR5 and check for lithium (non-PFAS, also monitored)
ucmr5 <- data.table::fread(file.path(data_dir, "ucmr5/UCMR5_All.txt"), sep = "\t")
non_pfas <- ucmr5[!grepl("PF|GenX|HFPO|ADONA|FTS|FBSA|NEtFOSAA|NMeFOSAA",
                          Contaminant, ignore.case = TRUE)]
cat("Non-PFAS contaminants:", paste(unique(non_pfas$Contaminant), collapse = ", "), "\n")

if (nrow(non_pfas) > 0) {
  non_pfas[, result := as.numeric(AnalyticalResultValue)]
  pws_nonpfas <- non_pfas[, .(
    any_detect_nonpfas = as.integer(any(result > 0, na.rm = TRUE))
  ), by = PWSID]

  df_placebo <- merge(df, pws_nonpfas, by = "PWSID", all.x = TRUE)
  df_placebo[is.na(any_detect_nonpfas), any_detect_nonpfas := 0]

  if (sum(df_placebo$any_detect_nonpfas) > 10) {
    m_placebo <- feols(any_detect_nonpfas ~ any_karst | state_fips,
                       data = df_placebo, cluster = ~county_fips)
    cat("Placebo (non-PFAS detection) ~ Any Karst:\n")
    summary(m_placebo)
  }
}

# ============================================================
# 4. Conley standard errors (spatial correlation)
# ============================================================
cat("\n=== State-clustered vs County-clustered SEs ===\n")

m_state_cluster <- feols(any_detect ~ any_karst | state_fips, data = df,
                         cluster = ~state_fips)
cat("State-clustered SE:", se(m_state_cluster)["any_karst"], "\n")
cat("County-clustered SE:", se(res$m1_detect)["any_karst"], "\n")

# ============================================================
# 5. High karst fraction bins
# ============================================================
cat("\n=== Karst Fraction Bins ===\n")

df[, karst_bin := cut(karst_frac, breaks = c(-0.01, 0, 0.05, 0.15, 0.3, 1),
                       labels = c("0%", "0-5%", "5-15%", "15-30%", ">30%"))]

m_bins <- feols(any_detect ~ karst_bin | state_fips, data = df,
                cluster = ~county_fips)
cat("Karst fraction bins:\n")
summary(m_bins)

# ============================================================
# 6. Save
# ============================================================
saveRDS(list(
  m_log = m_log,
  m_quad = m_quad,
  m_state_cluster = m_state_cluster,
  m_bins = m_bins,
  m_placebo = if (exists("m_placebo")) m_placebo else NULL
), file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness complete.\n")
