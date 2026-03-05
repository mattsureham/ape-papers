# ==============================================================================
# 06_tables.R — All table generation (LaTeX)
# apep_0532: Extreme Weather and Climate Beliefs in India
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tbl_dir <- "../tables"
dir.create(tbl_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("Table 1: Summary Statistics\n")

sumstats <- fread(file.path(data_dir, "summary_stats.csv"))

# Format for LaTeX
sumstats_tex <- sumstats[Variable %in% c("climate_search", "placebo_search",
  "tavg_anomaly", "precip_anomaly", "heat_extreme", "drought",
  "ag_share", "internet_pen_2015")]

sumstats_tex[, Variable := fcase(
  Variable == "climate_search", "Climate Search Index",
  Variable == "placebo_search", "Placebo Search Index",
  Variable == "tavg_anomaly", "Temperature Anomaly (\\degree C)",
  Variable == "precip_anomaly", "Precipitation Anomaly (mm)",
  Variable == "heat_extreme", "Heat Extreme ($z > 1.5$)",
  Variable == "drought", "Drought ($z < -1.5$)",
  Variable == "ag_share", "Agricultural Share",
  Variable == "internet_pen_2015", "Internet Penetration (per 100)"
)]

writeLines(
  kbl(sumstats_tex, format = "latex", booktabs = TRUE,
      caption = "Summary Statistics",
      label = "tab:sumstats",
      col.names = c("Variable", "N", "Mean", "SD", "Min", "P25", "Median", "P75", "Max"),
      escape = FALSE) |>
    kable_styling(latex_options = c("hold_position")) |>
    footnote(general = "Panel of 22 Indian states observed monthly from 2004 to 2023 (5,280 state-month observations). Climate Search Index is the average Google Trends index for ``global warming'' and ``climate change.'' Temperature and precipitation anomalies are deviations from 1981--2000 normals. Agricultural Share is the pre-period (triennium ending 2000) share of cultivated area under major crops.",
             threeparttable = TRUE, escape = FALSE),
  file.path(tbl_dir, "table1_sumstats.tex")
)

# ==============================================================================
# Table 2: Main OLS Results
# ==============================================================================
cat("Table 2: Main OLS\n")

m1 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)
m2 <- feols(climate_search ~ tavg_anomaly + precip_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)
m3 <- feols(climate_search ~ heat_extreme + drought + flood | state_id + time_id,
            data = panel, cluster = ~state_id)
m4 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)
m5 <- feols(log_climate ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

cm <- c("tavg_anomaly" = "Temperature Anomaly",
        "precip_anomaly" = "Precipitation Anomaly",
        "heat_extreme" = "Heat Extreme",
        "drought" = "Drought",
        "flood" = "Flood",
        "tavg_x_ag" = "Temp. Anom. $\\times$ Ag. Share")

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 4),
  list("raw" = "FE: state_id", "clean" = "State FE", "fmt" = 0),
  list("raw" = "FE: time_id", "clean" = "Month-Year FE", "fmt" = 0)
)

modelsummary(list("(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5),
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = cm,
             gof_map = gm,
             output = file.path(tbl_dir, "table2_ols.tex"),
             title = "Temperature Anomalies and Climate Search Interest",
             notes = list("Standard errors clustered at the state level in parentheses.",
                          "Columns (4)--(5) include interaction of temperature anomaly with pre-period agricultural share."),
             escape = FALSE)

# ==============================================================================
# Table 3: Bartik IV
# ==============================================================================
cat("Table 3: Bartik IV\n")

iv1 <- feols(climate_search ~ 1 | state_id + time_id |
               tavg_anomaly ~ bartik_tavg,
             data = panel, cluster = ~state_id)
iv2 <- feols(climate_search ~ 1 | state_id + time_id |
               tavg_anomaly + precip_anomaly ~ bartik_tavg + bartik_precip,
             data = panel, cluster = ~state_id)

modelsummary(list("OLS" = m1, "IV (Temp)" = iv1, "IV (Both)" = iv2),
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c("tavg_anomaly" = "Temperature Anomaly",
                          "fit_tavg_anomaly" = "Temperature Anomaly (IV)",
                          "precip_anomaly" = "Precipitation Anomaly",
                          "fit_precip_anomaly" = "Precipitation Anomaly (IV)"),
             gof_map = gm,
             output = file.path(tbl_dir, "table3_iv.tex"),
             title = "Bartik IV: Crop-Share-Weighted National Weather as Instrument",
             notes = list("Bartik instrument: $B_{it} = \\sum_k s_{ik} \\times g_{kt}$ where $s_{ik}$ is state $i$'s pre-period share of area under crop $k$ and $g_{kt}$ is leave-one-out national weather anomaly for crop $k$'s growing season.",
                          "Standard errors clustered at the state level."),
             escape = FALSE)

# ==============================================================================
# Table 4: Placebo Tests
# ==============================================================================
cat("Table 4: Placebo\n")

p1 <- feols(placebo_search ~ tavg_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)
p2 <- feols(climate_search ~ tavg_lead1 | state_id + time_id,
            data = panel[!is.na(tavg_lead1)], cluster = ~state_id)

modelsummary(list("Climate Search" = m1, "Placebo (Cricket/Bollywood)" = p1,
                  "Lead Temperature" = p2),
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c("tavg_anomaly" = "Temperature Anomaly",
                          "tavg_lead1" = "Temperature Anomaly ($t+1$)"),
             gof_map = gm,
             output = file.path(tbl_dir, "table4_placebo.tex"),
             title = "Placebo Tests",
             notes = list("Column (1) reproduces baseline. Column (2) uses non-climate search terms (cricket, Bollywood) as outcome. Column (3) uses 1-month lead temperature as treatment.",
                          "Standard errors clustered at the state level."),
             escape = FALSE)

# ==============================================================================
# Table 5: Heterogeneity
# ==============================================================================
cat("Table 5: Heterogeneity\n")

panel[, high_internet := as.integer(internet_pen_2015 > median(internet_pen_2015, na.rm = TRUE))]
panel[, high_ag := as.integer(ag_share > median(ag_share, na.rm = TRUE))]

h1 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_internet == 1], cluster = ~state_id)
h2 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_internet == 0], cluster = ~state_id)
h3 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_ag == 1], cluster = ~state_id)
h4 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_ag == 0], cluster = ~state_id)

modelsummary(list("High Internet" = h1, "Low Internet" = h2,
                  "High Agriculture" = h3, "Low Agriculture" = h4),
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c("tavg_anomaly" = "Temperature Anomaly"),
             gof_map = gm,
             output = file.path(tbl_dir, "table5_heterogeneity.tex"),
             title = "Heterogeneity: Internet Penetration and Agricultural Dependence",
             notes = list("Sample split at state-level median. High Internet: states above median internet subscribers per 100 (2015). High Agriculture: states above median pre-period agricultural share.",
                          "Standard errors clustered at the state level."),
             escape = FALSE)

cat("\n=== All tables generated ===\n")
