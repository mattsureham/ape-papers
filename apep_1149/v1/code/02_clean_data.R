# ==============================================================================
# 02_clean_data.R — Build county-quarter panel with Cardinal share treatment
# ==============================================================================

source("00_packages.R")
library(fixest)

arcos_dt <- fread("../data/arcos_county_qtr_distributor.csv")
county_qtr_total <- fread("../data/arcos_county_qtr_total.csv")

# State FIPS map
state_fips_map <- fread(text = "
state,state_fips
AL,01
AK,02
AZ,04
AR,05
CA,06
CO,08
CT,09
DE,10
DC,11
FL,12
GA,13
HI,15
ID,16
IL,17
IN,18
IA,19
KS,20
KY,21
LA,22
ME,23
MD,24
MA,25
MI,26
MN,27
MS,28
MO,29
MT,30
NE,31
NV,32
NH,33
NJ,34
NM,35
NY,36
NC,37
ND,38
OH,39
OK,40
OR,41
PA,42
RI,44
SC,45
SD,46
TN,47
TX,48
UT,49
VT,50
VA,51
WA,53
WV,54
WI,55
WY,56
")

arcos_dt <- merge(arcos_dt, state_fips_map, by = "state", all.x = TRUE)
county_qtr_total <- merge(county_qtr_total, state_fips_map, by = "state", all.x = TRUE)

arcos_dt[, county_id := paste0(state, "_", county_name)]
county_qtr_total[, county_id := paste0(state, "_", county_name)]

# Time period identifier (year-quarter)
arcos_dt[, yq := year + (quarter - 1) / 4]
county_qtr_total[, yq := year + (quarter - 1) / 4]

# Create period index (1 = 2006Q1, ..., 28 = 2012Q4)
arcos_dt[, period := (year - 2006) * 4 + quarter]
county_qtr_total[, period := (year - 2006) * 4 + quarter]

# Classify major distributors
arcos_dt[, distributor_group := fcase(
  grepl("CARDINAL", distributor, ignore.case = TRUE), "Cardinal",
  grepl("MCKESSON", distributor, ignore.case = TRUE), "McKesson",
  grepl("AMERISOURCE", distributor, ignore.case = TRUE), "AmerisourceBergen",
  grepl("WALGREEN", distributor, ignore.case = TRUE), "Walgreens",
  default = "Other"
)]

# Aggregate by county-quarter-distributor_group
dist_panel <- arcos_dt[, .(pills = sum(total_pills, na.rm = TRUE)),
                        by = .(county_id, state, state_fips, county_name,
                               year, quarter, period, yq, distributor_group)]

# Pivot wide
dist_wide <- dcast(dist_panel,
                   county_id + state + state_fips + county_name + year + quarter + period + yq ~ distributor_group,
                   value.var = "pills", fill = 0)

# Merge total pills
dist_wide <- merge(dist_wide,
                   county_qtr_total[, .(county_id, year, quarter, total_pills)],
                   by = c("county_id", "year", "quarter"), all.x = TRUE)

# Pre-enforcement Cardinal share (2006Q1-2007Q4 = periods 1-8)
pre_cardinal <- dist_wide[period <= 8,
  .(cardinal_pre_pills = sum(Cardinal, na.rm = TRUE),
    total_pre_pills = sum(total_pills, na.rm = TRUE)),
  by = county_id]
pre_cardinal[, cardinal_share := cardinal_pre_pills / total_pre_pills]
pre_cardinal[is.nan(cardinal_share), cardinal_share := 0]

# Build panel
panel <- merge(dist_wide, pre_cardinal[, .(county_id, cardinal_share)],
               by = "county_id", all.x = TRUE)

# Treatment: post = 2008Q1 onward (period >= 9)
panel[, post := as.integer(period >= 9)]

# Treatment period for event study: 2007Q4 (period 8) is reference
# Cardinal suspensions happened Nov-Dec 2007 = 2007Q4
panel[, period_factor := factor(period)]

# Log transforms
panel[, log_total_pills := log(total_pills + 1)]
panel[, log_cardinal := log(Cardinal + 1)]
panel[, log_mckesson := log(McKesson + 1)]
panel[, log_amerisource := log(AmerisourceBergen + 1)]

# Market shares
panel[, cardinal_share_t := Cardinal / total_pills]
panel[is.nan(cardinal_share_t), cardinal_share_t := 0]
panel[, mckesson_share_t := McKesson / total_pills]
panel[is.nan(mckesson_share_t), mckesson_share_t := 0]
panel[, amerisource_share_t := AmerisourceBergen / total_pills]
panel[is.nan(amerisource_share_t), amerisource_share_t := 0]

# Summary
cat("\n=== Panel Summary ===\n")
cat(sprintf("Counties: %d\n", uniqueN(panel$county_id)))
cat(sprintf("Quarters: %d (periods 1-28)\n", uniqueN(panel$period)))
cat(sprintf("Pre-treatment periods: %d (2006Q1-2007Q4)\n", 8))
cat(sprintf("County-quarter obs: %d\n", nrow(panel)))
cat(sprintf("Total pills (all quarters): %.1fB\n", sum(panel$total_pills, na.rm = TRUE) / 1e9))
cat(sprintf("\nCardinal pre-share distribution:\n"))
print(summary(pre_cardinal$cardinal_share))
cat(sprintf("\nCounties with Cardinal share >= 0.20: %d\n",
            sum(pre_cardinal$cardinal_share >= 0.20, na.rm = TRUE)))

fwrite(panel, "../data/analysis_panel.csv")
fwrite(pre_cardinal, "../data/cardinal_pre_share.csv")

cat("\nPanel saved.\n")
