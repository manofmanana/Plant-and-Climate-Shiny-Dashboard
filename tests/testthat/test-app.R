# End-to-end: boot the real app in headless Chrome and drive it.
test_that("app starts and every tab renders", {
    skip_on_cran()
    skip_if_not_installed("shinytest2")
    skip_if(is.null(chromote::find_chrome()), "Chrome not available")

    app <- shinytest2::AppDriver$new(project_root, name = "smoke", load_timeout = 60000, timeout = 30000, height = 1000, width = 1400)
    on.exit(app$stop(), add = TRUE)

    # Plant dashboard reacts to filters.
    app$set_inputs(main_nav = "plants")
    app$wait_for_idle()
    expect_match(app$get_text("#filter_summary"), sprintf("Showing %d of", nrow(d$plants)))
    app$set_inputs(species = "Monstera deliciosa")
    app$wait_for_idle()
    expect_match(app$get_text("#filter_summary"), "Showing \\d+ of")
    app$set_inputs(humidity = 80)
    app$wait_for_idle()

    # Climate explorer switches to a single plant.
    app$set_inputs(main_nav = "climate")
    app$wait_for_idle()
    expect_match(app$get_text("#plant_facts"), "climate sites")
    plant_id <- d$plants$occurrence_id[1]
    app$set_inputs(location_selector = plant_id)
    app$wait_for_idle()
    expect_match(app$get_text("#plant_facts"), "Growth index")

    app$set_inputs(main_nav = "table")
    app$wait_for_idle()
    expect_true(app$get_js("document.querySelectorAll('#data_table tbody tr').length") > 0)

    # No server-side errors were rendered anywhere.
    errors <- app$get_js("document.querySelectorAll('.shiny-output-error:not(.shiny-output-error-validation)').length")
    expect_equal(errors, 0)
})
