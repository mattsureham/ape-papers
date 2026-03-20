## 01_fetch_data.R — Fetch and parse all data for apep_0729
## Sources: SSB API (turnout, population), Medietilsynet (subsidies)

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. PARSE SSB STORTING ELECTION TURNOUT (table 08243)
# ============================================================
cat("Parsing Storting election turnout...\n")
ssb_storting <- fromJSON(file.path(data_dir, "ssb_storting_turnout_full.json"))

storting_regions <- ssb_storting$dimension$Region$category$label
storting_years <- ssb_storting$dimension$Tid$category$label
storting_vals <- ssb_storting$value

region_codes <- names(storting_regions)
year_codes <- names(storting_years)
n_years <- length(year_codes)

storting_dt <- rbindlist(lapply(seq_along(region_codes), function(i) {
  r <- region_codes[i]
  name <- storting_regions[[r]]
  vals <- storting_vals[((i-1)*n_years + 1):(i*n_years)]
  data.table(
    region_code = r,
    region_name = name,
    year = as.integer(year_codes),
    turnout_storting = as.numeric(vals)
  )
}))

# Remove national total and county-level aggregates
storting_dt <- storting_dt[!grepl("^(0|v\\d+|\\d{2})$", region_code)]
storting_dt <- storting_dt[!is.na(turnout_storting)]
cat(sprintf("  Storting turnout: %d municipality-year obs, %d unique municipalities\n",
            nrow(storting_dt), uniqueN(storting_dt$region_code)))

# ============================================================
# 2. PARSE SSB LOCAL ELECTION TURNOUT (table 09475)
# ============================================================
cat("Parsing local election turnout...\n")
ssb_local <- fromJSON(file.path(data_dir, "ssb_local_turnout.json"))

local_regions <- ssb_local$dimension$Region$category$label
local_years <- ssb_local$dimension$Tid$category$label
local_vals <- ssb_local$value

l_region_codes <- names(local_regions)
l_year_codes <- names(local_years)
l_n_years <- length(l_year_codes)

local_dt <- rbindlist(lapply(seq_along(l_region_codes), function(i) {
  r <- l_region_codes[i]
  name <- local_regions[[r]]
  vals <- local_vals[((i-1)*l_n_years + 1):(i*l_n_years)]
  data.table(
    region_code = r,
    region_name = name,
    year = as.integer(l_year_codes),
    turnout_local = as.numeric(vals)
  )
}))

local_dt <- local_dt[!grepl("^(0|v\\d+|\\d{2})$", region_code)]
local_dt <- local_dt[!is.na(turnout_local)]
cat(sprintf("  Local election turnout: %d municipality-year obs, %d unique municipalities\n",
            nrow(local_dt), uniqueN(local_dt$region_code)))

# ============================================================
# 3. PARSE SUBSIDY DATA (2021 Excel)
# ============================================================
cat("Parsing Medietilsynet subsidy data...\n")
subsidy_raw <- as.data.table(read_excel(
  file.path(data_dir, "produksjonstilskudd_2021.xlsx"),
  sheet = 1
))

# Keep relevant columns
setnames(subsidy_raw, c(
  "tildeling_id", "system_name", "qualified", "id_number", "company_name",
  "newspaper_name", "competitive_status", "circulation_weekday", "issues_per_year_weekday",
  "circulation_sunday", "issues_per_year_sunday", "subsidy_rate", "subsidy_2021",
  "computed_subsidy", "subsidy_2020", "year", "decision", "old_calc", "diff"
))

subsidy <- subsidy_raw[decision == "Godkjent for tilskudd" |
                         decision == "Godkjent for tilskudd - ukesaviser",
                       .(id_number, company_name, newspaper_name, competitive_status,
                         circulation = as.numeric(circulation_weekday),
                         issues_per_year = as.numeric(issues_per_year_weekday),
                         subsidy_rate, subsidy_2021 = as.numeric(subsidy_2021),
                         subsidy_2020 = as.numeric(subsidy_2020))]

cat(sprintf("  Subsidized newspapers: %d\n", nrow(subsidy)))
cat(sprintf("  By category:\n"))
print(subsidy[, .N, by = subsidy_rate])

# ============================================================
# 4. MAP NEWSPAPERS TO MUNICIPALITIES
# ============================================================
cat("Mapping newspapers to municipalities...\n")

# Norwegian newspaper names strongly encode geography
# Manual mapping of local newspapers to SSB municipality codes
# Focus on "Øvrige medier" (local papers) — the key treatment group
newspaper_municipality_map <- data.table(
  newspaper_name = c(
    "ITROMSØ", "PORSGRUNNS DAGBLAD", "vol.no (Vesterålen Online)",
    "HAMMERFESTINGEN", "SØR-VARANGER AVIS", "VARDEN",
    "FINNMARKSPOSTEN", "SALTENPOSTEN", "BRØNNØYSUNDS AVIS",
    "BODØ NU", "HELGELANDS BLAD", "FRAMTID I NORD",
    "NYE TROMS", "ALTAPOSTEN", "ANDØYPOSTEN",
    "iHARSTAD", "STEINKJER AVISA", "TRØNDERBLADET",
    "MITT KONGSVINGER", "JARLSBERG AVIS", "SANDNESPOSTEN",
    "GRIMSTAD ADRESSETIDENDE", "TELEN", "RJUKAN ARBEIDERBLAD",
    "LIERPOSTEN", "ASKØYVÆRINGEN", "MALVIKNYTT",
    "STANGEAVISA", "RAKKESTAD AVIS", "TOTENS BLAD",
    "ÅS AVIS", "VESTBY AVIS", "LILLESANDS-POSTEN",
    "VENNESLA TIDENDE", "LINDESNES", "SOLABLADET",
    "GJESDALBUEN", "ENEBAKK AVIS",
    "SVELVIKSPOSTEN", "BØMLO-NYTT", "RYFYLKE",
    "KVINNHERINGEN", "HARDANGER FOLKEBLAD", "HORDALAND FOLKEBLAD",
    "GRANNAR", "STRANDBUEN", "SULDALSPOSTEN",
    "SETESDØLEN", "VEST-TELEMARK BLAD", "DRIVA",
    "FJORDINGEN", "MØRE-NYTT", "SYNSTE MØRE",
    "FJORDENES TIDENDE", "VIKEBLADET VESTPOSTEN", "VESTLANDSNYTT",
    "SELBYGGEN", "GAULDALSPOSTEN", "OPP",
    "FJELL-LJOM", "MERÅKERPOSTEN", "SNÅSNINGEN",
    "FROSTINGEN", "INDERØYNINGEN", "NORDSALTEN AVIS",
    "LOFOT-TIDENDE", "ØKSNESAVISA", "VESTERÅLENS AVIS",
    "FOLKEBLADET", "NORDDALEN", "FJUKEN",
    "VIGGA", "DØLEN", "YTRE SOGN",
    "BYGDANYTT", "STRILEN", "NORDHORDALAND",
    "TYSNES", "BIRKENES-AVISA", "FROLENDINGEN",
    "LYNGDALS AVIS", "KARMØYNYTT", "TYSVÆR BYGDEBLAD",
    "SULAPOSTEN", "STORFJORDNYTT", "AURA AVIS",
    "ÅNDALSNES AVIS", "DRANGEDALSPOSTEN", "BØ BLAD"
  ),
  municipality_name = c(
    "Tromsø", "Porsgrunn", "Sortland",
    "Hammerfest", "Sør-Varanger", "Porsgrunn",
    "Hammerfest", "Fauske", "Brønnøy",
    "Bodø", "Alstahaug", "Nordreisa",
    "Målselv", "Alta", "Andøy",
    "Harstad", "Steinkjer", "Melhus",
    "Kongsvinger", "Tønsberg", "Sandnes",
    "Grimstad", "Notodden", "Tinn",
    "Lier", "Askøy", "Malvik",
    "Stange", "Rakkestad", "Østre Toten",
    "Ås", "Vestby", "Lillesand",
    "Vennesla", "Lindesnes", "Sola",
    "Gjesdal", "Enebakk",
    "Drammen", "Bømlo", "Strand",
    "Kvinnherad", "Kvam", "Ullensvang",
    "Suldal", "Hjelmeland", "Suldal",
    "Valle", "Kviteseid", "Sunndal",
    "Stryn", "Ørsta", "Vanylven",
    "Måløy", "Herøy", "Herøy",
    "Selbu", "Midtre Gauldal", "Oppdal",
    "Røros", "Meråker", "Snåsa",
    "Frosta", "Inderøy", "Steigen",
    "Vestvågøy", "Øksnes", "Sortland",
    "Finnsnes", "Nord-Fron", "Skjåk",
    "Dovre", "Nord-Aurdal", "Sogndal",
    "Arna", "Lindås", "Alver",
    "Tysnes", "Birkenes", "Froland",
    "Lyngdal", "Karmøy", "Tysvær",
    "Sula", "Norddal", "Surnadal",
    "Rauma", "Drangedal", "Bø"
  )
)

# Also add national/big-city papers (these don't serve a specific municipality)
national_papers <- subsidy[subsidy_rate == "Riksmedier", newspaper_name]
cat(sprintf("  National papers (excluded from local analysis): %d\n", length(national_papers)))
cat(sprintf("  Local papers mapped: %d\n", nrow(newspaper_municipality_map)))

# Merge subsidy data with municipality mapping
subsidy_local <- merge(subsidy, newspaper_municipality_map, by = "newspaper_name", all.x = FALSE)
cat(sprintf("  Matched local subsidized papers: %d\n", nrow(subsidy_local)))
cat(sprintf("  Total subsidy to local papers: %.0f NOK\n", sum(subsidy_local$subsidy_2021, na.rm = TRUE)))

# ============================================================
# 5. PARSE POPULATION DATA
# ============================================================
cat("Parsing population data...\n")
ssb_pop <- fromJSON(file.path(data_dir, "ssb_population.json"))

pop_regions <- ssb_pop$dimension$Region$category$label
pop_years <- ssb_pop$dimension$Tid$category$label
pop_vals <- ssb_pop$value

p_region_codes <- names(pop_regions)
p_year_codes <- names(pop_years)

# Population has dimensions: Region x TettSpredt(3) x Kjonn(2) x Tid
# Total = sum over TettSpredt and Kjonn
n_tett <- 3  # densely, sparsely, unknown
n_kjonn <- 2  # female, male
n_p_years <- length(p_year_codes)
stride <- n_tett * n_kjonn * n_p_years

pop_dt <- rbindlist(lapply(seq_along(p_region_codes), function(i) {
  r <- p_region_codes[i]
  name <- pop_regions[[r]]
  base_idx <- (i - 1) * stride
  # Sum over all TettSpredt × Kjonn for each year
  year_totals <- sapply(seq_along(p_year_codes), function(y) {
    total <- 0
    for (t in 1:n_tett) {
      for (k in 1:n_kjonn) {
        idx <- base_idx + (t-1)*n_kjonn*n_p_years + (k-1)*n_p_years + y
        val <- pop_vals[[idx]]
        if (!is.null(val) && !is.na(val)) total <- total + val
      }
    }
    if (total == 0) NA_real_ else total
  })
  data.table(
    region_code = r,
    region_name = name,
    year = as.integer(p_year_codes),
    population = year_totals
  )
}))

pop_dt <- pop_dt[!grepl("^(0|v\\d+|\\d{2})$", region_code)]
pop_dt <- pop_dt[!is.na(population) & population > 0]
cat(sprintf("  Population data: %d municipality-year obs\n", nrow(pop_dt)))

# ============================================================
# 6. SAVE ALL PARSED DATA
# ============================================================
fwrite(storting_dt, file.path(data_dir, "storting_turnout.csv"))
fwrite(local_dt, file.path(data_dir, "local_turnout.csv"))
fwrite(subsidy_local, file.path(data_dir, "subsidy_local.csv"))
fwrite(subsidy, file.path(data_dir, "subsidy_all.csv"))
fwrite(pop_dt, file.path(data_dir, "population.csv"))

cat("\nAll data fetched and saved.\n")
cat(sprintf("  Storting turnout: %s\n", file.path(data_dir, "storting_turnout.csv")))
cat(sprintf("  Local turnout: %s\n", file.path(data_dir, "local_turnout.csv")))
cat(sprintf("  Subsidies: %s\n", file.path(data_dir, "subsidy_local.csv")))
cat(sprintf("  Population: %s\n", file.path(data_dir, "population.csv")))
