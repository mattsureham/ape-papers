# =============================================================================
# 02_clean_data.R — Process Erasmus flows, build Bartik instrument, merge
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"

# ---------------------------------------------------------------
# 1. Load raw data
# ---------------------------------------------------------------
erasmus <- fread(file.path(data_dir, "Erasmus_2014-2023_aggregate_NUTS.csv"))
educ    <- fread(file.path(data_dir, "eurostat_edat_lfse_04.csv"))
emp     <- fread(file.path(data_dir, "eurostat_lfst_r_lfe2emp.csv"))
lfp     <- fread(file.path(data_dir, "eurostat_lfst_r_lfp2act.csv"))
gdp     <- fread(file.path(data_dir, "eurostat_nama_10r_2gdp.csv"))
pop     <- fread(file.path(data_dir, "eurostat_population.csv"))

# ---------------------------------------------------------------
# 2. Aggregate Erasmus NUTS3 flows to NUTS2
# ---------------------------------------------------------------
# Standardize column names to lowercase
setnames(erasmus, tolower(names(erasmus)))

# NUTS3 codes are 5 characters (e.g., "DE111"), NUTS2 are first 4 (e.g., "DE11")
# Some codes may be 4 or fewer chars already (country-level or NUTS1)

erasmus[, orig_nuts2 := substr(origin, 1, 4)]
erasmus[, dest_nuts2 := substr(destination, 1, 4)]

# Keep only valid NUTS2 codes (4 characters, starting with 2 letters)
erasmus <- erasmus[nchar(orig_nuts2) == 4 & nchar(dest_nuts2) == 4]
erasmus <- erasmus[grepl("^[A-Z]{2}", orig_nuts2) & grepl("^[A-Z]{2}", dest_nuts2)]

# Remove intra-regional flows (same NUTS2)
erasmus <- erasmus[orig_nuts2 != dest_nuts2]

# Aggregate to NUTS2 bilateral flows by year
bilateral <- erasmus[, .(flow = sum(count, na.rm = TRUE)),
                     by = .(orig = orig_nuts2, dest = dest_nuts2, year)]

cat("Bilateral NUTS2 flows:", nrow(bilateral), "rows\n")
cat("  Unique origins:", length(unique(bilateral$orig)), "\n")
cat("  Unique destinations:", length(unique(bilateral$dest)), "\n")
cat("  Years:", sort(unique(bilateral$year)), "\n")

# ---------------------------------------------------------------
# 3. Compute outflows and inflows per region-year
# ---------------------------------------------------------------
outflows <- bilateral[, .(total_out = sum(flow)), by = .(nuts2 = orig, year)]
inflows  <- bilateral[, .(total_in = sum(flow)), by = .(nuts2 = dest, year)]

flows <- merge(outflows, inflows, by = c("nuts2", "year"), all = TRUE)
flows[is.na(total_out), total_out := 0]
flows[is.na(total_in), total_in := 0]
flows[, net_out := total_out - total_in]

cat("Region-year flow panel:", nrow(flows), "rows,",
    length(unique(flows$nuts2)), "regions\n")

# ---------------------------------------------------------------
# 4. Build Bartik instrument
# ---------------------------------------------------------------

# Pre-period: 2014-2016
pre_bilateral <- bilateral[year %in% 2014:2016,
                           .(flow_pre = sum(flow)), by = .(orig, dest)]

# Pre-period total outflows per origin
pre_totals <- pre_bilateral[, .(total_pre = sum(flow_pre)), by = orig]

# Compute shares: s_{ij} = flow_{ij,pre} / total_{i,pre}
shares <- merge(pre_bilateral, pre_totals, by = "orig")
shares[, share := flow_pre / total_pre]

# Destination-level total inflows per year
dest_inflows <- bilateral[, .(G_jt = sum(flow)), by = .(dest, year)]

# For leave-one-out: need destination inflows excluding each origin
# G_{j,-i,t} = G_{j,t} - f_{ij,t}
bartik_parts <- merge(shares[, .(orig, dest, share)],
                      bilateral[, .(orig, dest, year, flow)],
                      by = c("orig", "dest"), all.x = TRUE, allow.cartesian = TRUE)
bartik_parts[is.na(flow), flow := 0]

# Merge total destination inflows
bartik_parts <- merge(bartik_parts, dest_inflows, by = c("dest", "year"), all.x = TRUE)

# Leave-one-out destination inflow
bartik_parts[, G_jt_loo := G_jt - flow]

# Bartik instrument: Z_{it} = sum_j s_{ij} * G_{j,-i,t}
bartik <- bartik_parts[, .(bartik_iv = sum(share * G_jt_loo, na.rm = TRUE)),
                       by = .(nuts2 = orig, year)]

cat("Bartik instrument computed for", length(unique(bartik$nuts2)),
    "regions x", length(unique(bartik$year)), "years\n")

# ---------------------------------------------------------------
# 5. Process Eurostat outcomes
# ---------------------------------------------------------------

# 5a. Tertiary education share (25-34 and 35-64 for placebo)
# Filter: ISCED 5-8, percentage, NUTS2 level
educ_cols <- names(educ)
cat("Education data columns:", educ_cols, "\n")

# The dataset uses isced11 for education level and age for age groups
educ_nuts2 <- educ[nchar(as.character(geo)) == 4 &
                   grepl("^[A-Z]{2}", geo)]

# Tertiary = ED5-8 (ISCED levels 5-8)
educ_tert <- educ_nuts2[isced11 == "ED5-8" & sex == "T" &
                        unit == "PC"]

# Young (25-34) and older (35-64) for placebo
educ_young <- educ_tert[age == "Y25-34",
                        .(nuts2 = as.character(geo),
                          year = as.integer(TIME_PERIOD),
                          tert_share_25_34 = values)]

# Use Y25-64 as the broader cohort for placebo (includes older workers)
educ_old <- educ_tert[age == "Y25-64",
                      .(nuts2 = as.character(geo),
                        year = as.integer(TIME_PERIOD),
                        tert_share_25_64 = values)]

cat("Education (25-34):", nrow(educ_young), "rows,",
    length(unique(educ_young$nuts2)), "regions\n")
cat("Education (35-64):", nrow(educ_old), "rows,",
    length(unique(educ_old$nuts2)), "regions\n")

# 5b. Employment (total and by age group)
emp_nuts2 <- emp[nchar(as.character(geo)) == 4 &
                 grepl("^[A-Z]{2}", geo)]

# Employment for 25-34 year-olds (thousands)
emp_young <- emp_nuts2[age == "Y25-34" & sex == "T" &
                       unit == "THS_PER",
                       .(nuts2 = as.character(geo),
                         year = as.integer(TIME_PERIOD),
                         emp_25_34 = values)]

# Also get employment for 25-64 (broader group, for placebo)
emp_older <- emp_nuts2[age == "Y25-64" & sex == "T" &
                       unit == "THS_PER",
                       .(nuts2 = as.character(geo),
                         year = as.integer(TIME_PERIOD),
                         emp_25_64 = values)]

cat("Employment (25-34):", nrow(emp_young), "rows\n")
cat("Employment (25-64):", nrow(emp_older), "rows\n")

# 5c. Labor force participation
lfp_nuts2 <- lfp[nchar(as.character(geo)) == 4 &
                 grepl("^[A-Z]{2}", geo)]

lfp_young <- lfp_nuts2[age == "Y25-34" & sex == "T" &
                       unit == "THS_PER",
                       .(nuts2 = as.character(geo),
                         year = as.integer(TIME_PERIOD),
                         lfp_25_34 = values)]

cat("LFP (25-34):", nrow(lfp_young), "rows\n")

# 5d. GDP per capita (EUR per inhabitant)
gdp_nuts2 <- gdp[nchar(as.character(geo)) == 4 &
                 grepl("^[A-Z]{2}", geo) &
                 unit == "EUR_HAB",
                 .(nuts2 = as.character(geo),
                   year = as.integer(TIME_PERIOD),
                   gdp_pc = values)]

cat("GDP per capita:", nrow(gdp_nuts2), "rows\n")

# 5e. Population (20-29 for scaling Erasmus flows)
pop_nuts2 <- pop[nchar(as.character(geo)) == 4 &
                 grepl("^[A-Z]{2}", geo)]

# Youth population (20-29): combine 5-year bands Y20-24 + Y25-29
pop_youth_bands <- pop_nuts2[age %in% c("Y20-24", "Y25-29") & sex == "T",
                             .(pop_20_29 = sum(values, na.rm = TRUE)),
                             by = .(nuts2 = as.character(geo),
                                    year = as.integer(TIME_PERIOD))]

# Total population
pop_total <- pop_nuts2[age == "TOTAL" & sex == "T",
                       .(nuts2 = as.character(geo),
                         year = as.integer(TIME_PERIOD),
                         pop_total = values)]

cat("Population (20-29):", nrow(pop_youth_bands), "rows\n")
cat("Population (total):", nrow(pop_total), "rows\n")

# ---------------------------------------------------------------
# 6. Merge into analysis panel
# ---------------------------------------------------------------
panel <- merge(flows, bartik, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, educ_young, by = c("nuts2", "year"), all = FALSE)
panel <- merge(panel, educ_old, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, emp_young, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, emp_older, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, lfp_young, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, gdp_nuts2, by = c("nuts2", "year"), all.x = TRUE)

# Merge population for scaling
panel <- merge(panel, pop_youth_bands, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, pop_total, by = c("nuts2", "year"), all.x = TRUE)

# Scale flows by population
if ("pop_20_29" %in% names(panel)) {
  panel[, net_out_rate := net_out / (pop_20_29 / 1000)]
  panel[, out_rate := total_out / (pop_20_29 / 1000)]
  panel[, bartik_rate := bartik_iv / (pop_20_29 / 1000)]
} else if ("pop_total" %in% names(panel)) {
  panel[, net_out_rate := net_out / (pop_total / 1000)]
  panel[, out_rate := total_out / (pop_total / 1000)]
  panel[, bartik_rate := bartik_iv / (pop_total / 1000)]
} else {
  # Use raw flows if no population data available at this level
  panel[, net_out_rate := net_out]
  panel[, out_rate := total_out]
  panel[, bartik_rate := bartik_iv]
  cat("WARNING: No population data for scaling; using raw flow counts\n")
}

# Country code from NUTS2
panel[, country := substr(nuts2, 1, 2)]

# Pre/post period indicators
panel[, period := fifelse(year <= 2019, "pre",
                  fifelse(year == 2020, "covid", "post"))]

# Log GDP per capita
panel[gdp_pc > 0, log_gdp_pc := log(gdp_pc)]

# ---------------------------------------------------------------
# 7. Long-difference dataset (cross-section)
# ---------------------------------------------------------------
available_vars_pre <- intersect(c("tert_share_25_34", "tert_share_25_64",
                                  "lfp_25_34", "net_out_rate", "gdp_pc"),
                                names(panel))
cat("Available vars for long diff:", available_vars_pre, "\n")

pre_means <- panel[year %in% 2014:2019,
                   .(tert_pre = mean(tert_share_25_34, na.rm = TRUE),
                     tert_old_pre = mean(tert_share_25_64, na.rm = TRUE),
                     net_out_rate_pre = mean(net_out_rate, na.rm = TRUE),
                     gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)),
                   by = nuts2]

post_means <- panel[year %in% 2021:2022,
                    .(tert_post = mean(tert_share_25_34, na.rm = TRUE),
                      tert_old_post = mean(tert_share_25_64, na.rm = TRUE),
                      net_out_rate_post = mean(net_out_rate, na.rm = TRUE),
                      bartik_post = mean(bartik_rate, na.rm = TRUE)),
                    by = nuts2]

# Pre-period bartik (for placebo)
pre_bartik <- panel[year %in% 2014:2016,
                    .(bartik_pre = mean(bartik_rate, na.rm = TRUE)),
                    by = nuts2]

cross <- merge(pre_means, post_means, by = "nuts2")
cross <- merge(cross, pre_bartik, by = "nuts2", all.x = TRUE)
cross[, country := substr(nuts2, 1, 2)]

# Long differences
cross[, delta_tert := tert_post - tert_pre]
cross[, delta_tert_old := tert_old_post - tert_old_pre]
cross[, delta_net_out := net_out_rate_post - net_out_rate_pre]

cat("\nLong-difference cross-section:", nrow(cross), "regions\n")

# ---------------------------------------------------------------
# 8. Save analysis datasets
# ---------------------------------------------------------------
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(cross, file.path(data_dir, "analysis_cross_section.csv"))
fwrite(bilateral, file.path(data_dir, "bilateral_nuts2_flows.csv"))
fwrite(shares, file.path(data_dir, "pre_period_shares.csv"))

cat("\n=== CLEANING COMPLETE ===\n")
cat("Panel:", nrow(panel), "rows,", length(unique(panel$nuts2)), "regions,",
    length(unique(panel$year)), "years\n")
cat("Cross-section:", nrow(cross), "regions\n")
cat("Bilateral flows:", nrow(bilateral), "origin-destination-year combos\n")

# Validation
stopifnot("Panel has >500 rows" = nrow(panel) > 500)
stopifnot("Cross-section has >100 regions" = nrow(cross) > 100)
stopifnot("Bartik IV computed" = sum(!is.na(panel$bartik_rate)) > 100)
cat("Data validation passed.\n")
