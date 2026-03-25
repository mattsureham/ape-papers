## 05_tables.R — Generate all tables for apep_0954
## Beirut Port Explosion and Food Prices

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

dt <- fread(file.path(data_dir, "panel_main.csv"))
dt[, ym := as.Date(ym)]
dt[, mc_fe := paste0(market, "_", commodity)]
dt[, ct_fe := paste0(commodity, "_", as.character(ym))]
dt[, mt_fe := paste0(market, "_", as.character(ym))]
dt[, bp_post := beirut_proximity * post]

geo <- fread(file.path(data_dir, "markets_geocoded.csv"))

# Balanced panel: only commodities with both pre and post
pre_commod <- unique(dt[post == 0, commodity])
post_commod <- unique(dt[post == 1, commodity])
both_commod <- intersect(pre_commod, post_commod)
dt_bal <- dt[commodity %in% both_commod]
dt_bal[, mc_fe := paste0(market, "_", commodity)]
dt_bal[, ct_fe := paste0(commodity, "_", as.character(ym))]
dt_bal[, mt_fe := paste0(market, "_", as.character(ym))]
dt_bal[, bp_post := beirut_proximity * post]

# ---- TABLE 1: Summary Statistics ----
cat("=== TABLE 1: Summary Statistics ===\n")

# Pre-explosion statistics
pre <- dt_bal[post == 0]
post_d <- dt_bal[post == 1]

# Panel A: Market characteristics
mkt_stats <- geo[, .(
  dist_beirut = round(mean(dist_beirut_km), 1),
  dist_tripoli = round(mean(dist_tripoli_km), 1),
  proximity = round(mean(beirut_proximity), 3)
)]

# Panel B: Price statistics by period and commodity type
make_stats <- function(d, label) {
  data.table(
    Period = label,
    N = nrow(d),
    Markets = uniqueN(d$market),
    Commodities = uniqueN(d$commodity),
    `Mean LBP` = round(mean(d$price_lbp)),
    `SD LBP` = round(sd(d$price_lbp)),
    `Mean USD` = round(mean(d$price_usd, na.rm = TRUE), 2),
    `SD USD` = round(sd(d$price_usd, na.rm = TRUE), 2)
  )
}

stats <- rbind(
  make_stats(pre, "Pre-explosion (2019--2020m7)"),
  make_stats(post_d, "Post-explosion (2020m8--2021)"),
  make_stats(pre[imported == 1], "Pre: Imported"),
  make_stats(post_d[imported == 1], "Post: Imported"),
  make_stats(pre[local == 1], "Pre: Local"),
  make_stats(post_d[local == 1], "Post: Local")
)

cat("\nSummary statistics:\n")
print(stats)

# Write Table 1 as LaTeX
tab1 <- kbl(stats, format = "latex", booktabs = TRUE, linesep = "",
            caption = "Summary Statistics",
            label = "tab:summary") |>
  kable_styling(latex_options = "hold_position") |>
  pack_rows("Full Sample", 1, 2) |>
  pack_rows("Imported Commodities", 3, 4) |>
  pack_rows("Local Commodities", 5, 6)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ---- TABLE 2: Main DiD Results ----
cat("\n=== TABLE 2: Main Results ===\n")

# Run models fresh for table
m1 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt_bal, cluster = ~market)

m2 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt_bal[imported == 1], cluster = ~market)

m3 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt_bal[local == 1], cluster = ~market)

# Short window (Aug-Dec 2020)
dt_short <- dt_bal[ym <= "2020-12-31"]
dt_short[, bp_post_s := beirut_proximity * post]
m4 <- feols(log_price ~ bp_post_s | mc_fe + ct_fe,
            data = dt_short[imported == 1], cluster = ~market)

# Excluding Beirut
m5 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt_bal[market != "Beirut" & imported == 1], cluster = ~market)

models <- list(
  "All" = m1,
  "Imported" = m2,
  "Local" = m3,
  "Short window" = m4,
  "Excl. Beirut" = m5
)

# Generate LaTeX table using fixest::etable
setFixest_dict(c(bp_post = "Beirut Proximity $\\times$ Post",
                 bp_post_s = "Beirut Proximity $\\times$ Post",
                 mc_fe = "Market $\\times$ Commodity",
                 ct_fe = "Commodity $\\times$ Time"))

etable(m1, m2, m3, m4, m5,
       headers = c("All", "Imported", "Local", "Short Window", "Excl. Beirut"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "wr2"),
       file = file.path(tables_dir, "tab2_main.tex"),
       replace = TRUE,
       label = "tab:main",
       title = "Effect of Beirut Proximity on Food Prices")
cat("Table 2 written.\n")

# ---- TABLE 3: Triple-Difference ----
cat("\n=== TABLE 3: Triple-Difference ===\n")

dt_td <- dt_bal[commodity_type != "ambiguous"]
dt_td[, bp_imp_post := beirut_proximity * imported * post]
dt_td[, bp_post_td := beirut_proximity * post]
dt_td[, mc_fe := paste0(market, "_", commodity)]
dt_td[, ct_fe := paste0(commodity, "_", as.character(ym))]
dt_td[, mt_fe := paste0(market, "_", as.character(ym))]

m_td1 <- feols(log_price ~ bp_imp_post + bp_post_td | mc_fe + ct_fe,
               data = dt_td, cluster = ~market)

m_td2 <- feols(log_price ~ bp_imp_post | mc_fe + mt_fe + ct_fe,
               data = dt_td, cluster = ~market)

# Short window triple-diff
dt_td_s <- dt_td[ym <= "2020-12-31"]
dt_td_s[, bp_imp_post := beirut_proximity * imported * post]
m_td3 <- feols(log_price ~ bp_imp_post | mc_fe + mt_fe + ct_fe,
               data = dt_td_s, cluster = ~market)

models_td <- list(
  "DDD (1)" = m_td1,
  "DDD (2)" = m_td2,
  "DDD Short" = m_td3
)

setFixest_dict(c(bp_imp_post = "Proximity $\\times$ Imported $\\times$ Post",
                 bp_post_td = "Proximity $\\times$ Post",
                 mc_fe = "Market $\\times$ Commodity",
                 ct_fe = "Commodity $\\times$ Time",
                 mt_fe = "Market $\\times$ Time"))

etable(m_td1, m_td2, m_td3,
       headers = c("DDD (1)", "DDD Saturated", "DDD Short Window"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "wr2"),
       file = file.path(tables_dir, "tab3_triple.tex"),
       replace = TRUE,
       label = "tab:triple",
       title = "Triple-Difference: Imported vs.\\ Local Commodities")
cat("Table 3 written.\n")

# ---- TABLE 4: Distance Bins ----
cat("\n=== TABLE 4: Distance Bins ===\n")

dt_bal[, dist_bin := cut(dist_beirut_km, breaks = c(0, 20, 40, 60, 100),
                         labels = c("0_20km", "20_40km", "40_60km", "60_100km"),
                         include.lowest = TRUE)]

m_bin1 <- feols(log_price ~ i(dist_bin, post, ref = "60_100km") | mc_fe + ct_fe,
                data = dt_bal, cluster = ~market)

m_bin2 <- feols(log_price ~ i(dist_bin, post, ref = "60_100km") | mc_fe + ct_fe,
                data = dt_bal[imported == 1], cluster = ~market)

etable(m_bin1, m_bin2,
       headers = c("All", "Imported"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "wr2"),
       file = file.path(tables_dir, "tab4_distance.tex"),
       replace = TRUE,
       label = "tab:distance",
       title = "Distance Gradient: Price Effects by Distance from Beirut Port")
cat("Table 4 written.\n")

# ---- TABLE F1: Standardized Effect Sizes (SDE) ----
cat("\n=== TABLE F1: SDE ===\n")

# Compute SDE for main specifications
# SDE = β / SD(Y) for binary treatment
# Here treatment is continuous (0-1), so SDE = β × SD(X) / SD(Y)
# But since BeirutProximity × Post is the treatment and proximity is continuous,
# we use: SDE = β × SD(BeirutProximity) / SD(log_price) in pre-period

sd_prox <- sd(dt_bal$beirut_proximity)
sd_y_pre <- sd(dt_bal[post == 0, log_price])
sd_y_pre_imp <- sd(dt_bal[post == 0 & imported == 1, log_price])
sd_y_pre_loc <- sd(dt_bal[post == 0 & local == 1, log_price])

# Short window
sd_y_pre_short <- sd(dt_short[post == 0 & imported == 1, log_price])

# Results table
sde_results <- data.table(
  Outcome = c(
    "Log price (all commodities)",
    "Log price (imported)",
    "Log price (local, placebo)",
    "Log price (imported, short window)",
    "Log price (imported, excl. Beirut)",
    "Log price (DDD: imported vs local)"
  ),
  beta = c(coef(m1)["bp_post"], coef(m2)["bp_post"], coef(m3)["bp_post"],
           coef(m4)["bp_post_s"], coef(m5)["bp_post"],
           coef(m_td2)["bp_imp_post"]),
  se = c(se(m1)["bp_post"], se(m2)["bp_post"], se(m3)["bp_post"],
         se(m4)["bp_post_s"], se(m5)["bp_post"],
         se(m_td2)["bp_imp_post"]),
  sd_y = c(sd_y_pre, sd_y_pre_imp, sd_y_pre_loc,
           sd_y_pre_short, sd_y_pre_imp, sd_y_pre_imp)
)

sde_results[, SDE := beta * sd_prox / sd_y]
sde_results[, SE_SDE := se * sd_prox / sd_y]

# Classification
sde_results[, Classification := fcase(
  SDE < -0.15, "Large negative",
  SDE < -0.05, "Moderate negative",
  SDE < -0.005, "Small negative",
  SDE <= 0.005, "Null",
  SDE <= 0.05, "Small positive",
  SDE <= 0.15, "Moderate positive",
  default = "Large positive"
)]

cat("\nSDE Results:\n")
print(sde_results[, .(Outcome, beta = round(beta, 4), se = round(se, 4),
                       sd_y = round(sd_y, 4), SDE = round(SDE, 4),
                       SE_SDE = round(SE_SDE, 4), Classification)])

# Write SDE table
sde_tab <- sde_results[, .(
  Outcome,
  `$\\hat{\\beta}$` = sprintf("%.4f", beta),
  SE = sprintf("%.4f", se),
  `SD($Y$)` = sprintf("%.4f", sd_y),
  SDE = sprintf("%.4f", SDE),
  `SE(SDE)` = sprintf("%.4f", SE_SDE),
  Classification
)]

# SDE Notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Lebanon. ",
  "\\textbf{Research question:} Does the destruction of a country's primary port ",
  "differentially affect food prices in markets dependent on that port versus markets ",
  "closer to an alternative port? ",
  "\\textbf{Policy mechanism:} The August 4, 2020 Beirut port explosion destroyed ",
  "Lebanon's only grain silos and severely damaged port infrastructure that handled ",
  "approximately 70\\% of national imports, forcing rerouting to the smaller Port of Tripoli. ",
  "\\textbf{Outcome definition:} Log monthly food commodity price in Lebanese Pounds (LBP), ",
  "from WFP VAM monitoring across 27 markets covering all Lebanese governorates. ",
  "\\textbf{Treatment:} Continuous Beirut Proximity index (distance to Tripoli / total distance ",
  "to both ports), ranging from 0.016 (Tripoli) to 0.971 (Beirut). ",
  "\\textbf{Data:} WFP Humanitarian Data Exchange food price monitoring, January 2019--December 2021, ",
  "27 markets, 14 commodities in balanced panel, 6,165 market-commodity-month observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with market$\\times$commodity and commodity$\\times$time FE; ",
  "triple-difference adds market$\\times$time FE and imported/local commodity distinction; standard errors ",
  "clustered at market level. ",
  "\\textbf{Sample:} Balanced panel of commodities observed both before and after the explosion; ",
  "main window January 2019 to December 2021; short window restricts post-period to August--December 2020. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of Beirut Proximity. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table manually for SDE
sde_latex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  paste0(sde_tab[1, paste(unlist(.SD), collapse = " & ")], " \\\\"),
  paste0(sde_tab[2, paste(unlist(.SD), collapse = " & ")], " \\\\"),
  paste0(sde_tab[3, paste(unlist(.SD), collapse = " & ")], " \\\\"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  paste0(sde_tab[4, paste(unlist(.SD), collapse = " & ")], " \\\\"),
  paste0(sde_tab[5, paste(unlist(.SD), collapse = " & ")], " \\\\"),
  paste0(sde_tab[6, paste(unlist(.SD), collapse = " & ")], " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_latex, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table written.\n")

# ---- Update diagnostics with final counts ----
# Continuous treatment: all 26 markets have non-zero Beirut proximity
# n_treated = all markets (continuous design, not binary)
diag <- list(
  n_treated = uniqueN(dt_bal$market),
  n_pre = uniqueN(dt_bal[post == 0, ym]),
  n_obs = nrow(dt_bal),
  n_markets = uniqueN(dt_bal$market),
  n_commodities = uniqueN(dt_bal$commodity)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\nAll tables generated.\n")
