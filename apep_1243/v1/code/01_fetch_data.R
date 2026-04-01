# =============================================================================
# 01_fetch_data.R — Fetch merger timing and demographic-balance outcomes
# apep_1243: Municipal Consolidation and Residential Sorting in Switzerland
# =============================================================================

source("00_packages.R")

cat("=== PART 1: Fetching commune merger data from AGVCH ===\n")

mutations_url <- paste0(
  "https://www.agvchapp.bfs.admin.ch/api/communes/mutations",
  "?includeTerritoryExchange=false",
  "&startPeriod=01-01-1990",
  "&endPeriod=31-12-2024"
)

resp <- GET(mutations_url, timeout(120))
stopifnot("AGVCH mutations API failed" = status_code(resp) == 200)
mutations <- fread(text = content(resp, as = "text", encoding = "UTF-8"))
mutations[, MutationDate := as.Date(MutationDate, format = "%d.%m.%Y")]
mutations[, merger_year := as.integer(format(MutationDate, "%Y"))]
cat("  Downloaded", nrow(mutations), "mutation records\n")

dissolved <- mutations[InitialStep == 29]
successors <- mutations[
  MutationNumber %in% dissolved$MutationNumber & TerminalStep %in% c(21, 26)
]

merger_xwalk <- merge(
  dissolved[, .(
    MutationNumber,
    dissolved_code = InitialCode,
    dissolved_name = InitialName,
    merger_year,
    MutationDate
  )],
  successors[, .(
    MutationNumber,
    successor_code = TerminalCode,
    successor_name = TerminalName
  )],
  by = "MutationNumber",
  allow.cartesian = TRUE
)
merger_xwalk <- unique(merger_xwalk)
cat("  Merger crosswalk rows:", nrow(merger_xwalk), "\n")

fwrite(mutations, file.path(DATA_DIR, "mutations_full.csv"))
fwrite(merger_xwalk, file.path(DATA_DIR, "merger_crosswalk.csv"))

cat("\n=== PART 2: Fetching municipality snapshot ===\n")

snap_url <- "https://www.agvchapp.bfs.admin.ch/api/communes/snapshot?date=01-01-2024"
snap_resp <- GET(snap_url, timeout(60))
stopifnot("Snapshot API failed" = status_code(snap_resp) == 200)
snapshot <- fread(text = content(snap_resp, as = "text", encoding = "UTF-8"))
cat("  Current municipalities:", nrow(snapshot), "\n")

fwrite(snapshot, file.path(DATA_DIR, "municipality_snapshot_2024.csv"))

cat("\n=== PART 3: Fetching population by citizenship from BFS PXWeb ===\n")

bfs_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102010000_104/px-x-0102010000_104.px"
meta_resp <- GET(bfs_url, timeout(60))
stopifnot("BFS metadata request failed" = status_code(meta_resp) == 200)
meta <- content(meta_resp, as = "parsed", type = "application/json")

vars <- meta$variables
geo_row <- which(vapply(vars, function(x) grepl("Gemeinde", x$code), logical(1)))
cit_row <- which(vapply(vars, function(x) grepl("Staatsange", x$code), logical(1)))
poptype_row <- which(vapply(vars, function(x) grepl("Bevölkerungstyp", x$code), logical(1)))
birthplace_row <- which(vapply(vars, function(x) grepl("Geburtsort", x$code), logical(1)))

geo_code <- vars[[geo_row]]$code
cit_code <- vars[[cit_row]]$code
poptype_code <- vars[[poptype_row]]$code
birthplace_code <- vars[[birthplace_row]]$code

all_geo <- unlist(vars[[geo_row]]$values)
all_geo_text <- unlist(vars[[geo_row]]$valueTexts)
commune_mask <- startsWith(all_geo_text, "......")
communes <- all_geo[commune_mask]
commune_lookup <- data.table(
  geo_code = communes,
  geo_text = all_geo_text[commune_mask]
)
commune_lookup[, bfs_nr := as.integer(sub("^......([0-9]{4}).*$", "\\1", geo_text))]
cat("  Commune codes:", length(communes), "\n")
fwrite(commune_lookup, file.path(DATA_DIR, "commune_lookup.csv"))

years <- as.character(2010:2024)
citizenship_vals <- c("-99999", "8100")
population_type <- "1"
birthplace_total <- "-99999"

all_rows <- vector("list", length(years))

for (i in seq_along(years)) {
  yr <- years[[i]]
  cat(sprintf("  Fetching %s (%d/%d)...", yr, i, length(years)))

  query_body <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = list(yr))),
      list(code = geo_code, selection = list(filter = "item", values = as.list(communes))),
      list(code = poptype_code, selection = list(filter = "item", values = list(population_type))),
      list(code = birthplace_code, selection = list(filter = "item", values = list(birthplace_total))),
      list(code = cit_code, selection = list(filter = "item", values = as.list(citizenship_vals)))
    ),
    response = list(format = "json")
  )

  yr_resp <- POST(
    bfs_url,
    body = toJSON(query_body, auto_unbox = TRUE),
    content_type_json(),
    timeout(180)
  )
  if (status_code(yr_resp) != 200) {
    stop("BFS data request failed for year ", yr, " with status ", status_code(yr_resp))
  }

  body <- fromJSON(content(yr_resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
  rows <- rbindlist(lapply(body$data, function(row) {
    val <- row$values[[1]]
    if (is.null(val) || val == "" || val == "...") {
      return(NULL)
    }
    data.table(
      year = as.integer(row$key[[1]]),
      geo_code = row$key[[2]],
      citizenship = row$key[[5]],
      value = as.numeric(val)
    )
  }), fill = TRUE)

  all_rows[[i]] <- rows
  cat(nrow(rows), "rows\n")
  Sys.sleep(0.2)
}

pop_raw <- rbindlist(all_rows, fill = TRUE)
stopifnot("Population data too sparse" = nrow(pop_raw) > 50000)

pop_raw <- merge(pop_raw, commune_lookup[, .(geo_code, bfs_nr)], by = "geo_code", all.x = TRUE)
stopifnot("Missing BFS municipality codes" = all(!is.na(pop_raw$bfs_nr)))

pop_raw[, cit_short := fifelse(
  citizenship == "-99999", "total",
  fifelse(citizenship == "8100", "swiss", "other")
)]

population_panel <- dcast(
  pop_raw[, .(bfs_nr, year, cit_short, value)],
  bfs_nr + year ~ cit_short,
  value.var = "value",
  fill = 0
)
population_panel[, foreign := total - swiss]
population_panel[, foreign_share := fifelse(total > 0, foreign / total, NA_real_)]

cat("  Total population rows:", nrow(pop_raw), "\n")
cat("  Municipality-years:", uniqueN(population_panel[, .(bfs_nr, year)]), "\n")

fwrite(population_panel, file.path(DATA_DIR, "population_panel.csv"))

cat("\nAll raw data fetched successfully.\n")
