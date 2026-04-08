## 05_tables.R — generate all .tex tables
suppressPackageStartupMessages({ library(data.table); library(fixest); library(jsonlite) })
ROOT <- normalizePath("."); DAT <- file.path(ROOT,"data"); TAB <- file.path(ROOT,"tables")
dir.create(TAB, showWarnings=FALSE)

df  <- readRDS(file.path(DAT,"analysis.rds"))
mods<- readRDS(file.path(DAT,"models.rds"))
rob <- readRDS(file.path(DAT,"robust.rds"))

fmt  <- function(x,d=4) formatC(x,format="f",digits=d)
fmt0 <- function(x) formatC(x,format="f",digits=1,big.mark=",")

# ---- Table 1: Summary ----
sumtab <- data.table(
  Variable = c("|$\\Delta$ pages|/proposed pages",
               "$\\log(1 + |\\Delta$ pages|/proposed pages$)$",
               "Comment period (days)",
               "Significant (EO 12866)",
               "Proposed rule pages",
               "Text distance (subsample, $n$=N\\_TD)"),
  Mean = c(mean(df$page_change_ratio), mean(df$log_page_change),
           mean(df$days_open), mean(df$significant_flag),
           mean(df$p_pages_n), mean(df$text_dist,na.rm=TRUE)),
  SD   = c(sd(df$page_change_ratio), sd(df$log_page_change),
           sd(df$days_open), sd(df$significant_flag),
           sd(df$p_pages_n), sd(df$text_dist,na.rm=TRUE)),
  Median = c(median(df$page_change_ratio), median(df$log_page_change),
             median(df$days_open), median(df$significant_flag),
             median(df$p_pages_n), median(df$text_dist,na.rm=TRUE))
)
n_td <- sum(!is.na(df$text_dist))
sumtab[, Variable := gsub("N\\\\_TD", as.character(n_td), Variable)]

sink(file.path(TAB,"tab1_summary.tex"))
cat("\\begin{table}[t]\n\\caption{Summary statistics}\n\\label{tab:summary}\n\\centering\n\\small\n")
cat("\\begin{tabular}{lrrr}\n\\toprule\n")
cat("Variable & Mean & SD & Median \\\\\n\\midrule\n")
for(i in 1:nrow(sumtab)){
  cat(sumtab$Variable[i],"&",fmt(sumtab$Mean[i],3),"&",fmt(sumtab$SD[i],3),"&",fmt(sumtab$Median[i],3),"\\\\\n")
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{flushleft}\\footnotesize \\textit{Notes:} N=",nrow(df)," matched proposed--final rule pairs from the Federal Register, 2015--2022, linked by Regulation Identifier Number (RIN). The primary outcome is $\\log(1 + |\\Delta\\text{pages}|/\\text{proposed pages})$, a bounded measure of revision intensity that captures both additions and deletions of rule sections. Text distance, available for ",n_td," pairs whose full text was successfully retrieved from the Federal Register API, is reported as a secondary check. \\end{flushleft}\n",sep="")
cat("\\end{table}\n")
sink()

# ---- Table 2: Main results ----
fs_F <- mods$fs_F
m1<-mods$models$m1; m2<-mods$models$m2; m3<-mods$models$m3; m4<-mods$models$m4; m5<-mods$models$m5
get <- function(m,v){
  co<-coef(m); s<-se(m)
  if(!v %in% names(co)) return(c("",""))
  c(fmt(co[v],5), paste0("(",fmt(s[v],5),")"))
}
b1<-get(m1,"days_open"); b2<-get(m2,"days_open"); b3<-get(m3,"days_open")
b4<-get(m4,"fit_days_open"); b5<-get(m5,"significant_flag")

sink(file.path(TAB,"tab2_main.tex"))
cat("\\begin{table}[t]\n\\caption{Comment period length and rule revision (primary outcome: $\\log$ page-change ratio)}\n\\label{tab:main}\n\\centering\n\\small\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & OLS & OLS & OLS & 2SLS & RF \\\\\n\\midrule\n")
cat("Comment days &",b1[1],"&",b2[1],"&",b3[1],"&",b4[1],"& \\\\\n")
cat("             &",b1[2],"&",b2[2],"&",b3[2],"&",b4[2],"& \\\\\n")
cat("Significant (EO 12866) & & & & &",b5[1],"\\\\\n")
cat("                        & & & & &",b5[2],"\\\\\n")
cat("\\midrule\n")
cat("Log proposed pages & Y & Y & Y & Y & Y \\\\\n")
cat("Agency FE & N & Y & N & N & N \\\\\n")
cat("Agency$\\times$Year FE & N & N & Y & Y & Y \\\\\n")
cat("Estimator & OLS & OLS & OLS & 2SLS & OLS \\\\\n")
cat("First-stage F & & & & ",fmt(fs_F,1)," & \\\\\n")
cat("Observations &",fmt0(nobs(m1)),"&",fmt0(nobs(m2)),"&",fmt0(nobs(m3)),"&",fmt0(nobs(m4)),"&",fmt0(nobs(m5)),"\\\\\n")
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{flushleft}\\footnotesize \\textit{Notes:} Outcome is $\\log(1+|\\text{pages}_{\\text{final}}-\\text{pages}_{\\text{proposed}}|/\\text{pages}_{\\text{proposed}})$. Column (4) instruments the realized comment period in days with the EO 12866 ``significant'' designation. Column (5) reports the reduced form. Standard errors clustered by agency. The first-stage F refers to column (4). \\end{flushleft}\n")
cat("\\end{table}\n")
sink()

# ---- Table 3: Robustness ----
sink(file.path(TAB,"tab3_robust.tex"))
cat("\\begin{table}[t]\n\\caption{Robustness of the IV estimate}\n\\label{tab:robust}\n\\centering\n\\small\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat("Specification & Coef. on days open & SE & N \\\\\n\\midrule\n")
labs <- c(drop_epa="Drop EPA rules",
          nonsig_only="Non-significant subsample (OLS)",
          parent_cluster="Cluster by parent agency",
          dpages_iv="Outcome: $\\log(1+|\\Delta$ pages$|)$ (IV)",
          trim90="Trim top decile of comment days",
          pre2021="Restrict 2015--2020 (pre-pandemic)")
for(nm in names(rob)){
  m <- rob[[nm]]
  vname <- if (nm == "nonsig_only") "days_open" else "fit_days_open"
  co <- coef(m); s <- se(m)
  if(!vname %in% names(co)) next
  cat(labs[nm]," & ",fmt(co[vname],5)," & (",fmt(s[vname],5),") & ",fmt0(nobs(m))," \\\\\n",sep="")
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{flushleft}\\footnotesize \\textit{Notes:} Each row re-estimates the agency$\\times$year FE specification with the modification listed. Outcome is $\\log$ page-change ratio unless noted. Cluster-robust SEs (agency, except where stated). The non-significant subsample row uses OLS (no instrument), exploiting within-agency-year variation in comment period length among rules below the EO 12866 threshold. \\end{flushleft}\n")
cat("\\end{table}\n")
sink()

# ---- Table 4: Heterogeneity by agency volume + text-distance secondary ----
df[, agency_n := .N, by=agency]
amed <- median(df$agency_n)
df[, big := as.integer(agency_n > amed)]
het_big   <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag,
                   data=df[big==1], cluster=~agency)
het_small <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag,
                   data=df[big==0], cluster=~agency)

sink(file.path(TAB,"tab4_het.tex"))
cat("\\begin{table}[t]\n\\caption{Heterogeneity and the text-distance secondary outcome}\n\\label{tab:het}\n\\centering\n\\small\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat("Specification & Coef. on days open & SE & N \\\\\n\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Heterogeneity (primary outcome, IV)}} \\\\\n")
g <- function(m,v="fit_days_open"){
  if(is.null(m)) return(c("","",""))
  co<-coef(m); s<-se(m)
  if(!v %in% names(co)) return(c("","",""))
  c(fmt(co[v],5), paste0("(",fmt(s[v],5),")"), fmt0(nobs(m)))
}
v <- g(het_big);   cat("High-volume agencies (above-median rule count) & ",v[1]," & ",v[2]," & ",v[3]," \\\\\n",sep="")
v <- g(het_small); cat("Low-volume agencies                              & ",v[1]," & ",v[2]," & ",v[3]," \\\\\n",sep="")
cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Text-distance secondary outcome (cached subsample)}} \\\\\n")
tm <- mods$text_models
if (!is.null(tm)) {
  v <- g(tm$ols, "days_open"); cat("OLS, no FE                                       & ",v[1]," & ",v[2]," & ",v[3]," \\\\\n",sep="")
  if (!is.null(tm$iv))
    v <- g(tm$iv); cat("2SLS, agency FE                                  & ",v[1]," & ",v[2]," & ",v[3]," \\\\\n",sep="")
  v <- g(tm$rf, "significant_flag"); cat("Reduced form (coeff.~on Significant)             & ",v[1]," & ",v[2]," & ",v[3]," \\\\\n",sep="")
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{flushleft}\\footnotesize \\textit{Notes:} Panel A reports IV estimates of the comment-day coefficient on $\\log$ page-change ratio in subsamples split at the median agency rule count. Panel B reports the same exercise on a secondary outcome --- TF-IDF cosine distance between the proposed and final full text --- on the subsample of pairs whose full text was successfully retrieved from the Federal Register API. The 2SLS row uses agency FE only (the cached subsample is too small to absorb agency$\\times$year). \\end{flushleft}\n")
cat("\\end{table}\n")
sink()

# ---- Appendix Table F1: SDE ----
# Use OLS within agency-year (m3) for SDE; the IV (m4) first stage is too weak
# (F < 10) to give meaningful magnitudes.
sd_y  <- sd(df$log_page_change)
sd_x  <- sd(df$days_open)
beta  <- coef(m3)["days_open"]
sebeta<- se(m3)["days_open"]
sde   <- as.numeric(beta * sd_x / sd_y)
sde_se<- as.numeric(sebeta * sd_x / sd_y)

# Re-estimate heterogeneous panels by OLS within agency-year for the SDE
het_big_ols   <- feols(log_page_change ~ days_open + log_pages | agency_year,
                       data=df[big==1], cluster=~agency)
het_small_ols <- feols(log_page_change ~ days_open + log_pages | agency_year,
                       data=df[big==0], cluster=~agency)
b_big   <- coef(het_big_ols)["days_open"];   s_big   <- se(het_big_ols)["days_open"]
b_small <- coef(het_small_ols)["days_open"]; s_small <- se(het_small_ols)["days_open"]
sd_y_big<-sd(df[big==1, log_page_change]); sd_x_big<-sd(df[big==1, days_open])
sd_y_sml<-sd(df[big==0, log_page_change]); sd_x_sml<-sd(df[big==0, days_open])
sde_big <- as.numeric(b_big*sd_x_big/sd_y_big);   sde_big_se <- as.numeric(s_big*sd_x_big/sd_y_big)
sde_sml <- as.numeric(b_small*sd_x_sml/sd_y_sml); sde_sml_se <- as.numeric(s_small*sd_x_sml/sd_y_sml)

classify <- function(s){
  if(is.na(s)) return("--")
  if(s < -0.15) return("Large neg.")
  if(s < -0.05) return("Moderate neg.")
  if(s < -0.005) return("Small neg.")
  if(s <  0.005) return("Null")
  if(s <  0.05)  return("Small pos.")
  if(s <  0.15)  return("Moderate pos.")
  return("Large pos.")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does extending the public comment period for proposed federal rules cause agencies to revise the substance of those rules more between proposal and finalization? ",
  "\\textbf{Policy mechanism:} The Administrative Procedure Act sets a 30-day floor on comment periods; agencies routinely choose between 30 and 90+ days. Executive Order 12866 directs agencies to provide at least 60 days for `significant' rules with $100M+ economic impact, but in practice only shifts the realized window by about 3 days. ",
  "\\textbf{Outcome definition:} $\\log(1+|\\text{pages}_{\\text{final}}-\\text{pages}_{\\text{proposed}}|/\\text{pages}_{\\text{proposed}})$, a bounded log measure of how much the rule's length changes between the proposed and final version, computed from Federal Register page counts. ",
  "\\textbf{Treatment:} Continuous comment-period length in days (mean $\\approx 47$, sd $\\approx 15$). ",
  "\\textbf{Data:} Federal Register API; matched proposed--final rule pairs 2015--2022 linked by Regulation Identifier Number (RIN). ",
  "\\textbf{Method:} OLS with agency$\\times$year fixed effects and a log proposed-page control; standard errors clustered by agency. The natural instrument (EO 12866 significance) yields a first-stage F below 2 because the significance designation shifts realized comment time by only about 3 days, so it is reported transparently in the main table but is not used to compute this magnitude. ",
  "\\textbf{Sample:} Proposed rules with valid comment-close dates, an existing OIRA significance flag, a matched final rule within 36 months, and non-zero proposed-rule page counts on both sides. High-volume agencies are those with above-median rule counts in the matched sample. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for the continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(TAB,"tabF1_sde.tex"))
cat("\\begin{table}[t]\n\\caption{Standardized effect size (SDE)}\n\\label{tab:sde}\n\\centering\n\\small\n")
cat("\\begin{tabular}{lrrrrrl}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat("Log page-change ratio & ",fmt(beta)," & ",fmt(sebeta)," & ",fmt(sd_y)," & ",fmt(sde)," & ",fmt(sde_se)," & ",classify(sde),"\\\\\n",sep="")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n")
cat("Log page change, high-volume agencies & ",fmt(b_big)," & ",fmt(s_big)," & ",fmt(sd_y_big)," & ",fmt(sde_big)," & ",fmt(sde_big_se)," & ",classify(sde_big),"\\\\\n",sep="")
cat("Log page change, low-volume agencies  & ",fmt(b_small)," & ",fmt(s_small)," & ",fmt(sd_y_sml)," & ",fmt(sde_sml)," & ",fmt(sde_sml_se)," & ",classify(sde_sml),"\\\\\n",sep="")
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{itemize}\\setlength{\\itemsep}{0pt}\\footnotesize\n")
cat(sde_notes,"\n")
cat("\\end{itemize}\n")
cat("\\end{table}\n")
sink()

cat("All tables written to",TAB,"\n")
