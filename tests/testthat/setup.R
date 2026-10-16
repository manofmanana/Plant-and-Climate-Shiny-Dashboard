# Source the app's helpers and load the real data once for all tests.
project_root <- normalizePath(testthat::test_path("..", ".."))
for (f in list.files(file.path(project_root, "R"), pattern = "\\.R$", full.names = TRUE)) source(f)
d <- load_data(file.path(project_root, "data"))
