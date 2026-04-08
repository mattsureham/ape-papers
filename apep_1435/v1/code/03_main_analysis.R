## 03_main_analysis.R — Main IV/OLS for comment-period -> rule revision
suppressPackageStartupMessages({
  library(data.table); library(fixest); library(jsonlite)
})

ROOT <- normalizePath(".")
DAT  <- file.path(ROOT, "data")
TAB  <- file.path(ROOT, "tables")
dir.create(TAB, showWarnings=FALSE)

df <- fread(file.path(DAT,"pairs_meta.csv"))
stopifnot(nrow(df) > 1000)

# Variable construction
df[, p_pub_date := as.Date(p_pub)]
df[, p_close_date := as.Date(p_close)]
df[, days_open := as.integer(p_close_date - p_pub_date)]
df <- df[!is.na(days_open) & days_open >= 1 & days_open <= 365]
df[, p_year := as.integer(format(p_pub_date,"%Y"))]
df[, significant_flag := as.integer(tolower(p_significant) == "true")]
df[, p_pages_n := suppressWarnings(as.numeric(p_pages))]
df[, f_pages_n := suppressWarnings(as.numeric(f_pages))]
df[, log_pages := log1p(p_pages_n)]
df[, agency := p_agency]
df <- df[!is.na(agency) & agency != ""]
df[, agency_year := paste(agency, p_year, sep="_")]

# Primary outcome: revision intensity proxied by log(1+|Δpages|/proposed pages),
# bounded change ratio that captures section additions/deletions even when no
# text retrieval occurred.
df <- df[!is.na(p_pages_n) & !is.na(f_pages_n) & p_pages_n > 0]
df[, dpages := abs(f_pages_n - p_pages_n)]
df[, page_change_ratio := dpages / p_pages_n]
df[, log_page_change := log1p(page_change_ratio)]   # primary
df[, log_dpages := log1p(dpages)]                   # secondary

# Cap days_open at 99.5th pct
qcap <- quantile(df$days_open, 0.995, na.rm=TRUE)
df <- df[days_open <= qcap]

# Merge text-distance secondary outcome (subsample)
td_path <- file.path(DAT,"textdist.csv")
if (file.exists(td_path)) {
  td <- fread(td_path)
  df <- merge(df, td[, .(p_doc, text_dist)], by="p_doc", all.x=TRUE)
} else {
  df[, text_dist := NA_real_]
}

cat("Sample N =", nrow(df), "\n")
cat("Unique agencies =", uniqueN(df$agency), "\n")
cat("Year range =", paste(range(df$p_year), collapse="-"), "\n")
cat("Mean days_open: significant=",
    round(df[significant_flag==1, mean(days_open)],2),
    " non-sig=", round(df[significant_flag==0, mean(days_open)],2),"\n")
cat("Mean |Δpages|/proposed_pages =", round(mean(df$page_change_ratio),4), "\n")
cat("Pairs with text_dist =", sum(!is.na(df$text_dist)),"\n")

saveRDS(df, file.path(DAT,"analysis.rds"))

# ----- Models on PRIMARY outcome (log_page_change) -----
m1 <- feols(log_page_change ~ days_open + log_pages + significant_flag, data=df, cluster=~agency)
m2 <- feols(log_page_change ~ days_open + log_pages + significant_flag | agency, data=df, cluster=~agency)
m3 <- feols(log_page_change ~ days_open + log_pages + significant_flag | agency_year, data=df, cluster=~agency)
m4 <- feols(log_page_change ~ log_pages | agency_year | days_open ~ significant_flag, data=df, cluster=~agency)
m5 <- feols(log_page_change ~ significant_flag + log_pages | agency_year, data=df, cluster=~agency)

fs_F <- as.numeric(fitstat(m4, "ivf1")[[1]]$stat)
cat("\nFirst-stage F (m4):", fs_F, "\n")

models <- list(m1=m1,m2=m2,m3=m3,m4=m4,m5=m5)

# ---- Text distance (secondary) on the cached subsample ----
df_td <- df[!is.na(text_dist)]
text_models <- NULL
if (nrow(df_td) >= 50) {
  cat("\nText-distance subsample N =", nrow(df_td),"\n")
  td_ols <- feols(text_dist ~ days_open + log_pages + significant_flag, data=df_td, cluster=~agency)
  td_iv  <- tryCatch(
    feols(text_dist ~ log_pages | agency | days_open ~ significant_flag,
          data=df_td, cluster=~agency),
    error=function(e) NULL)
  td_rf  <- feols(text_dist ~ significant_flag + log_pages, data=df_td, cluster=~agency)
  text_models <- list(ols=td_ols, iv=td_iv, rf=td_rf)
}

saveRDS(list(models=models, fs_F=fs_F, text_models=text_models), file.path(DAT,"models.rds"))

# Diagnostics
diag <- list(
  n_obs = nrow(df),
  n_treated = sum(df$significant_flag==1),
  n_pre = length(unique(df$p_year)),
  n_agencies = uniqueN(df$agency),
  mean_days_open = mean(df$days_open),
  mean_days_sig = mean(df[significant_flag==1, days_open]),
  mean_days_nonsig = mean(df[significant_flag==0, days_open]),
  fs_gain = mean(df[significant_flag==1, days_open]) - mean(df[significant_flag==0, days_open]),
  mean_page_change = mean(df$page_change_ratio),
  sd_page_change = sd(df$page_change_ratio),
  fs_F = fs_F,
  n_text = sum(!is.na(df$text_dist)),
  mean_text_dist = if (sum(!is.na(df$text_dist))) mean(df$text_dist,na.rm=TRUE) else NA,
  sd_text_dist = if (sum(!is.na(df$text_dist))) sd(df$text_dist,na.rm=TRUE) else NA
)
write_json(diag, file.path(DAT,"diagnostics.json"), auto_unbox=TRUE, pretty=TRUE)
cat("\nWrote diagnostics.json\n")
print(etable(models, fitstat=~n+r2))
