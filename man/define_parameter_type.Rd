% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parameter.R
\name{define_parameter_type}
\alias{define_parameter_type}
\title{Define Parameter Type}
\usage{
define_parameter_type(name, regexp, transformer)
}
\arguments{
\item{name}{The name of the parameter.}

\item{regexp}{A regular expression that the parameter will match on.}

\item{transformer}{A function that will transform the parameter from a string to the desired type.
Must be a funcion that requires only a single argument.}
}
\description{
Add a new parameter to the list of parameters that can be used in step definitions.
}
\examples{
define_parameter_type("color", "red|blue|green", as.character)
define_parameter_type("sci_number", "[+-]?\\\\d*\\\\.?\\\\d+(e[+-]?\\\\d+)?", as.numeric)

}