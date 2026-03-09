## =============================================================================
## 05_figures.R — All figures for the paper
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir  <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE)

## -----------------------------------------------------------------------------
## Figure 1: Trends in Alcohol-Involved Fatal Crashes by Treatment Status
## -----------------------------------------------------------------------------

cat("Figure 1: Trends by treatment status...\n")

state_year <- fread(file.path(data_dir, "state_year_panel.csv"))

# Compute group means by year
trends <- state_year[, .(
  mean_alc_rate = mean(alc_rate),
  mean_non_alc_rate = mean(non_alc_rate),
  n_states = uniqueN(state_fips)
), by = .(YEAR, ever_treated)]

trends[, group := fifelse(ever_treated == 1,
                           "States that legalized online betting",
                           "States without online betting")]

fig1 <- ggplot(trends, aes(x = YEAR, y = mean_alc_rate,
                            color = group, linetype = group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "gray50",
             linewidth = 0.5) +
  annotate("text", x = 2018.1, y = max(trends$mean_alc_rate) * 0.95,
           label = "PASPA struck down\n(May 2018)", hjust = 0, size = 3,
           color = "gray40") +
  scale_color_manual(values = c("#2166AC", "#B2182B")) +
  scale_linetype_manual(values = c("solid", "solid")) +
  labs(
    x = "Year",
    y = "Alcohol-Involved Fatal Crashes per 100,000",
    color = NULL, linetype = NULL
  ) +
  theme(legend.position = c(0.35, 0.95),
        legend.background = element_rect(fill = "white", color = NA))

ggsave(file.path(fig_dir, "fig1_trends.pdf"), fig1,
       width = 7, height = 5)

## -----------------------------------------------------------------------------
## Figure 2: Event Study (CS-DiD or fixest)
## -----------------------------------------------------------------------------

cat("Figure 2: Event study...\n")

# Try CS event study first, fall back to fixest
if (file.exists(file.path(data_dir, "cs_event_study.csv"))) {
  es_df <- fread(file.path(data_dir, "cs_event_study.csv"))
  es_label <- "Callaway-Sant'Anna"
} else {
  es_df <- fread(file.path(data_dir, "fixest_event_study.csv"))
  setnames(es_df, c("estimate", "se", "ci_lower", "ci_upper"),
           c("att", "se", "ci_lower", "ci_upper"), skip_absent = TRUE)
  es_label <- "fixest"
}

# Add reference period
es_df <- rbind(
  es_df,
  data.table(event_time = -1, att = 0, se = 0,
             ci_lower = 0, ci_upper = 0),
  fill = TRUE
)

fig2 <- ggplot(es_df, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.4) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray50",
             linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = "#2166AC", alpha = 0.15) +
  geom_point(color = "#2166AC", size = 1.8) +
  geom_line(color = "#2166AC", linewidth = 0.5) +
  labs(
    x = "Months Relative to Online Betting Legalization",
    y = "ATT: Alcohol-Involved Fatal Crash Rate\n(per 100,000)"
  ) +
  scale_x_continuous(breaks = seq(-24, 24, by = 6)) +
  annotate("text", x = -12, y = max(es_df$ci_upper, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", hjust = 0.5, size = 3, color = "gray40") +
  annotate("text", x = 12, y = max(es_df$ci_upper, na.rm = TRUE) * 0.9,
           label = "Post-treatment", hjust = 0.5, size = 3, color = "gray40")

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2,
       width = 7, height = 5)

## -----------------------------------------------------------------------------
## Figure 3: Day-of-Week Alcohol Crash Shares (Treated vs Control)
## -----------------------------------------------------------------------------

cat("Figure 3: Day-of-week patterns...\n")

state_dow <- fread(file.path(data_dir, "state_dow_month_panel.csv"))

# Compute each day's share of total weekly alcohol-involved crashes
# This is: (Sunday alc crashes) / (total alc crashes across all days)
dow_pre_post <- state_dow[ever_treated == 1, .(
  alc_crashes = sum(alcohol_crashes)
), by = .(dow, treated)]

# Compute weekly totals per period
dow_totals <- dow_pre_post[, .(weekly_total = sum(alc_crashes)), by = treated]
dow_pre_post <- merge(dow_pre_post, dow_totals, by = "treated")
dow_pre_post[, alc_share := alc_crashes / weekly_total]

dow_pre_post[, period := fifelse(treated == 1, "Post-legalization", "Pre-legalization")]
dow_pre_post[, day_name := c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")[dow]]
dow_pre_post[, day_name := factor(day_name,
                                   levels = c("Sun", "Mon", "Tue", "Wed",
                                              "Thu", "Fri", "Sat"))]

fig3 <- ggplot(dow_pre_post,
               aes(x = day_name, y = alc_share, fill = period)) +
  geom_col(position = "dodge", width = 0.7) +
  geom_hline(yintercept = 1/7, linetype = "dashed", color = "gray50",
             linewidth = 0.4) +
  scale_fill_manual(values = c("#92C5DE", "#B2182B")) +
  labs(
    x = "Day of Week",
    y = "Share of Weekly Alcohol-Involved Fatal Crashes",
    fill = NULL
  ) +
  scale_y_continuous(labels = percent_format()) +
  annotate("text", x = 7, y = 1/7 + 0.005, label = "Uniform (1/7)",
           size = 2.5, color = "gray40", hjust = 1) +
  theme(legend.position = c(0.8, 0.9))

ggsave(file.path(fig_dir, "fig3_dow_pattern.pdf"), fig3,
       width = 7, height = 5)

## -----------------------------------------------------------------------------
## Figure 4: Leave-One-Out Sensitivity
## -----------------------------------------------------------------------------

cat("Figure 4: Leave-one-out...\n")

loo_dt <- fread(file.path(data_dir, "leave_one_out.csv"))

# Get state abbreviations (correct FIPS mapping)
state_abbrs <- data.table(
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
           "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
           "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
           "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
           "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

loo_dt[, dropped_state := as.character(dropped_state)]
loo_dt <- merge(loo_dt, state_abbrs,
                by.x = "dropped_state", by.y = "state_fips", all.x = TRUE)
loo_dt[is.na(abbr) | abbr == "", abbr := dropped_state]

setorder(loo_dt, coef)
loo_dt[, order := .I]

# Main estimate line
main_coef <- mean(loo_dt$coef)  # approximate

fig4 <- ggplot(loo_dt, aes(x = reorder(abbr, coef), y = coef)) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.4) +
  geom_hline(yintercept = main_coef, color = "#B2182B",
             linetype = "dashed", linewidth = 0.5) +
  geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  size = 0.3, color = "#2166AC") +
  coord_flip() +
  labs(
    x = "Dropped State",
    y = "DDD Coefficient (Legal × Sunday × NFL)"
  ) +
  annotate("text", x = 2, y = main_coef * 1.1,
           label = "Full sample", color = "#B2182B", size = 3, hjust = 0)

ggsave(file.path(fig_dir, "fig4_leave_one_out.pdf"), fig4,
       width = 6, height = 8)

## -----------------------------------------------------------------------------
## Figure 5: Treatment Map (states with online betting)
## -----------------------------------------------------------------------------

cat("Figure 5: Treatment map...\n")

# We'll use a simple listing since map packages may not be available
# Create a timeline visualization instead
state_year <- fread(file.path(data_dir, "state_year_panel.csv"))
state_year[, treat_date := as.Date(treat_date)]
treat_info <- unique(state_year[ever_treated == 1, .(state_fips, treat_date)])
treat_info[, state_fips := as.character(state_fips)]
treat_info <- merge(treat_info, state_abbrs,
                    by = "state_fips", all.x = TRUE)
treat_info[is.na(abbr) | abbr == "", abbr := state_fips]
setorder(treat_info, treat_date)
treat_info[, order := .I]

fig5 <- ggplot(treat_info, aes(x = treat_date, y = reorder(abbr, -order))) +
  geom_segment(aes(xend = as.Date("2023-12-31"), yend = reorder(abbr, -order)),
               color = "#B2182B", linewidth = 2, alpha = 0.5) +
  geom_point(size = 3, color = "#B2182B") +
  labs(
    x = "Online Sports Betting Launch Date",
    y = NULL
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(fig_dir, "fig5_treatment_timeline.pdf"), fig5,
       width = 7, height = 8)

## -----------------------------------------------------------------------------
## Figure 6: Nighttime vs. Daytime DDD comparison
## -----------------------------------------------------------------------------

cat("Figure 6: Mechanism summary...\n")

# Load main and robustness model objects for complete coefficient + SE data
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# Build mechanism summary from actual model objects
mechanism_df <- data.table(
  test = c("Main DDD (Alcohol)", "Placebo (Non-alcohol)",
           "Nighttime DDD", "Daytime DDD",
           "NFL Season DD", "Off-Season DD"),
  coef = c(
    coef(ddd1)["legal_x_sunday_x_nfl"],
    coef(ddd_placebo)["legal_x_sunday_x_nfl"],
    coef(ddd_night)["legal_x_sunday_x_nfl"],
    coef(ddd_day)["legal_x_sunday_x_nfl"],
    coef(dd_nfl)["legal_x_sunday"],
    coef(dd_offseason)["legal_x_sunday"]
  ),
  se = c(
    se(ddd1)["legal_x_sunday_x_nfl"],
    se(ddd_placebo)["legal_x_sunday_x_nfl"],
    se(ddd_night)["legal_x_sunday_x_nfl"],
    se(ddd_day)["legal_x_sunday_x_nfl"],
    se(dd_nfl)["legal_x_sunday"],
    se(dd_offseason)["legal_x_sunday"]
  )
)

mechanism_df[, `:=`(
  ci_lo = coef - 1.645 * se,
  ci_hi = coef + 1.645 * se
)]

# Order from top to bottom
mechanism_df[, test := factor(test, levels = rev(mechanism_df$test))]

fig6 <- ggplot(mechanism_df, aes(x = test, y = coef)) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.4) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#2166AC", size = 0.5, linewidth = 0.8) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Coefficient Estimate"
  )

ggsave(file.path(fig_dir, "fig6_mechanism.pdf"), fig6,
       width = 6, height = 4)

cat("\nAll figures saved to figures/\n")
cat(sprintf("  %d PDF files generated\n",
            length(list.files(fig_dir, pattern = "\\.pdf$"))))
