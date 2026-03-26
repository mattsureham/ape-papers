## 01_fetch_data.R — Load OSPAR beach litter data + assign UK nations
## APEP-0973: Plastic Bag Charges and Beach Litter

source("00_packages.R")
setwd(file.path(here::here(), "output", "apep_0973", "v1"))

cat("=== Step 1: Load OSPAR Survey Data (2001-2020) ===\n")

# Read all annual CSV files
ospar_files <- list.files("data", pattern = "^ospar_\\d{4}\\.csv$", full.names = TRUE)
stopifnot("No OSPAR files found" = length(ospar_files) > 0)

all_surveys <- map_dfr(ospar_files, function(f) {
  df <- read_csv(f, show_col_types = FALSE, col_types = cols(.default = col_character()))
  year <- as.integer(str_extract(basename(f), "\\d{4}"))
  df$file_year <- year
  df
})

cat(sprintf("  Total surveys loaded: %d from %d files\n", nrow(all_surveys), length(ospar_files)))

# Filter to United Kingdom
uk <- all_surveys |> filter(Country == "United Kingdom")
cat(sprintf("  UK surveys: %d\n", nrow(uk)))

cat("=== Step 2: Assign UK Nations to Beaches ===\n")

# Map beach IDs to devolved nations based on coordinates
# Northern Ireland beaches: UK025-UK038, UK052 (Western longitudes > 5°W, latitudes ~54-55°N)
# Scotland beaches: UK011, UK012, UK018, UK045, UK046, UK047 (latitudes > 55°N, except NI)
# Wales beaches: UK002, UK003, UK004, UK005, UK021, UK039 (Welsh coast)
# England: remainder (excl. Channel Islands UK017, UK051)

nation_map <- tribble(
  ~beach_id, ~nation,
  # England
  "UK001", "England",   # Hilbre Island (Merseyside)
  "UK006", "England",   # Burnham-on-Sea (Somerset)
  "UK007", "England",   # Hastings (Sussex)
  "UK008", "England",   # Margate (Kent)
  "UK009", "England",   # Heacham (Norfolk)
  "UK010", "England",   # Staithes (Yorkshire)
  "UK013", "England",   # Porth Kidney (Cornwall)
  "UK014", "England",   # Allonby (Cumbria)
  "UK015", "England",   # St Marys (Devon)
  "UK016", "England",   # Chilton Chine (Isle of Wight)
  "UK019", "England",   # Upgang (Yorkshire)
  "UK020", "England",   # Sand Bay (Somerset)
  "UK040", "England",   # Seatown (Dorset)
  "UK041", "England",   # Polhawn (Cornwall)
  "UK042", "England",   # Felixstowe (Suffolk)
  "UK043", "England",   # Jubilee Beach (Essex)
  "UK044", "England",   # Rottingdean (Sussex)
  "UK048", "England",   # Formby (Merseyside)
  "UK049", "England",   # Robin Hood's Bay (Yorkshire)
  "UK050", "England",   # Saltburn (Cleveland)
  # Wales
  "UK002", "Wales",     # Tan-y-Bwlch (Ceredigion)
  "UK003", "Wales",     # Traeth Mawr (Pembrokeshire)
  "UK004", "Wales",     # West Angle Bay (Pembrokeshire)
  "UK005", "Wales",     # Freshwater East (Pembrokeshire)
  "UK021", "Wales",     # Langland Bay (Swansea)
  "UK039", "Wales",     # Tal-y-Foel (Anglesey)
  # Scotland
  "UK011", "Scotland",  # Cramond (Edinburgh)
  "UK012", "Scotland",  # Menie Links (Aberdeenshire)
  "UK018", "Scotland",  # Linkim Shore (East Lothian)
  "UK045", "Scotland",  # Lunderston Bay (Inverclyde)
  "UK046", "Scotland",  # Mill Bay (Orkney)
  "UK047", "Scotland",  # Kinghorn Harbour (Fife)
  # Northern Ireland
  "UK025", "Northern Ireland", # Ardglass
  "UK026", "Northern Ireland", # Ballyhornan
  "UK027", "Northern Ireland", # Minearny
  "UK028", "Northern Ireland", # Ballywalter
  "UK029", "Northern Ireland", # Cloughey
  "UK030", "Northern Ireland", # Drains Bay
  "UK031", "Northern Ireland", # Hazelbank
  "UK032", "Northern Ireland", # Kilkeel North
  "UK033", "Northern Ireland", # Portavogie
  "UK034", "Northern Ireland", # Rathlin
  "UK035", "Northern Ireland", # Rostrevor
  "UK036", "Northern Ireland", # Runkerry
  "UK037", "Northern Ireland", # Tyrella
  "UK038", "Northern Ireland", # White Park Bay
  "UK052", "Northern Ireland"  # Culmore Point
  # Excluded: UK017 (Guernsey), UK051 (Jersey) — not UK nations
)

uk <- uk |>
  mutate(beach_id = `Beach ID`) |>
  left_join(nation_map, by = "beach_id")

# Drop Channel Islands
uk <- uk |> filter(!is.na(nation))
cat(sprintf("  UK surveys (excl. Channel Islands): %d\n", nrow(uk)))
cat(sprintf("  Beaches: %d\n", n_distinct(uk$beach_id)))

# Nation breakdown
uk |> count(nation) |> print()

cat("=== Step 3: Parse Survey Dates and Extract Litter Variables ===\n")

# Parse survey date
uk <- uk |>
  mutate(
    survey_date = as.Date(`Survey date`, format = "%d/%m/%Y"),
    year = year(survey_date),
    month = month(survey_date),
    # Half-year period for panel construction
    half = ifelse(month <= 6, 1, 2),
    year_half = year + (half - 1) * 0.5
  )

# Extract key litter variables
# Column names contain the item category and OSPAR code
bag_cols <- names(uk)[grepl("Bags|bags|Bag_ends", names(uk), ignore.case = TRUE)]
cat(sprintf("  Bag-related columns found: %s\n", paste(bag_cols, collapse = ", ")))

uk <- uk |>
  mutate(
    # Primary outcome: carrier bags (OSPAR code 2)
    bags = as.numeric(`Plastic: Bags [2]`),
    # Small bags (OSPAR code 3)
    small_bags = as.numeric(`Plastic: Small_bags [3]`),
    # Bag ends (OSPAR code 112)
    bag_ends = as.numeric(`Plastic: Bag_ends [112]`),
    # Total bag litter
    total_bags = coalesce(bags, 0) + coalesce(small_bags, 0) + coalesce(bag_ends, 0),
    # Placebo outcomes — non-bag plastic items
    plastic_bottles = as.numeric(`Plastic: Drinks [4]`),
    plastic_caps = as.numeric(ifelse("Plastic: Caps [15]" %in% names(uk),
                                      `Plastic: Caps [15]`, NA)),
    plastic_food = as.numeric(`Plastic: Food [6]`),
    # Total litter (sum of all item columns, approximately)
    # We'll compute this from all numeric litter columns
    beach_name = `Beach name`
  )

# Compute total litter from all item columns
litter_cols <- names(uk)[grepl("^(Plastic|Rubber|Cloth|Paper|Wood|Metal|Glass|Pottery|Sanitary|Pollutant)", names(uk))]
uk <- uk |>
  mutate(
    total_litter = rowSums(across(all_of(litter_cols), ~as.numeric(.x)), na.rm = TRUE),
    nonbag_litter = total_litter - total_bags
  )

cat(sprintf("  Litter columns identified: %d\n", length(litter_cols)))

cat("=== Step 4: Construct Treatment Variables ===\n")

# Treatment timing (using fiscal/calendar half-year)
# Wales: October 2011 → treated from 2012H1 onward (year = 2012)
# NI: April 2013 → treated from 2013H2 onward (year = 2014 conservatively, or 2013)
# Scotland: October 2014 → treated from 2015H1 onward (year = 2015)
# England: October 2015 → treated from 2016H1 onward (year = 2016)
#
# For annual panel, use year of implementation taking effect

treatment_years <- tribble(
  ~nation,              ~treat_year,
  "Wales",              2012L,  # charge introduced Oct 2011
  "Northern Ireland",   2013L,  # charge introduced Apr 2013
  "Scotland",           2015L,  # charge introduced Oct 2014
  "England",            2016L   # charge introduced Oct 2015
)

uk <- uk |>
  left_join(treatment_years, by = "nation") |>
  mutate(
    post = ifelse(year >= treat_year, 1L, 0L)
  )

cat("Treatment assignment:\n")
uk |> distinct(nation, treat_year) |> arrange(treat_year) |> print()

# Create numeric beach ID for did package
beach_ids <- uk |> distinct(beach_id) |> mutate(beach_num = row_number())
uk <- uk |> left_join(beach_ids, by = "beach_id")

cat(sprintf("\n=== Final Dataset: %d surveys, %d beaches, %d years ===\n",
            nrow(uk), n_distinct(uk$beach_id), n_distinct(uk$year)))

saveRDS(uk, "data/uk_beach_litter.rds")

# Quick summary
cat("\nSurveys per nation-year (first/last 3 years):\n")
uk |>
  count(nation, year) |>
  filter(year <= 2003 | year >= 2018) |>
  pivot_wider(names_from = nation, values_from = n, values_fill = 0) |>
  print(n = 20)
