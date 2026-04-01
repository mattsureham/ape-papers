## 01_fetch_data.R — Fetch ABS state x industry employment via readabs
## Data: ABS Cat 6291.0.55.001 — Labour Force, Australia, Detailed
## Table 5: Employed persons by industry × state × quarter

source("00_packages.R")
library(readabs)

cat("=== Fetching ABS Labour Force Detailed data (Table 5) ===\n")

# ---------------------------------------------------------------
# Download Table 5: State x Industry employment (quarterly)
# ---------------------------------------------------------------
raw <- read_abs(cat_no = "6291.0.55.001", tables = "5")
dt <- as.data.table(raw)

cat("Raw download:", nrow(dt), "rows\n")
cat("Date range:", as.character(min(dt$date)), "to", as.character(max(dt$date)), "\n")

# ---------------------------------------------------------------
# Parse series string: "State ; Industry ; Measure"
# ---------------------------------------------------------------
dt[, c("state_raw", "industry_raw", "measure_raw") := tstrsplit(series, " ;  ", fixed = TRUE)]
dt[, state_raw := trimws(gsub("^> ", "", state_raw))]
dt[, industry_raw := trimws(industry_raw)]
dt[, measure_raw := trimws(measure_raw)]

# Keep only "Employed total" (only Original series available at state x industry level)
dt_emp <- dt[grepl("^Employed total", measure_raw)]

# Exclude "Australia" aggregate — keep only states/territories
dt_emp <- dt_emp[state_raw != "Australia"]

# Map state names to abbreviations
state_map <- c(
  "New South Wales" = "NSW",
  "Victoria" = "VIC",
  "Queensland" = "QLD",
  "South Australia" = "SA",
  "Western Australia" = "WA",
  "Tasmania" = "TAS",
  "Northern Territory" = "NT",
  "Australian Capital Territory" = "ACT"
)
dt_emp[, state := state_map[state_raw]]
stopifnot("Unmapped states" = !any(is.na(dt_emp$state)))

# ---------------------------------------------------------------
# Select target industries
# ---------------------------------------------------------------
target_industries <- c(
  "Electricity, Gas, Water and Waste Services",
  "Mining",
  "Manufacturing",
  "Construction"  # additional placebo
)
dt_emp <- dt_emp[industry_raw %in% target_industries]

# Create clean industry variable
dt_emp[, industry := fcase(
  industry_raw == "Electricity, Gas, Water and Waste Services", "electricity",
  industry_raw == "Mining", "mining",
  industry_raw == "Manufacturing", "manufacturing",
  industry_raw == "Construction", "construction"
)]

# ---------------------------------------------------------------
# Create time variables
# ---------------------------------------------------------------
dt_emp[, year := year(date)]
dt_emp[, quarter := quarter(date)]
dt_emp[, yq := year + (quarter - 1) / 4]
dt_emp[, employment := value]  # thousands of persons

# Restrict to analysis window: 2005-2019
dt_emp <- dt_emp[year >= 2005 & year <= 2019]

cat("\n=== Filtered data ===\n")
cat("States:", paste(sort(unique(dt_emp$state)), collapse = ", "), "\n")
cat("Industries:", paste(unique(dt_emp$industry), collapse = ", "), "\n")
cat("Time range:", min(dt_emp$yq), "to", max(dt_emp$yq), "\n")
cat("Obs per state-industry:", nrow(dt_emp) / (length(unique(dt_emp$state)) * length(unique(dt_emp$industry))), "quarters\n")

# Validate no missing values
stopifnot("Missing employment" = !any(is.na(dt_emp$employment)))

# Check for zeros/very small values
cat("\nMin employment by state-industry:\n")
print(dt_emp[, .(min_emp = min(employment)), by = .(state, industry)][order(min_emp)][1:10])

# ---------------------------------------------------------------
# Treatment intensity: coal share of electricity generation (2010-11)
# Source: BREE/ABS Energy Account Australia
# ---------------------------------------------------------------
cat("\n=== Coal share treatment intensity ===\n")

coal_share <- data.table(
  state = c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
  coal_share = c(0.86, 0.92, 0.68, 0.21, 0.39, 0.02, 0.00, 0.00),
  coal_type = c("black", "brown", "black", "black", "black", "none", "none", "none")
)
# Carbon intensity adjustment: Victoria's brown coal (lignite) emits ~40% more CO2/MWh
coal_share[, carbon_intensity := fifelse(coal_type == "brown", coal_share * 1.40, coal_share)]

print(coal_share[order(-coal_share)])

# ---------------------------------------------------------------
# Merge into panel
# ---------------------------------------------------------------
panel <- merge(dt_emp[, .(state, industry, year, quarter, yq, employment, date)],
               coal_share, by = "state", all.x = TRUE)

# Define treatment periods
# Carbon tax: July 1, 2012 (Q3 2012) to July 17, 2014 (Q3 2014)
# Pre: before Q3 2012; Tax: Q3 2012 to Q2 2014; Post-repeal: Q3 2014 onward
panel[, period := fcase(
  yq < 2012.5, "pre",
  yq >= 2012.5 & yq < 2014.5, "tax",
  yq >= 2014.5, "post_repeal"
)]
panel[, tax_period := as.integer(period == "tax")]
panel[, post_repeal := as.integer(period == "post_repeal")]

# Treatment interaction terms
panel[, coal_x_tax := coal_share * tax_period]
panel[, coal_x_post := coal_share * post_repeal]
panel[, carbon_x_tax := carbon_intensity * tax_period]
panel[, carbon_x_post := carbon_intensity * post_repeal]

# Log employment (in thousands)
panel[, log_emp := log(employment)]

# State-industry identifier for FE
panel[, state_ind := paste0(state, "_", industry)]

# Numeric quarter index for event study
panel[, qtr_idx := (year - 2005) * 4 + quarter]

# Event time relative to Q3 2012 (carbon tax start)
# Q3 2012 = 2012 + 0.5 → qtr_idx for 2012Q3 = (2012-2005)*4 + 3 = 31
tax_start_idx <- (2012 - 2005) * 4 + 3  # = 31
panel[, event_time := qtr_idx - tax_start_idx]

# Save panel
fwrite(panel, "../data/panel.csv")

cat("\n=== Panel saved ===\n")
cat("Total observations:", nrow(panel), "\n")
cat("State-industry units:", length(unique(panel$state_ind)), "\n")
cat("Quarters:", length(unique(panel$yq)), "\n")

# Quick summary for electricity sector
elec <- panel[industry == "electricity"]
cat("\n=== Electricity sector summary ===\n")
cat("Obs:", nrow(elec), "\n")
cat("Employment range:", min(elec$employment), "to", max(elec$employment), "(thousands)\n")
cat("Mean employment by state:\n")
print(elec[, .(mean_emp = round(mean(employment), 1)), by = state][order(-mean_emp)])
