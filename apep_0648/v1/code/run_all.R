## run_all.R — Combined pipeline for APEP-0636: PBM Spread Pricing Bans
## This single script avoids file overwrite issues from concurrent sessions

# ============================================================
# PACKAGES
# ============================================================
required_packages <- c("tidyverse","fixest","did","HonestDiD","modelsummary",
  "kableExtra","httr","jsonlite","sandwich","lmtest","bacondecomp")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}
cat("Packages loaded.\n")

dir.create("../data", showWarnings = FALSE)
dir.create("../tables", showWarnings = FALSE)

# ============================================================
# 1. TREATMENT CODING
# ============================================================
cc_laws <- tribble(
  ~state_name,       ~state_fips, ~cc_year,
  "Vermont",50,1903,"Alaska",2,2003,"Arizona",4,2010,"Wyoming",56,2011,
  "Kansas",20,2015,"Maine",23,2015,"Idaho",16,2016,"Mississippi",28,2016,
  "Missouri",29,2016,"West Virginia",54,2016,"New Hampshire",33,2017,
  "North Dakota",38,2017,"Arkansas",5,2018,
  "Kentucky",21,2019,"Oklahoma",40,2019,"South Dakota",46,2019,
  "Iowa",19,2021,"Montana",30,2021,"Tennessee",47,2021,"Texas",48,2021,"Utah",49,2021,
  "Georgia",13,2022,"Indiana",18,2022,"Ohio",39,2022,
  "Alabama",1,2023,"Florida",12,2023,"Nebraska",31,2023,
  "Louisiana",22,2024,"South Carolina",45,2024
)
write_csv(cc_laws, "data/cc_laws.csv")
cat("CC laws:", nrow(cc_laws), "states\n")

# ============================================================
# 2. FETCH CDC MAPPING INJURY DATA
# ============================================================
fetch_cdc_intent <- function(intent_name) {
  cat("Fetching", intent_name, "...")
  all_rows <- list()
  offset <- 0
  repeat {
    resp <- GET("https://data.cdc.gov/resource/psx4-wq38.json",
                query = list(intent = intent_name, `$limit` = 50000,
                             `$offset` = offset, `$where` = "period != 'TTM'"))
    stopifnot(status_code(resp) == 200)
    df <- content(resp, as = "text", encoding = "UTF-8") |> fromJSON()
    if (nrow(df) == 0) break
    all_rows[[length(all_rows) + 1]] <- df
    offset <- offset + 50000
    if (nrow(df) < 50000) break
  }
  result <- bind_rows(all_rows)
  cat(" got", nrow(result), "rows\n")
  result
}

cdc_county <- map_dfr(c("FA_Homicide","FA_Suicide","All_Homicide","All_Suicide"), fetch_cdc_intent)
stopifnot(nrow(cdc_county) > 0)

cdc_county <- cdc_county |>
  mutate(count = suppressWarnings(as.numeric(count_sup)),
         year = as.integer(period), st_fips = as.integer(st_geoid))

cat("CDC:", nrow(cdc_county), "county rows,", n_distinct(cdc_county$st_name), "states\n")

# Aggregate to state-year
state_year <- cdc_county |>
  group_by(st_name, st_fips, intent, year) |>
  summarise(deaths = sum(count, na.rm = TRUE), .groups = "drop")

# ============================================================
# 3. POPULATION DATA
# ============================================================
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  # Try loading from .env
  env_path <- file.path(dirname(dirname(dirname(dirname(getwd())))), ".env")
  if (file.exists(env_path)) {
    lines <- readLines(env_path, warn = FALSE)
    for (l in lines) {
      if (grepl("^CENSUS_API_KEY=", l)) {
        census_key <- gsub("[\"']", "", sub("^CENSUS_API_KEY=", "", l))
      }
    }
  }
}
stopifnot("Census API key needed" = nchar(census_key) > 0)

pop_long <- NULL

# Try PEP charEstimates
tryCatch({
  resp <- GET("https://api.census.gov/data/2023/pep/charEstimates",
              query = list(get = "POP,NAME", `for` = "state:*", key = census_key))
  if (status_code(resp) == 200) {
    mat <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
    pop_base <- tibble(state_name = mat[-1, 2], state_fips = as.integer(mat[-1, 3]),
                       population = as.numeric(mat[-1, 1]))
    pop_long <- crossing(pop_base, year = 2019:2024)
    cat("Got population from PEP charEstimates 2023\n")
  }
}, error = function(e) NULL)

# Fallback: try PEP population
if (is.null(pop_long)) {
  for (yr in c(2023, 2022, 2021, 2019)) {
    tryCatch({
      resp <- GET(paste0("https://api.census.gov/data/", yr, "/pep/population"),
                  query = list(get = "POP,NAME", `for` = "state:*", key = census_key))
      if (status_code(resp) == 200) {
        mat <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
        pop_base <- tibble(state_name = mat[-1, 2], state_fips = as.integer(mat[-1, 3]),
                           population = as.numeric(mat[-1, 1]))
        pop_long <- crossing(pop_base, year = 2019:2024)
        cat("Got pop from vintage", yr, "\n")
        break
      }
    }, error = function(e) NULL)
  }
}

# Fallback: decennial
if (is.null(pop_long)) {
  resp <- GET("https://api.census.gov/data/2020/dec/pl",
              query = list(get = "P1_001N,NAME", `for` = "state:*", key = census_key))
  if (status_code(resp) == 200) {
    mat <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
    pop_base <- tibble(state_name = mat[-1, 2], state_fips = as.integer(mat[-1, 3]),
                       population = as.numeric(mat[-1, 1]))
    pop_long <- crossing(pop_base, year = 2019:2024)
    cat("Got pop from 2020 Census\n")
  }
}

stopifnot("No population data" = !is.null(pop_long))
pop_long <- pop_long |> filter(state_fips <= 56, state_fips != 11) # exclude DC, territories

# ============================================================
# 4. BUILD PANEL
# ============================================================
panel <- state_year |>
  select(st_name, st_fips, intent, year, deaths) |>
  pivot_wider(names_from = intent, values_from = deaths, values_fill = 0) |>
  rename(state_name = st_name, state_fips = st_fips,
         fa_homicide = FA_Homicide, fa_suicide = FA_Suicide,
         all_homicide = All_Homicide, all_suicide = All_Suicide) |>
  mutate(nfa_homicide = all_homicide - fa_homicide,
         nfa_suicide = all_suicide - fa_suicide)

panel <- panel |>
  left_join(pop_long, by = c("state_name", "state_fips", "year"))

panel <- panel |>
  mutate(fa_homicide_rate = fa_homicide / population * 1e5,
         fa_suicide_rate = fa_suicide / population * 1e5,
         all_homicide_rate = all_homicide / population * 1e5,
         all_suicide_rate = all_suicide / population * 1e5,
         nfa_homicide_rate = nfa_homicide / population * 1e5,
         nfa_suicide_rate = nfa_suicide / population * 1e5,
         total_fa_rate = (fa_homicide + fa_suicide) / population * 1e5)

panel <- panel |>
  left_join(cc_laws |> select(state_name, cc_year), by = "state_name") |>
  mutate(
    gname = case_when(is.na(cc_year) ~ 0L, cc_year < 2019 ~ 0L, TRUE ~ as.integer(cc_year)),
    treated = as.integer(!is.na(cc_year) & year >= cc_year),
    cc_wave = case_when(is.na(cc_year) ~ "Never", cc_year < 2019 ~ "Pre-2019", TRUE ~ as.character(cc_year))
  )

# State IDs for did package
state_ids <- panel |> distinct(state_name, state_fips) |> arrange(state_fips) |> mutate(state_id = row_number())
panel <- panel |> left_join(state_ids, by = c("state_name", "state_fips"))

# DiD sample: exclude pre-2019 adopters
did_panel <- panel |> filter(cc_wave != "Pre-2019")

n_treated <- n_distinct(did_panel$state_fips[did_panel$gname > 0])
n_control <- n_distinct(did_panel$state_fips[did_panel$gname == 0])
cat("\nDiD sample:", n_distinct(did_panel$state_fips), "states,",
    n_treated, "treated,", n_control, "control\n")
did_panel |> filter(gname > 0) |> distinct(state_name, gname) |> count(gname) |> print()

write_csv(panel, "data/full_panel.csv")
write_csv(did_panel, "data/analysis_panel.csv")
jsonlite::write_json(list(n_treated = n_treated, n_pre = 5L, n_obs = nrow(did_panel)),
                     "data/diagnostics.json", auto_unbox = TRUE)

# ============================================================
# 5. MAIN ANALYSIS: Callaway-Sant'Anna
# ============================================================
cat("\n=== MAIN ANALYSIS ===\n")

cs_hom <- att_gt(yname = "fa_homicide_rate", tname = "year", idname = "state_id",
                 gname = "gname", data = did_panel, control_group = "nevertreated",
                 anticipation = 0, base_period = "universal")
agg_hom <- aggte(cs_hom, type = "simple")
es_hom <- aggte(cs_hom, type = "dynamic", min_e = -4, max_e = 3)
grp_hom <- aggte(cs_hom, type = "group")

cs_sui <- att_gt(yname = "fa_suicide_rate", tname = "year", idname = "state_id",
                 gname = "gname", data = did_panel, control_group = "nevertreated",
                 anticipation = 0, base_period = "universal")
agg_sui <- aggte(cs_sui, type = "simple")
es_sui <- aggte(cs_sui, type = "dynamic", min_e = -4, max_e = 3)
grp_sui <- aggte(cs_sui, type = "group")

cs_total <- att_gt(yname = "total_fa_rate", tname = "year", idname = "state_id",
                   gname = "gname", data = did_panel, control_group = "nevertreated",
                   anticipation = 0, base_period = "universal")
agg_total <- aggte(cs_total, type = "simple")
es_total <- aggte(cs_total, type = "dynamic", min_e = -4, max_e = 3)

# TWFE comparison
twfe_hom <- feols(fa_homicide_rate ~ treated | state_fips + year, data = did_panel, cluster = ~state_fips)
twfe_sui <- feols(fa_suicide_rate ~ treated | state_fips + year, data = did_panel, cluster = ~state_fips)
twfe_total <- feols(total_fa_rate ~ treated | state_fips + year, data = did_panel, cluster = ~state_fips)

# Sun-Abraham
did_panel <- did_panel |>
  mutate(sunab_cohort = ifelse(gname == 0, 10000L, gname))
sa_hom <- feols(fa_homicide_rate ~ sunab(sunab_cohort, year) | state_fips + year,
                data = did_panel, cluster = ~state_fips)
sa_sui <- feols(fa_suicide_rate ~ sunab(sunab_cohort, year) | state_fips + year,
                data = did_panel, cluster = ~state_fips)

cat("\n=== KEY RESULTS ===\n")
pval_fn <- function(est, se) 2 * pnorm(-abs(est / se))
cat(sprintf("CS-DiD ATT (FA Homicide): %.3f (SE=%.3f, p=%.3f)\n",
            agg_hom$overall.att, agg_hom$overall.se,
            pval_fn(agg_hom$overall.att, agg_hom$overall.se)))
cat(sprintf("CS-DiD ATT (FA Suicide):  %.3f (SE=%.3f, p=%.3f)\n",
            agg_sui$overall.att, agg_sui$overall.se,
            pval_fn(agg_sui$overall.att, agg_sui$overall.se)))
cat(sprintf("CS-DiD ATT (Total FA):    %.3f (SE=%.3f, p=%.3f)\n",
            agg_total$overall.att, agg_total$overall.se,
            pval_fn(agg_total$overall.att, agg_total$overall.se)))
cat(sprintf("TWFE (FA Homicide): %.3f (SE=%.3f)\n", coef(twfe_hom)["treated"], se(twfe_hom)["treated"]))
cat(sprintf("TWFE (FA Suicide):  %.3f (SE=%.3f)\n", coef(twfe_sui)["treated"], se(twfe_sui)["treated"]))

results <- list(cs_hom=cs_hom, cs_sui=cs_sui, cs_total=cs_total,
                agg_hom=agg_hom, agg_sui=agg_sui, agg_total=agg_total,
                es_hom=es_hom, es_sui=es_sui, es_total=es_total,
                grp_hom=grp_hom, grp_sui=grp_sui,
                twfe_hom=twfe_hom, twfe_sui=twfe_sui, twfe_total=twfe_total,
                sa_hom=sa_hom, sa_sui=sa_sui)
saveRDS(results, "data/main_results.rds")

# ============================================================
# 6. ROBUSTNESS
# ============================================================
cat("\n=== ROBUSTNESS ===\n")

# Placebo: non-firearm
cs_nfa_hom <- att_gt(yname = "nfa_homicide_rate", tname = "year", idname = "state_id",
                     gname = "gname", data = did_panel, control_group = "nevertreated",
                     anticipation = 0, base_period = "universal")
agg_nfa_hom <- aggte(cs_nfa_hom, type = "simple")
cat(sprintf("Placebo (NFA Homicide): %.3f (SE=%.3f)\n", agg_nfa_hom$overall.att, agg_nfa_hom$overall.se))

cs_nfa_sui <- att_gt(yname = "nfa_suicide_rate", tname = "year", idname = "state_id",
                     gname = "gname", data = did_panel, control_group = "nevertreated",
                     anticipation = 0, base_period = "universal")
agg_nfa_sui <- aggte(cs_nfa_sui, type = "simple")
cat(sprintf("Placebo (NFA Suicide):  %.3f (SE=%.3f)\n", agg_nfa_sui$overall.att, agg_nfa_sui$overall.se))

# Not-yet-treated control
cs_hom_nyt <- att_gt(yname = "fa_homicide_rate", tname = "year", idname = "state_id",
                     gname = "gname", data = did_panel, control_group = "notyettreated",
                     anticipation = 0, base_period = "universal")
agg_hom_nyt <- aggte(cs_hom_nyt, type = "simple")
cs_sui_nyt <- att_gt(yname = "fa_suicide_rate", tname = "year", idname = "state_id",
                     gname = "gname", data = did_panel, control_group = "notyettreated",
                     anticipation = 0, base_period = "universal")
agg_sui_nyt <- aggte(cs_sui_nyt, type = "simple")
cat(sprintf("Not-yet-treated (Hom): %.3f (SE=%.3f)\n", agg_hom_nyt$overall.att, agg_hom_nyt$overall.se))
cat(sprintf("Not-yet-treated (Sui): %.3f (SE=%.3f)\n", agg_sui_nyt$overall.att, agg_sui_nyt$overall.se))

# Leave-one-out
treated_states <- did_panel |> filter(gname > 0) |> distinct(state_fips, state_name)
loo_results <- map_dfr(1:nrow(treated_states), function(i) {
  sub <- did_panel |> filter(state_fips != treated_states$state_fips[i])
  tryCatch({
    cs <- att_gt(yname = "fa_homicide_rate", tname = "year", idname = "state_id",
                 gname = "gname", data = sub, control_group = "nevertreated",
                 anticipation = 0, base_period = "universal")
    a <- aggte(cs, type = "simple")
    tibble(dropped = treated_states$state_name[i], att = a$overall.att, se = a$overall.se)
  }, error = function(e) tibble(dropped = treated_states$state_name[i], att = NA, se = NA))
})
cat(sprintf("LOO range: [%.3f, %.3f]\n", min(loo_results$att, na.rm=T), max(loo_results$att, na.rm=T)))

# Wild cluster bootstrap
tryCatch({
  cat("WCB skipped: fwildclusterboot not available for R 4.3\n")
}, error = function(e) cat("WCB failed:", e$message, "\n"))

rob_results <- list(agg_nfa_hom=agg_nfa_hom, agg_nfa_sui=agg_nfa_sui,
                    agg_hom_nyt=agg_hom_nyt, agg_sui_nyt=agg_sui_nyt,
                    loo_results=loo_results)
saveRDS(rob_results, "data/robustness_results.rds")

# ============================================================
# 7. TABLES
# ============================================================
cat("\n=== GENERATING TABLES ===\n")

stars_fn <- function(p) { if(p<0.01)"***" else if(p<0.05)"**" else if(p<0.10)"*" else "" }

# -- Table 1: Summary Statistics --
summ_t <- did_panel |> filter(gname > 0, year < gname) |>
  summarise(across(c(fa_homicide_rate, fa_suicide_rate, total_fa_rate, population),
                   list(m = ~mean(., na.rm=T), s = ~sd(., na.rm=T))))
summ_c <- did_panel |> filter(gname == 0) |>
  summarise(across(c(fa_homicide_rate, fa_suicide_rate, total_fa_rate, population),
                   list(m = ~mean(., na.rm=T), s = ~sd(., na.rm=T))))

tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{CC States (Pre-Treat)} & \\multicolumn{2}{c}{Never-CC States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\midrule
Firearm homicide rate & %.2f & %.2f & %.2f & %.2f \\\\
Firearm suicide rate & %.2f & %.2f & %.2f & %.2f \\\\
Total firearm death rate & %.2f & %.2f & %.2f & %.2f \\\\
Population (millions) & %.2f & %.2f & %.2f & %.2f \\\\
\\midrule
States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
State-year observations & \\multicolumn{4}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Rates per 100,000 population. CC states: states adopting constitutional carry 2019--2024; pre-treatment means computed using only years prior to each state's adoption. Never-CC states: states without constitutional carry as of 2024. Data: CDC Mapping Injury (2019--2024), Census Bureau population estimates.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  summ_t$fa_homicide_rate_m, summ_t$fa_homicide_rate_s, summ_c$fa_homicide_rate_m, summ_c$fa_homicide_rate_s,
  summ_t$fa_suicide_rate_m, summ_t$fa_suicide_rate_s, summ_c$fa_suicide_rate_m, summ_c$fa_suicide_rate_s,
  summ_t$total_fa_rate_m, summ_t$total_fa_rate_s, summ_c$total_fa_rate_m, summ_c$total_fa_rate_s,
  summ_t$population_m/1e6, summ_t$population_s/1e6, summ_c$population_m/1e6, summ_c$population_s/1e6,
  n_treated, n_control, format(nrow(did_panel), big.mark=","))
writeLines(tab1, "tables/tab1_summary.tex")

# -- Table 2: Main Results --
ctrl_hom <- mean(did_panel$fa_homicide_rate[did_panel$gname==0], na.rm=T)
ctrl_sui <- mean(did_panel$fa_suicide_rate[did_panel$gname==0], na.rm=T)
ctrl_tot <- mean(did_panel$total_fa_rate[did_panel$gname==0], na.rm=T)
p_cs_hom <- pval_fn(agg_hom$overall.att, agg_hom$overall.se)
p_cs_sui <- pval_fn(agg_sui$overall.att, agg_sui$overall.se)
p_cs_tot <- pval_fn(agg_total$overall.att, agg_total$overall.se)

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Effect of Constitutional Carry Laws on Firearm Mortality}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& \\multicolumn{3}{c}{Outcome (rate per 100,000)} \\\\
\\cmidrule(lr){2-4}
& FA Homicide & FA Suicide & Total FA Deaths \\\\
& (1) & (2) & (3) \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\[3pt]
ATT & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) \\\\
95%%%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\[3pt]
Treated & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) \\\\
\\midrule
Control mean & %.2f & %.2f & %.2f \\\\
Effect as %%%% of mean & %.1f%%%% & %.1f%%%% & %.1f%%%% \\\\
Treated states & %d & %d & %d \\\\
Control states & %d & %d & %d \\\\
State-year obs & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports the overall ATT from the \\citet{callaway2021} estimator with never-treated states as controls. Panel B reports TWFE with state and year FE. Standard errors clustered at state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}",
  agg_hom$overall.att, stars_fn(p_cs_hom), agg_sui$overall.att, stars_fn(p_cs_sui), agg_total$overall.att, stars_fn(p_cs_tot),
  agg_hom$overall.se, agg_sui$overall.se, agg_total$overall.se,
  agg_hom$overall.att - 1.96*agg_hom$overall.se, agg_hom$overall.att + 1.96*agg_hom$overall.se,
  agg_sui$overall.att - 1.96*agg_sui$overall.se, agg_sui$overall.att + 1.96*agg_sui$overall.se,
  agg_total$overall.att - 1.96*agg_total$overall.se, agg_total$overall.att + 1.96*agg_total$overall.se,
  coef(twfe_hom)["treated"], stars_fn(pvalue(twfe_hom)["treated"]),
  coef(twfe_sui)["treated"], stars_fn(pvalue(twfe_sui)["treated"]),
  coef(twfe_total)["treated"], stars_fn(pvalue(twfe_total)["treated"]),
  se(twfe_hom)["treated"], se(twfe_sui)["treated"], se(twfe_total)["treated"],
  ctrl_hom, ctrl_sui, ctrl_tot,
  agg_hom$overall.att/ctrl_hom*100, agg_sui$overall.att/ctrl_sui*100, agg_total$overall.att/ctrl_tot*100,
  n_treated, n_treated, n_treated, n_control, n_control, n_control,
  format(nrow(did_panel), big.mark=","), format(nrow(did_panel), big.mark=","), format(nrow(did_panel), big.mark=","))
writeLines(tab2, "tables/tab2_main.tex")

# -- Table 3: Event Study --
es_df <- tibble(et = es_hom$egt, ah = es_hom$att.egt, sh = es_hom$se.egt,
                as_ = es_sui$att.egt, ss = es_sui$se.egt)
es_rows <- es_df |> mutate(
  r = sprintf("$k = %+d$ & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
              et, ah, sapply(pval_fn(ah,sh), stars_fn), sh,
              as_, sapply(pval_fn(as_,ss), stars_fn), ss)) |> pull(r)

tab3 <- paste0("\\begin{table}[H]\n\\centering\n\\caption{Event Study: Dynamic Treatment Effects}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lcccc}\n\\toprule\n",
  "& \\multicolumn{2}{c}{FA Homicide Rate} & \\multicolumn{2}{c}{FA Suicide Rate} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Event Time & ATT & SE & ATT & SE \\\\\n\\midrule\n",
  paste(es_rows, collapse="\n"), "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Event study coefficients from \\citet{callaway2021}, aggregated dynamically. $k=0$ is adoption year. Negative $k$ are pre-treatment (parallel trends test). Never-treated states as controls. State-clustered SEs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:eventstudy}\n\\end{table}")
writeLines(tab3, "tables/tab3_eventstudy.tex")

# -- Table 4: Robustness --
p_nfa_h <- pval_fn(agg_nfa_hom$overall.att, agg_nfa_hom$overall.se)
p_nfa_s <- pval_fn(agg_nfa_sui$overall.att, agg_nfa_sui$overall.se)
p_nyt_h <- pval_fn(agg_hom_nyt$overall.att, agg_hom_nyt$overall.se)
p_nyt_s <- pval_fn(agg_sui_nyt$overall.att, agg_sui_nyt$overall.se)

tab4 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{FA Homicide} & \\multicolumn{2}{c}{FA Suicide} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Specification & ATT & SE & ATT & SE \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Baseline}} \\\\[3pt]
CS-DiD (never-treated) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Alternative Control}} \\\\[3pt]
CS-DiD (not-yet-treated) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Placebo Outcomes}} \\\\[3pt]
Non-firearm homicide & %.3f%s & (%.3f) & & \\\\
Non-firearm suicide & & & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel D: Leave-One-Out}} \\\\[3pt]
Min ATT & %.3f & & & \\\\
Max ATT & %.3f & & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A: baseline from \\Cref{tab:main}. Panel B: not-yet-treated control group. Panel C: placebo outcomes unaffected by carry laws. Panel D: range of FA homicide ATT dropping each treated state. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}",
  agg_hom$overall.att, stars_fn(p_cs_hom), agg_hom$overall.se,
  agg_sui$overall.att, stars_fn(p_cs_sui), agg_sui$overall.se,
  agg_hom_nyt$overall.att, stars_fn(p_nyt_h), agg_hom_nyt$overall.se,
  agg_sui_nyt$overall.att, stars_fn(p_nyt_s), agg_sui_nyt$overall.se,
  agg_nfa_hom$overall.att, stars_fn(p_nfa_h), agg_nfa_hom$overall.se,
  agg_nfa_sui$overall.att, stars_fn(p_nfa_s), agg_nfa_sui$overall.se,
  min(loo_results$att, na.rm=T), max(loo_results$att, na.rm=T))
writeLines(tab4, "tables/tab4_robustness.tex")

# -- Table 5: Heterogeneity by Cohort --
gd <- tibble(cohort = grp_hom$egt, ah = grp_hom$att.egt, sh = grp_hom$se.egt,
             as_ = grp_sui$att.egt, ss = grp_sui$se.egt,
             ns = sapply(grp_hom$egt, function(g) n_distinct(did_panel$state_fips[did_panel$gname==g])))
grp_rows <- gd |> mutate(
  r = sprintf("%d & %d & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
              cohort, ns, ah, sapply(pval_fn(ah,sh), stars_fn), sh,
              as_, sapply(pval_fn(as_,ss), stars_fn), ss)) |> pull(r)

tab5 <- paste0("\\begin{table}[H]\n\\centering\n\\caption{Treatment Effects by Adoption Cohort}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{cccccc}\n\\toprule\n",
  "& & \\multicolumn{2}{c}{FA Homicide} & \\multicolumn{2}{c}{FA Suicide} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  "Cohort & States & ATT & SE & ATT & SE \\\\\n\\midrule\n",
  paste(grp_rows, collapse="\n"), "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Group-specific ATTs from \\citet{callaway2021}. Each row: ATT for states adopting in indicated year. State-clustered SEs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:heterogeneity}\n\\end{table}")
writeLines(tab5, "tables/tab5_heterogeneity.tex")

# -- SDE Table (mandatory appendix) --
sd_h <- sd(did_panel$fa_homicide_rate, na.rm=T)
sd_s <- sd(did_panel$fa_suicide_rate, na.rm=T)
sd_t <- sd(did_panel$total_fa_rate, na.rm=T)

sde_cls <- function(s) case_when(s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative", s < 0.005 ~ "Null", s < 0.05 ~ "Small positive",
  s < 0.15 ~ "Moderate positive", TRUE ~ "Large positive")

sde <- tibble(
  Outcome = c("Firearm homicide rate","Firearm suicide rate","Total firearm death rate"),
  beta = c(agg_hom$overall.att, agg_sui$overall.att, agg_total$overall.att),
  se_b = c(agg_hom$overall.se, agg_sui$overall.se, agg_total$overall.se),
  sdy = c(sd_h, sd_s, sd_t)
) |> mutate(sde = beta/sdy, se_sde = se_b/sdy, cls = sde_cls(sde))

sde_rows <- sde |> mutate(r = sprintf("%s & %.3f & (%.3f) & %.2f & %.3f & (%.3f) & %s \\\\",
  Outcome, beta, se_b, sdy, sde, se_sde, cls)) |> pull(r)

sde_tex <- paste0("\\begin{table}[H]\n\\centering\n\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  paste(sde_rows, collapse="\n"), "\n\\bottomrule\n\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. ",
  "SD($Y$) is the unconditional standard deviation.\n\n",
  "\\textbf{Research question:} Effect of constitutional carry laws on firearm mortality.\n",
  "\\textbf{Treatment:} Binary---state adopted CC (2019--2024 wave).\n",
  "\\textbf{Data:} CDC Mapping Injury (2019--2024), state-year panel, ", format(nrow(did_panel), big.mark=","), " obs.\n",
  "\\textbf{Method:} Staggered DiD, Callaway--Sant'Anna, state-clustered SEs.\n",
  "\\textbf{Sample:} US states excluding pre-2019 CC adopters.\n\n",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes $|$SDE$| < 0.005$.}\n",
  "\\end{table}")
writeLines(sde_tex, "tables/tabF1_sde.tex")

# Update diagnostics
diag <- jsonlite::read_json("data/diagnostics.json")
diag$att_fa_homicide <- round(agg_hom$overall.att, 4)
diag$att_fa_suicide <- round(agg_sui$overall.att, 4)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n============================================\n")
cat("ALL TABLES GENERATED\n")
cat("Files:", paste(list.files("tables"), collapse=", "), "\n")
cat("============================================\n")
