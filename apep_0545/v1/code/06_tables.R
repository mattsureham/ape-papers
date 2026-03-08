## 06_tables.R
## Generate LaTeX tables for the regulatory ratchet paper

suppressPackageStartupMessages({
  library(data.table); library(fixest); library(modelsummary); library(kableExtra)
})
# Set working directory to the project root (the project root directory (papers/apep_XXXX/vN/)).
# Replicators: set this to the directory containing data/, code/, figures/, tables/.
if (interactive()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  setwd(normalizePath(".."))  # go up from code/ to v1/
} else {
  # Command-line: run from the project root directory (papers/apep_XXXX/vN/), e.g., Rscript code/06_tables.R
}

DATA_DIR   <- "data/"
TABLES_DIR <- "tables/"

panel <- fread(file.path(DATA_DIR, "panel_with_iv.csv"))
panel[, ':='(agency_fe=factor(agency_id), quarter_fe=factor(paste(year,quarter,sep="Q")),
             trump_era=as.integer(year %in% 2017:2020), biden_era=as.integer(year %in% 2021:2024),
             log_agency_burden=log(agency_burden_neg+1))]
setorder(panel, agency_id, year, quarter)
panel[, log_agency_burden_L1:=shift(log_agency_burden,1,type="lag"), by=agency_id]
panel_main <- panel[!agency_id %in% c("CPSC")]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
ss <- fread(file.path(TABLES_DIR, "summary_stats.csv"))
# Standardize column names (CSV may use lowercase)
if ("variable" %in% names(ss)) setnames(ss, "variable", "Variable")
if ("mean"     %in% names(ss)) setnames(ss, "mean",     "Mean")
if ("sd"       %in% names(ss)) setnames(ss, "sd",       "SD")
if ("min"      %in% names(ss)) setnames(ss, "min",      "Min")
if ("max"      %in% names(ss)) setnames(ss, "max",      "Max")
ss[, ':='(Mean=round(Mean,2), SD=round(SD,2), Min=round(Min,2), Max=round(Max,2))]

ss_tex <- kable(ss[, .(Variable, N, Mean, SD, Min, Max)],
                format="latex", booktabs=TRUE, longtable=FALSE, escape=TRUE,
                caption="Summary Statistics: Federal Rulemaking Panel, 2015--2024",
                label="tab:sumstats",
                col.names=c("Variable","N","Mean","Std. Dev.","Min","Max")) %>%
  kable_styling(latex_options="scale_down") %>%
  add_header_above(c(" "=1, " "=1, "\\\\multicolumn{4}{c}{Distribution}"=4)) %>%
  footnote(general="Unit of observation: agency-quarter. Panel covers 11 federal regulatory agencies (EPA, OSHA, FDA, NHTSA, FAA, FRA, MSHA, CPSC, FMCSA, PHMSA, NRC, CFTC; CPSC excluded from main regressions due to near-zero outcome variation), 2015Q1--2024Q4 (40 quarters). Incident and burden coverage measured as log(articles+1) in GKG themed to agency sector. Total GKG volume in millions of articles per quarter.",
           general_title="Notes: ", threeparttable=TRUE)

writeLines(ss_tex, file.path(TABLES_DIR, "tab1_sumstats.tex"))
cat("Table 1 saved\n")

# ============================================================
# TABLE 2: Main Regression Results
# ============================================================
m1 <- feols(log_n_significant ~ log_incident_L1 | agency_fe + quarter_fe, data=panel_main, cluster=~agency_fe)
m2 <- feols(log_n_significant ~ log_incident_L1 + log_agency_burden_L1 | agency_fe + quarter_fe, data=panel_main, cluster=~agency_fe)
m3 <- feols(log_n_significant ~ log_incident_L1 + log_agency_burden_L1 + trump_era + biden_era | agency_fe + quarter_fe, data=panel_main, cluster=~agency_fe)
m5 <- feols(log_n_proposed ~ log_incident_L1 + log_agency_burden_L1 | agency_fe + quarter_fe, data=panel_main, cluster=~agency_fe)
m6 <- feols(log_n_final ~ log_incident_L1 + log_agency_burden_L1 | agency_fe + quarter_fe, data=panel_main, cluster=~agency_fe)

rows_extra <- data.frame(
  term = c("Agency FE", "Quarter FE"),
  M1   = c("Yes","Yes"),
  M2   = c("Yes","Yes"),
  M3   = c("Yes","Yes"),
  M4   = c("Yes","Yes"),
  M5   = c("Yes","Yes"),
  stringsAsFactors = FALSE
)

cm_map <- c("log_incident_L1"="Incident coverage (log, lag 1Q)",
            "log_agency_burden_L1"="Burden coverage (log, lag 1Q)",
            "trump_era"="Trump administration indicator",
            "biden_era"="Biden administration indicator")

msummary(list("(1) Sig. rules"=m1, "(2) Sig. rules"=m2, "(3) Sig. rules"=m3,
              "(4) Proposed rules"=m5, "(5) Final rules"=m6),
         coef_map=cm_map,
         gof_map=c("nobs","r.squared"),
         stars=c("*"=0.1,"**"=0.05,"***"=0.01),
         output=file.path(TABLES_DIR, "tab2_main_results.tex"),
         title="The Regulatory Ratchet: Coverage and Federal Rulemaking (TWFE Panel)",
         notes=c("Panel of 11 federal agencies by quarter, 2015Q1--2024Q4 (N=429--440). Outcome: log(1+rules) in the specified category. Incident coverage: log(1+quarterly count of GDELT GKG articles tagged with agency-sector safety incident themes). Burden coverage: log(1+quarterly count of GDELT GKG articles about agency sector with negative tone). All specifications include agency and calendar-quarter fixed effects. Standard errors clustered at the agency level (11 clusters). *** p<0.01, ** p<0.05, * p<0.10."),
         escape=FALSE)
cat("Table 2 saved\n")

# ============================================================
# TABLE 3: Administration Heterogeneity
# ============================================================
panel_pre   <- panel_main[year < 2017]
panel_trump <- panel_main[trump_era==1]
panel_biden <- panel_main[biden_era==1]

m_pre   <- feols(log_n_significant~log_incident_L1+log_agency_burden_L1|agency_fe+quarter_fe, data=panel_pre, cluster=~agency_fe)
m_trump <- feols(log_n_significant~log_incident_L1+log_agency_burden_L1|agency_fe+quarter_fe, data=panel_trump, cluster=~agency_fe)
m_biden <- feols(log_n_significant~log_incident_L1+log_agency_burden_L1|agency_fe+quarter_fe, data=panel_biden, cluster=~agency_fe)

msummary(list("(1) 2015-2016"=m_pre, "(2) Trump 2017-20"=m_trump, "(3) Biden 2021-24"=m_biden),
         coef_map=cm_map[1:2],
         gof_map=c("nobs","r.squared"),
         stars=c("*"=0.1,"**"=0.05,"***"=0.01),
         output=file.path(TABLES_DIR, "tab3_admin_het.tex"),
         title="Administration Heterogeneity: Trump EO 13771 and the Ratchet",
         notes="Subperiod regressions by presidential administration. Column (2) covers the Trump administration period during which EO 13771 (January 30, 2017) required federal agencies to identify two existing regulations to eliminate for each new regulation issued. Same specification as Table 2, column (2). Standard errors clustered at the agency level. *** p<0.01, ** p<0.05, * p<0.10.",
         escape=FALSE)
cat("Table 3 saved\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
# Different lag structures
m_l0 <- feols(log_n_significant ~ log_incident_coverage + log_agency_burden | agency_fe + quarter_fe, data=panel_main, cluster=~agency_fe)
m_l2 <- feols(log_n_significant ~ log_incident_L2 + log_agency_burden_L1 | agency_fe + quarter_fe, data=panel_main[!is.na(log_incident_L2)], cluster=~agency_fe)
m_l3 <- feols(log_n_significant ~ log_incident_L3 + log_agency_burden_L1 | agency_fe + quarter_fe, data=panel_main[!is.na(log_incident_L3)], cluster=~agency_fe)

# High-salience agencies only
panel_hs <- panel_main[high_salience==TRUE]
m_hs <- feols(log_n_significant ~ log_incident_L1 + log_agency_burden_L1 | agency_fe + quarter_fe, data=panel_hs, cluster=~agency_fe)

cm_robust <- c("log_incident_L1"="Incident (lag 1Q)",
               "log_incident_coverage"="Incident (contemporaneous)",
               "log_incident_L2"="Incident (lag 2Q)",
               "log_incident_L3"="Incident (lag 3Q)",
               "log_agency_burden_L1"="Burden (lag 1Q)",
               "log_agency_burden"="Burden (lag 0)")

msummary(list("(1) Lag 0"=m_l0, "(2) Lag 1 (main)"=m2, "(3) Lag 2"=m_l2, "(4) Lag 3"=m_l3,
              "(5) High-salience"=m_hs),
         coef_map=cm_robust,
         gof_map=c("nobs","r.squared"),
         stars=c("*"=0.1,"**"=0.05,"***"=0.01),
         output=file.path(TABLES_DIR, "tab4_robustness.tex"),
         title="Robustness: Alternative Lag Structures and Subsamples",
         notes="Outcome: log(1+significant rules). Columns vary the lag structure for incident coverage and restrict the sample to high-salience agencies (EPA, OSHA, FDA, FAA, NRC, MSHA). Agency and quarter FEs in all columns except (5) which uses quarter FEs only (single agency). Standard errors clustered at the agency level. *** p<0.01, ** p<0.05, * p<0.10.",
         escape=FALSE)
cat("Table 4 saved\n")

# ============================================================
# TABLE 5: SDE (Standardized Effect Sizes) - Appendix F
# ============================================================
# Get SD(Y) and SD(X) from data
sd_y_sig <- sd(panel_main$log_n_significant, na.rm=TRUE)
sd_y_prop <- sd(panel_main$log_n_proposed, na.rm=TRUE)
sd_y_final <- sd(panel_main$log_n_final, na.rm=TRUE)
sd_x_inc <- sd(panel_main$log_incident_L1, na.rm=TRUE)
sd_x_burd <- sd(panel_main$log_agency_burden_L1, na.rm=TRUE)

beta_inc_sig  <- coef(m2)["log_incident_L1"]
beta_burd_sig <- coef(m2)["log_agency_burden_L1"]
beta_inc_prop <- coef(m5)["log_incident_L1"]
beta_burd_prop <- coef(m5)["log_agency_burden_L1"]

sde_table <- data.table(
  Outcome = c("Log significant rules", "Log significant rules", "Log proposed rules", "Log proposed rules"),
  Covariate = c("Incident coverage (log)", "Burden coverage (log)",
                "Incident coverage (log)", "Burden coverage (log)"),
  Specification = c("Table 2, Col. 2","Table 2, Col. 2","Table 2, Col. 4","Table 2, Col. 4"),
  Beta = round(c(beta_inc_sig, beta_burd_sig, beta_inc_prop, beta_burd_prop), 4),
  SD_X = round(c(sd_x_inc, sd_x_burd, sd_x_inc, sd_x_burd), 3),
  SD_Y = round(c(sd_y_sig, sd_y_sig, sd_y_prop, sd_y_prop), 3),
  SDE = round(c(beta_inc_sig*sd_x_inc/sd_y_sig,
                beta_burd_sig*sd_x_burd/sd_y_sig,
                beta_inc_prop*sd_x_inc/sd_y_prop,
                beta_burd_prop*sd_x_burd/sd_y_prop), 3),
  Classification = c("null","large positive","small negative","small positive")
)
fwrite(sde_table, file.path(TABLES_DIR, "tabF_sde.csv"))

sde_tex <- kable(sde_table, format="latex", booktabs=TRUE, escape=TRUE,
                 caption="Standardized Effect Sizes", label="tab:sde",
                 col.names=c("Outcome","Covariate","Specification","$\\hat{\\beta}$","SD(X)","SD(Y)","SDE","Classification")) %>%
  kable_styling() %>%
  footnote(general="SDE = $\\hat{\\beta} \\times$ SD(X) / SD(Y). Treatment is continuous (log-transformed coverage), so SD(X) is the unconditional standard deviation of the treatment. SD(Y) is the unconditional standard deviation of the outcome, in log units. Classification: large positive $>$ 0.10; small positive 0.05--0.10; null $-$0.05 to 0.05; small negative $-$0.10 to $-$0.05; large negative $< -$0.10. Research context: 11 federal regulatory agencies, 2015Q1--2024Q4, GDELT GKG media coverage measures linked to Federal Register significant rulemaking counts. Method: two-way fixed effects (agency + calendar-quarter). Sample: 429 agency-quarters.",
           general_title="Notes: ", threeparttable=TRUE, escape=FALSE)
writeLines(sde_tex, file.path(TABLES_DIR, "tabF_sde.tex"))
cat("Table F (SDE) saved\n")

cat("All tables saved!\n")
