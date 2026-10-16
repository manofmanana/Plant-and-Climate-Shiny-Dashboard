is_widget <- function(x) inherits(x, "htmlwidget")
plant <- d$plants[1, ]
window <- d$plant_climate[d$plant_climate$occurrence_id == plant$occurrence_id, ]

test_that("every chart builds with real data", {
    built <- list(
        plot_growth_distribution(d$plants), plot_species_counts(d$plants),
        plot_humidity_vs_growth(d$plants), plot_growth_trend(d$plants),
        plot_correlations(analyze_relationships(d$plants)), map_plants(d$plants),
        plot_climate_trend(d$air), plot_monthly_precip(d$air),
        plot_temp_distribution(d$air$Temperature), plot_temp_timeseries(d$air),
        plot_growth_histogram(d$plants), plot_plant_temperature(window, plant),
        plot_plant_moisture(window, plant),
        plot_growth_vs_temperature(d$plants, plant$occurrence_id),
        plot_temp_distribution(d$plants$temperature, plant$temperature)
    )
    expect_true(all(vapply(built, is_widget, logical(1))))
    # Force plotly to evaluate each figure so data errors surface here.
    for (w in built) if (inherits(w, "plotly")) expect_no_error(plotly::plotly_build(w))
})

test_that("charts degrade gracefully with no data", {
    empty <- d$plants[0, ]
    for (f in list(plot_growth_distribution, plot_species_counts, plot_humidity_vs_growth,
                   plot_growth_trend, plot_growth_histogram, map_plants)) {
        expect_true(is_widget(f(empty)))
    }
    expect_true(is_widget(plot_plant_temperature(window[0, ], plant)))
})

test_that("map popups escape HTML", {
    evil <- d$plants[1, ]
    evil$common_name <- "<script>alert(1)</script>"
    m <- map_plants(evil)
    popup <- m$x$calls[[2]]$args[[7]]
    expect_false(any(grepl("<script>", popup, fixed = TRUE)))
})
