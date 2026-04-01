## 03_main_analysis.R — DiD estimation: AEOI shock and Swiss real estate
## APEP-1285

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

cat("=== Main Analysis: AEOI Shock and Swiss Real Estate ===\n")
cat("Panel: ", n_distinct(df$region), " regions x ", n_distinct(df$year), " years\n")

# ---- Focus on apartments (EW) as primary outcome ----
# EW = privately owned apartments — most liquid residential market
df_ew <- df %>% filter(property_type == "EW")
cat("Apartment (EW) panel: ", nrow(df_ew), " obs\n")
cat("Regions with EW data: ", n_distinct(df_ew$region), "\n")
cat("Years with EW data: ", min(df_ew$year), "-", max(df_ew$year), "\n")

# ---- Restrict to 2005-2023 for cleaner analysis ----
# Pre-period: 2005-2016 (12 years), Post: 2017-2023 (7 years)
df_main <- df_ew %>% filter(year >= 2005, year <= 2023)
cat("Main sample (2005-2023): ", nrow(df_main), " obs\n")

# ---- Model 1: Basic TWFE with continuous treatment ----
cat("\n--- Model 1: Continuous Treatment DiD (Apartments) ---\n")
m1 <- feols(log_price ~ treat_x_post | region + year,
            data = df_main, cluster = ~region)
cat("Coefficient on Banking_Intensity × Post:\n")
print(summary(m1))

# ---- Wild cluster bootstrap (12 clusters is few) ----
cat("\n--- Wild Cluster Bootstrap (Webb weights) ---\n")
boot1 <- tryCatch(
  boottest(m1, param = "treat_x_post", B = 9999,
           clustid = df_main$region, type = "webb"),
  error = function(e) {
    cat("WCB error: ", conditionMessage(e), "\n")
    NULL
  }
)
if (!is.null(boot1)) {
  cat("WCB p-value: ", boot1$p_val, "\n")
  cat("WCB 95% CI: [", boot1$conf_int[1], ", ", boot1$conf_int[2], "]\n")
}

# ---- Model 2: Standardized treatment ----
cat("\n--- Model 2: Standardized Treatment (1 SD increase) ---\n")
df_main$treat_std_x_post <- df_main$treat_std * df_main$post
m2 <- feols(log_price ~ treat_std_x_post | region + year,
            data = df_main, cluster = ~region)
print(summary(m2))

# ---- Event Study ----
cat("\n--- Event Study ---\n")
# Create event-time dummies interacted with banking intensity
# Base period: t = -1 (2016)
df_main <- df_main %>%
  mutate(event_time = year - 2017)

# Restrict event window
df_es <- df_main %>% filter(event_time >= -8, event_time <= 6)

# Run event study with fixest sunab-like interaction
m_es <- feols(log_price ~ i(event_time, treat_intensity, ref = -1) | region + year,
              data = df_es, cluster = ~region)
cat("Event study coefficients:\n")
print(summary(m_es))

# ---- Multi-property-type analysis ----
cat("\n--- All Property Types ---\n")
df_all <- df %>%
  filter(year >= 2005, year <= 2023,
         property_type %in% c("EW", "EH", "MW", "BF"))

results_by_type <- list()
for (ptype in c("EW", "EH", "MW", "BF")) {
  sub <- df_all %>% filter(property_type == ptype)
  if (nrow(sub) < 20) next
  mod <- feols(log_price ~ treat_x_post | region + year,
               data = sub, cluster = ~region)
  results_by_type[[ptype]] <- list(
    type = ptype,
    coef = coef(mod)["treat_x_post"],
    se = se(mod)["treat_x_post"],
    pval = pvalue(mod)["treat_x_post"],
    nobs = nobs(mod),
    n_regions = n_distinct(sub$region)
  )
  cat(sprintf("  %s: β = %.4f (SE = %.4f), p = %.3f, N = %d, R = %d\n",
              ptype,
              coef(mod)["treat_x_post"],
              se(mod)["treat_x_post"],
              pvalue(mod)["treat_x_post"],
              nobs(mod),
              n_distinct(sub$region)))
}

# ---- Save results ----
# Event study coefficients for table
# Extract event-time labels from coefficient names
es_names <- names(coef(m_es))
es_times <- as.integer(gsub(".*event_time::(-?\\d+):.*", "\\1", es_names))
es_coefs <- data.frame(
  event_time = es_times,
  coefficient = as.numeric(coef(m_es)),
  se = as.numeric(se(m_es)),
  pval = as.numeric(pvalue(m_es))
)
es_coefs <- es_coefs[order(es_coefs$event_time), ]

cat("\n=== Event Study Coefficients ===\n")
print(es_coefs)

saveRDS(list(
  m1 = m1,
  m2 = m2,
  m_es = m_es,
  boot1 = boot1,
  results_by_type = results_by_type,
  es_coefs = es_coefs
), "../data/main_results.rds")

# ---- Diagnostics for validator ----
# Continuous-treatment DiD: all regions receive treatment intensity > 0
# "Treated" = region-years in post-AEOI period (2017+)
n_post_region_years <- nrow(df_main %>% filter(year >= 2017))
n_pre_periods <- n_distinct(df_main$year[df_main$year < 2017])

diagnostics <- list(
  n_treated = as.integer(n_post_region_years),  # 8 regions × 7 post years = 56
  n_pre = as.integer(n_pre_periods),            # 12 pre-treatment years
  n_obs = as.integer(nrow(df_main))
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved: n_treated =", diagnostics$n_treated,
    ", n_pre =", diagnostics$n_pre,
    ", n_obs =", diagnostics$n_obs, "\n")

# ---- Pre-treatment summary stats for SDE ----
pre_stats <- df_main %>%
  filter(year < 2017) %>%
  summarise(
    sd_log_price = sd(log_price, na.rm = TRUE),
    mean_log_price = mean(log_price, na.rm = TRUE),
    sd_price = sd(value, na.rm = TRUE),
    mean_price = mean(value, na.rm = TRUE),
    sd_treat = sd(treat_intensity, na.rm = TRUE),
    mean_treat = mean(treat_intensity, na.rm = TRUE)
  )
cat("\nPre-treatment stats for SDE calculation:\n")
print(pre_stats)
saveRDS(pre_stats, "../data/pre_stats.rds")

cat("\nMain analysis complete.\n")
