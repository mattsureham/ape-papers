## 02_clean_data.R — Build analysis panels
## apep_0997: Romania Construction Tax Holiday

source("00_packages.R")

# ----------------------------------------------------------------
# 1. Fetch salaried employees (SAL_DC) for formalization measure
# ----------------------------------------------------------------
cat("Fetching salaried employees (SAL_DC) from Eurostat...\n")

sal_raw <- eurostat::get_eurostat("nama_10_a64_e",
                                  filters = list(geo = "RO",
                                                 na_item = "SAL_DC",
                                                 unit = "THS_PER"),
                                  time_format = "num")

keep_nace <- c("F", "C", "G", "H", "I", "J", "K", "L", "M", "N")

sal <- sal_raw %>%
  filter(nace_r2 %in% keep_nace) %>%
  select(nace_r2, year = time, salaried_ths = values) %>%
  arrange(nace_r2, year)

cat(sprintf("  SAL_DC: %d sector-years\n", nrow(sal)))

# ----------------------------------------------------------------
# 2. Load pre-fetched data
# ----------------------------------------------------------------
ann <- readRDS("../data/analysis_annual.rds")
lci_raw <- readRDS("../data/lci_raw.rds")
copr <- tryCatch(readRDS("../data/construction_prod.rds"), error = function(e) NULL)

# ----------------------------------------------------------------
# 3. Build annual analysis panel
# ----------------------------------------------------------------
cat("Building annual panel...\n")

panel_annual <- ann %>%
  filter(year >= 2010, year <= 2023) %>%
  left_join(sal, by = c("nace_r2", "year")) %>%
  mutate(
    # Self-employment = total employment - salaried
    self_emp_ths = employment_ths - salaried_ths,
    # Self-employment share (proxy for informality)
    self_emp_share = self_emp_ths / employment_ths,
    # Log outcomes
    log_emp = log(employment_ths),
    log_sal = log(salaried_ths),
    log_self = ifelse(self_emp_ths > 0, log(self_emp_ths), NA_real_),
    # Event time
    event_time = year - 2019,
    # Numeric sector ID for FE
    sector_id = as.integer(factor(nace_r2))
  )

cat(sprintf("  Annual panel: %d obs, %d sectors, years %d-%d\n",
            nrow(panel_annual),
            n_distinct(panel_annual$nace_r2),
            min(panel_annual$year),
            max(panel_annual$year)))

# ----------------------------------------------------------------
# 4. Build quarterly analysis panel
# ----------------------------------------------------------------
cat("Building quarterly panel...\n")

lfs <- readRDS("../data/analysis_quarterly.rds")

# LCI is already merged in the quarterly panel from 01_fetch_data.R
panel_quarterly <- lfs %>%
  filter(year >= 2010, year <= 2023) %>%
  mutate(
    log_emp = log(lfs_emp_ths),
    log_lci = ifelse(!is.na(lci) & lci > 0, log(lci), NA_real_),
    time_q = year + (quarter - 1) / 4,
    yq = paste0(year, "Q", quarter),
    # Event time in quarters (treatment = 2019Q1)
    event_q = (year - 2019) * 4 + (quarter - 1),
    sector_id = as.integer(factor(nace_r2)),
    # COVID dummy
    covid = ifelse(year == 2020 & quarter >= 2, 1L,
                   ifelse(year == 2021 & quarter <= 1, 1L, 0L))
  )

# Construction production index already merged from 01_fetch_data.R

cat(sprintf("  Quarterly panel: %d obs, %d sectors, %d-%d\n",
            nrow(panel_quarterly),
            n_distinct(panel_quarterly$nace_r2),
            min(panel_quarterly$year),
            max(panel_quarterly$year)))

# ----------------------------------------------------------------
# 5. Summary statistics
# ----------------------------------------------------------------
cat("\n=== Pre-Treatment Summary (2015-2018) ===\n")

pre_summary <- panel_annual %>%
  filter(year >= 2015, year <= 2018) %>%
  group_by(construction, sector_label) %>%
  summarise(
    mean_emp = mean(employment_ths, na.rm = TRUE),
    mean_sal = mean(salaried_ths, na.rm = TRUE),
    mean_self_share = mean(self_emp_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(construction), sector_label)

print(pre_summary, n = 20)

cat("\n=== Construction vs Control: Annual Trends ===\n")
panel_annual %>%
  filter(year >= 2015) %>%
  group_by(construction, year) %>%
  summarise(
    mean_emp = mean(employment_ths, na.rm = TRUE),
    mean_sal = mean(salaried_ths, na.rm = TRUE),
    mean_self_share = mean(self_emp_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print(n = 30)

cat("\n=== LCI Trends (Construction vs Manufacturing) ===\n")
panel_quarterly %>%
  filter(nace_r2 %in% c("F", "C"), year >= 2016) %>%
  select(nace_r2, year, quarter, lci) %>%
  pivot_wider(names_from = nace_r2, values_from = lci, names_prefix = "lci_") %>%
  print(n = 40)

# ----------------------------------------------------------------
# 6. Save clean panels
# ----------------------------------------------------------------
saveRDS(panel_annual, "../data/panel_annual.rds")
saveRDS(panel_quarterly, "../data/panel_quarterly.rds")

cat("\nSaved: data/panel_annual.rds, data/panel_quarterly.rds\n")
cat("02_clean_data.R complete.\n")
