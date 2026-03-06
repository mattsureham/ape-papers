## 05_figures.R — Generate all figures for apep_0537
## GenAI as Seniority-Biased Technological Change

source("00_packages.R")
data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Load data
seniority_trends <- fread(file.path(data_dir, "summary_seniority_trends.csv"))
ddd_panel <- fread(file.path(data_dir, "ddd_panel.csv"))
ind_aioe <- unique(ddd_panel[!is.na(aioe_industry), .(naics_2d, aioe_industry)])
oews_ind_sen <- fread(file.path(data_dir, "oews_industry_seniority.csv"))
qcew_trends <- fread(file.path(data_dir, "qcew_tercile_trends.csv"))

# Load regression results
res_entry <- readRDS(file.path(data_dir, "results_oews_entry_share.rds"))
res_ddd <- readRDS(file.path(data_dir, "results_ddd.rds"))
res_qcew <- readRDS(file.path(data_dir, "results_qcew.rds"))
rob <- readRDS(file.path(data_dir, "results_robustness.rds"))

# ===========================================================================
# Figure 1: Aggregate Seniority Shares Over Time
# ===========================================================================
cat("--- Figure 1: Seniority Shares ---\n")

fig1_data <- seniority_trends[seniority %in% c("Entry-Level", "Senior")]
fig1_data[, seniority := factor(seniority, levels = c("Entry-Level", "Senior"))]

p1 <- ggplot(fig1_data, aes(x = oews_year, y = emp_share, color = seniority)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2022.5, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  annotate("text", x = 2022.5, y = max(fig1_data$emp_share) * 0.98,
           label = "ChatGPT\nRelease", hjust = 1.1, size = 3, color = "grey40") +
  scale_color_manual(values = apep_colors) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_x_continuous(breaks = 2015:2024) +
  labs(
    title = "Entry-Level Employment Share Declining, Senior Share Rising",
    subtitle = "Share of total employment by O*NET Job Zone seniority, BLS OEWS 2015-2024",
    x = NULL, y = "Share of Total Employment", color = NULL
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "fig1_seniority_trends.pdf"), p1, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig1_seniority_trends.png"), p1, width = 8, height = 5, dpi = 300)
fwrite(fig1_data, file.path(data_dir, "fig1_data.csv"))
cat("  Saved fig1_seniority_trends\n")

# ===========================================================================
# Figure 2: Entry-Level Share by AIOE Tercile
# ===========================================================================
cat("--- Figure 2: Entry-Level Share by AIOE Tercile ---\n")

# Compute entry share by AIOE tercile × year
entry_by_tercile <- oews_ind_sen[seniority == "Entry-Level"]
entry_by_tercile <- merge(entry_by_tercile, ind_aioe, by = "naics_2d", all.x = TRUE)
entry_by_tercile <- entry_by_tercile[!is.na(aioe_industry)]
entry_by_tercile[, aioe_tercile := fcase(
  aioe_industry >= quantile(aioe_industry, 0.67), "High AI Exposure",
  aioe_industry >= quantile(aioe_industry, 0.33), "Medium AI Exposure",
  default = "Low AI Exposure"
)]

fig2_data <- entry_by_tercile[,
  .(entry_share = weighted.mean(emp_share, industry_total, na.rm = TRUE)),
  by = .(aioe_tercile, oews_year)
]
fig2_data[, aioe_tercile := factor(aioe_tercile,
                                    levels = c("High AI Exposure", "Medium AI Exposure", "Low AI Exposure"))]

p2 <- ggplot(fig2_data, aes(x = oews_year, y = entry_share, color = aioe_tercile)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.2) +
  geom_vline(xintercept = 2022.5, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  annotate("text", x = 2022.5, y = max(fig2_data$entry_share, na.rm = TRUE) * 0.98,
           label = "ChatGPT", hjust = 1.1, size = 3, color = "grey40") +
  scale_color_manual(values = c("High AI Exposure" = "#E63946",
                                 "Medium AI Exposure" = "#457B9D",
                                 "Low AI Exposure" = "#2A9D8F")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_x_continuous(breaks = 2015:2024) +
  labs(
    title = "Entry-Level Share Declines Faster in High-AI-Exposure Industries",
    subtitle = "Industries grouped by Felten-Raj-Seamans AI Occupational Exposure, BLS OEWS",
    x = NULL, y = "Entry-Level Employment Share", color = NULL
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "fig2_entry_share_by_aioe.pdf"), p2, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig2_entry_share_by_aioe.png"), p2, width = 8, height = 5, dpi = 300)
fwrite(fig2_data, file.path(data_dir, "fig2_data.csv"))
cat("  Saved fig2_entry_share_by_aioe\n")

# ===========================================================================
# Figure 3: Event Study — Entry-Level Share × AIOE
# ===========================================================================
cat("--- Figure 3: Event Study ---\n")

es_coefs <- as.data.table(coeftable(res_entry$m1b), keep.rownames = TRUE)
setnames(es_coefs, c("rn", "Estimate", "Std. Error", "t value", "Pr(>|t|)"),
         c("term", "estimate", "se", "t", "p"))

# Extract year from coefficient name
es_coefs[, year := as.integer(sub(".*::", "", term))]
es_coefs <- es_coefs[!is.na(year)]

# Add reference year
ref_row <- data.table(term = "ref", estimate = 0, se = 0, t = 0, p = 1, year = 2022)
es_coefs <- rbind(es_coefs, ref_row)

es_coefs[, `:=`(
  ci_lower = estimate - 1.96 * se,
  ci_upper = estimate + 1.96 * se
)]

p3 <- ggplot(es_coefs, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_vline(xintercept = 2022.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#E63946") +
  geom_line(color = "#E63946", linewidth = 1) +
  geom_point(color = "#E63946", size = 2.5) +
  annotate("text", x = 2022.5, y = max(es_coefs$ci_upper, na.rm = TRUE),
           label = "ChatGPT", hjust = 1.1, size = 3, color = "grey40") +
  scale_x_continuous(breaks = sort(unique(es_coefs$year))) +
  labs(
    title = "Event Study: Entry-Level Share Response to AI Exposure",
    subtitle = "Coefficient on AIOE × Year interaction, ref. year = 2022",
    x = NULL, y = "Coefficient (Entry-Level Share × AIOE)"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3_event_study.png"), p3, width = 8, height = 5, dpi = 300)
fwrite(es_coefs, file.path(data_dir, "fig3_data.csv"))
cat("  Saved fig3_event_study\n")

# ===========================================================================
# Figure 4: SEC EDGAR GenAI Filings Over Time
# ===========================================================================
cat("--- Figure 4: EDGAR GenAI Filings ---\n")

edgar_df <- fread(file.path(data_dir, "edgar_genai_filings.csv"))
edgar_by_year <- edgar_df[, .N, by = filing_year]
setnames(edgar_by_year, "N", "n_filings")

# Add zeros for years with no filings
all_years <- data.table(filing_year = 2018:2025)
edgar_by_year <- merge(all_years, edgar_by_year, by = "filing_year", all.x = TRUE)
edgar_by_year[is.na(n_filings), n_filings := 0]

p4 <- ggplot(edgar_by_year, aes(x = filing_year, y = n_filings)) +
  geom_col(fill = "#457B9D", alpha = 0.8) +
  geom_vline(xintercept = 2022.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2022.5, y = max(edgar_by_year$n_filings) * 0.9,
           label = "ChatGPT\nRelease", hjust = 1.1, size = 3, color = "grey40") +
  scale_x_continuous(breaks = 2018:2025) +
  labs(
    title = "Generative AI Mentions in SEC 10-K Filings",
    subtitle = "Number of 10-K filings mentioning GenAI terms, EDGAR Full-Text Search",
    x = NULL, y = "Number of 10-K Filings"
  )

ggsave(file.path(fig_dir, "fig4_edgar_genai.pdf"), p4, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig4_edgar_genai.png"), p4, width = 7, height = 4.5, dpi = 300)
fwrite(edgar_by_year, file.path(data_dir, "fig4_data.csv"))
cat("  Saved fig4_edgar_genai\n")

# ===========================================================================
# Figure 5: Senior Share by AIOE Tercile (Companion to Fig 2)
# ===========================================================================
cat("--- Figure 5: Senior Share by AIOE Tercile ---\n")

senior_by_tercile <- oews_ind_sen[seniority == "Senior"]
senior_by_tercile <- merge(senior_by_tercile, ind_aioe, by = "naics_2d", all.x = TRUE)
senior_by_tercile <- senior_by_tercile[!is.na(aioe_industry)]
senior_by_tercile[, aioe_tercile := fcase(
  aioe_industry >= quantile(aioe_industry, 0.67), "High AI Exposure",
  aioe_industry >= quantile(aioe_industry, 0.33), "Medium AI Exposure",
  default = "Low AI Exposure"
)]

fig5_data <- senior_by_tercile[,
  .(senior_share = weighted.mean(emp_share, industry_total, na.rm = TRUE)),
  by = .(aioe_tercile, oews_year)
]
fig5_data[, aioe_tercile := factor(aioe_tercile,
                                    levels = c("High AI Exposure", "Medium AI Exposure", "Low AI Exposure"))]

p5 <- ggplot(fig5_data, aes(x = oews_year, y = senior_share, color = aioe_tercile)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.2) +
  geom_vline(xintercept = 2022.5, linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("High AI Exposure" = "#E63946",
                                 "Medium AI Exposure" = "#457B9D",
                                 "Low AI Exposure" = "#2A9D8F")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_x_continuous(breaks = 2015:2024) +
  labs(
    title = "Senior Employment Share Rises Faster in High-AI-Exposure Industries",
    subtitle = "Industries grouped by AI Occupational Exposure, BLS OEWS",
    x = NULL, y = "Senior Employment Share", color = NULL
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "fig5_senior_share_by_aioe.pdf"), p5, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig5_senior_share_by_aioe.png"), p5, width = 8, height = 5, dpi = 300)
fwrite(fig5_data, file.path(data_dir, "fig5_data.csv"))
cat("  Saved fig5_senior_share_by_aioe\n")

cat("\n=== All figures generated ===\n")
