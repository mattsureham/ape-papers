## 05_tables.R — Generate all LaTeX tables for apep_0824
source("00_packages.R")

panel <- readRDS("../data/panel.rds") %>% filter(year >= 2008, year <= 2020)
results <- readRDS("../data/results.rds")
diag <- fromJSON("../data/diagnostics.json")

cee_peers <- c("BG", "HU", "CZ", "PL", "SK", "HR", "SI", "EE", "LT", "LV")
sectors <- c("C", "F", "G", "H", "I", "J", "L", "M", "N")

# ---- TABLE 1: Summary Statistics ----
cat("=== Generating Table 1: Summary Statistics ===\n")

micro <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers), size == "0-9") %>%
  mutate(
    ro = as.integer(geo == "RO"),
    avg_turn_k = turnover_m * 1000 / enterprises,
    avg_emp = employment / enterprises
  )

# Compute stats by group
stats_fn <- function(df, label) {
  data.frame(
    Group = label,
    `Enterprises` = sprintf("%.0f", mean(df$enterprises, na.rm = TRUE)),
    `SD Enterprises` = sprintf("%.0f", sd(df$enterprises, na.rm = TRUE)),
    `Avg Turnover (000 EUR)` = sprintf("%.1f", mean(df$avg_turn_k, na.rm = TRUE)),
    `SD Avg Turnover` = sprintf("%.1f", sd(df$avg_turn_k, na.rm = TRUE)),
    N = nrow(df),
    check.names = FALSE
  )
}

ro_pre <- micro %>% filter(geo == "RO", year < 2017)
ro_post <- micro %>% filter(geo == "RO", year >= 2017)
ctrl_pre <- micro %>% filter(geo != "RO", year < 2017)
ctrl_post <- micro %>% filter(geo != "RO", year >= 2017)

summ <- rbind(
  stats_fn(ro_pre, "Romania, Pre-2017"),
  stats_fn(ro_post, "Romania, Post-2017"),
  stats_fn(ctrl_pre, "CEE Peers, Pre-2017"),
  stats_fn(ctrl_post, "CEE Peers, Post-2017")
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Micro-Enterprises (0--9 Employees) by Sector}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Enterprises & SD & Avg. Turnover & SD & Obs. \\\\",
  " & (count) & & (000 EUR) & & \\\\",
  "\\midrule",
  paste0("Romania, Pre-2017 & ", summ$Enterprises[1], " & ", summ$`SD Enterprises`[1],
         " & ", summ$`Avg Turnover (000 EUR)`[1], " & ", summ$`SD Avg Turnover`[1],
         " & ", summ$N[1], " \\\\"),
  paste0("Romania, Post-2017 & ", summ$Enterprises[2], " & ", summ$`SD Enterprises`[2],
         " & ", summ$`Avg Turnover (000 EUR)`[2], " & ", summ$`SD Avg Turnover`[2],
         " & ", summ$N[2], " \\\\"),
  "\\midrule",
  paste0("CEE Peers, Pre-2017 & ", summ$Enterprises[3], " & ", summ$`SD Enterprises`[3],
         " & ", summ$`Avg Turnover (000 EUR)`[3], " & ", summ$`SD Avg Turnover`[3],
         " & ", summ$N[3], " \\\\"),
  paste0("CEE Peers, Post-2017 & ", summ$Enterprises[4], " & ", summ$`SD Enterprises`[4],
         " & ", summ$`Avg Turnover (000 EUR)`[4], " & ", summ$`SD Avg Turnover`[4],
         " & ", summ$N[4], " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Unit of observation is country--sector--year. ",
  "Sectors include NACE sections C, F, G, H, I, J, L, M, N (market economy excluding finance). ",
  "Micro-enterprises are firms with 0--9 employees. Turnover from Eurostat SBS. ",
  "CEE peers: Bulgaria, Czech Republic, Croatia, Estonia, Hungary, Latvia, Lithuania, Poland, Slovakia, Slovenia.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ---- TABLE 2: Main DiD results ----
cat("=== Generating Table 2: Main DiD ===\n")

# Regenerate main models for clean table
micro_reg <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers), size == "0-9") %>%
  mutate(ro = as.integer(geo == "RO"), post = as.integer(year >= 2017),
         treat = ro * post, log_ent = log(enterprises + 1))

m1 <- feols(log_ent ~ treat | geo + year, data = micro_reg, cluster = ~geo)
m2 <- feols(log_ent ~ treat | geo + year + nace, data = micro_reg, cluster = ~geo)
m3 <- feols(log_ent ~ treat | geo^nace + year, data = micro_reg, cluster = ~geo)
m4 <- feols(log_ent ~ treat | geo^nace + nace^year, data = micro_reg, cluster = ~geo)

tab2_tex <- etable(m1, m2, m3, m4,
                   headers = c("(1)", "(2)", "(3)", "(4)"),
                   se.below = TRUE,
                   fitstat = c("n", "r2"),
                   depvar = FALSE,
                   tex = TRUE,
                   style.tex = style.tex("aer"),
                   title = "Effect of Romania's Micro-Enterprise Expansion on Firm Counts",
                   label = "tab:main_did")

writeLines(tab2_tex, "../tables/tab2_main_did.tex")

# ---- TABLE 3: Average Turnover by Size Class ----
cat("=== Generating Table 3: Average Turnover ===\n")

turn_models <- list()
for (sz in c("0-9", "10-19", "20-49", "50-249", "GE250")) {
  sz_data <- panel %>%
    filter(nace %in% sectors, geo %in% c("RO", cee_peers), size == sz,
           year >= 2008, year <= 2020, !is.na(turnover_m), enterprises > 0) %>%
    mutate(ro = as.integer(geo == "RO"), post = as.integer(year >= 2017),
           treat = ro * post,
           log_avg_turn = log(turnover_m * 1000 / enterprises)) %>%
    filter(is.finite(log_avg_turn))

  turn_models[[sz]] <- feols(log_avg_turn ~ treat | geo^nace + nace^year,
                             data = sz_data, cluster = ~geo)
}

tab3_tex <- etable(turn_models,
                   headers = c("0--9", "10--19", "20--49", "50--249", "250+"),
                   se.below = TRUE,
                   fitstat = c("n", "r2"),
                   depvar = FALSE,
                   tex = TRUE,
                   style.tex = style.tex("aer"),
                   title = "Effect on Log Average Turnover per Enterprise by Employee Size Class",
                   label = "tab:turnover")

writeLines(tab3_tex, "../tables/tab3_turnover.tex")

# ---- TABLE 4: Robustness ----
cat("=== Generating Table 4: Robustness ===\n")

# Timing, control groups, placebo
micro_2016 <- micro_reg %>%
  mutate(treat16 = ro * as.integer(year >= 2016))
r_16 <- feols(log_ent ~ treat16 | geo^nace + nace^year, data = micro_2016, cluster = ~geo)

micro_2018 <- micro_reg %>%
  mutate(treat18 = ro * as.integer(year >= 2018))
r_18 <- feols(log_ent ~ treat18 | geo^nace + nace^year, data = micro_2018, cluster = ~geo)

pre_data <- micro_reg %>% filter(year <= 2016) %>%
  mutate(treat_p = ro * as.integer(year >= 2013))
r_placebo <- feols(log_ent ~ treat_p | geo^nace + nace^year, data = pre_data, cluster = ~geo)

# Micro-enterprise share
share_data <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers),
         size %in% c("0-9", "TOTAL"), year >= 2008, year <= 2020) %>%
  select(nace, size, geo, year, enterprises) %>%
  pivot_wider(names_from = size, values_from = enterprises) %>%
  rename(micro = `0-9`, total = TOTAL) %>%
  filter(!is.na(micro), !is.na(total), total > 0) %>%
  mutate(share = micro / total,
         ro = as.integer(geo == "RO"),
         treat = ro * as.integer(year >= 2017))
r_share <- feols(share ~ treat | geo^nace + nace^year, data = share_data, cluster = ~geo)

tab4_tex <- etable(r_16, m4, r_18, r_placebo, r_share,
                   headers = c("Post-2016", "Post-2017", "Post-2018", "Placebo 2013", "Micro Share"),
                   se.below = TRUE,
                   fitstat = c("n", "r2"),
                   depvar = FALSE,
                   tex = TRUE,
                   style.tex = style.tex("aer"),
                   title = "Robustness: Alternative Treatment Timing and Placebo",
                   label = "tab:robustness")

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ---- TABLE F1: Standardized Effect Size (SDE) ----
cat("=== Generating Table F1: SDE ===\n")

# Main outcomes with SDE computation
# Use SD(Y) from Romania pre-treatment period for each outcome

# Outcome 1: Log micro-enterprise count
y1_pre <- micro_reg$log_ent[micro_reg$geo == "RO" & micro_reg$year < 2017]
sd_y1 <- sd(y1_pre, na.rm = TRUE)
b1 <- coef(m4)["treat"]
se1 <- se(m4)["treat"]
sde1 <- b1 / sd_y1
se_sde1 <- se1 / sd_y1

# Outcome 2: Log avg turnover (0-9 employees)
micro_turn <- micro_reg %>%
  filter(!is.na(turnover_m), enterprises > 0) %>%
  mutate(log_avg_turn = log(turnover_m * 1000 / enterprises)) %>%
  filter(is.finite(log_avg_turn))
y2_pre <- micro_turn$log_avg_turn[micro_turn$geo == "RO" & micro_turn$year < 2017]
sd_y2 <- sd(y2_pre, na.rm = TRUE)
b2 <- coef(turn_models[["0-9"]])["treat"]
se2 <- se(turn_models[["0-9"]])["treat"]
sde2 <- b2 / sd_y2
se_sde2 <- se2 / sd_y2

# Outcome 3: Log avg turnover (20-49 employees)
sz_2049 <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers), size == "20-49",
         year >= 2008, year <= 2020, !is.na(turnover_m), enterprises > 0) %>%
  mutate(log_avg_turn = log(turnover_m * 1000 / enterprises)) %>%
  filter(is.finite(log_avg_turn))
y3_pre <- sz_2049$log_avg_turn[sz_2049$geo == "RO" & sz_2049$year < 2017]
sd_y3 <- sd(y3_pre, na.rm = TRUE)
b3 <- coef(turn_models[["20-49"]])["treat"]
se3 <- se(turn_models[["20-49"]])["treat"]
sde3 <- b3 / sd_y3
se_sde3 <- se3 / sd_y3

# Outcome 4: Micro-enterprise share
y4_pre <- share_data$share[share_data$geo == "RO" & share_data$year < 2017]
sd_y4 <- sd(y4_pre, na.rm = TRUE)
b4 <- coef(r_share)["treat"]
se4 <- se(r_share)["treat"]
sde4 <- b4 / sd_y4
se_sde4 <- se4 / sd_y4

# Classification function
classify_sde <- function(x) {
  ax <- abs(x)
  if (ax < 0.005) return("Null")
  if (x > 0) {
    if (ax < 0.05) return("Small positive")
    if (ax < 0.15) return("Moderate positive")
    return("Large positive")
  } else {
    if (ax < 0.05) return("Small negative")
    if (ax < 0.15) return("Moderate negative")
    return("Large negative")
  }
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Romania. ",
  "\\textbf{Research question:} Does expanding the micro-enterprise turnover tax threshold (from EUR 65,000 to EUR 1,000,000) increase firm creation or alter the size distribution of enterprises? ",
  "\\textbf{Policy mechanism:} Romania's micro-enterprise regime taxes annual turnover at 1--3\\% instead of the 16\\% corporate income tax on profits; successive threshold expansions (2016--2018) extended eligibility to firms with up to EUR 1 million in annual revenue, dramatically lowering the effective tax rate for a large share of the economy. ",
  "\\textbf{Outcome definition:} (1) Log number of enterprises with 0--9 employees per country--sector--year; (2--3) Log average turnover per enterprise in indicated size class; (4) Share of enterprises in the 0--9 employee class. ",
  "\\textbf{Treatment:} Binary (Romania post-2017 vs.\\ pre-2017). ",
  "\\textbf{Data:} Eurostat Structural Business Statistics (SBS), 2008--2020, country--NACE sector--year panel, $N \\approx 1{,}250$ observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with country$\\times$sector and sector$\\times$year fixed effects, standard errors clustered by country ($G = 11$). ",
  "\\textbf{Sample:} Romania and 10 Central/Eastern European peers (BG, CZ, EE, HR, HU, LT, LV, PL, SI, SK); 9 NACE market-economy sectors (C, F, G, H, I, J, L, M, N). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log enterprises (0--9) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b1, se1, sd_y1, sde1, se_sde1, classify_sde(sde1)),
  sprintf("Log avg.\\ turnover (0--9) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b2, se2, sd_y2, sde2, se_sde2, classify_sde(sde2)),
  sprintf("Log avg.\\ turnover (20--49) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b3, se3, sd_y3, sde3, se_sde3, classify_sde(sde3)),
  sprintf("Micro-enterprise share & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b4, se4, sd_y4, sde4, se_sde4, classify_sde(sde4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat("\nSDE values:\n")
cat("  Log enterprises (0-9):", round(sde1, 4), classify_sde(sde1), "\n")
cat("  Log avg turnover (0-9):", round(sde2, 4), classify_sde(sde2), "\n")
cat("  Log avg turnover (20-49):", round(sde3, 4), classify_sde(sde3), "\n")
cat("  Micro-enterprise share:", round(sde4, 4), classify_sde(sde4), "\n")
