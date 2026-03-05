## 01_fetch_data.R — Fetch building heating data and treatment timing
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption
##
## Data sources:
##   1. BFS Asset 1642414: Buildings by heating energy source × canton (2009-2015)
##   2. BFS Asset 23524566: Building overview by canton (2021)
##   3. BFS Asset 27585122: Building overview by canton (2022)
##   4. BFS Asset 32329800: Living surface by heating system × canton (2021-2023)
##   5. MuKEn 2014 adoption dates (hand-coded from ENDK/cantonal sources)
##   6. BFS PXWeb: Canton population (for per-capita normalization)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## 1. MuKEn 2014 ADOPTION TIMELINE (hand-coded from ENDK, cantonal sources)
## ============================================================================
## Sources: ENDK Umsetzungsstand Sept 2023, energie-experten.ch, ofri.ch,
##          cantonal energy office announcements, University of Lucerne WP6

muken_adoption <- data.table(
  canton = c("AG", "AI", "AR", "BE", "BL", "BS", "FR", "GE", "GL", "GR",
             "JU", "LU", "NE", "NW", "OW", "SG", "SH", "SZ", "SO", "TG",
             "TI", "UR", "VD", "VS", "ZG", "ZH"),
  canton_name = c("Aargau", "Appenzell Innerrhoden", "Appenzell Ausserrhoden",
                  "Bern", "Basel-Landschaft", "Basel-Stadt", "Fribourg",
                  "Genève", "Glarus", "Graubünden", "Jura", "Luzern",
                  "Neuchâtel", "Nidwalden", "Obwalden", "St. Gallen",
                  "Schaffhausen", "Schwyz", "Solothurn", "Thurgau",
                  "Ticino", "Uri", "Vaud", "Valais", "Zug", "Zürich"),
  adoption_year = c(2020L, 2020L, 2022L, 2023L, 2018L, 2017L, 2020L, 2023L,
                    2020L, 2020L, 2019L, 2019L, 2020L, 2020L, 2018L, 2020L,
                    2020L, 2020L, NA_integer_, 2020L, 2024L, 2021L, 2018L,
                    2022L, 2024L, 2022L),
  canton_nr = c(19L, 16L, 15L, 2L, 13L, 12L, 10L, 25L, 8L, 18L,
                26L, 3L, 24L, 7L, 6L, 17L, 14L, 5L, 11L, 20L,
                21L, 4L, 22L, 23L, 9L, 1L)
)

## SO (Solothurn): rejected MuKEn 2014 in referendum, never adopted
muken_adoption[canton == "SO", adopted := FALSE]
muken_adoption[canton != "SO", adopted := TRUE]

fwrite(muken_adoption, file.path(data_dir, "muken_adoption.csv"))
cat("MuKEn adoption timeline saved:", nrow(muken_adoption), "cantons\n")

## ============================================================================
## 2. DOWNLOAD BFS DATA FILES
## ============================================================================

download_bfs_asset <- function(asset_id, filename) {
  filepath <- file.path(data_dir, filename)
  if (file.exists(filepath) && file.size(filepath) > 1000) {
    cat("  Already downloaded:", filename, "\n")
    return(filepath)
  }
  url <- paste0("https://www.bfs.admin.ch/bfsstatic/dam/assets/", asset_id, "/master")
  r <- GET(url, config(followlocation = TRUE))
  if (status_code(r) != 200) {
    stop("Failed to download BFS asset ", asset_id, ": HTTP ", status_code(r))
  }
  writeBin(content(r, as = "raw"), filepath)
  cat("  Downloaded:", filename, "(", file.size(filepath), "bytes)\n")
  return(filepath)
}

cat("\nDownloading BFS data files...\n")
f_2009_2015 <- download_bfs_asset("1642414", "bfs_heating_2009_2015.xls")
f_2021_overview <- download_bfs_asset("23524566", "bfs_overview_2021.xlsx")
f_2022_overview <- download_bfs_asset("27585122", "bfs_overview_2022.xlsx")
f_surface <- download_bfs_asset("32329800", "bfs_surface_heating_2021_2023.xlsx")

## ============================================================================
## 3. PARSE 2009-2015 DATA (multi-year Excel with canton-level building counts)
## ============================================================================
## Structure: 7 sheets (2009-2015), each with cantons in rows
## Columns: 1=region, 2=Total, 10=Heizöl, 11=Kohle, 12=Gas, 13=Elektrizität,
##           14=Holz, 15=Wärmepumpe, 16=Sonnenkollektor, 17=Fernwärme, 18=Andere

cat("\nParsing 2009-2015 heating data...\n")

## Map canton names (as they appear in the Excel) to canton abbreviations
canton_name_map <- c(
  "Zürich" = "ZH", "Bern" = "BE", "Luzern" = "LU", "Uri" = "UR",
  "Schwyz" = "SZ", "Obwalden" = "OW", "Nidwalden" = "NW", "Glarus" = "GL",
  "Zug" = "ZG", "Fribourg" = "FR", "Solothurn" = "SO",
  "Basel-Stadt" = "BS", "Basel-Landschaft" = "BL", "Schaffhausen" = "SH",
  "Appenzell Ausserrhoden" = "AR", "Appenzell Innerrhoden" = "AI",
  "St. Gallen" = "SG", "Graubünden" = "GR", "Aargau" = "AG",
  "Thurgau" = "TG", "Ticino" = "TI", "Vaud" = "VD",
  "Valais" = "VS", "Neuchâtel" = "NE", "Genève" = "GE", "Jura" = "JU",
  ## Also handle alternative spellings
  "Fribourg / Freiburg" = "FR", "Graubünden / Grigioni / Grischun" = "GR",
  "Bern / Berne" = "BE", "Valais / Wallis" = "VS"
)

parse_2009_2015 <- function(filepath) {
  years <- as.character(2009:2015)
  all_data <- list()

  for (yr in years) {
    d <- read_excel(filepath, sheet = yr, col_names = FALSE)
    result <- data.table()

    for (i in 14:nrow(d)) {
      region <- trimws(as.character(d[[1]][i]))
      if (is.na(region) || nchar(region) == 0) next
      if (region %in% names(canton_name_map)) {
        canton_abbr <- canton_name_map[region]
        total <- as.numeric(d[[2]][i])
        oil <- as.numeric(d[[10]][i])
        coal <- as.numeric(d[[11]][i])
        gas <- as.numeric(d[[12]][i])
        electricity <- as.numeric(d[[13]][i])
        wood <- as.numeric(d[[14]][i])
        heat_pump <- as.numeric(d[[15]][i])
        solar <- as.numeric(d[[16]][i])
        district <- as.numeric(d[[17]][i])
        other <- as.numeric(d[[18]][i])

        result <- rbind(result, data.table(
          year = as.integer(yr),
          canton = canton_abbr,
          total_buildings = total,
          n_oil = oil, n_coal = coal, n_gas = gas,
          n_electricity = electricity, n_wood = wood,
          n_heat_pump = heat_pump, n_solar = solar,
          n_district_heating = district, n_other = other
        ))
      }
    }
    all_data[[yr]] <- result
    cat("  ", yr, ":", nrow(result), "cantons\n")
  }
  rbindlist(all_data)
}

panel_2009_2015 <- parse_2009_2015(f_2009_2015)

## ============================================================================
## 4. PARSE 2021-2022 OVERVIEW FILES (per-canton sheets with building counts)
## ============================================================================
## Structure: 27 sheets (CH + 26 cantons), energy section at ~row 31
## Energy source labels: Energiequellen für Wärmepumpen, Gas, Heizöl, Holz,
##                       Elektrizität, Fernwärme, Solarthermie, Andere

cat("\nParsing 2021-2022 overview files...\n")

## Map sheet names to canton abbreviations
sheet_to_canton <- c(
  "01_ZH" = "ZH", "02_BE" = "BE", "03_LU" = "LU", "04_UR" = "UR",
  "05_SZ" = "SZ", "06_OW" = "OW", "07_NW" = "NW", "08_GL" = "GL",
  "09_ZG" = "ZG", "10_FR" = "FR", "11_SO" = "SO", "12_BS" = "BS",
  "13_BL" = "BL", "14_SH" = "SH", "15_AR" = "AR", "16_AI" = "AI",
  "17_SG" = "SG", "18_GR" = "GR", "19_AG" = "AG", "20_TG" = "TG",
  "21_TI" = "TI", "22_VD" = "VD", "23_VS" = "VS", "24_NE" = "NE",
  "25_GE" = "GE", "26_JU" = "JU"
)

parse_overview <- function(filepath, year) {
  sheets <- excel_sheets(filepath)
  canton_sheets <- sheets[sheets != "CH"]
  result <- data.table()

  for (s in canton_sheets) {
    canton_abbr <- sheet_to_canton[s]
    if (is.na(canton_abbr)) next

    d <- read_excel(filepath, sheet = s, col_names = FALSE, n_max = 55)

    ## Find the row with "Energiequelle der Heizung" or similar
    energy_start <- NA
    for (i in 1:nrow(d)) {
      val <- as.character(d[[1]][i])
      if (!is.na(val) && grepl("Energiequelle|Energieträger|Source d", val, ignore.case = TRUE)) {
        energy_start <- i
        break
      }
    }

    if (is.na(energy_start)) {
      cat("  WARNING: No energy data in sheet", s, "\n")
      next
    }

    ## Extract building counts from the energy section
    ## Each row has: label | total | by_period_1 | by_period_2 | ...
    heat_pump <- gas <- oil <- wood <- electricity <- district <- solar <- other_e <- 0
    total_buildings <- as.numeric(d[[2]][6])  ## Row 6 is typically "Total"

    for (i in (energy_start + 1):(energy_start + 10)) {
      if (i > nrow(d)) break
      label <- tolower(as.character(d[[1]][i]))
      val <- as.numeric(d[[2]][i])
      if (is.na(label) || is.na(val)) next

      if (grepl("wärmepump|pompe", label)) heat_pump <- val
      else if (grepl("^gas$", label)) gas <- val
      else if (grepl("heizöl|mazout", label)) oil <- val
      else if (grepl("holz|bois", label)) wood <- val
      else if (grepl("elektri|élect", label)) electricity <- val
      else if (grepl("fernwärme|chaleur", label)) district <- val
      else if (grepl("solar|solaire", label)) solar <- val
      else if (grepl("andere|autre", label)) other_e <- val
    }

    result <- rbind(result, data.table(
      year = year,
      canton = canton_abbr,
      total_buildings = total_buildings,
      n_oil = oil, n_coal = 0, n_gas = gas,
      n_electricity = electricity, n_wood = wood,
      n_heat_pump = heat_pump, n_solar = solar,
      n_district_heating = district, n_other = other_e
    ))
  }

  cat("  ", year, ":", nrow(result), "cantons\n")
  result
}

panel_2021 <- parse_overview(f_2021_overview, 2021L)
panel_2022 <- parse_overview(f_2022_overview, 2022L)

## ============================================================================
## 5. PARSE 2021-2023 SURFACE AREA DATA (heating system shares by canton)
## ============================================================================
## Structure: Sheets Cantons_2023, Cantons_2022, Cantons_2021
## Columns: region, Total(m2), Pompe à chaleur(%), Solaire(%), Chaudière(%),
##          Poêle(%), Electrique(%), Echangeur(%), Autres(%), Aucun(%)

cat("\nParsing 2021-2023 surface area data...\n")

## Map French canton names to abbreviations
canton_name_fr <- c(
  "Zurich" = "ZH", "Berne" = "BE", "Lucerne" = "LU", "Uri" = "UR",
  "Schwyz" = "SZ", "Obwald" = "OW", "Nidwald" = "NW", "Glaris" = "GL",
  "Zoug" = "ZG", "Fribourg" = "FR", "Soleure" = "SO",
  "Bâle-Ville" = "BS", "Bâle-Campagne" = "BL", "Schaffhouse" = "SH",
  "Appenzell Rh.-Ext." = "AR", "Appenzell Rh.-Int." = "AI",
  "Saint-Gall" = "SG", "Grisons" = "GR", "Argovie" = "AG",
  "Thurgovie" = "TG", "Tessin" = "TI", "Vaud" = "VD",
  "Valais" = "VS", "Neuchâtel" = "NE", "Genève" = "GE",
  ## Handle footnote markers
  "Genève2)" = "GE",
  "Jura" = "JU"
)

parse_surface <- function(filepath) {
  result <- data.table()

  for (yr in c(2021, 2022, 2023)) {
    sheet_name <- paste0("Cantons_", yr)
    d <- read_excel(filepath, sheet = sheet_name, col_names = FALSE, n_max = 40)

    for (i in 8:35) {
      if (i > nrow(d)) break
      region <- trimws(as.character(d[[1]][i]))
      if (is.na(region) || nchar(region) == 0) next
      if (region == "Suisse" || region == "Schweiz") next

      canton_abbr <- canton_name_fr[region]
      if (is.na(canton_abbr)) next

      total_surface <- as.numeric(d[[2]][i])
      pct_heat_pump <- as.numeric(d[[3]][i])
      pct_solar <- as.numeric(d[[4]][i])
      pct_boiler <- as.numeric(d[[5]][i])
      pct_stove <- as.numeric(d[[6]][i])
      pct_electric <- as.numeric(d[[7]][i])
      pct_district <- as.numeric(d[[8]][i])
      pct_other <- as.numeric(d[[9]][i])

      result <- rbind(result, data.table(
        year = as.integer(yr),
        canton = canton_abbr,
        total_surface_m2 = total_surface,
        pct_heat_pump_surface = pct_heat_pump,
        pct_solar_surface = pct_solar,
        pct_boiler_surface = pct_boiler,
        pct_stove_surface = pct_stove,
        pct_electric_surface = pct_electric,
        pct_district_surface = pct_district,
        pct_other_surface = pct_other
      ))
    }
    cat("  Surface", yr, ":", sum(result$year == yr), "cantons\n")
  }
  result
}

panel_surface <- parse_surface(f_surface)

## ============================================================================
## 6. MERGE INTO UNIFIED PANEL
## ============================================================================

cat("\nBuilding unified panel...\n")

## Combine building count data (2009-2015 + 2021 + 2022)
panel_counts <- rbindlist(list(panel_2009_2015, panel_2021, panel_2022),
                          use.names = TRUE, fill = TRUE)

## Compute shares
panel_counts[, `:=`(
  share_heat_pump = n_heat_pump / total_buildings,
  share_oil = n_oil / total_buildings,
  share_gas = n_gas / total_buildings,
  share_wood = n_wood / total_buildings,
  share_electricity = n_electricity / total_buildings,
  share_district = n_district_heating / total_buildings,
  share_fossil = (n_oil + n_gas + n_coal) / total_buildings
)]

## Merge treatment timing
panel_counts <- merge(panel_counts, muken_adoption[, .(canton, adoption_year, adopted)],
                      by = "canton", all.x = TRUE)

## Create treatment indicator
panel_counts[, treated := fifelse(!is.na(adoption_year) & year >= adoption_year, 1L, 0L)]
panel_counts[, years_since_adoption := fifelse(!is.na(adoption_year),
                                                as.integer(year - adoption_year),
                                                NA_integer_)]

## Merge surface data for 2021-2023
panel_full <- merge(panel_counts, panel_surface,
                    by = c("year", "canton"), all = TRUE)

## Order
setorder(panel_full, canton, year)

## ============================================================================
## 7. DOWNLOAD POPULATION DATA FOR PER-CAPITA NORMALIZATION
## ============================================================================

cat("\nFetching population data...\n")

## Canton population from BFS PXWeb
pop_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102010000_101/px-x-0102010000_101.px"
pop_meta <- GET(pop_url)

if (status_code(pop_meta) == 200) {
  meta <- content(pop_meta, as = "parsed")

  ## Build query for total population by canton and year
  canton_vals <- sapply(meta$variables[[1]]$values, identity)
  year_vals <- sapply(meta$variables[[length(meta$variables)]]$values, identity)

  ## Filter to relevant years (2009-2023) and canton-level only (codes 1-26)
  year_vals_keep <- year_vals[year_vals %in% as.character(2009:2023)]
  canton_vals_keep <- canton_vals[grepl("^[0-9]{1,2}$", canton_vals) &
                                   as.integer(canton_vals) >= 1 &
                                   as.integer(canton_vals) <= 26]

  if (length(year_vals_keep) > 0 && length(canton_vals_keep) > 0) {
    ## Query for total population (first value of other dimensions)
    query_body <- list(
      query = list(
        list(code = meta$variables[[1]]$code,
             selection = list(filter = "item", values = as.list(canton_vals_keep))),
        list(code = meta$variables[[length(meta$variables)]]$code,
             selection = list(filter = "item", values = as.list(year_vals_keep)))
      ),
      response = list(format = "json")
    )

    pop_r <- POST(pop_url, body = toJSON(query_body, auto_unbox = TRUE),
                  content_type_json())

    if (status_code(pop_r) == 200) {
      pop_raw <- fromJSON(content(pop_r, as = "text", encoding = "UTF-8"))
      pop_dt <- data.table(
        canton_nr = as.integer(sapply(pop_raw$data, function(x) x$key[1])),
        year = as.integer(sapply(pop_raw$data, function(x) x$key[length(x$key)])),
        population = as.numeric(sapply(pop_raw$data, function(x) x$values[1]))
      )
      ## Map canton_nr to canton abbreviation
      pop_dt <- merge(pop_dt, muken_adoption[, .(canton, canton_nr)],
                      by = "canton_nr", all.x = TRUE)
      pop_dt[, canton_nr := NULL]
      cat("  Population data:", nrow(pop_dt), "rows\n")

      ## Merge population into panel
      panel_full <- merge(panel_full, pop_dt, by = c("canton", "year"), all.x = TRUE)
    } else {
      cat("  WARNING: Population query failed, skipping per-capita normalization\n")
    }
  }
} else {
  cat("  WARNING: Could not access population table metadata\n")
}

## ============================================================================
## 8. SAVE FINAL PANEL
## ============================================================================

fwrite(panel_full, file.path(data_dir, "panel_canton_year.csv"))
fwrite(panel_surface, file.path(data_dir, "panel_surface.csv"))

cat("\n=== DATA VALIDATION ===\n")
cat("Panel rows:", nrow(panel_full), "\n")
cat("Cantons:", uniqueN(panel_full$canton), "\n")
cat("Years:", paste(sort(unique(panel_full$year)), collapse = ", "), "\n")
cat("Years with building counts:", paste(sort(unique(panel_counts$year)), collapse = ", "), "\n")
cat("Years with surface data:", paste(sort(unique(panel_surface$year)), collapse = ", "), "\n")
cat("\nTreatment summary (building counts panel):\n")
cat("  Pre-treatment obs:", sum(panel_counts$treated == 0, na.rm = TRUE), "\n")
cat("  Post-treatment obs:", sum(panel_counts$treated == 1, na.rm = TRUE), "\n")
cat("  Never-treated (SO):", sum(is.na(panel_counts$adoption_year)), "\n")

## Validate key variables
stopifnot("Expected 26 cantons" = uniqueN(panel_full$canton) == 26)
stopifnot("Expected >= 9 years" = uniqueN(panel_full$year) >= 9)
stopifnot("Heat pump share should be between 0 and 1" =
            all(panel_counts$share_heat_pump >= 0 & panel_counts$share_heat_pump <= 1,
                na.rm = TRUE))

cat("\nData fetching and panel construction complete.\n")
