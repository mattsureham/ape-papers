## 03_main_analysis.R — Main DiD regressions
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

cat(sprintf("Analysis panel: %s rows, %d ports, %d months\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$PORT), uniqueN(panel$year_month)))

# ============================================================
# 1. MAIN SPECIFICATION: Continuous Treatment DiD
# ============================================================
# Y = log(imports) ~ canal_share × drought_intensity + port FE + month FE

cat("\n=== Main Results: Continuous Treatment DiD ===\n")

# Specification 1: Basic DiD (canal_share × drought_period)
m1 <- feols(log_imports ~ treatment_binary | PORT + year_month,
            data = panel, cluster = ~PORT)

# Specification 2: Continuous drought intensity
m2 <- feols(log_imports ~ treatment | PORT + year_month,
            data = panel, cluster = ~PORT)

# Specification 3: With port-specific time trends
panel[, port_trend := time_idx]
m3 <- feols(log_imports ~ treatment | PORT + year_month + PORT[port_trend],
            data = panel, cluster = ~PORT)

# Specification 4: Asinh transform (handles zeros better)
m4 <- feols(asinh_imports ~ treatment | PORT + year_month,
            data = panel, cluster = ~PORT)

# Specification 5: Canal-origin imports (using treatment interaction)
m5 <- feols(log_canal_imports ~ treatment | PORT + year_month,
            data = panel, cluster = ~PORT)

cat("Main regression results:\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Binary", "Continuous", "Port Trends", "Asinh", "Canal Imports"))

# Save coefficient data
main_results <- data.table(
  spec = c("Binary DiD", "Continuous Intensity", "Port Trends",
           "Asinh Transform", "Canal-Origin Imports"),
  coef = c(coef(m1)["treatment_binary"],
           coef(m2)["treatment"],
           coef(m3)["treatment"],
           coef(m4)["treatment"],
           coef(m5)["treatment"]),
  se = c(se(m1)["treatment_binary"],
         se(m2)["treatment"],
         se(m3)["treatment"],
         se(m4)["treatment"],
         se(m5)["treatment"]),
  n_obs = c(m1$nobs, m2$nobs, m3$nobs, m4$nobs, m5$nobs),
  n_ports = c(m1$fixef_sizes["PORT"], m2$fixef_sizes["PORT"],
              m3$fixef_sizes["PORT"], m4$fixef_sizes["PORT"],
              m5$fixef_sizes["PORT"])
)
main_results[, pval := 2 * pnorm(-abs(coef / se))]
main_results[, ci_low := coef - 1.96 * se]
main_results[, ci_high := coef + 1.96 * se]

fwrite(main_results, file.path(data_dir, "main_results.csv"))

# ============================================================
# 2. EVENT STUDY
# ============================================================

cat("\n=== Event Study ===\n")

# Create event-time dummies interacted with canal_share
# Base period: June 2023 (month before drought)
panel[, event_time_capped := pmax(pmin(event_time, 14), -24)]

# Event study with continuous treatment
es_model <- feols(log_imports ~ i(event_time_capped, canal_share, ref = -1) |
                    PORT + year_month,
                  data = panel[event_time_capped >= -24 & event_time_capped <= 14],
                  cluster = ~PORT)

cat("Event study summary:\n")
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.table(coef(es_model), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate"))
es_se <- as.data.table(se(es_model), keep.rownames = TRUE)
setnames(es_se, c("term", "se"))
es_data <- merge(es_coefs, es_se, by = "term")

# Parse event time from term names
es_data[, event_time := as.integer(gsub(".*::([-0-9]+):.*", "\\1", term))]
es_data[, ci_low := estimate - 1.96 * se]
es_data[, ci_high := estimate + 1.96 * se]

# Add reference period
es_data <- rbind(es_data, data.table(
  term = "ref", estimate = 0, se = 0,
  event_time = -1, ci_low = 0, ci_high = 0
))

es_data <- es_data[order(event_time)]
fwrite(es_data, file.path(data_dir, "event_study_coefs.csv"))

# ============================================================
# 3. TRIPLE DIFFERENCE: Port × Origin × Time
# ============================================================

cat("\n=== Triple Difference: Canal vs European Origins ===\n")

# Reshape to port × origin_group × month
origin_panel <- panel[, .(PORT, PORT_NAME, year_month, coast, canal_share,
                          drought_intensity, drought_period, high_canal,
                          date, year, month, time_idx, event_time)]

# Add Canal-dependent imports
canal_long <- panel[, .(PORT, year_month, imports = Canal_dependent,
                        origin = "Canal_dependent")]
euro_long <- panel[, .(PORT, year_month, imports = European,
                       origin = "European")]

origin_long <- rbind(canal_long, euro_long)
origin_long <- merge(origin_long, unique(panel[, .(PORT, canal_share, coast,
                                                    drought_intensity, drought_period,
                                                    high_canal, year_month)]),
                     by = c("PORT", "year_month"))

origin_long[, log_imports := log(imports + 1)]
origin_long[, is_canal_origin := fifelse(origin == "Canal_dependent", 1L, 0L)]

# Triple diff: canal_share × is_canal_origin × drought
origin_long[, triple_treat := canal_share * is_canal_origin * drought_intensity]
origin_long[, double_canal_drought := canal_share * drought_intensity]
origin_long[, double_origin_drought := is_canal_origin * drought_intensity]

# Triple difference regression
m_triple <- feols(log_imports ~ triple_treat + double_canal_drought +
                    double_origin_drought |
                    PORT^origin + year_month^origin,
                  data = origin_long, cluster = ~PORT)

cat("Triple difference results:\n")
summary(m_triple)

# Save triple diff results
triple_results <- data.table(
  term = names(coef(m_triple)),
  coef = coef(m_triple),
  se = se(m_triple)
)
triple_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(triple_results, file.path(data_dir, "triple_diff_results.csv"))

# ============================================================
# 4. DIVERSION TEST: West Coast gains
# ============================================================

cat("\n=== Diversion Test: West Coast Import Gains ===\n")

# If Canal restrictions divert trade, West Coast ports should gain Asian imports
# Use asian_share x drought_intensity (varies at port x month) separately by coast
# Key insight: asian_share measures exposure to Asian trade regardless of route
# For East/Gulf: Asian imports transit Canal → negative effect expected
# For West Coast: Asian imports are direct Pacific → positive diversion expected

# Create asian_share-based treatment for all ports
panel[, asian_treatment := asian_share * drought_intensity]

wc_panel <- panel[coast == "West Coast"]
ec_panel <- panel[coast %in% c("East Coast", "Gulf Coast")]

m_wc <- feols(log_imports ~ asian_treatment | PORT + year_month,
              data = wc_panel, cluster = ~PORT)
m_ec <- feols(log_imports ~ treatment | PORT + year_month,
              data = ec_panel, cluster = ~PORT)

cat("West Coast — Asian exposure x drought (expected positive = diversion):\n")
summary(m_wc)
cat("\nEast/Gulf Coast — Canal exposure x drought (expected negative):\n")
summary(m_ec)

# Pooled diversion model with coast interaction
panel[, west_coast := fifelse(coast == "West Coast", 1L, 0L)]
panel[, diversion_interact := asian_treatment * west_coast]

m_diversion <- feols(log_imports ~ asian_treatment + diversion_interact |
                       PORT + year_month,
                     data = panel, cluster = ~PORT)

cat("\nPooled diversion model (interaction = diversion effect):\n")
summary(m_diversion)

diversion_results <- data.table(
  coast = c("West Coast (diversion)", "East/Gulf Coast (direct)"),
  coef = c(coef(m_wc)["asian_treatment"], coef(m_ec)["treatment"]),
  se = c(se(m_wc)["asian_treatment"], se(m_ec)["treatment"]),
  n = c(m_wc$nobs, m_ec$nobs)
)
diversion_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(diversion_results, file.path(data_dir, "diversion_results.csv"))

# ============================================================
# 5. HETEROGENEITY: By commodity type
# ============================================================

cat("\n=== Heterogeneity by Port Size ===\n")

# Port size terciles
port_sizes <- panel[, .(avg_imports = mean(total_imports, na.rm = TRUE)), by = PORT]
port_sizes[, size_tercile := ntile(avg_imports, 3)]

panel <- merge(panel, port_sizes[, .(PORT, size_tercile)], by = "PORT", all.x = TRUE)

m_small <- feols(log_imports ~ treatment | PORT + year_month,
                 data = panel[size_tercile == 1], cluster = ~PORT)
m_medium <- feols(log_imports ~ treatment | PORT + year_month,
                  data = panel[size_tercile == 2], cluster = ~PORT)
m_large <- feols(log_imports ~ treatment | PORT + year_month,
                 data = panel[size_tercile == 3], cluster = ~PORT)

cat("Small ports:\n")
summary(m_small)
cat("Medium ports:\n")
summary(m_medium)
cat("Large ports:\n")
summary(m_large)

het_results <- data.table(
  group = c("Small Ports", "Medium Ports", "Large Ports"),
  coef = c(coef(m_small)["treatment"], coef(m_medium)["treatment"],
           coef(m_large)["treatment"]),
  se = c(se(m_small)["treatment"], se(m_medium)["treatment"],
         se(m_large)["treatment"]),
  n = c(m_small$nobs, m_medium$nobs, m_large$nobs)
)
het_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(het_results, file.path(data_dir, "heterogeneity_results.csv"))

# ============================================================
# 6. Save main model objects for tables/figures
# ============================================================

save(m1, m2, m3, m4, m5, es_model, m_triple, m_wc, m_ec,
     m_small, m_medium, m_large,
     file = file.path(data_dir, "main_models.RData"))

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Main effect (continuous DiD): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m2)["treatment"], se(m2)["treatment"],
            2 * pnorm(-abs(coef(m2)["treatment"] / se(m2)["treatment"]))))
