## 01_fetch_data.R — Fetch all data for apep_0825
## Networked Backlash in Sweden: Bosättningslagen Dispersal and SD Surge via SCI

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## HELPER: SCB PxWeb API
## ============================================================================

fetch_scb_tidy <- function(table_path, query_body, value_name = "value",
                          use_codes = TRUE) {
  url <- paste0("https://api.scb.se/OV0104/v1/doris/en/ssd/", table_path)
  resp <- POST(url, body = query_body, encode = "json", content_type_json())
  if (status_code(resp) != 200) {
    stop("SCB API error ", status_code(resp), " for ", table_path,
         "\nBody: ", content(resp, "text", encoding = "UTF-8"))
  }
  raw <- content(resp, "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)
  dims <- parsed$dimension
  dim_names <- names(dims)
  values <- parsed$value

  dim_labels <- lapply(dim_names, function(d) {
    cats <- dims[[d]]$category
    idx <- unlist(cats$index)
    if (use_codes) {
      # Use codes (keys of index) instead of labels
      codes <- names(idx)
      codes[order(idx)]
    } else {
      labs <- unlist(cats$label)
      labs[order(idx)]
    }
  })
  names(dim_labels) <- dim_names

  grid <- expand.grid(rev(dim_labels), stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  grid <- grid[, rev(seq_len(ncol(grid)))]
  grid[[value_name]] <- values
  as_tibble(grid)
}

## ============================================================================
## 1. ELECTION DATA: SD vote shares by municipality (2010-2022)
## Source: SCB ME0104T3
## ============================================================================

cat("\n=== 1. Fetching Riksdag election data by party and municipality ===\n")

# Get municipality codes from metadata
meta_resp <- GET("https://api.scb.se/OV0104/v1/doris/en/ssd/ME/ME0104/ME0104C/ME0104T3")
if (status_code(meta_resp) != 200) stop("Cannot reach SCB election metadata")
meta <- content(meta_resp, "parsed")
all_regions <- unlist(meta$variables[[1]]$values)
region_texts <- unlist(meta$variables[[1]]$valueTexts)
# Municipality codes are 4 digits (not VR prefixed constituency codes)
muni_mask <- nchar(all_regions) == 4
muni_codes <- all_regions[muni_mask]
muni_names <- region_texts[muni_mask]
cat("Found", length(muni_codes), "municipalities\n")
cat("Sample codes:", head(muni_codes, 5), "\n")

# Fetch in batches (SCB limits query size)
batch_size <- 50
election_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  Election batch", ceiling(i / batch_size), "of", ceiling(length(muni_codes) / batch_size), "\n")

  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = as.list(batch))),
      list(code = "Partimm", selection = list(filter = "item",
           values = as.list(c("M", "C", "FP", "KD", "MP", "S", "V", "SD", "ÖVRIGA")))),
      list(code = "ContentsCode", selection = list(filter = "item",
           values = as.list(c("ME0104B6", "ME0104B7"))))
    ),
    response = list(format = "json-stat2")
  )

  result <- tryCatch(
    fetch_scb_tidy("ME/ME0104/ME0104C/ME0104T3", query),
    error = function(e) {
      stop("Failed to fetch election data batch ", ceiling(i / batch_size), ": ", e$message)
    }
  )
  election_list <- c(election_list, list(result))
  Sys.sleep(0.3)
}

election_raw <- bind_rows(election_list)
cat("Raw election rows:", nrow(election_raw), "\n")

# Pivot to get vote counts and shares side by side
election_df <- election_raw %>%
  pivot_wider(names_from = ContentsCode, values_from = value)

# Identify content columns
content_cols <- setdiff(names(election_df), c("Region", "Partimm", "Tid"))
cat("Content columns:", paste(content_cols, collapse = ", "), "\n")
names(election_df)[names(election_df) == content_cols[1]] <- "votes"
names(election_df)[names(election_df) == content_cols[2]] <- "vote_share"

election_df <- election_df %>%
  rename(muni_code = Region, party = Partimm, year = Tid) %>%
  mutate(year = as.integer(year))

# SD vote shares
# Party codes: M, C, FP, KD, MP, S, V, SD, ÖVRIGA
sd_votes <- election_df %>%
  filter(party == "SD") %>%
  select(muni_code, year, sd_share = vote_share, sd_votes = votes)

cat("SD vote data: ", n_distinct(sd_votes$muni_code), "munis x",
    n_distinct(sd_votes$year), "elections\n")

# Sanity check: national SD trend
sd_national <- sd_votes %>%
  group_by(year) %>%
  summarise(mean_sd = mean(sd_share, na.rm = TRUE), .groups = "drop")
cat("SD national mean share by year:\n")
print(sd_national)

write_csv(election_df, file.path(DATA_DIR, "election_all_parties.csv"))
write_csv(sd_votes, file.path(DATA_DIR, "sd_votes.csv"))

# Municipality name lookup
muni_lookup <- tibble(muni_code = muni_codes, muni_name = muni_names)
write_csv(muni_lookup, file.path(DATA_DIR, "muni_lookup.csv"))

## ============================================================================
## 2. FACEBOOK SOCIAL CONNECTEDNESS INDEX (SCI) — NUTS3
## Source: Meta/Facebook via Humanitarian Data Exchange
## ============================================================================

cat("\n=== 2. Downloading SCI data ===\n")

sci_url <- "https://data.humdata.org/dataset/e9988552-74e4-4ff4-943f-c782ac8bca87/resource/b691d1d1-b286-456d-9a23-16e2f2d463cc/download/nuts_2024.zip"
sci_zip <- file.path(DATA_DIR, "nuts_2024.zip")
sci_dir <- file.path(DATA_DIR, "sci")

if (!file.exists(sci_zip)) {
  download.file(sci_url, sci_zip, mode = "wb", quiet = FALSE)
  dir.create(sci_dir, showWarnings = FALSE)
  unzip(sci_zip, exdir = sci_dir)
  cat("SCI data downloaded and extracted.\n")
} else {
  cat("SCI data already exists, skipping download.\n")
  if (!dir.exists(sci_dir)) {
    dir.create(sci_dir, showWarnings = FALSE)
    unzip(sci_zip, exdir = sci_dir)
  }
}

sci_files <- list.files(sci_dir, pattern = "\\.tsv$|\\.csv$",
                        recursive = TRUE, full.names = TRUE)
cat("SCI files found:", length(sci_files), "\n")
cat("Files:", paste(basename(sci_files), collapse = ", "), "\n")

# Read the NUTS3 SCI file (prefer nuts3 over nuts1/nuts2)
sci_file <- sci_files[grepl("nuts3", sci_files, ignore.case = TRUE)]
if (length(sci_file) == 0) sci_file <- sci_files[1]
sci_raw <- fread(sci_file[1], header = TRUE)
cat("Total SCI rows:", nrow(sci_raw), "\n")
cat("SCI columns:", paste(names(sci_raw), collapse = ", "), "\n")

# Swedish NUTS3 codes start with "SE"
# Sweden has 21 counties (län) at NUTS3 level: SE110, SE121, SE122, ..., SE332
# Column names vary across SCI releases - detect automatically
sci_cols <- names(sci_raw)
cat("SCI columns:", paste(sci_cols, collapse = ", "), "\n")
user_col <- sci_cols[grepl("user", sci_cols, ignore.case = TRUE) & grepl("reg|loc", sci_cols, ignore.case = TRUE)][1]
friend_col <- sci_cols[grepl("fr", sci_cols, ignore.case = TRUE) & grepl("reg|loc", sci_cols, ignore.case = TRUE)][1]
sci_col <- sci_cols[grepl("sci", sci_cols, ignore.case = TRUE)][1]
cat("Using columns:", user_col, friend_col, sci_col, "\n")

sci_se <- sci_raw %>%
  filter(grepl("^SE", .data[[user_col]]) & grepl("^SE", .data[[friend_col]])) %>%
  as_tibble() %>%
  rename(user_nuts3 = !!user_col, friend_nuts3 = !!friend_col, sci = !!sci_col)

cat("Sweden-Sweden SCI pairs:", nrow(sci_se), "\n")
cat("Unique Swedish NUTS3 regions:", n_distinct(c(sci_se$user_nuts3, sci_se$friend_nuts3)), "\n")

# Get list of Swedish NUTS3 codes
se_nuts3 <- sort(unique(c(sci_se$user_nuts3, sci_se$friend_nuts3)))
cat("Swedish NUTS3 codes:", paste(se_nuts3, collapse = ", "), "\n")

write_csv(sci_se, file.path(DATA_DIR, "sci_se_pairs.csv"))

## ============================================================================
## 3. MUNICIPALITY-TO-NUTS3 CROSSWALK
## Swedish municipalities map to 21 counties (län)
## ============================================================================

cat("\n=== 3. Building municipality-to-county crosswalk ===\n")

# SCB municipality codes: first 2 digits = county code
# County code → NUTS3 mapping:
# County codes 01-25 map to NUTS3 codes SE110-SE332
# The mapping is:
#   01 Stockholm → SE110
#   03 Uppsala → SE121
#   04 Södermanland → SE122
#   05 Östergötland → SE123
#   06 Jönköping → SE211
#   07 Kronoberg → SE212
#   08 Kalmar → SE213
#   09 Gotland → SE214
#   10 Blekinge → SE221
#   12 Skåne → SE224
#   13 Halland → SE231
#   14 Västra Götaland → SE232
#   17 Värmland → SE311
#   18 Örebro → SE312
#   19 Västmanland → SE313
#   20 Dalarna → SE321
#   21 Gävleborg → SE322
#   22 Västernorrland → SE323
#   23 Jämtland → SE331
#   24 Västerbotten → SE332
#   25 Norrbotten → SE332  # shares NUTS3 with Västerbotten

# Actually, let me use the official mapping. Sweden's NUTS3 = counties (län)
# BUT NUTS2016/2024 reorganized some. Let me build from the SCB county codes.

county_nuts3 <- tribble(
  ~county_code, ~county_name, ~nuts3,
  "01", "Stockholm",        "SE110",
  "03", "Uppsala",          "SE121",
  "04", "Södermanland",     "SE122",
  "05", "Östergötland",     "SE123",
  "06", "Jönköping",        "SE211",
  "07", "Kronoberg",        "SE212",
  "08", "Kalmar",           "SE213",
  "09", "Gotland",          "SE214",
  "10", "Blekinge",         "SE221",
  "12", "Skåne",            "SE224",
  "13", "Halland",          "SE231",
  "14", "Västra Götaland",  "SE232",
  "17", "Värmland",         "SE311",
  "18", "Örebro",           "SE312",
  "19", "Västmanland",      "SE313",
  "20", "Dalarna",          "SE321",
  "21", "Gävleborg",        "SE322",
  "22", "Västernorrland",   "SE323",
  "23", "Jämtland",         "SE331",
  "24", "Västerbotten",     "SE332",
  "25", "Norrbotten",       "SE332"
)

# Check which NUTS3 codes are in the SCI data
matched <- county_nuts3$nuts3 %in% se_nuts3
cat("NUTS3 codes in SCI data:", sum(matched), "of", nrow(county_nuts3), "\n")
if (!all(matched)) {
  cat("Missing from SCI:", county_nuts3$nuts3[!matched], "\n")
}

# If NUTS3 codes don't match exactly, try to reconcile
if (sum(matched) < 15) {
  cat("WARNING: Low match rate. Let me check SCI NUTS3 codes...\n")
  cat("SCI has these SE codes:", paste(se_nuts3, collapse = ", "), "\n")
  # Try alternate mapping
}

# Municipality → county → NUTS3
muni_crosswalk <- muni_lookup %>%
  mutate(county_code = substr(muni_code, 1, 2)) %>%
  left_join(county_nuts3, by = "county_code")

cat("Municipalities with NUTS3 mapping:", sum(!is.na(muni_crosswalk$nuts3)),
    "of", nrow(muni_crosswalk), "\n")

write_csv(muni_crosswalk, file.path(DATA_DIR, "muni_crosswalk.csv"))
write_csv(county_nuts3, file.path(DATA_DIR, "county_nuts3.csv"))

## ============================================================================
## 4. REFUGEE EXPOSURE: Foreign-born population by municipality
## Source: SCB BE0101 (Population statistics)
## ============================================================================

cat("\n=== 4. Fetching foreign-born data from Kolada API ===\n")

# Kolada has pre-aggregated municipality-level indicators:
#   N02926: Foreign-born share (%)
#   N02925: Foreign-born excl. EU/EFTA share (%)
#   N01807: International in-migrants (count)

fetch_kolada <- function(kpi_id, years, label) {
  cat("  Fetching", label, "...\n")
  all_out <- list()
  # Fetch one year at a time to avoid 5000-row API limit
  for (yr in years) {
    url <- paste0("https://api.kolada.se/v2/data/kpi/", kpi_id, "/year/", yr)
    resp <- GET(url)
    if (status_code(resp) != 200) {
      cat("    Year", yr, "error:", status_code(resp), "\n")
      next
    }
    raw <- content(resp, "text", encoding = "UTF-8")
    parsed <- fromJSON(raw)
    if (parsed$count == 0) next

    rows <- parsed$values
    out <- map_dfr(seq_len(nrow(rows)), function(r) {
      row <- rows[r, ]
      vals <- row$values[[1]]
      total <- vals[vals$gender == "T", ]
      if (nrow(total) > 0 && !is.na(total$value[1])) {
        tibble(
          muni_code = as.character(row$municipality),
          year = as.integer(row$period),
          value = total$value[1]
        )
      }
    })
    # Keep only 4-digit municipality codes (not 2-digit county aggregates)
    out <- out %>% filter(nchar(muni_code) == 4)
    all_out <- c(all_out, list(out))
    Sys.sleep(0.2)
  }
  result <- bind_rows(all_out)
  cat("   ", label, ":", nrow(result), "rows,",
      n_distinct(result$muni_code), "munis,",
      n_distinct(result$year), "years\n")
  result
}

kolada_years <- 2010:2022

# Foreign-born share
fb_share <- fetch_kolada("N02926", kolada_years, "foreign-born share")
fb_share <- fb_share %>% rename(foreign_share = value)

# Foreign-born excl EU/EFTA (better proxy for refugee-origin)
fb_noneu <- fetch_kolada("N02925", kolada_years, "foreign-born excl EU/EFTA")
fb_noneu <- fb_noneu %>% rename(foreign_noneu_share = value)

# International in-migrants (refugee flow proxy)
inmig <- fetch_kolada("N01807", kolada_years, "international in-migrants")
inmig <- inmig %>% rename(intl_inmigrants = value)

# Merge
kolada_df <- fb_share %>%
  left_join(fb_noneu, by = c("muni_code", "year")) %>%
  left_join(inmig, by = c("muni_code", "year"))

cat("Kolada panel:", n_distinct(kolada_df$muni_code), "munis x",
    n_distinct(kolada_df$year), "years\n")

# Sanity: Stockholm should have high foreign-born share
sthlm_fb <- kolada_df %>% filter(muni_code == "0180", year == 2018)
cat("Stockholm 2018 foreign-born share:", sthlm_fb$foreign_share, "%\n")

write_csv(kolada_df, file.path(DATA_DIR, "kolada_demographics.csv"))

# Also fetch population (for per-capita denominators)
pop_total <- fetch_kolada("N01951", kolada_years, "total population")
pop_total <- pop_total %>% rename(population = value)
write_csv(pop_total, file.path(DATA_DIR, "population.csv"))

## ============================================================================
## 5. INCOME DATA by municipality (2012-2022)
## Source: SCB HE0110
## ============================================================================

cat("\n=== 5. Fetching income data ===\n")

income_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  Income batch", ceiling(i / batch_size), "\n")

  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = as.list(batch))),
      list(code = "Kon", selection = list(filter = "item", values = list("1+2"))),
      list(code = "Alder", selection = list(filter = "item", values = list("20-64"))),
      list(code = "Inkomstklass", selection = list(filter = "item", values = list("TOT"))),
      list(code = "ContentsCode", selection = list(filter = "item",
           values = as.list(c("HE0110J7"))))
    ),
    response = list(format = "json-stat2")
  )

  result <- tryCatch(
    fetch_scb_tidy("HE/HE0110/HE0110A/SamForvInk1", query),
    error = function(e) {
      cat("  Income error:", e$message, "\n")
      NULL
    }
  )
  if (!is.null(result)) income_list <- c(income_list, list(result))
  Sys.sleep(0.3)
}

if (length(income_list) > 0) {
  income_raw <- bind_rows(income_list)
  income_df <- income_raw %>%
    rename(muni_code = Region, year = Tid, mean_income = value) %>%
    select(muni_code, year, mean_income) %>%
    mutate(year = as.integer(year))

  cat("Income panel:", n_distinct(income_df$muni_code), "munis x",
      n_distinct(income_df$year), "years\n")
  write_csv(income_df, file.path(DATA_DIR, "income.csv"))
}

## ============================================================================
## 6. EDUCATION DATA by municipality
## Source: SCB UF0506
## ============================================================================

cat("\n=== 6. Fetching education data ===\n")

# Try educational attainment table
edu_meta_resp <- GET("https://api.scb.se/OV0104/v1/doris/en/ssd/UF/UF0506/UF0506B/Utbildning")
if (status_code(edu_meta_resp) == 200) {
  edu_meta <- content(edu_meta_resp, "parsed")
  cat("Education table found\n")
  for (v in edu_meta$variables) {
    cat("  ", v$code, ":", v$text, "(", length(v$values), "values)\n")
  }

  edu_list <- list()
  for (i in seq(1, length(muni_codes), by = batch_size)) {
    batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
    cat("  Education batch", ceiling(i / batch_size), "\n")

    query <- list(
      query = list(
        list(code = "Region", selection = list(filter = "item", values = as.list(batch))),
        list(code = "Kon", selection = list(filter = "item", values = list("1+2"))),
        list(code = "Alder", selection = list(filter = "item", values = list("25-64"))),
        list(code = "UtbildningsNiva", selection = list(filter = "item",
             values = as.list(c("1", "2", "3", "4", "5", "6", "7")))),
        list(code = "Tid", selection = list(filter = "item",
             values = as.list(as.character(2012:2022))))
      ),
      response = list(format = "json-stat2")
    )

    result <- tryCatch(
      fetch_scb_tidy("UF/UF0506/UF0506B/Utbildning", query),
      error = function(e) {
        cat("  Education error:", e$message, "\n")
        NULL
      }
    )
    if (!is.null(result)) edu_list <- c(edu_list, list(result))
    Sys.sleep(0.3)
  }

  if (length(edu_list) > 0) {
    edu_raw <- bind_rows(edu_list)
    cat("Education data rows:", nrow(edu_raw), "\n")
    write_csv(edu_raw, file.path(DATA_DIR, "education_raw.csv"))
  }
} else {
  cat("Education table not found, skipping.\n")
}

## ============================================================================
## 7. TURNOUT DATA by municipality (for controls)
## Source: SCB ME0104T4
## ============================================================================

cat("\n=== 7. Fetching turnout data ===\n")

turnout_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  Turnout batch", ceiling(i / batch_size), "\n")

  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = as.list(batch))),
      list(code = "ContentsCode", selection = list(filter = "item",
           values = list("ME0104B8"))),
      list(code = "Tid", selection = list(filter = "item",
           values = as.list(c("2010", "2014", "2018", "2022"))))
    ),
    response = list(format = "json-stat2")
  )

  result <- tryCatch(
    fetch_scb_tidy("ME/ME0104/ME0104D/ME0104T4", query),
    error = function(e) {
      cat("  Turnout error:", e$message, "\n")
      NULL
    }
  )
  if (!is.null(result)) turnout_list <- c(turnout_list, list(result))
  Sys.sleep(0.3)
}

if (length(turnout_list) > 0) {
  turnout_raw <- bind_rows(turnout_list)
  turnout_df <- turnout_raw %>%
    rename(muni_code = Region, year = Tid, turnout = value) %>%
    select(muni_code, year, turnout) %>%
    mutate(year = as.integer(year))
  cat("Turnout panel:", n_distinct(turnout_df$muni_code), "munis x",
      n_distinct(turnout_df$year), "years\n")
  write_csv(turnout_df, file.path(DATA_DIR, "turnout.csv"))
}

## ============================================================================
## SUMMARY
## ============================================================================

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files saved to:", DATA_DIR, "\n")
cat("Files:\n")
for (f in list.files(DATA_DIR, pattern = "\\.csv$")) {
  sz <- file.size(file.path(DATA_DIR, f))
  cat(sprintf("  %-35s %s\n", f, format(sz, big.mark = ",")))
}
