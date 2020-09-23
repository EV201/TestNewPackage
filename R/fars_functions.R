#' @title
#' fars_read()
#'
#' @description
#'  This function checks if the file exists, stops with a message if it does not or loads the file if it does.
#'
#' @param filename character. The file name of the file to be loaded
#'
#' @return returns a tibble with the data
#'
#' @examples
#' \dontrun{
#'     fars_read(filename)
#'     fars_read(filename = "file name")
#'     }

fars_read <- function(filename) {
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        tibble::as_tibble(data)
}

#' @title
#' make_filename()
#'
#' @description
#'  This function takes the year and makes it an integer, then uses it to construct the file name
#'
#' @param year integer or character. The file name of the file to be loaded
#'
#' @return character. Returns a file name
#'
#' @examples
#' \dontrun{
#'     make_filename(2013)
#'     make_filename("2013")
#'     }

make_filename <- function(year) {
        year <- as.integer(year)
        system.file("extdata", sprintf("accident_%d.csv.bz2", year), package = "TestNewPackage")
#        sprintf("accident_%d.csv.bz2", year)
}

#' @title
#' fars_read()
#'
#' @description
#' This function reads in the file for each year and selects MONTH and year and returns these as a list of tibbles
#'
#' @param years a vector of integer or character
#'
#' @return NULL if there is an error
#' @return a list with of tibbles each with 2 colums: MONTH and year
#'
#' @note conditions that may result in an error: input of an invalid year returns a warning
#'
#' @importFrom magrittr %>%
#'
#' @examples
#' \dontrun{
#'     fars_read_years(c(2013, 2014))
#'     fars_read_years(c("2013", "2014"))
#'     }

fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>%
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}


#' @title
#' fars_summarize_years()
#'
#' @description
#' This function reads the data for each year and summarizes it into month and year columns.
#'
#' @param years vector of int or character
#'
#' @return tbl_df with MONTH in the first column and # of accidents for each month in each year in the following columns.
#'
#' @importFrom magrittr %>%
#'
#' @examples
#' \dontrun{
#'     fars_summarize(c(2013, 2014))
#'     fars_summarize(c("2013", "2014"))
#'     }
#'
#' @export

fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>%
                dplyr::group_by(year, MONTH) %>%
                dplyr::summarize(n = dplyr::n()) %>%
                tidyr::spread(year, n)
}

#' @title
#' fars_map_state()
#'
#' @description
#' This function plots a state map of the accidents in a certain year
#'
#' @param state.num integer or character. State by number
#' @param year integer or character
#'
#' @return The result of this function is a graph of a state map with accidents plotted in. It also returns 0 for testing
#'
#' @note conditions that may result in an error: This function does not seem to work for state.num = 2: all regions out of bounds error
#' invalid state number generates an invalid state number message (for example state.num = 3)
#' no accidents generates a no accidents to plot message
#'

#'
#' @examples
#' \dontrun{
#'     fars_map_state(1, 2013)
#'     fars_map_state("1", "2013")
#'     }
#'
#' @export

fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)

        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
        return(0)
}
