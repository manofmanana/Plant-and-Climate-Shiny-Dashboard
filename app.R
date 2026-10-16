###########################################################
# Maquerina Mundo — Plants Meet Climate
# Author: Alejandro (Alex) Ines
# A solarpunk Shiny dashboard relating where houseplant species are observed
# (GBIF) to the real weather around each observation (Open-Meteo).
###########################################################

library(shiny)
library(bslib)
library(plotly)
library(leaflet)
library(DT)

# Helpers live in R/. Shiny also auto-loads that folder; sourcing explicitly
# keeps `Rscript app.R`, tests and deployments behaving the same way.
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

data <- load_data()
plants <- data$plants
meta <- data$meta

species_counts <- sort(table(plants$species), decreasing = TRUE)
species_choices <- c(
    "All species" = "All",
    stats::setNames(
        names(species_counts),
        paste0(species_profile(names(species_counts))$common_name, " — ", names(species_counts), " (", species_counts, ")")
    )
)
species_choices <- sub("^NA — ", "", species_choices)

humidity_range <- c(floor(min(plants$humidity, na.rm = TRUE) / 5) * 5, ceiling(max(plants$humidity, na.rm = TRUE) / 5) * 5)

plant_choices <- c(
    list("Overview" = c("All climate sites (average)" = "All")),
    lapply(split(plants, plants$common_name), function(df) {
        df <- df[order(df$obs_date), ]
        stats::setNames(df$occurrence_id, df$label)
    })
)

###########################################################
# THEME — Solarpunk Fusion
###########################################################
solarpunk_theme <- bs_theme(
    version = 5,
    bg = "#14221D",
    fg = "#E9F2E2",
    primary = "#E3C567",
    secondary = "#6BBF8F",
    success = "#A6D49F",
    info = "#88C9BF",
    dark = "#243E36",
    base_font = font_google("Outfit"),
    heading_font = font_google("Poppins")
)

stat_box <- function(title, value, icon, theme = "primary") {
    value_box(
        title = title, value = value, showcase = bsicons::bs_icon(icon), showcase_layout = "left center",
        theme = value_box_theme(bg = "rgba(255,255,255,0.05)", fg = "#E9F2E2"),
        class = "mm-stat"
    )
}

###########################################################
# UI
###########################################################
ui <- page_navbar(
    id = "main_nav",
    title = tags$span(class = "mm-brand", "☀️ Maquerina Mundo"),
    theme = solarpunk_theme,
    window_title = "Maquerina Mundo — Solarpunk Dashboard",
    fillable = FALSE,
    header = tags$head(
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
        tags$meta(name = "description", content = "A solarpunk dashboard relating houseplant observations to the real climate around them."),
        tags$link(rel = "stylesheet", href = "style.css"),
        tags$link(rel = "icon", type = "image/webp", href = "favicon.webp"),
        tags$script(src = "expand.js")
    ),

    # HOME -----------------------------------------------------------------
    nav_panel(
        title = "🏡 Home", value = "home",
        div(
            class = "mm-page-wrapper",
            div(
                class = "mm-page-content",
                div(
                    class = "mm-hero",
                    h1("Maquerina Mundo — Nature, Light & Data in Harmony"),
                    p(class = "mm-hero-lead", "Welcome to a solarpunk world where technology and ecology grow together. Explore where popular houseplants are found around the world and the real weather they were growing in."),
                    div(class = "mm-hero-quote", tags$p(
                        class = "mm-hero-quote-text", '"A tree falls the way it leans. Be careful which way you lean."',
                        tags$span(class = "mm-hero-quote-author", "~ The Lorax")
                    ))
                ),
                layout_columns(
                    class = "mm-stats-row",
                    col_widths = breakpoints(sm = 6, lg = 3),
                    stat_box("Plant observations", format(meta$n_plants, big.mark = ","), "flower1"),
                    stat_box("Species", meta$n_species, "tree"),
                    stat_box("Countries", meta$n_countries, "globe-americas"),
                    stat_box("Days of climate data", format(nrow(data$air), big.mark = ","), "sun")
                ),
                layout_columns(
                    class = "mm-feature-row",
                    col_widths = breakpoints(sm = 12, md = 4),
                    div(
                        class = "mm-card mm-framed mm-feature mm-feature-nasa mm-bg-nasa",
                        h4("NASA Climate Tracker"),
                        p("Follow real-time climate patterns, renewable energy insights, and sustainability progress around the world."),
                        tags$a(href = "https://science.nasa.gov/climate-change/", target = "_blank", rel = "noopener", class = "mm-btn", "Visit NASA Climate")
                    ),
                    div(
                        class = "mm-card mm-framed mm-feature mm-feature-solarpunk mm-bg-solarpunk",
                        h4("Solarpunk Literature & Ideas"),
                        p("Read stories, manifestos, and resources on building brighter ecological futures."),
                        tags$a(href = "https://iandennismiller.github.io/solarpunk/", target = "_blank", rel = "noopener", class = "mm-btn", "Solarpunk Resources")
                    ),
                    div(
                        class = "mm-card mm-framed mm-feature mm-feature-news mm-bg-climate2",
                        h4("Positive Climate News"),
                        p("Stay updated with hopeful, solution-oriented stories about climate progress."),
                        tags$a(href = "https://www.dailyclimate.org/good-news/", target = "_blank", rel = "noopener", class = "mm-btn", "Good News")
                    )
                )
            ),
            site_footer()
        )
    ),

    # PLANT GROWTH DASHBOARD -------------------------------------------------
    nav_panel(
        title = "🌱 Plant Growth Dashboard", value = "plants",
        div(
            class = "mm-page-wrapper page-bg-plantdash",
            div(
                class = "mm-page-content",
                layout_sidebar(
                    fillable = FALSE,
                    sidebar = sidebar(
                        width = 300,
                        open = list(desktop = "open", mobile = "closed"),
                        div(
                            class = "mm-card mm-framed mm-no-expand",
                            h4("Filter", class = "mm-card-title"),
                            selectInput("species", "Species", choices = species_choices, selected = "All"),
                            sliderInput("humidity", "Minimum 30-day humidity (%)",
                                min = humidity_range[1], max = humidity_range[2], value = humidity_range[1], step = 5
                            ),
                            uiOutput("filter_summary")
                        ),
                        div(
                            class = "mm-card mm-framed mm-no-expand mm-model-note",
                            h4("About the growth index", class = "mm-card-title"),
                            p(
                                "GBIF records where a plant was seen, not how fast it grew. The ",
                                strong("growth index"), " (0–100) is modeled: it scores how well the real temperature, humidity and sunlight in the 30 days before each observation matched that species' ideal care range."
                            )
                        )
                    ),
                    layout_columns(
                        col_widths = breakpoints(sm = 6, lg = 3),
                        uiOutput("stat_observations"), uiOutput("stat_median"),
                        uiOutput("stat_thriving"), uiOutput("stat_driver")
                    ),
                    layout_columns(
                        col_widths = breakpoints(sm = 12, lg = 4),
                        mm_card(plotlyOutput("growth_plot", height = "320px")),
                        mm_card(plotlyOutput("humidity_growth", height = "320px")),
                        mm_card(plotlyOutput("cor_plot", height = "320px"))
                    ),
                    layout_columns(
                        col_widths = breakpoints(sm = 12, lg = c(7, 5)),
                        mm_card(leafletOutput("plant_map", height = 400)),
                        mm_card(plotlyOutput("growth_trend", height = "400px"))
                    ),
                    layout_columns(
                        col_widths = 12,
                        mm_card(plotlyOutput("species_counts", height = "300px"))
                    )
                )
            ),
            site_footer()
        )
    ),

    # CLIMATE EXPLORER --------------------------------------------------------
    nav_panel(
        title = "☀️ Climate Explorer", value = "climate",
        div(
            class = "mm-page-wrapper page-bg-climateexplorer",
            div(
                class = "mm-page-content",
                layout_sidebar(
                    fillable = FALSE,
                    sidebar = sidebar(
                        width = 320,
                        open = list(desktop = "open", mobile = "closed"),
                        div(
                            class = "mm-card mm-framed mm-no-expand",
                            h4("Select a plant", class = "mm-card-title"),
                            selectizeInput("location_selector", NULL, choices = plant_choices, selected = "All"),
                            p("Pick one observation to see the weather it grew in, or keep the overview of all climate sites.", class = "direction-text"),
                            uiOutput("plant_facts")
                        )
                    ),
                    layout_columns(
                        col_widths = breakpoints(sm = 12, lg = 4),
                        mm_card(plotlyOutput("climate_plot", height = "320px")),
                        mm_card(plotlyOutput("monthly_precip", height = "320px")),
                        mm_card(plotlyOutput("temp_distribution", height = "320px"))
                    ),
                    layout_columns(
                        col_widths = breakpoints(sm = 12, lg = 6),
                        mm_card(plotlyOutput("climate_point_ts", height = "380px")),
                        mm_card(plotlyOutput("growth_ts", height = "380px"))
                    )
                )
            ),
            site_footer()
        )
    ),

    # DATA TABLE ------------------------------------------------------------
    nav_panel(
        title = "📊 Data Table", value = "table",
        div(
            class = "mm-page-wrapper page-bg-datatable",
            div(
                class = "mm-page-content",
                mm_card(
                    expand = FALSE,
                    h4("Plant observations with climate and growth index", class = "mm-card-title"),
                    p(class = "direction-text", "Search, sort, filter each column, and download as CSV or Excel."),
                    DTOutput("data_table")
                )
            ),
            site_footer()
        )
    ),
    nav_spacer(),
    nav_item(tags$a(href = "https://github.com/manofmanana/Plant-and-Climate-Shiny-Dashboard", target = "_blank", rel = "noopener", bsicons::bs_icon("github"), "Source"))
)

###########################################################
# SERVER
###########################################################
server <- function(input, output, session) {
    filtered <- reactive({
        filter_plants(plants, input$species, input$humidity)
    })
    correlations <- reactive(analyze_relationships(filtered()))

    # --- Plant dashboard ---------------------------------------------------
    output$filter_summary <- renderUI({
        n <- nrow(filtered())
        p(class = "direction-text", sprintf("Showing %d of %d observations.", n, nrow(plants)))
    })

    output$stat_observations <- renderUI(stat_box("Observations", nrow(filtered()), "flower1"))
    output$stat_median <- renderUI({
        val <- if (nrow(filtered()) > 0) round(stats::median(filtered()$growth_index, na.rm = TRUE)) else "–"
        stat_box("Median growth index", val, "graph-up-arrow")
    })
    output$stat_thriving <- renderUI({
        val <- if (nrow(filtered()) > 0) paste0(round(100 * mean(filtered()$category == "Thriving")), "%") else "–"
        stat_box("Thriving", val, "brightness-high")
    })
    output$stat_driver <- renderUI({
        cors <- correlations()
        cors <- cors[!is.na(cors$correlation), ]
        val <- if (nrow(cors) > 0) cors$variable[which.max(abs(cors$correlation))] else "–"
        stat_box("Strongest driver", val, "thermometer-sun")
    })

    output$growth_plot <- renderPlotly(plot_growth_distribution(filtered()))
    output$humidity_growth <- renderPlotly(plot_humidity_vs_growth(filtered()))
    output$cor_plot <- renderPlotly(plot_correlations(correlations()))
    output$plant_map <- renderLeaflet(map_plants(filtered()))
    output$growth_trend <- renderPlotly(plot_growth_trend(filtered()))
    output$species_counts <- renderPlotly(plot_species_counts(filter_plants(plants, "All", input$humidity)))

    # --- Climate explorer --------------------------------------------------
    selected_plant <- reactive({
        id <- input$location_selector
        if (is.null(id) || id == "All") {
            return(NULL)
        }
        plants[plants$occurrence_id == id, , drop = FALSE]
    })
    selected_window <- reactive({
        p <- selected_plant()
        if (is.null(p)) {
            return(NULL)
        }
        data$plant_climate[data$plant_climate$occurrence_id == p$occurrence_id, , drop = FALSE]
    })

    output$plant_facts <- renderUI({
        p <- selected_plant()
        if (is.null(p)) {
            return(p(class = "direction-text", sprintf(
                "Overview: %d climate sites, %s.", meta$n_sites, format_date_range(meta$climate_dates)
            )))
        }
        prof <- species_profile(p$species)
        tags$dl(
            class = "mm-facts",
            tags$dt("Species"), tags$dd(em(p$species)),
            tags$dt("Observed"), tags$dd(sprintf("%s · %s", format(p$obs_date, "%d %b %Y"), p$country)),
            tags$dt("Growth index"), tags$dd(strong(round(p$growth_index)), sprintf(" (%s)", p$category)),
            tags$dt("30-day mean temp"), tags$dd(sprintf("%.1f °C (ideal %d–%d)", p$temperature, prof$temp_min, prof$temp_max)),
            tags$dt("30-day humidity"), tags$dd(sprintf("%.0f%% (ideal %d–%d)", p$humidity, prof$humidity_min, prof$humidity_max)),
            tags$dt("Rain in window"), tags$dd(sprintf("%.0f mm", p$precipitation))
        )
    })

    output$climate_plot <- renderPlotly({
        p <- selected_plant()
        if (is.null(p)) plot_climate_trend(data$air) else plot_plant_temperature(selected_window(), p)
    })
    output$monthly_precip <- renderPlotly({
        p <- selected_plant()
        if (is.null(p)) plot_monthly_precip(data$air) else plot_plant_moisture(selected_window(), p)
    })
    output$temp_distribution <- renderPlotly({
        p <- selected_plant()
        if (is.null(p)) {
            plot_temp_distribution(data$air$Temperature)
        } else {
            same <- plants[plants$species == p$species, ]
            plot_temp_distribution(same$temperature, p$temperature,
                title = paste("30-day temperatures across", p$common_name, "observations")
            )
        }
    })
    output$climate_point_ts <- renderPlotly({
        p <- selected_plant()
        if (is.null(p)) {
            plot_temp_timeseries(data$air)
        } else {
            plot_growth_vs_temperature(plants[plants$species == p$species, ], p$occurrence_id)
        }
    })
    output$growth_ts <- renderPlotly({
        p <- selected_plant()
        if (is.null(p)) plot_growth_histogram(plants) else plot_growth_histogram(plants[plants$species == p$species, ])
    })

    # --- Data table --------------------------------------------------------
    output$data_table <- renderDT({
        tbl <- plants |>
            dplyr::transmute(
                `Common name` = common_name, Species = species, Country = country, Observed = obs_date,
                Latitude = round(latitude, 3), Longitude = round(longitude, 3),
                `Temp (°C)` = round(temperature, 1), `Humidity (%)` = round(humidity),
                `Rain (mm, 30d)` = round(precipitation), `Sun (MJ/m²/day)` = round(radiation, 1),
                `Growth index` = round(growth_index), Category = category, `GBIF record` = occurrence_id
            )
        datatable(tbl,
            extensions = "Buttons", filter = "top", rownames = FALSE,
            class = "cell-border stripe hover compact",
            options = list(
                pageLength = 15, scrollX = TRUE, dom = "Bfrtip",
                buttons = list(
                    list(extend = "csv", filename = "maquerina_mundo_plants"),
                    list(extend = "excel", filename = "maquerina_mundo_plants")
                )
            )
        )
    })
}

shinyApp(ui, server)
