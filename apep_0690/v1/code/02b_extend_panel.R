## 02b_extend_panel.R — Extend panel with Table 122 (2001-2024 net additions)
## Paper: apep_0690 — UK Office-to-Residential PD Rights

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

# ============================================================
# Parse Table 122 — net additions 2001-2024 in a single sheet
# ============================================================
cat("\n=== Parsing Table 122 (extended time series) ===\n")

t122 <- data.table(suppressMessages(readODS::read_ods(
  "Live_Table_122.ods", sheet = "LT_122", skip = 4)))

# Column 3 = ONS code, column 4 = LA name, columns 5-28 = years
cn <- names(t122)

# Extract year columns (5 onward)
year_cols <- cn[5:length(cn)]
years <- as.integer(gsub("^(\\d{4}).*", "\\1", year_cols))
cat("Years found:", paste(years, collapse = ", "), "\n")

# Melt to long format
t122_long <- melt(t122, id.vars = cn[1:4],
                  measure.vars = year_cols,
                  variable.name = "year_col",
                  value.name = "net_additions_raw")

# Extract year and clean
t122_long[, year := as.integer(gsub("^(\\d{4}).*", "\\1", year_col))]
t122_long[, ons_code := as.character(get(cn[3]))]
t122_long[, la_name := as.character(get(cn[4]))]

# Clean numeric values
t122_long[, net_additions := suppressWarnings(as.numeric(gsub("\\[.*\\]", NA, net_additions_raw)))]

# Filter to English LAs
t122_long <- t122_long[grepl("^E0[6-9]|^E10", ons_code)]
t122_long <- t122_long[, .(ons_code, la_name, year, net_additions)]

cat("Table 122 panel:", nrow(t122_long), "rows,",
    uniqueN(t122_long$ons_code), "LAs,",
    uniqueN(t122_long$year), "years\n")
cat("Year range:", paste(range(t122_long$year), collapse = "-"), "\n")

# ============================================================
# Load existing panel components and rebuild
# ============================================================
# Load VOA office share
voa_office <- fread("analysis_panel.csv")[, .(ons_code, office_share, total_office_fs, total_fs)]
voa_office <- unique(voa_office[!is.na(office_share)])

# Load population
pop <- fread("population_by_la.csv")
names(pop) <- tolower(names(pop))
pop <- pop[, .(ons_code = geography_code,
               year = as.integer(gsub("Mid-", "", date_name)),
               population = obs_value)]
pop <- pop[grepl("^E0[6-9]|^E10", ons_code)]

# Load house prices
hpi_annual <- fread("hpi_annual_la.csv")

# Load PDR data from Table 123 panel
old_panel <- fread("analysis_panel.csv")[, .(ons_code, year, pdr_office,
                                              pdr_total_residential, new_build,
                                              net_conversions, net_change_of_use)]

# Article 4
article4 <- fread("article4_boroughs.csv")

# ============================================================
# Build extended panel
# ============================================================
cat("\n=== Building extended panel ===\n")

# Start with Table 122 (net additions only, but back to 2001)
# Use years 2006-2024 for our panel (7 pre-periods: 2006-2012)
panel <- t122_long[year >= 2006]
cat("Panel (2006-2024):", nrow(panel), "rows\n")

# Merge population
panel <- merge(panel, pop, by = c("ons_code", "year"), all.x = TRUE)

# Merge VOA office share
panel <- merge(panel, voa_office, by = "ons_code", all.x = TRUE)

# Merge HPI
panel <- merge(panel, hpi_annual, by = c("ons_code", "year"), all.x = TRUE)

# Merge PDR data (only available 2015+)
panel <- merge(panel, old_panel, by = c("ons_code", "year"), all.x = TRUE)

# Drop missing office share
panel <- panel[!is.na(office_share)]

# Treatment variables
panel[, post := as.integer(year >= 2013)]
panel[, office_x_post := office_share * post]

# Per-capita measures
panel[, additions_pc := net_additions / (population / 1000)]

# Log outcomes
panel[, log_additions := log(pmax(net_additions, 1))]
panel[, log_additions_pc := log(pmax(additions_pc, 0.01))]

# PDR share
panel[, pdr_office_share := pdr_office / pmax(net_additions, 1)]

# Article 4
panel[, article4 := as.integer(la_name %in% article4$la_name |
        gsub(" UA$| London Boro$| City of London", "", la_name) %in%
        gsub(" UA$| London Boro$| City of London", "", article4$la_name))]

# Event time
panel[, event_time := year - 2013]

# Log prices
for (pv in intersect(c("AveragePrice", "FlatPrice", "DetachedPrice",
                         "SemiDetachedPrice", "TerracedPrice"), names(panel))) {
  panel[, (paste0("log_", pv)) := log(pmax(get(pv), 1))]
}

# Office quartiles
q_breaks <- quantile(panel$office_share, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
panel[, office_q := cut(office_share, breaks = q_breaks,
                         labels = c("Q1", "Q2", "Q3", "Q4"),
                         include.lowest = TRUE)]

# Save
fwrite(panel, "analysis_panel.csv")

# Summary
cat("\n=== EXTENDED PANEL SUMMARY ===\n")
cat(sprintf("Rows: %d\n", nrow(panel)))
cat(sprintf("LAs: %d\n", uniqueN(panel$ons_code)))
cat(sprintf("Years: %s\n", paste(range(panel$year), collapse = "-")))
cat(sprintf("Pre-periods (year < 2013): %d\n", uniqueN(panel$year[panel$year < 2013])))
cat(sprintf("Post-periods: %d\n", uniqueN(panel$year[panel$year >= 2013])))
cat(sprintf("Net additions: mean=%.1f, sd=%.1f\n",
            mean(panel$net_additions, na.rm = TRUE),
            sd(panel$net_additions, na.rm = TRUE)))
