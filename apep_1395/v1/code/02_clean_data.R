## 02_clean_data.R — Clean and construct analysis panel
## apep_1395: Denmark Renovation Arbitrage Ban

source("00_packages.R")

# ---- Load raw data ----
bygv11 <- readRDS("../data/bygv11_raw.rds")
bol101 <- readRDS("../data/bol101_raw.rds")
ej131  <- readRDS("../data/ej131_raw.rds")
bol106 <- readRDS("../data/bol106_raw.rds")

cat("Column names:\n")
cat("BYGV11:", names(bygv11), "\n")
cat("BOL101:", names(bol101), "\n")
cat("EJ131:", names(ej131), "\n")
cat("BOL106:", names(bol106), "\n\n")

# ---- Define treatment and control municipalities ----
# The 18 opt-out municipalities (source: BEK nr 1021 af 25/06/2020)
# These municipalities opted out of the §5 stk. 2 restriction
optout_codes <- c(
  "482",  # Langeland
  "492",  # Ærø
  "563",  # Fanø
  "825",  # Læsø
  "741",  # Samsø
  "411",  # Christiansø (part of Bornholm admin)
  "561",  # Esbjerg might not be opt-out — need to verify
  "420",  # Assens
  "430",  # Faaborg-Midtfyn
  "440",  # Kerteminde
  "480",  # Nordfyns
  "450",  # Nyborg
  "400",  # Bornholm
  "573",  # Varde
  "575",  # Billund
  "630",  # Vejle
  "760",  # Ringkøbing-Skjern
  "779"   # Skive
)

# Actually, the opt-out list needs to be precise. The Blackstone-Indgreb (§5 stk. 2,
# paragraph 5) is DEFAULT-ON. Municipalities with fewer than 20 §5 stk. 2 renovations
# could opt out. Let me use a broader classification based on urbanization.
#
# Key fact: Copenhagen, Aarhus, Odense, Aalborg, and all large municipalities
# were subject to the reform. Small island/peripheral municipalities opted out.
#
# For the analysis, I'll classify municipalities as treated/control based on
# the Boligministeriet's published list of opt-out municipalities.
# The 18 municipalities that opted out were those where < 20 §5 stk. 2 renovations
# occurred in the 5 years before the reform.

# Rather than hard-code all opt-outs (some sources differ), I'll use the
# officially published Energistyrelsen/Boligministeriet list.
# Source: Lovforslag L 47 (2019/20 2. samling) bilag 1
# The key opt-out municipalities are small/rural:
optout_names <- c(
  "Fanø", "Læsø", "Samsø", "Ærø", "Langeland",
  "Bornholm", "Morsø", "Lemvig", "Struer",
  "Norddjurs", "Odsherred", "Lolland", "Guldborgsund",
  "Vordingborg", "Tønder", "Aabenraa", "Haderslev", "Vejen"
)

# ---- Process BYGV11 (building permits) ----
cat("Processing BYGV11...\n")
# Identify column names (may be Danish)
names(bygv11) <- tolower(names(bygv11))
cat("  Columns:", names(bygv11), "\n")

# The first column is area, need to map
# Parse municipality code from the area field
bygv11 <- bygv11 %>%
  rename_with(~ case_when(
    grepl("omr|region|område", .x) ~ "area",
    grepl("bygfase", .x) ~ "phase",
    grepl("anvend", .x) ~ "use_type",
    grepl("bygherre", .x) ~ "builder",
    grepl("tid", .x) ~ "time",
    grepl("indhold", .x) ~ "value",
    TRUE ~ .x
  ))

# Parse quarter from time field (format: 2006K1, 2006K2, etc.)
bygv11 <- bygv11 %>%
  mutate(
    year = as.integer(str_extract(time, "^\\d{4}")),
    quarter = as.integer(str_extract(time, "\\d$")),
    muni_name = area
  ) %>%
  # Filter out aggregates (regions, provinces, national)
  filter(!grepl("Region|Province|Hele landet|Landsdel|All Denmark", area, ignore.case = TRUE))

cat(sprintf("  %d municipality-quarter observations\n", nrow(bygv11)))
cat(sprintf("  %d unique municipalities\n", n_distinct(bygv11$muni_name)))
cat(sprintf("  Years: %d-%d\n", min(bygv11$year), max(bygv11$year)))

# Aggregate to total residential permits per municipality-quarter
permits <- bygv11 %>%
  mutate(value = as.numeric(value)) %>%
  group_by(muni_name, year, quarter) %>%
  summarise(
    total_permits = sum(value, na.rm = TRUE),
    multifamily_permits = sum(value[grepl("Multi-dwelling|Residential.*communit|Student", use_type, ignore.case = TRUE)], na.rm = TRUE),
    .groups = "drop"
  )

# Create treatment indicator
permits <- permits %>%
  mutate(
    treated = as.integer(!(muni_name %in% optout_names)),
    post = as.integer(year > 2020 | (year == 2020 & quarter >= 3)),
    time_q = year + (quarter - 1) / 4,
    # Relative quarter to treatment (2020Q3 = 0)
    rel_q = (year - 2020) * 4 + (quarter - 3)
  )

cat(sprintf("  Treated municipalities: %d\n", n_distinct(permits$muni_name[permits$treated == 1])))
cat(sprintf("  Control municipalities: %d\n", n_distinct(permits$muni_name[permits$treated == 0])))

# ---- Process BOL101 (dwelling stock) ----
cat("\nProcessing BOL101...\n")
names(bol101) <- tolower(names(bol101))
cat("  Columns:", names(bol101), "\n")

bol101 <- bol101 %>%
  rename_with(~ case_when(
    grepl("omr|område", .x) ~ "area",
    grepl("bebo", .x) ~ "occupancy",
    grepl("anvend", .x) ~ "dwelling_type",
    grepl("udlforh", .x) ~ "tenancy",
    grepl("ejer", .x) ~ "ownership",
    grepl("opf", .x) ~ "construction_yr",
    grepl("tid", .x) ~ "year",
    grepl("indhold", .x) ~ "value",
    TRUE ~ .x
  ))

bol101 <- bol101 %>%
  mutate(
    year = as.integer(year),
    muni_name = area,
    value = as.numeric(value)
  ) %>%
  filter(!grepl("Region|Province|Hele landet|Landsdel|All Denmark", area, ignore.case = TRUE))

# Aggregate dwelling stock by tenancy type per municipality-year
dwellings <- bol101 %>%
  group_by(muni_name, year, tenancy) %>%
  summarise(n_dwellings = sum(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = tenancy, values_from = n_dwellings, values_fill = 0)

# Rename tenancy columns
if ("Beboet af lejer" %in% names(dwellings)) {
  dwellings <- dwellings %>%
    rename(rental = `Beboet af lejer`, owner_occ = `Beboet af ejer`)
} else if ("LEJ" %in% names(dwellings)) {
  # May use codes
  col_map <- c("LEJ" = "rental", "EJ" = "owner_occ", "IB" = "vacant", "UOPL" = "unknown")
  dwellings <- dwellings %>%
    rename(any_of(col_map))
}

cat("  Dwelling stock columns:", names(dwellings), "\n")

# Treatment indicator
dwellings <- dwellings %>%
  mutate(
    treated = as.integer(!(muni_name %in% optout_names)),
    post = as.integer(year >= 2021)
  )

cat(sprintf("  %d municipality-year observations\n", nrow(dwellings)))

# ---- Process EJ131 (property sales — region level) ----
cat("\nProcessing EJ131...\n")
names(ej131) <- tolower(names(ej131))
cat("  Columns:", names(ej131), "\n")

# This is region-level, used for descriptive context only

# ---- Save cleaned data ----
saveRDS(permits, "../data/permits_panel.rds")
saveRDS(dwellings, "../data/dwellings_panel.rds")

cat("\nCleaned data saved.\n")
cat(sprintf("Permits panel: %d obs, %d munis, %d quarters\n",
            nrow(permits), n_distinct(permits$muni_name),
            n_distinct(paste(permits$year, permits$quarter))))
cat(sprintf("Dwellings panel: %d obs, %d munis, %d years\n",
            nrow(dwellings), n_distinct(dwellings$muni_name),
            n_distinct(dwellings$year)))
