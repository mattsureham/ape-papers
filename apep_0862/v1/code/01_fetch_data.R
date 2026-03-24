## 01_fetch_data.R — Fetch employment data from BFS PXWeb and ZIVI statistics
## apep_0862: Civilian Service Expansion and Healthcare Employment in Switzerland
##
## Data sources:
## 1. BFS BESTA (Beschäftigungsstatistik): Quarterly employment by NOGA sector
##    Cube: px-x-0602000000_101 (national, 1991Q3-2025Q4)
## 2. BFS STATENT: Annual employment by canton x NOGA sector (2011-2023)
##    Cube: px-x-0602010000_101
## 3. Zivildienst (ZIVI) statistics: admissions and service days (manual entry from official reports)

source("00_packages.R")

# ==============================================================================
# 1. BFS BESTA — National Quarterly Employment by NOGA Sector
# ==============================================================================
cat("=== Fetching BFS BESTA quarterly employment data ===\n")

besta_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602000000_101/px-x-0602000000_101.px"

# Target NOGA sectors:
# Treatment: 86 (Health), 87 (Residential care), 88 (Social work)
# Controls: 85 (Education), 55-56 (Gastgewerbe), 84 (Public admin),
#           69-75 (Professional services), 77-82 (Business services),
#           90-93 (Arts/recreation), 94-96 (Other services),
#           47 (Retail), 56 (Gastro), 68 (Real estate)
# Also get aggregates for context

target_sectors <- c(
  "86-88",  # Health & social (aggregate)
  "86",     # Health
  "87",     # Residential care
  "88",     # Social work (without residential)
  "85",     # Education
  "55-56",  # Hospitality
  "84",     # Public admin
  "69-75",  # Professional services
  "77-82",  # Business services
  "90-93",  # Arts/recreation
  "94-96",  # Other services
  "47",     # Retail
  "68",     # Real estate
  "45-96",  # Total sector III
  "5-96"    # Grand total
)

# Generate quarter values: 2003Q1 to 2016Q4
quarters <- c()
for (yr in 2003:2016) {
  for (q in 1:4) {
    quarters <- c(quarters, paste0(yr, "Q", q))
  }
}

# Build PXWeb query
query_body <- list(
  query = list(
    list(
      code = "Wirtschaftsabteilung",
      selection = list(filter = "item", values = as.list(target_sectors))
    ),
    list(
      code = "Beschäftigungsgrad",
      selection = list(filter = "item", values = list("TOT", "4"))
    ),
    list(
      code = "Geschlecht",
      selection = list(filter = "item", values = list("TOT"))
    ),
    list(
      code = "Quartal",
      selection = list(filter = "item", values = as.list(quarters))
    )
  ),
  response = list(format = "json-stat2")
)

cat("Sending query (15 sectors x 2 measures x 56 quarters)...\n")
resp <- POST(
  besta_url,
  body = toJSON(query_body, auto_unbox = TRUE),
  content_type_json(),
  timeout(120)
)

stopifnot("BFS BESTA query failed" = status_code(resp) == 200)
cat("Success! Parsing JSON-stat2 response...\n")

raw_json <- content(resp, as = "text", encoding = "UTF-8")
jstat <- fromJSON(raw_json)

# Parse JSON-stat2 format
# Dimensions: sector x employment_type x gender x quarter
dims <- jstat$dimension
sizes <- jstat$size
values <- jstat$value

# Build index vectors
dim_names <- names(dims)
cat("Dimensions:", paste(dim_names, collapse = " x "), "\n")
cat("Sizes:", paste(sizes, collapse = " x "), "\n")

# Extract category labels
get_labels <- function(dim_obj) {
  idx <- dim_obj$category$index
  lab <- dim_obj$category$label
  # Handle both named vector and list formats
  if (is.list(idx)) {
    codes <- names(idx)
    order <- unlist(idx)
    labels <- unlist(lab[codes])
  } else {
    codes <- names(idx)
    order <- unlist(idx)
    labels <- unlist(lab[codes])
  }
  tibble(code = codes, label = labels, pos = order) |> arrange(pos)
}

sector_labs <- get_labels(dims[[dim_names[1]]])
emptype_labs <- get_labels(dims[[dim_names[2]]])
gender_labs <- get_labels(dims[[dim_names[3]]])
quarter_labs <- get_labels(dims[[dim_names[4]]])

cat(sprintf("Sectors: %d, Employment types: %d, Genders: %d, Quarters: %d\n",
            nrow(sector_labs), nrow(emptype_labs), nrow(gender_labs), nrow(quarter_labs)))

# Expand grid and attach values
grid <- expand_grid(
  sector = sector_labs$code,
  emptype = emptype_labs$code,
  gender = gender_labs$code,
  quarter = quarter_labs$code
)

# Values are in row-major order matching the dimension order
stopifnot("Grid size mismatch" = nrow(grid) == length(values))
grid$employment <- unlist(values)

# Add labels
besta_panel <- grid |>
  left_join(sector_labs |> rename(sector = code, sector_label = label) |> select(-pos), by = "sector") |>
  left_join(emptype_labs |> rename(emptype = code, emptype_label = label) |> select(-pos), by = "emptype") |>
  left_join(quarter_labs |> rename(quarter = code, quarter_label = label) |> select(-pos), by = "quarter") |>
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    qtr = as.integer(substr(quarter, 6, 6)),
    # Time index (quarters since 2003Q1)
    time_idx = (year - 2003) * 4 + qtr,
    # Treatment indicator
    treated = sector %in% c("86", "87", "88"),
    # Post-reform (April 1, 2009 = 2009Q2)
    post = (year > 2009) | (year == 2009 & qtr >= 2),
    # Dose: partial reversal after 2011Q1
    partial_reversal = year >= 2011
  )

cat(sprintf("\nBESTA panel: %d rows\n", nrow(besta_panel)))
cat("Sectors in panel:\n")
besta_panel |> distinct(sector, sector_label, treated) |> print(n = 20)

# Check for missing values
n_miss <- sum(is.na(besta_panel$employment))
cat(sprintf("Missing values: %d (%.1f%%)\n", n_miss, 100 * n_miss / nrow(besta_panel)))

write_csv(besta_panel, "../data/besta_quarterly.csv")
cat("BESTA quarterly panel saved to data/besta_quarterly.csv\n")

# ==============================================================================
# 2. BFS STATENT — Annual Canton x NOGA Sector Employment (2011-2023)
# ==============================================================================
cat("\n=== Fetching BFS STATENT annual canton x sector data ===\n")

statent_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_101/px-x-0602010000_101.px"

# Target NOGA sectors (using 2-digit codes)
statent_sectors <- c(
  "86", "87", "88",   # Treatment
  "85", "84",          # Controls: education, public admin
  "55", "56",          # Hospitality
  "47",                # Retail
  "69", "70", "71", "72",  # Professional services
  "78",                # Temporary employment
  "999"                # Total
)

# All cantons (1-26) plus Switzerland total (999)
cantons <- as.character(c(999, 1:26))

# All years
years_statent <- as.character(2011:2023)

query_statent <- list(
  query = list(
    list(
      code = "Jahr",
      selection = list(filter = "item", values = as.list(years_statent))
    ),
    list(
      code = "Kanton",
      selection = list(filter = "item", values = as.list(cantons))
    ),
    list(
      code = "Wirtschaftsabteilung",
      selection = list(filter = "item", values = as.list(statent_sectors))
    ),
    list(
      code = "Beobachtungseinheit",
      selection = list(filter = "item", values = list("2", "5"))  # Beschäftigte, VZÄ
    )
  ),
  response = list(format = "json-stat2")
)

cat("Sending STATENT query...\n")
resp2 <- POST(
  statent_url,
  body = toJSON(query_statent, auto_unbox = TRUE),
  content_type_json(),
  timeout(120)
)

stopifnot("BFS STATENT query failed" = status_code(resp2) == 200)
cat("Success! Parsing...\n")

raw2 <- content(resp2, as = "text", encoding = "UTF-8")
jstat2 <- fromJSON(raw2)

dims2 <- jstat2$dimension
sizes2 <- jstat2$size
values2 <- jstat2$value
dim_names2 <- names(dims2)

cat("Dimensions:", paste(dim_names2, collapse = " x "), "\n")
cat("Sizes:", paste(sizes2, collapse = " x "), "\n")

year_labs2 <- get_labels(dims2[[dim_names2[1]]])
canton_labs2 <- get_labels(dims2[[dim_names2[2]]])
sector_labs2 <- get_labels(dims2[[dim_names2[3]]])
measure_labs2 <- get_labels(dims2[[dim_names2[4]]])

grid2 <- expand_grid(
  year = year_labs2$code,
  canton = canton_labs2$code,
  sector = sector_labs2$code,
  measure = measure_labs2$code
)

stopifnot("STATENT grid mismatch" = nrow(grid2) == length(values2))
grid2$value <- unlist(values2)

statent_panel <- grid2 |>
  left_join(canton_labs2 |> rename(canton = code, canton_label = label) |> select(-pos), by = "canton") |>
  left_join(sector_labs2 |> rename(sector = code, sector_label = label) |> select(-pos), by = "sector") |>
  left_join(measure_labs2 |> rename(measure = code, measure_label = label) |> select(-pos), by = "measure") |>
  mutate(
    year = as.integer(year),
    treated = sector %in% c("86", "87", "88")
  )

cat(sprintf("\nSTATENT panel: %d rows\n", nrow(statent_panel)))

write_csv(statent_panel, "../data/statent_annual.csv")
cat("STATENT annual panel saved to data/statent_annual.csv\n")

# ==============================================================================
# 3. ZIVI Administrative Statistics (from official annual reports)
# ==============================================================================
cat("\n=== Creating ZIVI statistics ===\n")

# Admissions time series (manually verified from ZIVI Tätigkeitsbericht)
zivi_admissions <- tribble(
  ~year, ~admissions,
  2000L,    544L,
  2001L,    685L,
  2002L,    756L,
  2003L,    871L,
  2004L,   1011L,
  2005L,   1148L,
  2006L,   1262L,
  2007L,   1404L,
  2008L,   1632L,
  2009L,   6720L,   # Tatbeweis reform (April 1, 2009)
  2010L,   6824L,
  2011L,   5826L,   # Partial tightening
  2012L,   5755L,
  2013L,   5971L,
  2014L,   5977L,
  2015L,   6059L,
  2016L,   6216L
)

# Total service days (from annual reports)
zivi_days <- tribble(
  ~year, ~total_days,
  2005L,  396959L,
  2006L,  428337L,
  2007L,  469881L,
  2008L,  532601L,
  2009L,  598482L,
  2010L,  878088L,
  2011L, 1140858L,
  2012L, 1375293L,
  2013L, 1553019L,
  2014L, 1645200L,
  2015L, 1724098L,
  2016L, 1768437L
)

# Sector shares of service days (stable over time, from 2015/2016 reports)
# Health + social = ~66.4% of all days
zivi_sector <- tribble(
  ~sector_label, ~share_pct,
  "Social services",          51.6,
  "Healthcare",               14.8,
  "Environmental protection", 10.8,
  "Agriculture",               7.5,
  "Cultural heritage",         3.1,
  "Forestry",                  2.8,
  "Development cooperation",   2.6,
  "Civil protection",          1.5,
  "Education",                 1.2,
  "Other",                     4.1
)

# Compute estimated health/social service days by year
zivi_combined <- zivi_days |>
  mutate(
    health_social_days = round(total_days * 0.664),
    # Convert to approximate FTE (assuming 220 working days/year)
    health_social_fte = round(health_social_days / 220)
  )

write_csv(zivi_admissions, "../data/zivi_admissions.csv")
write_csv(zivi_days, "../data/zivi_service_days.csv")
write_csv(zivi_sector, "../data/zivi_sector_shares.csv")
write_csv(zivi_combined, "../data/zivi_combined.csv")

cat("ZIVI data saved:\n")
cat(sprintf("  Admissions jump: %d (2008) -> %d (2009) = +%.0f%%\n",
            1632, 6720, (6720/1632 - 1) * 100))
cat(sprintf("  Service days: %d (2008) -> %d (2010) -> %d (2015)\n",
            532601, 878088, 1724098))
cat(sprintf("  Health+social share: %.1f%%\n", 66.4))
cat(sprintf("  Estimated FTE in health/social: %d (2008) -> %d (2015)\n",
            round(532601 * 0.664 / 220), round(1724098 * 0.664 / 220)))

# ==============================================================================
# 4. Validation
# ==============================================================================
cat("\n=== Data validation ===\n")

# Check BESTA FTE data for health sectors
besta_fte <- besta_panel |>
  filter(emptype == "4", gender == "TOT", sector %in% c("86", "87", "88")) |>
  group_by(quarter) |>
  summarise(total_fte = sum(employment, na.rm = TRUE), .groups = "drop") |>
  arrange(quarter)

cat("\nTotal FTE in NOGA 86-88 (selected quarters):\n")
besta_fte |> filter(quarter %in% c("2003Q1", "2006Q1", "2008Q4", "2009Q1", "2009Q2", "2010Q1", "2012Q1", "2015Q1")) |> print()

# ZIVI FTE as share of sectoral employment
if (nrow(besta_fte) > 0) {
  fte_2008 <- besta_fte |> filter(quarter == "2008Q4") |> pull(total_fte)
  fte_2012 <- besta_fte |> filter(quarter == "2012Q1") |> pull(total_fte)
  zivi_fte_2012 <- round(1375293 * 0.664 / 220)

  if (length(fte_2008) > 0 && fte_2008 > 0) {
    cat(sprintf("\nZIVI penetration (2012): ~%.0f FTE / %.0f total = %.1f%%\n",
                zivi_fte_2012, fte_2012, 100 * zivi_fte_2012 / fte_2012))
  }
}

cat("\n=== Data fetch complete ===\n")
