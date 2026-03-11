# =============================================================================
# 02b_rebuild_instrument.R — Restructure Bartik IV with proper scaling
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
bilateral <- fread(file.path(data_dir, "bilateral_nuts2_flows.csv"))
panel_old <- fread(file.path(data_dir, "analysis_panel.csv"))

# ---------------------------------------------------------------
# 1. Construct shift-share using growth rates (standard Bartik)
# ---------------------------------------------------------------

# Pre-period bilateral shares (2014-2016)
pre_bilateral <- bilateral[year %in% 2014:2016,
                           .(flow_pre = sum(flow)), by = .(orig, dest)]
pre_totals <- pre_bilateral[, .(total_pre = sum(flow_pre)), by = orig]
shares <- merge(pre_bilateral, pre_totals, by = "orig")
shares[, share := flow_pre / total_pre]

# Pre-period destination totals
dest_pre <- bilateral[year %in% 2014:2016,
                      .(G_j_pre = sum(flow) / 3), by = dest]  # annual average

# Destination inflows by year (leave-one-out)
dest_year <- bilateral[, .(G_jt = sum(flow)), by = .(dest, year)]

# For each origin-dest pair, compute LOO destination growth
bartik_parts <- merge(shares[, .(orig, dest, share, flow_pre)],
                      bilateral[, .(orig, dest, year, flow)],
                      by = c("orig", "dest"), all.x = TRUE, allow.cartesian = TRUE)
bartik_parts[is.na(flow), flow := 0]
bartik_parts <- merge(bartik_parts, dest_year, by = c("dest", "year"), all.x = TRUE)
bartik_parts <- merge(bartik_parts, dest_pre, by = "dest", all.x = TRUE)

# LOO destination inflow
bartik_parts[, G_jt_loo := G_jt - flow]

# LOO destination growth rate: (G_{j,t} - G_{j,pre}) / G_{j,pre}
# Using pre-period annual average as base
bartik_parts[, g_jt_loo := (G_jt_loo - G_j_pre) / pmax(G_j_pre, 1)]

# Bartik IV = Σ_j share_{ij} × growth_rate_{j,t}  (leave-one-out)
bartik_growth <- bartik_parts[, .(bartik_growth = sum(share * g_jt_loo, na.rm = TRUE)),
                              by = .(nuts2 = orig, year)]

cat("Bartik growth IV computed:", nrow(bartik_growth), "rows\n")
cat("  Mean:", mean(bartik_growth$bartik_growth, na.rm = TRUE), "\n")
cat("  SD:", sd(bartik_growth$bartik_growth, na.rm = TRUE), "\n")

# ---------------------------------------------------------------
# 2. Also compute predicted outflow (level, properly scaled)
# ---------------------------------------------------------------
# Predicted outflow = F_{i,pre} * (1 + bartik_growth)
# This directly predicts what outflows would be if bilateral structure held
pre_total_merged <- merge(bartik_growth,
                          pre_totals[, .(nuts2 = orig, total_pre_annual = total_pre / 3)],
                          by = "nuts2", all.x = TRUE)
pre_total_merged[, predicted_out := total_pre_annual * (1 + bartik_growth)]

# ---------------------------------------------------------------
# 3. Merge into panel
# ---------------------------------------------------------------
panel <- copy(panel_old)

# Remove old Bartik columns
if ("bartik_iv" %in% names(panel)) panel[, bartik_iv := NULL]
if ("bartik_rate" %in% names(panel)) panel[, bartik_rate := NULL]

# Merge new instrument
panel <- merge(panel, bartik_growth[, .(nuts2, year, bartik_growth)],
               by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, pre_total_merged[, .(nuts2, year, predicted_out)],
               by = c("nuts2", "year"), all.x = TRUE)

# Scale predicted outflow by population (same as out_rate)
panel[, predicted_out_rate := predicted_out / (pop_20_29 / 1000)]

# Also compute outflow growth rate as the endogenous variable
outflow_pre_avg <- panel[year %in% 2014:2016,
                         .(out_rate_pre = mean(out_rate, na.rm = TRUE)),
                         by = nuts2]
panel <- merge(panel, outflow_pre_avg, by = "nuts2", all.x = TRUE)
panel[, out_growth := (out_rate - out_rate_pre) / pmax(out_rate_pre, 0.01)]

cat("\nNew variable distributions:\n")
cat("bartik_growth: mean=", mean(panel$bartik_growth, na.rm=TRUE),
    " sd=", sd(panel$bartik_growth, na.rm=TRUE), "\n")
cat("out_growth: mean=", mean(panel$out_growth, na.rm=TRUE),
    " sd=", sd(panel$out_growth, na.rm=TRUE), "\n")
cat("out_rate: mean=", mean(panel$out_rate, na.rm=TRUE),
    " sd=", sd(panel$out_rate, na.rm=TRUE), "\n")
cat("predicted_out_rate: mean=", mean(panel$predicted_out_rate, na.rm=TRUE),
    " sd=", sd(panel$predicted_out_rate, na.rm=TRUE), "\n")

# ---------------------------------------------------------------
# 4. Rebuild cross-section
# ---------------------------------------------------------------
pre_means <- panel[year %in% 2014:2019,
                   .(tert_pre = mean(tert_share_25_34, na.rm = TRUE),
                     tert_old_pre = mean(tert_share_25_64, na.rm = TRUE),
                     out_rate_pre_cs = mean(out_rate, na.rm = TRUE),
                     net_out_rate_pre = mean(net_out_rate, na.rm = TRUE),
                     gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)),
                   by = nuts2]

post_means <- panel[year %in% 2021:2022,
                    .(tert_post = mean(tert_share_25_34, na.rm = TRUE),
                      tert_old_post = mean(tert_share_25_64, na.rm = TRUE),
                      out_rate_post = mean(out_rate, na.rm = TRUE),
                      net_out_rate_post = mean(net_out_rate, na.rm = TRUE),
                      bartik_growth_post = mean(bartik_growth, na.rm = TRUE)),
                    by = nuts2]

cross <- merge(pre_means, post_means, by = "nuts2")
cross[, country := substr(nuts2, 1, 2)]
cross[, delta_tert := tert_post - tert_pre]
cross[, delta_tert_old := tert_old_post - tert_old_pre]
cross[, delta_out := out_rate_post - out_rate_pre_cs]
cross[, delta_net_out := net_out_rate_post - net_out_rate_pre]

cat("\nCross-section:", nrow(cross), "regions\n")

# ---------------------------------------------------------------
# 5. Save updated datasets
# ---------------------------------------------------------------
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(cross, file.path(data_dir, "analysis_cross_section.csv"))

cat("\n=== INSTRUMENT REBUILD COMPLETE ===\n")

# Quick first stage check
library(fixest)

# Panel: outflow rate ~ bartik growth
fs1 <- feols(out_rate ~ bartik_growth | nuts2 + year,
             data = panel[!is.na(bartik_growth) & !is.na(out_rate)],
             cluster = ~nuts2)
cat("\nFirst stage (panel, outflow ~ bartik_growth):\n")
print(summary(fs1))

# Panel: net outflow ~ bartik growth
fs2 <- feols(net_out_rate ~ bartik_growth | nuts2 + year,
             data = panel[!is.na(bartik_growth) & !is.na(net_out_rate)],
             cluster = ~nuts2)
cat("\nFirst stage (panel, net_outflow ~ bartik_growth):\n")
print(summary(fs2))

# Cross-section check
fs3 <- feols(delta_out ~ bartik_growth_post | country,
             data = cross[!is.na(bartik_growth_post) & !is.na(delta_out)])
cat("\nFirst stage (cross-section, delta_out ~ bartik_growth_post):\n")
print(summary(fs3))

# Panel: predicted outflow rate (levels)
fs4 <- feols(out_rate ~ predicted_out_rate | nuts2 + year,
             data = panel[!is.na(predicted_out_rate) & !is.na(out_rate)],
             cluster = ~nuts2)
cat("\nFirst stage (panel, out_rate ~ predicted_out_rate):\n")
print(summary(fs4))
