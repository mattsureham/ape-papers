## 02_clean_data.R — Clean and construct analysis panel
## apep_1025: Residential Neonicotinoid Bans and Bird Populations

source("00_packages.R")

data_dir <- "../data"

## ---- Load raw data ----
routes <- readRDS(file.path(data_dir, "routes_raw.rds"))
counts <- readRDS(file.path(data_dir, "counts_raw.rds"))
weather <- readRDS(file.path(data_dir, "weather_raw.rds"))

## ---- Parse species list (fixed-width format) ----
cat("Parsing species list...\n")
## Use UTF-8 converted version if available
sp_file <- file.path(data_dir, "SpeciesList_utf8.txt")
if (!file.exists(sp_file)) sp_file <- file.path(data_dir, "SpeciesList.txt")
sp_lines <- readLines(sp_file, encoding = "UTF-8", warn = FALSE)
## Find the dashes line to locate column positions
dash_line <- grep("^-{3,}", sp_lines)
stopifnot("FATAL: Cannot find header delimiter in SpeciesList.txt" = length(dash_line) > 0)
## Header is one line above dashes
header_line <- sp_lines[dash_line[1] - 1]
## Data starts after dashes
data_lines <- sp_lines[(dash_line[1] + 1):length(sp_lines)]
data_lines <- data_lines[nchar(trimws(data_lines)) > 0]

## Parse using fixed widths from the dash line
dashes <- sp_lines[dash_line[1]]
## Split by spaces between dash groups
field_widths <- nchar(strsplit(dashes, " +")[[1]])
## But we need cumulative positions. Use the dashes to find column breaks.
## Simpler: use read.fwf approach or just parse with trimws
species <- data.table(
  Seq = as.integer(trimws(substr(data_lines, 1, 6))),
  AOU = as.integer(trimws(substr(data_lines, 8, 12))),
  English_Common_Name = trimws(substr(data_lines, 13, 62)),
  ORDER = trimws(substr(data_lines, 163, 212)),
  Family = trimws(substr(data_lines, 213, 262)),
  Genus = trimws(substr(data_lines, 263, 312)),
  Species_name = trimws(substr(data_lines, 313, 362))
)

## Remove rows that failed to parse
species <- species[!is.na(AOU) & AOU > 0]
cat("  Parsed", nrow(species), "species\n")

## ---- Dietary classification ----
## Classify species into dietary guilds based on ORDER and Family
## Key categories:
##   insectivore: birds that primarily eat insects (our treatment group)
##   non_insectivore: raptors, waterfowl, granivores (our placebo group)

## Insectivorous orders/families (primary diet = insects/invertebrates)
insect_orders <- c(
  "Passeriformes"  ## Most passerines are insectivorous (warblers, flycatchers, swallows, wrens)
)

## Non-insectivorous families WITHIN Passeriformes (granivores, omnivores)
granivore_families <- c(
  "Fringillidae",   ## Finches (seeds)
  "Passeridae",     ## Old World sparrows (seeds)
  "Cardinalidae",   ## Cardinals, grosbeaks (seeds/fruit)
  "Icteridae",      ## Blackbirds (mixed, many granivorous)
  "Corvidae"        ## Crows, jays (omnivorous)
)

## Clearly non-insectivorous orders (our placebo species)
non_insect_orders <- c(
  "Anseriformes",      ## Ducks, geese (aquatic/grazing)
  "Accipitriformes",   ## Hawks, eagles (raptors)
  "Falconiformes",     ## Falcons (raptors)
  "Strigiformes",      ## Owls (raptors)
  "Cathartiformes",    ## Vultures (scavengers)
  "Columbiformes",     ## Pigeons, doves (granivores)
  "Galliformes",       ## Grouse, quail (granivores/omnivores)
  "Pelecaniformes",    ## Pelicans, herons (fish)
  "Suliformes",        ## Cormorants (fish)
  "Gaviiformes",       ## Loons (fish)
  "Podicipediformes",  ## Grebes (fish)
  "Procellariiformes"  ## Seabirds
)

## Insectivorous non-passerine orders
insect_non_passerine <- c(
  "Caprimulgiformes",  ## Nightjars, swifts (aerial insectivores)
  "Apodiformes",       ## Swifts (aerial insectivores; hummingbirds excluded below)
  "Piciformes",        ## Woodpeckers (bark insects)
  "Coraciiformes"      ## Kingfishers (some insectivorous)
)

species[, diet_guild := "other"]

## Passerines: default to insectivore, override for granivore families
species[ORDER == "Passeriformes", diet_guild := "insectivore"]
species[ORDER == "Passeriformes" & Family %in% granivore_families, diet_guild := "non_insectivore"]

## Non-insectivorous orders
species[ORDER %in% non_insect_orders, diet_guild := "non_insectivore"]

## Insectivorous non-passerines
species[ORDER %in% insect_non_passerine, diet_guild := "insectivore"]

## Hummingbirds (Trochilidae) are nectarivores, not insectivores
species[Family == "Trochilidae", diet_guild := "other"]

## Shorebirds (Charadriiformes) - mixed, many eat invertebrates but mostly coastal/aquatic
species[ORDER == "Charadriiformes", diet_guild := "non_insectivore"]

## Cuckoos eat caterpillars (insectivores)
species[ORDER == "Cuculiformes", diet_guild := "insectivore"]

cat("Diet guild distribution:\n")
print(species[, .N, by = diet_guild][order(-N)])

## Keep species lookup
species_lookup <- species[, .(AOU, English_Common_Name, ORDER, Family, diet_guild)]

## ---- Process count data ----
cat("\nProcessing count data...\n")

## Sum across all 50 stops to get route-level total per species per year
stop_cols <- paste0("Stop", 1:50)
## Handle the whitespace-padded count columns
for (col in stop_cols) {
  if (col %in% names(counts)) {
    counts[, (col) := as.integer(trimws(get(col)))]
    counts[is.na(get(col)), (col) := 0L]
  }
}

existing_stops <- intersect(stop_cols, names(counts))
counts[, total_count := rowSums(.SD, na.rm = TRUE), .SDcols = existing_stops]

## Keep US routes only (CountryNum == 840)
counts_us <- counts[CountryNum == 840]
cat("  US count records:", nrow(counts_us), "\n")

## Merge with species diet guild
setnames(counts_us, "AOU", "AOU_code", skip_absent = TRUE)
if ("AOU" %in% names(counts_us)) {
  counts_us[, AOU_code := AOU]
}
## AOU in counts is stored as character with leading zeros; convert both to integer
counts_us[, AOU_int := as.integer(AOU_code)]
species_lookup[, AOU_int := as.integer(AOU)]
counts_us <- merge(counts_us, species_lookup[, .(AOU_int, diet_guild, English_Common_Name)],
                   by = "AOU_int", all.x = TRUE)

## Drop unclassified species
counts_classified <- counts_us[diet_guild %in% c("insectivore", "non_insectivore")]
cat("  Classified records:", nrow(counts_classified), "\n")

## ---- Aggregate to route × year × diet guild ----
cat("Aggregating to route × year × diet guild level...\n")
route_year <- counts_classified[, .(
  total_count = sum(total_count, na.rm = TRUE),
  n_species = uniqueN(AOU_int)
), by = .(CountryNum, StateNum, Route, Year, diet_guild)]

cat("  Route-year-guild observations:", nrow(route_year), "\n")

## ---- Merge with route metadata ----
route_year <- merge(route_year, routes[, .(CountryNum, StateNum, Route, Latitude, Longitude, BCR)],
                    by = c("CountryNum", "StateNum", "Route"), all.x = TRUE)

## ---- Merge with weather ----
## Weather has RunType, observer info (ObsN), temperature, wind, sky
## RPID == 101 means acceptable data quality
weather[, `:=`(
  StartTemp = as.numeric(trimws(StartTemp)),
  EndTemp = as.numeric(trimws(EndTemp)),
  StartWind = as.numeric(trimws(StartWind)),
  EndWind = as.numeric(trimws(EndWind)),
  RPID = as.integer(trimws(RPID))
)]
weather_clean <- weather[RPID == 101, .(CountryNum, StateNum, Route, Year, ObsN,
                                         StartTemp, EndTemp, StartWind, EndWind)]
## Compute mean conditions
weather_clean[, `:=`(
  mean_temp = (StartTemp + EndTemp) / 2,
  mean_wind = (StartWind + EndWind) / 2
)]

route_year <- merge(route_year, weather_clean[, .(CountryNum, StateNum, Route, Year,
                                                   ObsN, mean_temp, mean_wind)],
                    by = c("CountryNum", "StateNum", "Route", "Year"),
                    all.x = TRUE)

## ---- Construct observer experience ----
cat("Computing observer experience...\n")
obs_exp <- weather_clean[, .(first_year = min(Year)), by = ObsN]
route_year <- merge(route_year, obs_exp, by = "ObsN", all.x = TRUE)
route_year[, obs_experience := Year - first_year]

## ---- Treatment assignment ----
cat("Assigning treatment status...\n")

## State FIPS to BBS state number mapping
## BBS StateNum for US states (these are BBS-internal codes, not FIPS)
## We need to map state abbreviations to BBS StateNum
## BBS uses its own numbering: check routes data
cat("  BBS StateNum values in US routes:\n")
us_routes <- routes[CountryNum == 840]
state_nums <- sort(unique(us_routes$StateNum))
cat("  ", paste(state_nums, collapse = ", "), "\n")

## BBS uses its own state numbering (NOT FIPS). Mapping determined from route coordinates.
## Full BBS→abbreviation lookup:
bbs_state_map <- data.table(
  StateNum = c(2,3,6,7,14,17,18,21,25,27,33,34,35,36,38,39,42,44,46,47,49,50,51,52,53,54,55,58,59,60,61,63,64,66,67,69,72,77,80,81,82,83,85,87,88,89,90,91,92),
  state_abbr_bbs = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

## Treatment states and their BBS state numbers
treatment_states <- data.table(
  state_abbr = c("MD", "CT", "ME", "VT", "MA", "NJ", "NY", "RI", "CO", "NV", "CA", "WA"),
  treat_year = c(2016, 2016, 2018, 2019, 2021, 2022, 2022, 2022, 2023, 2023, 2024, 2024)
)

## Map BBS StateNum to abbreviation, then merge treatment
route_year <- merge(route_year, bbs_state_map, by = "StateNum", all.x = TRUE)

## Merge treatment info
route_year <- merge(route_year, treatment_states,
                    by.x = "state_abbr_bbs", by.y = "state_abbr", all.x = TRUE)
route_year[, state_abbr := state_abbr_bbs]

## Treatment indicator: 1 if state has ban AND year >= ban year
route_year[, treated := as.integer(!is.na(treat_year) & Year >= treat_year)]
route_year[is.na(treat_year), treat_year := 0]  ## Never-treated

## ---- Create route ID ----
route_year[, route_id := paste(CountryNum, StateNum, Route, sep = "_")]

## ---- Log abundance ----
route_year[, log_count := log(total_count + 1)]
route_year[, log_species := log(n_species + 1)]

## ---- Filter to analysis sample ----
## Keep years 2000-2021 for tractable pre-period (still 16 years pre-treatment for first cohort)
## Keep routes with at least 10 years of observations for balanced-ish panel
cat("Filtering analysis sample...\n")
panel <- route_year[Year >= 2000 & Year <= 2021]

## Route coverage
route_coverage <- panel[, .(n_years = uniqueN(Year)), by = .(route_id, diet_guild)]
good_routes <- route_coverage[n_years >= 10, unique(route_id)]
panel <- panel[route_id %in% good_routes]

cat("  Analysis panel: ", nrow(panel), " observations\n")
cat("  Unique routes:", uniqueN(panel$route_id), "\n")
cat("  Year range:", paste(range(panel$Year), collapse = "–"), "\n")
cat("  Treated routes:", uniqueN(panel[treated == 1]$route_id), "\n")
cat("  Control routes:", uniqueN(panel[treated == 0 & treat_year == 0]$route_id), "\n")

## ---- Summary stats by diet guild ----
cat("\nSummary by diet guild:\n")
panel[, .(mean_count = mean(total_count), sd_count = sd(total_count),
          mean_species = mean(n_species), n_routes = uniqueN(route_id),
          n_obs = .N), by = diet_guild] |> print()

## ---- Treatment cohort summary ----
cat("\nTreatment cohort sizes (unique routes):\n")
cohort_summary <- panel[treat_year > 0, .(n_routes = uniqueN(route_id)),
                         by = .(treat_year, state_abbr)]
print(cohort_summary[order(treat_year)])

## ---- Save ----
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(species_lookup, file.path(data_dir, "species_lookup.rds"))
cat("\nAnalysis panel saved.\n")
