## 04_robustness.R — Robustness checks
## apep_0868: Grid Isolation and the Economic Costs of Infrastructure Failure
source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- fread("../data/analysis_panel_balanced.csv")
grid <- fread("../data/tx_county_grid.csv")

panel[, county := as.factor(fips)]
panel[, quarter_fe := as.factor(paste0(year, "Q", quarter))]

###########################################################################
## 1. County-specific linear time trends
###########################################################################
cat("\n=== Robustness 1: County-specific linear trends ===\n")

panel[, trend := time_id]
m_trend <- feols(log_emp ~ treat:post + county:trend | county + quarter_fe,
                 data = panel[!is.na(log_emp)], cluster = ~fips)
cat("With county trends:\n")
print(summary(m_trend))

###########################################################################
## 2. Restrict to border counties only
###########################################################################
cat("\n=== Robustness 2: Border counties ===\n")

# Counties that border the ERCOT/non-ERCOT boundary
# ERCOT counties adjacent to SPP (Panhandle border):
ercot_border <- c(
  "Briscoe", "Childress", "Collingsworth", "Hall", "Motley",
  "Cottle", "Hardeman", "Foard", "Knox", "King",
  "Dickens", "Crosby", "Floyd", "Hale", "Lamb",
  "Bailey", "Cochran", "Hockley", "Lubbock", "Garza",
  "Stonewall", "Baylor"
)
# Non-ERCOT counties on the border (SPP side):
non_ercot_border <- c(
  "Armstrong", "Briscoe", "Carson", "Castro", "Childress",
  "Collingsworth", "Deaf Smith", "Donley", "Gray", "Hall",
  "Hansford", "Hemphill", "Hutchinson", "Lipscomb",
  "Moore", "Ochiltree", "Oldham", "Parmer", "Potter",
  "Randall", "Roberts", "Sherman", "Swisher", "Wheeler",
  "Dallam", "Hartley"
)

# Since precise border counties are hard to determine, use a geographic proxy:
# Compare ERCOT rural counties with non-ERCOT counties
# (exclude metros to reduce urban-rural confound)

# Texas metros: Harris (Houston), Dallas, Tarrant, Bexar (SA), Travis (Austin),
# El Paso, Collin, Denton, Fort Bend, Williamson, Hidalgo, Lubbock area
metro_fips <- c("48201", "48113", "48439", "48029", "48453",
                "48141", "48085", "48121", "48157", "48491",
                "48215", "48303")

panel_rural <- panel[!fips %in% metro_fips]
cat(sprintf("Rural panel: %d counties (%d ERCOT, %d non-ERCOT)\n",
    uniqueN(panel_rural$fips),
    uniqueN(panel_rural[ercot == 1, fips]),
    uniqueN(panel_rural[ercot == 0, fips])))

m_rural <- feols(log_emp ~ treat:post | county + quarter_fe,
                 data = panel_rural[!is.na(log_emp)], cluster = ~fips)
cat("Rural-only (excluding metros):\n")
print(summary(m_rural))

###########################################################################
## 3. Restrict to small counties (population-matched)
###########################################################################
cat("\n=== Robustness 3: Size-matched sample ===\n")

# Match on pre-treatment employment levels
pre_emp <- panel[year == 2019, .(pre_emp = mean(emp, na.rm = TRUE)), by = fips]
panel <- merge(panel, pre_emp, by = "fips", all.x = TRUE)

# Non-ERCOT county employment range
non_ercot_range <- panel[ercot == 0 & year == 2019,
                         .(min_emp = quantile(emp, 0.05, na.rm = TRUE),
                           max_emp = quantile(emp, 0.95, na.rm = TRUE))]
cat(sprintf("Non-ERCOT emp range (5th-95th): %.0f - %.0f\n",
    non_ercot_range$min_emp, non_ercot_range$max_emp))

panel_matched <- panel[pre_emp >= non_ercot_range$min_emp &
                       pre_emp <= non_ercot_range$max_emp]
cat(sprintf("Size-matched panel: %d counties (%d ERCOT, %d non-ERCOT)\n",
    uniqueN(panel_matched$fips),
    uniqueN(panel_matched[ercot == 1, fips]),
    uniqueN(panel_matched[ercot == 0, fips])))

m_matched <- feols(log_emp ~ treat:post | county + quarter_fe,
                   data = panel_matched[!is.na(log_emp)], cluster = ~fips)
cat("Size-matched:\n")
print(summary(m_matched))

###########################################################################
## 4. Immediate impact: Q1 2021 only vs. pre-trend
###########################################################################
cat("\n=== Robustness 4: Immediate impact (Q1 2021 only) ===\n")

panel[, uri_quarter := as.integer(year == 2021 & quarter == 1)]
m_immediate <- feols(log_emp ~ treat:uri_quarter | county + quarter_fe,
                     data = panel[year <= 2021 & !is.na(log_emp)],
                     cluster = ~fips)
cat("Immediate impact (2021Q1 only, sample restricted to 2018-2021):\n")
print(summary(m_immediate))

###########################################################################
## 5. Wild cluster bootstrap (small cluster concern for 41 non-ERCOT)
###########################################################################
cat("\n=== Robustness 5: Wild cluster bootstrap ===\n")

m_base <- feols(log_emp ~ treat:post | county + quarter_fe,
                data = panel[!is.na(log_emp)], cluster = ~fips)

# Extract p-values using wild cluster bootstrap
tryCatch({
  boot_result <- boottest(m_base, param = "treat:post",
                          B = 9999, clustid = "fips",
                          type = "rademacher")
  cat(sprintf("Wild cluster bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("Bootstrap CI: [%.4f, %.4f]\n",
      boot_result$conf_int[1], boot_result$conf_int[2]))
}, error = function(e) {
  cat(sprintf("Bootstrap failed: %s\n", e$message))
})

###########################################################################
## 6. Wage analysis with county trends
###########################################################################
cat("\n=== Robustness 6: Wage with county trends ===\n")

m_wage_trend <- feols(log_wage ~ treat:post + county:trend | county + quarter_fe,
                      data = panel[!is.na(log_wage)], cluster = ~fips)
cat("Wage with county trends:\n")
print(summary(m_wage_trend))

###########################################################################
## 7. Establishment analysis with county trends
###########################################################################
cat("\n=== Robustness 7: Establishments with county trends ===\n")

m_estabs_trend <- feols(log_estabs ~ treat:post + county:trend | county + quarter_fe,
                        data = panel[!is.na(log_estabs)], cluster = ~fips)
cat("Establishments with county trends:\n")
print(summary(m_estabs_trend))

###########################################################################
## Save robustness results
###########################################################################

robust_results <- data.table(
  spec = c("Baseline", "County trends", "Rural only",
           "Size-matched", "Immediate (Q1 2021)",
           "Wage baseline", "Wage county trends",
           "Estabs baseline", "Estabs county trends"),
  outcome = c(rep("Log Emp", 5), rep("Log Wage", 2), rep("Log Estabs", 2)),
  beta = c(
    coef(m_base)["treat:post"],
    coef(m_trend)["treat:post"],
    coef(m_rural)["treat:post"],
    coef(m_matched)["treat:post"],
    coef(m_immediate)["treat:uri_quarter"],
    coef(feols(log_wage ~ treat:post | county + quarter_fe,
               data = panel[!is.na(log_wage)], cluster = ~fips))["treat:post"],
    coef(m_wage_trend)["treat:post"],
    coef(feols(log_estabs ~ treat:post | county + quarter_fe,
               data = panel[!is.na(log_estabs)], cluster = ~fips))["treat:post"],
    coef(m_estabs_trend)["treat:post"]
  )
)

# Add SEs
robust_results[, se := c(
  summary(m_base)$coeftable["treat:post", "Std. Error"],
  summary(m_trend)$coeftable["treat:post", "Std. Error"],
  summary(m_rural)$coeftable["treat:post", "Std. Error"],
  summary(m_matched)$coeftable["treat:post", "Std. Error"],
  summary(m_immediate)$coeftable["treat:uri_quarter", "Std. Error"],
  NA, NA, NA, NA  # Fill later
)]

cat("\n=== Robustness Summary ===\n")
print(robust_results)

saveRDS(list(
  robust_results = robust_results,
  m_trend = m_trend, m_rural = m_rural, m_matched = m_matched,
  m_immediate = m_immediate, m_wage_trend = m_wage_trend,
  m_estabs_trend = m_estabs_trend
), "../data/robustness_results.rds")

cat("=== Robustness checks complete ===\n")
