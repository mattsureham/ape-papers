## 03_main_analysis.R — Main DiD estimation
## apep_1395: Denmark Renovation Arbitrage Ban

source("00_packages.R")

permits <- readRDS("../data/permits_panel.rds")
dwellings <- readRDS("../data/dwellings_panel.rds")

cat("=== PERMITS PANEL SUMMARY ===\n")
cat(sprintf("Obs: %d, Municipalities: %d, Quarters: %d\n",
            nrow(permits), n_distinct(permits$muni_name),
            n_distinct(paste(permits$year, permits$quarter))))
cat(sprintf("Treated: %d, Control: %d\n",
            n_distinct(permits$muni_name[permits$treated == 1]),
            n_distinct(permits$muni_name[permits$treated == 0])))
cat(sprintf("Pre-periods: %.0f quarters (2006Q1-2020Q2)\n",
            sum(permits$rel_q < 0) / n_distinct(permits$muni_name)))
cat(sprintf("Post-periods: %.0f quarters (2020Q3-2025Q4)\n",
            sum(permits$rel_q >= 0) / n_distinct(permits$muni_name)))

# ---- Summary statistics ----
cat("\n=== PRE-TREATMENT MEANS ===\n")
pre_means <- permits %>%
  filter(post == 0) %>%
  group_by(treated) %>%
  summarise(
    mean_permits = mean(total_permits, na.rm = TRUE),
    sd_permits = sd(total_permits, na.rm = TRUE),
    mean_multi = mean(multifamily_permits, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )
print(pre_means)

# ---- Main DiD: Total building permits ----
cat("\n=== MAIN DiD: TOTAL PERMITS ===\n")

# Create numeric municipality ID for FE
permits$muni_id <- as.numeric(factor(permits$muni_name))
permits$time_id <- as.numeric(factor(paste(permits$year, permits$quarter)))

# Specification 1: Basic TWFE
m1 <- feols(total_permits ~ treated:post | muni_id + time_id,
            data = permits, cluster = ~muni_id)
cat("\nSpec 1: Basic TWFE (total permits)\n")
summary(m1)

# Specification 2: Log permits (+ 1)
permits$log_permits <- log(permits$total_permits + 1)
m2 <- feols(log_permits ~ treated:post | muni_id + time_id,
            data = permits, cluster = ~muni_id)
cat("\nSpec 2: Log total permits\n")
summary(m2)

# Specification 3: Multifamily permits only (rental-relevant)
m3 <- feols(multifamily_permits ~ treated:post | muni_id + time_id,
            data = permits, cluster = ~muni_id)
cat("\nSpec 3: Multifamily permits\n")
summary(m3)

# Specification 4: Log multifamily
permits$log_multi <- log(permits$multifamily_permits + 1)
m4 <- feols(log_multi ~ treated:post | muni_id + time_id,
            data = permits, cluster = ~muni_id)
cat("\nSpec 4: Log multifamily permits\n")
summary(m4)

# ---- Dwelling stock DiD (annual) ----
cat("\n=== DWELLING STOCK DiD ===\n")
dwellings$muni_id <- as.numeric(factor(dwellings$muni_name))

# Rename columns to be safe
names(dwellings) <- make.names(names(dwellings))

# Identify rental column
rental_col <- grep("tenant|lejer|rental", names(dwellings), value = TRUE, ignore.case = TRUE)
owner_col <- grep("owner|ejer", names(dwellings), value = TRUE, ignore.case = TRUE)
cat("Rental column:", rental_col, "\n")
cat("Owner column:", owner_col, "\n")

if (length(rental_col) > 0 && length(owner_col) > 0) {
  dwellings$rental <- dwellings[[rental_col[1]]]
  dwellings$owner_occ <- dwellings[[owner_col[1]]]
  dwellings$log_rental <- log(dwellings$rental + 1)
  dwellings$log_owner <- log(dwellings$owner_occ + 1)

  m5 <- feols(log_rental ~ treated:post | muni_id + year,
              data = dwellings, cluster = ~muni_id)
  cat("\nSpec 5: Log rental dwelling stock\n")
  summary(m5)

  # Placebo: owner-occupied stock (should NOT be affected)
  m6 <- feols(log_owner ~ treated:post | muni_id + year,
              data = dwellings, cluster = ~muni_id)
  cat("\nSpec 6: Placebo — Log owner-occupied dwelling stock\n")
  summary(m6)
}

# ---- Event study: Total permits ----
cat("\n=== EVENT STUDY ===\n")
# Create event-time dummies, omitting -1
permits$rel_q_factor <- relevel(factor(permits$rel_q), ref = as.character(-1))

m_es <- feols(total_permits ~ i(rel_q, treated, ref = -1) | muni_id + time_id,
              data = permits, cluster = ~muni_id)
cat("Event study estimates:\n")
summary(m_es)

# Save event study coefficients
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$rel_q <- as.numeric(str_extract(rownames(es_coefs), "-?\\d+"))
es_coefs <- es_coefs[!is.na(es_coefs$rel_q), ]
names(es_coefs)[1:4] <- c("estimate", "se", "tstat", "pvalue")
saveRDS(es_coefs, "../data/event_study_coefs.rds")

# ---- Save diagnostics ----
n_treated <- n_distinct(permits$muni_name[permits$treated == 1])
n_pre <- sum(permits$rel_q < 0) / n_distinct(permits$muni_name)
n_obs <- nrow(permits)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%.0f, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# ---- Save all models ----
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m_es = m_es,
             m5 = if (exists("m5")) m5 else NULL,
             m6 = if (exists("m6")) m6 else NULL,
             pre_means = pre_means),
        "../data/main_models.rds")

cat("\nAll models saved.\n")
