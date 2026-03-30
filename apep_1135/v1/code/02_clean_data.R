# ==============================================================================
# 02_clean_data.R — Construct analysis dataset
# ==============================================================================
source("00_packages.R")

# Load raw data
qwi_sa <- readRDS("../data/qwi_sa_raw.rds")
qwi_total <- readRDS("../data/qwi_total.rds")
qwi_rh <- readRDS("../data/qwi_rh_raw.rds")
trade_df <- readRDS("../data/comtrade_raw.rds")

# --- 1. Clean QWI industry data ---
cat("Cleaning QWI industry data...\n")

# Create time variable (quarters since 2013Q1)
qwi_sa <- qwi_sa %>%
  mutate(
    fips = as.character(fips),
    time_q = (year - 2013) * 4 + quarter,
    yq = paste0(year, "Q", quarter),
    state_fips = substr(fips, 1, 2)
  ) %>%
  filter(!is.na(Emp))

cat(sprintf("  %s rows after cleaning\n", format(nrow(qwi_sa), big.mark = ",")))
cat(sprintf("  Counties: %d\n", n_distinct(qwi_sa$fips)))
cat(sprintf("  Quarters: %d (%s to %s)\n", n_distinct(qwi_sa$yq),
            min(qwi_sa$yq), max(qwi_sa$yq)))

# --- 2. Construct county-level waste exposure ---
cat("Constructing waste exposure measure...\n")

# Pre-period average employment by county x industry
pre_emp <- qwi_sa %>%
  filter(year >= 2015 & year <= 2017, industry == "562") %>%
  group_by(fips) %>%
  summarise(waste_emp_pre = mean(Emp, na.rm = TRUE), .groups = "drop")

# Pre-period average total employment
pre_total <- qwi_total %>%
  mutate(fips = as.character(fips)) %>%
  filter(year >= 2015 & year <= 2017) %>%
  group_by(fips) %>%
  summarise(total_emp_pre = mean(total_emp, na.rm = TRUE), .groups = "drop")

# Merge and compute exposure share
exposure <- pre_emp %>%
  inner_join(pre_total, by = "fips") %>%
  mutate(
    waste_share = waste_emp_pre / total_emp_pre,
    high_exposure = as.integer(waste_share > median(waste_share, na.rm = TRUE))
  ) %>%
  filter(!is.na(waste_share) & is.finite(waste_share))

cat(sprintf("  Counties with exposure: %d\n", nrow(exposure)))
cat(sprintf("  High exposure (above median): %d\n", sum(exposure$high_exposure)))
cat(sprintf("  Waste share: median=%.4f, mean=%.4f, sd=%.4f\n",
            median(exposure$waste_share), mean(exposure$waste_share), sd(exposure$waste_share)))

# --- 3. Merge exposure to panel ---
panel <- qwi_sa %>%
  inner_join(exposure %>% select(fips, waste_share, high_exposure, waste_emp_pre, total_emp_pre),
             by = "fips") %>%
  mutate(
    post = as.integer(year >= 2018),
    log_emp = log(Emp + 1),
    earn_per_worker = EarnS / pmax(Emp, 1),
    log_earn = log(earn_per_worker + 1)
  )

cat(sprintf("  Panel: %s rows, %d counties, %d quarters\n",
            format(nrow(panel), big.mark = ","),
            n_distinct(panel$fips),
            n_distinct(panel$time_q)))

# --- 4. Treatment timing for C-S: first quarter in post period ---
# For C-S DiD, we define treatment group by exposure tercile
# "First treated" = 2018Q1 for high-exposure counties, never for low-exposure
panel <- panel %>%
  mutate(
    first_treat = if_else(high_exposure == 1, 21L, 0L)  # 2018Q1 = quarter 21
  )

# --- 5. Clean Comtrade data ---
cat("\nCleaning Comtrade data...\n")
trade_clean <- trade_df %>%
  select(period, cmdCode, cmdDesc, primaryValue, netWgt, qty) %>%
  mutate(
    year = as.integer(period),
    hs_code = as.character(cmdCode),
    value_usd = as.numeric(primaryValue),
    weight_kg = as.numeric(netWgt)
  ) %>%
  filter(!is.na(year))

cat("  Trade data:\n")
trade_summary <- trade_clean %>%
  group_by(hs_code, year) %>%
  summarise(value_usd = sum(value_usd, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = year, values_from = value_usd) %>%
  as.data.frame()
print(trade_summary)

# --- 6. Save analysis datasets ---
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(exposure, "../data/exposure.rds")
saveRDS(trade_clean, "../data/trade_clean.rds")

cat("\nAnalysis dataset saved.\n")
cat(sprintf("  Panel dimensions: %s rows × %d cols\n",
            format(nrow(panel), big.mark = ","), ncol(panel)))

# --- 7. Summary stats for validation ---
cat("\n--- Key Descriptives ---\n")
waste_panel <- panel %>% filter(industry == "562")
cat(sprintf("NAICS 562 panel: %s county-quarters\n",
            format(nrow(waste_panel), big.mark = ",")))
cat(sprintf("Counties with waste employment: %d\n", n_distinct(waste_panel$fips)))
cat(sprintf("Pre-period mean emp (562): %.1f\n",
            mean(waste_panel$Emp[waste_panel$post == 0], na.rm = TRUE)))
cat(sprintf("Post-period mean emp (562): %.1f\n",
            mean(waste_panel$Emp[waste_panel$post == 1], na.rm = TRUE)))
