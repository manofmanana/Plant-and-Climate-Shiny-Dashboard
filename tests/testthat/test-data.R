test_that("load_data returns every dataset", {
    expect_named(d, c("plants", "plant_climate", "sites", "air", "meta"))
    expect_gt(nrow(d$plants), 100)
    expect_gt(nrow(d$air), 365)
    expect_equal(d$meta$n_plants, nrow(d$plants))
})

test_that("every plant has climate from its own place and time", {
    p <- d$plants
    expect_false(anyNA(p$temperature))
    expect_false(anyNA(p$humidity))
    expect_true(all(p$humidity >= 0 & p$humidity <= 100))
    # The 30-day windows end on the observation date (the old data never overlapped).
    last_day <- tapply(d$plant_climate$date, d$plant_climate$occurrence_id, max)
    expect_equal(as.Date(as.vector(last_day[p$occurrence_id])), p$obs_date)
})

test_that("load_data is deterministic and read-only", {
    before <- tools::md5sum(list.files(file.path(project_root, "data"), full.names = TRUE))
    again <- load_data(file.path(project_root, "data"))
    after <- tools::md5sum(list.files(file.path(project_root, "data"), full.names = TRUE))
    expect_identical(again$plants$growth_index, d$plants$growth_index)
    expect_identical(before, after)
})

test_that("species names are cleaned to binomials", {
    expect_equal(
        clean_species(c("Monstera deliciosa Liebm.", "ZZ plant", "ZZ plant (Zamioculcas zamiifolia)", "Epipremnum aureum (Linden & André) G.S.Bunting")),
        c("Monstera deliciosa", "Zamioculcas zamiifolia", "Zamioculcas zamiifolia", "Epipremnum aureum")
    )
    expect_true(all(d$plants$species %in% species_profiles$species))
})

test_that("site average uses mean precipitation, not a cross-continent sum", {
    day <- d$sites[d$sites$date == d$sites$date[1], ]
    expect_equal(d$air$Precipitation[d$air$date == d$sites$date[1]], mean(day$Precipitation, na.rm = TRUE))
})
