## =============================================================================
## 02_clean_data.R — Merge election results + affidavits, construct RDD variables
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## =============================================================================
## PART 1: Load raw data
## =============================================================================

cat("=== Loading raw data ===\n")
assembly <- fread(file.path(data_dir, "assembly_elections.csv"), encoding = "UTF-8")
mynetas  <- fread(file.path(data_dir, "mynetas_all.csv"), encoding = "UTF-8", fill = TRUE)

## Filter assembly to post-2004 only
assembly <- assembly[as.integer(YEAR) >= 2004]

## Filter mynetas to state assembly only
mynetas_state <- mynetas[type == "state"]

cat("Assembly post-2004:", nrow(assembly), "rows\n")
cat("MyNeta state:", nrow(mynetas_state), "rows\n")

## =============================================================================
## PART 2: Clean assembly election data
## =============================================================================

cat("\n=== Cleaning assembly election data ===\n")

## Fix invalid UTF-8 characters
str_cols <- names(assembly)[sapply(assembly, is.character)]
for (col in str_cols) {
  assembly[[col]] <- iconv(assembly[[col]], from = "UTF-8", to = "UTF-8", sub = "")
}

## Standardize columns
assembly[, `:=`(
  state      = toupper(trimws(ST_NAME)),
  year       = as.integer(YEAR),
  ac_no      = as.integer(AC_NO),
  ac_name    = toupper(trimws(AC_NAME)),
  cand_name  = toupper(trimws(NAME)),
  party      = trimws(PARTY),
  votes      = as.integer(gsub(",", "", VOTES)),
  sex        = SEX,
  age        = as.integer(AGE),
  ac_type    = AC_TYPE
)]

## Remove rows with missing votes
assembly <- assembly[!is.na(votes) & votes >= 0]

## Create constituency ID
assembly[, const_id := paste(state, ac_no, year, sep = "_")]

## Identify top-2 candidates per constituency
assembly[, rank := frankv(-votes, ties.method = "first"), by = const_id]
top2 <- assembly[rank <= 2]

cat("Constituency-elections with top-2 candidates:", length(unique(top2$const_id)), "\n")

## Compute vote margin
top2_wide <- dcast(top2, const_id + state + year + ac_no + ac_name + ac_type ~
                     paste0("rank", rank),
                   value.var = c("cand_name", "party", "votes", "sex", "age"))

top2_wide[, `:=`(
  total_top2_votes = votes_rank1 + votes_rank2,
  margin_pct = (votes_rank1 - votes_rank2) / (votes_rank1 + votes_rank2) * 100,
  winner_name  = cand_name_rank1,
  winner_party = party_rank1,
  runner_name  = cand_name_rank2,
  runner_party = party_rank2
)]

cat("Top-2 constituency-elections:", nrow(top2_wide), "\n")
cat("Mean margin (pct):", round(mean(top2_wide$margin_pct, na.rm = TRUE), 2), "\n")
cat("Close elections (|margin| < 5%):", sum(abs(top2_wide$margin_pct) < 5, na.rm = TRUE), "\n")

## =============================================================================
## PART 3: Clean MyNeta affidavit data — parse asset values
## =============================================================================

cat("\n=== Cleaning MyNeta affidavit data ===\n")

## Fix invalid UTF-8 characters in MyNeta
str_cols_mn <- names(mynetas_state)[sapply(mynetas_state, is.character)]
for (col in str_cols_mn) {
  mynetas_state[[col]] <- iconv(mynetas_state[[col]], from = "UTF-8", to = "UTF-8", sub = "")
}

## Parse rupee strings to numeric
## Format: "Rs 31,00031 Thou+" means Rs 31,000 with "31 Thou+" summary appended
## Must strip the summary digits from the raw number before parsing
parse_rupees <- function(x) {
  x <- as.character(x)
  n <- length(x)
  result <- numeric(n)

  for (i in seq_len(n)) {
    s <- x[i]
    if (is.na(s) || s == "" || tolower(trimws(s)) == "nil") {
      result[i] <- 0
      next
    }

    ## Remove "Rs" prefix
    s <- gsub("^Rs\\s*", "", s)
    s <- trimws(s)

    if (s == "" || s == "0") {
      result[i] <- 0
      next
    }

    ## Detect suffix
    has_crore <- grepl("Crore", s, ignore.case = TRUE)
    has_lac   <- grepl("Lac|Lakh", s, ignore.case = TRUE)
    has_thou  <- grepl("Thou", s, ignore.case = TRUE)

    ## Extract numeric part (before the unit word)
    num_str <- gsub("\\s*(Crore|Lacs?|Lakhs?|Thou)\\+?.*$", "", s, ignore.case = TRUE)
    num_str <- gsub(",", "", num_str)
    num_str <- gsub("[^0-9.]", "", num_str)

    if (has_crore || has_lac || has_thou) {
      mult <- if (has_crore) 1e7 else if (has_lac) 1e5 else 1e3

      ## The format concatenates raw_value_digits + summary_digits
      ## E.g., "3100031" = "31000" + "31", where 31 = floor(31000 / 1000)
      ## Try stripping 1-4 digits from end to find consistent raw value
      found <- FALSE
      for (strip in 1:min(4, nchar(num_str) - 1)) {
        candidate_str <- substr(num_str, 1, nchar(num_str) - strip)
        candidate_val <- suppressWarnings(as.numeric(candidate_str))
        if (!is.na(candidate_val)) {
          summary_val <- floor(candidate_val / mult)
          if (nchar(as.character(summary_val)) == strip) {
            result[i] <- candidate_val
            found <- TRUE
            break
          }
        }
      }
      if (!found) {
        ## Fallback: parse full number without multiplication
        val <- suppressWarnings(as.numeric(num_str))
        result[i] <- ifelse(is.na(val), 0, val)
      }
    } else {
      ## No suffix — just a raw number
      val <- suppressWarnings(as.numeric(num_str))
      result[i] <- ifelse(is.na(val), 0, val)
    }
  }

  return(result)
}

## Parse key asset columns
mynetas_state[, `:=`(
  movable_self   = parse_rupees(self_movable_assets_totals),
  movable_spouse = parse_rupees(spouse_movable_assets_totals),
  immovable_self   = parse_rupees(self_immovable_assets_totals),
  immovable_spouse = parse_rupees(spouse_immovable_assets_totals),
  liab_self   = parse_rupees(self_liabilities_totals),
  liab_spouse = parse_rupees(spouse_liabilities_totals)
)]

## Total assets = movable + immovable (self + spouse)
mynetas_state[, total_assets := movable_self + movable_spouse +
                immovable_self + immovable_spouse]

## Net worth = total assets - total liabilities
mynetas_state[, net_worth := total_assets - liab_self - liab_spouse]

## Criminal cases
mynetas_state[, n_criminal := as.integer(gsub("[^0-9]", "", criminal_cases))]
mynetas_state[is.na(n_criminal), n_criminal := 0]

## Winner indicator
mynetas_state[, is_winner := grepl("winner|won", politician_name, ignore.case = TRUE) |
                tolower(winner) == "yes"]

## Clean name for matching
clean_name <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("\\s*\\(.*?\\)\\s*", "", x)       # Remove parenthetical (Winner) etc
  x <- gsub("^(DR|MR|MRS|SMT|SHRI|ADV|PROF)\\.?\\s*", "", x)  # Remove prefixes
  x <- gsub("\\.", " ", x)                     # Dots to spaces (T.TEJESWARA -> T TEJESWARA)
  x <- gsub("[^A-Z ]", "", x)                  # Keep only letters and spaces
  x <- gsub("\\s+", " ", trimws(x))            # Normalize whitespace
  return(x)
}

## Harmonize state names
harmonize_state <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("CHATTISGARH", "CHHATTISGARH", x)
  x <- gsub("JAMMU & KASHMIR", "JAMMU AND KASHMIR", x)
  x <- gsub("ORISSA", "ODISHA", x)
  x <- gsub("PONDICHERRY", "PUDUCHERRY", x)
  return(x)
}

mynetas_state[, `:=`(
  cand_name_clean = clean_name(politician_name),
  state_clean     = harmonize_state(toupper(trimws(state))),
  const_clean     = toupper(trimws(constituency)),
  year_clean      = as.integer(election_year)
)]

cat("Parsed assets for", sum(!is.na(mynetas_state$total_assets)), "candidates\n")
cat("Non-zero assets:", sum(mynetas_state$total_assets > 0, na.rm = TRUE), "\n")
cat("Median total assets (Rs):",
    formatC(median(mynetas_state$total_assets[mynetas_state$total_assets > 0], na.rm = TRUE),
            format = "f", big.mark = ",", digits = 0), "\n")

## =============================================================================
## PART 4: Merge election results with affidavit data
## =============================================================================

cat("\n=== Merging election results with affidavit data ===\n")

## Strategy: fuzzy match on candidate name + state + year
## Assembly elections have: state, year, ac_name, cand_name, votes
## MyNeta has: state_clean, year_clean, const_clean, cand_name_clean, total_assets

## Clean assembly names and harmonize states
assembly[, cand_name_clean := clean_name(NAME)]
assembly[, state_clean := harmonize_state(state)]

## Prepare merge keys: state + year + cleaned name
assembly[, merge_key := paste(state_clean, year, cand_name_clean)]
mynetas_state[, merge_key := paste(state_clean, year_clean, cand_name_clean)]

## Exact merge
merged <- merge(
  assembly[, .(merge_key, state, year, ac_no, ac_name, cand_name, party,
               votes, sex, age, rank, const_id, ac_type)],
  mynetas_state[, .(merge_key, total_assets, net_worth, n_criminal,
                     movable_self, immovable_self, education,
                     cand_name_clean)],
  by = "merge_key",
  all.x = FALSE
)

## Remove duplicate matches (keep first)
merged <- merged[!duplicated(merge_key)]

cat("Exact matches:", nrow(merged), "candidates\n")
cat("Match rate:", round(nrow(merged) / nrow(assembly) * 100, 1), "%\n")

## Second pass: try matching without first name initial
## Some assembly names have "INITIAL.SURNAME" while MyNeta has "FIRSTNAME SURNAME"
## Try matching on state + year + last word of name (surname)
if (nrow(merged) < 20000) {
  cat("Attempting surname-based matching for unmatched candidates...\n")

  ## Get unmatched from assembly
  unmatched_ae <- assembly[!merge_key %in% merged$merge_key]

  ## Get unmatched from MyNeta
  unmatched_mn <- mynetas_state[!merge_key %in% merged$merge_key]

  ## For name matching: use state + year + constituency + surname
  get_surname <- function(x) {
    words <- strsplit(x, "\\s+")
    sapply(words, function(w) if (length(w) > 0) w[length(w)] else "")
  }

  unmatched_ae[, surname := get_surname(cand_name_clean)]
  unmatched_mn[, surname := get_surname(cand_name_clean)]

  ## Match on state + year + constituency + surname
  unmatched_ae[, merge_key2 := paste(state_clean, year, toupper(trimws(ac_name)), surname)]
  unmatched_mn[, merge_key2 := paste(state_clean, year_clean, const_clean, surname)]

  merged2 <- merge(
    unmatched_ae[, .(merge_key2, merge_key, state, year, ac_no, ac_name, cand_name, party,
                     votes, sex, age, rank, const_id, ac_type)],
    unmatched_mn[, .(merge_key2, total_assets, net_worth, n_criminal,
                      movable_self, immovable_self, education,
                      cand_name_clean)],
    by = "merge_key2",
    all.x = FALSE,
    allow.cartesian = TRUE
  )

  ## Keep only unique matches (one-to-one by merge_key2)
  merged2[, n_matches := .N, by = merge_key2]
  merged2 <- merged2[n_matches == 1]
  merged2[, c("merge_key2", "n_matches") := NULL]

  cat("Surname+constituency matches:", nrow(merged2), "additional candidates\n")

  ## Combine
  merged <- rbind(merged, merged2, fill = TRUE)
  merged <- merged[!duplicated(merge_key)]

  cat("Total matches after both passes:", nrow(merged), "candidates\n")
  cat("Combined match rate:", round(nrow(merged) / nrow(assembly) * 100, 1), "%\n")
}

## =============================================================================
## PART 5: Construct RDD analysis dataset
## =============================================================================

cat("\n=== Constructing RDD analysis dataset ===\n")

## For each constituency-election, identify top-2 candidates with asset data
merged[, cand_rank := frankv(-votes, ties.method = "first"), by = const_id]
merged_top2 <- merged[cand_rank <= 2]

## Only keep constituency-elections where BOTH top-2 candidates have asset data
merged_top2[, n_with_assets := sum(!is.na(total_assets) & total_assets > 0),
            by = const_id]
matched_both <- merged_top2[n_with_assets == 2]

cat("Constituencies with both top-2 candidates matched:",
    length(unique(matched_both$const_id)), "\n")

## Reshape to wide format (one row per constituency-election)
rdd_data <- dcast(matched_both[cand_rank <= 2],
                  const_id + state + year + ac_no + ac_name + ac_type ~
                    paste0("c", cand_rank),
                  value.var = c("cand_name", "party", "votes", "total_assets",
                                "net_worth", "n_criminal", "sex", "age",
                                "movable_self", "immovable_self", "education"))

## Identify the wealthier candidate
rdd_data[, `:=`(
  ## Who is wealthier? (candidate 1 = winner by construction)
  c1_wealthier = total_assets_c1 > total_assets_c2,

  ## Vote margin (winner - runner-up, as pct of top-2 votes)
  total_top2_votes = votes_c1 + votes_c2,
  margin_abs = votes_c1 - votes_c2
)]

rdd_data[, margin_pct := margin_abs / total_top2_votes * 100]

## Construct the RDD running variable:
## Vote margin of the WEALTHIER candidate
## Positive = wealthier candidate won; Negative = wealthier candidate lost
rdd_data[, `:=`(
  ## Assign 'rich' and 'poor' candidate labels
  rich_votes = ifelse(c1_wealthier, votes_c1, votes_c2),
  poor_votes = ifelse(c1_wealthier, votes_c2, votes_c1),
  rich_assets = ifelse(c1_wealthier, total_assets_c1, total_assets_c2),
  poor_assets = ifelse(c1_wealthier, total_assets_c2, total_assets_c1),
  rich_name = ifelse(c1_wealthier, cand_name_c1, cand_name_c2),
  poor_name = ifelse(c1_wealthier, cand_name_c2, cand_name_c1),
  rich_party = ifelse(c1_wealthier, party_c1, party_c2),
  poor_party = ifelse(c1_wealthier, party_c2, party_c1),
  rich_criminal = ifelse(c1_wealthier, n_criminal_c1, n_criminal_c2),
  poor_criminal = ifelse(c1_wealthier, n_criminal_c2, n_criminal_c1),
  rich_sex = ifelse(c1_wealthier, sex_c1, sex_c2),
  poor_sex = ifelse(c1_wealthier, sex_c2, sex_c1),
  rich_age = ifelse(c1_wealthier, age_c1, age_c2),
  poor_age = ifelse(c1_wealthier, age_c2, age_c1)
)]

## RDD running variable: vote margin of wealthier candidate
rdd_data[, rich_margin := (rich_votes - poor_votes) / (rich_votes + poor_votes) * 100]

## Treatment indicator: wealthier candidate won
rdd_data[, rich_won := as.integer(rich_margin > 0)]

## Wealth ratio and log wealth difference
rdd_data[, `:=`(
  wealth_ratio = rich_assets / pmax(poor_assets, 1),
  log_wealth_diff = log(rich_assets + 1) - log(poor_assets + 1),
  log_rich_assets = log(rich_assets + 1),
  log_poor_assets = log(poor_assets + 1)
)]

## Close election indicator
rdd_data[, close_election := abs(rich_margin) < 5]

cat("RDD dataset constructed:", nrow(rdd_data), "constituency-elections\n")
cat("Rich candidate won:", sum(rdd_data$rich_won), "(",
    round(mean(rdd_data$rich_won) * 100, 1), "%)\n")
cat("Close elections (|margin| < 5%):", sum(rdd_data$close_election), "\n")
cat("Median wealth ratio:", round(median(rdd_data$wealth_ratio, na.rm = TRUE), 1), "\n")
cat("Mean log wealth diff:", round(mean(rdd_data$log_wealth_diff, na.rm = TRUE), 2), "\n")

## Summary statistics
cat("\n=== Summary Statistics ===\n")
cat("States:", length(unique(rdd_data$state)), "\n")
cat("Years:", paste(sort(unique(rdd_data$year)), collapse = ", "), "\n")
cat("Observations:", nrow(rdd_data), "\n")
cat("Rich candidate's median assets (Rs):",
    formatC(median(rdd_data$rich_assets, na.rm = TRUE),
            format = "f", big.mark = ",", digits = 0), "\n")
cat("Poor candidate's median assets (Rs):",
    formatC(median(rdd_data$poor_assets, na.rm = TRUE),
            format = "f", big.mark = ",", digits = 0), "\n")

## =============================================================================
## PART 6: Also prepare Lok Sabha dataset (validation)
## =============================================================================

cat("\n=== Preparing Lok Sabha dataset (validation) ===\n")
loksabha <- fread(file.path(data_dir, "loksabha_affidavits_2004_2019.csv"),
                  encoding = "UTF-8")

## The LS data already has assets + winner flag
## Clean names and assets
loksabha[, `:=`(
  state_clean = toupper(trimws(State)),
  const_clean = toupper(trimws(Constituency)),
  cand_clean  = toupper(trimws(Candidate)),
  total_assets_ls = parse_rupees(TotalAssets),
  total_liab_ls = parse_rupees(TotalLiabilities),
  n_criminal_ls = as.integer(CriminalCases),
  is_winner_ls = as.integer(Winner == "Yes" | Winner == "1" | Winner == "TRUE"),
  year_ls = as.integer(Year)
)]

## Create constituency ID
loksabha[, const_id_ls := paste(state_clean, const_clean, year_ls)]

## Rank by votes (if available) or by winner status
## The LS dataset doesn't have vote counts directly
## We'll use it for supplementary analysis (comparing asset distributions)
cat("Lok Sabha dataset:", nrow(loksabha), "candidates\n")
cat("With valid assets:", sum(loksabha$total_assets_ls > 0, na.rm = TRUE), "\n")

## =============================================================================
## Save cleaned data
## =============================================================================

cat("\n=== Saving cleaned data ===\n")

fwrite(rdd_data, file.path(data_dir, "rdd_analysis.csv"))
fwrite(top2_wide, file.path(data_dir, "assembly_top2.csv"))
fwrite(loksabha, file.path(data_dir, "loksabha_clean.csv"))

cat("Saved rdd_analysis.csv:", nrow(rdd_data), "rows\n")
cat("Saved assembly_top2.csv:", nrow(top2_wide), "rows\n")
cat("Saved loksabha_clean.csv:", nrow(loksabha), "rows\n")

cat("\n=== Data cleaning complete ===\n")
