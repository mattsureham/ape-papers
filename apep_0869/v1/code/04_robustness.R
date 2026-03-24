# 04_robustness.R — Robustness checks
# APEP-0869: The Litigation Tax on Biometrics

source("00_packages.R")

# ============================================================
# Load data
# ============================================================

df <- fread("../data/analysis_panel.csv")
df_border <- df[border == 1 & sector != "total"]

df_border[, il_exposed := illinois * exposed]
df_border[, il_post := illinois * post]
df_border[, exposed_post := exposed * post]
df_border[, triple := illinois * exposed * post]

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# R1: Pre-COVID subsample (2015Q1–2019Q4)
# ============================================================

cat("--- R1: Pre-COVID subsample ---\n")
df_precovid <- df_border[year < 2020 | (year == 2019)]

m_precovid_emp <- feols(log_emp ~ triple + il_post + exposed_post + il_exposed |
                          county_sector + yearqtr,
                        data = df_precovid,
                        cluster = ~state_fips)
cat("Employment (pre-COVID):\n")
print(coeftable(m_precovid_emp))

m_precovid_estab <- feols(log_estab ~ triple + il_post + exposed_post + il_exposed |
                            county_sector + yearqtr,
                          data = df_precovid,
                          cluster = ~state_fips)
cat("\nEstablishments (pre-COVID):\n")
print(coeftable(m_precovid_estab))

# ============================================================
# R2: Leave-one-state-out
# ============================================================

cat("\n--- R2: Leave-one-state-out ---\n")
control_states <- c("18", "55", "29", "19", "21")
loso_results <- list()

for (drop_st in control_states) {
  df_loso <- df_border[state_fips != drop_st]
  m_loso <- feols(log_emp ~ triple + il_post + exposed_post + il_exposed |
                    county_sector + yearqtr,
                  data = df_loso,
                  cluster = ~state_fips)
  loso_results[[drop_st]] <- data.table(
    dropped_state = drop_st,
    coef = coef(m_loso)["triple"],
    se = se(m_loso)["triple"],
    pval = pvalue(m_loso)["triple"]
  )
  cat(sprintf("Drop %s: β = %.4f (SE = %.4f, p = %.3f)\n",
              drop_st, coef(m_loso)["triple"], se(m_loso)["triple"],
              pvalue(m_loso)["triple"]))
}

loso_dt <- rbindlist(loso_results)

# ============================================================
# R3: Wild cluster bootstrap (few clusters)
# ============================================================

cat("\n--- R3: Wild cluster bootstrap ---\n")
m_boot <- feols(log_emp ~ triple + il_post + exposed_post + il_exposed |
                  county_sector + yearqtr,
                data = df_border,
                cluster = ~state_fips)

boot_result <- tryCatch({
  # Use fwildclusterboot for WCB inference
  boot_out <- fwildclusterboot::boottest(
    m_boot,
    param = "triple",
    clustid = "state_fips",
    B = 9999,
    type = "webb"  # Webb weights recommended for few clusters
  )
  cat("WCB p-value:", boot_out$p_val, "\n")
  cat("WCB 95% CI:", boot_out$conf_int, "\n")
  boot_out
}, error = function(e) {
  cat("WCB failed:", e$message, "\n")
  cat("Proceeding with cluster-robust SEs only.\n")
  NULL
})

# ============================================================
# R4: Alternative industry classification
# Using only Information (51) as treated, only Healthcare (62) as control
# ============================================================

cat("\n--- R4: Narrow industry definition (Info vs Healthcare only) ---\n")
df_narrow <- df_border[sector %in% c("information", "healthcare")]
df_narrow[, exposed_narrow := fifelse(sector == "information", 1L, 0L)]
df_narrow[, triple_narrow := illinois * exposed_narrow * post]
df_narrow[, il_post := illinois * post]
df_narrow[, exposed_post_narrow := exposed_narrow * post]
df_narrow[, il_exposed_narrow := illinois * exposed_narrow]

m_narrow <- feols(log_emp ~ triple_narrow + il_post + exposed_post_narrow +
                    il_exposed_narrow | county_sector + yearqtr,
                  data = df_narrow,
                  cluster = ~state_fips)
cat("Employment (Info vs Healthcare):\n")
print(coeftable(m_narrow))

# ============================================================
# R5: Placebo test — Pre-period fake treatment (2017Q1)
# ============================================================

cat("\n--- R5: Placebo test (fake treatment 2017Q1) ---\n")
df_pre <- df_border[year <= 2018]  # Only pre-treatment data
df_pre[, fake_post := fifelse(year >= 2017, 1L, 0L)]
df_pre[, fake_triple := illinois * exposed * fake_post]
df_pre[, il_fakepost := illinois * fake_post]
df_pre[, exposed_fakepost := exposed * fake_post]

m_placebo <- feols(log_emp ~ fake_triple + il_fakepost + exposed_fakepost +
                     il_exposed | county_sector + yearqtr,
                   data = df_pre,
                   cluster = ~state_fips)
cat("Employment (placebo 2017Q1):\n")
print(coeftable(m_placebo))

# ============================================================
# R6: Simple DiD (IL vs neighbors, all sectors pooled)
# ============================================================

cat("\n--- R6: Simple DiD (pooled exposed + exempt) ---\n")
# Pool all sectors together for a simple IL vs border-state DiD
df_pooled <- df_border[, .(log_emp = log(sum(exp(log_emp) - 1, na.rm = TRUE) + 1)),
                       by = .(area_fips, state_fips, year, qtr, yearqtr, illinois, post)]
df_pooled[, il_post := illinois * post]

m_simple <- feols(log_emp ~ il_post | area_fips + yearqtr,
                  data = df_pooled,
                  cluster = ~state_fips)
cat("Employment (simple DiD, pooled sectors):\n")
print(coeftable(m_simple))

# ============================================================
# Save robustness models
# ============================================================

save(m_precovid_emp, m_precovid_estab, loso_dt, boot_result,
     m_narrow, m_placebo, m_simple,
     file = "../data/robustness_models.RData")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
