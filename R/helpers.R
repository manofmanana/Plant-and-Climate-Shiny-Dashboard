# R/helpers.R
# Small utilities shared by the app and plots.

scale01 <- function(x) {
    rng <- range(x, na.rm = TRUE)
    if (diff(rng) == 0) {
        return(ifelse(is.na(x), NA_real_, 0))
    }
    (x - rng[1]) / diff(rng)
}

format_num <- function(x, digits = 2) {
    format(round(x, digits), nsmall = digits, big.mark = ",")
}

format_date_range <- function(rng) {
    paste(format(rng[1], "%b %Y"), "–", format(rng[2], "%b %Y"))
}

#' Footer shown at the bottom of every page.
site_footer <- function() {
    shiny::tags$footer(
        class = "mm-page-footer site-footer",
        shiny::tags$span(class = "site-footer-left", shiny::HTML(paste0("&copy; Alejandro Ines ", format(Sys.Date(), "%Y")))),
        shiny::tags$span(
            class = "site-footer-right",
            "Data: ",
            shiny::tags$a(href = "https://www.gbif.org/", target = "_blank", rel = "noopener", "GBIF"),
            " & ",
            shiny::tags$a(href = "https://open-meteo.com/", target = "_blank", rel = "noopener", "Open-Meteo"),
            " · Made with Shiny for R"
        )
    )
}

#' Card wrapper used for every chart; `expand = TRUE` adds the expand button.
mm_card <- function(..., title = NULL, expand = TRUE, class = NULL) {
    shiny::div(
        class = paste("mm-card mm-framed", if (expand) "mm-expandable" else "mm-no-expand", class),
        if (!is.null(title)) shiny::h4(title, class = "mm-card-title"),
        ...
    )
}
