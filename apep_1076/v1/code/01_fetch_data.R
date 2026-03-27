## 01_fetch_data.R — Download YRBSS SADC data and construct treatment panel
## apep_1076: Conversion Therapy Bans and Adolescent Mental Health

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. Download YRBSS SADC ASCII files (state-level, all years through 2023)
# =============================================================================

# CDC splits the combined SADC dataset by state-name alphabetical groups
base_url <- "https://www.cdc.gov/yrbs/files/sadc_2023/HS"
state_groups <- c("a_d", "e_h", "i_l", "m", "n_p", "q_t", "u_z")

dat_files <- c()
for (sg in state_groups) {
  fname <- paste0("sadc_2023_state_", sg, ".dat")
  fpath <- file.path(data_dir, fname)
  url <- paste0(base_url, "/", fname)

  if (!file.exists(fpath)) {
    cat("Downloading:", fname, "...\n")
    tryCatch({
      download.file(url, destfile = fpath, mode = "wb", quiet = FALSE)
      stopifnot(file.exists(fpath) && file.size(fpath) > 1000)
      cat("  OK:", round(file.size(fpath) / 1e6, 1), "MB\n")
    }, error = function(e) {
      stop("FATAL: Could not download ", url, ": ", conditionMessage(e))
    })
  } else {
    cat("Already have:", fname, "(", round(file.size(fpath) / 1e6, 1), "MB)\n")
  }
  dat_files <- c(dat_files, fpath)
}

# =============================================================================
# 2. Parse fixed-width ASCII files using column positions from SPSS syntax
# =============================================================================

# Column positions extracted from 2023-SADC-SPSS-Input-Program.sps
# Note: R's read.fwf uses widths, not start-end positions
# We define start positions and widths for each variable

col_specs <- list(
  sitecode  = c(start = 1,   width = 5),    # State/site code (character)
  year      = c(start = 114, width = 8),     # Survey year (numeric)
  weight    = c(start = 125, width = 10),    # Analysis weight
  stratum   = c(start = 135, width = 8),     # Stratum
  PSU       = c(start = 143, width = 8),     # PSU
  age       = c(start = 159, width = 3),     # Age category
  sex       = c(start = 162, width = 3),     # 1=Female, 2=Male
  grade     = c(start = 165, width = 3),     # Grade 9-12
  race4     = c(start = 168, width = 3),     # Race (4 categories)
  race7     = c(start = 171, width = 3),     # Race (7 categories)
  sexid     = c(start = 215, width = 8),     # Sexual identity
  qn26      = c(start = 388, width = 3),     # Felt sad/hopeless (2+ weeks)
  qn27      = c(start = 391, width = 3),     # Seriously considered suicide
  qn28      = c(start = 397, width = 3),     # Made a suicide plan
  qn29      = c(start = 403, width = 3)      # Attempted suicide
)

# Read and combine all state group files
all_data <- list()

for (fpath in dat_files) {
  cat("Parsing:", basename(fpath), "... ")

  # Read lines first to handle fixed-width
  lines <- readLines(fpath, warn = FALSE)
  cat(length(lines), "records\n")

  if (length(lines) == 0) next

  # Extract each variable using substr
  # Column positions from 2023-SADC-SPSS-Input-Program.sps (verified)
  df <- data.table(
    sitecode = trimws(substr(lines, 1, 5)),
    year     = as.integer(trimws(substr(lines, 114, 121))),
    weight   = as.numeric(trimws(substr(lines, 125, 134))),
    stratum  = as.integer(trimws(substr(lines, 135, 142))),
    PSU      = as.integer(trimws(substr(lines, 143, 150))),
    age      = as.integer(trimws(substr(lines, 159, 161))),
    sex      = as.integer(trimws(substr(lines, 162, 164))),
    grade    = as.integer(trimws(substr(lines, 165, 167))),
    race4    = as.integer(trimws(substr(lines, 168, 170))),
    race7    = as.integer(trimws(substr(lines, 171, 173))),
    sexid    = as.integer(trimws(substr(lines, 215, 222))),
    qn24     = as.integer(trimws(substr(lines, 388, 390))),  # Bullied at school
    qn25     = as.integer(trimws(substr(lines, 391, 393))),  # Electronic bullying
    qn26     = as.integer(trimws(substr(lines, 394, 396))),  # Sad or hopeless
    qn27     = as.integer(trimws(substr(lines, 397, 399))),  # Considered suicide
    qn28     = as.integer(trimws(substr(lines, 400, 402))),  # Made suicide plan
    qn29     = as.integer(trimws(substr(lines, 403, 405)))   # Attempted suicide
  )

  all_data[[basename(fpath)]] <- df
}

yrbss <- rbindlist(all_data, fill = TRUE)
cat("\nCombined YRBSS dataset:", nrow(yrbss), "observations\n")

# Validate: must have data
stopifnot(nrow(yrbss) > 10000)

# Check year distribution
cat("\nYear distribution:\n")
print(table(yrbss$year, useNA = "ifany"))

# Check sexual identity availability
cat("\nSexual identity (sexid) distribution:\n")
print(table(yrbss$sexid, useNA = "ifany"))

# Check state coverage
cat("\nNumber of unique sites:", length(unique(yrbss$sitecode)), "\n")

# Save raw parsed data
fwrite(yrbss, file.path(data_dir, "yrbss_combined.csv"))
cat("Saved combined YRBSS data:", nrow(yrbss), "rows\n")

# =============================================================================
# 3. Treatment Panel: Conversion Therapy Ban Adoption Dates
# =============================================================================

cat("\nConstructing treatment panel...\n")

# Hand-coded from Movement Advancement Project (MAP) and legislative records
# Effective dates for conversion therapy bans on minors by state
# Sources: MAP, Williams Institute, state legislative records
ban_data <- data.table(
  state_abbr = c(
    "CA", "NJ", "DC", "OR", "IL", "VT", "NV", "CT", "NM", "RI",
    "NH", "WA", "MD", "HI", "DE", "NY", "MA", "ME", "CO", "VA",
    "UT", "MN"
  ),
  ban_year = c(
    2012, 2013, 2014, 2015, 2016, 2016, 2017, 2017, 2017, 2017,
    2018, 2018, 2018, 2018, 2018, 2019, 2019, 2019, 2019, 2020,
    2020, 2023
  )
)
# Note: MI (2024) and PA (2024) excluded — after our last survey wave

# State abbreviation to YRBSS sitecode mapping
# YRBSS sitecodes are typically 2-letter state abbreviations
state_fips <- data.table(
  state_abbr = c(
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL",
    "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
    "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
    "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
    "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
  ),
  state_name = c(
    "Alabama","Alaska","Arizona","Arkansas","California","Colorado",
    "Connecticut","Delaware","Florida",
    "Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa",
    "Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts",
    "Michigan","Minnesota","Mississippi","Missouri","Montana",
    "Nebraska","Nevada","New Hampshire","New Jersey","New Mexico",
    "New York","North Carolina","North Dakota","Ohio","Oklahoma",
    "Oregon","Pennsylvania","Rhode Island","South Carolina",
    "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia",
    "Washington","West Virginia","Wisconsin","Wyoming"
  )
)

# Merge ban data with state info
ban_panel <- merge(state_fips, ban_data, by = "state_abbr", all.x = TRUE)
ban_panel[is.na(ban_year), ban_year := Inf]  # Never-treated states

fwrite(ban_panel, file.path(data_dir, "treatment_panel.csv"))
cat("Treatment panel saved:", nrow(ban_panel), "states,",
    sum(is.finite(ban_panel$ban_year)), "with bans.\n")

cat("\nBan adoption timeline:\n")
print(ban_panel[is.finite(ban_year)][order(ban_year), .(state_abbr, ban_year)])

cat("\n=== Data fetch complete ===\n")
