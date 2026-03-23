## 05_tables.R — Generate all LaTeX tables
## APEP Paper apep_0829: The Goldilocks Examiner

source("00_packages.R")

df <- as.data.table(readRDS("../data/analysis_clean.rds"))
results <- readRDS("../data/main_results.rds")

## ====================================================================
## TABLE 1: Summary Statistics
## ====================================================================
cat("Generating Table 1: Summary Statistics...\n")

vars <- list(
  list("Claims at grant", df$num_claims),
  list("LOO examiner avg. claims", df$loo_examiner_claims),
  list("Forward citations (5yr, total)", df$total_forward_cites_5yr),
  list("Forward citations (5yr, other)", df$other_forward_cites_5yr),
  list("Forward citations (5yr, self)", df$self_forward_cites_5yr),
  list("Any forward citation", df$has_citation),
  list("Grant lag (years)", as.numeric(df$patent_date - df$filing_date) / 365.25)
)

sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{lrrrrr}\n")
cat("\\hline\\hline\n")
cat("Variable & Mean & SD & P10 & P90 & N \\\\\n")
cat("\\hline\n")
for (v in vars) {
  x <- v[[2]]
  cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n",
              v[[1]], mean(x, na.rm = TRUE), sd(x, na.rm = TRUE),
              quantile(x, 0.10, na.rm = TRUE), quantile(x, 0.90, na.rm = TRUE),
              format(sum(!is.na(x)), big.mark = ",")))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Sample includes USPTO utility patents filed 2005--2015 ")
cat("with examiner data from PatentsView. Claims at grant is the number of claims ")
cat("in the issued patent. LOO examiner avg.\\ claims is the leave-one-out mean of ")
cat("claims at grant for the same examiner within USPC class $\\times$ filing year cells. ")
cat("Forward citations counted within 5 years of grant date; ``other'' excludes same-assignee ")
cat("citations. Cells with fewer than 10 patents are excluded. ")
cat(sprintf("N = %s patents, %s examiners, %s cells.\n",
            format(nrow(df), big.mark = ","),
            format(uniqueN(df$examiner_id), big.mark = ","),
            format(uniqueN(df$art_unit_year), big.mark = ",")))
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Saved tables/tab1_summary.tex\n")

## ====================================================================
## TABLE 2: First Stage
## ====================================================================
cat("Generating Table 2: First Stage...\n")

fs1 <- feols(num_claims_w ~ loo_examiner_claims_w | art_unit_year,
             data = df, cluster = ~examiner_id)

etable(fs1,
       file = "../tables/tab2_first_stage.tex",
       replace = TRUE,
       se = "cluster",
       dict = c(loo_examiner_claims_w = "LOO Examiner Claims",
                num_claims_w = "Claims at Grant"),
       title = "First Stage: Examiner Leniency and Patent Scope",
       label = "tab:first_stage",
       notes = paste0("Dependent variable is number of claims at grant (winsorized at 1\\%). ",
                      "LOO Examiner Claims is the leave-one-out mean of claims at grant ",
                      "for the same examiner within USPC class $\\times$ filing year cells ",
                      "(cells with $\\geq$10 patents). Standard errors clustered at the ",
                      "examiner level in parentheses. ",
                      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."),
       fitstat = ~ n + r2,
       style.tex = style.tex("aer"))
cat("Saved tables/tab2_first_stage.tex\n")

## ====================================================================
## TABLE 3: Reduced Form — Main Results
## ====================================================================
cat("Generating Table 3: Main Results...\n")

rf_total <- feols(ln_total_cites ~ loo_examiner_claims_w | art_unit_year,
                  data = df, cluster = ~examiner_id)
rf_other <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                  data = df, cluster = ~examiner_id)
rf_self <- feols(ln_self_cites ~ loo_examiner_claims_w | art_unit_year,
                 data = df, cluster = ~examiner_id)
rf_any <- feols(has_citation ~ loo_examiner_claims_w | art_unit_year,
                data = df, cluster = ~examiner_id)
rf_any_other <- feols(has_other_citation ~ loo_examiner_claims_w | art_unit_year,
                      data = df, cluster = ~examiner_id)

etable(rf_total, rf_other, rf_self, rf_any, rf_any_other,
       file = "../tables/tab3_reduced_form.tex",
       replace = TRUE,
       se = "cluster",
       dict = c(loo_examiner_claims_w = "LOO Examiner Claims"),
       title = "Reduced Form: Examiner Scope Leniency and Follow-On Innovation",
       label = "tab:reduced_form",
       headers = c("ln(Total)", "ln(Other)", "ln(Self)", "Any Cite", "Any Other"),
       notes = paste0("Dependent variables are log (plus one) forward citations within 5 years ",
                      "of grant, or indicators for receiving any citation. ``Other'' citations ",
                      "exclude same-assignee citations. LOO Examiner Claims is the leave-one-out ",
                      "examiner mean of claims at grant within USPC class $\\times$ filing year cells. ",
                      "All specifications include USPC class $\\times$ filing year fixed effects. ",
                      "Standard errors clustered at the examiner level. ",
                      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."),
       fitstat = ~ n + r2,
       style.tex = style.tex("aer"))
cat("Saved tables/tab3_reduced_form.tex\n")

## ====================================================================
## TABLE 4: Robustness and Heterogeneity
## ====================================================================
cat("Generating Table 4: Robustness...\n")

## Balance test: grant lag
df[, grant_lag := as.numeric(patent_date - filing_date) / 365.25]
bal_lag <- feols(grant_lag ~ loo_examiner_claims_w | art_unit_year,
                 data = df, cluster = ~examiner_id)

## Crowdedness heterogeneity
class_density <- df[, .(class_patents = .N), by = uspc_mainclass_id]
df <- merge(df, class_density, by = "uspc_mainclass_id", all.x = TRUE)
df[, crowded := class_patents > median(class_patents)]

rf_crowded <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                    data = df[crowded == TRUE], cluster = ~examiner_id)
rf_uncrowded <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                      data = df[crowded == FALSE], cluster = ~examiner_id)

etable(bal_lag, rf_crowded, rf_uncrowded,
       file = "../tables/tab4_robustness.tex",
       replace = TRUE,
       se = "cluster",
       dict = c(loo_examiner_claims_w = "LOO Examiner Claims"),
       title = "Robustness: Balance Tests and Heterogeneity by Technology Crowdedness",
       label = "tab:robustness",
       headers = c("Grant Lag", "Crowded", "Uncrowded"),
       notes = paste0("Column 1: Balance test — regressing grant lag (years from filing to grant) ",
                      "on LOO Examiner Claims. Grant lag may partially respond to examiner behavior. ",
                      "Columns 2--3: Split by technology class crowdedness ",
                      "(above/below median patent count in USPC class). Dependent variable is ",
                      "ln(other forward citations + 1). All specifications include USPC class ",
                      "$\\times$ filing year FE. Standard errors clustered at examiner level. ",
                      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."),
       fitstat = ~ n + r2,
       style.tex = style.tex("aer"))
cat("Saved tables/tab4_robustness.tex\n")

## ====================================================================
## TABLE F1: Standardized Effect Sizes (MANDATORY)
## ====================================================================
cat("Generating Table F1: SDE...\n")

sd_x <- results$sd_loo

sde_rows <- data.frame(
  Outcome = c(
    "Total fwd. citations (5yr)",
    "Other fwd. citations (5yr)",
    "Self fwd. citations (5yr)",
    "Any forward citation"
  ),
  beta = c(
    results$rf_total_coef,
    results$rf_other_coef,
    results$rf_self_coef,
    results$rf_any_coef
  ),
  se_beta = c(
    results$rf_total_se,
    results$rf_other_se,
    results$rf_self_se,
    results$rf_any_se
  ),
  sd_y = c(
    results$sd_ln_total,
    results$sd_ln_other,
    results$sd_ln_self,
    results$sd_has_citation
  ),
  stringsAsFactors = FALSE
)

sde_rows$SDE <- sde_rows$beta * sd_x / sde_rows$sd_y
sde_rows$SE_SDE <- sde_rows$se_beta * sd_x / sde_rows$sd_y
sde_rows$Classification <- ifelse(sde_rows$SDE < -0.15, "Large negative",
  ifelse(sde_rows$SDE < -0.05, "Moderate negative",
  ifelse(sde_rows$SDE < -0.005, "Small negative",
  ifelse(sde_rows$SDE <= 0.005, "Null",
  ifelse(sde_rows$SDE <= 0.05, "Small positive",
  ifelse(sde_rows$SDE <= 0.15, "Moderate positive",
         "Large positive"))))))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does examiner-driven variation in patent scope (number of claims allowed) affect follow-on innovation by competitors, as measured by forward patent citations? ",
  "\\textbf{Policy mechanism:} USPTO patent examiners reject individual claims during prosecution, forcing applicants to narrow their patents; examiners who systematically allow more claims grant broader patents that cover more technological space, potentially blocking competitor innovation or, conversely, signaling valuable technology that attracts follow-on work. ",
  "\\textbf{Outcome definition:} Forward patent citations received within 5 years of grant date, decomposed into total, other-assignee (competitor), and self-assignee citations; also extensive margin (any citation received). ",
  "\\textbf{Treatment:} Continuous; leave-one-out examiner average number of claims at grant within USPC class $\\times$ filing year cells. ",
  "\\textbf{Data:} PatentsView bulk data (USPTO), filing years 2005--2015, patent-level observations, N = ",
  format(nrow(df), big.mark = ","), ". ",
  "\\textbf{Method:} Reduced-form OLS with USPC class $\\times$ filing year fixed effects; standard errors clustered at examiner level; 2SLS IV estimates reported separately. ",
  "\\textbf{Sample:} Granted USPTO utility patents with primary examiner data, USPC classification, and examiner $\\times$ USPC class $\\times$ year cells with $\\geq$10 patents. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the LOO examiner claims instrument and SD($Y$) is the standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sde_rows)) {
  cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
              sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se_beta[i],
              sde_rows$sd_y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
              sde_rows$Classification[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Saved tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
