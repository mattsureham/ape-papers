# 01_fetch_data.R — Fetch CBS housing data via cbsodataR
# Data source: CBS Statline OData API (public, no key required)

library(cbsodataR)
library(httr)
library(jsonlite)
library(tidyverse)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

# ============================================================
# 1. Fetch housing data (Woning = A045364)
# ============================================================
cat("Fetching CBS housing data (table 81955NED, Woning)...\n")

housing_raw <- cbs_get_data(
  "81955NED",
  Gebruiksfunctie = "A045364",
  verbose = TRUE
)
cat("Total rows:", nrow(housing_raw), "\n")
stopifnot("No housing data returned" = nrow(housing_raw) > 0)

# ============================================================
# 2. Filter to municipalities and monthly periods
# ============================================================
cat("\nFiltering to municipalities, monthly data...\n")

housing <- housing_raw %>%
  mutate(
    region = trimws(RegioS),
    period = trimws(Perioden),
    new_construction = as.numeric(Nieuwbouw_2),
    stock_end = as.numeric(EindstandVoorraad_8),
    demolition = as.numeric(Sloop_4),
    other_addition = as.numeric(OverigeToevoeging_3)
  ) %>%
  filter(
    grepl("^GM", region),
    grepl("MM[0-9][0-9]$", period)
  ) %>%
  mutate(
    year = as.integer(substr(period, 1, 4)),
    month = as.integer(substr(period, 7, 8)),
    date = as.Date(sprintf("%04d-%02d-01", year, month))
  ) %>%
  filter(year >= 2012 & year <= 2023)

cat("  Monthly obs:", nrow(housing), "\n")
cat("  Municipalities:", n_distinct(housing$region), "\n")
cat("  Months:", n_distinct(housing$period), "\n")
cat("  Years:", paste(sort(unique(housing$year)), collapse = ", "), "\n")

# Province-level data for validation
prov_housing <- housing_raw %>%
  mutate(
    region = trimws(RegioS),
    period = trimws(Perioden),
    new_construction = as.numeric(Nieuwbouw_2)
  ) %>%
  filter(
    grepl("^PV", region),
    grepl("MM[0-9][0-9]$", period)
  ) %>%
  mutate(
    year = as.integer(substr(period, 1, 4)),
    month = as.integer(substr(period, 7, 8))
  ) %>%
  filter(year >= 2012 & year <= 2023)

# ============================================================
# 3. Fetch RegioS metadata
# ============================================================
cat("\nFetching RegioS metadata...\n")
regio_resp <- GET(
  "https://opendata.cbs.nl/ODataApi/odata/81955NED/RegioS",
  query = list(`$format` = "json", `$top` = 1000),
  timeout(120)
)
stopifnot("RegioS fetch failed" = status_code(regio_resp) == 200)
regio_meta <- fromJSON(content(regio_resp, "text", encoding = "UTF-8"))$value %>%
  mutate(Key = trimws(Key))

gm_meta <- regio_meta %>%
  filter(grepl("^GM", Key)) %>%
  rename(gem_code = Key, gem_name = Title)

cat("  Municipality entries:", nrow(gm_meta), "\n")

# ============================================================
# 4. Province assignment via cbsodataR mapping table
# ============================================================
cat("\nFetching province mapping...\n")

# CBS table 84992NED = Gebieden in Nederland (municipality-province lookup)
tryCatch({
  geo_data <- cbs_get_data("84992NED")
  cat("  Geo mapping rows:", nrow(geo_data), "\n")
  cat("  Columns:", paste(names(geo_data), collapse = ", "), "\n")
  print(head(geo_data, 3))
  saveRDS(geo_data, "data/geo_mapping_raw.rds")
}, error = function(e) {
  cat("  84992NED failed:", conditionMessage(e), "\n")
})

# Alternative: try 70072ned (Regionale kerncijfers Nederland)
tryCatch({
  rc_meta <- cbs_get_meta("70072ned")
  cat("  70072ned table:", rc_meta$TableInfos$ShortTitle, "\n")
}, error = function(e) {
  cat("  70072ned meta failed:", conditionMessage(e), "\n")
})

# ============================================================
# 5. Province assignment (well-known mapping)
# ============================================================
cat("\nAssigning provinces...\n")

# Use CBS Gemeentegrootteklasse to get province linkage
# Each Dutch municipality belongs to exactly one province
# We use the official list per 2019 (year of PFAS freeze)

# Zuid-Holland (PV28) — includes Dordrecht, Rotterdam, The Hague
zh <- c("GM0482","GM0489","GM0497","GM0499","GM0501","GM0502","GM0503",
        "GM0505","GM0513","GM0518","GM0530","GM0531","GM0534","GM0537",
        "GM0542","GM0546","GM0547","GM0553","GM0569","GM0575","GM0579",
        "GM0585","GM0588","GM0590","GM0597","GM0599","GM0603","GM0606",
        "GM0610","GM0613","GM0614","GM0617","GM0622","GM0623","GM0626",
        "GM0627","GM0629","GM0637","GM0638","GM0643","GM0644","GM0645",
        "GM0646","GM0650","GM0654","GM0659","GM0668","GM1598","GM1621",
        "GM1672","GM1892","GM1916","GM1926","GM1927","GM1930","GM1931",
        "GM1963")

# Noord-Brabant (PV30)
nb <- c("GM0723","GM0727","GM0738","GM0743","GM0744","GM0748","GM0753",
        "GM0755","GM0757","GM0758","GM0762","GM0766","GM0770","GM0772",
        "GM0777","GM0779","GM0784","GM0785","GM0786","GM0788","GM0794",
        "GM0796","GM0797","GM0798","GM0809","GM0815","GM0820","GM0823",
        "GM0824","GM0826","GM0828","GM0840","GM0844","GM0845","GM0847",
        "GM0848","GM0851","GM0855","GM0856","GM0858","GM0860","GM0861",
        "GM0865","GM0866","GM0867","GM0870","GM0873","GM0874","GM0878",
        "GM0879","GM0880","GM0882","GM0884","GM1652","GM1658","GM1659",
        "GM1667","GM1669","GM1674","GM1676","GM1709","GM1719","GM1721",
        "GM1723","GM1728","GM1771","GM1948","GM1959","GM1960","GM1961",
        "GM1962")

# Zeeland (PV29)
ze <- c("GM0654","GM0664","GM0677","GM0678","GM0687","GM0689","GM0703",
        "GM0715","GM0716","GM0717","GM0718","GM1695","GM1714")

# Assign province — use explicit lists for Rhine-Maas delta provinces,
# code ranges for others
gm_num <- as.integer(substr(gm_meta$gem_code, 3, 6))

gm_meta$province <- case_when(
  gm_meta$gem_code %in% zh ~ "Zuid-Holland",
  gm_meta$gem_code %in% nb ~ "Noord-Brabant",
  gm_meta$gem_code %in% ze ~ "Zeeland",
  gm_num <= 14 ~ "Groningen",
  gm_num >= 51 & gm_num <= 98 ~ "Friesland",
  gm_num >= 106 & gm_num <= 119 ~ "Drenthe",
  gm_num >= 140 & gm_num <= 193 ~ "Overijssel",
  gm_meta$gem_code %in% c("GM0034","GM0050","GM0171","GM0303") ~ "Flevoland",
  gm_num >= 200 & gm_num <= 305 ~ "Gelderland",
  gm_num >= 306 & gm_num <= 356 ~ "Utrecht",
  gm_num >= 358 & gm_num <= 481 ~ "Noord-Holland",
  gm_num >= 880 & gm_num <= 998 ~ "Limburg",
  TRUE ~ "Unknown"
)

# Fix known new/merged municipalities (post-2000 codes)
new_gm_prov <- c(
  "GM1507" = "Limburg", "GM1525" = "Limburg",
  "GM1586" = "Gelderland", "GM1598" = "Zuid-Holland",
  "GM1621" = "Zuid-Holland", "GM1640" = "Limburg",
  "GM1641" = "Limburg", "GM1651" = "Groningen",
  "GM1652" = "Noord-Brabant", "GM1655" = "Gelderland",
  "GM1658" = "Noord-Brabant", "GM1659" = "Noord-Brabant",
  "GM1667" = "Noord-Brabant", "GM1669" = "Noord-Brabant",
  "GM1672" = "Zuid-Holland", "GM1674" = "Noord-Brabant",
  "GM1676" = "Noord-Brabant", "GM1680" = "Drenthe",
  "GM1681" = "Drenthe", "GM1690" = "Drenthe",
  "GM1695" = "Zeeland", "GM1699" = "Drenthe",
  "GM1700" = "Overijssel", "GM1701" = "Drenthe",
  "GM1705" = "Gelderland", "GM1706" = "Noord-Holland",
  "GM1708" = "Overijssel", "GM1709" = "Noord-Brabant",
  "GM1711" = "Flevoland", "GM1714" = "Zeeland",
  "GM1718" = "Flevoland", "GM1719" = "Noord-Brabant",
  "GM1721" = "Noord-Brabant", "GM1723" = "Noord-Brabant",
  "GM1724" = "Noord-Brabant", "GM1728" = "Noord-Brabant",
  "GM1729" = "Limburg", "GM1730" = "Gelderland",
  "GM1731" = "Drenthe", "GM1740" = "Gelderland",
  "GM1742" = "Overijssel", "GM1771" = "Noord-Brabant",
  "GM1773" = "Overijssel", "GM1774" = "Overijssel",
  "GM1859" = "Gelderland", "GM1876" = "Gelderland",
  "GM1883" = "Limburg", "GM1891" = "Friesland",
  "GM1892" = "Zuid-Holland", "GM1895" = "Groningen",
  "GM1896" = "Gelderland", "GM1900" = "Friesland",
  "GM1903" = "Limburg", "GM1904" = "Utrecht",
  "GM1908" = "Utrecht", "GM1916" = "Zuid-Holland",
  "GM1926" = "Zuid-Holland", "GM1927" = "Zuid-Holland",
  "GM1930" = "Zuid-Holland", "GM1931" = "Zuid-Holland",
  "GM1940" = "Friesland", "GM1942" = "Friesland",
  "GM1945" = "Gelderland", "GM1948" = "Noord-Brabant",
  "GM1954" = "Limburg", "GM1955" = "Gelderland",
  "GM1959" = "Noord-Brabant", "GM1960" = "Noord-Brabant",
  "GM1961" = "Noord-Brabant", "GM1962" = "Noord-Brabant",
  "GM1963" = "Zuid-Holland", "GM1966" = "Groningen",
  "GM1969" = "Noord-Holland", "GM1970" = "Groningen",
  "GM1978" = "Overijssel", "GM1979" = "Gelderland",
  "GM1980" = "Friesland", "GM1982" = "Friesland",
  "GM1987" = "Groningen"
)

for (code in names(new_gm_prov)) {
  idx <- which(gm_meta$gem_code == code)
  if (length(idx) > 0) gm_meta$province[idx] <- new_gm_prov[code]
}

cat("Province distribution:\n")
print(table(gm_meta$province, useNA = "always"))

# ============================================================
# 6. PFAS treatment classification
# ============================================================
cat("\nClassifying PFAS treatment intensity...\n")

# Chemours factory coordinates (Baanhoekweg, Dordrecht)
chemours_lat <- 51.7900
chemours_lon <- 4.6850

# Rhine-Maas delta provinces = high PFAS exposure
# We define treatment as: Zuid-Holland + Noord-Brabant (downstream of Chemours)
gm_meta$high_pfas <- gm_meta$province %in% c("Zuid-Holland", "Noord-Brabant")

cat("  High PFAS municipalities:", sum(gm_meta$high_pfas), "\n")
cat("  Low PFAS municipalities:", sum(!gm_meta$high_pfas), "\n")

# ============================================================
# 7. Save
# ============================================================
dir.create("data", showWarnings = FALSE)
saveRDS(housing, "data/housing_monthly.rds")
saveRDS(prov_housing, "data/prov_housing.rds")
saveRDS(gm_meta, "data/gm_metadata.rds")

cat("\n=== Data fetch summary ===\n")
cat("Housing obs:", nrow(housing), "\n")
cat("Municipalities:", n_distinct(housing$region), "\n")
cat("Months:", n_distinct(housing$period), "\n")

# Dordrecht check
dord <- housing %>%
  filter(region == "GM0505") %>%
  group_by(year) %>%
  summarise(total = sum(new_construction, na.rm = TRUE), .groups = "drop")
cat("\nDordrecht (GM0505) annual new construction:\n")
print(as.data.frame(dord))

# National totals
nat <- housing %>%
  group_by(year) %>%
  summarise(total = sum(new_construction, na.rm = TRUE), .groups = "drop")
cat("\nNational annual new construction:\n")
print(as.data.frame(nat))
