test_that("range_score is 1 inside the range and falls off linearly", {
    expect_equal(range_score(c(20, 25, 29), 20, 29, 10), c(1, 1, 1))
    expect_equal(range_score(15, 20, 29, 10), 0.5)
    expect_equal(range_score(c(0, 50), 20, 29, 10), c(0, 0))
})

test_that("growth_index rewards ideal conditions", {
    ideal <- growth_index("Monstera deliciosa", 24, 70, 20)
    cold <- growth_index("Monstera deliciosa", 12, 70, 20)
    dry <- growth_index("Monstera deliciosa", 24, 30, 20)
    expect_equal(ideal, 100)
    expect_lt(cold, ideal)
    expect_lt(dry, ideal)
    expect_true(all(d$plants$growth_index >= 0 & d$plants$growth_index <= 100))
})

test_that("unknown species fall back to a generic profile", {
    prof <- species_profile(c("Monstera deliciosa", "Plantus imaginarius"))
    expect_equal(prof$temp_min, c(20, 18))
    expect_false(is.na(growth_index("Plantus imaginarius", 22, 55, 15)))
})
