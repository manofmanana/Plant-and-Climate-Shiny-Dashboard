library(testthat)

source(file.path("..", "R", "data_load.R"))
source(file.path("..", "R", "helpers.R"))
source(file.path("..", "R", "analysis.R"))
source(file.path("..", "R", "visualize.R"))

 d <- load_data()

 test_that("visualize helpers return htmlwidgets/plotly", {
     skip_if(is.null(d$plants) || nrow(d$plants) == 0, "no plant data")
     skip_if(is.null(d$air) || nrow(d$air) == 0, "no climate data")

     p1 <- plot_species_counts(d$plants)
     expect_true(inherits(p1, "htmlwidget") || inherits(p1, "plotly"))

     p2 <- plot_humidity_vs_growth(d$plants)
     expect_true(inherits(p2, "htmlwidget") || inherits(p2, "plotly"))

     p3 <- plot_growth_trend_agg(d$plants)
     expect_true(inherits(p3, "htmlwidget") || inherits(p3, "plotly"))

     p4 <- plot_climate_trend(d$air)
     expect_true(inherits(p4, "htmlwidget") || inherits(p4, "plotly"))
 })
