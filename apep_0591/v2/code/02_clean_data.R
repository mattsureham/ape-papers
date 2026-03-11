# =============================================================================
# 02_clean_data.R — Build analysis datasets for v2
# APEP-0591 v2: The Erasmus Drain
# =============================================================================
# Key data availability finding: Education × age at NUTS3 is NOT available
# from Eurostat census data. Education is at NUTS2 only.
#
# Strategy:
#   1. Build NUTS3 Bartik IV from bilateral flows (primary instrument)
#   2. NUTS2 panel with education outcomes (main analysis, as in v1)
#   3. NUTS3 youth population share as alternative outcome
#   4. Census 2011→2021 long-difference at NUTS2 with NUTS3-sourced Bartik
#   5. Test whether NUTS3 Bartik has more within-country variation than NUTS2
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
pop     <- fread(file.path(data_dir, "eurostat_demo_r_pjangrp3.csv"))

# Census data (may not all exist)
cens11_educ <- tryCatch(fread(file.path(data_dir, "eurostat_cens_11aed_r2.csv")),
                          error = function(e) NULL)
cens21_educ <- tryCatch(fread(file.path(data_dir, "eurostat_cens_21ae_r2.csv")),
                          error = function(e) NULL)

setnames(erasmus, tolower(names(erasmus)))

# ---------------------------------------------------------------
# 2. Build NUTS3 bilateral flows and Bartik IV
# ---------------------------------------------------------------
cat("Building NUTS3 Bartik instrument from bilateral flows...\n")

# Keep only NUTS3 bilateral flows (5-char codes)
erasmus_n3 <- erasmus[nchar(origin) == 5 & nchar(destination) == 5]
erasmus_n3 <- erasmus_n3[grepl("^[A-Z]{2}", origin) & grepl("^[A-Z]{2}", destination)]
erasmus_n3 <- erasmus_n3[origin != destination]

bilateral_n3 <- erasmus_n3[, .(flow = sum(count, na.rm = TRUE)),
                            by = .(orig = origin, dest = destination, year)]

cat("  NUTS3 bilateral flows:", nrow(bilateral_n3), "rows\n")
cat("  Unique origins:", length(unique(bilateral_n3$orig)), "\n")

# Pre-period shares (2014-2016)
pre_bilateral_n3 <- bilateral_n3[year %in% 2014:2016,
                                  .(flow_pre = sum(flow)), by = .(orig, dest)]
pre_totals_n3 <- pre_bilateral_n3[, .(total_pre = sum(flow_pre)), by = orig]
shares_n3 <- merge(pre_bilateral_n3, pre_totals_n3, by = "orig")
shares_n3[, share := flow_pre / total_pre]

# Pre-period destination totals (annual avg)
dest_pre_n3 <- bilateral_n3[year %in% 2014:2016,
                              .(G_j_pre = sum(flow) / 3), by = dest]

# Destination inflows by year
dest_year_n3 <- bilateral_n3[, .(G_jt = sum(flow)), by = .(dest, year)]

# LOO destination growth + Bartik
bartik_parts <- merge(shares_n3[, .(orig, dest, share, flow_pre)],
                       bilateral_n3[, .(orig, dest, year, flow)],
                       by = c("orig", "dest"), all.x = TRUE, allow.cartesian = TRUE)
bartik_parts[is.na(flow), flow := 0]
bartik_parts <- merge(bartik_parts, dest_year_n3, by = c("dest", "year"), all.x = TRUE)
bartik_parts <- merge(bartik_parts, dest_pre_n3, by = "dest", all.x = TRUE)

bartik_parts[, G_jt_loo := G_jt - flow]
bartik_parts[, g_jt_loo := (G_jt_loo - G_j_pre) / pmax(G_j_pre, 1)]

bartik_n3 <- bartik_parts[, .(bartik_growth = sum(share * g_jt_loo, na.rm = TRUE)),
                           by = .(nuts3 = orig, year)]

cat("  NUTS3 Bartik computed:", length(unique(bartik_n3$nuts3)), "regions ×",
    length(unique(bartik_n3$year)), "years\n")

# ---------------------------------------------------------------
# 3. NUTS3 outflows and population
# ---------------------------------------------------------------
outflows_n3 <- bilateral_n3[, .(total_out = sum(flow)), by = .(nuts3 = orig, year)]
inflows_n3  <- bilateral_n3[, .(total_in = sum(flow)), by = .(nuts3 = dest, year)]

flows_n3 <- merge(outflows_n3, inflows_n3,
                   by.x = c("nuts3", "year"), by.y = c("nuts3", "year"), all = TRUE)
flows_n3[is.na(total_out), total_out := 0]
flows_n3[is.na(total_in), total_in := 0]
flows_n3[, net_out := total_out - total_in]

# NUTS3 population
pop_nuts3 <- pop[nchar(as.character(geo)) == 5 & grepl("^[A-Z]{2}", geo)]
pop_youth_n3 <- pop_nuts3[age %in% c("Y20-24", "Y25-29") & sex == "T",
                           .(pop_20_29 = sum(values, na.rm = TRUE)),
                           by = .(nuts3 = as.character(geo),
                                  year = as.integer(TIME_PERIOD))]

# Build NUTS3 panel
panel_n3 <- merge(flows_n3, bartik_n3, by = c("nuts3", "year"), all.x = TRUE)
panel_n3 <- merge(panel_n3, pop_youth_n3, by = c("nuts3", "year"), all.x = TRUE)
panel_n3[pop_20_29 > 0, out_rate := total_out / (pop_20_29 / 1000)]
panel_n3[pop_20_29 > 0, net_out_rate := net_out / (pop_20_29 / 1000)]
panel_n3[, country := substr(nuts3, 1, 2)]
panel_n3[, nuts2 := substr(nuts3, 1, 4)]

# Predicted outflow: pre-period level × (1 + bartik growth)
pre_total_annual <- pre_totals_n3[, .(nuts3 = orig, total_pre_annual = total_pre / 3)]
panel_n3 <- merge(panel_n3, pre_total_annual, by = "nuts3", all.x = TRUE)
panel_n3[!is.na(bartik_growth) & !is.na(total_pre_annual) & pop_20_29 > 0,
         predicted_out_rate := (total_pre_annual * (1 + bartik_growth)) / (pop_20_29 / 1000)]

cat("NUTS3 panel:", nrow(panel_n3), "rows\n")

# ---------------------------------------------------------------
# 4. Aggregate NUTS3 Bartik to NUTS2
# ---------------------------------------------------------------
cat("\nAggregating NUTS3 Bartik to NUTS2...\n")

# Weight by pre-period outflows (larger senders get more weight)
n3_weights <- pre_totals_n3[, .(nuts3 = orig, weight = total_pre)]
n3_weights[, nuts2 := substr(nuts3, 1, 4)]
n3_weights[, weight_norm := weight / sum(weight, na.rm = TRUE), by = nuts2]

bartik_n3_weighted <- merge(bartik_n3, n3_weights[, .(nuts3, nuts2, weight_norm)],
                             by = "nuts3", all.x = TRUE)

bartik_n2_from_n3 <- bartik_n3_weighted[!is.na(weight_norm),
                                          .(bartik_growth_n3agg = sum(weight_norm * bartik_growth, na.rm = TRUE)),
                                          by = .(nuts2, year)]

cat("  NUTS2 regions with aggregated NUTS3 Bartik:",
    length(unique(bartik_n2_from_n3$nuts2)), "\n")

# ---------------------------------------------------------------
# 5. Build NUTS2 bilateral flows and Bartik (original v1 approach)
# ---------------------------------------------------------------
cat("\nBuilding NUTS2 Bartik (original approach)...\n")

erasmus[, orig_nuts2 := substr(origin, 1, 4)]
erasmus[, dest_nuts2 := substr(destination, 1, 4)]
erasmus_n2 <- erasmus[nchar(orig_nuts2) == 4 & nchar(dest_nuts2) == 4 &
                        grepl("^[A-Z]{2}", orig_nuts2) & grepl("^[A-Z]{2}", dest_nuts2) &
                        orig_nuts2 != dest_nuts2]

bilateral_n2 <- erasmus_n2[, .(flow = sum(count, na.rm = TRUE)),
                            by = .(orig = orig_nuts2, dest = dest_nuts2, year)]

# NUTS2 Bartik (same as v1)
pre_bilateral_n2 <- bilateral_n2[year %in% 2014:2016,
                                  .(flow_pre = sum(flow)), by = .(orig, dest)]
pre_totals_n2 <- pre_bilateral_n2[, .(total_pre = sum(flow_pre)), by = orig]
shares_n2 <- merge(pre_bilateral_n2, pre_totals_n2, by = "orig")
shares_n2[, share := flow_pre / total_pre]

dest_pre_n2 <- bilateral_n2[year %in% 2014:2016,
                              .(G_j_pre = sum(flow) / 3), by = dest]
dest_year_n2 <- bilateral_n2[, .(G_jt = sum(flow)), by = .(dest, year)]

bartik_n2_parts <- merge(shares_n2[, .(orig, dest, share, flow_pre)],
                          bilateral_n2[, .(orig, dest, year, flow)],
                          by = c("orig", "dest"), all.x = TRUE, allow.cartesian = TRUE)
bartik_n2_parts[is.na(flow), flow := 0]
bartik_n2_parts <- merge(bartik_n2_parts, dest_year_n2, by = c("dest", "year"), all.x = TRUE)
bartik_n2_parts <- merge(bartik_n2_parts, dest_pre_n2, by = "dest", all.x = TRUE)

bartik_n2_parts[, G_jt_loo := G_jt - flow]
bartik_n2_parts[, g_jt_loo := (G_jt_loo - G_j_pre) / pmax(G_j_pre, 1)]

bartik_n2 <- bartik_n2_parts[, .(bartik_growth = sum(share * g_jt_loo, na.rm = TRUE)),
                              by = .(nuts2 = orig, year)]

# Predicted outflow level
pred_n2 <- merge(bartik_n2,
                  pre_totals_n2[, .(nuts2 = orig, total_pre_annual = total_pre / 3)],
                  by = "nuts2", all.x = TRUE)
pred_n2[, predicted_out := total_pre_annual * (1 + bartik_growth)]

# ---------------------------------------------------------------
# 6. Process Eurostat outcomes (NUTS2)
# ---------------------------------------------------------------
cat("\nProcessing Eurostat NUTS2 outcomes...\n")

educ_nuts2 <- educ[nchar(as.character(geo)) == 4 & grepl("^[A-Z]{2}", geo)]
educ_tert <- educ_nuts2[isced11 == "ED5-8" & sex == "T" & unit == "PC"]

educ_young <- educ_tert[age == "Y25-34",
                         .(nuts2 = as.character(geo),
                           year = as.integer(TIME_PERIOD),
                           tert_share_25_34 = values)]
educ_old <- educ_tert[age == "Y25-64",
                       .(nuts2 = as.character(geo),
                         year = as.integer(TIME_PERIOD),
                         tert_share_25_64 = values)]

emp_nuts2 <- emp[nchar(as.character(geo)) == 4 & grepl("^[A-Z]{2}", geo)]
emp_young <- emp_nuts2[age == "Y25-34" & sex == "T" & unit == "THS_PER",
                        .(nuts2 = as.character(geo),
                          year = as.integer(TIME_PERIOD),
                          emp_25_34 = values)]
emp_older <- emp_nuts2[age == "Y25-64" & sex == "T" & unit == "THS_PER",
                        .(nuts2 = as.character(geo),
                          year = as.integer(TIME_PERIOD),
                          emp_25_64 = values)]

lfp_nuts2 <- lfp[nchar(as.character(geo)) == 4 & grepl("^[A-Z]{2}", geo)]
lfp_young <- lfp_nuts2[age == "Y25-34" & sex == "T" & unit == "THS_PER",
                         .(nuts2 = as.character(geo),
                           year = as.integer(TIME_PERIOD),
                           lfp_25_34 = values)]

gdp_nuts2 <- gdp[nchar(as.character(geo)) == 4 &
                   grepl("^[A-Z]{2}", geo) & unit == "EUR_HAB",
                   .(nuts2 = as.character(geo),
                     year = as.integer(TIME_PERIOD),
                     gdp_pc = values)]

pop_nuts2 <- pop[nchar(as.character(geo)) == 4 & grepl("^[A-Z]{2}", geo)]
pop_youth_n2 <- pop_nuts2[age %in% c("Y20-24", "Y25-29") & sex == "T",
                           .(pop_20_29 = sum(values, na.rm = TRUE)),
                           by = .(nuts2 = as.character(geo),
                                  year = as.integer(TIME_PERIOD))]
pop_total_n2 <- pop_nuts2[age == "TOTAL" & sex == "T",
                           .(nuts2 = as.character(geo),
                             year = as.integer(TIME_PERIOD),
                             pop_total = values)]

# ---------------------------------------------------------------
# 7. Build NUTS2 outflow panel
# ---------------------------------------------------------------
outflows_n2 <- bilateral_n2[, .(total_out = sum(flow)), by = .(nuts2 = orig, year)]
inflows_n2_agg <- bilateral_n2[, .(total_in = sum(flow)), by = .(nuts2 = dest, year)]
flows_n2 <- merge(outflows_n2, inflows_n2_agg, by = c("nuts2", "year"), all = TRUE)
flows_n2[is.na(total_out), total_out := 0]
flows_n2[is.na(total_in), total_in := 0]
flows_n2[, net_out := total_out - total_in]

# ---------------------------------------------------------------
# 8. Assemble NUTS2 panel
# ---------------------------------------------------------------
cat("\nAssembling NUTS2 panel...\n")

panel_n2 <- merge(flows_n2, bartik_n2[, .(nuts2, year, bartik_growth)],
                   by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, pred_n2[, .(nuts2, year, predicted_out)],
                   by = c("nuts2", "year"), all.x = TRUE)

# Also merge NUTS3-aggregated Bartik
panel_n2 <- merge(panel_n2, bartik_n2_from_n3, by = c("nuts2", "year"), all.x = TRUE)

panel_n2 <- merge(panel_n2, educ_young, by = c("nuts2", "year"), all = FALSE)
panel_n2 <- merge(panel_n2, educ_old, by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, emp_young, by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, emp_older, by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, lfp_young, by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, gdp_nuts2, by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, pop_youth_n2, by = c("nuts2", "year"), all.x = TRUE)
panel_n2 <- merge(panel_n2, pop_total_n2, by = c("nuts2", "year"), all.x = TRUE)

# Compute rates
panel_n2[pop_20_29 > 0, out_rate := total_out / (pop_20_29 / 1000)]
panel_n2[pop_20_29 > 0, net_out_rate := net_out / (pop_20_29 / 1000)]
panel_n2[pop_20_29 > 0, predicted_out_rate := predicted_out / (pop_20_29 / 1000)]
panel_n2[pop_20_29 > 0, in_rate := total_in / (pop_20_29 / 1000)]

# Also predicted from NUTS3-aggregated Bartik
panel_n2[, predicted_out_n3 := pre_totals_n2[match(panel_n2$nuts2,
                                                     pre_totals_n2$orig), total_pre] / 3 *
                                 (1 + bartik_growth_n3agg)]
panel_n2[pop_20_29 > 0, predicted_out_rate_n3 := predicted_out_n3 / (pop_20_29 / 1000)]

panel_n2[, country := substr(nuts2, 1, 2)]
panel_n2[gdp_pc > 0, log_gdp_pc := log(gdp_pc)]

# Pre-period outflow rates for growth calculation
out_rate_pre <- panel_n2[year %in% 2014:2016,
                          .(out_rate_pre = mean(out_rate, na.rm = TRUE)),
                          by = nuts2]
panel_n2 <- merge(panel_n2, out_rate_pre, by = "nuts2", all.x = TRUE)
panel_n2[, out_growth := (out_rate - out_rate_pre) / pmax(out_rate_pre, 0.01)]

cat("NUTS2 panel:", nrow(panel_n2), "rows,",
    length(unique(panel_n2$nuts2)), "regions\n")

# ---------------------------------------------------------------
# 9. Build Census long-difference (NUTS2)
# ---------------------------------------------------------------
cat("\nBuilding Census long-difference...\n")

# Use Census 2011 and 2021 education at NUTS2 if available
census_cross <- NULL

if (!is.null(cens11_educ) && !is.null(cens21_educ)) {
  cat("  Processing Census 2011 education (NUTS2)...\n")
  cat("  Census 2011 columns:", paste(names(cens11_educ), collapse = ", "), "\n")
  cat("  Census 2021 columns:", paste(names(cens21_educ), collapse = ", "), "\n")

  # Process Census 2011 education at NUTS2
  # cens_11aed_r2: Population by current activity status, education, NUTS2
  cens11_n2 <- cens11_educ[nchar(as.character(geo)) == 4 & grepl("^[A-Z]{2}", geo)]

  cat("  Census 2011 ISCED levels:", paste(unique(cens11_n2$isced11), collapse = ", "), "\n")
  cat("  Census 2011 age groups:", paste(unique(cens11_n2$age), collapse = ", "), "\n")

  # Process Census 2021 education at NUTS2
  cens21_n2 <- cens21_educ[nchar(as.character(geo)) == 4 & grepl("^[A-Z]{2}", geo)]

  cat("  Census 2021 ISCED levels:", paste(unique(cens21_n2$isced11), collapse = ", "), "\n")
  cat("  Census 2021 age groups:", paste(unique(cens21_n2$age), collapse = ", "), "\n")

  # Will continue processing in analysis scripts based on column structure
}

# Also construct long-difference from LFS (edat_lfse_04)
cat("  Building LFS-based long-difference (2014 vs 2022)...\n")

pre_means <- panel_n2[year %in% 2014:2016,
                       .(tert_pre = mean(tert_share_25_34, na.rm = TRUE),
                         tert_old_pre = mean(tert_share_25_64, na.rm = TRUE),
                         out_rate_pre_cs = mean(out_rate, na.rm = TRUE),
                         net_out_pre = mean(net_out_rate, na.rm = TRUE),
                         gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)),
                       by = nuts2]

post_means <- panel_n2[year %in% 2021:2022,
                        .(tert_post = mean(tert_share_25_34, na.rm = TRUE),
                          tert_old_post = mean(tert_share_25_64, na.rm = TRUE),
                          out_rate_post = mean(out_rate, na.rm = TRUE),
                          net_out_post = mean(net_out_rate, na.rm = TRUE),
                          bartik_post = mean(bartik_growth, na.rm = TRUE),
                          bartik_n3_post = mean(bartik_growth_n3agg, na.rm = TRUE)),
                        by = nuts2]

cross_n2 <- merge(pre_means, post_means, by = "nuts2")
cross_n2[, country := substr(nuts2, 1, 2)]
cross_n2[, delta_tert := tert_post - tert_pre]
cross_n2[, delta_tert_old := tert_old_post - tert_old_pre]
cross_n2[, delta_out := out_rate_post - out_rate_pre_cs]
cross_n2[, delta_net_out := net_out_post - net_out_pre]
cross_n2[gdp_pc_pre > 0, log_gdp_pre := log(gdp_pc_pre)]

gdp_median_n2 <- median(cross_n2$gdp_pc_pre, na.rm = TRUE)
cross_n2[, peripheral := as.integer(gdp_pc_pre < gdp_median_n2)]

cat("NUTS2 cross-section:", nrow(cross_n2), "regions\n")

# ---------------------------------------------------------------
# 10. Build NUTS3 cross-section (for diagnostic and population outcome)
# ---------------------------------------------------------------
cat("\nBuilding NUTS3 cross-section...\n")

# NUTS3 population outcome: change in youth share (25-34 / total)
pop_youth_25_34 <- pop[nchar(as.character(geo)) == 5 & grepl("^[A-Z]{2}", geo) &
                         age %in% c("Y25-29", "Y30-34") & sex == "T",
                         .(pop_25_34 = sum(values, na.rm = TRUE)),
                         by = .(nuts3 = as.character(geo),
                                year = as.integer(TIME_PERIOD))]

pop_total_n3 <- pop[nchar(as.character(geo)) == 5 & grepl("^[A-Z]{2}", geo) &
                      age == "TOTAL" & sex == "T",
                      .(pop_total = sum(values, na.rm = TRUE)),
                       by = .(nuts3 = as.character(geo),
                              year = as.integer(TIME_PERIOD))]

pop_n3_merged <- merge(pop_youth_25_34, pop_total_n3, by = c("nuts3", "year"))
pop_n3_merged[pop_total > 0, youth_share_25_34 := 100 * pop_25_34 / pop_total]

# Pre and post youth share
pre_youth <- pop_n3_merged[year %in% 2014:2016,
                            .(youth_share_pre = mean(youth_share_25_34, na.rm = TRUE),
                              pop_total_pre = mean(pop_total, na.rm = TRUE)),
                            by = nuts3]
post_youth <- pop_n3_merged[year %in% 2020:2022,
                              .(youth_share_post = mean(youth_share_25_34, na.rm = TRUE)),
                              by = nuts3]

# Average Bartik and flows
bartik_n3_avg <- bartik_n3[year %in% 2014:2022,
                            .(bartik_avg = mean(bartik_growth, na.rm = TRUE)),
                            by = nuts3]
flows_n3_avg <- flows_n3[year %in% 2014:2022,
                          .(mean_out = mean(total_out, na.rm = TRUE),
                            mean_net_out = mean(net_out, na.rm = TRUE)),
                          by = nuts3]
pop_n3_avg <- pop_youth_n3[year %in% 2014:2019,
                            .(pop_20_29_avg = mean(pop_20_29, na.rm = TRUE)),
                            by = nuts3]

# GDP at NUTS3
gdp_nuts3 <- gdp[nchar(as.character(geo)) == 5 &
                   grepl("^[A-Z]{2}", geo) & unit == "EUR_HAB",
                   .(nuts3 = as.character(geo),
                     year = as.integer(TIME_PERIOD),
                     gdp_pc = values)]
gdp_n3_avg <- gdp_nuts3[year %in% 2013:2016,
                          .(gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)),
                          by = nuts3]

# Assemble NUTS3 cross-section
nuts3_cross <- merge(pre_youth, post_youth, by = "nuts3", all = FALSE)
nuts3_cross[, delta_youth_share := youth_share_post - youth_share_pre]
nuts3_cross <- merge(nuts3_cross, bartik_n3_avg, by = "nuts3", all.x = TRUE)
nuts3_cross <- merge(nuts3_cross, flows_n3_avg, by = "nuts3", all.x = TRUE)
nuts3_cross <- merge(nuts3_cross, pop_n3_avg, by = "nuts3", all.x = TRUE)
nuts3_cross <- merge(nuts3_cross, gdp_n3_avg, by = "nuts3", all.x = TRUE)
nuts3_cross <- merge(nuts3_cross, pre_total_annual, by = "nuts3", all.x = TRUE)

# Compute rates
nuts3_cross[pop_20_29_avg > 0, out_rate := mean_out / (pop_20_29_avg / 1000)]
nuts3_cross[pop_20_29_avg > 0, net_out_rate := mean_net_out / (pop_20_29_avg / 1000)]

# Predicted outflow rate
nuts3_cross[pop_20_29_avg > 0 & !is.na(total_pre_annual) & !is.na(bartik_avg),
            predicted_out_rate := (total_pre_annual * (1 + bartik_avg * 9)) /
                                   (pop_20_29_avg / 1000)]

nuts3_cross[, country := substr(nuts3, 1, 2)]
nuts3_cross[, nuts2 := substr(nuts3, 1, 4)]
nuts3_cross[gdp_pc_pre > 0, log_gdp_pre := log(gdp_pc_pre)]

gdp_median_n3 <- median(nuts3_cross$gdp_pc_pre, na.rm = TRUE)
nuts3_cross[, peripheral := as.integer(gdp_pc_pre < gdp_median_n3)]

cat("NUTS3 cross-section:", nrow(nuts3_cross), "regions\n")
cat("  With youth share change:", sum(!is.na(nuts3_cross$delta_youth_share)), "\n")
cat("  With Bartik:", sum(!is.na(nuts3_cross$bartik_avg)), "\n")
cat("  Countries:", length(unique(nuts3_cross$country)), "\n")

# ---------------------------------------------------------------
# 11. Save all datasets
# ---------------------------------------------------------------
fwrite(nuts3_cross, file.path(data_dir, "nuts3_cross_section.csv"))
fwrite(panel_n2, file.path(data_dir, "nuts2_panel.csv"))
fwrite(panel_n3, file.path(data_dir, "nuts3_panel.csv"))
fwrite(cross_n2, file.path(data_dir, "nuts2_cross_section.csv"))
fwrite(bilateral_n3, file.path(data_dir, "bilateral_nuts3_flows.csv"))
fwrite(bilateral_n2, file.path(data_dir, "bilateral_nuts2_flows.csv"))
fwrite(shares_n3, file.path(data_dir, "pre_period_shares_nuts3.csv"))
fwrite(shares_n2, file.path(data_dir, "pre_period_shares_nuts2.csv"))
fwrite(bartik_n3, file.path(data_dir, "bartik_nuts3_annual.csv"))

cat("\n=== ALL DATASETS SAVED ===\n")
cat("NUTS3 cross-section:", nrow(nuts3_cross), "\n")
cat("NUTS2 panel:", nrow(panel_n2), "\n")
cat("NUTS2 cross-section:", nrow(cross_n2), "\n")
cat("NUTS3 panel:", nrow(panel_n3), "\n")
