## 01_fetch_data.R — Fetch USPTO patent data from PatentsView bulk S3
## APEP Paper apep_0829: The Goldilocks Examiner
##
## Data sources (PatentsView S3 bulk downloads):
##   1. g_patent.tsv — patent_id, num_claims, patent_date
##   2. g_examiner_not_disambiguated.tsv — patent_id, examiner name, art_group
##   3. g_application.tsv — patent_id, filing_date
##   4. g_uspc_at_issue.tsv — patent_id, USPC class (technology field)
##   5. g_us_patent_citation.tsv — patent-to-patent citations
##   6. g_assignee_not_disambiguated.tsv — patent_id, assignee (for self-cite ID)

source("00_packages.R")

DATA_DIR <- "../data"
PV_BASE <- "https://s3.amazonaws.com/data.patentsview.org/download"

## ---- Helper: download and extract ----
download_pv <- function(key) {
  fname <- paste0(key, ".tsv.zip")
  dest <- file.path(DATA_DIR, fname)
  tsv <- file.path(DATA_DIR, paste0(key, ".tsv"))

  if (file.exists(tsv)) {
    cat("  Already extracted:", tsv, "\n")
    return(tsv)
  }

  url <- paste0(PV_BASE, "/", fname)
  cat("  Downloading:", key, "...\n")
  ## Use curl for large files (R's download.file has 60s timeout)
  ret <- system2("curl", c("-L", "-o", dest, "--max-time", "1800", url),
                 stdout = TRUE, stderr = TRUE)
  if (!file.exists(dest)) stop("Download failed for ", key)
  cat("  Unzipping:", fname, "...\n")
  unzip(dest, exdir = DATA_DIR)
  ## Remove zip to save space
  file.remove(dest)
  stopifnot("TSV must exist after extraction" = file.exists(tsv))
  return(tsv)
}

## ---- Step 1: Download patent data (219MB) ----
cat("=== Step 1: Patent data ===\n")
patent_tsv <- download_pv("g_patent")
patent_dt <- fread(patent_tsv, select = c("patent_id", "patent_type", "patent_date",
                                           "num_claims", "wipo_kind"))
cat(sprintf("  Raw patents: %s\n", format(nrow(patent_dt), big.mark = ",")))

## Filter to utility patents
patent_dt <- patent_dt[patent_type == "utility"]
patent_dt[, patent_date := as.Date(patent_date)]
patent_dt[, grant_year := year(patent_date)]
cat(sprintf("  Utility patents: %s\n", format(nrow(patent_dt), big.mark = ",")))

## ---- Step 2: Download examiner data (187MB) ----
cat("\n=== Step 2: Examiner data ===\n")
exam_tsv <- download_pv("g_examiner_not_disambiguated")
exam_dt <- fread(exam_tsv)
cat(sprintf("  Raw examiner records: %s\n", format(nrow(exam_dt), big.mark = ",")))

## Create unique examiner ID from name + art group
exam_dt[, examiner_id := paste(raw_examiner_name_first, raw_examiner_name_last,
                                art_group, sep = "_")]
## Keep primary examiners (they make the decisions)
exam_dt <- exam_dt[examiner_role == "primary"]
## One row per patent (take first if duplicates)
exam_dt <- exam_dt[!duplicated(patent_id)]
cat(sprintf("  Primary examiner records: %s\n", format(nrow(exam_dt), big.mark = ",")))
cat(sprintf("  Unique examiners: %s\n", format(uniqueN(exam_dt$examiner_id), big.mark = ",")))

## ---- Step 3: Download application data (67MB) ----
cat("\n=== Step 3: Application data ===\n")
app_tsv <- download_pv("g_application")
app_dt <- fread(app_tsv, select = c("patent_id", "filing_date"))
app_dt[, filing_date := as.Date(filing_date)]
app_dt[, filing_year := year(filing_date)]
## Filter to valid dates
app_dt <- app_dt[filing_date >= "2005-01-01" & filing_date <= "2015-12-31"]
cat(sprintf("  Applications (2005-2015): %s\n", format(nrow(app_dt), big.mark = ",")))

## ---- Step 4: Download USPC at issue (technology class) ----
cat("\n=== Step 4: USPC data ===\n")
uspc_tsv <- download_pv("g_uspc_at_issue")
uspc_dt <- fread(uspc_tsv, select = c("patent_id", "uspc_sequence",
                                       "uspc_mainclass_id"))
## Keep primary classification only (sequence 0)
uspc_dt <- uspc_dt[uspc_sequence == 0]
uspc_dt[, uspc_sequence := NULL]
cat(sprintf("  USPC records (primary): %s\n", format(nrow(uspc_dt), big.mark = ",")))

## ---- Step 5: Download assignee data (for self-citation identification) ----
cat("\n=== Step 5: Assignee data ===\n")
asgn_tsv <- download_pv("g_assignee_not_disambiguated")
asgn_dt <- fread(asgn_tsv, select = c("patent_id", "raw_assignee_organization"))
## Keep first assignee per patent
asgn_dt <- asgn_dt[!duplicated(patent_id)]
cat(sprintf("  Assignee records: %s\n", format(nrow(asgn_dt), big.mark = ",")))

## ---- Step 6: Merge patent-level data ----
cat("\n=== Step 6: Merging ===\n")
df <- merge(patent_dt, app_dt, by = "patent_id", all = FALSE)
df <- merge(df, exam_dt[, .(patent_id, examiner_id, art_group)],
            by = "patent_id", all.x = FALSE, all.y = FALSE)
df <- merge(df, uspc_dt, by = "patent_id", all.x = TRUE)
df <- merge(df, asgn_dt, by = "patent_id", all.x = TRUE)

cat(sprintf("  After merge: %s patents\n", format(nrow(df), big.mark = ",")))

## Filter: must have USPC class, num_claims > 0
df <- df[!is.na(uspc_mainclass_id) & num_claims > 0]
cat(sprintf("  After USPC + claims filter: %s\n", format(nrow(df), big.mark = ",")))

## Create Art Unit × Year cell
df[, art_unit_year := paste0(uspc_mainclass_id, "_", filing_year)]

## Save sample patent IDs for citation filtering
sample_patents <- df$patent_id
cat(sprintf("  Sample patents for citation lookup: %s\n",
            format(length(sample_patents), big.mark = ",")))

## Clean up large objects
rm(patent_dt, exam_dt, app_dt, uspc_dt, asgn_dt)
gc()

## ---- Step 7: Download and process citations (2.1GB — largest file) ----
cat("\n=== Step 7: Citation data ===\n")
cite_tsv <- download_pv("g_us_patent_citation")

## Read citation data — filter immediately to save memory
## Only keep citations WHERE the cited patent is in our sample
cat("  Reading citations (this may take a few minutes)...\n")
cite_dt <- fread(cite_tsv, select = c("patent_id", "citation_patent_id", "citation_category"))

cat(sprintf("  Raw citation records: %s\n", format(nrow(cite_dt), big.mark = ",")))

## Filter: cited patent must be in our sample
cite_dt <- cite_dt[citation_patent_id %in% sample_patents]
cat(sprintf("  Citations to sample patents: %s\n", format(nrow(cite_dt), big.mark = ",")))

## Merge citing patent's grant date and assignee for time-window + self-cite
cite_dt <- merge(cite_dt,
                 df[, .(patent_id, patent_date, raw_assignee_organization)],
                 by.x = "citation_patent_id", by.y = "patent_id",
                 all.x = TRUE)
setnames(cite_dt, c("patent_date", "raw_assignee_organization"),
         c("cited_grant_date", "cited_assignee"))

## Get citing patent's grant date and assignee
citing_info <- fread(download_pv("g_patent"),
                     select = c("patent_id", "patent_date"))
citing_info[, patent_date := as.Date(patent_date)]
cite_dt <- merge(cite_dt, citing_info, by = "patent_id", all.x = TRUE)
setnames(cite_dt, "patent_date", "citing_grant_date")

citing_asgn <- fread(download_pv("g_assignee_not_disambiguated"),
                     select = c("patent_id", "raw_assignee_organization"))
citing_asgn <- citing_asgn[!duplicated(patent_id)]
cite_dt <- merge(cite_dt, citing_asgn[, .(patent_id, raw_assignee_organization)],
                 by = "patent_id", all.x = TRUE)
setnames(cite_dt, "raw_assignee_organization", "citing_assignee")

rm(citing_info, citing_asgn)
gc()

## 5-year citation window: citing patent granted within 5 years of cited patent
cite_dt[, days_diff := as.numeric(citing_grant_date - cited_grant_date)]
cite_5yr <- cite_dt[!is.na(days_diff) & days_diff >= 0 & days_diff <= 365.25 * 5]

## Identify self-citations (same assignee organization)
cite_5yr[, is_self := !is.na(cited_assignee) & !is.na(citing_assignee) &
           cited_assignee != "" & citing_assignee != "" &
           cited_assignee == citing_assignee]

## Count forward citations per cited patent
fwd_cites <- cite_5yr[, .(
  total_forward_cites_5yr = .N,
  other_forward_cites_5yr = sum(!is_self),
  self_forward_cites_5yr = sum(is_self),
  examiner_cites_5yr = sum(citation_category == "cited by examiner")
), by = .(citation_patent_id)]

setnames(fwd_cites, "citation_patent_id", "patent_id")
cat(sprintf("  Patents with >=1 citation: %s\n", format(nrow(fwd_cites), big.mark = ",")))

## ---- Step 8: Final merge ----
cat("\n=== Step 8: Final merge ===\n")
df <- merge(df, fwd_cites, by = "patent_id", all.x = TRUE)

## Zero-fill missing citations
for (col in c("total_forward_cites_5yr", "other_forward_cites_5yr",
              "self_forward_cites_5yr", "examiner_cites_5yr")) {
  df[is.na(get(col)), (col) := 0L]
}

cat(sprintf("Final dataset: %s patents\n", format(nrow(df), big.mark = ",")))
cat(sprintf("Unique examiners: %s\n", format(uniqueN(df$examiner_id), big.mark = ",")))
cat(sprintf("Unique art_unit_year cells: %s\n", format(uniqueN(df$art_unit_year), big.mark = ",")))
cat(sprintf("Filing years: %d to %d\n", min(df$filing_year), max(df$filing_year)))
cat(sprintf("Mean num_claims: %.1f (SD: %.1f)\n", mean(df$num_claims), sd(df$num_claims)))
cat(sprintf("Mean forward cites (5yr): %.1f\n", mean(df$total_forward_cites_5yr)))

stopifnot("Final dataset must have >100K patents" = nrow(df) > 100000)

## ---- Step 9: Save ----
saveRDS(df, "../data/analysis_raw.rds")

## Clean up TSV files to save disk space (keep only RDS)
cat("\nCleaning up TSV files...\n")
tsv_files <- list.files(DATA_DIR, pattern = "\\.tsv$", full.names = TRUE)
file.remove(tsv_files)

cat("Saved data/analysis_raw.rds\n")
cat("Done!\n")
