################################################################################
# 09f_diffusion_figures.R
# Figures for Policy Diffusion Analysis
#
# Figure 1: Distance monotonicity — coefficient vs. distance restriction
# Figure 2: Cascade visualization (conditional on Scenario A)
#
# Input:  ../data/state_diffusion_panel.rds, cascade_results.rds,
#         diffusion_scenario.txt
# Output: ../figures/fig_diffusion_distance.pdf
#         ../figures/fig_diffusion_cascade.pdf (if applicable)
################################################################################

source("00_packages.R")

cat("=== Diffusion Figures ===\n\n")

# ============================================================================
# 1. Distance Monotonicity Figure
# ============================================================================

cat("1. Distance monotonicity: coefficient vs. distance restriction...\n")

df <- readRDS("../data/state_diffusion_panel.rds")
df_main <- df %>% filter(!at_ceiling)

# State SCI weights for computing distance-restricted exposures
state_sci <- readRDS("../data/state_sci_weights.rds")

# State MW annual
state_mw_annual <- df %>%
  select(state_fips, year, log_own_mw) %>%
  distinct()

# Compute exposure at various distance thresholds
thresholds <- c(0, 100, 200, 300, 400, 500, 750, 1000)

compute_dist_exposure <- function(min_dist) {
  weights <- state_sci %>%
    filter(dist_km >= min_dist) %>%
    group_by(state_fips_1) %>%
    mutate(w_renorm = sci_state / sum(sci_state)) %>%
    ungroup()

  exp_list <- lapply(sort(unique(state_mw_annual$year)), function(yr) {
    mw <- state_mw_annual %>%
      filter(year == yr) %>%
      select(state_fips, log_mw = log_own_mw)

    weights %>%
      left_join(mw, by = c("state_fips_2" = "state_fips")) %>%
      filter(!is.na(log_mw)) %>%
      group_by(state_fips_1) %>%
      summarise(network_mw = sum(w_renorm * log_mw), .groups = "drop") %>%
      mutate(year = yr)
  })

  bind_rows(exp_list)
}

dist_results <- tibble(
  min_dist = integer(),
  coef = numeric(),
  se = numeric(),
  ci_lo = numeric(),
  ci_hi = numeric(),
  n_obs = integer()
)

for (d in thresholds) {
  cat("  Distance >=", d, "km...\n")

  exposure_d <- compute_dist_exposure(d) %>%
    rename(network_mw_d = network_mw)

  df_d <- df_main %>%
    left_join(exposure_d, by = c("state_fips" = "state_fips_1", "year")) %>%
    filter(!is.na(network_mw_d))

  if (nrow(df_d) < 50) {
    cat("    Too few obs (", nrow(df_d), "), skipping\n")
    next
  }

  m_d <- tryCatch(
    feols(mw_increased ~ network_mw_d + log_own_mw +
            gov_dem + trifecta_dem + trifecta_rep +
            union_density + unemp_rate |
            state_fips + year,
          data = df_d, cluster = ~state_fips),
    error = function(e) NULL
  )

  if (!is.null(m_d)) {
    b <- coef(m_d)["network_mw_d"]
    s <- sqrt(vcov(m_d)["network_mw_d", "network_mw_d"])
    dist_results <- bind_rows(dist_results, tibble(
      min_dist = d,
      coef = b,
      se = s,
      ci_lo = b - 1.96 * s,
      ci_hi = b + 1.96 * s,
      n_obs = nobs(m_d)
    ))
  }
}

# Plot
if (nrow(dist_results) > 2) {
  p_dist <- ggplot(dist_results, aes(x = min_dist, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#4575b4") +
    geom_line(color = "#4575b4", linewidth = 1) +
    geom_point(color = "#4575b4", size = 3) +
    labs(
      x = "Minimum Distance Threshold (km)",
      y = "Coefficient on Network MW Exposure",
      title = "Policy Diffusion: Distance Monotonicity",
      subtitle = "Effect of network MW exposure on state MW adoption, by distance restriction"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )

  ggsave("../figures/fig_diffusion_distance.pdf", p_dist, width = 7, height = 5)
  cat("  Saved fig_diffusion_distance.pdf\n")
} else {
  cat("  WARNING: Too few distance thresholds with valid results for figure\n")
}

# ============================================================================
# 2. Cascade Visualization (conditional on Scenario A)
# ============================================================================

scenario <- readLines("../data/diffusion_scenario.txt")[1]

if (scenario == "A" && file.exists("../data/cascade_results.rds")) {
  cat("\n2. Cascade visualization...\n")

  cascade <- readRDS("../data/cascade_results.rds")

  if (cascade$cascade_computed) {
    # Distribution of total states affected
    dist_df <- tibble(states_affected = cascade$total_states_distribution)

    p_cascade <- ggplot(dist_df, aes(x = states_affected)) +
      geom_histogram(binwidth = 1, fill = "#d73027", alpha = 0.7, color = "white") +
      geom_vline(xintercept = cascade$median_states_affected,
                 linetype = "dashed", color = "black", linewidth = 0.8) +
      annotate("text",
               x = cascade$median_states_affected + 1,
               y = Inf, vjust = 2,
               label = paste0("Median = ", cascade$median_states_affected),
               fontface = "bold") +
      labs(
        x = "Number of States Affected by Cascade",
        y = "Frequency (10,000 simulations)",
        title = "Policy Cascade: California $1 MW Increase",
        subtitle = paste0("Spectral radius = ", round(cascade$spectral_radius, 3),
                         ", avg multiplier = ", round(cascade$avg_multiplier, 2))
      ) +
      theme_minimal(base_size = 11) +
      theme(
        plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank()
      )

    ggsave("../figures/fig_diffusion_cascade.pdf", p_cascade, width = 7, height = 5)
    cat("  Saved fig_diffusion_cascade.pdf\n")
  }
} else {
  cat("\n2. Cascade figure not applicable (scenario:", scenario, ")\n")
}

cat("\n=== Diffusion Figures Complete ===\n")
