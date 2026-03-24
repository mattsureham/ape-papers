## 01_fetch_data.R — Fetch Eurostat data for Croatia fiscalization study
## apep_0877

source("code/00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# ---------------------------------------------------------------
# 1. VAT revenue as % of GDP — gov_10a_taxag
#    D211 = VAT, sector S13 = General government, unit = PC_GDP
# ---------------------------------------------------------------
cat("Fetching VAT/GDP data (gov_10a_taxag)...\n")

# Countries: Croatia + 5 controls (Slovakia, Austria, Slovenia, Romania, Hungary)
countries <- c("HR", "SK", "AT", "SI", "RO", "HU")

vat_raw <- get_eurostat("gov_10a_taxag", time_format = "num",
                         filters = list(
                           na_item = "D211",
                           sector = "S13",
                           unit = "PC_GDP",
                           geo = countries
                         ))

stopifnot("No VAT data returned" = nrow(vat_raw) > 0)

vat <- vat_raw %>%
  rename(year = time, country = geo, vat_gdp = values) %>%
  filter(year >= 2008, year <= 2023) %>%
  select(country, year, vat_gdp) %>%
  arrange(country, year)

cat(sprintf("VAT/GDP: %d obs, %d countries, years %d-%d\n",
            nrow(vat), n_distinct(vat$country), min(vat$year), max(vat$year)))

# Validate: Croatia must have jump in 2012->2013
hr_vat <- vat %>% filter(country == "HR")
stopifnot("Croatia VAT data missing" = nrow(hr_vat) > 0)
cat(sprintf("Croatia VAT/GDP 2012: %.1f%%, 2013: %.1f%% (jump: %.2fpp)\n",
            hr_vat$vat_gdp[hr_vat$year == 2012],
            hr_vat$vat_gdp[hr_vat$year == 2013],
            hr_vat$vat_gdp[hr_vat$year == 2013] - hr_vat$vat_gdp[hr_vat$year == 2012]))

saveRDS(vat, "data/vat_gdp.rds")
cat("Saved data/vat_gdp.rds\n")

# ---------------------------------------------------------------
# 2. National Accounts by NACE A64 — nama_10_a64
#    Gross value added by sector — primary sector-level data source
#    Covers ALL NACE sectors uniformly (unlike SBS which splits
#    industry/trade/services into separate datasets)
# ---------------------------------------------------------------
cat("\nFetching GVA by sector (nama_10_a64)...\n")

gva_raw <- get_eurostat("nama_10_a64", time_format = "num",
                         filters = list(
                           geo = countries,
                           na_item = "B1G",  # Gross value added
                           unit = "CP_MEUR"  # Current prices, millions EUR
                         ))

stopifnot("No GVA data returned" = nrow(gva_raw) > 0)

gva <- gva_raw %>%
  rename(year = time, country = geo, gva = values, nace = nace_r2) %>%
  filter(year >= 2008, year <= 2023) %>%
  select(country, year, nace, gva) %>%
  arrange(country, nace, year)

cat(sprintf("GVA: %d obs, %d country-sector pairs\n",
            nrow(gva), n_distinct(paste(gva$country, gva$nace))))

hr_gva <- gva %>% filter(country == "HR")
cat(sprintf("Croatia GVA: %d obs, %d sectors, years %d-%d\n",
            nrow(hr_gva), n_distinct(hr_gva$nace), min(hr_gva$year), max(hr_gva$year)))
cat("Croatia NACE sectors:\n")
print(sort(unique(hr_gva$nace)))

saveRDS(gva, "data/gva_sector.rds")
cat("Saved data/gva_sector.rds\n")

# ---------------------------------------------------------------
# 3. SBS turnover data — fetch industry, trade, and services separately
# ---------------------------------------------------------------
cat("\nFetching SBS sector turnover...\n")

# Industry (B-E)
sbs_ind <- get_eurostat("sbs_na_ind_r2", time_format = "num",
                         filters = list(
                           geo = countries,
                           indic_sb = "V12110"  # Turnover
                         ))
cat(sprintf("SBS industry: %d obs\n", nrow(sbs_ind)))

# Trade (G)
sbs_trade <- get_eurostat("sbs_na_dt_r2", time_format = "num",
                           filters = list(
                             geo = countries,
                             indic_sb = "V12110"
                           ))
cat(sprintf("SBS trade: %d obs\n", nrow(sbs_trade)))

# Services (H-S excl K)
sbs_serv <- get_eurostat("sbs_na_1a_se_r2", time_format = "num",
                          filters = list(
                            geo = countries,
                            indic_sb = "V12110"
                          ))
cat(sprintf("SBS services: %d obs\n", nrow(sbs_serv)))

# Combine all SBS data
sbs_all <- bind_rows(sbs_ind, sbs_trade, sbs_serv) %>%
  rename(year = time, country = geo, turnover = values, nace = nace_r2) %>%
  filter(year >= 2008, year <= 2021) %>%
  select(country, year, nace, turnover) %>%
  distinct() %>%
  arrange(country, nace, year)

cat(sprintf("SBS combined: %d obs, %d country-sector pairs\n",
            nrow(sbs_all), n_distinct(paste(sbs_all$country, sbs_all$nace))))

hr_sbs <- sbs_all %>% filter(country == "HR")
cat(sprintf("Croatia SBS: %d obs, %d sectors\n",
            nrow(hr_sbs), n_distinct(hr_sbs$nace)))

saveRDS(sbs_all, "data/sbs_turnover.rds")
cat("Saved data/sbs_turnover.rds\n")

# ---------------------------------------------------------------
# 4. Additional macro controls — GDP growth, unemployment
# ---------------------------------------------------------------
cat("\nFetching macro controls...\n")

# GDP growth
gdp_raw <- get_eurostat("nama_10_gdp", time_format = "num",
                         filters = list(
                           geo = countries,
                           na_item = "B1GQ",
                           unit = "CLV_PCH_PRE"
                         ))

gdp <- gdp_raw %>%
  rename(year = time, country = geo, gdp_growth = values) %>%
  filter(year >= 2008, year <= 2023) %>%
  select(country, year, gdp_growth)

# Unemployment rate
unemp_raw <- get_eurostat("une_rt_a", time_format = "num",
                           filters = list(
                             geo = countries,
                             sex = "T",
                             age = "Y15-74",
                             unit = "PC_ACT"
                           ))

unemp <- unemp_raw %>%
  rename(year = time, country = geo, unemp_rate = values) %>%
  filter(year >= 2008, year <= 2023) %>%
  select(country, year, unemp_rate)

macro <- gdp %>%
  left_join(unemp, by = c("country", "year"))

saveRDS(macro, "data/macro_controls.rds")
cat(sprintf("Macro controls: %d obs\n", nrow(macro)))

cat("\n=== All data fetched successfully ===\n")
