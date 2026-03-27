# 05_tables.R — Generate all LaTeX tables for apep_1085
# Wind Turbines and Avian Community Restructuring

library(tidyverse)
library(fixest)
library(modelsummary)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))[1]
if (length(script_dir) > 0 && nchar(script_dir) > 0) setwd(file.path(script_dir, ".."))

panel <- readRDS("data/panel.rds")
models <- readRDS("data/models.rds")
robust_models <- readRDS("data/robust_models.rds")
pre_stats <- readRDS("data/pre_stats.rds")

dir.create("tables", showWarnings = FALSE)

# Disable siunitx wrapping so we get plain LaTeX tabular output
options("modelsummary_format_numeric_latex" = "plain")
options("tinytable_tt_eval" = FALSE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

summ <- panel %>%
  mutate(group = ifelse(first_treat_year > 0, "Wind states", "No wind")) %>%
  group_by(group) %>%
  summarise(
    n_states = n_distinct(state),
    n_obs = n(),
    mean_capacity = mean(cum_capacity_mw),
    sd_capacity = sd(cum_capacity_mw),
    mean_rr_raptor = mean(rr_raptors, na.rm = TRUE),
    sd_rr_raptor = sd(rr_raptors, na.rm = TRUE),
    mean_rr_grassland = mean(rr_grassland, na.rm = TRUE),
    sd_rr_grassland = sd(rr_grassland, na.rm = TRUE),
    mean_rr_waterfowl = mean(rr_waterfowl, na.rm = TRUE),
    sd_rr_waterfowl = sd(rr_waterfowl, na.rm = TRUE),
    mean_total_birds = mean(total_bird_records, na.rm = TRUE),
    sd_total_birds = sd(total_bird_records, na.rm = TRUE),
    .groups = "drop"
  )

fmt <- function(x, d = 4) sprintf(paste0("%.", d, "f"), x)
fmtk <- function(x) format(round(x), big.mark = ",")

wind <- filter(summ, group == "Wind states")
nowind <- filter(summ, group == "No wind")

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Wind States} & \\multicolumn{2}{c}{Non-Wind States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline",
  paste0("Cumulative wind capacity (MW) & ", fmtk(wind$mean_capacity), " & ", fmtk(wind$sd_capacity),
         " & ", fmtk(nowind$mean_capacity), " & ", fmtk(nowind$sd_capacity), " \\\\"),
  paste0("Raptor reporting rate & ", fmt(wind$mean_rr_raptor), " & ", fmt(wind$sd_rr_raptor),
         " & ", fmt(nowind$mean_rr_raptor), " & ", fmt(nowind$sd_rr_raptor), " \\\\"),
  paste0("Grassland bird reporting rate & ", fmt(wind$mean_rr_grassland, 6), " & ", fmt(wind$sd_rr_grassland, 6),
         " & ", fmt(nowind$mean_rr_grassland, 6), " & ", fmt(nowind$sd_rr_grassland, 6), " \\\\"),
  paste0("Waterfowl reporting rate & ", fmt(wind$mean_rr_waterfowl), " & ", fmt(wind$sd_rr_waterfowl),
         " & ", fmt(nowind$mean_rr_waterfowl), " & ", fmt(nowind$sd_rr_waterfowl), " \\\\"),
  paste0("Total eBird records & ", fmtk(wind$mean_total_birds), " & ", fmtk(wind$sd_total_birds),
         " & ", fmtk(nowind$mean_total_birds), " & ", fmtk(nowind$sd_total_birds), " \\\\"),
  "\\hline",
  paste0("States & \\multicolumn{2}{c}{", wind$n_states, "} & \\multicolumn{2}{c}{", nowind$n_states, "} \\\\"),
  paste0("State-year obs. & \\multicolumn{2}{c}{", wind$n_obs, "} & \\multicolumn{2}{c}{", nowind$n_obs, "} \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} State-year panel, 2008--2023. Wind states are those reaching $\\geq$100 MW cumulative installed wind capacity by 2023 (38 states). Reporting rate = taxon-specific eBird occurrence count / total eBird bird records for the state-year. Source: USGS Wind Turbine Database v8.3 and GBIF (eBird observations).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "tables/tab1_summary.tex")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results...\n")

# Use fixest::etable for reliable LaTeX output
etable(
  models$main_rr, models$main_log, models$waterfowl, models$binary,
  dict = c(
    "log_capacity" = "Log(1 + wind capacity MW)",
    "log_total" = "Log(total eBird records)",
    "post_treat" = "Post-treatment ($\\geq$100 MW)"
  ),
  headers = c("Raptor RR", "Log raptors", "Waterfowl RR", "Raptor RR"),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  tex = TRUE,
  fitstat = c("n", "r2"),
  file = "tables/tab2_main_inner.tex",
  replace = TRUE
)

# Wrap in table environment
inner <- readLines("tables/tab2_main_inner.tex")
tab2_full <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Wind Energy Expansion and Bird Populations}",
  "\\label{tab:main}",
  inner,
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a separate OLS regression at the state-year level, 2008--2023. The dependent variable is the reporting rate (occurrence count / total eBird records) for the species group, except column (2) which uses log counts with a log-effort control. Wind capacity is cumulative installed MW from the USGS Wind Turbine Database. Column (4) uses a binary indicator for reaching 100 MW cumulative capacity. All specifications include state and year fixed effects. Standard errors clustered at the state level in parentheses. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_full, "tables/tab2_main.tex")

# ============================================================
# Table 3: Event Study
# ============================================================
cat("Generating Table 3: Event Study...\n")

es <- models$event_study
es_coefs <- coeftable(es) %>%
  as.data.frame() %>%
  rownames_to_column("term") %>%
  filter(grepl("rel_year", term)) %>%
  mutate(
    rel_year = as.integer(gsub(".*::", "", term)),
    est = sprintf("%.5f", Estimate),
    se = sprintf("(%.5f)", `Std. Error`),
    stars = case_when(
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.10 ~ "*",
      TRUE ~ ""
    )
  ) %>%
  arrange(rel_year)

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Raptor Reporting Rate Around Wind Capacity Threshold}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Event time & Estimate & Std. Error \\\\",
  "\\hline"
)

for (i in 1:nrow(es_coefs)) {
  row <- es_coefs[i, ]
  yr_label <- ifelse(row$rel_year == -9, "$\\leq -8$",
              ifelse(row$rel_year == 9, "$\\geq 9$",
              as.character(row$rel_year)))
  if (row$rel_year == -1) next  # reference period
  tab3 <- c(tab3, paste0("$t = ", yr_label, "$ & ", row$est, row$stars, " & ", row$se, " \\\\"))
}

tab3 <- c(tab3,
  "\\hline",
  paste0("Observations & \\multicolumn{2}{c}{", format(nobs(es), big.mark = ","), "} \\\\"),
  paste0("States & \\multicolumn{2}{c}{", n_distinct(panel$state[panel$first_treat_year > 0]), "} \\\\"),
  "Reference period & \\multicolumn{2}{c}{$t = -1$} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Event study regression of raptor reporting rate on indicators for years relative to the state first reaching 100 MW cumulative wind capacity. Year $t=-1$ is the reference period. Endpoints bin all periods $\\leq -8$ and $\\geq 9$. State and year fixed effects included. Standard errors clustered at the state level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, "tables/tab3_eventstudy.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness...\n")

etable(
  models$main_rr, robust_models$no_texas, robust_models$threshold_50,
  robust_models$threshold_200, robust_models$placebo,
  dict = c(
    "log_capacity" = "Log(1 + wind capacity MW)",
    "post_50" = "Post 50 MW threshold",
    "post_200" = "Post 200 MW threshold",
    "fake_capacity" = "Placebo (future capacity)"
  ),
  headers = c("Baseline", "Drop TX", "50 MW", "200 MW", "Placebo"),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  tex = TRUE,
  fitstat = c("n", "r2"),
  file = "tables/tab4_rob_inner.tex",
  replace = TRUE
)

inner4 <- readLines("tables/tab4_rob_inner.tex")
tab4_full <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  inner4,
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} All columns report OLS regressions of raptor reporting rate on wind capacity measures with state and year fixed effects. Column (1): baseline continuous treatment. Column (2): drops Texas. Columns (3)--(4): binary treatment using alternative MW thresholds. Column (5): placebo test using future capacity as fake treatment. Standard errors clustered at the state level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_full, "tables/tab4_robustness.tex")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating Table F1: SDE...\n")

get_sde <- function(model, outcome_name, sd_y, coef_name = NULL) {
  cf <- coeftable(model)
  if (is.null(coef_name)) coef_name <- rownames(cf)[1]
  beta <- cf[coef_name, "Estimate"]
  se_beta <- cf[coef_name, "Std. Error"]
  # For continuous treatment, SDE = beta * SD(X) / SD(Y)
  # SD(log_capacity) from panel
  sd_x <- sd(panel$log_capacity, na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y
  classify <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  tibble(outcome = outcome_name, beta = beta, se = se_beta,
         sd_y = sd_y, sde = sde, se_sde = se_sde, classification = classify)
}

sde_rows <- list(
  get_sde(models$main_rr, "Raptor reporting rate", pre_stats$sd_rr_raptors, "log_capacity"),
  get_sde(models$waterfowl, "Waterfowl reporting rate (placebo)", pre_stats$sd_rr_waterfowl, "log_capacity")
)

# Add effort-controlled log raptors
sde_rows[[3]] <- get_sde(models$main_log, "Log raptor count (effort-controlled)",
                         pre_stats$sd_log_raptors, "log_capacity")

sde_table <- bind_rows(sde_rows)

# Panel B: Heterogeneity — Great Plains vs rest
panel_plains <- panel %>%
  mutate(plains = as.integer(state %in% c("TX","OK","KS","NE","SD","ND","IA","MN","MT","WY","CO")))

m_plains <- feols(rr_raptors ~ log_capacity | state + year,
                  data = filter(panel_plains, plains == 1), cluster = ~state)
m_nonplains <- feols(rr_raptors ~ log_capacity | state + year,
                     data = filter(panel_plains, plains == 0), cluster = ~state)

sd_plains <- sd(panel_plains$rr_raptors[panel_plains$plains == 1 &
                (is.na(panel_plains$rel_year) | panel_plains$rel_year < 0)], na.rm = TRUE)
sd_nonplains <- sd(panel_plains$rr_raptors[panel_plains$plains == 0 &
                   (is.na(panel_plains$rel_year) | panel_plains$rel_year < 0)], na.rm = TRUE)

sde_het <- bind_rows(
  get_sde(m_plains, "Raptors (Great Plains states)", sd_plains, "log_capacity"),
  get_sde(m_nonplains, "Raptors (Non-Plains states)", sd_nonplains, "log_capacity")
)

fmt4 <- function(x) sprintf("%.5f", x)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_table)) {
  row <- sde_table[i, ]
  sde_lines <- c(sde_lines, paste0(
    row$outcome, " & ", fmt4(row$beta), " & ", fmt4(row$se),
    " & ", fmt4(row$sd_y), " & ", fmt4(row$sde), " & ", fmt4(row$se_sde),
    " & ", row$classification, " \\\\"
  ))
}

sde_lines <- c(sde_lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\"
)

for (i in 1:nrow(sde_het)) {
  row <- sde_het[i, ]
  sde_lines <- c(sde_lines, paste0(
    row$outcome, " & ", fmt4(row$beta), " & ", fmt4(row$se),
    " & ", fmt4(row$sd_y), " & ", fmt4(row$sde), " & ", fmt4(row$se_sde),
    " & ", row$classification, " \\\\"
  ))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does wind energy expansion reduce raptor populations relative to other bird species in states that install large-scale wind capacity? ",
  "\\textbf{Policy mechanism:} Federal Production Tax Credits and state Renewable Portfolio Standards drove staggered installation of 72,000+ utility-scale wind turbines across 38 states (2000--2023), creating rotating blade hazards that disproportionately kill soaring raptors through collision mortality. ",
  "\\textbf{Outcome definition:} Annual raptor (Accipitridae) eBird occurrence count divided by total bird records for the state-year, measuring the proportional representation of raptors in citizen science observations. ",
  "\\textbf{Treatment:} Continuous; log(1 + cumulative installed wind capacity in MW) per state-year. ",
  "\\textbf{Data:} USGS Wind Turbine Database v8.3 and GBIF eBird occurrence records, 2008--2023, ",
  nrow(panel), " state-year observations across 50 states. ",
  "\\textbf{Method:} OLS with state and year fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 US states; Great Plains subsample includes TX, OK, KS, NE, SD, ND, IA, MN, MT, WY, CO (primary wind corridor). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of log wind capacity and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
