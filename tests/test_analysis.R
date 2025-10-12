# tests/test_analysis.R
# Load package code for testing
source("R/data_load.R")
source("R/helpers.R")
source("R/analysis.R")
source("R/visualize.R")

data <- load_data()
out <- analyze_relationships(data$air, data$plants)
# Check structure
stopifnot(is.list(out))
stopifnot("summary" %in% names(out))
stopifnot("ozone_temp_cor" %in% names(out))
stopifnot(is.numeric(out$ozone_temp_cor))
# adjusted_growth column present
stopifnot("adjusted_growth" %in% names(out$summary))
message("test_analysis: OK")
