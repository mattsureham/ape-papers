## 02_clean_data.R — Construct Fornero bite and analysis panel
## apep_0665

source("code/00_packages.R")

emp_5564 <- readRDS("data/emp_5564.rds")
emp_2564 <- readRDS("data/emp_2564.rds")
emp_1524 <- readRDS("data/emp_1524.rds")
gfcf_raw <- readRDS("data/gfcf_raw.rds")
rd_raw <- readRDS("data/rd_raw.rds")

cat("=== Cleaning data ===\n")

## ---- 1. Employment rates by NUTS2 ----
# Combine all age groups
emp <- bind_rows(
  emp_5564 %>% mutate(age_group = "55_64"),
  emp_2564 %>% mutate(age_group = "25_64"),
  emp_1524 %>% mutate(age_group = "15_24")
) %>%
  select(region = geo, year = TIME_PERIOD, age_group, emp_rate = OBS_VALUE) %>%
  filter(!is.na(emp_rate)) %>%
  mutate(year = as.integer(year))

# Keep NUTS2 only
emp <- emp %>% filter(nchar(region) == 4, grepl("^IT", region))
cat("NUTS2 regions:", paste(sort(unique(emp$region)), collapse = ", "), "\n")

## ---- 2. Construct Fornero bite ----
# Bite = change in 55-64 employment rate from 2010 to 2014
bite <- emp %>%
  filter(age_group == "55_64", year %in% c(2010, 2014)) %>%
  select(region, year, emp_rate) %>%
  pivot_wider(names_from = year, values_from = emp_rate, names_prefix = "y") %>%
  mutate(fornero_bite = y2014 - y2010) %>%
  select(region, fornero_bite, emp_2010 = y2010, emp_2014 = y2014)

cat("\nFornero bite distribution:\n")
print(summary(bite$fornero_bite))
cat("\nBite by region:\n")
print(bite %>% arrange(desc(fornero_bite)))

## ---- 3. GFCF panel ----
cat("GFCF columns:", paste(names(gfcf_raw), collapse = ", "), "\n")
gfcf <- gfcf_raw %>%
  select(region = geo, year = TIME_PERIOD, sector = nace_r2,
         gfcf = OBS_VALUE) %>%
  filter(!is.na(gfcf), nchar(region) == 4, grepl("^IT", region)) %>%
  mutate(year = as.integer(year))

cat("\nGFCF sectors:", paste(unique(gfcf$sector), collapse = ", "), "\n")

## ---- 4. R&D panel ----
rd <- rd_raw %>%
  select(region = geo, year = TIME_PERIOD, rd_spend = OBS_VALUE) %>%
  filter(!is.na(rd_spend), nchar(region) == 4, grepl("^IT", region)) %>%
  mutate(year = as.integer(year))

## ---- 5. Merge into analysis panel ----
# Start from GFCF (main outcome)
panel <- gfcf %>%
  filter(sector == "TOTAL") %>%
  select(region, year, gfcf_total = gfcf) %>%
  left_join(bite, by = "region") %>%
  left_join(rd, by = c("region", "year")) %>%
  filter(!is.na(fornero_bite))

# Add manufacturing GFCF
mfg <- gfcf %>% filter(sector == "C") %>%
  select(region, year, gfcf_mfg = gfcf)
panel <- panel %>% left_join(mfg, by = c("region", "year"))

# Add services GFCF
svc <- gfcf %>% filter(sector == "G-Q") %>%
  select(region, year, gfcf_svc = gfcf)
panel <- panel %>% left_join(svc, by = c("region", "year"))

# Add employment rates for mechanisms
emp_wide <- emp %>%
  pivot_wider(names_from = age_group, values_from = emp_rate, names_prefix = "emprate_")

panel <- panel %>%
  left_join(emp_wide, by = c("region", "year"))

## ---- 6. Construct variables ----
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2012),
    treat_intensity = fornero_bite * post,

    ln_gfcf = log(gfcf_total),
    ln_gfcf_mfg = ifelse(!is.na(gfcf_mfg) & gfcf_mfg > 0, log(gfcf_mfg), NA),
    ln_gfcf_svc = ifelse(!is.na(gfcf_svc) & gfcf_svc > 0, log(gfcf_svc), NA),
    ln_rd = ifelse(!is.na(rd_spend) & rd_spend > 0, log(rd_spend), NA),

    # Standardize bite for interpretability
    bite_std = (fornero_bite - mean(fornero_bite, na.rm = TRUE)) /
               sd(fornero_bite, na.rm = TRUE),
    treat_std = bite_std * post,

    rel_year = year - 2012
  )

## ---- Summary ----
cat("\n=== Panel summary ===\n")
cat("Rows:", nrow(panel), "\n")
cat("Regions:", length(unique(panel$region)), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")

saveRDS(panel, "data/panel.rds")
cat("Panel saved.\n")
