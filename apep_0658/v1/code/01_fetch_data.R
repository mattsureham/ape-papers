## 01_fetch_data.R — Fetch all SSB data for Norway wealth tax analysis
## apep_0658

source("00_packages.R")

## ----- Helper: fetch from SSB JSON-stat2 API -----
## CRITICAL: JSON-stat uses row-major order (last dim varies fastest),
## but R's expand.grid has first dim varying fastest. We reverse the
## dimension order for expand.grid, then un-reverse the columns.
fetch_ssb <- function(table_id, query_body, description) {
  url <- paste0("https://data.ssb.no/api/v0/en/table/", table_id)
  cat(sprintf("Fetching SSB table %s (%s)...\n", table_id, description))

  resp <- POST(url, body = toJSON(query_body, auto_unbox = TRUE),
               content_type_json(), timeout(180))

  if (status_code(resp) != 200) {
    stop(sprintf("SSB table %s HTTP %d: %s",
                 table_id, status_code(resp), content(resp, "text")))
  }

  raw <- content(resp, "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)

  dim_ids <- parsed$id
  values <- parsed$value

  # Extract CODES for each dimension
  dim_codes <- lapply(dim_ids, function(did) {
    cats <- parsed$dimension[[did]]$category
    idx <- unlist(cats$index)
    code_names <- names(idx)
    code_names[order(idx)]
  })
  names(dim_codes) <- dim_ids

  # Build grid with REVERSED order (last dim = first in expand.grid = varies fastest)
  grid <- expand.grid(rev(dim_codes), stringsAsFactors = FALSE)
  # Reverse columns back to original dimension order
  grid <- grid[, rev(names(grid))]
  grid$value <- as.numeric(values)

  cat(sprintf("  -> %d rows\n", nrow(grid)))
  return(grid)
}

get_meta <- function(table_id) {
  url <- paste0("https://data.ssb.no/api/v0/en/table/", table_id)
  resp <- GET(url, timeout(30))
  if (status_code(resp) != 200) stop(sprintf("Metadata fetch failed for %s", table_id))
  fromJSON(content(resp, "text", encoding = "UTF-8"))
}

## ===========================================================
## 1. Wealth tax (Table 10333) — all regions, 2010-2024
## ===========================================================
meta1 <- get_meta("10333")
time_idx1 <- which(meta1$variables$time %in% TRUE)
yr1 <- meta1$variables$values[[time_idx1]]
yr1_sel <- yr1[yr1 >= "2010" & yr1 <= "2024"]

q1 <- list(
  query = list(
    list(code = "Region", selection = list(filter = "all", values = list("*"))),
    list(code = "ContentsCode", selection = list(filter = "all", values = list("*"))),
    list(code = "Tid", selection = list(filter = "item", values = yr1_sel))
  ),
  response = list(format = "json-stat2")
)
wealth_tax <- fetch_ssb("10333", q1, "wealth tax by municipality")
saveRDS(wealth_tax, "../data/wealth_tax_raw.rds")

## Quick validation: national average should be ~27700 in 2021
nat_check <- wealth_tax[wealth_tax$Region == "0" &
                        wealth_tax$ContentsCode == "GjsnittFormuesskatt" &
                        wealth_tax$Tid == "2021", "value"]
cat(sprintf("  Validation: national avg wealth tax 2021 = %s (expect ~27700)\n", nat_check))
if (abs(nat_check - 27700) > 1000) warning("National avg wealth tax doesn't match expected value!")

## ===========================================================
## 2. Secondary dwelling assessed values (Table 09838)
## ===========================================================
meta2 <- get_meta("09838")
time_idx2 <- which(meta2$variables$time %in% TRUE)
yr2 <- meta2$variables$values[[time_idx2]]
yr2_sel <- yr2[yr2 >= "2010" & yr2 <= "2024"]

q2 <- list(
  query = list(
    list(code = "Region", selection = list(filter = "all", values = list("*"))),
    list(code = "PrimarSekundar", selection = list(filter = "all", values = list("*"))),
    list(code = "Alder", selection = list(filter = "item", values = list("999A"))),
    list(code = "ContentsCode", selection = list(filter = "all", values = list("*"))),
    list(code = "Tid", selection = list(filter = "item", values = yr2_sel))
  ),
  response = list(format = "json-stat2")
)
dwellings <- fetch_ssb("09838", q2, "secondary dwelling values")
saveRDS(dwellings, "../data/dwellings_raw.rds")

## ===========================================================
## 3. Building permits (Table 05940)
## ===========================================================
meta3 <- get_meta("05940")
time_idx3 <- which(meta3$variables$time %in% TRUE)
yr3 <- meta3$variables$values[[time_idx3]]
yr3_sel <- yr3[yr3 >= "2010" & yr3 <= "2024"]

bldg_types <- c("111", "121", "131", "141", "142", "143")

q3 <- list(
  query = list(
    list(code = "Region", selection = list(filter = "all", values = list("*"))),
    list(code = "Byggeareal", selection = list(filter = "item", values = bldg_types)),
    list(code = "ContentsCode", selection = list(filter = "item",
         values = list("Igangsatte", "Fullforte"))),
    list(code = "Tid", selection = list(filter = "item", values = yr3_sel))
  ),
  response = list(format = "json-stat2")
)
permits <- fetch_ssb("05940", q3, "building permits (key types)")
saveRDS(permits, "../data/permits_raw.rds")

## ===========================================================
## 4. New enterprises (Table 14012)
## ===========================================================
meta4 <- get_meta("14012")
time_idx4 <- which(meta4$variables$time %in% TRUE)
yr4 <- meta4$variables$values[[time_idx4]]
yr4_sel <- yr4[yr4 >= "2010" & yr4 <= "2024"]

q4 <- list(
  query = list(
    list(code = "Region", selection = list(filter = "all", values = list("*"))),
    list(code = "EtableringType", selection = list(filter = "item", values = list("0"))),
    list(code = "Storleik", selection = list(filter = "item", values = list("l00"))),
    list(code = "ContentsCode", selection = list(filter = "item", values = list("Foretak"))),
    list(code = "Tid", selection = list(filter = "item", values = yr4_sel))
  ),
  response = list(format = "json-stat2")
)
enterprises <- fetch_ssb("14012", q4, "new enterprises (total)")
saveRDS(enterprises, "../data/enterprises_raw.rds")

## ===========================================================
## 5. Migration (Table 05426)
## ===========================================================
meta5 <- get_meta("05426")
time_idx5 <- which(meta5$variables$time %in% TRUE)
yr5 <- meta5$variables$values[[time_idx5]]
yr5_sel <- yr5[yr5 >= "2010" & yr5 <= "2024"]

q5 <- list(
  query = list(
    list(code = "Region", selection = list(filter = "all", values = list("*"))),
    list(code = "ContentsCode", selection = list(filter = "all", values = list("*"))),
    list(code = "Tid", selection = list(filter = "item", values = yr5_sel))
  ),
  response = list(format = "json-stat2")
)
migration <- fetch_ssb("05426", q5, "migration by municipality")
saveRDS(migration, "../data/migration_raw.rds")

## ----- Verify -----
data_files <- c("wealth_tax_raw.rds", "dwellings_raw.rds", "permits_raw.rds",
                "enterprises_raw.rds", "migration_raw.rds")
for (f in data_files) {
  fp <- file.path("../data", f)
  if (!file.exists(fp)) stop(sprintf("MISSING: %s", fp))
  cat(sprintf("  OK %s (%s bytes)\n", f, format(file.size(fp), big.mark = ",")))
}

cat("\n=== All data fetched successfully ===\n")
