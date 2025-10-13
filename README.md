# Maquerina Mundo

Modeling the harmony between nature, climate, and machines.

Author: Alejandro (Alex) Ines

## Live demo https://www.youtube.com/watch?v=I6cCEDqALec

Try the live deployed app here:

[Maquerina Mundo — live demo](https://manofmanana.shinyapps.io/maquerinamundo/)

## Overview

Maquerina Mundo is a solarpunk-inspired Shiny dashboard that explores the relationships between climate variables and indoor plant health. The app combines climate data visualizations, spatial mapping of plant locations, and interactive controls to help users explore how temperature, humidity, solar radiation, and other factors correlate with plant growth.

The project was inspired by a personal love for plants, hiking, and the outdoors, and a desire to make climate data feel accessible and hopeful. It blends aesthetic design and data-first storytelling to encourage sustainable thinking.

## Features

- Interactive climate trend plots and correlation heatmaps
- Filterable plant growth dashboard with map and distribution plots
- Data table browsing and export
- Curated hero presentation with editorial quote

## Local setup

Prerequisites: R >= 4.0

1. From the repository root, install packages listed in `requirements.txt` (run inside R):

```r
pkgs <- readLines('requirements.txt')
install.packages(pkgs)
```

1. Run the Shiny app locally:

```bash
R -e "shiny::runApp('.', launch.browser = TRUE)"
```

## Deploy to shinyapps.io (rsconnect)

If you want to deploy the app to shinyapps.io, follow these steps locally. Do NOT commit your rsconnect token/secret to source control.

1. Install `rsconnect`:

```r
install.packages('rsconnect')
```

1. Authorize your account (replace with your token/secret):

```r
rsconnect::setAccountInfo(name='YOUR_ACCOUNT_NAME',
  token='YOUR_TOKEN',
  secret='YOUR_SECRET')
```

1. Deploy from the project root:

```r
library(rsconnect)
rsconnect::deployApp(appDir = '.', account = 'YOUR_ACCOUNT_NAME')
```

Or from the command line:

```bash
Rscript -e "rsconnect::deployApp(appDir='.', account='YOUR_ACCOUNT_NAME')"
```

## Files of interest

- `app.R` — main Shiny UI and server logic
- `www/` — static assets (images, CSS, JS)
- `R/` — helper scripts for data loading, analysis, and visualization
- `data/` — CSV datasets used by the app

## Dependencies

See `requirements.txt` for R package dependencies used by the project.

## License & Credit

Author: Alejandro Ines. Please credit the author when reusing or adapting this work.

## Contact

Open an issue or contact the author directly for collaboration.

