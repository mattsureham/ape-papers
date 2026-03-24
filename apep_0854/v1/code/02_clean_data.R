# 02_clean_data.R — Construct analysis dataset
# Merges HDB resale transactions with Census 2020 ethnic composition

source("00_packages.R")

cat("=== Loading Raw Data ===\n")
hdb <- readRDS("../data/hdb_resale_raw.rds")
census <- readRDS("../data/census_ethnic_parsed.rds")

cat("HDB transactions:", nrow(hdb), "\n")
cat("Census subzone records:", nrow(census), "\n")

# ============================================================
# 1. Clean HDB transactions
# ============================================================
cat("\n=== Cleaning HDB Transactions ===\n")

hdb_clean <- hdb %>%
  mutate(
    resale_price = as.numeric(resale_price),
    floor_area_sqm = as.numeric(floor_area_sqm),
    lease_commence_date = as.integer(lease_commence_date),
    year_month = month,
    year = as.integer(substr(month, 1, 4)),
    month_num = as.integer(substr(month, 6, 7)),
    year_quarter = paste0(year, "Q", ceiling(month_num / 3)),
    log_price = log(resale_price),
    # Parse storey range to midpoint
    storey_mid = {
      parts <- str_match(storey_range, "(\\d+) TO (\\d+)")
      (as.numeric(parts[, 2]) + as.numeric(parts[, 3])) / 2
    },
    # Remaining lease in years
    remaining_lease_years = {
      rl <- remaining_lease
      yrs <- as.numeric(str_extract(rl, "^\\d+"))
      mos <- as.numeric(str_extract(rl, "(\\d+) month"))
      mos[is.na(mos)] <- 0
      yrs + mos / 12
    },
    # Flat type as ordered factor
    flat_type_f = factor(flat_type, levels = c(
      "1 ROOM", "2 ROOM", "3 ROOM", "4 ROOM", "5 ROOM",
      "EXECUTIVE", "MULTI-GENERATION"
    )),
    town_upper = toupper(town)
  ) %>%
  filter(
    !is.na(resale_price),
    resale_price > 50000,
    !is.na(floor_area_sqm),
    floor_area_sqm > 20,
    year >= 2017
  )

cat("After cleaning:", nrow(hdb_clean), "transactions\n")
cat("Year range:", min(hdb_clean$year), "-", max(hdb_clean$year), "\n")
cat("Towns:", n_distinct(hdb_clean$town), "\n")
cat("Price range: S$", scales::comma(min(hdb_clean$resale_price)),
    "- S$", scales::comma(max(hdb_clean$resale_price)), "\n")

# ============================================================
# 2. Clean Census ethnic data — planning area level
# ============================================================
cat("\n=== Processing Census Ethnic Data ===\n")

# Extract planning area totals (rows with "- Total")
pa_ethnic <- census %>%
  filter(grepl("- Total$", subzone)) %>%
  mutate(
    town = toupper(str_trim(gsub(" - Total$", "", subzone))),
    total_pop = total_pop,
    chinese_share = chinese_pop / total_pop,
    malay_share = malay_pop / total_pop,
    indian_share = indian_pop / total_pop,
    other_share = other_pop / total_pop,
    minority_share = (malay_pop + indian_pop + other_pop) / total_pop
  ) %>%
  filter(total_pop > 0) %>%
  select(town, total_pop, chinese_share, malay_share, indian_share,
         other_share, minority_share)

cat("Planning areas with ethnic data:", nrow(pa_ethnic), "\n")

# Also extract subzone-level data for finer analysis
sz_ethnic <- census %>%
  filter(
    !grepl("- Total$", subzone),
    subzone != "Total",
    total_pop > 0
  ) %>%
  mutate(
    chinese_share = chinese_pop / total_pop,
    malay_share = malay_pop / total_pop,
    indian_share = indian_pop / total_pop,
    minority_share = (malay_pop + indian_pop + other_pop) / total_pop
  )

cat("Subzones with ethnic data:", nrow(sz_ethnic), "\n")

# ============================================================
# 3. EIP Threshold Variables
# ============================================================
cat("\n=== Constructing EIP Threshold Variables ===\n")

# EIP neighbourhood-level limits (from HDB policy documents)
EIP_CHINESE_LIMIT <- 0.84
EIP_MALAY_LIMIT <- 0.22
EIP_INDIAN_LIMIT <- 0.10

pa_ethnic <- pa_ethnic %>%
  mutate(
    # Distance from EIP thresholds (positive = above limit = constrained)
    chinese_dist = chinese_share - EIP_CHINESE_LIMIT,
    malay_dist = malay_share - EIP_MALAY_LIMIT,
    indian_dist = indian_share - EIP_INDIAN_LIMIT,
    # Binding constraint indicators
    chinese_constrained = chinese_share > EIP_CHINESE_LIMIT,
    malay_constrained = malay_share > EIP_MALAY_LIMIT,
    indian_constrained = indian_share > EIP_INDIAN_LIMIT,
    # Any binding constraint
    any_constrained = chinese_constrained | malay_constrained | indian_constrained,
    # Number of binding constraints (0-3)
    n_constraints = chinese_constrained + malay_constrained + indian_constrained,
    # EIP constraint intensity: max distance above any threshold
    constraint_intensity = pmax(chinese_dist, malay_dist, indian_dist, 0)
  )

cat("\nEIP Constraint Status by Planning Area:\n")
cat("Chinese constrained (>84%):", sum(pa_ethnic$chinese_constrained), "towns\n")
cat("Malay constrained (>22%):", sum(pa_ethnic$malay_constrained), "towns\n")
cat("Indian constrained (>10%):", sum(pa_ethnic$indian_constrained), "towns\n")
cat("Any constraint:", sum(pa_ethnic$any_constrained), "towns\n")

# ============================================================
# 4. Merge HDB transactions with ethnic composition
# ============================================================
cat("\n=== Merging Datasets ===\n")

# Match town names between HDB and Census
# First check for mismatches
hdb_towns <- sort(unique(hdb_clean$town_upper))
census_towns <- sort(pa_ethnic$town)

cat("HDB towns:", length(hdb_towns), "\n")
cat("Census towns:", length(census_towns), "\n")

# Handle known name mismatches
name_map <- c(
  "KALLANG/WHAMPOA" = "KALLANG/WHAMPOA",
  "CENTRAL AREA" = "CENTRAL AREA"
)

# Try direct match first
matched <- hdb_towns[hdb_towns %in% census_towns]
unmatched_hdb <- hdb_towns[!hdb_towns %in% census_towns]

cat("Matched towns:", length(matched), "\n")
if (length(unmatched_hdb) > 0) {
  cat("Unmatched HDB towns:", paste(unmatched_hdb, collapse = ", "), "\n")
}

# Merge
df <- hdb_clean %>%
  left_join(pa_ethnic, by = c("town_upper" = "town"))

matched_pct <- 100 * mean(!is.na(df$chinese_share))
cat("Merge rate:", round(matched_pct, 1), "%\n")

if (matched_pct < 80) {
  stop("FATAL: Only ", round(matched_pct, 1), "% of transactions matched. ",
       "Town name alignment issue.")
}

# Drop unmatched
df <- df %>% filter(!is.na(chinese_share))
cat("Final analysis dataset:", nrow(df), "transactions\n")

# ============================================================
# 5. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

cat("\nPrice by year:\n")
df %>%
  group_by(year) %>%
  summarise(
    n = n(),
    mean_price = mean(resale_price),
    median_price = median(resale_price),
    .groups = "drop"
  ) %>%
  print(n = 20)

cat("\nPrice by flat type:\n")
df %>%
  group_by(flat_type) %>%
  summarise(
    n = n(),
    mean_price = mean(resale_price),
    .groups = "drop"
  ) %>%
  arrange(mean_price) %>%
  print()

cat("\nMinority share distribution:\n")
print(summary(df$minority_share))

cat("\nConstrained vs unconstrained towns:\n")
df %>%
  group_by(any_constrained) %>%
  summarise(
    n = n(),
    n_towns = n_distinct(town),
    mean_price = mean(resale_price),
    mean_minority = mean(minority_share),
    .groups = "drop"
  ) %>%
  print()

# Save
saveRDS(df, "../data/analysis_data.rds")
saveRDS(pa_ethnic, "../data/pa_ethnic.rds")
cat("\nSaved analysis_data.rds (", nrow(df), " obs) and pa_ethnic.rds\n")
