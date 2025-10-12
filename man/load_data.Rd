\name{load_data}
\alias{load_data}
\title{Load example climate and plant data}
\description{
Loads and prepares example climate (built-in `airquality`) and simulated plant
observation data. This convenience function is intended for demos and examples
within the Maquerina Mundo project.
}
\usage{
load_data()
}
\arguments{}
\value{
A list with two elements:
\item{air}{A data frame based on the built-in \code{airquality} dataset (cleaned)}
\item{plants}{A tibble of simulated plant observations used for examples and plots}
}
\examples{
## Basic usage
res <- load_data()
str(res)
}
