# Event study table generation
source("00_packages.R")
results <- readRDS("../data/main_results.rds")
es <- results$es_event_study

es_coefs <- data.frame(
  Year = c("2013 (k=-4)", "2014 (k=-3)", "2015 (k=-2)", "2016 (k=-1)",
           "2017 (k=0)", "2018 (k=1)", "2019 (k=2)", "2020 (k=3)", "2021 (k=4)"),
  Coefficient = round(c(coef(es)[1:3], 0, coef(es)[4:8]), 2),
  SE = c(round(se(es)[1:3], 2), NA, round(se(es)[4:8], 2))
)

es_tex <- kbl(es_coefs, format = "latex", booktabs = TRUE, escape = FALSE,
              caption = "Event Study Estimates: Fail $\\times$ Year Interactions\\label{tab:eventstudy}",
              align = c("l", "c", "c"),
              col.names = c("Year (relative to publication)", "$\\hat{\\delta}_k$", "SE")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Reference year: 2016 (k = -1). Standard errors clustered at the institution level. Program and year FE included. Endpoints binned.",
           escape = FALSE, threeparttable = TRUE)

writeLines(es_tex, "../tables/tab5_eventstudy.tex")
cat("Event study table written.\n")
