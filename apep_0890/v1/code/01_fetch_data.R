# 01_fetch_data.R — Data acquisition
# apep_0890: Craigslist Entry and Local Journalism Employment
#
# PREREQUISITE: Run 00_extract_azure.py first to extract QWI from Azure.
#
# Sources:
#   1. QWI NAICS 513 county-quarter employment (extracted from Azure)
#   2. Craigslist MSA entry years from published literature
#   3. Census CBSA-FIPS crosswalk

source("00_packages.R")
setwd(file.path(getwd(), "..", "data"))

# =============================================================================
# 1. Load QWI data from CSV (extracted by 00_extract_azure.py)
# =============================================================================
cat("Loading QWI publishing data...\n")
qwi_pub <- read_csv("qwi_publishing.csv", show_col_types = FALSE)
cat("Publishing QWI rows:", nrow(qwi_pub), "\n")
cat("Unique counties:", n_distinct(qwi_pub$fips), "\n")
cat("Year range:", range(qwi_pub$year), "\n")

qwi_placebo <- read_csv("qwi_placebo.csv", show_col_types = FALSE)
cat("Placebo QWI rows:", nrow(qwi_placebo), "\n")

# =============================================================================
# 2. Craigslist MSA Entry Years
# =============================================================================
# Constructed from Kroft and Pope (2014, JLE Table A1), Seamans and Zhu (2014,
# Management Science), and documented public sources.
# Entry year = year Craigslist opened a dedicated city page for the MSA.
#
# Rollout: 1995 SF only; 2000 first 11 cities; 2001-2006 remaining metros.

craigslist_dates <- tribble(
  ~cbsa_code, ~cbsa_name, ~cl_entry_year,
  # 2000 cohort (first wave — 11 cities)
  "14460", "Boston-Cambridge-Newton", 2000L,
  "16980", "Chicago-Naperville-Elgin", 2000L,
  "26420", "Houston-The Woodlands-Sugar Land", 2000L,
  "31080", "Los Angeles-Long Beach-Anaheim", 2000L,
  "35620", "New York-Newark-Jersey City", 2000L,
  "38900", "Portland-Vancouver-Hillsboro", 2000L,
  "40900", "Sacramento-Roseville-Folsom", 2000L,
  "41740", "San Diego-Chula Vista-Carlsbad", 2000L,
  "42660", "Seattle-Tacoma-Bellevue", 2000L,
  "47900", "Washington-Arlington-Alexandria", 2000L,
  "41860", "San Francisco-Oakland-Berkeley", 2000L,
  # 2001 cohort
  "12060", "Atlanta-Sandy Springs-Alpharetta", 2001L,
  "12420", "Austin-Round Rock-Georgetown", 2001L,
  "19100", "Dallas-Fort Worth-Arlington", 2001L,
  "19740", "Denver-Aurora-Lakewood", 2001L,
  "29820", "Las Vegas-Henderson-Paradise", 2001L,
  "33460", "Minneapolis-St. Paul-Bloomington", 2001L,
  "37980", "Philadelphia-Camden-Wilmington", 2001L,
  "38060", "Phoenix-Mesa-Chandler", 2001L,
  "39580", "Raleigh-Cary", 2001L,
  "45300", "Tampa-St. Petersburg-Clearwater", 2001L,
  # 2002 cohort
  "12580", "Baltimore-Columbia-Towson", 2002L,
  "16740", "Charlotte-Concord-Gastonia", 2002L,
  "17140", "Cincinnati-Hamilton-Middletown", 2002L,
  "17460", "Cleveland-Elyria", 2002L,
  "18140", "Columbus-Marion-Zanesville", 2002L,
  "19820", "Detroit-Warren-Dearborn", 2002L,
  "26900", "Indianapolis-Carmel-Anderson", 2002L,
  "28140", "Kansas City", 2002L,
  "32820", "Memphis-Forrest City", 2002L,
  "33100", "Miami-Fort Lauderdale-Pompano Beach", 2002L,
  "33340", "Milwaukee-Waukesha", 2002L,
  "34980", "Nashville-Davidson-Murfreesboro", 2002L,
  "35380", "New Orleans-Metairie", 2002L,
  "36740", "Orlando-Kissimmee-Sanford", 2002L,
  "38300", "Pittsburgh", 2002L,
  "41700", "San Antonio-New Braunfels", 2002L,
  "41180", "St. Louis", 2002L,
  "41620", "Salt Lake City", 2002L,
  # 2003 cohort
  "10420", "Akron", 2003L,
  "10580", "Albany-Schenectady-Troy", 2003L,
  "10900", "Allentown-Bethlehem-Easton", 2003L,
  "14860", "Bridgeport-Stamford-Norwalk", 2003L,
  "15380", "Buffalo-Cheektowaga", 2003L,
  "19380", "Dayton-Kettering", 2003L,
  "24340", "Grand Rapids-Kentwood", 2003L,
  "24860", "Greenville-Anderson", 2003L,
  "25540", "Hartford-East Hartford-Middletown", 2003L,
  "27260", "Jacksonville", 2003L,
  "30780", "Little Rock-North Little Rock", 2003L,
  "31140", "Louisville/Jefferson County", 2003L,
  "36420", "Oklahoma City", 2003L,
  "36540", "Omaha-Council Bluffs", 2003L,
  "40060", "Richmond", 2003L,
  "40380", "Rochester", 2003L,
  "44700", "Stockton", 2003L,
  "46060", "Tucson", 2003L,
  "46140", "Tulsa", 2003L,
  "47260", "Virginia Beach-Norfolk-Newport News", 2003L,
  # 2004 cohort
  "12940", "Baton Rouge", 2004L,
  "13820", "Birmingham-Hoover", 2004L,
  "15980", "Cape Coral-Fort Myers", 2004L,
  "16700", "Charleston-North Charleston", 2004L,
  "17900", "Columbia", 2004L,
  "20500", "Durham-Chapel Hill", 2004L,
  "21340", "El Paso", 2004L,
  "23420", "Fresno", 2004L,
  "25260", "Greensboro-High Point", 2004L,
  "28940", "Knoxville", 2004L,
  "29460", "Lakeland-Winter Haven", 2004L,
  "30460", "Lexington-Fayette", 2004L,
  "31540", "Madison", 2004L,
  "35300", "New Haven-Milford", 2004L,
  "37100", "Oxnard-Thousand Oaks-Ventura", 2004L,
  "39300", "Providence-Warwick", 2004L,
  "42100", "Santa Cruz-Watsonville", 2004L,
  "42200", "Santa Maria-Santa Barbara", 2004L,
  "44060", "Spokane-Spokane Valley", 2004L,
  "45060", "Syracuse", 2004L,
  "48620", "Wichita", 2004L,
  # 2005 cohort
  "10740", "Albuquerque", 2005L,
  "11700", "Asheville", 2005L,
  "14260", "Boise City", 2005L,
  "16860", "Chattanooga", 2005L,
  "17820", "Colorado Springs", 2005L,
  "19660", "Deltona-Daytona Beach-Ormond Beach", 2005L,
  "21660", "Eugene-Springfield", 2005L,
  "22020", "Fargo", 2005L,
  "22220", "Fayetteville-Springdale-Rogers", 2005L,
  "22660", "Fort Collins", 2005L,
  "23060", "Fort Wayne", 2005L,
  "24580", "Green Bay", 2005L,
  "25420", "Harrisburg-Carlisle", 2005L,
  "29620", "Lansing-East Lansing", 2005L,
  "30700", "Lincoln", 2005L,
  "33660", "Mobile", 2005L,
  "37340", "Palm Bay-Melbourne-Titusville", 2005L,
  "39340", "Provo-Orem", 2005L,
  "39900", "Reno", 2005L,
  "40140", "Riverside-San Bernardino-Ontario", 2005L,
  "41500", "Salinas", 2005L,
  "41940", "San Jose-Sunnyvale-Santa Clara", 2005L,
  "42260", "Santa Rosa-Petaluma", 2005L,
  "42340", "Savannah", 2005L,
  "43580", "Sioux Falls", 2005L,
  "45780", "Toledo", 2005L,
  "46520", "Urban Honolulu", 2005L,
  # 2006 cohort
  "11460", "Ann Arbor", 2006L,
  "11260", "Anchorage", 2006L,
  "12260", "Augusta-Richmond County", 2006L,
  "13380", "Bellingham", 2006L,
  "16300", "Cedar Rapids", 2006L,
  "16580", "Champaign-Urbana", 2006L,
  "21780", "Evansville", 2006L,
  "22420", "Flint", 2006L,
  "24300", "Grand Junction", 2006L,
  "28020", "Kalamazoo-Portage", 2006L,
  "29180", "Lafayette", 2006L,
  "32780", "Medford", 2006L,
  "33540", "Missoula", 2006L,
  "33700", "Modesto", 2006L,
  "33860", "Montgomery", 2006L,
  "36500", "Olympia-Lacey-Tumwater", 2006L,
  "37900", "Peoria", 2006L,
  "40220", "Roanoke", 2006L,
  "42020", "San Luis Obispo-Paso Robles", 2006L,
  "43340", "Shreveport-Bossier City", 2006L,
  "44300", "State College", 2006L,
  "45220", "Tallahassee", 2006L,
  "45820", "Topeka", 2006L,
  "48900", "Wilmington", 2006L,
  "49180", "Winston-Salem", 2006L,
  "49660", "Youngstown-Warren-Boardman", 2006L
)

cat("Craigslist entry dates for", nrow(craigslist_dates), "CBSAs\n")
cat("Entry year distribution:\n")
print(table(craigslist_dates$cl_entry_year))

# =============================================================================
# 3. CBSA-FIPS County Crosswalk
# =============================================================================
cat("Downloading CBSA-FIPS crosswalk...\n")
crosswalk_url <- "https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2020/delineation-files/list1_2020.xls"

temp_file <- tempfile(fileext = ".xls")
download.file(crosswalk_url, temp_file, mode = "wb", quiet = TRUE)
xwalk_raw <- readxl::read_excel(temp_file, skip = 2)

xwalk <- xwalk_raw %>%
  select(
    cbsa_code = 1,
    fips_state = 10,
    fips_county = 11
  ) %>%
  filter(!is.na(cbsa_code), !is.na(fips_state), !is.na(fips_county)) %>%
  mutate(
    cbsa_code = as.character(cbsa_code),
    fips = as.integer(paste0(
      sprintf("%02d", as.integer(fips_state)),
      sprintf("%03d", as.integer(fips_county))
    ))
  ) %>%
  select(cbsa_code, fips)
cat("Crosswalk loaded:", nrow(xwalk), "county-CBSA mappings\n")

# =============================================================================
# 4. Merge Craigslist dates to counties via CBSA crosswalk
# =============================================================================
county_treatment <- xwalk %>%
  inner_join(craigslist_dates %>% select(cbsa_code, cl_entry_year), by = "cbsa_code")

cat("Counties matched to Craigslist entry:", nrow(county_treatment), "\n")

# =============================================================================
# 5. Merge treatment to QWI data
# =============================================================================
qwi_pub <- qwi_pub %>%
  mutate(
    time_period = year * 4L + quarter,
    fips = as.integer(fips)
  )

panel <- qwi_pub %>%
  left_join(county_treatment %>% select(fips, cl_entry_year), by = "fips") %>%
  mutate(
    treated_ever = !is.na(cl_entry_year),
    first_treat_period = ifelse(treated_ever, cl_entry_year * 4L + 1L, 0L),
    post = ifelse(treated_ever & time_period >= first_treat_period, 1L, 0L)
  )

cat("\nPanel dimensions:\n")
cat("  Total obs:", nrow(panel), "\n")
cat("  Counties:", n_distinct(panel$fips), "\n")
cat("  Treated counties:", sum(panel$treated_ever[!duplicated(panel$fips)]), "\n")
cat("  Never-treated counties:", sum(!panel$treated_ever[!duplicated(panel$fips)]), "\n")

# Prepare placebo panel
qwi_placebo <- qwi_placebo %>%
  mutate(time_period = year * 4L + quarter, fips = as.integer(fips)) %>%
  left_join(county_treatment %>% select(fips, cl_entry_year), by = "fips") %>%
  mutate(
    treated_ever = !is.na(cl_entry_year),
    first_treat_period = ifelse(treated_ever, cl_entry_year * 4L + 1L, 0L),
    post = ifelse(treated_ever & time_period >= first_treat_period, 1L, 0L)
  )

# =============================================================================
# 6. Save
# =============================================================================
saveRDS(panel, "panel_publishing.rds")
saveRDS(qwi_placebo, "panel_placebo.rds")
saveRDS(county_treatment, "county_treatment.rds")
saveRDS(craigslist_dates, "craigslist_dates.rds")

cat("\nData saved.\n")
cat("  panel_publishing.rds:", nrow(panel), "rows\n")
cat("  panel_placebo.rds:", nrow(qwi_placebo), "rows\n")
