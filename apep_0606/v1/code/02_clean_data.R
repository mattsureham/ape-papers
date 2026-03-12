## 02_clean_data.R — Parse NIAAA alcohol data + construct treatment from CDC taxes
## APEP-0606: Cross-Substance Spillovers of Cigarette Excise Taxes

source("00_packages.R")

# =============================================================================
# 1. Parse NIAAA alcohol consumption data (fixed-width format)
# =============================================================================
cat("Parsing NIAAA alcohol consumption data...\n")
niaaa_lines <- readRDS("../data/niaaa_raw_lines.rds")

# Format (from header):
# Col 1-4:  Year
# Col 6-7:  FIPS state code
# Col 9:    Beverage type (1=beer, 2=wine, 3=spirits, 4=all)
# Col 11-20: Gallons of beverage
# Col 22-30: Gallons of ethanol
# Col 32-40: Population (14+)
# Col 43-47: Per capita ethanol (14+) — DIVIDE BY 10,000
# Col 52-60: Population (21+)
# Col 63-67: Per capita ethanol (21+) — DIVIDE BY 10,000

# Parse data lines (those starting with a 4-digit year)
data_lines <- niaaa_lines[grepl("^\\d{4}", niaaa_lines)]
cat("Data lines found:", length(data_lines), "\n")

# Parse fixed-width
parsed <- data.table(
  year = as.integer(substr(data_lines, 1, 4)),
  fips = sprintf("%02d", as.integer(trimws(substr(data_lines, 6, 7)))),
  bev_type = as.integer(trimws(substr(data_lines, 9, 9))),
  gal_beverage = as.numeric(trimws(substr(data_lines, 11, 20))),
  gal_ethanol = as.numeric(trimws(substr(data_lines, 22, 30))),
  pop14 = as.numeric(trimws(substr(data_lines, 32, 40))),
  pc_ethanol14 = as.numeric(trimws(substr(data_lines, 43, 47))),
  pop21 = as.numeric(trimws(substr(data_lines, 52, 60))),
  pc_ethanol21 = as.numeric(trimws(substr(data_lines, 63, 67)))
)

# Divide per capita by 10,000 as specified
parsed[, pc_ethanol14 := pc_ethanol14 / 10000]
parsed[, pc_ethanol21 := pc_ethanol21 / 10000]

cat("Parsed:", nrow(parsed), "rows\n")
cat("Year range:", min(parsed$year), "-", max(parsed$year), "\n")
cat("FIPS codes:", length(unique(parsed$fips)), "\n")
cat("Beverage types:", paste(sort(unique(parsed$bev_type)), collapse = ", "), "\n")

# Filter: keep state-level (FIPS 01-56), exclude US total (00) and territories
state_fips_map <- data.table(
  fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                           24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,
                           44,45,46,47,48,49,50,51,53,54,55,56)),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                 "Connecticut","Delaware","District of Columbia","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky",
                 "Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota",
                 "Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire",
                 "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont",
                 "Virginia","Washington","West Virginia","Wisconsin","Wyoming"),
  state_abb = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
                "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
                "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
                "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

parsed <- merge(parsed, state_fips_map, by = "fips")
cat("After state merge:", nrow(parsed), "rows,", length(unique(parsed$state_name)), "states\n")

# Reshape: one row per state-year with columns for each beverage type
# bev_type: 1=beer, 2=wine, 3=spirits, 4=all
bev_labels <- c("1" = "beer", "2" = "wine", "3" = "spirits", "4" = "total")

# Use per capita ethanol (21+) as primary outcome
alcohol_wide <- dcast(parsed,
                      state_name + state_abb + year ~ bev_type,
                      value.var = "pc_ethanol21",
                      fun.aggregate = mean)
setnames(alcohol_wide, c("1","2","3","4"),
         c("beer", "wine", "spirits", "total"),
         skip_absent = TRUE)

cat("\nAlcohol panel (wide):", nrow(alcohol_wide), "state-year obs\n")
cat("States:", length(unique(alcohol_wide$state_name)), "\n")
cat("Years:", min(alcohol_wide$year), "-", max(alcohol_wide$year), "\n")

# Validate: California
cat("\nCalifornia alcohol consumption (gallons ethanol per capita 21+):\n")
print(alcohol_wide[state_name == "California" & year >= 2014 & year <= 2019,
                   .(year, beer, wine, spirits, total)])

# =============================================================================
# 2. Parse CDC cigarette tax data
# =============================================================================
cat("\nProcessing CDC cigarette tax data...\n")
cdc <- readRDS("../data/cdc_tax_raw.rds")
cdc[, year := as.integer(year)]
cdc[, tax_per_pack := as.numeric(data_value)]
cdc[, state_name := locationdesc]

# Keep state-level only
cdc <- cdc[state_name != "United States"]
cat("CDC tax data:", nrow(cdc), "state-year obs\n")

# =============================================================================
# 3. Identify treatment events
# =============================================================================
cat("\nIdentifying cigarette tax increases...\n")
cdc <- cdc[order(state_name, year)]
cdc[, tax_change := tax_per_pack - shift(tax_per_pack, 1), by = state_name]

# Large increase: >= $0.25/pack
cdc[, large_increase := as.integer(!is.na(tax_change) & tax_change >= 0.25)]

increases <- cdc[large_increase == 1 & year >= 2001]
cat("Total large increases (>=$0.25, 2001-2019):", nrow(increases), "\n")
cat("Mean increase: $", round(mean(increases$tax_change), 2), "/pack\n")

# First large increase per state
first_increase <- cdc[large_increase == 1 & year >= 2001,
                       .(first_treat_year = min(year),
                         first_tax_change = tax_change[which.min(year)]),
                       by = state_name]
cat("States with first large increase:", nrow(first_increase), "\n")

cat("\nFirst treatment year distribution:\n")
print(first_increase[, .N, by = first_treat_year][order(first_treat_year)])

# =============================================================================
# 4. Merge into analysis panel
# =============================================================================
cat("\nMerging data...\n")
panel <- merge(alcohol_wide, first_increase, by = "state_name", all.x = TRUE)
panel[is.na(first_treat_year), first_treat_year := 0L]

# Merge tax levels
tax_levels <- cdc[, .(state_name, year, tax_per_pack, tax_change)]
panel <- merge(panel, tax_levels, by = c("state_name", "year"), all.x = TRUE)

# Restrict to 1995-2019
panel <- panel[year >= 1995 & year <= 2019]
panel[, state_id := as.integer(as.factor(state_name))]

never_treated <- unique(panel[first_treat_year == 0]$state_name)
cat("\nAnalysis panel:", nrow(panel), "state-year obs\n")
cat("States:", length(unique(panel$state_name)), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Treated states:", length(unique(panel[first_treat_year > 0]$state_name)), "\n")
cat("Never-treated:", length(never_treated), "\n")
if (length(never_treated) > 0) {
  cat("  Names:", paste(never_treated, collapse = ", "), "\n")
}

# =============================================================================
# 5. Summary statistics
# =============================================================================
cat("\n=== SUMMARY STATISTICS ===\n")
for (v in c("total", "beer", "wine", "spirits")) {
  vals <- panel[[v]]
  cat(sprintf("  %s: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
              v, mean(vals, na.rm=TRUE), sd(vals, na.rm=TRUE),
              min(vals, na.rm=TRUE), max(vals, na.rm=TRUE)))
}

if (sum(!is.na(panel$tax_per_pack)) > 0) {
  tax_vals <- panel$tax_per_pack[!is.na(panel$tax_per_pack)]
  cat(sprintf("  tax_per_pack: mean=%.2f, sd=%.2f, min=%.2f, max=%.2f\n",
              mean(tax_vals), sd(tax_vals), min(tax_vals), max(tax_vals)))
}

saveRDS(panel, "../data/panel_clean.rds")
saveRDS(first_increase, "../data/first_increase.rds")
cat("\nClean panel saved.\n")
