test_that("filter_plants applies species and humidity filters", {
    all <- filter_plants(d$plants, "All", 0)
    expect_equal(nrow(all), nrow(d$plants))
    mon <- filter_plants(d$plants, "Monstera deliciosa", 0)
    expect_true(all(mon$species == "Monstera deliciosa"))
    humid <- filter_plants(d$plants, "All", 80)
    expect_true(all(humid$humidity >= 80))
})

test_that("analyze_relationships returns one correlation per driver", {
    cors <- analyze_relationships(d$plants)
    expect_equal(cors$variable, c("Temperature", "Humidity", "Radiation", "Precipitation"))
    expect_true(all(abs(cors$correlation) <= 1, na.rm = TRUE))
    expect_true(all(is.na(analyze_relationships(d$plants[1:2, ])$correlation)))
})

test_that("describe_correlation labels strength and direction", {
    expect_equal(describe_correlation(0.72), "strong positive (r = 0.72)")
    expect_equal(describe_correlation(-0.4), "moderate negative (r = -0.40)")
    expect_equal(describe_correlation(NA), "not enough data")
})
