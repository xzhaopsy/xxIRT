% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/module3_ata.R
\name{ata}
\alias{ata}
\alias{ata_constraint}
\alias{ata_item_enemy}
\alias{ata_item_fixedvalue}
\alias{ata_item_maxselect}
\alias{ata_obj_absolute}
\alias{ata_obj_relative}
\alias{ata_solve}
\alias{ata_solve_glpk}
\alias{ata_solve_lpsolve}
\alias{plot.ata}
\alias{print.ata}
\title{Automated Test Assembly (ATA)}
\usage{
ata(pool, nforms = 1, len = NULL, maxselect = NULL)

\method{print}{ata}(x, ...)

\method{plot}{ata}(x, ...)

ata_obj_relative(x, coef, mode = c("max", "min"), negative = FALSE,
  flatten = NULL, forms = NULL, collapse = FALSE)

ata_obj_absolute(x, coef, target, forms = NULL, collapse = FALSE)

ata_constraint(x, coef, min = NA, max = NA, level = NULL, forms = NULL,
  collapse = FALSE)

ata_item_maxselect(x, maxselect, items = NULL)

ata_item_enemy(x, items)

ata_item_fixedvalue(x, items, min = NA, max = NA, forms = NULL,
  collapse = FALSE)

ata_solve(x, solver = c("lpsolve", "glpk"), as.list = TRUE, timeout = 10,
  mip_gap = 0.1, verbose = c("none", "normal", "full"), ...)

ata_solve_glpk(x, ...)

ata_solve_lpsolve(x, ...)
}
\arguments{
\item{pool}{item pool}

\item{nforms}{the number of forms}

\item{len}{the test length}

\item{maxselect}{the maximum selection of each item}

\item{x}{the ata object}

\item{...}{further arguments}

\item{coef}{the coefficients of the objective function or the constraint}

\item{mode}{the optimzation mode: 'max' for maximization and 'min' for minimization}

\item{negative}{\code{TRUE} when the expected value of the objective function is negative}

\item{flatten}{the flatten parameter to make the objective function flat}

\item{forms}{the indcies of forms where objectives are added. \code{NULL} for all forms}

\item{collapse}{\code{TRUE} to collapse all forms into one objective function}

\item{target}{the target of the objective function}

\item{min}{the lower bound of the constraint}

\item{max}{the upper bound of the constraint}

\item{level}{the level value for categorical variable}

\item{items}{a vector of item indices}

\item{solver}{\code{"glpk"} for GLPK and \code{"lpsolve"} for lpSolve}

\item{as.list}{\code{TRUE} to return resutls in a list; otherwise, data frame}

\item{timeout}{the time limit in seconds}

\item{mip_gap}{the mip gap paraemter}

\item{verbose}{the message parameter}
}
\description{
\code{ata} creates an \code{ata} object

\code{ata_obj_relative} adds relative (maximize/minimize) objectives to LP

\code{ata_obj_absolute} adds absolute objectives to LP

\code{ata_constraint} adds a constraint to LP

\code{ata_item_maxselect} sets the maximum selection for items

\code{ata_item_enemy} adds enemy item relationship to LP

\code{ata_item_fixedvalue} sets a fixed value range for items

\code{ata_solve} solves the LP

\code{ata_solve_glpk} solves the LP using  GLPK

\code{ata_solve_lpsolve} solves the LP using LpSolve
}
\details{
The \code{ata} object stores LP information in \code{obj}, \code{mat}, \code{dir}, 
\code{rhs}, \code{types}, \code{bounds}, \code{max}. When the \code{ata_solve} is
called, this information will be converted to real LP object for the selected solver.
When the LP is solved successfully, two results will be added to the \code{ata} object:
(i) \code{result} is a matrix of binary selection results (items in rows and forms in columns)
and (ii) \code{items} is a list or data frame of selected items.\cr

To maximize the LP, it is to maximize y while subject to sum(x) - y >= 0 and <= F (flatten parameter).
To minimize teh LP, it is to minimize y while subject to sum(x) - y <= 0 and >= F.
By default, y is non-negative. When \code{negative=TRUE}, y is set to be negative. \cr 
When \code{coef} is a pool-size or form-size numeric vector, coefficients are used directly.
When \code{coef} is a variable name, variable values are used as coefficients.
When \code{coef} is a numeric vector unequal to pool size, information at those points are used as coefficients.\cr

\code{ata_obj_absolute} is to minimize y while subject to sum(x) + y >= T and sum(x) - y <= T. \cr

For \code{ata_constraint}, set \code{coef} to a variable name and \code{level} a level 
of that variable to add a categorical constraint. Set \code{coef} to a variable name and
leave \code{level} to default value (\code{NULL} or \code{NA}) to add a quantitative constraint. 
Set \code{coef} to a constant or a vector to add a constraint directly.\cr

In \code{ata_solve}, additional control parameters will be passed into solvers.
When passing control parameters to the GLPK solver, use the correct parameter name
(see \code{?glpkAPI::glpkConstants}).
}
\examples{
\dontrun{
library(dplyr)
# generate a 100-item pool
items <- irt_model("3pl")$gendata(1, 100)$items
items$id <- 1:nrow(items)
items$content <- sample(1:3, nrow(items), replace=TRUE)
items$time <- round(rlnorm(nrow(items), log(60), .2), 0)

## ex. 1: 6 forms, 10 items, maximize b parmaters
## solved by GLPK and LpSolve respectively
x <- ata(items, 6, len=10, maxselect=1)
x <- ata_obj_relative(x, "b", "max")
glpk <- ata_solve(x, solver="glpk")
glpk$optimum
sapply(glpk$items, function(x)
  c(mean=mean(x$b), sd=sd(x$b), min=min(x$b), max=max(x$b)))
lpsolve <- ata_solve(x, solver="lpsolve")
lpsolve$optimum
sapply(lpsolve$items, function(x)
  c(mean=mean(x$b), sd=sd(x$b), min=min(x$b), max=max(x$b)))

## ex. 2: 4 forms, 10 items, minimize b parmaeters
x <- ata(items, 3, len=10, maxselect=1)
x <- ata_obj_relative(x, "b", "min", negative=TRUE)
glpk <- ata_solve(x, solver="glpk", as.list=FALSE, timeout=5)
group_by(glpk$items, form) \%>\% 
  summarise(mean=mean(b), sd=sd(b), min=min(b), max=max(b))
lpsolve <- ata_solve(x, solver="lpsolve", as.list=FALSE, timeout=5)
group_by(lpsolve$items, form) \%>\% 
  summarise(mean=mean(b), sd=sd(b), min=min(b), max=max(b))
  
## ex. 3: 3 forms, 10 items, maximize information at -1 and 1
## content distribution: 3, 3, 4
## response time: avg. 55-65 seconds
x <- ata(items, 3, len=10, maxselect=1)
x <- ata_obj_relative(x, c(-1, 1), "max")
x <- ata_constraint(x, "content", min=3, max=3, level=1)
x <- ata_constraint(x, "content", min=3, max=3, level=2)
x <- ata_constraint(x, "content", min=4, max=4, level=3)
x <- ata_constraint(x, "time", min=55*10, max=65*10)
lpsolve <- ata_solve(x, solver="lpsolve")
lpsolve$optimum
plot(lpsolve)
sapply(lpsolve$items, function(x) 
  c(freq(x$content, 1:3)$freq, mean(x$time)))
  
## ex. 4: 2 forms, 10 items, mean(b) = 0, sd(b) = 1.0, content = (3, 3, 4)
x <- ata(items, 2, len=10, maxselect=1) \%>\%
     ata_obj_absolute(items$b, 0 * 10) \%>\%
     ata_obj_absolute((items$b - 0)^2, 1 * 10) \%>\%
     ata_constraint("content", min=3, max=3, level=1) \%>\%
     ata_constraint("content", min=3, max=3, level=2) \%>\%
     ata_constraint("content", min=4, max=4, level=3)
lpsolve <- ata_solve(x, "lpsolve", verbose="normal", timeout=5)
sapply(lpsolve$items, function(x) c(mean=mean(x$b), sd=sd(x$b)))

# ex. 5: 2 forms, 10 items, flat TIF over [-1, 1]
x <- ata(items, 2, len=10, maxselect=1) \%>\%
     ata_obj_relative(seq(-1, 1, .5), "max", flatten=0.05)
x <- ata_solve(x, "lpsolve")
plot(x)
}
}

