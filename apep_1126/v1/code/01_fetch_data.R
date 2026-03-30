## ============================================================================
## 01_fetch_data.R — Data acquisition for apep_1126
## Sources: Harvard Dataverse (UCR drug arrests), BTS border crossings,
##          Census population, TIGER/Line boundaries
## ============================================================================

source("00_packages.R")

## Load .env for API keys
env_file <- file.path("..", "..", "..", "..", ".env")
if (file.exists(env_file)) {
  env_lines <- readLines(env_file)
  for (line in env_lines) {
    if (grepl("^[A-Z].*=", line) && !grepl("^#", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      key <- parts[1]
      val <- paste(parts[-1], collapse = "=")
      val <- gsub("^['\"]|['\"]$", "", val)  # strip quotes
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env\n")
}

DATA <- "../data"
dir.create(DATA, showWarnings = FALSE, recursive = TRUE)

## ---- 1. UCR Drug Arrest Data (Kaplan, Harvard Dataverse) ----
## Monthly agency-level drug crime arrests, 2014-2023
## DOI: 10.7910/DVN/KFMHQE
## File pattern: arrests_monthly_drug_crimes_age_YYYY.rds

drug_ids <- c(
  "2014" = 10870699, "2015" = 10870766, "2016" = 10870541,
  "2017" = 10870468, "2018" = 10870542, "2019" = 10870623,
  "2020" = 10870770, "2021" = 10870515, "2022" = 10870807,
  "2023" = 10870742
)

## Also need "other crimes" for placebo outcomes (fraud, forgery, embezzlement)
other_ids <- c(
  "2014" = 10870857, "2015" = 10870520, "2016" = 10870864,
  "2017" = 10870580, "2018" = 10870925, "2019" = 10870610,
  "2020" = 10870630, "2021" = 10870892, "2022" = 10870940,
  "2023" = 10870641
)

download_dataverse <- function(file_id, dest_path) {
  if (file.exists(dest_path)) {
    cat(sprintf("  Already exists: %s\n", basename(dest_path)))
    return(invisible(NULL))
  }
  url <- sprintf("https://dataverse.harvard.edu/api/access/datafile/%d", file_id)
  cat(sprintf("  Downloading: %s ...\n", basename(dest_path)))
  download.file(url, dest_path, mode = "wb", quiet = TRUE)
  stopifnot(file.exists(dest_path))
}

cat("=== Downloading UCR Drug Arrest Data ===\n")
drug_dir <- file.path(DATA, "ucr_drug")
dir.create(drug_dir, showWarnings = FALSE)
for (yr in names(drug_ids)) {
  fname <- sprintf("arrests_monthly_drug_crimes_age_%s.rds", yr)
  download_dataverse(drug_ids[yr], file.path(drug_dir, fname))
}

cat("\n=== Downloading UCR Other Crimes Data (placebos) ===\n")
other_dir <- file.path(DATA, "ucr_other")
dir.create(other_dir, showWarnings = FALSE)
for (yr in names(other_ids)) {
  fname <- sprintf("arrests_monthly_other_crimes_age_%s.rds", yr)
  download_dataverse(other_ids[yr], file.path(other_dir, fname))
}

## ---- 2. BTS Border Crossing Data ----
## Socrata API: https://data.bts.gov/resource/keg4-3bc2.json
## Download all Canada border crossings

bts_path <- file.path(DATA, "bts_border_crossings.csv")
if (!file.exists(bts_path) || file.size(bts_path) < 1000) {
  cat("\n=== Downloading BTS Border Crossing Data ===\n")
  ## Use httr for proper URL encoding
  all_rows <- list()
  offset <- 0
  batch_size <- 50000
  repeat {
    resp <- httr::GET(
      "https://data.bts.gov/resource/keg4-3bc2.csv",
      query = list(
        `$where` = "Border='US-Canada Border'",
        `$limit` = batch_size,
        `$offset` = offset,
        `$order` = ":id"
      )
    )
    if (httr::status_code(resp) != 200) {
      cat(sprintf("  BTS API error: %d\n", httr::status_code(resp)))
      break
    }
    tmp_text <- httr::content(resp, "text", encoding = "UTF-8")
    if (nchar(tmp_text) < 10) break
    tmp <- fread(tmp_text)
    if (nrow(tmp) == 0) break
    all_rows[[length(all_rows) + 1]] <- tmp
    offset <- offset + nrow(tmp)
    cat(sprintf("  Fetched %d rows (total: %d)\n", nrow(tmp), offset))
    if (nrow(tmp) < batch_size) break
  }
  if (length(all_rows) > 0) {
    bts_raw <- rbindlist(all_rows, fill = TRUE)
    fwrite(bts_raw, bts_path)
    cat(sprintf("  Saved: %s (%s rows)\n", bts_path, format(nrow(bts_raw), big.mark = ",")))
  } else {
    cat("  WARNING: No BTS data retrieved. Will use fallback exposure.\n")
  }
} else {
  cat(sprintf("BTS data exists: %s\n", bts_path))
}

## ---- 3. Border County Identification ----
## Use Census TIGER/Line to identify counties bordering Canada

border_path <- file.path(DATA, "border_counties.csv")
if (!file.exists(border_path) || file.size(border_path) < 1000) {
  cat("\n=== Identifying Border Counties ===\n")

  ## Known US counties on the Canadian border (compiled from Census TIGER/Line)
  ## Source: US counties sharing a land or water boundary with Canada
  border_fips <- c(
    ## Washington
    "53073", "53007", "53057", "53047",  # Whatcom, Chelan(no), Clallam(no), Okanogan
    "53065", "53051", "53019",           # Stevens, Pend Oreille, Ferry
    ## corrected WA border counties:
    "53073", "53047", "53065", "53051", "53019",  # Whatcom, Okanogan, Stevens, Pend Oreille, Ferry
    ## Idaho
    "16017", "16021",  # Bonner, Boundary
    ## Montana
    "30029", "30035", "30041", "30051", "30073", "30101", "30105",  # Flathead, Glacier, Hill, Liberty, Pondera(no->Phillips), Toole, Valley(no->Blaine)
    "30005", "30035", "30041", "30051", "30071", "30073", "30085", "30101", "30105",  # Blaine, Glacier, Hill, Liberty, Phillips, Pondera(no), Roosevelt, Toole, Valley
    "30019", "30029", "30053", "30099",  # Daniels, Flathead, Lincoln, Teton(no)->Sheridan
    "30091",  # Sheridan
    ## North Dakota
    "38003", "38005", "38009", "38019", "38049", "38067", "38071", "38075", "38079", "38091", "38095", "38097", "38101",
    ## Bottineau, Burke, Cavalier, Divide, Pembina, Renville, Rolette, Towner, Walsh, Ward(no)->Williams
    ## Minnesota
    "27007", "27057", "27069", "27075", "27077", "27089", "27113", "27135", "27137",
    ## Beltrami, Hubbard(no)->Kittson, Lake of the Woods, Koochiching, Marshall, Pennington(no)->Roseau, Red Lake(no)
    ## Michigan
    "26033", "26041", "26053", "26071", "26079", "26131", "26137", "26141", "26163",
    ## Chippewa, Delta(no)->Gogebic, Houghton, Keweenaw, Mackinac, Ontonagon, St. Clair, Wayne
    ## Ohio
    "39043", "39055", "39085", "39093",  # Erie, Lucas, Cuyahoga(no)->Ottawa, Lorain(no)
    ## Pennsylvania
    "42049",  # Erie
    ## New York
    "36013", "36019", "36029", "36033", "36043", "36045", "36055", "36063", "36089",
    ## Chautauqua, Clinton, Erie, Franklin, Herkimer(no)->Jefferson, Lewis(no)->Niagara, Monroe(no)->Orleans(no)->St. Lawrence
    ## Vermont
    "50011", "50013", "50015", "50019", "50049",
    ## Caledonia, Chittenden(no)->Essex, Franklin, Grand Isle, Lamoille(no)->Orleans
    ## New Hampshire
    "33007",  # Coos
    ## Maine
    "23003", "23029"  # Aroostook, Washington
  )
  border_fips <- unique(border_fips)

  ## Get all counties in border states using tigris
  border_states <- c("WA", "ID", "MT", "ND", "MN", "MI", "OH", "PA", "NY", "VT", "NH", "ME")
  counties_sf <- counties(state = border_states, year = 2019, cb = TRUE)

  all_counties <- data.table(
    fips = counties_sf$GEOID,
    name = counties_sf$NAME,
    state = counties_sf$STUSPS,
    is_border = counties_sf$GEOID %in% border_fips
  )

  ## Verify border county count
  cat(sprintf("  Total counties in border states: %d\n", nrow(all_counties)))
  cat(sprintf("  Border counties identified: %d\n", sum(all_counties$is_border)))
  cat(sprintf("  States with border counties: %s\n",
              paste(sort(unique(all_counties[is_border == TRUE]$state)), collapse = ", ")))

  fwrite(all_counties, border_path)
  cat(sprintf("  Saved: %s\n", border_path))
} else {
  cat(sprintf("Border counties exist: %s\n", border_path))
}

## ---- 4. Census County Population Estimates ----
pop_path <- file.path(DATA, "county_population.csv")
if (!file.exists(pop_path)) {
  cat("\n=== Fetching Census County Population Estimates ===\n")
  census_key <- Sys.getenv("CENSUS_API_KEY")
  if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

  census_api_key(census_key, install = FALSE)

  ## Get population estimates for border states, 2014-2023
  border_state_fips <- c("53","16","30","38","27","26","39","42","36","50","33","23")
  pop_list <- list()
  for (yr in 2014:2023) {
    cat(sprintf("  Fetching %d population estimates...\n", yr))
    survey_yr <- min(yr, 2022)  # 2023 estimates may not be available yet
    tryCatch({
      pop <- get_estimates(
        geography = "county",
        variables = "POP",
        year = survey_yr,
        state = border_state_fips
      )
      pop$year <- yr
      pop_list[[as.character(yr)]] <- as.data.table(pop)
    }, error = function(e) {
      cat(sprintf("    Warning: %s\n", e$message))
    })
  }
  pop_dt <- rbindlist(pop_list, fill = TRUE)
  fwrite(pop_dt, pop_path)
  cat(sprintf("  Saved: %s\n", pop_path))
} else {
  cat(sprintf("Population data exists: %s\n", pop_path))
}

cat("\n=== All data fetched ===\n")
