# tests/test_visualize.R
# Load package code for testing
source("R/data_load.R")
source("R/helpers.R")
source("R/analysis.R")
source("R/visualize.R")

# Ensure plot functions return objects without crashing
sample <- analyze_relationships(load_data()$air, load_data()$plants)$summary
p <- plot_growth_distribution(sample)
# We expect a plotly object (a list with class 'plotly')
stopifnot(inherits(p, "plotly"))
p2 <- plot_climate_trend(load_data()$air)
stopifnot(inherits(p2, "plotly"))
message("test_visualize: OK")
