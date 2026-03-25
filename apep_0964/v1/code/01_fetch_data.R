# 01_fetch_data.R — Fetch Eurostat sector accounts + construct ATAD treatment
source("00_packages.R")

cat("=== Fetching Eurostat sector accounts data ===\n")

# ---- 1. Financial balance sheets: debt securities (F3) and loans (F4) ----
cat("Fetching nasa_10_f_bs (financial balance sheets)...\n")
fbs <- get_eurostat("nasa_10_f_bs", time_format = "num")
fbs <- as.data.table(fbs)
cat(sprintf("  Raw rows: %d, cols: %s\n", nrow(fbs), paste(names(fbs), collapse=", ")))

# S11 = non-financial corps, LIAB, NCO (non-consolidated), MIO_NAC
fbs_s11 <- fbs[sector == "S11" & finpos == "LIAB" & co_nco == "NCO" &
                 na_item %in% c("F3", "F4", "F5") &
                 unit == "MIO_NAC",
               .(geo = as.character(geo), year = as.numeric(TIME_PERIOD),
                 na_item = as.character(na_item), values = as.numeric(values))]
cat(sprintf("  S11 liabilities (F3/F4/F5): %d rows\n", nrow(fbs_s11)))

# Pivot wide
fbs_wide <- dcast(fbs_s11, geo + year ~ na_item, value.var = "values")
setnames(fbs_wide, c("F3", "F4", "F5"), c("debt_securities", "loans", "equity"))
cat(sprintf("  Wide panel: %d rows, countries: %s\n", nrow(fbs_wide),
            paste(sort(unique(fbs_wide$geo)), collapse = ", ")))

# ---- 2. Non-financial transactions: interest paid (D41) and GOS (B2A3G) ----
cat("Fetching nasa_10_nf_tr (non-financial transactions)...\n")
nftr <- get_eurostat("nasa_10_nf_tr", time_format = "num")
nftr <- as.data.table(nftr)
cat(sprintf("  Raw rows: %d, cols: %s\n", nrow(nftr), paste(names(nftr), collapse=", ")))

# D41 PAID = interest paid by S11; B2A3G = gross operating surplus
# Use CP_MNAC (millions national currency)
d41_paid <- nftr[sector == "S11" & unit == "CP_MNAC" &
                   na_item == "D41" & direct == "PAID",
                 .(geo = as.character(geo), year = as.numeric(TIME_PERIOD),
                   interest_paid = as.numeric(values))]

d41_recv <- nftr[sector == "S11" & unit == "CP_MNAC" &
                   na_item == "D41" & direct == "RECV",
                 .(geo = as.character(geo), year = as.numeric(TIME_PERIOD),
                   interest_recv = as.numeric(values))]

b2a3g <- nftr[sector == "S11" & unit == "CP_MNAC" &
                na_item == "B2A3G",
              .(geo = as.character(geo), year = as.numeric(TIME_PERIOD),
                gos_ebitda = as.numeric(values))]

cat(sprintf("  D41 PAID: %d, D41 RECV: %d, B2A3G: %d rows\n",
            nrow(d41_paid), nrow(d41_recv), nrow(b2a3g)))

nftr_wide <- merge(d41_paid, b2a3g, by = c("geo", "year"), all = TRUE)
nftr_wide <- merge(nftr_wide, d41_recv, by = c("geo", "year"), all.x = TRUE)
cat(sprintf("  Merged transactions: %d rows\n", nrow(nftr_wide)))

# ---- 3. Merge financial balance sheet + transaction data ----
panel <- merge(fbs_wide, nftr_wide, by = c("geo", "year"), all = TRUE)

# ---- 4. ATAD treatment coding ----
# Source: Council Directive (EU) 2016/1164, KPMG ATAD Implementation Guide 2019
atad <- data.table(
  geo = c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE"),
  # De minimis threshold in EUR millions
  de_minimis_eur = c(3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
                     3, 3, 3, 3, 0, 0, 3, 3, 3, 1,
                     3, 1, 1, 0, 1, 1, 5),
  # EBITDA cap percentage
  ebitda_cap_pct = c(30, 30, 30, 30, 30, 30, 30, 30, 25, 30,
                     30, 30, 30, 30, 30, 30, 30, 30, 30, 20,
                     30, 30, 30, 25, 30, 30, 30),
  # Year of effective adoption
  adoption_year = c(2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2024,
                    2019, 2024, 2019, 2022, 2019, 2019, 2019, 2019, 2019, 2019,
                    2019, 2019, 2019, 2024, 2024, 2024, 2019),
  # Derogation country flag (adopted later than Jan 2019)
  derogation = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
                 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 1, 1, 1, 0)
)

# Treatment intensity: inverse of de minimis (higher = more firms constrained)
# Standardize: 0 = EUR 5M (weakest), 1 = EUR 0 (strongest)
atad[, dose := (5 - de_minimis_eur) / 5]

cat(sprintf("ATAD treatment map: %d countries\n", nrow(atad)))
cat(sprintf("  De minimis: nil=%d, 1M=%d, 3M=%d, 5M=%d\n",
            sum(atad$de_minimis_eur == 0), sum(atad$de_minimis_eur == 1),
            sum(atad$de_minimis_eur == 3), sum(atad$de_minimis_eur == 5)))
cat(sprintf("  Derogation: %s\n", paste(atad[derogation == 1, geo], collapse = ", ")))

# ---- 5. Merge treatment to panel ----
panel <- merge(panel, atad, by = "geo", all.x = TRUE)

# Keep only EU27 countries with ATAD data
panel <- panel[!is.na(adoption_year)]

# Create treatment indicators
panel[, adopted := as.integer(year >= adoption_year)]
panel[, post2019 := as.integer(year >= 2019)]

# Construct key ratios
# Net interest = paid - received (aligns with ATAD's net borrowing cost constraint)
panel[, net_interest := interest_paid - fifelse(is.na(interest_recv), 0, interest_recv)]
panel[, interest_gos_ratio := interest_paid / gos_ebitda]
panel[, net_interest_gos := net_interest / gos_ebitda]
panel[, debt_ratio := debt_securities / (debt_securities + loans)]
panel[, loan_to_bond := loans / debt_securities]
panel[, leverage := (debt_securities + loans) / equity]

# ---- 6. Macro controls ----
cat("Fetching GDP growth (nama_10_gdp)...\n")
gdp <- get_eurostat("nama_10_gdp", time_format = "num")
gdp <- as.data.table(gdp)
gdp_growth <- gdp[na_item == "B1GQ" & unit == "CLV_PCH_PRE",
                   .(geo = as.character(geo), year = as.numeric(TIME_PERIOD),
                     gdp_growth = as.numeric(values))]
panel <- merge(panel, gdp_growth, by = c("geo", "year"), all.x = TRUE)

cat("Fetching HICP inflation (prc_hicp_aind)...\n")
hicp <- get_eurostat("prc_hicp_aind", time_format = "num")
hicp <- as.data.table(hicp)
inflation <- hicp[coicop == "CP00" & unit == "RCH_A_AVG",
                   .(geo = as.character(geo), year = as.numeric(TIME_PERIOD),
                     inflation = as.numeric(values))]
panel <- merge(panel, inflation, by = c("geo", "year"), all.x = TRUE)

# ---- 7. Filter to analysis period ----
panel <- panel[year >= 2012 & year <= 2023]

# Summary stats
cat(sprintf("\n=== FINAL PANEL ===\n"))
cat(sprintf("Countries: %d\n", uniqueN(panel$geo)))
cat(sprintf("Years: %d (%d-%d)\n", uniqueN(panel$year),
            min(panel$year), max(panel$year)))
cat(sprintf("Country-years: %d\n", nrow(panel)))
cat(sprintf("Interest/GOS available: %d\n", sum(!is.na(panel$interest_gos_ratio))))
cat(sprintf("Debt composition available: %d\n", sum(!is.na(panel$debt_ratio))))

# Key outcome variation
cat(sprintf("\nInterest/GOS ratio (pre-2019):\n"))
pre <- panel[year < 2019 & !is.na(interest_gos_ratio)]
if (nrow(pre) > 0) {
  cat(sprintf("  Mean: %.4f, SD: %.4f, Min: %.4f, Max: %.4f\n",
              mean(pre$interest_gos_ratio), sd(pre$interest_gos_ratio),
              min(pre$interest_gos_ratio), max(pre$interest_gos_ratio)))
}

cat(sprintf("\nDebt securities share (pre-2019):\n"))
pre_d <- panel[year < 2019 & !is.na(debt_ratio)]
if (nrow(pre_d) > 0) {
  cat(sprintf("  Mean: %.4f, SD: %.4f\n",
              mean(pre_d$debt_ratio), sd(pre_d$debt_ratio)))
}

# ---- 8. Save ----
saveRDS(panel, "../data/panel.rds")
cat("\nSaved data/panel.rds\n")
saveRDS(atad, "../data/atad_treatment.rds")
cat("Saved data/atad_treatment.rds\n")
