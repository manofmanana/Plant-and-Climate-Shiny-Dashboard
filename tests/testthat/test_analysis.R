source(file.path("..", "R", "data_load.R"))
source(file.path("..", "R", "helpers.R"))
source(file.path("..", "R", "analysis.R"))
source(file.path("..", "R", "visualize.R"))

data <- load_data()
out <- analyze_relationships(data$air, data$plants)
# Check structure
stopifnot(is.list(out))
stopifnot("summary" %in% names(out))
stopifnot("climate_corr" %in% names(out))
# climate_corr may be NA_real_ if insufficient data, but should be present
stopifnot(length(out$climate_corr) == 1)
# adjusted_growth column present
stopifnot("adjusted_growth" %in% names(out$summary))
message("test_analysis: OK")
