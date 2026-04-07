## 05_tables.R — Generate tables
## apep_1395: Denmark Renovation Arbitrage Ban

source("00_packages.R")

permits <- readRDS("../data/permits_panel.rds")
dwellings <- readRDS("../data/dwellings_panel.rds")
models <- readRDS("../data/main_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")

tabdir <- "../tables/"

# ---- Table 1: Summary Statistics ----
cat("Table 1: Summary statistics...\n")

permits_2015 <- permits %>% filter(year >= 2015)

summ <- permits_2015 %>%
  mutate(group = ifelse(treated == 1, "Treated", "Control"),
         period = ifelse(post == 0, "Pre", "Post")) %>%
  group_by(group, period) %>%
  summarise(
    mean_total = mean(total_permits, na.rm = TRUE),
    sd_total = sd(total_permits, na.rm = TRUE),
    mean_multi = mean(multifamily_permits, na.rm = TRUE),
    sd_multi = sd(multifamily_permits, na.rm = TRUE),
    n_obs = n(),
    n_munis = n_distinct(muni_name),
    .groups = "drop"
  )

# Format for LaTeX
summ_tex <- summ %>%
  mutate(across(where(is.numeric), ~round(., 1))) %>%
  mutate(
    total_str = paste0(format(mean_total, big.mark = ","), " (", format(sd_total, big.mark = ","), ")"),
    multi_str = paste0(format(mean_multi, big.mark = ","), " (", format(sd_multi, big.mark = ","), ")"),
    obs_str = format(n_obs, big.mark = ",")
  )

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Building Permits by Treatment Status}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated (80 munis)} & \\multicolumn{2}{c}{Control (18 munis)} \\\\\n",
  " & Pre & Post & Pre & Post \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(summ_tex)) {
  if (summ_tex$group[i] == "Treated" & summ_tex$period[i] == "Pre") {
    tab1 <- paste0(tab1, sprintf("Total permits & %s", summ_tex$total_str[i]))
    # Find other cells
    tp <- summ_tex %>% filter(group == "Treated", period == "Post")
    cp <- summ_tex %>% filter(group == "Control", period == "Pre")
    cpp <- summ_tex %>% filter(group == "Control", period == "Post")
    tab1 <- paste0(tab1, sprintf(" & %s & %s & %s \\\\\n",
                                  tp$total_str, cp$total_str, cpp$total_str))
    tab1 <- paste0(tab1, sprintf("Multifamily permits & %s & %s & %s & %s \\\\\n",
                                  summ_tex$multi_str[i], tp$multi_str, cp$multi_str, cpp$multi_str))
    tab1 <- paste0(tab1, sprintf("Observations & %s & %s & %s & %s \\\\\n",
                                  summ_tex$obs_str[i], tp$obs_str, cp$obs_str, cpp$obs_str))
  }
}

tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. Building permits from Statistics Denmark BYGV11 ",
  "(quarterly, municipality-level). Treated municipalities are those subject to the 2020 \\S5 stk.\\ 2 renovation ",
  "cap (default-on). Control municipalities are 18 that opted out. Pre: 2015Q1--2020Q2. Post: 2020Q3--2025Q4.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n")

writeLines(tab1, paste0(tabdir, "tab1_summary.tex"))

# ---- Table 2: Main DiD Results ----
cat("Table 2: Main results...\n")

# Use restricted pre-period as primary
permits_short <- permits %>% filter(year >= 2015)
permits_short$muni_id <- as.numeric(factor(permits_short$muni_name))
permits_short$time_id <- as.numeric(factor(paste(permits_short$year, permits_short$quarter)))
permits_short$log_permits <- log(permits_short$total_permits + 1)
permits_short$log_multi <- log(permits_short$multifamily_permits + 1)

m_main1 <- feols(total_permits ~ treated:post | muni_id + time_id,
                 data = permits_short, cluster = ~muni_id)
m_main2 <- feols(log_permits ~ treated:post | muni_id + time_id,
                 data = permits_short, cluster = ~muni_id)
m_main3 <- feols(multifamily_permits ~ treated:post | muni_id + time_id,
                 data = permits_short, cluster = ~muni_id)
m_main4 <- feols(log_multi ~ treated:post | muni_id + time_id,
                 data = permits_short, cluster = ~muni_id)

etable(m_main1, m_main2, m_main3, m_main4,
       title = "Effect of the Renovation Cap on Building Permits",
       headers = c("Total", "Log Total", "Multifamily", "Log Multi"),
       dict = c("treated:post" = "Treated $\\times$ Post"),
       notes = "Municipality and quarter fixed effects. Standard errors clustered at the municipality level. Sample: 2015Q1--2025Q4 (98 municipalities, 43 quarters). Treated = 80 municipalities subject to the \\S5 stk.\\ 2 renovation cap. Control = 18 opt-out municipalities.",
       label = "tab:main",
       file = paste0(tabdir, "tab2_main.tex"),
       replace = TRUE,
       style.tex = style.tex("aer"))

# ---- Table 3: Robustness ----
cat("Table 3: Robustness...\n")

etable(rob_models$r1, rob_models$r1b, rob_models$r2, rob_models$r5,
       title = "Robustness Checks",
       headers = c("Total (2015+)", "Log (2015+)", "Muni Trends", "Late Post"),
       dict = c("treated:post" = "Treated $\\times$ Post",
                "treated:post_late" = "Treated $\\times$ Late Post"),
       notes = "All specifications include municipality and quarter fixed effects with clustered standard errors. Column (1)--(2): pre-period restricted to 2015+. Column (3): municipality-specific linear trends over full panel. Column (4): pre-period vs.\\ late post (2022Q3+) only.",
       label = "tab:robust",
       file = paste0(tabdir, "tab3_robust.tex"),
       replace = TRUE,
       style.tex = style.tex("aer"))

# ---- Table 4: Placebo Tests ----
cat("Table 4: Placebo...\n")

# Dwelling stock for placebo
names(dwellings) <- make.names(names(dwellings))
dwellings$muni_id <- as.numeric(factor(dwellings$muni_name))
rental_col <- grep("tenant|lejer|rental", names(dwellings), value = TRUE, ignore.case = TRUE)
owner_col <- grep("owner|ejer", names(dwellings), value = TRUE, ignore.case = TRUE)
dwellings$rental <- dwellings[[rental_col[1]]]
dwellings$owner_occ <- dwellings[[owner_col[1]]]
dwellings$log_rental <- log(dwellings$rental + 1)
dwellings$log_owner <- log(dwellings$owner_occ + 1)

m_rental <- feols(log_rental ~ treated:post | muni_id + year,
                  data = dwellings, cluster = ~muni_id)
m_owner <- feols(log_owner ~ treated:post | muni_id + year,
                 data = dwellings, cluster = ~muni_id)

# Placebo time
permits_placebo <- permits %>% filter(year >= 2015, year <= 2019)
permits_placebo$post_placebo <- as.integer(permits_placebo$year >= 2018)
permits_placebo$muni_id <- as.numeric(factor(permits_placebo$muni_name))
permits_placebo$time_id <- as.numeric(factor(paste(permits_placebo$year, permits_placebo$quarter)))

m_plac <- feols(total_permits ~ treated:post_placebo | muni_id + time_id,
                data = permits_placebo, cluster = ~muni_id)

etable(m_plac, m_rental, m_owner,
       title = "Placebo Tests",
       headers = c("Placebo (2018)", "Log Rental Stock", "Log Owner Stock"),
       dict = c("treated:post_placebo" = "Treated $\\times$ Post (Placebo)",
                "treated:post" = "Treated $\\times$ Post"),
       notes = "Column (1): Placebo treatment date of 2018Q1 using 2015--2019 sample. Columns (2)--(3): Dwelling stock from Statistics Denmark BOL101 (annual, municipality-level). Owner-occupied dwelling stock serves as a placebo outcome.",
       label = "tab:placebo",
       file = paste0(tabdir, "tab4_placebo.tex"),
       replace = TRUE,
       style.tex = style.tex("aer"))

# ---- SDE Table (Appendix) ----
cat("Generating SDE table...\n")

# Main estimate: log total permits with restricted pre-period
beta_main <- coef(m_main2)[1]
se_main <- se(m_main2)[1]

# SD(Y) = pre-treatment SD of log permits in treated group
sd_y_main <- sd(permits_short$log_permits[permits_short$treated == 1 & permits_short$post == 0])

sde_main <- beta_main / sd_y_main
sde_se_main <- se_main / sd_y_main

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Multifamily
beta_multi <- coef(m_main4)[1]
se_multi <- se(m_main4)[1]
sd_y_multi <- sd(permits_short$log_multi[permits_short$treated == 1 & permits_short$post == 0])
sde_multi <- beta_multi / sd_y_multi
sde_se_multi <- se_multi / sd_y_multi

# Heterogeneity: urban vs semi-urban (split treated into large cities vs others)
large_cities <- c("København", "Aarhus", "Odense", "Aalborg", "Frederiksberg",
                  "Roskilde", "Esbjerg", "Kolding", "Vejle", "Horsens")

permits_urban <- permits_short %>%
  filter(treated == 1, muni_name %in% large_cities)
permits_urban$muni_id <- as.numeric(factor(permits_urban$muni_name))
permits_urban$time_id <- as.numeric(factor(paste(permits_urban$year, permits_urban$quarter)))

permits_nonurban <- permits_short %>%
  filter(treated == 1, !(muni_name %in% large_cities))
permits_nonurban$muni_id <- as.numeric(factor(permits_nonurban$muni_name))
permits_nonurban$time_id <- as.numeric(factor(paste(permits_nonurban$year, permits_nonurban$quarter)))

# Compare treated urban vs all control
perm_urban_ctrl <- bind_rows(
  permits_urban %>% mutate(treated = 1),
  permits_short %>% filter(treated == 0) %>%
    mutate(muni_id = as.numeric(factor(muni_name)))
)
perm_urban_ctrl$muni_id <- as.numeric(factor(perm_urban_ctrl$muni_name))
perm_urban_ctrl$time_id <- as.numeric(factor(paste(perm_urban_ctrl$year, perm_urban_ctrl$quarter)))

m_urban <- feols(log_permits ~ treated:post | muni_id + time_id,
                 data = perm_urban_ctrl, cluster = ~muni_id)

beta_urban <- coef(m_urban)[1]
se_urban <- se(m_urban)[1]
sd_y_urban <- sd(perm_urban_ctrl$log_permits[perm_urban_ctrl$treated == 1 & perm_urban_ctrl$post == 0])
sde_urban <- beta_urban / sd_y_urban
sde_se_urban <- se_urban / sd_y_urban

# Non-urban treated vs control
perm_nonurban_ctrl <- bind_rows(
  permits_nonurban %>% mutate(treated = 1),
  permits_short %>% filter(treated == 0) %>%
    mutate(muni_id = as.numeric(factor(muni_name)))
)
perm_nonurban_ctrl$muni_id <- as.numeric(factor(perm_nonurban_ctrl$muni_name))
perm_nonurban_ctrl$time_id <- as.numeric(factor(paste(perm_nonurban_ctrl$year, perm_nonurban_ctrl$quarter)))

m_nonurban <- feols(log_permits ~ treated:post | muni_id + time_id,
                    data = perm_nonurban_ctrl, cluster = ~muni_id)

beta_nonurban <- coef(m_nonurban)[1]
se_nonurban <- se(m_nonurban)[1]
sd_y_nonurban <- sd(perm_nonurban_ctrl$log_permits[perm_nonurban_ctrl$treated == 1 & perm_nonurban_ctrl$post == 0])
sde_nonurban <- beta_nonurban / sd_y_nonurban
sde_se_nonurban <- se_nonurban / sd_y_nonurban

# Build SDE table
sde_rows <- data.frame(
  panel = c("A", "A", "B", "B"),
  outcome = c("Log building permits (total)", "Log building permits (multifamily)",
              "Log permits (large cities)", "Log permits (other treated)"),
  beta = c(beta_main, beta_multi, beta_urban, beta_nonurban),
  se_b = c(se_main, se_multi, se_urban, se_nonurban),
  sd_y = c(sd_y_main, sd_y_multi, sd_y_urban, sd_y_nonurban),
  sde = c(sde_main, sde_multi, sde_urban, sde_nonurban),
  sde_se = c(sde_se_main, sde_se_multi, sde_se_urban, sde_se_nonurban),
  stringsAsFactors = FALSE
)
sde_rows$class <- sapply(sde_rows$sde, classify_sde)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Denmark. ",
  "\\textbf{Research question:} Does capping post-renovation rents (blocking \\S5 stk.\\ 2 renovation-to-relet arbitrage) deter municipal-level housing investment? ",
  "\\textbf{Policy mechanism:} The June 2020 Blackstone-Indgreb inserted a new paragraph blocking any rent increase above the regulated level after renovation in default-on municipalities, eliminating the renovation arbitrage channel that allowed investors to charge market rents post-renovation. ",
  "\\textbf{Outcome definition:} Log quarterly building permits from Statistics Denmark BYGV11, counting residential construction permits (total and multifamily subcategory) per municipality-quarter. ",
  "\\textbf{Treatment:} Binary; 80 municipalities subject to the default-on renovation cap vs.\\ 18 opt-out municipalities. ",
  "\\textbf{Data:} Statistics Denmark StatBank BYGV11, 2015Q1--2025Q4, municipality-quarter panel, 98 municipalities, 4,214 observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with municipality and quarter fixed effects; standard errors clustered at municipality level. ",
  "\\textbf{Sample:} Restricted to 2015+ pre-period for clean parallel trends; all 98 Danish municipalities included. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in which(sde_rows$panel == "A")) {
  sde_tex <- paste0(sde_tex, sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se_b[i], sde_rows$sd_y[i],
    sde_rows$sde[i], sde_rows$sde_se[i], sde_rows$class[i]))
}

sde_tex <- paste0(sde_tex,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by urbanization)}} \\\\\n"
)

for (i in which(sde_rows$panel == "B")) {
  sde_tex <- paste0(sde_tex, sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se_b[i], sde_rows$sd_y[i],
    sde_rows$sde[i], sde_rows$sde_se[i], sde_rows$class[i]))
}

sde_tex <- paste0(sde_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n")

writeLines(sde_tex, paste0(tabdir, "tabF1_sde.tex"))

cat("All tables saved.\n")
cat(sprintf("Total table files: %d\n", length(list.files(tabdir, pattern = "\\.tex$"))))
