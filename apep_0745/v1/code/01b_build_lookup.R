## 01b_build_lookup.R — Build postcode-to-LA lookup using two-pass approach:
## 1. Direct match on full postcode from NSPL (covers ~43%)
## 2. Outward-code majority match for remaining postcodes (covers ~90%+)
## APEP-0745: The Freeport Gamble

source("00_packages.R")

lookup_file <- "../data/postcode_la_lookup.rds"
if (file.exists(lookup_file)) { cat("Lookup exists.\n"); q("no") }

cat("=== Building postcode-to-LA lookup (two-pass) ===\n")

# --- Load NSPL ---
nspl <- fread("../data/nspl_lookup.csv", showProgress = FALSE)
nspl[, postcode := toupper(trimws(pcds))]
nspl_eng <- nspl[grepl("^E", rgn25cd)]
nspl_eng <- unique(nspl_eng[, .(postcode, la_code = lad25cd, la_name = lad25nm, region = rgn25cd)])
cat("NSPL English postcodes:", format(nrow(nspl_eng), big.mark = ","), "\n")

# --- Load CH postcodes ---
cat("Reading CH postcodes...\n")
ch <- fread("../data/companies_house.csv",
  select = c("RegAddress.PostCode", "IncorporationDate"),
  showProgress = FALSE)
ch[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
ch <- ch[inc_date >= "2016-01-01" & inc_date <= "2025-12-31"]
ch[, postcode := toupper(trimws(RegAddress.PostCode))]
ch <- ch[nchar(postcode) >= 5 & nchar(postcode) <= 8]
ch_pcs <- unique(ch$postcode)
cat("CH unique postcodes:", format(length(ch_pcs), big.mark = ","), "\n")

# --- Pass 1: Direct match ---
pass1 <- nspl_eng[postcode %in% ch_pcs]
cat("Pass 1 (direct match):", format(nrow(pass1), big.mark = ","), "postcodes\n")

# --- Pass 2: Outward-code majority match ---
# Build outward-code to LA lookup from NSPL
nspl_eng[, outcode := sub("\\s+[0-9][A-Za-z]{2}$", "", postcode)]

# For each outcode, find the majority LA
outcode_la <- nspl_eng[, .N, by = .(outcode, la_code, la_name, region)][
  order(outcode, -N)][
  , .SD[1], by = outcode]
cat("Outward codes mapped:", nrow(outcode_la), "\n")

# Get unmatched CH postcodes
unmatched_pcs <- ch_pcs[!ch_pcs %in% pass1$postcode]
unmatched_dt <- data.table(postcode = unmatched_pcs)
unmatched_dt[, outcode := sub("\\s+[0-9][A-Za-z]{2}$", "", postcode)]

# Match via outward code
pass2 <- merge(
  unmatched_dt,
  outcode_la[, .(outcode, la_code, la_name, region)],
  by = "outcode",
  all.x = FALSE
)[, .(postcode, la_code, la_name, region)]

cat("Pass 2 (outcode match):", format(nrow(pass2), big.mark = ","), "postcodes\n")

# --- Combine ---
lookup <- rbind(pass1, pass2)
lookup <- unique(lookup, by = "postcode")

total_matched <- nrow(lookup)
total_ch <- length(ch_pcs)
cat("\nTotal matched:", format(total_matched, big.mark = ","), "/",
    format(total_ch, big.mark = ","),
    "(", round(100 * total_matched / total_ch), "%)\n")

# Check freeport LAs specifically
freeport_la_names <- c(
  "Redcar and Cleveland", "Middlesbrough", "Stockton-on-Tees", "Hartlepool",
  "East Riding of Yorkshire", "North Lincolnshire", "North East Lincolnshire",
  "Thurrock", "Barking and Dagenham", "Havering",
  "Tendring", "Ipswich",
  "Southampton", "Eastleigh",
  "North West Leicestershire", "South Derbyshire", "Rushcliffe",
  "Plymouth",
  "Liverpool", "Halton", "Wirral"
)
freeport_pcs <- lookup[la_name %in% freeport_la_names]
cat("Postcodes in freeport LAs:", format(nrow(freeport_pcs), big.mark = ","), "\n")
cat("Freeport LAs found:", paste(unique(freeport_pcs$la_name), collapse = ", "), "\n")

saveRDS(lookup, lookup_file)
cat("\nLookup saved.\n")
