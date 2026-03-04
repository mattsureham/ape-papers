## 03_main_analysis.R — Primary DiD and DDD regressions
## apep_0495: Private School VAT and State School Housing Premium

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

cat("=== MAIN ANALYSIS ===\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date_transfer := as.Date(date_transfer)]
panel[, year_month_date := as.Date(paste0(year_month, "-01"))]
panel[, prop_type := factor(property_type)]
cat("Analysis panel:", format(nrow(panel), big.mark = ","), "transactions\n\n")

## =========================================================================
## 1. FIRST STAGE: Does the VAT affect private school enrollment/prices?
## =========================================================================
cat("--- First Stage Evidence ---\n")
cat("  (Documented using aggregate statistics from ISC Census and GIAS)\n")
cat("  ISC Census 2025: 556,551 pupils (down from ~565,000 in 2024)\n")
cat("  Government projection: ~37,000 pupils switching to state sector\n")
cat("  Average day fee increase: ~14-17% net of partial VAT absorption\n")
cat("  We verify bite using housing market response as the main test.\n\n")

## =========================================================================
## 2. DDD: High Private Share × Near Good School × Post-VAT
## =========================================================================
cat("--- Triple-Difference Estimates ---\n")

## Model 1: Basic DDD
m1 <- feols(log_price ~ high_private:near_good_school:post_vat +
              high_private:post_vat + near_good_school:post_vat +
              high_private:near_good_school +
              i(property_type) + i(old_new) + i(duration) |
              la_code + year_month,
            data = panel, cluster = ~la_code)

## Model 2: With postcode-sector fixed effects (absorbs location)
m2 <- feols(log_price ~ high_private:near_good_school:post_vat +
              high_private:post_vat + near_good_school:post_vat +
              i(property_type) + i(old_new) + i(duration) |
              pc_sector + year_month,
            data = panel, cluster = ~la_code)

## Model 3: Continuous treatment intensity
m3 <- feols(log_price ~ private_share:near_good_school:post_vat +
              private_share:post_vat + near_good_school:post_vat +
              i(property_type) + i(old_new) + i(duration) |
              pc_sector + year_month,
            data = panel, cluster = ~la_code)

## Model 4: Multi-period (announcement, budget, implementation)
m4 <- feols(log_price ~ high_private:near_good_school:post_announce +
              high_private:near_good_school:post_budget +
              high_private:near_good_school:post_vat +
              high_private:post_announce + high_private:post_budget + high_private:post_vat +
              near_good_school:post_announce + near_good_school:post_budget + near_good_school:post_vat +
              i(property_type) + i(old_new) + i(duration) |
              pc_sector + year_month,
            data = panel, cluster = ~la_code)

cat("\n  Model 1 (Basic DDD):\n")
print(summary(m1))
cat("\n  Model 2 (Postcode-sector FE):\n")
print(summary(m2))
cat("\n  Model 3 (Continuous treatment):\n")
print(summary(m3))
cat("\n  Model 4 (Multi-period):\n")
print(summary(m4))

## =========================================================================
## 3. EVENT STUDY: Monthly DDD coefficients
## =========================================================================
cat("\n--- Event Study ---\n")

## Create relative time factor (base period: t = -1, Dec 2024)
panel[, rel_month_f := factor(rel_month)]

## Event study with monthly treatment effects
## Restrict to reasonable window (-36 to +14 months)
es_sample <- panel[rel_month >= -36 & rel_month <= 14]

## DDD event study — use I() for interaction inside i()
es_sample[, hp_ng := high_private * near_good_school]

m_es <- feols(log_price ~ i(rel_month, hp_ng, ref = -1) +
                i(rel_month, high_private, ref = -1) +
                i(rel_month, near_good_school, ref = -1) +
                i(property_type) + i(old_new) + i(duration) |
                pc_sector + year_month,
              data = es_sample, cluster = ~la_code)

cat("  Event study estimated with", length(coef(m_es)), "coefficients\n")

## Save event study coefficients for plotting
es_coefs <- as.data.table(coeftable(m_es), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pvalue"))

## Extract DDD interaction terms (hp_ng = high_private × near_good_school)
es_ddd <- es_coefs[grepl("hp_ng", term)]
es_ddd[, rel_month := as.integer(gsub(".*::([-0-9]+).*", "\\1", term))]
es_ddd <- es_ddd[order(rel_month)]

fwrite(es_ddd, file.path(data_dir, "event_study_ddd_coefs.csv"))

## =========================================================================
## 4. DD: Just High Private × Post (without school quality dimension)
## =========================================================================
cat("\n--- Difference-in-Differences (DD) ---\n")

## Simple DD: do prices in high-private areas change differentially?
m_dd <- feols(log_price ~ high_private:post_vat +
                i(property_type) + i(old_new) + i(duration) |
                pc_sector + year_month,
              data = panel, cluster = ~la_code)

cat("  DD coefficient (high_private × post_vat):\n")
print(summary(m_dd))

## =========================================================================
## 5. Heterogeneity: By property type
## =========================================================================
cat("\n--- Heterogeneity by Property Type ---\n")

m_het_type <- feols(log_price ~ high_private:near_good_school:post_vat +
                      high_private:post_vat + near_good_school:post_vat +
                      i(old_new) + i(duration) |
                      pc_sector + year_month,
                    data = panel, cluster = ~la_code,
                    split = ~property_type)

for (i in seq_along(m_het_type)) {
  cat("  Property type subsample", i, ":\n")
  cat("    DDD coef:", coef(m_het_type[[i]])["high_private:near_good_school:post_vat"], "\n")
}

## =========================================================================
## 6. Heterogeneity: London vs non-London
## =========================================================================
cat("\n--- Heterogeneity: London vs Non-London ---\n")

panel[, is_london := as.integer(grepl("^E09", la_code))]  # London boroughs

m_london <- feols(log_price ~ high_private:near_good_school:post_vat +
                    high_private:post_vat + near_good_school:post_vat +
                    i(property_type) + i(old_new) + i(duration) |
                    pc_sector + year_month,
                  data = panel, cluster = ~la_code,
                  split = ~is_london)

cat("  Non-London DDD:", coef(m_london[[1]])["high_private:near_good_school:post_vat"], "\n")
cat("  London DDD:", coef(m_london[[2]])["high_private:near_good_school:post_vat"], "\n")

## =========================================================================
## 7. Save results
## =========================================================================
cat("\n--- Saving results ---\n")

## Main results table
etable(m1, m2, m3, m_dd,
       title = "Private School VAT and State School Housing Premium",
       dict = c(
         "high_private:near_good_school:post_vat" = "High Private × Near Good × Post",
         "private_share:near_good_school:post_vat" = "Private Share × Near Good × Post",
         "high_private:post_vat" = "High Private × Post",
         "near_good_school:post_vat" = "Near Good × Post",
         "high_private:near_good_school" = "High Private × Near Good"
       ),
       file = file.path(tables_dir, "main_results.tex"),
       style.tex = style.tex("aer"),
       replace = TRUE)

## Multi-period table
etable(m4,
       title = "Announcement, Budget, and Implementation Effects",
       file = file.path(tables_dir, "multi_period.tex"),
       style.tex = style.tex("aer"),
       replace = TRUE)

## Save model objects
save(m1, m2, m3, m4, m_dd, m_es, m_het_type, m_london,
     file = file.path(data_dir, "main_models.RData"))

cat("=== MAIN ANALYSIS COMPLETE ===\n")
