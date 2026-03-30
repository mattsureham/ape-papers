# 02_clean_data.R — Clean and construct analysis panel
# apep_1162: Belgium SSC Cut and Employment

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

# ─────────────────────────────────────────────────────────────
# Load raw data
# ─────────────────────────────────────────────────────────────
emp_raw  <- readRDS("emp_raw.rds")
lci_raw  <- readRDS("lci_raw.rds")
comp_raw <- readRDS("comp_raw.rds")
gva_raw  <- readRDS("gva_raw.rds")

# ─────────────────────────────────────────────────────────────
# 1. Employment panel: country × sector × quarter
# ─────────────────────────────────────────────────────────────

# NACE A*10 sector codes
nace_sectors <- c("A", "B-E", "F", "G-I", "J", "K", "L", "M_N", "O-Q", "R-U")
nace_labels <- c(
  "A" = "Agriculture",
  "B-E" = "Industry",
  "F" = "Construction",
  "G-I" = "Trade/Transport/Hospitality",
  "J" = "ICT",
  "K" = "Finance/Insurance",
  "L" = "Real Estate",
  "M_N" = "Professional/Admin Services",
  "O-Q" = "Public Admin/Education/Health",
  "R-U" = "Arts/Other Services"
)

emp <- emp_raw |>
  filter(nace_r2 %in% nace_sectors) |>
  mutate(
    year = year(time),
    quarter = quarter(time),
    yq = year + (quarter - 1) / 4,
    geo = as.character(geo),
    nace = as.character(nace_r2),
    emp = values
  ) |>
  filter(yq >= 2013.0, yq <= 2019.75) |>  # 2013-Q1 to 2019-Q4
  select(geo, nace, year, quarter, yq, emp)

stopifnot("No Belgian employment data" = sum(emp$geo == "BE") > 0)
cat(sprintf("Employment panel: %d obs, %d country-sector pairs\n",
            nrow(emp), n_distinct(paste(emp$geo, emp$nace))))

# ─────────────────────────────────────────────────────────────
# 2. Labor Cost Index: wages vs non-wage costs
# ─────────────────────────────────────────────────────────────

lci <- lci_raw |>
  mutate(
    year = year(time),
    quarter = quarter(time),
    yq = year + (quarter - 1) / 4,
    geo = as.character(geo),
    component = as.character(lcstruct)
  ) |>
  filter(yq >= 2013.0, yq <= 2019.75) |>
  select(geo, component, yq, values) |>
  pivot_wider(names_from = component, values_from = values) |>
  rename(wage_index = D11, nonwage_index = D12_D4_MD5)

cat(sprintf("LCI panel: %d obs\n", nrow(lci)))

# ─────────────────────────────────────────────────────────────
# 3. Compensation breakdown: employer SSC share by sector
# ─────────────────────────────────────────────────────────────

comp <- comp_raw |>
  filter(nace_r2 %in% nace_sectors) |>
  mutate(
    year = year(time),
    quarter = quarter(time),
    yq = year + (quarter - 1) / 4,
    geo = as.character(geo),
    nace = as.character(nace_r2),
    item = as.character(na_item)
  ) |>
  filter(yq >= 2013.0, yq <= 2019.75) |>
  select(geo, nace, yq, item, values) |>
  pivot_wider(names_from = item, values_from = values) |>
  rename(compensation = D1, wages = D11, employer_ssc = D12) |>
  mutate(ssc_share = employer_ssc / compensation)

cat(sprintf("Compensation panel: %d obs\n", nrow(comp)))

# ─────────────────────────────────────────────────────────────
# 4. Labor intensity by sector (pre-treatment average)
#    = Compensation / GVA in 2013-2015
# ─────────────────────────────────────────────────────────────

gva <- gva_raw |>
  filter(nace_r2 %in% nace_sectors) |>
  mutate(
    year = year(time),
    geo = as.character(geo),
    nace = as.character(nace_r2),
    item = as.character(na_item)
  ) |>
  filter(year >= 2013, year <= 2015) |>
  select(geo, nace, year, item, values) |>
  pivot_wider(names_from = item, values_from = values) |>
  rename(gva = B1G, comp_annual = D1)

# Pre-treatment average labor intensity by country-sector
labor_intensity <- gva |>
  group_by(geo, nace) |>
  summarise(
    labor_share = mean(comp_annual / gva, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("Labor intensity: %d country-sector pairs\n", nrow(labor_intensity)))

# ─────────────────────────────────────────────────────────────
# 5. Merge into analysis panel
# ─────────────────────────────────────────────────────────────

panel <- emp |>
  left_join(labor_intensity, by = c("geo", "nace")) |>
  mutate(
    belgium = as.integer(geo == "BE"),
    post = as.integer(yq >= 2016.25),   # 2016-Q2 onwards (April 2016 = first cut)
    full_post = as.integer(yq >= 2018.0),  # 2018-Q1 onwards (full 25% rate)
    log_emp = log(emp),
    sector_label = nace_labels[nace],
    # Time index for fixed effects
    time_id = as.integer(factor(yq)),
    cs_id = paste(geo, nace, sep = "_")
  )

# Belgium-specific SSC intensity: higher labor_share = larger cost reduction
# Normalize labor share to mean 0, SD 1 within Belgium pre-treatment
be_ls <- panel |>
  filter(geo == "BE", !post) |>
  summarise(m = mean(labor_share, na.rm = TRUE),
            s = sd(labor_share, na.rm = TRUE))

panel <- panel |>
  mutate(
    labor_intensity_z = (labor_share - be_ls$m) / be_ls$s
  )

# Drop sectors with missing data
panel <- panel |> filter(!is.na(emp), !is.na(labor_share))

cat(sprintf("\nFinal panel: %d obs\n", nrow(panel)))
cat(sprintf("  Countries: %s\n", paste(sort(unique(panel$geo)), collapse = ", ")))
cat(sprintf("  Sectors: %d\n", n_distinct(panel$nace)))
cat(sprintf("  Quarters: %d (%s to %s)\n",
            n_distinct(panel$yq),
            min(panel$yq), max(panel$yq)))
cat(sprintf("  Belgium obs: %d\n", sum(panel$belgium)))

# ─────────────────────────────────────────────────────────────
# Save
# ─────────────────────────────────────────────────────────────

saveRDS(panel, "panel.rds")
saveRDS(lci, "lci.rds")
saveRDS(comp, "comp.rds")
saveRDS(labor_intensity, "labor_intensity.rds")

cat("\nCleaned data saved.\n")
