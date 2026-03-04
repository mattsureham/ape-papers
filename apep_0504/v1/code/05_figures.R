## ============================================================
## 05_figures.R — All figure generation
## APEP Paper: Does Naming Work?
## ============================================================

source("00_packages.R")
library(fixest)
library(patchwork)
library(data.table)

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, yq := as.Date(yq)]
food_panel <- panel[is_food == TRUE]
results <- readRDS(file.path(data_dir, "main_results.rds"))

## ============================================================
## Figure 1: Raw trends — Food business entries by country
## ============================================================
cat("Creating Figure 1: Raw trends...\n")

trends <- food_panel[, .(
  total_entry = sum(n_entry, na.rm = TRUE),
  n_la = uniqueN(la_code)
), by = .(country, yq)]

trends[, avg_entry := total_entry / n_la]

fig1 <- ggplot(trends, aes(x = yq, y = avg_entry, color = country)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2013-11-28"),
             linetype = "dashed", color = "red", alpha = 0.7) +
  geom_vline(xintercept = as.Date("2016-10-07"),
             linetype = "dashed", color = "orange", alpha = 0.7) +
  annotate("text", x = as.Date("2014-06-01"), y = Inf,
           label = "Wales\nmandatory", vjust = 1.5, size = 3, color = "red") +
  annotate("text", x = as.Date("2017-04-01"), y = Inf,
           label = "NI\nmandatory", vjust = 1.5, size = 3, color = "orange") +
  scale_color_manual(values = c("England" = "grey50",
                                "Wales" = "#CC0000",
                                "Northern Ireland" = "#FF8C00")) +
  labs(title = "Food Business Entries per Local Authority",
       subtitle = "Quarterly count of new food service company incorporations",
       x = NULL, y = "Average entries per LA per quarter",
       color = "Country") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig1_raw_trends.pdf"),
       fig1, width = 8, height = 5)

## ============================================================
## Figure 2: Event study — Dynamic treatment effects
## ============================================================
cat("Creating Figure 2: Event study...\n")

m_es_entry <- results$event_study_entry
m_es_exit <- results$event_study_exit

# Extract coefficients for manual ggplot event study
make_es_plot <- function(model, title, ylab = "Coefficient estimate") {
  ct <- coeftable(model)
  es_rows <- grep("rel_time_binned", rownames(ct))
  d <- data.table(
    rel_time = as.integer(gsub(".*::", "", rownames(ct)[es_rows])),
    estimate = ct[es_rows, 1],
    se = ct[es_rows, 2]
  )
  d[, ci_lo := estimate - 1.96 * se]
  d[, ci_hi := estimate + 1.96 * se]

  ggplot(d, aes(x = rel_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "steelblue", size = 2) +
    labs(title = title,
         x = "Quarters relative to mandatory display",
         y = ylab) +
    theme_minimal(base_size = 12)
}

fig2a <- make_es_plot(m_es_entry, "Effect on Food Business Entries")
ggsave(file.path(fig_dir, "fig2a_event_study_entry.pdf"),
       fig2a, width = 8, height = 5)

fig2b <- make_es_plot(m_es_exit, "Effect on Cohort Exit Proxy")
ggsave(file.path(fig_dir, "fig2b_event_study_exit.pdf"),
       fig2b, width = 8, height = 5)

## ============================================================
## Figure 3: CS-DiD dynamic aggregation
## ============================================================
cat("Creating Figure 3: CS-DiD...\n")

tryCatch({
  cs_entry_dyn <- readRDS(file.path(data_dir, "cs_entry_dyn.rds"))

  fig3 <- ggdid(cs_entry_dyn,
    title = "Callaway & Sant'Anna: Dynamic Effects on Food Business Entries") +
    theme_minimal(base_size = 12) +
    labs(x = "Periods relative to mandatory display",
         y = "ATT estimate")

  ggsave(file.path(fig_dir, "fig3_cs_did_entry.pdf"),
         fig3, width = 8, height = 5)
}, error = function(e) {
  cat("CS-DiD plot skipped:", e$message, "\n")
})

## ============================================================
## Figure 4: Placebo — Non-food vs food businesses
## ============================================================
cat("Creating Figure 4: Placebo comparison...\n")

placebo_trends <- panel[country %in% c("Wales", "England"),
  .(avg_entry = mean(n_entry, na.rm = TRUE)),
  by = .(yq, is_food, country)
]

fig4 <- ggplot(placebo_trends, aes(x = yq, y = avg_entry,
                                    color = interaction(country, is_food),
                                    linetype = is_food)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = as.Date("2013-11-28"),
             linetype = "dashed", color = "grey30") +
  scale_color_manual(
    values = c("England.TRUE" = "grey60", "England.FALSE" = "grey80",
               "Wales.TRUE" = "#CC0000", "Wales.FALSE" = "#FF6666"),
    labels = c("England Food", "England Non-food",
               "Wales Food", "Wales Non-food")
  ) +
  scale_linetype_manual(values = c("TRUE" = "solid", "FALSE" = "dashed"),
                        guide = "none") +
  labs(title = "Placebo Test: Food vs. Non-Food Business Entries",
       subtitle = "Non-food businesses should not respond to FHRS mandate",
       x = NULL, y = "Average entries per LA per quarter",
       color = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig4_placebo.pdf"),
       fig4, width = 8, height = 5)

## ============================================================
## Figure 5: FHRS quality distribution by country
## ============================================================
cat("Creating Figure 5: Rating distribution...\n")

fhrs <- fread(file.path(data_dir, "fhrs_establishments.csv"))
fhrs[, rating_numeric := suppressWarnings(as.integer(rating_value))]

rating_dist <- fhrs[!is.na(rating_numeric) & rating_numeric >= 0 &
                     rating_numeric <= 5,
  .(count = .N), by = .(country, rating_numeric)
]
rating_dist[, pct := count / sum(count) * 100, by = country]

fig5 <- ggplot(rating_dist, aes(x = factor(rating_numeric), y = pct,
                                 fill = country)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("England" = "grey50",
                                "Wales" = "#CC0000",
                                "Northern Ireland" = "#FF8C00")) +
  labs(title = "Food Hygiene Rating Distribution by Country",
       subtitle = "Mandatory display jurisdictions vs voluntary (England)",
       x = "Food Hygiene Rating", y = "Percent of establishments (%)",
       fill = "Country") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig5_rating_distribution.pdf"),
       fig5, width = 8, height = 5)

## ============================================================
## Figure 6: Cohort survival rates by country
## ============================================================
cat("Creating Figure 6: Cohort survival...\n")

survival <- fread(file.path(data_dir, "cohort_survival.csv"))
food_survival <- survival[is_food == TRUE & inc_year >= 2005 & inc_year <= 2022]

fig6 <- ggplot(food_survival, aes(x = inc_year, y = survival_rate * 100,
                                    color = country)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2013, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_vline(xintercept = 2016, linetype = "dashed", color = "orange", alpha = 0.5) +
  scale_color_manual(values = c("England" = "grey50",
                                "Wales" = "#CC0000",
                                "Northern Ireland" = "#FF8C00")) +
  labs(title = "Food Business Survival Rate by Incorporation Cohort",
       subtitle = "Fraction of cohort still registered as Active",
       x = "Year of incorporation", y = "Survival rate (%)",
       color = "Country") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig6_cohort_survival.pdf"),
       fig6, width = 8, height = 5)

## ============================================================
## Figure 7: Treatment map
## ============================================================
cat("Creating Figure 7: Treatment map...\n")

la_summary <- food_panel[, .(n_la = uniqueN(la_code)), by = country]
la_summary[, treatment := fifelse(country == "England", "Control (voluntary)",
                           "Treated (mandatory)")]

fig7 <- ggplot(la_summary, aes(x = country, y = n_la, fill = treatment)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = n_la), vjust = -0.3) +
  scale_fill_manual(values = c("Control (voluntary)" = "grey60",
                                "Treated (mandatory)" = "#CC0000")) +
  labs(title = "Local Authorities by Country and Treatment Status",
       x = NULL, y = "Number of Local Authorities",
       fill = "Display mandate") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig7_treatment_map.pdf"),
       fig7, width = 6, height = 4)

cat("\n=== ALL FIGURES GENERATED ===\n")
cat("Figures saved to:", fig_dir, "\n")
