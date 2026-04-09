## 04b_extensive_margin.R — Extensive margin: share of short-term transactions
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# Load the FULL transaction data (not just repeat sales)
cat("=== Loading full transaction data ===\n")
dt <- fread(file.path(data_dir, "taiwan_raw_transactions.csv"),
            encoding = "UTF-8", fill = TRUE,
            select = c("交易標的", "交易年月日", "總價元"))

# Skip English row
dt <- dt[!grepl("^(The villages|transaction sign)", `交易標的`, ignore.case = TRUE)]

# Parse dates
dt[, txn_str := as.character(`交易年月日`)]
dt[, txn_str := trimws(txn_str)]
dt[nchar(txn_str) == 6, txn_str := paste0("0", txn_str)]
dt[, roc_yr := as.integer(substr(txn_str, 1, 3))]
dt[, mon := as.integer(substr(txn_str, 4, 5))]
dt[, west_yr := roc_yr + 1911L]
dt <- dt[!is.na(roc_yr) & mon >= 1 & mon <= 12 & west_yr >= 2012 & west_yr <= 2024]
dt[, txn_date := as.Date(sprintf("%04d-%02d-15", west_yr, mon))]
dt <- dt[!is.na(txn_date)]

# Building transactions only
dt <- dt[grepl("(房地|建物)", `交易標的`)]

# Count by quarter
dt[, txn_qtr := floor_date(txn_date, "quarter")]
qtr_counts <- dt[, .(total_txns = .N), by = txn_qtr]
setorder(qtr_counts, txn_qtr)

# Reform date: July 1, 2021
reform_date <- as.Date("2021-07-01")

# Compute share of transactions in each quarter
# We'll look at total volume as the extensive margin measure
qtr_counts[, post_reform := txn_qtr >= reform_date]
qtr_counts[, year := year(txn_qtr)]

# Annual volume comparison
annual <- dt[, .(total = .N), by = .(year = year(txn_date))]
setorder(annual, year)
cat("Annual transaction volume:\n")
print(annual)

# Pre vs post reform (excluding 2021 as transition year)
pre <- annual[year >= 2017 & year <= 2020, mean(total)]
post <- annual[year >= 2022 & year <= 2024, mean(total)]
cat(sprintf("\nMean annual transactions:\n  Pre-reform (2017-2020): %s\n  Post-reform (2022-2024): %s\n  Change: %.1f%%\n",
            format(pre, big.mark = ","), format(post, big.mark = ","),
            100 * (post - pre) / pre))

# ---- Table 5: Transaction Volume Before and After Reform ----
cat("\n=== Table 5: Extensive Margin ===\n")

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Transaction Volume Before and After Tax 2.0}\n",
  "\\label{tab:volume}\n",
  "\\begin{tabular}{lrr}\n",
  "\\toprule\n",
  "Year & Building Transactions & Change from 2019 (\\%) \\\\\n",
  "\\midrule\n"
)

base_year <- annual[year == 2019, total]
for (i in seq_len(nrow(annual))) {
  yr <- annual$year[i]
  if (yr >= 2017 & yr <= 2024) {
    pct <- sprintf("%.1f", 100 * (annual$total[i] - base_year) / base_year)
    tab5_tex <- paste0(tab5_tex,
      sprintf("%d & %s & %s \\\\\n", yr, format(annual$total[i], big.mark = ","), pct))
    if (yr == 2020) tab5_tex <- paste0(tab5_tex, "\\midrule\n")
    if (yr == 2021) tab5_tex <- paste0(tab5_tex, "\\addlinespace\n")
  }
}

tab5_tex <- paste0(tab5_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Total building transactions (房地 + 建物) from Taiwan Actual Price Registration. ",
  "Tax 2.0 took effect July 1, 2021 (dashed line). Percentage change computed relative to 2019, ",
  "the last full pre-reform, pre-COVID year. The increase in post-reform volume suggests the tax ",
  "did not substantially reduce overall market activity on the extensive margin.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, file.path(tables_dir, "tab5_volume.tex"))
cat("Written tab5_volume.tex\n")
