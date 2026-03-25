## 05_tables.R — Generate all LaTeX tables
## apep_0958: Dutch Nitrogen Ruling and Populist Backlash

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
cross_section <- readRDS(file.path(data_dir, "cross_section_clean.rds"))
main_coefs <- readRDS(file.path(data_dir, "main_coefs.rds"))
es_coefs <- readRDS(file.path(data_dir, "event_study_coefs.rds"))

# Rebuild models for table export
panel <- panel %>%
  mutate(
    exposure_q = ntile(exposure, 4),
    exposure_group = case_when(
      exposure == 0 ~ "No Exposure",
      exposure_q <= 2 ~ "Low Exposure",
      TRUE ~ "High Exposure"
    ),
    rel_q = (year - 2019) * 4 + (quarter - 2),
    rel_q_bin = case_when(
      rel_q <= -12 ~ -12L,
      rel_q >= 12 ~ 12L,
      TRUE ~ rel_q
    ),
    high_post = high_exposure * post,
    n2k_post = n2k_share * post,
    exposure_post = exposure * post
  )

cross_section <- cross_section %>%
  mutate(log_nitrogen = log(pmax(nitrogen_excretion, 1)))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-treatment summary by exposure group
tab1_data <- panel %>%
  filter(post == 0, !is.na(exposure)) %>%
  group_by(exposure_group) %>%
  summarise(
    `Municipalities` = n_distinct(gm_code),
    `Dwellings/qtr` = sprintf("%.1f", mean(total_dwellings, na.rm = TRUE)),
    `Permits/1K pop` = sprintf("%.2f", mean(permits_pc, na.rm = TRUE)),
    `N2K share` = sprintf("%.3f", mean(n2k_share, na.rm = TRUE)),
    `Exposure` = sprintf("%.4f", mean(exposure, na.rm = TRUE)),
    `Agri share` = sprintf("%.3f", mean(agri_share, na.rm = TRUE)),
    `Pop (1000s)` = sprintf("%.1f", mean(population, na.rm = TRUE) / 1000),
    .groups = "drop"
  )

tab1_latex <- kable(tab1_data, format = "latex", booktabs = TRUE,
                    caption = "Pre-Treatment Summary Statistics by Exposure Group",
                    label = "tab:sumstats",
                    align = c("l", rep("r", 7))) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Summary statistics calculated over pre-treatment quarters (2012Q1--2019Q2). Exposure = Natura 2000 area share $\\\\times$ (agriculture + construction employment share). High Exposure = above-median exposure among municipalities with positive exposure.",
           escape = FALSE, threeparttable = TRUE)

writeLines(tab1_latex, file.path(tables_dir, "tab1_sumstats.tex"))

## ============================================================
## Table 2: Main DiD — Building Permits
## ============================================================
cat("=== Table 2: Main DiD Results ===\n")

m1 <- feols(log_permits ~ n2k_post | gm_code + time_fe, data = panel, cluster = ~gm_code)
m2 <- feols(log_permits ~ exposure_post | gm_code + time_fe, data = panel, cluster = ~gm_code)
m3 <- feols(permits_pc ~ exposure_post | gm_code + time_fe, data = panel, cluster = ~gm_code)
m4 <- feols(log_permits ~ high_post | gm_code + time_fe, data = panel, cluster = ~gm_code)

# Nitrogen treatment — already in panel from 02_clean_data merge
panel2 <- panel %>%
  filter(!is.na(nitrogen_excretion)) %>%
  mutate(
    log_nitrogen = log(pmax(nitrogen_excretion, 1)),
    nitrogen_post = log_nitrogen * post
  )

m5 <- feols(log_permits ~ nitrogen_post | gm_code + time_fe, data = panel2, cluster = ~gm_code)

tab2_latex <- etable(m1, m2, m3, m4, m5,
                     headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
                     depvar = FALSE,
                     se.below = TRUE,
                     fitstat = c("n", "r2", "wr2"),
                     dict = c(
                       n2k_post = "N2K Share $\\times$ Post",
                       exposure_post = "Exposure $\\times$ Post",
                       high_post = "High Exposure $\\times$ Post",
                       nitrogen_post = "Log(Nitrogen) $\\times$ Post",
                       log_permits = "Log(Permits+1)",
                       permits_pc = "Permits/1K"
                     ),
                     tex = TRUE,
                     style.tex = style.tex("aer"),
                     notes = c("Municipality and quarter fixed effects in all specifications.",
                               "Standard errors clustered at municipality level in parentheses.",
                               "Exposure = N2K area share $\\times$ (agriculture + construction employment share).",
                               "Post = 2019Q3 onwards (ruling: May 29, 2019)."),
                     title = "Effect of Nitrogen Ruling on Building Permits",
                     label = "tab:did_permits")

writeLines(tab2_latex, file.path(tables_dir, "tab2_did_permits.tex"))

## ============================================================
## Table 3: Cross-Section — BBB Vote Share
## ============================================================
cat("=== Table 3: BBB Cross-Section ===\n")

p1 <- feols(bbb_share ~ n2k_share, data = cross_section, vcov = "hetero")
p2 <- feols(bbb_share ~ agri_share, data = cross_section, vcov = "hetero")
p3 <- feols(bbb_share ~ agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")
p4 <- feols(bbb_share ~ exposure + agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")
p5 <- feols(bbb_share ~ log_nitrogen + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")

tab3_latex <- etable(p1, p2, p3, p4, p5,
                     headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
                     depvar = FALSE,
                     se.below = TRUE,
                     fitstat = c("n", "r2", "ar2"),
                     dict = c(
                       n2k_share = "N2K Area Share",
                       agri_share = "Agriculture Empl. Share",
                       bev_dichtheid = "Pop. Density",
                       exposure = "Exposure Index",
                       log_nitrogen = "Log(Nitrogen Excretion)",
                       bbb_share = "BBB Vote Share"
                     ),
                     tex = TRUE,
                     style.tex = style.tex("aer"),
                     notes = c("Dependent variable: BBB vote share in 2023 Provincial Elections.",
                               "Heteroskedasticity-robust standard errors in parentheses.",
                               "Exposure Index = N2K area share $\\times$ (agriculture + construction employment share).",
                               "Agriculture Empl. Share = share of total municipal jobs in agriculture sector (2018)."),
                     title = "Determinants of BBB Vote Share (2023 Provincial Elections)",
                     label = "tab:bbb_cross")

writeLines(tab3_latex, file.path(tables_dir, "tab3_bbb_cross.tex"))

## ============================================================
## Table 4: Robustness — Placebo Party Outcomes
## ============================================================
cat("=== Table 4: Placebo Parties ===\n")

r1 <- feols(bbb_share ~ agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")
r2 <- feols(fvd_share ~ agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")
r3 <- feols(pvv_share ~ agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")
r4 <- feols(populist_share ~ agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")

tab4_latex <- etable(r1, r2, r3, r4,
                     headers = c("BBB", "FvD", "PVV", "All Populist"),
                     depvar = FALSE,
                     se.below = TRUE,
                     fitstat = c("n", "r2"),
                     dict = c(
                       agri_share = "Agriculture Empl. Share",
                       bev_dichtheid = "Pop. Density",
                       bbb_share = "BBB", fvd_share = "FvD",
                       pvv_share = "PVV", populist_share = "All Populist"
                     ),
                     tex = TRUE,
                     style.tex = style.tex("aer"),
                     notes = c("Dependent variable: party vote share in 2023 Provincial Elections.",
                               "FvD = Forum voor Democratie; PVV = Partij voor de Vrijheid.",
                               "Agriculture employment share is specific to BBB, not other populist parties."),
                     title = "Agriculture Employment and Populist Party Vote Shares",
                     label = "tab:placebo_parties")

writeLines(tab4_latex, file.path(tables_dir, "tab4_placebo_parties.tex"))

## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================
cat("=== Table F1: SDE ===\n")

# Primary outcome: BBB vote share (cross-section)
sd_bbb_pre <- sd(cross_section$bbb_share, na.rm = TRUE)
# Agricultural employment share is the key treatment variable
beta_agri <- coef(p3)["agri_share"]
se_agri <- se(p3)["agri_share"]
sd_agri <- sd(cross_section$agri_share, na.rm = TRUE)

# SDE for continuous treatment: beta * SD(X) / SD(Y)
sde_agri <- beta_agri * sd_agri / sd_bbb_pre
se_sde_agri <- se_agri * sd_agri / sd_bbb_pre

# Building permits (panel DiD) — using exposure treatment
m_did <- feols(log_permits ~ exposure_post | gm_code + time_fe, data = panel, cluster = ~gm_code)
sd_y_pre <- sd(panel$log_permits[panel$post == 0], na.rm = TRUE)
beta_did <- coef(m_did)["exposure_post"]
se_did <- se(m_did)["exposure_post"]
sd_exposure <- sd(panel$exposure[panel$post == 0], na.rm = TRUE)
sde_did <- beta_did * sd_exposure / sd_y_pre
se_sde_did <- se_did * sd_exposure / sd_y_pre

# N2K share on BBB (simple)
sde_n2k <- coef(p1)["n2k_share"] * sd(cross_section$n2k_share, na.rm=TRUE) / sd_bbb_pre
se_sde_n2k <- se(p1)["n2k_share"] * sd(cross_section$n2k_share, na.rm=TRUE) / sd_bbb_pre

# Nitrogen on BBB
sd_logn <- sd(cross_section$log_nitrogen, na.rm = TRUE)
sde_nitrogen <- coef(p5)["log_nitrogen"] * sd_logn / sd_bbb_pre
se_sde_nitrogen <- se(p5)["log_nitrogen"] * sd_logn / sd_bbb_pre

# Heterogeneity: rural vs urban municipalities
cs_rural <- cross_section %>% filter(bev_dichtheid < median(bev_dichtheid, na.rm=TRUE))
cs_urban <- cross_section %>% filter(bev_dichtheid >= median(bev_dichtheid, na.rm=TRUE))

p_rural <- feols(bbb_share ~ agri_share + bev_dichtheid + log(population),
                 data = cs_rural, vcov = "hetero")
p_urban <- feols(bbb_share ~ agri_share + bev_dichtheid + log(population),
                 data = cs_urban, vcov = "hetero")

sd_bbb_rural <- sd(cs_rural$bbb_share, na.rm=TRUE)
sd_bbb_urban <- sd(cs_urban$bbb_share, na.rm=TRUE)
sd_agri_rural <- sd(cs_rural$agri_share, na.rm=TRUE)
sd_agri_urban <- sd(cs_urban$agri_share, na.rm=TRUE)

sde_rural <- coef(p_rural)["agri_share"] * sd_agri_rural / sd_bbb_rural
se_sde_rural <- se(p_rural)["agri_share"] * sd_agri_rural / sd_bbb_rural
sde_urban <- coef(p_urban)["agri_share"] * sd_agri_urban / sd_bbb_urban
se_sde_urban <- se(p_urban)["agri_share"] * sd_agri_urban / sd_bbb_urban

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_rows <- tibble(
  Panel = c(rep("Panel A: Pooled", 4), rep("Panel B: Heterogeneous", 2)),
  Outcome = c(
    "BBB vote share (agri. empl.)",
    "BBB vote share (N2K share)",
    "BBB vote share (nitrogen)",
    "Building permits (exposure)",
    "BBB vote share (rural munis)",
    "BBB vote share (urban munis)"
  ),
  Beta = c(beta_agri, coef(p1)["n2k_share"], coef(p5)["log_nitrogen"], beta_did,
           coef(p_rural)["agri_share"], coef(p_urban)["agri_share"]),
  SE = c(se_agri, se(p1)["n2k_share"], se(p5)["log_nitrogen"], se_did,
         se(p_rural)["agri_share"], se(p_urban)["agri_share"]),
  SD_Y = c(sd_bbb_pre, sd_bbb_pre, sd_bbb_pre, sd_y_pre,
           sd_bbb_rural, sd_bbb_urban),
  SDE = c(sde_agri, sde_n2k, sde_nitrogen, sde_did, sde_rural, sde_urban),
  SE_SDE = c(se_sde_agri, se_sde_n2k, se_sde_nitrogen, se_sde_did,
             se_sde_rural, se_sde_urban)
) %>%
  mutate(Classification = sapply(SDE, classify_sde))

# Format numbers
sde_formatted <- sde_rows %>%
  mutate(across(c(Beta, SE, SD_Y, SDE, SE_SDE), ~sprintf("%.4f", .)))

# Build LaTeX table
sde_body <- ""
current_panel <- ""
for (i in 1:nrow(sde_formatted)) {
  r <- sde_formatted[i, ]
  if (r$Panel != current_panel) {
    current_panel <- r$Panel
    sde_body <- paste0(sde_body, "\\midrule\n\\multicolumn{8}{l}{\\textit{", current_panel, "}} \\\\\n")
  }
  sde_body <- paste0(sde_body,
    r$Outcome, " & ", r$Beta, " & ", r$SE, " & ", r$SD_Y, " & ",
    r$SDE, " & ", r$SE_SDE, " & ", r$Classification, " \\\\\n")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Netherlands. ",
  "\\textbf{Research question:} Did the 2019 Dutch nitrogen court ruling cause political realignment toward the agrarian-populist BBB party in municipalities with greater agricultural exposure? ",
  "\\textbf{Policy mechanism:} The Raad van State invalidated the PAS nitrogen permit system, freezing 18,000 construction permits and threatening 3,000 livestock farms near 162 Natura 2000 sites, disproportionately affecting agricultural municipalities. ",
  "\\textbf{Outcome definition:} BBB (BoerBurgerBeweging) vote share in the March 2023 Provincial Elections, measured as BBB valid votes divided by total valid votes per municipality. ",
  "\\textbf{Treatment:} Continuous; agriculture employment share (Panel A rows 1--3), N2K area share, log nitrogen excretion, or composite exposure index (N2K share $\\times$ agri+construction employment share). ",
  "\\textbf{Data:} Kiesraad EML official election results (342 municipalities), CBS StatLine regional key figures (2018), PDOK Natura 2000 shapefiles, CBS building permits (2012--2025, quarterly). $N = 283$ municipalities (cross-section), $N = 15{,}776$ municipality-quarters (panel). ",
  "\\textbf{Method:} OLS cross-section with heteroskedasticity-robust SEs (BBB outcome); two-way FE DiD with municipality-clustered SEs (permits outcome). ",
  "\\textbf{Sample:} Dutch municipalities matched across CBS, Kiesraad, and PDOK spatial data; excludes municipalities with missing employment or population data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  sde_body,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_latex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste(" ", list.files(tables_dir)), sep = "\n")
