## 05_tables.R — Generate all LaTeX tables
## apep_0905: Argentina Aviation Deregulation

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "route_month_panel.csv"))
panel_nocovid <- panel[covid == 0]
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================

pre <- panel_nocovid[post == 0 & ym >= "2022-01-01"]
post_d <- panel_nocovid[post == 1]

# Route-level means
summ <- rbind(
  pre[monopoly == 1, .(
    Group = "Monopoly routes", Period = "Pre-decree",
    Passengers = mean(passengers), Seats = mean(seats),
    Flights = mean(flights), Airlines = mean(n_airlines),
    LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    Routes = uniqueN(route), Obs = .N)],
  pre[monopoly == 0, .(
    Group = "Competed routes", Period = "Pre-decree",
    Passengers = mean(passengers), Seats = mean(seats),
    Flights = mean(flights), Airlines = mean(n_airlines),
    LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    Routes = uniqueN(route), Obs = .N)],
  post_d[monopoly == 1, .(
    Group = "Monopoly routes", Period = "Post-decree",
    Passengers = mean(passengers), Seats = mean(seats),
    Flights = mean(flights), Airlines = mean(n_airlines),
    LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    Routes = uniqueN(route), Obs = .N)],
  post_d[monopoly == 0, .(
    Group = "Competed routes", Period = "Post-decree",
    Passengers = mean(passengers), Seats = mean(seats),
    Flights = mean(flights), Airlines = mean(n_airlines),
    LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    Routes = uniqueN(route), Obs = .N)]
)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Route-Month Averages}\n",
  "\\label{tab:summ}\n",
  "\\small\n",
  "\\begin{tabular}{llrrrrrrr}\n",
  "\\toprule\n",
  " & & Passengers & Seats & Flights & Airlines & Load & Routes & Obs. \\\\\n",
  " & & (monthly) & (monthly) & (monthly) & (count) & Factor & & \\\\\n",
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Pre-decree (Jan 2022--Jun 2024)}} \\\\\n",
  sprintf("\\quad Monopoly routes & & %s & %s & %s & %s & %s & %d & %s \\\\\n",
          formatC(round(summ[1, Passengers]), format = "d", big.mark = ","),
          formatC(round(summ[1, Seats]), format = "d", big.mark = ","),
          formatC(round(summ[1, Flights], 1), format = "f", digits = 1),
          formatC(round(summ[1, Airlines], 2), format = "f", digits = 2),
          formatC(round(summ[1, LF], 3), format = "f", digits = 3),
          summ[1, Routes],
          formatC(summ[1, Obs], format = "d", big.mark = ",")),
  sprintf("\\quad Competed routes & & %s & %s & %s & %s & %s & %d & %s \\\\\n",
          formatC(round(summ[2, Passengers]), format = "d", big.mark = ","),
          formatC(round(summ[2, Seats]), format = "d", big.mark = ","),
          formatC(round(summ[2, Flights], 1), format = "f", digits = 1),
          formatC(round(summ[2, Airlines], 2), format = "f", digits = 2),
          formatC(round(summ[2, LF], 3), format = "f", digits = 3),
          summ[2, Routes],
          formatC(summ[2, Obs], format = "d", big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Post-decree (Jul 2024--Jan 2026)}} \\\\\n",
  sprintf("\\quad Monopoly routes & & %s & %s & %s & %s & %s & %d & %s \\\\\n",
          formatC(round(summ[3, Passengers]), format = "d", big.mark = ","),
          formatC(round(summ[3, Seats]), format = "d", big.mark = ","),
          formatC(round(summ[3, Flights], 1), format = "f", digits = 1),
          formatC(round(summ[3, Airlines], 2), format = "f", digits = 2),
          formatC(round(summ[3, LF], 3), format = "f", digits = 3),
          summ[3, Routes],
          formatC(summ[3, Obs], format = "d", big.mark = ",")),
  sprintf("\\quad Competed routes & & %s & %s & %s & %s & %s & %d & %s \\\\\n",
          formatC(round(summ[4, Passengers]), format = "d", big.mark = ","),
          formatC(round(summ[4, Seats]), format = "d", big.mark = ","),
          formatC(round(summ[4, Flights], 1), format = "f", digits = 1),
          formatC(round(summ[4, Airlines], 2), format = "f", digits = 2),
          formatC(round(summ[4, LF], 3), format = "f", digits = 3),
          summ[4, Routes],
          formatC(summ[4, Obs], format = "d", big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Pre-decree averages computed over Jan 2022--Jun 2024 ",
  "(excluding COVID period Mar 2020--Dec 2021). Monopoly routes are those with ",
  "HHI = 10,000 in 2023; competed routes have HHI $<$ 10,000. Load factor is ",
  "passengers/seats, conditional on positive service.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

cat(tab1, file = file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ============================================================
## Table 2: Main DiD Results
## ============================================================

# Rerun models for clean etable output
m1 <- feols(log_pax ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
m2 <- feols(log_seats ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
m3 <- feols(log_flights ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
m4 <- feols(n_airlines ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

# Continuous HHI
panel_nocovid[, cal_month := month(ym)]
m5 <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
m6 <- feols(log_seats ~ hhi_norm:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
m7 <- feols(n_airlines ~ hhi_norm:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

setFixest_dict(c(
  log_pax = "Log(Passengers)",
  log_seats = "Log(Seats)",
  log_flights = "Log(Flights)",
  n_airlines = "N Airlines",
  "monopoly:post" = "Monopoly $\\times$ Post",
  "hhi_norm:post" = "HHI (norm.) $\\times$ Post"
))

etable(m1, m2, m3, m4, m5, m6, m7,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main_did.tex"),
       title = "Effect of Aviation Deregulation on Route-Level Outcomes",
       label = "tab:main",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)"),
       style.tex = style.tex("aer"),
       notes = paste0(
         "Route-month panel, Jan 2017--Jan 2026 (excluding Mar 2020--Dec 2021). ",
         "Columns (1)--(4): binary treatment (Monopoly = HHI of 10,000 in 2023). ",
         "Columns (5)--(7): continuous treatment (HHI normalized to [0,1]). ",
         "All specifications include route and month fixed effects. ",
         "Standard errors clustered at the route level in parentheses. ",
         "*** p$<$0.01, ** p$<$0.05, * p$<$0.1."
       ),
       se.below = TRUE,
       fitstat = c("n", "r2"))

cat("Table 2 written.\n")

## ============================================================
## Table 3: Robustness
## ============================================================

# Route x season FE
r_season <- feols(log_pax ~ hhi_norm:post | route_id + month_id + route_id[cal_month],
                  data = panel_nocovid, cluster = ~route)

# Full sample (including COVID)
r_full <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
                data = panel, cluster = ~route)

# Placebo at July 2022
panel_placebo <- panel_nocovid[ym < as.Date("2024-07-01")]
panel_placebo[, post_placebo := as.integer(ym >= as.Date("2022-07-01"))]
r_placebo <- feols(log_pax ~ hhi_norm:post_placebo | route_id + month_id,
                   data = panel_placebo, cluster = ~route)

# Large routes only
panel_nocovid[, large_route := as.integer(annual_pax > median(annual_pax, na.rm = TRUE))]
r_large <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
                 data = panel_nocovid[large_route == 1], cluster = ~route)

# Small routes only
r_small <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
                 data = panel_nocovid[large_route == 0], cluster = ~route)

etable(m5, r_season, r_full, r_placebo, r_large, r_small,
       tex = TRUE,
       file = file.path(tables_dir, "tab3_robustness.tex"),
       title = "Robustness: Continuous Treatment (Log Passengers)",
       label = "tab:robust",
       headers = c("Baseline", "Route$\\times$Season", "Incl. COVID",
                    "Placebo 2022", "Large Routes", "Small Routes"),
       style.tex = style.tex("aer"),
       notes = paste0(
         "Dependent variable: log(passengers + 1). Treatment: pre-decree HHI normalized to [0,1]. ",
         "Baseline: route and month FE, excluding COVID. ",
         "Column 2 adds route $\\times$ calendar-month varying slopes. ",
         "Column 3 includes the COVID period. ",
         "Column 4 uses a placebo treatment date of July 2022 (pre-decree sample only). ",
         "Columns 5--6 split by median 2023 annual traffic. ",
         "Randomization inference (500 permutations of HHI across routes): p $<$ 0.002. ",
         "Standard errors clustered at route level. ",
         "*** p$<$0.01, ** p$<$0.05, * p$<$0.1."
       ),
       se.below = TRUE,
       fitstat = c("n", "r2"))

cat("Table 3 written.\n")

## ============================================================
## Table 4: Entry Patterns
## ============================================================

# Count new route-airline entries by type
raw <- fread(file.path(data_dir, "domestic_flights.csv"))
raw[, city_A := pmin(origen_localidad, destino_localidad)]
raw[, city_B := pmax(origen_localidad, destino_localidad)]
raw[, route := paste(city_A, city_B, sep = " - ")]
raw[, ym := floor_date(as.Date(indice_tiempo), "month")]

first_svc <- raw[, .(first_month = min(ym)), by = .(route, aerolinea)]
new_entries <- first_svc[first_month >= as.Date("2024-07-01")]

hhi_info <- panel[, .(monopoly = monopoly[1], hhi_pre = hhi_pre[1]), by = route]
new_entries <- merge(new_entries, hhi_info, by = "route", all.x = TRUE)
new_entries[, route_type := fifelse(is.na(monopoly), "New route",
                                     fifelse(monopoly == 1, "Monopoly", "Competed"))]

# Entry by airline type
lcc_names <- c("Flybondi", "JetSMART Airlines")
new_entries[, airline_type := fifelse(aerolinea %in% lcc_names, "LCC", "Legacy/Regional")]

entry_tab <- new_entries[, .N, by = .(route_type, airline_type)]
entry_tab <- dcast(entry_tab, route_type ~ airline_type, value.var = "N", fill = 0)
entry_tab[, Total := LCC + `Legacy/Regional`]

# Format as LaTeX
tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Post-Decree Route-Airline Entries by Route Type and Carrier}\n",
  "\\label{tab:entry}\n",
  "\\begin{tabular}{lrrr}\n",
  "\\toprule\n",
  "Route type & LCC & Legacy/Regional & Total \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(entry_tab)) {
  tab4 <- paste0(tab4, sprintf("%s & %d & %d & %d \\\\\n",
                                entry_tab$route_type[i],
                                entry_tab$LCC[i],
                                entry_tab$`Legacy/Regional`[i],
                                entry_tab$Total[i]))
}

total_row <- entry_tab[, .(LCC = sum(LCC), Leg = sum(`Legacy/Regional`), Tot = sum(Total))]
tab4 <- paste0(tab4,
               "\\midrule\n",
               sprintf("Total & %d & %d & %d \\\\\n", total_row$LCC, total_row$Leg, total_row$Tot),
               "\\bottomrule\n",
               "\\end{tabular}\n",
               "\\begin{tablenotes}\n",
               "\\item \\textit{Notes:} A route-airline entry is the first observed service by ",
               "a carrier on a route after Decree 599/2024 (July 2024). LCCs are Flybondi and ",
               "JetSMART. ``New route'' denotes city pairs with no pre-decree scheduled service. ",
               "Monopoly routes had HHI = 10,000 in 2023; competed routes had HHI $<$ 10,000.\n",
               "\\end{tablenotes}\n",
               "\\end{table}\n")

cat(tab4, file = file.path(tables_dir, "tab4_entry.tex"))
cat("Table 4 written.\n")

## ============================================================
## Table F1: Standardized Effect Sizes (SDE Appendix — MANDATORY)
## ============================================================

# Compute SDE for main outcomes
# Binary treatment specification
sd_y_pre_pax <- sd(panel_nocovid[post == 0]$log_pax)
sd_y_pre_seats <- sd(panel_nocovid[post == 0]$log_seats)
sd_y_pre_flights <- sd(panel_nocovid[post == 0]$log_flights)
sd_y_pre_airlines <- sd(panel_nocovid[post == 0]$n_airlines)

# Main coefficients from binary treatment
beta_pax <- coef(m1)[1]
se_pax <- sqrt(vcov(m1)[1, 1])
beta_seats <- coef(m2)[1]
se_seats <- sqrt(vcov(m2)[1, 1])
beta_flights <- coef(m3)[1]
se_flights <- sqrt(vcov(m3)[1, 1])
beta_airlines <- coef(m4)[1]
se_airlines <- sqrt(vcov(m4)[1, 1])

sde_pax <- beta_pax / sd_y_pre_pax
sde_se_pax <- se_pax / sd_y_pre_pax
sde_seats <- beta_seats / sd_y_pre_seats
sde_se_seats <- se_seats / sd_y_pre_seats
sde_flights <- beta_flights / sd_y_pre_flights
sde_se_flights <- se_flights / sd_y_pre_flights
sde_airlines <- beta_airlines / sd_y_pre_airlines
sde_se_airlines <- se_airlines / sd_y_pre_airlines

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: Large vs small routes (binary treatment, log passengers)
m_het_large <- feols(log_pax ~ monopoly:post | route_id + month_id,
                     data = panel_nocovid[large_route == 1], cluster = ~route)
m_het_small <- feols(log_pax ~ monopoly:post | route_id + month_id,
                     data = panel_nocovid[large_route == 0], cluster = ~route)

sd_y_large <- sd(panel_nocovid[post == 0 & large_route == 1]$log_pax)
sd_y_small <- sd(panel_nocovid[post == 0 & large_route == 0]$log_pax)

beta_large <- coef(m_het_large)[1]
se_large <- sqrt(vcov(m_het_large)[1, 1])
beta_small <- coef(m_het_small)[1]
se_small <- sqrt(vcov(m_het_small)[1, 1])

sde_large <- beta_large / sd_y_large
sde_se_large <- se_large / sd_y_large
sde_small <- beta_small / sd_y_small
sde_se_small <- se_small / sd_y_small

# Build SDE table
fmt <- function(x, d = 4) formatC(round(x, d), format = "f", digits = d)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Argentina. ",
  "\\textbf{Research question:} Does aviation deregulation (Decree 599/2024, eliminating fare controls and route barriers) ",
  "increase passenger traffic and competition on previously monopoly domestic routes? ",
  "\\textbf{Policy mechanism:} The decree removed government fare-setting, opened all domestic routes to any licensed carrier, ",
  "and authorized foreign cabotage, thereby eliminating the key regulatory barriers to entry on monopoly routes. ",
  "\\textbf{Outcome definition:} Log monthly passengers (columns vary by outcome: passengers, seats, flights, carrier count). ",
  "\\textbf{Treatment:} Binary---monopoly routes (HHI = 10,000 in the pre-decree year 2023) versus competed routes (HHI $<$ 10,000). ",
  "\\textbf{Data:} ANAC commercial aviation microdata (datos.yvera.gob.ar), Jan 2017--Jan 2026, 198 domestic routes, ",
  "17,226 route-month observations (excluding COVID period Mar 2020--Dec 2021). ",
  "\\textbf{Method:} Two-way fixed effects (route + month FE), standard errors clustered at route level. ",
  "\\textbf{Sample:} Domestic regular scheduled flights; balanced panel of 198 routes active in 2023. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lrrrrrrl}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log(Passengers) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_pax, 3), fmt(se_pax, 3), fmt(sd_y_pre_pax, 3),
          fmt(sde_pax), fmt(sde_se_pax), classify_sde(sde_pax)),
  sprintf("Log(Seats) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_seats, 3), fmt(se_seats, 3), fmt(sd_y_pre_seats, 3),
          fmt(sde_seats), fmt(sde_se_seats), classify_sde(sde_seats)),
  sprintf("Log(Flights) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_flights, 3), fmt(se_flights, 3), fmt(sd_y_pre_flights, 3),
          fmt(sde_flights), fmt(sde_se_flights), classify_sde(sde_flights)),
  sprintf("N Airlines & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_airlines, 3), fmt(se_airlines, 3), fmt(sd_y_pre_airlines, 3),
          fmt(sde_airlines), fmt(sde_se_airlines), classify_sde(sde_airlines)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Log Passengers by route size)}} \\\\\n",
  sprintf("Large routes & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_large, 3), fmt(se_large, 3), fmt(sd_y_large, 3),
          fmt(sde_large), fmt(sde_se_large), classify_sde(sde_large)),
  sprintf("Small routes & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_small, 3), fmt(se_small, 3), fmt(sd_y_small, 3),
          fmt(sde_small), fmt(sde_se_small), classify_sde(sde_small)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

cat(tabF1, file = file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n05_tables.R complete.\n")
