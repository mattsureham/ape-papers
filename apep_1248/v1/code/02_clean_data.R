## 02_clean_data.R — Clean GEIH data and construct analysis variables
## Creates the analytic sample for the thin formality paper

library(data.table)
library(tidyverse)

DATA_DIR <- file.path(dirname(getwd()), "data")

# Read combined CSV produced by Python fetch script
geih <- fread(file.path(DATA_DIR, "geih_combined_2011_2016.csv"))
cat(sprintf("Raw data: %s observations (2011-2016)\n", format(nrow(geih), big.mark = ",")))

# ---- Variable construction ----

# Standardize variable names to lowercase for convenience
names(geih) <- tolower(names(geih))

# Age (P6040)
geih[, age := as.numeric(p6040)]

# Sex (P6020: 1=male, 2=female)
geih[, female := as.integer(p6020 == 2)]

# Education level (P6210: 1=none, 2=preschool, 3=primary, 4=secondary, 5=media,
#                  6=superior/university, 9=NS/NR)
geih[, educ_level := as.numeric(p6210)]
geih[educ_level == 9, educ_level := NA]

# Monthly earnings (P6500)
geih[, earnings := as.numeric(p6500)]
geih[earnings == 98 | earnings == 99, earnings := NA]  # NS/NR codes

# Weekly hours (P6800)
geih[, hours := as.numeric(p6800)]
geih[hours == 98 | hours == 99, hours := NA]

# Has written contract (P6440: 1=yes, 2=no; P6450: 1=verbal, 2=written)
geih[, has_contract := as.integer(p6440 == 1)]
geih[, written_contract := as.integer(p6450 == 2)]

# Firm size (P6870)
# Codes: 1=solo, 2=2-3, 3=4-5, 4=6-10, 5=11-19, 6=20-30, 7=31-50,
#        8=51-100, 9=101+
geih[, firmsize_cat := as.numeric(p6870)]

# Create firm size groups for triple-diff
# Small firms: ≤10 employees (codes 1-4)
# Medium firms: 11-50 employees (codes 5-7)
geih[, small_firm := as.integer(firmsize_cat %in% 1:4)]
geih[, medium_firm := as.integer(firmsize_cat %in% 5:7)]
geih[, large_firm := as.integer(firmsize_cat %in% 8:9)]

# ---- Benefit receipt indicators ----
# P6424S1: Paid vacation entitlement (1=yes, 2=no)
geih[, benefit_vacation := as.integer(p6424s1 == 1)]
# P6424S2: Prima de navidad entitlement (1=yes, 2=no)
geih[, benefit_prima_nav := as.integer(p6424s2 == 1)]
# P6424S3: Cesantías entitlement (1=yes, 2=no)
geih[, benefit_cesantias := as.integer(p6424s3 == 1)]
# P6920: Contributing to pension fund (1=yes, 2=no)
geih[, benefit_pension := as.integer(p6920 == 1)]

# Benefit completeness index (0-4)
geih[, benefit_index := rowSums(cbind(benefit_vacation, benefit_prima_nav,
                                       benefit_cesantias, benefit_pension),
                                 na.rm = FALSE)]

# ---- Earnings relative to minimum wage ----
# Colombian minimum wages (monthly, COP):
mw_table <- data.table(
  year = 2010:2016,
  min_wage = c(515000, 535600, 566700, 589500, 616000, 644350, 689455)
)

geih <- merge(geih, mw_table, by = "year", all.x = TRUE)

# Earnings in multiples of minimum wage
geih[, earnings_mw := earnings / min_wage]

# Treatment: below 10 minimum wages (reform applied below 10 MW)
geih[, below_10mw := as.integer(earnings_mw < 10)]

# ---- Treatment and period indicators ----
geih[, post := as.integer(year >= 2013)]

# Quarter for clustering/FE
geih[, quarter := ceiling(month / 3)]
geih[, year_quarter := paste0(year, "Q", quarter)]

# City (AREA or DPTO — AREA gives metro-area code)
geih[, city := as.factor(area)]

# Sector (RAMA2D — 2-digit ISIC)
geih[, sector := as.numeric(rama2d)]

# ---- Sample restrictions ----
cat("\n--- Sample restrictions ---\n")

# Start: all employed persons
n0 <- nrow(geih)
cat(sprintf("All employed: %s\n", format(n0, big.mark = ",")))

# Restrict to wage/salary workers (P6430 == 1: "Obrero o empleado de empresa particular"
# or P6430 == 2: "Obrero o empleado del gobierno")
# Exclude self-employed, employers, unpaid family workers
geih <- geih[p6430 %in% c(1, 2)]
cat(sprintf("Wage/salary workers: %s (dropped %s)\n",
            format(nrow(geih), big.mark = ","),
            format(n0 - nrow(geih), big.mark = ",")))

# Restrict to ages 18-65
n1 <- nrow(geih)
geih <- geih[age >= 18 & age <= 65]
cat(sprintf("Ages 18-65: %s (dropped %s)\n",
            format(nrow(geih), big.mark = ","),
            format(n1 - nrow(geih), big.mark = ",")))

# Require non-missing earnings
n2 <- nrow(geih)
geih <- geih[!is.na(earnings) & earnings > 0]
cat(sprintf("Non-missing positive earnings: %s (dropped %s)\n",
            format(nrow(geih), big.mark = ","),
            format(n2 - nrow(geih), big.mark = ",")))

# Require non-missing firm size
n3 <- nrow(geih)
geih <- geih[!is.na(firmsize_cat)]
cat(sprintf("Non-missing firm size: %s (dropped %s)\n",
            format(nrow(geih), big.mark = ","),
            format(n3 - nrow(geih), big.mark = ",")))

# Restrict to small (≤10) and medium (11-50) firms for triple-diff
# Large firms are too different in compliance behavior
n4 <- nrow(geih)
geih <- geih[small_firm == 1 | medium_firm == 1]
cat(sprintf("Small or medium firms (≤50 employees): %s (dropped %s)\n",
            format(nrow(geih), big.mark = ","),
            format(n4 - nrow(geih), big.mark = ",")))

# Require at least one benefit variable non-missing
n5 <- nrow(geih)
geih <- geih[!is.na(benefit_vacation) | !is.na(benefit_prima_nav) |
             !is.na(benefit_cesantias) | !is.na(benefit_pension)]
cat(sprintf("At least one benefit var non-missing: %s (dropped %s)\n",
            format(nrow(geih), big.mark = ","),
            format(n5 - nrow(geih), big.mark = ",")))

# Focus on workers with formal contracts for the benefit-quality analysis
# (We also run on the full sample to show extensive margin as context)
geih[, formal := as.integer(has_contract == 1)]

# ---- Summary statistics ----
cat("\n--- Summary statistics ---\n")
cat(sprintf("Final analytic sample: %s observations\n",
            format(nrow(geih), big.mark = ",")))
cat(sprintf("Years: %s\n", paste(sort(unique(geih$year)), collapse = ", ")))
cat(sprintf("Cities: %d\n", length(unique(geih$city))))

cat("\nBy treatment group:\n")
cat(sprintf("  Below 10 MW: %s (%.1f%%)\n",
            format(sum(geih$below_10mw == 1, na.rm = TRUE), big.mark = ","),
            100 * mean(geih$below_10mw == 1, na.rm = TRUE)))
cat(sprintf("  Small firms: %s (%.1f%%)\n",
            format(sum(geih$small_firm == 1), big.mark = ","),
            100 * mean(geih$small_firm == 1)))

cat("\nBenefit receipt rates (full sample):\n")
for (v in c("benefit_vacation", "benefit_prima_nav", "benefit_cesantias", "benefit_pension")) {
  cat(sprintf("  %s: %.1f%%\n", v, 100 * mean(geih[[v]], na.rm = TRUE)))
}

cat("\nBenefit index distribution:\n")
print(table(geih$benefit_index, useNA = "ifany"))

# ---- Save analytic dataset ----
analytic_path <- file.path(DATA_DIR, "geih_analytic.rds")
saveRDS(geih, analytic_path)
cat(sprintf("\nSaved analytic dataset: %s (%s bytes)\n",
            analytic_path, format(file.size(analytic_path), big.mark = ",")))

# Also save a formal-workers-only subset for the main analysis
geih_formal <- geih[formal == 1]
formal_path <- file.path(DATA_DIR, "geih_formal.rds")
saveRDS(geih_formal, formal_path)
cat(sprintf("Saved formal-workers subset: %s obs\n",
            format(nrow(geih_formal), big.mark = ",")))

cat("\n=== Data cleaning complete ===\n")
