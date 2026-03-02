
## -----------------------------------------
## Log File
## -----------------------------------------

library(logr)
log_open("./01_create_ae_summary_table.log")


## -----------------------------------------
## Load the libraries 
## -----------------------------------------

library(tidyverse)
library(admiral)
library(gt)
library(gtsummary)
library(pharmaverseraw)
library(sdtm.oak)
options(width=550)


## -----------------------------------------
## Functions
## -----------------------------------------


#' Create AE Severity Stacked Bar Chart
#'
#' @param data A data frame containing AE data (e.g., ADAE)
#' @param figure_path Path of the figure to be saved - string
#'
#' @return A ggplot object
generate_ae_severity_barchart <- function(
    data_adae,
    data_adsl,
    figure_path
) {
    # Filter the data
    data_adae <- adae |>
    filter(
        TRTEMFL == "Y",
    )

    # Generate a hierarchical table
    tbl <- data_adae |>
        tbl_hierarchical(
            variables = c(AESOC, AETERM),
            by = TRT01A,
            id = USUBJID,
            denominator = data_adsl,
            overall_row = TRUE,
            label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
        ) |>
        sort_hierarchical(
            sort = list(
                AETERM = "descending",
                AESOC = "descending"
            )
        )

    sink(figure_path) # NB: only way I found to generate the html file - the gtsave function did not work using my envs/terminal
    print(tbl)
    sink() 

}


## -----------------------------------------
## Process
## -----------------------------------------


# load the data
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl

# generate the table
table_ae <- generate_ae_severity_barchart(
    data_adae = adae,
    data_adsl = adsl,
    figure_path = "./ae_table_treatment_emergent.html"
)

# close log file
log_close()