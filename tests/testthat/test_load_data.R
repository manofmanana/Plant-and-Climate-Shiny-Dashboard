source(file.path("..", "R", "data_load.R"))
source(file.path("..", "R", "helpers.R"))
source(file.path("..", "R", "analysis.R"))
source(file.path("..", "R", "visualize.R"))

res <- load_data()
# Basic smoke tests
stopifnot(is.list(res))
stopifnot(!is.null(res$air))
stopifnot(!is.null(res$plants))
stopifnot(nrow(res$plants) > 0) # expect at least one plant row (real data may vary)
message("test_load_data: OK")
