## ── 04_robustness.R ───────────────────────────────────────────────────────────
## Robustness checks for apep_0808
## ──────────────────────────────────────────────────────────────────────────────

source("code/00_packages.R")

cat("=== ROBUSTNESS CHECKS FOR APEP_0808 ===\n\n")

df <- readRDS("data/analysis_dataset.rds")

## ── 1. Logit specification ──────────────────────────────────────────────────
## Binary outcome → logit as robustness check on LPM
cat("=== Logit specification ===\n")

logit1 <- glm(reinstated ~ is_c3 + is_c4 + is_c5 + is_c6 + is_c8 + factor(state),
              data = df, family = binomial(link = "logit"))

## Average marginal effects
cat("Computing average marginal effects...\n")
ame <- margins::margins(logit1, variables = c("is_c3", "is_c4", "is_c5", "is_c6", "is_c8"))
cat("Logit AME:\n")
print(summary(ame))

## ── 2. Placebo: Compare 2010 wave to post-2010 waves ────────────────────────
## If the subsection gradient is specific to the PPA shock (information
## asymmetry), it should be weaker for post-2010 revocations (by then,
## the filing requirement was well-known).

cat("\n=== Placebo: Post-2010 revocations ===\n")

rev_all <- readRDS("data/revocation_raw.rds")
rev_all <- rev_all[country == "US" & nchar(state) == 2]
bmf_raw <- readRDS("data/bmf_raw.rds")
bmf_eins <- sprintf("%09d", as.integer(bmf_raw$EIN))
rev_all[, ein_char := sprintf("%09d", as.integer(ein))]
rev_all[, reinstated := as.integer(ein_char %in% bmf_eins)]
rev_all[, subsection_code := as.integer(subsection)]

## Post-2010 revocations (2012-2019, excluding 2011 transition year)
rev_post <- rev_all[rev_year >= 2012 & rev_year <= 2019]
rev_post[, has_physical_assets := as.integer(
  subsection_code %in% c(13, 19, 7, 8, 5)
)]

cat(sprintf("Post-2010 revocations (2012-2019): %s\n",
            format(nrow(rev_post), big.mark = ",")))

## Same regression on post-2010 data
m_post <- feols(reinstated ~ has_physical_assets | state,
                data = rev_post[nchar(state) == 2], vcov = ~state)

cat("Asset-holding effect in post-2010 revocations:\n")
print(summary(m_post))

## Compare coefficients
m_2010 <- readRDS("data/models.rds")$m4
cat(sprintf("\nAsset premium (2010 wave): %.3f (SE: %.3f)\n",
            coef(m_2010)["has_physical_assets"],
            se(m_2010)["has_physical_assets"]))
cat(sprintf("Asset premium (2012-2019): %.3f (SE: %.3f)\n",
            coef(m_post)["has_physical_assets"],
            se(m_post)["has_physical_assets"]))

## ── 3. Geographic concentration: Urban vs rural proxy ────────────────────────
## Use state-level nonprofit density as proxy for nonprofit infrastructure

cat("\n=== Nonprofit infrastructure gradient ===\n")

## Quintiles of state nonprofit density
state_data <- df[, .(
  rate = mean(reinstated),
  n_per_k = mean(nonprofits_per_1000, na.rm = TRUE),
  N = .N
), by = state][!is.na(n_per_k)]

state_data[, density_q := cut(n_per_k, breaks = quantile(n_per_k, probs = seq(0, 1, 0.2)),
                               include.lowest = TRUE, labels = paste0("Q", 1:5))]

density_gradient <- state_data[, .(
  mean_rate = weighted.mean(rate, N),
  n_states = .N,
  n_orgs = sum(N)
), by = density_q][order(density_q)]

cat("Reinstatement rate by state nonprofit density quintile:\n")
print(density_gradient)

## ── 4. Subsection × state interaction ────────────────────────────────────────
## Test whether the subsection gradient varies across states

cat("\n=== Subsection × state interaction ===\n")

## Focus on top 10 states (by revocation count) and 3 main subsections
big_states <- df[state %in% c("CA","TX","NY","FL","IL","PA","OH","MI","NJ","GA")]
big_states[, sub3 := fcase(
  subsection_code == 3, "c3",
  subsection_code == 7, "c7",
  subsection_code %in% c(13, 19, 8, 5), "asset_holding",
  default = "other"
)]

m_interact <- feols(reinstated ~ sub3 * state, data = big_states, vcov = "hetero")
cat("F-test for interaction: subsection pattern varies by state?\n")
## Joint test of interaction terms
wald_test <- wald(m_interact, "sub3.*:state.*", print = FALSE)
cat(sprintf("Wald stat: %.1f, p-value: %.4f\n", wald_test$stat, wald_test$p))

## ── 5. Compositional analysis: who died? ─────────────────────────────────────
## Compare the composition of the pre-revocation registry to the
## post-revocation registry to measure the permanent compositional shift

cat("\n=== Compositional shift analysis ===\n")

## Pre-revocation: 376,472 + current BMF = total pre-revocation registry
## Simplification: compare subsection mix of revoked vs. surviving

bmf_raw <- readRDS("data/bmf_raw.rds")
bmf_sub <- bmf_raw[, .N, by = SUBSECTION]
setnames(bmf_sub, c("subsection_code", "n_surviving"))
bmf_sub[, subsection_code := as.integer(subsection_code)]

rev_sub <- df[, .N, by = subsection_code]
setnames(rev_sub, c("subsection_code", "n_revoked"))

comp <- merge(bmf_sub, rev_sub, by = "subsection_code", all = TRUE)
comp[is.na(n_surviving), n_surviving := 0]
comp[is.na(n_revoked), n_revoked := 0]
comp[, total_pre := n_surviving + n_revoked]
comp[, pct_revoked := n_revoked / total_pre * 100]
comp[, pct_surviving_registry := n_surviving / sum(n_surviving) * 100]
comp[, pct_pre_registry := total_pre / sum(total_pre) * 100]

cat("Compositional shift (main subsections):\n")
main_subs <- comp[subsection_code %in% c(3, 4, 5, 6, 7, 8, 13, 19)]
main_subs <- main_subs[order(-n_revoked)]
print(main_subs[, .(subsection_code, n_revoked, n_surviving, total_pre,
                     pct_revoked = round(pct_revoked, 1))])

## ── 6. Save robustness results ───────────────────────────────────────────────
saveRDS(list(
  logit_ame = summary(ame),
  m_post = m_post,
  density_gradient = density_gradient,
  comp = comp
), "data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
