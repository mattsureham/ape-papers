## 03_main_analysis.R — Main DiD analysis of Romania's micro-enterprise threshold expansion
## apep_0824
source("00_packages.R")

# ---- 1. Load data ----
panel <- readRDS("../data/panel.rds")
country_year <- readRDS("../data/country_year.rds")

# Focus on 2008-2020 (consistent Eurostat framework)
# This covers the key expansion period (2016-2018)
panel <- panel %>% filter(year >= 2008, year <= 2020)
country_year <- country_year %>% filter(year >= 2008, year <= 2020)

# Define peer groups
cee_peers <- c("BG", "HU", "CZ", "PL", "SK", "HR", "SI", "EE", "LT", "LV")

cat("=== Analysis period: 2008-2020 ===\n")
cat("Treatment: Romania's micro-enterprise threshold expansion\n")
cat("  2016: Threshold raised to EUR 100K, rate cut to 1%\n")
cat("  2017: Threshold raised to EUR 500K (MAJOR)\n")
cat("  2018: Threshold raised to EUR 1M\n")
cat("Control: CEE peer countries\n\n")

# ---- 2. Sector-level panel ----
# Use 1-letter NACE sectors (market economy)
# Exclude K (financial) as micro-enterprise regime doesn't apply
sectors <- c("C", "F", "G", "H", "I", "J", "L", "M", "N")

sector_data <- panel %>%
  filter(
    nace %in% sectors,
    geo %in% c("RO", cee_peers),
    size %in% c("0-9", "10-19", "20-49", "50-249", "GE250", "TOTAL")
  ) %>%
  mutate(
    ro = as.integer(geo == "RO"),
    post = as.integer(year >= 2017),  # Major expansion (500K threshold)
    treat = ro * post,
    log_ent = log(enterprises + 1),
    log_turn = log(turnover_m + 1),
    avg_turn_k = turnover_m * 1000 / enterprises  # Avg turnover in thousands EUR
  )

cat("Sector panel:", nrow(sector_data), "rows\n")
cat("Romania obs:", sum(sector_data$geo == "RO"), "\n")
cat("Control obs:", sum(sector_data$geo != "RO"), "\n")

# ---- 3. Main outcome: Enterprise counts by size class ----
# DiD: Romania × Post-2017 on log(enterprises) in 0-9 employee class

cat("\n=== TABLE 1: DiD on Micro-Enterprise Counts (0-9 employees) ===\n")

micro <- sector_data %>% filter(size == "0-9")
total <- sector_data %>% filter(size == "TOTAL")

# Column 1: Basic DiD
m1 <- feols(log_ent ~ treat | geo + year, data = micro,
            cluster = ~geo)

# Column 2: Add sector FE
m2 <- feols(log_ent ~ treat | geo + year + nace, data = micro,
            cluster = ~geo)

# Column 3: Country-sector + year FE
m3 <- feols(log_ent ~ treat | geo^nace + year, data = micro,
            cluster = ~geo)

# Column 4: Country-sector + sector-year FE (most demanding)
m4 <- feols(log_ent ~ treat | geo^nace + nace^year, data = micro,
            cluster = ~geo)

cat("\nBasic DiD results:\n")
etable(m1, m2, m3, m4,
       headers = c("Basic", "+Sector", "Unit FE", "Unit+Sector-Year"),
       se.below = TRUE, fitstat = c("n", "r2"))

# ---- 4. TABLE 2: Effects across size classes ----
cat("\n=== TABLE 2: DiD by Size Class ===\n")

size_results <- list()
for (sz in c("0-9", "10-19", "20-49", "50-249", "GE250")) {
  sz_data <- sector_data %>% filter(size == sz)
  size_results[[sz]] <- feols(log_ent ~ treat | geo^nace + nace^year,
                               data = sz_data, cluster = ~geo)
}

etable(size_results, headers = c("0-9", "10-19", "20-49", "50-249", "250+"),
       se.below = TRUE, fitstat = c("n", "r2"))

# ---- 5. TABLE 3: Effects on average turnover per firm ----
cat("\n=== TABLE 3: Average Turnover per Micro-Enterprise ===\n")

# Average turnover per firm in the 0-9 class
micro_turn <- micro %>%
  filter(!is.na(avg_turn_k), is.finite(avg_turn_k), avg_turn_k > 0) %>%
  mutate(log_avg_turn = log(avg_turn_k))

t3_m1 <- feols(log_avg_turn ~ treat | geo + year, data = micro_turn,
               cluster = ~geo)
t3_m2 <- feols(log_avg_turn ~ treat | geo^nace + year, data = micro_turn,
               cluster = ~geo)
t3_m3 <- feols(log_avg_turn ~ treat | geo^nace + nace^year, data = micro_turn,
               cluster = ~geo)

etable(t3_m1, t3_m2, t3_m3,
       headers = c("Basic", "Unit FE", "Unit+Sector-Year"),
       se.below = TRUE, fitstat = c("n", "r2"))

# ---- 6. Event study ----
cat("\n=== EVENT STUDY: Micro-Enterprise Counts ===\n")

micro_es <- micro %>%
  mutate(
    event_time = year - 2017,
    event_time = ifelse(event_time < -5, -5, event_time),
    event_time = ifelse(event_time > 3, 3, event_time),
    event_factor = factor(event_time),
    ro_event = ro * event_time
  )

# Create leads and lags interacted with Romania dummy
# Reference period: event_time = -1 (2016)
es_model <- feols(log_ent ~ i(event_time, ro, ref = -1) | geo^nace + nace^year,
                  data = micro_es, cluster = ~geo)

cat("\nEvent study coefficients:\n")
print(summary(es_model))

# ---- 7. Sector heterogeneity ----
cat("\n=== TABLE 4: Sector Heterogeneity ===\n")

# Services (easier to manipulate revenue) vs Manufacturing/Construction
# Services: G (trade), I (accommodation), J (info/comm), L (real estate), M (professional), N (admin)
# Non-services: C (manufacturing), F (construction), H (transport)

micro_het <- micro %>%
  mutate(
    service = as.integer(nace %in% c("G", "I", "J", "L", "M", "N")),
    treat_service = treat * service
  )

het_model <- feols(log_ent ~ treat + treat_service | geo^nace + nace^year,
                   data = micro_het, cluster = ~geo)

# Also run separately
micro_svc <- micro %>% filter(nace %in% c("G", "I", "J", "L", "M", "N"))
micro_mfg <- micro %>% filter(nace %in% c("C", "F", "H"))

het_svc <- feols(log_ent ~ treat | geo^nace + nace^year, data = micro_svc, cluster = ~geo)
het_mfg <- feols(log_ent ~ treat | geo^nace + nace^year, data = micro_mfg, cluster = ~geo)

etable(het_model, het_svc, het_mfg,
       headers = c("Interaction", "Services Only", "Manuf/Constr"),
       se.below = TRUE, fitstat = c("n", "r2"))

# ---- 8. Save results ----
results <- list(
  tab1 = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
  tab2 = size_results,
  tab3 = list(m1 = t3_m1, m2 = t3_m2, m3 = t3_m3),
  event_study = es_model,
  tab4 = list(interaction = het_model, services = het_svc, manufacturing = het_mfg)
)
saveRDS(results, "../data/results.rds")

# ---- 9. Diagnostics ----
n_ro_micro <- sum(micro$geo == "RO")
n_ro_sectors <- length(unique(micro$nace[micro$geo == "RO"]))
n_countries <- length(unique(micro$geo))
n_pre <- sum(unique(micro$year) < 2017)
n_post <- sum(unique(micro$year) >= 2017)
n_obs <- nrow(micro)

# For SDE computation
sd_y_pre <- sd(micro$log_ent[micro$geo == "RO" & micro$year < 2017], na.rm = TRUE)
beta_hat <- coef(m4)["treat"]
se_hat <- se(m4)["treat"]

cat("\n=== DIAGNOSTICS ===\n")
cat("N treated (Romania sectors):", n_ro_micro, "\n")
cat("N treated sectors:", n_ro_sectors, "\n")
cat("N countries:", n_countries, "\n")
cat("N pre-treatment years:", n_pre, "\n")
cat("N post-treatment years:", n_post, "\n")
cat("Total observations:", n_obs, "\n")
cat("SD(Y) pre-treatment (Romania):", round(sd_y_pre, 4), "\n")
cat("Beta hat (main spec):", round(beta_hat, 4), "\n")
cat("SE (main spec):", round(se_hat, 4), "\n")
cat("SDE:", round(beta_hat / sd_y_pre, 4), "\n")

# Write diagnostics.json
diag <- list(
  n_treated = n_ro_sectors,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = n_countries,
  n_post = n_post,
  sd_y_pre = sd_y_pre,
  beta_hat = as.numeric(beta_hat),
  se_hat = as.numeric(se_hat),
  sde = as.numeric(beta_hat / sd_y_pre)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
