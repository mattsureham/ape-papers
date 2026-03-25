## 02_clean_data.R — Clean and construct analysis panel
## apep_0939: Employment Costs of Seismicity Regulation

library(tidyverse)
library(data.table)

data_dir <- "data"
if (!dir.exists(data_dir)) data_dir <- "../data"

# ===========================================================================
# 1. Load raw data
# ===========================================================================
cat("=== Loading raw data ===\n")

qcew_raw <- fread(file.path(data_dir, "qcew_oklahoma_raw.csv"))
treatment <- read_csv(file.path(data_dir, "treatment_mapping.csv"),
                       show_col_types = FALSE,
                       col_types = cols(county_fips = col_character()))

cat(sprintf("QCEW raw: %d rows\n", nrow(qcew_raw)))

# ===========================================================================
# 2. Filter QCEW to relevant industries and ownership
# ===========================================================================

# Keep only private ownership (own_code == 5) and county-level (agglvl_code == 74/75/76/78)
# agglvl_code 74 = county, by industry, NAICS 3-digit
# agglvl_code 73 = county, by industry, NAICS 2-digit
# agglvl_code 72 = county, by supersector
# agglvl_code 70 = county total, all industries
# own_code 5 = private, own_code 0 = total

# Target industries
target_naics <- c(
  "10",           # Total, all industries
  "1011",         # Natural resources and mining (supersector)
  "211",          # Oil and Gas Extraction
  "213",          # Support Activities for Mining
  "23",           # Construction
  "31-33",        # Manufacturing
  "44-45",        # Retail Trade
  "48-49",        # Transportation and Warehousing
  "62",           # Health Care and Social Assistance
  "72"            # Accommodation and Food Services
)

# Filter: private sector, county-level aggregation
qcew <- qcew_raw %>%
  filter(
    own_code %in% c(0, 5),  # Total or private
    agglvl_code %in% c(70, 71, 72, 73, 74, 75, 76, 78),  # County-level
    industry_code %in% target_naics
  ) %>%
  # Keep key columns, compute average quarterly employment
  mutate(
    county_fips = as.character(area_fips),
    emp = as.numeric(month1_emplvl + month2_emplvl + month3_emplvl) / 3,
    wages = as.numeric(total_qtrly_wages),
    estabs = as.numeric(qtrly_estabs),
    avg_wkly_wage = as.numeric(avg_wkly_wage),
    year = as.integer(year),
    qtr = as.integer(qtr)
  ) %>%
  select(county_fips, year, qtr, own_code, industry_code,
         emp, wages, estabs, avg_wkly_wage) %>%
  filter(!is.na(emp), emp > 0)

cat(sprintf("After filtering: %d rows\n", nrow(qcew)))
cat(sprintf("Industries: %s\n", paste(unique(qcew$industry_code), collapse = ", ")))
cat(sprintf("Counties: %d\n", length(unique(qcew$county_fips))))

# ===========================================================================
# 3. Construct analysis panel
# ===========================================================================

# Create year-quarter index
qcew <- qcew %>%
  mutate(
    yearqtr = year + (qtr - 1) / 4,
    yq = year * 4 + qtr  # Integer year-quarter for CS-DiD
  )

# Merge treatment information
qcew <- qcew %>%
  left_join(
    treatment %>%
      select(county_fips, directive_area, treatment_date) %>%
      mutate(
        treat_year = year(treatment_date),
        treat_qtr = quarter(treatment_date),
        first_treat_yq = treat_year * 4 + treat_qtr,
        treated_county = 1L
      ),
    by = "county_fips"
  ) %>%
  mutate(
    treated_county = replace_na(treated_county, 0L),
    directive_area = replace_na(directive_area, "Control"),
    # For never-treated, set first_treat_yq to 0 (CS-DiD convention)
    first_treat_yq = replace_na(first_treat_yq, 0L),
    # Post-treatment indicator
    post = if_else(treated_county == 1 & yq >= first_treat_yq, 1L, 0L)
  )

cat(sprintf("\nPanel: %d county-quarter-industry obs\n", nrow(qcew)))
cat(sprintf("Treated counties: %d\n", sum(qcew$treated_county == 1 & qcew$industry_code == "10") /
              length(unique(qcew$yq[qcew$treated_county == 1]))))
cat(sprintf("Control counties: %d\n", n_distinct(qcew$county_fips[qcew$treated_county == 0])))

# ===========================================================================
# 4. Build analysis datasets by industry
# ===========================================================================

# Primary: Total private employment
panel_total <- qcew %>%
  filter(industry_code == "10", own_code == 5) %>%
  select(county_fips, year, qtr, yq, yearqtr, emp, wages, estabs,
         avg_wkly_wage, treated_county, directive_area, first_treat_yq, post)

# Mining support services (NAICS 213) — primary treatment channel
panel_213 <- qcew %>%
  filter(industry_code == "213") %>%
  select(county_fips, year, qtr, yq, yearqtr, emp, wages, estabs,
         avg_wkly_wage, treated_county, directive_area, first_treat_yq, post)

# Oil and gas extraction (NAICS 211) — should be less affected
panel_211 <- qcew %>%
  filter(industry_code == "211") %>%
  select(county_fips, year, qtr, yq, yearqtr, emp, wages, estabs,
         avg_wkly_wage, treated_county, directive_area, first_treat_yq, post)

# Placebo industries (should NOT respond)
panel_retail <- qcew %>%
  filter(industry_code == "44-45") %>%
  select(county_fips, year, qtr, yq, yearqtr, emp, wages, estabs,
         avg_wkly_wage, treated_county, directive_area, first_treat_yq, post)

panel_food <- qcew %>%
  filter(industry_code == "72") %>%
  select(county_fips, year, qtr, yq, yearqtr, emp, wages, estabs,
         avg_wkly_wage, treated_county, directive_area, first_treat_yq, post)

# Log employment
for (p in list(panel_total, panel_213, panel_211, panel_retail, panel_food)) {
  p$log_emp <- log(p$emp)
}
panel_total$log_emp <- log(panel_total$emp)
panel_213$log_emp <- log(panel_213$emp)
panel_211$log_emp <- log(panel_211$emp)
panel_retail$log_emp <- log(panel_retail$emp)
panel_food$log_emp <- log(panel_food$emp)

# ===========================================================================
# 5. Create numeric county ID for CS-DiD
# ===========================================================================
county_ids <- qcew %>%
  distinct(county_fips) %>%
  mutate(county_id = row_number())

for (pname in c("panel_total", "panel_213", "panel_211", "panel_retail", "panel_food")) {
  assign(pname, get(pname) %>% left_join(county_ids, by = "county_fips"))
}

# ===========================================================================
# 6. Save cleaned panels
# ===========================================================================
write_csv(panel_total, file.path(data_dir, "panel_total.csv"))
write_csv(panel_213, file.path(data_dir, "panel_213.csv"))
write_csv(panel_211, file.path(data_dir, "panel_211.csv"))
write_csv(panel_retail, file.path(data_dir, "panel_retail.csv"))
write_csv(panel_food, file.path(data_dir, "panel_food.csv"))
write_csv(county_ids, file.path(data_dir, "county_ids.csv"))

# ===========================================================================
# 7. Summary statistics
# ===========================================================================
cat("\n=== Panel Summary ===\n")
for (pname in c("panel_total", "panel_213", "panel_211", "panel_retail", "panel_food")) {
  p <- get(pname)
  cat(sprintf("%-15s: %5d obs, %2d counties, mean emp = %.0f\n",
              pname, nrow(p), n_distinct(p$county_fips), mean(p$emp, na.rm = TRUE)))
}

# Pre-treatment summary by group
cat("\n=== Pre-Treatment Means (2012-2015 Q3) ===\n")
pre <- panel_total %>%
  filter(yq < 2015 * 4 + 4) %>%  # Before Nov 2015 (OWRA)
  group_by(treated_county) %>%
  summarise(
    mean_emp = mean(emp, na.rm = TRUE),
    mean_wage = mean(avg_wkly_wage, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  )
print(pre)

cat("\nCleaning complete.\n")
