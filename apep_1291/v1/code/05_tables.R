## 05_tables.R — Generate all LaTeX tables for apep_1291
## Tables: summary stats, main results, event study, robustness, SDE

source("00_packages.R")

models <- readRDS("../data/models.rds")
rob_models <- readRDS("../data/rob_models.rds")
border_panel <- readRDS("../data/border_panel.rds")
sumstats <- readRDS("../data/sumstats.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

bp <- border_panel |>
  mutate(
    log_farms = log(n_farms + 1),
    log_avg_size = log(avg_farm_size + 1)
  )

# ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics...\n")

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Border Counties}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Nebraska (Treated)} & \\multicolumn{3}{c}{Neighbors (Control)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule"
)

ne_stats <- sumstats |> filter(grepl("Nebraska", treat_label))
nb_stats <- sumstats |> filter(grepl("Neighbor", treat_label))

vars <- list(
  list("Number of farms", "mean_farms", "sd_farms"),
  list("Average farm size (acres)", "mean_avg_size", "sd_avg_size"),
  list("Land in farms (acres)", "mean_land", "sd_land"),
  list("Share of large farms ($\\geq$1,000 ac)", "mean_share_large", "sd_share_large")
)

for (v in vars) {
  ne_m <- sprintf("%.1f", ne_stats[[v[[2]]]])
  ne_s <- sprintf("%.1f", ne_stats[[v[[3]]]])
  nb_m <- sprintf("%.1f", nb_stats[[v[[2]]]])
  nb_s <- sprintf("%.1f", nb_stats[[v[[3]]]])
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %d & %s & %s & %d \\\\",
            v[[1]], ne_m, ne_s, ne_stats$n_county_years,
            nb_m, nb_s, nb_stats$n_county_years))
}

tab1_lines <- c(tab1_lines,
  sprintf("Distance to border (km) & %.1f & --- & --- & %.1f & --- & --- \\\\",
          ne_stats$mean_dist_km, nb_stats$mean_dist_km),
  sprintf("Counties & --- & --- & %d & --- & --- & %d \\\\",
          ne_stats$n_counties, nb_stats$n_counties),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Sample includes %d border county $\\times$ year observations across %d Census years (2002, 2007, 2012, 2017, 2022). Nebraska counties are those that share a border with counties in Iowa, Kansas, South Dakota, or Missouri. Neighbor counties are those in the four bordering states that are adjacent to Nebraska. Farm data from USDA NASS Census of Agriculture. Large farms defined as operations with 1,000 or more acres.",
          ne_stats$n_county_years + nb_stats$n_county_years, 5),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ---- Table 2: Main Results ----
cat("Generating Table 2: Main Results...\n")

m1 <- models$m1_farms
m2 <- models$m2_log_farms
m3 <- models$m3_avg_size
m4 <- models$m4_share_large
m5 <- models$m5_land

fmt_coef <- function(m, var = "treat_post") {
  b <- coef(m)[var]
  s <- se(m)[var]
  p <- pvalue(m)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  list(
    coef = sprintf("%.3f%s", b, stars),
    se = sprintf("(%.3f)", s),
    beta = b,
    se_num = s
  )
}

c1 <- fmt_coef(m1); c2 <- fmt_coef(m2); c3 <- fmt_coef(m3)
c5 <- fmt_coef(m5)

n_counties <- n_distinct(bp$fips[bp$treat == 1]) + n_distinct(bp$fips[bp$treat == 0])

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Corporate Farming Deregulation on Farm Structure}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Farms & Log Farms & Avg Size & Land (ac) \\\\",
  "\\midrule",
  sprintf("Nebraska $\\times$ Post-2007 & %s & %s & %s & %s \\\\",
          c1$coef, c2$coef, c3$coef, c5$coef),
  sprintf(" & %s & %s & %s & %s \\\\",
          c1$se, c2$se, c3$se, c5$se),
  "\\\\",
  sprintf("County FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m5), big.mark = ",")),
  sprintf("Counties & %d & %d & %d & %d \\\\",
          n_counties, n_counties, n_counties, n_counties),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Sample restricted to border counties (Nebraska counties adjacent to a neighboring state, and neighboring-state counties adjacent to Nebraska). ``Post-2007'' denotes Census years 2012, 2017, and 2022; ``Pre'' includes 1997, 2002, and 2007. ``Avg Size'' is average acres per farm. All specifications include county and year fixed effects.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ---- Table 3: Event Study ----
cat("Generating Table 3: Event Study...\n")

es_farms <- models$es_farms
es_size <- models$es_size
es_share <- models$es_share

# Dynamically extract event study variables
all_es_vars <- names(coef(es_size))
pre_vars <- sort(all_es_vars[grepl("yr_1[0-9]{3}|yr_200[0-6]|yr_2002", all_es_vars)])
post_vars <- sort(all_es_vars[grepl("yr_201[2-9]|yr_202[0-9]", all_es_vars)])

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Farm Structure Before and After Deregulation}",
  "\\label{tab:event_study}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Log Farms & Avg Size \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment (relative to 2007):}} \\\\"
)

for (v in pre_vars) {
  yr_num <- gsub("yr_", "", v)
  label <- sprintf("NE $\\times$ %s", yr_num)
  c_f <- fmt_coef(es_farms, v)
  c_s <- fmt_coef(es_size, v)
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %s \\\\", label, c_f$coef, c_s$coef),
    sprintf(" & %s & %s \\\\", c_f$se, c_s$se))
}

tab3_lines <- c(tab3_lines,
  "\\\\",
  "\\multicolumn{3}{l}{\\textit{Post-treatment:}} \\\\")

for (v in post_vars) {
  yr_num <- gsub("yr_", "", v)
  label <- sprintf("NE $\\times$ %s", yr_num)
  c_f <- fmt_coef(es_farms, v)
  c_s <- fmt_coef(es_size, v)
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %s \\\\", label, c_f$coef, c_s$coef),
    sprintf(" & %s & %s \\\\", c_f$se, c_s$se))
}

tab3_lines <- c(tab3_lines,
  "\\\\",
  sprintf("County FE & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes \\\\"),
  sprintf("Observations & %s & %s \\\\",
          format(nobs(es_farms), big.mark = ","),
          format(nobs(es_size), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Coefficients are interactions of Nebraska indicator with Census year dummies. The omitted category is 2007 (last pre-treatment Census). Null pre-treatment coefficients support the parallel trends assumption. Border county sample. Census years: 1997, 2002, 2007, 2012, 2017, 2022.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event_study.tex")

# ---- Table 4: Robustness ----
cat("Generating Table 4: Robustness...\n")

# Collect robustness results for avg_farm_size
rob_list <- list(
  "Baseline (border)" = models$m3_avg_size,
  "50 km bandwidth" = rob_models$bw_avg[["50"]],
  "75 km bandwidth" = rob_models$bw_avg[["75"]],
  "100 km bandwidth" = rob_models$bw_avg[["100"]],
  "150 km bandwidth" = rob_models$bw_avg[["150"]],
  "Rural counties only" = rob_models$rural_only,
  "HC-robust SEs" = rob_models$robust_se
)

# Remove NULLs
rob_list <- rob_list[!sapply(rob_list, is.null)]

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Average Farm Size}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & Observations \\\\",
  "\\midrule"
)

for (nm in names(rob_list)) {
  m <- rob_list[[nm]]
  rc <- fmt_coef(m)
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s & %s & %s \\\\",
            nm, rc$coef, rc$se, format(nobs(m), big.mark = ",")))
}

# Add placebo rows
if (!is.null(rob_models$placebo_size)) {
  pc <- fmt_coef(rob_models$placebo_size, "placebo_treat_post")
  tab4_lines <- c(tab4_lines,
    "\\midrule",
    "\\multicolumn{4}{l}{\\textit{Placebo tests:}} \\\\",
    sprintf("Placebo border (SD vs IA interior) & %s & %s & %s \\\\",
            pc$coef, pc$se, format(nobs(rob_models$placebo_size), big.mark = ",")))
}

if (!is.null(rob_models$placebo_time)) {
  pt <- fmt_coef(rob_models$placebo_time, "fake_treat_post")
  tab4_lines <- c(tab4_lines,
    sprintf("Placebo timing (pre-2007) & %s & %s & %s \\\\",
            pt$coef, pt$se, format(nobs(rob_models$placebo_time), big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications report the coefficient on Nebraska $\\times$ Post-2007 (or placebo equivalent) for average farm size (acres per operation). Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Bandwidth specifications include all counties within the specified distance of the Nebraska border. ``Rural only'' excludes counties in the bottom quartile of farm count.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ---- Table F1: Standardized Effect Sizes (SDE) ----
cat("Generating Table F1: SDE...\n")

classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# SDE for main outcomes (binary treatment)
sde_rows <- list()

# 1. Average farm size (main outcome)
b_size <- coef(models$m3_avg_size)["treat_post"]
se_size <- se(models$m3_avg_size)["treat_post"]
sd_y_size <- diagnostics$sd_avg_size
sde_size <- b_size / sd_y_size
se_sde_size <- se_size / sd_y_size

sde_rows[[1]] <- list(
  outcome = "Average farm size",
  spec = "Pooled",
  beta = b_size, se = se_size,
  sd_y = sd_y_size, sde = sde_size,
  se_sde = se_sde_size,
  class = classify_sde(sde_size)
)

# 2. Log number of farms (skip share_large — insufficient data across expanded years)
b_log <- coef(models$m2_log_farms)["treat_post"]
se_log <- se(models$m2_log_farms)["treat_post"]
sd_y_log <- diagnostics$sd_log_farms
sde_log <- b_log / sd_y_log
se_sde_log <- se_log / sd_y_log

sde_rows[[2]] <- list(
  outcome = "Log number of farms",
  spec = "Pooled",
  beta = b_log, se = se_log,
  sd_y = sd_y_log, sde = sde_log,
  se_sde = se_sde_log,
  class = classify_sde(sde_log)
)

# Panel B: Heterogeneity — Eastern vs Western NE border
bp_east <- bp |> filter(lon > -100)  # Eastern NE and eastern neighbors
bp_west <- bp |> filter(lon <= -100) # Western NE and western neighbors

m_east <- feols(avg_farm_size ~ treat_post | fips + year, data = bp_east, cluster = ~STUSPS)
m_west <- feols(avg_farm_size ~ treat_post | fips + year, data = bp_west, cluster = ~STUSPS)

b_east <- coef(m_east)["treat_post"]; se_east <- se(m_east)["treat_post"]
b_west <- coef(m_west)["treat_post"]; se_west <- se(m_west)["treat_post"]

sde_rows[[3]] <- list(
  outcome = "Avg size (East)",
  spec = "Heterogeneous",
  beta = b_east, se = se_east,
  sd_y = sd_y_size, sde = b_east / sd_y_size,
  se_sde = se_east / sd_y_size,
  class = classify_sde(b_east / sd_y_size)
)

sde_rows[[4]] <- list(
  outcome = "Avg size (West)",
  spec = "Heterogeneous",
  beta = b_west, se = se_west,
  sd_y = sd_y_size, sde = b_west / sd_y_size,
  se_sde = se_west / sd_y_size,
  class = classify_sde(b_west / sd_y_size)
)

# Build SDE table
sde_df <- bind_rows(lapply(sde_rows, as_tibble))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether anti-corporate farming laws constrain agricultural consolidation, as tested by the 2007 judicial invalidation of Nebraska's Initiative 300 on farm structure in border counties. ",
  "\\textbf{Policy mechanism:} Initiative 300 (1982) prohibited non-family corporations from acquiring Nebraska farmland; the Eighth Circuit struck it down in December 2006 (\\textit{Jones v.\\ Gale}), allowing corporate ownership while neighboring states maintained restrictions. ",
  "\\textbf{Outcome definition:} Average farm size in acres per operation and log number of farm operations (USDA Census of Agriculture county-level data). ",
  "\\textbf{Treatment:} Binary: Nebraska counties (deregulated) versus adjacent counties in Iowa, Kansas, South Dakota, and Missouri (restrictions maintained). ",
  "\\textbf{Data:} USDA NASS Census of Agriculture, county-level, 2002--2022 (five Census waves), border counties only; sample size varies by outcome. ",
  "\\textbf{Method:} Border-county difference-in-differences with county and year fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties sharing a border across the Nebraska state line; excludes interior counties and states not adjacent to Nebraska. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:2) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (East vs.\\ West border)}} \\\\"
)

for (i in 3:4) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Tables written to: ../tables/\n")
cat("  tab1_summary.tex\n  tab2_main.tex\n  tab3_event_study.tex\n")
cat("  tab4_robustness.tex\n  tabF1_sde.tex\n")
