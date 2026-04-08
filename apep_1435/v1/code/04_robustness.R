## 04_robustness.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
ROOT <- normalizePath("."); DAT <- file.path(ROOT,"data")
df <- readRDS(file.path(DAT,"analysis.rds"))

cl <- ~agency
out <- list()

out$drop_epa <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag,
                      data=df[!grepl("environmental",agency)], cluster=cl)
out$nonsig_only <- feols(log_page_change ~ days_open + log_pages | agency_year,
                         data=df[significant_flag==0], cluster=cl)
df[, parent := ifelse(is.na(p_agency_parent) | p_agency_parent=="", agency, as.character(p_agency_parent))]
out$parent_cluster <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag,
                            data=df, cluster=~parent)
out$dpages_iv <- feols(log_dpages ~ log_pages | agency_year | days_open ~ significant_flag,
                       data=df, cluster=cl)
cap <- quantile(df$days_open, 0.9)
out$trim90 <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag,
                    data=df[days_open <= cap], cluster=cl)
out$pre2021 <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag,
                     data=df[p_year <= 2020], cluster=cl)

saveRDS(out, file.path(DAT,"robust.rds"))
print(etable(out, fitstat=~n+r2))
