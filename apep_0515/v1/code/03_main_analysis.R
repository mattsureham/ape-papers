## ============================================================================
## 03_main_analysis.R — Primary Regressions
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Analysis Panel ===\n")
cat(sprintf("  %d obs, %d LAs, %d years\n",
            nrow(panel), length(unique(panel$la_name)), length(unique(panel$year))))

## ---- 0. Clean Panel ----
# Bite measures are already filtered in 02_clean_data.R
# Just remove any remaining NAs
panel_clean <- panel[!is.na(bite_kaitz) & !is.na(closure_rate)]
cat(sprintf("  Clean panel: %d obs, %d LAs\n",
            nrow(panel_clean), length(unique(panel_clean$la_name))))

# Create LA numeric ID for FE
panel_clean[, la_id := as.integer(factor(la_name))]

## ---- 1. First Stage: NLW Bite Predicts Wage Growth ----
cat("\n=== First Stage: Wage Pass-Through ===\n")

# Load ASHE wage panel
ashe_panel <- fread(file.path(data_dir, "ashe_wages_panel.csv"))

# Merge bite measure with ASHE wages
ashe_with_bite <- merge(
  ashe_panel[year >= 2012 & year <= 2019],
  unique(panel_clean[, .(la_code, bite_gap, bite_kaitz)]),
  by = "la_code"
)
ashe_with_bite <- ashe_with_bite[!is.na(bite_gap) & !is.na(median_wage)]
ashe_with_bite[, post := as.integer(year >= 2016)]
ashe_with_bite[, la_id := as.integer(factor(la_code))]
ashe_with_bite[, log_wage := log(median_wage)]

if (nrow(ashe_with_bite) > 100) {
  # First stage: high-bite LAs should see larger wage growth after NLW
  fs_model <- feols(log_wage ~ bite_kaitz:post | la_id + year, data = ashe_with_bite)
  cat("  First Stage (log wage ~ bite × post | LA + year FE):\n")
  cat(sprintf("    Coefficient: %.4f (SE: %.4f)\n",
              coef(fs_model)["bite_kaitz:post"],
              se(fs_model)["bite_kaitz:post"]))

  # Event study for first stage
  ashe_with_bite[, year_factor := factor(year)]
  fs_event <- feols(log_wage ~ i(year, bite_kaitz, ref = 2015) | la_id + year,
                     data = ashe_with_bite)

  saveRDS(fs_model, file.path(data_dir, "first_stage_model.rds"))
  saveRDS(fs_event, file.path(data_dir, "first_stage_event.rds"))
} else {
  cat("  WARNING: Insufficient data for first stage.\n")
}

## ---- 2. Main DiD: Closure Rate ----
cat("\n=== Main Results: Care Home Closures ===\n")

# Model 1: Basic DiD — closure rate ~ bite × post | LA + year FE
m1 <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
            data = panel_clean, cluster = ~la_id)

# Model 2: With population controls (if available)
has_pop <- panel_clean[!is.na(pop_total) & pop_total > 0 & !is.na(pop_65plus) & pop_65plus > 0]
if (nrow(has_pop) > 50) {
  m2 <- feols(closure_rate ~ bite_kaitz:post + log(pop_total) + log(pop_65plus) | la_id + year,
              data = has_pop, cluster = ~la_id)
} else {
  cat("  WARNING: Population data insufficient for Model 2. Skipping.\n")
  m2 <- m1  # Fallback to Model 1
}

# Model 3: Alternative bite measure (gap)
m3 <- feols(closure_rate ~ bite_gap:post | la_id + year,
            data = panel_clean, cluster = ~la_id)

cat("  Model 1 (Kaitz × Post, LA + Year FE):\n")
cat(sprintf("    beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m1)["bite_kaitz:post"], se(m1)["bite_kaitz:post"],
            fixest::pvalue(m1)["bite_kaitz:post"]))

cat("  Model 2 (+ population controls):\n")
cat(sprintf("    beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m2)["bite_kaitz:post"], se(m2)["bite_kaitz:post"],
            fixest::pvalue(m2)["bite_kaitz:post"]))

cat("  Model 3 (Gap × Post):\n")
cat(sprintf("    beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m3)["bite_gap:post"], se(m3)["bite_gap:post"],
            fixest::pvalue(m3)["bite_gap:post"]))

## ---- 3. Event Study ----
cat("\n=== Event Study ===\n")

# Event study: interact bite with year dummies, omit 2015
es_model <- feols(closure_rate ~ i(year, bite_kaitz, ref = 2015) | la_id + year,
                  data = panel_clean, cluster = ~la_id)

cat("  Event study coefficients:\n")
es_coefs <- coeftable(es_model)
print(es_coefs)

## ---- 4. Additional Outcomes ----
cat("\n=== Additional Outcomes ===\n")

# 4a. Number of homes (stock)
m_homes <- feols(n_homes ~ bite_kaitz:post | la_id + year,
                 data = panel_clean, cluster = ~la_id)
cat(sprintf("  Homes stock: beta = %.2f (SE = %.2f, p = %.4f)\n",
            coef(m_homes)["bite_kaitz:post"], se(m_homes)["bite_kaitz:post"],
            fixest::pvalue(m_homes)["bite_kaitz:post"]))

# 4b. Total beds
m_beds <- feols(total_beds ~ bite_kaitz:post | la_id + year,
                data = panel_clean, cluster = ~la_id)
cat(sprintf("  Total beds: beta = %.1f (SE = %.1f, p = %.4f)\n",
            coef(m_beds)["bite_kaitz:post"], se(m_beds)["bite_kaitz:post"],
            fixest::pvalue(m_beds)["bite_kaitz:post"]))

# 4c. Entry rate
m_entry <- feols(entry_rate ~ bite_kaitz:post | la_id + year,
                 data = panel_clean, cluster = ~la_id)
cat(sprintf("  Entry rate: beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_entry)["bite_kaitz:post"], se(m_entry)["bite_kaitz:post"],
            fixest::pvalue(m_entry)["bite_kaitz:post"]))

# 4d. Net change
m_net <- feols(net_change ~ bite_kaitz:post | la_id + year,
               data = panel_clean, cluster = ~la_id)
cat(sprintf("  Net change: beta = %.2f (SE = %.2f, p = %.4f)\n",
            coef(m_net)["bite_kaitz:post"], se(m_net)["bite_kaitz:post"],
            fixest::pvalue(m_net)["bite_kaitz:post"]))

## ---- 5. Save Results ----
results <- list(
  m1 = m1, m2 = m2, m3 = m3,
  es_model = es_model,
  m_homes = m_homes, m_beds = m_beds,
  m_entry = m_entry, m_net = m_net
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

cat("\nMain analysis complete. Results saved.\n")
