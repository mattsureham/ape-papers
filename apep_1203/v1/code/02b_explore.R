## 02b_explore.R — Explore geographic heterogeneity of the SAS ban
source("00_packages.R")

firms <- fread("../data/firms_clean.csv")

# Focus on CABA vs rest for SAS
sas_geo <- firms[type_clean == "SAS", .(n = .N),
                 by = .(province_clean, year = year(date_clean))]

# CABA SAS by year
cat("=== CABA SAS registrations by year ===\n")
print(sas_geo[province_clean == "CABA"][order(year)])

# Buenos Aires province SAS by year
cat("\n=== Buenos Aires Province SAS by year ===\n")
print(sas_geo[province_clean == "BUENOS AIRES"][order(year)])

# Rest of country SAS by year
cat("\n=== Rest of country SAS by year ===\n")
rest <- sas_geo[!province_clean %in% c("CABA", "BUENOS AIRES"),
                .(n = sum(n)), by = year]
print(rest[order(year)])

# CABA monthly SAS
cat("\n=== CABA SAS by month (2019-2025) ===\n")
caba_monthly <- firms[type_clean == "SAS" & province_clean == "CABA",
                      .(n = .N), by = .(ym = floor_date(date_clean, "month"))]
print(caba_monthly[ym >= "2019-01-01" & ym <= "2025-12-01"][order(ym)])

# Compare CABA SAS vs CABA SA/SRL during ban
cat("\n=== CABA firm types by year ===\n")
caba_types <- firms[province_clean == "CABA" & type_clean %in% c("SAS", "SA", "SRL"),
                    .(n = .N), by = .(type_clean, year = year(date_clean))]
caba_wide <- dcast(caba_types, year ~ type_clean, value.var = "n", fill = 0)
print(caba_wide[order(year)])

# Share of SAS that were in CABA by year
cat("\n=== CABA share of national SAS ===\n")
sas_total <- firms[type_clean == "SAS", .(total = .N), by = .(year = year(date_clean))]
sas_caba <- firms[type_clean == "SAS" & province_clean == "CABA",
                  .(caba = .N), by = .(year = year(date_clean))]
share <- merge(sas_total, sas_caba, by = "year", all.x = TRUE)
share[is.na(caba), caba := 0]
share[, pct_caba := round(100 * caba / total, 1)]
print(share[order(year)])
