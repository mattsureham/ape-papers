# =============================================================================
# 01_fetch_data.R — BRAC treatment list + QWI from Azure
# =============================================================================
source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# =============================================================================
# PART 1: BRAC Treatment List
# =============================================================================
# Major BRAC closures/realignments compiled from DoD BRAC Commission final
# reports (1988, 1991, 1993, 1995, 2005) and GAO-05-138.
# Only installations with significant civilian/military job losses.
# =============================================================================

brac_rows <- list(
  # === BRAC 1988 ===
  list("06075", "Presidio of San Francisco", 1988L, "closure"),
  list("06085", "Moffett Field NAS", 1988L, "closure"),
  list("17031", "Fort Sheridan", 1988L, "closure"),
  list("08041", "Ent AFB", 1988L, "closure"),
  list("42101", "Philadelphia Naval Shipyard", 1988L, "closure"),
  list("24005", "Fort Holabird", 1988L, "closure"),
  list("06013", "Concord NWS", 1988L, "closure"),
  list("26163", "Selfridge ANG Base", 1988L, "realignment"),

  # === BRAC 1991 ===
  list("06053", "Fort Ord", 1991L, "closure"),
  list("06037", "Long Beach Naval Shipyard", 1991L, "closure"),
  list("25021", "South Weymouth NAS", 1991L, "closure"),
  list("04019", "Williams AFB", 1991L, "closure"),
  list("21059", "Evansville AAP", 1991L, "closure"),
  list("34005", "Fort Dix", 1991L, "realignment"),
  list("09011", "Sub Base New London", 1991L, "realignment"),
  list("48141", "Biggs Army Airfield", 1991L, "realignment"),

  # === BRAC 1993 ===
  list("06061", "McClellan AFB", 1993L, "closure"),
  list("06067", "Sacramento Army Depot", 1993L, "closure"),
  list("06001", "Alameda NAS", 1993L, "closure"),
  list("06077", "Sharpe Army Depot", 1993L, "closure"),
  list("12031", "Cecil Field NAS", 1993L, "closure"),
  list("12025", "Homestead AFB", 1993L, "closure"),
  list("47157", "Memphis NAS", 1993L, "closure"),
  list("48297", "Chase Field NAS", 1993L, "closure"),
  list("27053", "Twin Cities AAP", 1993L, "closure"),
  list("39089", "Newark AFB", 1993L, "closure"),
  list("23003", "Loring AFB", 1993L, "closure"),
  list("44005", "Naval Station Newport", 1993L, "realignment"),
  list("42017", "NAWC Warminster", 1993L, "closure"),
  list("06081", "Onizuka AFS", 1993L, "realignment"),
  list("21111", "Fort Knox", 1993L, "realignment"),

  # === BRAC 1995 ===
  list("06077", "Defense Depot San Joaquin", 1995L, "closure"),
  list("22079", "England AFB", 1995L, "closure"),
  list("29095", "Richards-Gebaur ARS", 1995L, "closure"),
  list("39023", "Springfield-Beckley MAP", 1995L, "closure"),
  list("12031", "NAS Jacksonville", 1995L, "realignment"),
  list("13215", "Fort Benning", 1995L, "realignment"),
  list("17163", "Scott AFB", 1995L, "realignment"),
  list("51550", "NAS Oceana", 1995L, "realignment"),

  # === BRAC 2005 ===
  list("23005", "Brunswick NAS", 2005L, "closure"),
  list("36103", "Fort Totten", 2005L, "closure"),
  list("42041", "Carlisle Barracks", 2005L, "realignment"),
  list("51740", "Norfolk Naval Shipyard", 2005L, "realignment"),
  list("51710", "NAS Norfolk", 2005L, "realignment"),
  list("47093", "McGhee Tyson", 2005L, "realignment"),
  list("09009", "Sub Base Groton", 2005L, "realignment")
)

brac <- rbindlist(lapply(brac_rows, function(r) {
  data.table(county_fips = r[[1]], installation = r[[2]],
             brac_round = r[[3]], action = r[[4]])
}))

# Remove duplicate county-round combinations (keep first installation)
brac <- brac[!duplicated(paste(county_fips, brac_round)), ]

cat("BRAC treatment assignments:\n")
cat("  Total unique county-round:", nrow(brac), "\n")
cat("  By round:\n")
print(brac[, .N, by = brac_round][order(brac_round)])
cat("  Unique counties:", uniqueN(brac$county_fips), "\n")
cat("  Closures:", sum(brac$action == "closure"), "\n")
cat("  Realignments:", sum(brac$action == "realignment"), "\n")

# For staggered DiD, assign the FIRST closure round to each county
brac_treatment <- brac[, .(
  first_brac_round = min(brac_round),
  n_actions = .N,
  actions = paste(unique(action), collapse = ", ")
), by = county_fips]

cat("\nFirst-round treatment assignment:\n")
print(brac_treatment[, .N, by = first_brac_round][order(first_brac_round)])
cat("  Total treated counties:", nrow(brac_treatment), "\n")

fwrite(brac_treatment, "../data/brac_treatment.csv")
message("Saved BRAC treatment: ", nrow(brac_treatment), " counties")

# =============================================================================
# PART 2: Fetch QWI from Azure
# =============================================================================
# Fix: shell truncates connection string at semicolons. Read directly from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
cs_val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line[1])
cs_val <- gsub('^["\']|["\']$', '', cs_val)  # strip quotes if any
Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = cs_val)
cat("Azure conn string length:", nchar(cs_val), "\n")
stopifnot(nchar(cs_val) > 100)  # sanity check

con <- apep_azure_connect()

cat("\nFetching QWI data from Azure (all counties, sex=0, agegrp=A00)...\n")
cat("This queries ~33 GB of Parquet across 51 states...\n")

qwi <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    year,
    quarter,
    industry,
    Emp,
    HirA,
    Sep,
    EarnS,
    FrmJbGn,
    FrmJbLs
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE sex = 0
    AND agegrp = 'A00'
    AND year >= 1993
    AND year <= 2023
")

cat("QWI rows fetched:", nrow(qwi), "\n")
cat("Year range:", min(qwi$year), "-", max(qwi$year), "\n")
cat("Unique counties:", length(unique(qwi$county_fips)), "\n")
cat("Unique industries:", length(unique(qwi$industry)), "\n")

apep_azure_disconnect(con)

setDT(qwi)
qwi[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi[, time_q := year * 4L + as.integer(quarter)]

fwrite(qwi, "../data/qwi_raw.csv")
message("Saved QWI: ", nrow(qwi), " rows")
cat("\nData fetch complete.\n")
