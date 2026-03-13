## 02_clean_data.R — Construct analysis variables
## APEP paper apep_0611: CRA Lookback Cutoff and Midnight Rulemaking
##
## Defines CRA lookback dates for each presidential transition,
## computes running variable (days from cutoff), and constructs
## weekly aggregates for density analysis.

source("00_packages.R")

# ── Load raw data ────────────────────────────────────────────────────
rules <- readRDS("../data/fr_rules_raw.rds")
cat(sprintf("Loaded %d rules\n", nrow(rules)))

# ── CRA lookback cutoff dates ───────────────────────────────────────
# The CRA allows Congress to disapprove rules submitted in the last
# ~60 legislative (session) days. The CRS computes the approximate
# lookback date for each Congress. Sources: CRS Reports R43992, RL30116.
#
# These are approximate Senate lookback start dates. Rules published
# AFTER this date are CRA-vulnerable if a cross-party transition occurs.
# The exact dates vary by a few days depending on session calendar.

transitions <- tribble(
  ~transition_year, ~outgoing,    ~incoming,    ~cross_party, ~lookback_date,
  2001,             "Clinton",    "G.W. Bush",  TRUE,         "2000-05-29",
  2005,             "G.W. Bush",  "G.W. Bush",  FALSE,        "2004-05-19",
  2009,             "G.W. Bush",  "Obama",      TRUE,         "2008-05-15",
  2013,             "Obama",      "Obama",      FALSE,        "2012-05-15",
  2017,             "Obama",      "Trump",      TRUE,         "2016-05-30",
  2021,             "Trump",      "Biden",      TRUE,         "2020-05-19",
  2025,             "Biden",      "Trump",      TRUE,         "2024-05-22"
) %>%
  mutate(lookback_date = as.Date(lookback_date))

cat("Presidential transitions:\n")
print(transitions)

# ── Compute running variable ─────────────────────────────────────────
# For each rule, compute its distance (in days) from the nearest
# CRA lookback cutoff. Positive = inside the CRA window (vulnerable),
# Negative = before the window (immune).
#
# We assign each rule to the transition whose lookback date is closest,
# but only within a reasonable bandwidth (±365 days).

# For each transition, compute distance for all rules
rule_transition_pairs <- list()

for (i in seq_len(nrow(transitions))) {
  t <- transitions[i, ]
  rules_near <- rules %>%
    mutate(
      days_from_cutoff = as.numeric(pub_date - t$lookback_date),
      transition_year = t$transition_year,
      cross_party = t$cross_party,
      outgoing = t$outgoing,
      incoming = t$incoming,
      lookback_date = t$lookback_date
    ) %>%
    filter(abs(days_from_cutoff) <= 365) # Within 1 year of cutoff

  rule_transition_pairs[[i]] <- rules_near
}

df <- bind_rows(rule_transition_pairs)

# Remove potential duplicates (rules near two transition cutoffs)
# Keep the assignment to the closest cutoff
df <- df %>%
  group_by(document_number) %>%
  slice_min(abs(days_from_cutoff), n = 1, with_ties = FALSE) %>%
  ungroup()

cat(sprintf("Rules within ±365 days of a cutoff: %d\n", nrow(df)))

# ── Treatment indicator ─────────────────────────────────────────────
# CRA-vulnerable: published AFTER the lookback date (days_from_cutoff > 0)
df <- df %>%
  mutate(
    cra_vulnerable = days_from_cutoff > 0,
    in_window = cra_vulnerable & cross_party # Actually at risk
  )

# ── Weekly aggregates for density analysis ───────────────────────────
# Aggregate rule counts by week relative to the cutoff

df_weekly <- df %>%
  mutate(week_from_cutoff = floor(days_from_cutoff / 7)) %>%
  group_by(transition_year, cross_party, week_from_cutoff) %>%
  summarize(
    n_rules = n(),
    n_significant = sum(significant, na.rm = TRUE),
    avg_page_length = mean(page_length, na.rm = TRUE),
    avg_cfr_parts = mean(n_cfr_parts, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    cra_vulnerable = week_from_cutoff >= 0,
    mid_day = week_from_cutoff * 7 + 3.5 # Midpoint of week in days
  )

# ── Summary by transition ───────────────────────────────────────────
transition_summary <- df %>%
  group_by(transition_year, cross_party) %>%
  summarize(
    n_rules = n(),
    n_before = sum(!cra_vulnerable),
    n_after = sum(cra_vulnerable),
    n_significant = sum(significant, na.rm = TRUE),
    pct_significant = 100 * mean(significant, na.rm = TRUE),
    avg_page_length = mean(page_length, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nRules by transition:\n")
print(transition_summary, n = 20)

# ── Save analysis datasets ──────────────────────────────────────────
saveRDS(df, "../data/rules_analysis.rds")
saveRDS(df_weekly, "../data/rules_weekly.rds")
saveRDS(transitions, "../data/transitions.rds")
write_csv(df, "../data/rules_analysis.csv")

cat(sprintf("\nSaved analysis dataset: %d rules, %d weekly obs\n",
            nrow(df), nrow(df_weekly)))

cat("\n02_clean_data.R completed successfully.\n")
