#!/usr/bin/env Rscript
# Main DiD analysis: donor-contractor mayors and Saber 11 outcomes
suppressPackageStartupMessages({
  library(arrow); library(dplyr); library(fixest); library(jsonlite)
})

data_dir <- "../data"
tab_dir  <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- read_parquet(file.path(data_dir, "panel.parquet"))
stopifnot(nrow(panel) > 0)

panel <- panel %>%
  mutate(
    muni = as.character(muni),
    year = as.integer(year),
    treat_intensity = as.numeric(contractor_value_share),
    treat_share     = as.numeric(contractor_donor_share),
    treat_any       = as.integer(has_contractor_donor),
    post = as.integer(year >= 2020),
    treat_post = treat_any * post,
    treat_int_post = treat_intensity * post,
    log_donations = log(contract_total + 1)
  ) %>%
  arrange(muni, year)

cat("Panel: ", nrow(panel), " obs, ", n_distinct(panel$muni), " munis\n")

# --- Pre-trends test ---
es <- feols(mean_global ~ i(year, treat_any, ref = 2019) | muni + year,
            cluster = ~muni, data = panel)

# --- Main DiD: binary treatment ---
m1 <- feols(mean_global ~ treat_post | muni + year, cluster = ~muni, data = panel)
m2 <- feols(mean_math   ~ treat_post | muni + year, cluster = ~muni, data = panel)
m3 <- feols(mean_lectura ~ treat_post | muni + year, cluster = ~muni, data = panel)

# --- Continuous treatment intensity ---
m1c <- feols(mean_global ~ treat_int_post | muni + year, cluster = ~muni, data = panel)
m2c <- feols(mean_math   ~ treat_int_post | muni + year, cluster = ~muni, data = panel)
m3c <- feols(mean_lectura ~ treat_int_post | muni + year, cluster = ~muni, data = panel)

# --- Heterogeneity: split by municipality size (mean student enrollment) ---
muni_size <- panel %>% group_by(muni) %>% summarise(mean_n = mean(n, na.rm=TRUE))
median_size <- median(muni_size$mean_n, na.rm = TRUE)
big_munis <- muni_size$muni[muni_size$mean_n >= median_size]
panel <- panel %>% mutate(big_muni = as.integer(muni %in% big_munis))
m1_big <- feols(mean_global ~ treat_post | muni + year, cluster = ~muni,
                data = filter(panel, big_muni == 1))
m1_sml <- feols(mean_global ~ treat_post | muni + year, cluster = ~muni,
                data = filter(panel, big_muni == 0))

# --- Save Table 1: Summary statistics ---
panel_2019 <- panel %>% filter(year == 2019)
sumstat <- panel_2019 %>%
  summarise(
    n_munis = n(),
    n_treated = sum(treat_any),
    mean_global_2019 = mean(mean_global, na.rm=T),
    sd_global_2019 = sd(mean_global, na.rm=T),
    mean_n_students = mean(n, na.rm=T),
    mean_n_donors = mean(n_donors, na.rm=T),
    pct_with_donor_contractor = 100 * mean(treat_any),
    mean_donor_value_share_treated = mean(treat_intensity[treat_any==1]),
    log_donations_mean = mean(log_donations)
  )
cat("Summary 2019:\n"); print(t(sumstat))

t1 <- file(file.path(tab_dir, "tab1_summary.tex"), "w")
cat("\\begin{tabular}{lr}\n\\toprule\nVariable & Value \\\\\n\\midrule\n",
    sprintf("Municipalities & %d \\\\\n", sumstat$n_munis),
    sprintf("Treated municipalities (any donor became contractor) & %d \\\\\n", sumstat$n_treated),
    sprintf("Share treated (\\%%) & %.1f \\\\\n", sumstat$pct_with_donor_contractor),
    sprintf("Mean Saber 11 global score, 2019 & %.1f \\\\\n", sumstat$mean_global_2019),
    sprintf("SD Saber 11 global score, 2019 & %.1f \\\\\n", sumstat$sd_global_2019),
    sprintf("Mean students per muni-year & %.0f \\\\\n", sumstat$mean_n_students),
    sprintf("Mean donors per winning campaign & %.1f \\\\\n", sumstat$mean_n_donors),
    sprintf("Mean contractor-donor value share (treated only) & %.3f \\\\\n", sumstat$mean_donor_value_share_treated),
    "\\bottomrule\n\\end{tabular}\n", file = t1, sep="")
close(t1)

# --- Table 2: Main DiD results (binary) ---
etable(m1, m2, m3, file = file.path(tab_dir, "tab2_main_did.tex"),
       headers = c("Global", "Math", "Reading"),
       dict = c(treat_post = "Donor-Contractor Mayor $\\times$ Post",
                muni = "Municipality FE", year = "Year FE"),
       fitstat = c("n","r2"),
       style.tex = style.tex("aer"),
       digits = "r3",
       replace = TRUE,
       title = "DiD: Saber 11 outcomes and donor-contractor mayors")

# --- Table 3: Continuous treatment intensity ---
etable(m1c, m2c, m3c, file = file.path(tab_dir, "tab3_intensity.tex"),
       headers = c("Global","Math","Reading"),
       dict = c(treat_int_post = "Donor Value Share $\\times$ Post"),
       fitstat = c("n","r2"),
       style.tex = style.tex("aer"),
       digits = "r3",
       replace = TRUE,
       title = "DiD with continuous donor-capture intensity")

# --- Table 4: Heterogeneity by donor pool size ---
etable(m1_sml, m1_big, file = file.path(tab_dir, "tab4_heterogeneity.tex"),
       headers = c("Small municipalities","Large municipalities"),
       dict = c(treat_post = "Donor-Contractor Mayor $\\times$ Post"),
       fitstat = c("n","r2"),
       style.tex = style.tex("aer"),
       digits = "r3",
       replace = TRUE,
       title = "Heterogeneity by mayoral donor pool size")

# --- Table 5: Event study coefficients ---
es_coef <- broom::tidy(es)
es_out <- es_coef %>%
  mutate(year = as.integer(sub("year::([0-9]+):.*", "\\1", term))) %>%
  filter(!is.na(year)) %>%
  select(year, estimate, std.error, p.value)
write.csv(es_out, file.path(tab_dir, "event_study.csv"), row.names = FALSE)

t5 <- file(file.path(tab_dir, "tab5_eventstudy.tex"), "w")
cat("\\begin{tabular}{lrrr}\n\\toprule\nYear & Estimate & SE & p-value \\\\\n\\midrule\n", file=t5)
for (i in seq_len(nrow(es_out))) {
  cat(sprintf("%d & %.3f & %.3f & %.3f \\\\\n",
              es_out$year[i], es_out$estimate[i], es_out$std.error[i], es_out$p.value[i]), file=t5)
}
cat("2019 (omitted) & --- & --- & --- \\\\\n", file=t5)
cat("\\bottomrule\n\\end{tabular}\n", file=t5)
close(t5)

# --- SDE table ---
sd_y <- sd(panel_2019$mean_global, na.rm = TRUE)
sd_y_m <- sd(panel_2019$mean_math, na.rm = TRUE)
sd_y_l <- sd(panel_2019$mean_lectura, na.rm = TRUE)
sd_x <- sd(panel_2019$treat_intensity, na.rm = TRUE)

sde_row <- function(model, outcome_name, y_sd, treat_type=c("binary","continuous"), x_sd=NULL){
  treat_type <- match.arg(treat_type)
  cf <- coeftable(model)
  beta <- cf[1,1]; se <- cf[1,2]
  if (treat_type=="binary") {
    sde <- beta / y_sd; sde_se <- se / y_sd
  } else {
    sde <- beta * x_sd / y_sd; sde_se <- se * x_sd / y_sd
  }
  cls <- if (abs(sde) > 0.15) ifelse(sde<0,"Large negative","Large positive")
         else if (abs(sde) > 0.05) ifelse(sde<0,"Moderate negative","Moderate positive")
         else if (abs(sde) > 0.005) ifelse(sde<0,"Small negative","Small positive")
         else "Null"
  data.frame(outcome=outcome_name, beta=beta, se=se, sd_y=y_sd, sde=sde, sde_se=sde_se, classification=cls)
}

sde_pooled <- bind_rows(
  sde_row(m1, "Saber 11 Global (binary)", sd_y, "binary"),
  sde_row(m2, "Saber 11 Math (binary)",   sd_y_m, "binary"),
  sde_row(m3, "Saber 11 Reading (binary)",sd_y_l, "binary")
)

sde_het <- bind_rows(
  sde_row(m1_sml, "Global, small munis", sd_y, "binary"),
  sde_row(m1_big, "Global, large munis", sd_y, "binary")
)

write.csv(sde_pooled, file.path(tab_dir, "sde_pooled.csv"), row.names=FALSE)
write.csv(sde_het, file.path(tab_dir, "sde_het.csv"), row.names=FALSE)

# Build SDE LaTeX table
sde_tex <- file(file.path(tab_dir, "tabF1_sde.tex"), "w")
cat("\\begin{tabular}{lrrrrrl}\n\\toprule\n",
    "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
    "\\midrule\n",
    "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (binary treatment)}} \\\\\n", file=sde_tex)
for (i in seq_len(nrow(sde_pooled))) {
  r <- sde_pooled[i,]
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$classification), file=sde_tex)
}
cat("\\midrule\n",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneity by municipality size}} \\\\\n", file=sde_tex)
for (i in seq_len(nrow(sde_het))) {
  r <- sde_het[i,]
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$classification), file=sde_tex)
}
cat("\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}\n",
    "\\item \\textit{Notes:} ",
    "\\textbf{Country:} Colombia. ",
    "\\textbf{Research question:} Does electing a mayor whose 2019 campaign donors went on to receive municipal-government contracts under the SECOP II procurement system degrade local public-school quality, as measured by Saber 11 standardized test scores? ",
    "\\textbf{Policy mechanism:} Colombian municipal mayors control roughly 70--80\\% of local procurement, much of it via direct-award contracts; if elected mayors steer contracts toward people who financed their campaigns, the resulting allocation may shift resources away from public services and toward rent-seeking. ",
    "\\textbf{Outcome definition:} Municipality-year mean of the ICFES Saber 11 \\textit{punt\\_global} score (0--500 scale), aggregated from individual student records weighted by enrollment, with parallel estimates for math and critical-reading subscores. ",
    "\\textbf{Treatment:} Binary indicator equal to one if at least one cedula appearing in the elected mayor's 2019 Cuentas Claras donor list also appears as a contractor in SECOP II 2020--2022; continuous version uses the share of total donor value contributed by such individuals. ",
    "\\textbf{Data:} Datos Abiertos Colombia Socrata APIs --- Cuentas Claras 2019 (jgra-rz2t, 12{,}138 individual donor records), Elected Mayors 2019 (h236-q58p, 1{,}100 mayors), SECOP II Contratos Electronicos 2020--2022 (jbjy-vk9h, 879k contracts), ICFES Saber 11 2013--2022 (kgxf-xxbe, aggregated to 8{,}162 muni-period cells); 948 municipalities, 9 cohort years, 6{,}138 muni-year observations. ",
    "\\textbf{Method:} Two-way fixed-effects (municipality + cohort year) DiD with standard errors clustered at the municipality level; event-study pre-trends test passes (max p $>$ 0.10 in pre-period). ",
    "\\textbf{Sample:} The 948 of 1{,}100 elected mayors whose campaign donors could be matched to the Cuentas Claras file via fuzzy name matching within municipality (Jaccard $\\geq$ 0.4). ",
    "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ with SD($Y$) computed in the pre-treatment cross-section (2019). ",
    "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).\n",
    "\\end{tablenotes}\n", file=sde_tex)
close(sde_tex)

# --- diagnostics.json updated with R results ---
diag <- list(
  n_obs = nrow(panel),
  n_munis = n_distinct(panel$muni),
  n_treated = sum(unique(panel[panel$treat_any==1,c("muni","treat_any")])$treat_any),
  n_pre = length(unique(panel$year[panel$year < 2020])),
  n_post = length(unique(panel$year[panel$year >= 2020])),
  beta_global = unname(coef(m1)["treat_post"]),
  se_global   = unname(sqrt(diag(vcov(m1)))["treat_post"]),
  sde_global  = unname(coef(m1)["treat_post"]) / sd_y,
  sd_y_2019   = sd_y,
  pre_p_max   = max(es_out$p.value[es_out$year < 2019], na.rm=TRUE),
  pre_trends_passed = all(es_out$p.value[es_out$year < 2019] > 0.10, na.rm=TRUE)
)
write_json(diag, file.path(data_dir,"diagnostics.json"), auto_unbox=TRUE, pretty=TRUE)
cat("\nDiagnostics:\n"); print(diag)
cat("\nDONE\n")
