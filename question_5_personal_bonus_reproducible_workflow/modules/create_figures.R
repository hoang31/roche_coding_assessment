
## -----------------------------------------
## Log File
## -----------------------------------------

library(logr)
log_open(snakemake@log[[1]])

## -----------------------------------------
## Load the libraries 
## -----------------------------------------

library(tidyverse)
library(admiral)
library(gt)
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
    data,
    figure_path
) {

    # format the data
    data <- data %>%
        select(
            "ACTARM",
            "AESEV"
        )

    # generate the figure
    ae_severity_barchart <- ggplot(
        data = data,
        aes(
            x = ACTARM,
            fill = AESEV
        )
    ) +
        geom_bar(position = "stack", stat = "count") +
        labs(
            x = "Treatment Arm",
            y = "Count of AEs",
            title = "AE severity distribution by treatment",
            fill = "Severity/Intensity"
        )

    ggsave(
        ae_severity_barchart,
        filename = "ae_severity_distribution_by_treatment.png",
        width = 7,
        height = 6
    )

    return(ae_severity_barchart)
}


#' Create AE Frequency Dot Plot
#'
#' @param data A data frame containing AE data (e.g., ADAE)
#' @param n_top Number of top AEs to display (default is 10)

#' @return A frequency tibble, with:
#' - AETERM: AE term
#' - n_subjects: number of subjects
#' - ae_counting: number of AEs
#' - n_ae_total: total number of AEs
#' - ae_percentage: percentage of AEs
#' - ci_95_lower: lower bound of the 95% Clopper-Pearson CI
#' - ci_95_upper: upper bound of the 95% Clopper-Pearson CI
count_ae_freq <- function(
    data,
    n_top = 10
    ) {

    # counting the n_subjects, n_ae_total, and ae_percentage
    data <- data %>%
        select(
            "SUBJID",
            "AETERM"
        ) %>%
        distinct()  %>%
        add_count(
            AETERM,
            name = "ae_counting"
        )  %>%
        mutate(
            n_subjects = n_distinct(SUBJID),
            n_ae_total = sum(ae_counting),
            ae_percentage = ae_counting / n_subjects * 100
        ) %>%
        rowwise() %>%
        mutate(
            ci_95_lower = binom.test(ae_counting, n_subjects, conf.level = 0.95, alternative = "two.sided")$conf.int[1] * 100,
            ci_95_upper = binom.test(ae_counting, n_subjects, conf.level = 0.95, alternative = "two.sided")$conf.int[2] * 100
        )

    # format and order the data
    data <- data %>%
        select(
            "AETERM",
            "n_subjects",
            "ae_counting",
            "n_ae_total",
            "ae_percentage",
            "ci_95_lower",
            "ci_95_upper"
        ) %>%
        distinct()  %>%
        arrange(desc(ae_percentage)) %>%
        ungroup()

    data <- data %>%
        slice_head(n = n_top) 
    
    return(data)
}


#' Create AE Frequency Dot Plot
#'
#' @param data A data frame containing AE data (e.g., ADAE)
#' @param n_top Number of top AEs to display (default is 10)
#' @param figure_path Path of the figure to be saved - string
#'
#' @return A ggplot object
generate_ae_frequency_dotplot <- function(
    data,
    n_top,
    figure_path
) {

    # get top n_top AEs
    ae_freq_counting <- count_ae_freq(
        data = data,
        n_top = n_top
    )
    
    # generate the title and subtitle
    title <- paste0("Top ", n_top, " Most Frequent Adverse Events")
    subtitle <- paste0("n = ", unique(ae_freq_counting$n_subjects), " subjects, 95% Clopper-Pearson CIs")

    # orde the fig ae name
    ae_freq_counting$AETERM <- factor(
        ae_freq_counting$AETERM,
        levels = rev(unique(ae_freq_counting$AETERM))
    )

    # create the dotplot of the top 10 freuquencies AE
    top_ae_dotplot <- ggplot(
        data = ae_freq_counting,
        aes(
            x = AETERM,
            y = ae_percentage
        )
    ) +
    geom_point(size = 2) +
    geom_errorbar(aes(ymin = ci_95_lower, ymax = ci_95_upper), width = 0.3) +
    labs(
        x = "",
        y = "Percentage of Patient (%)",
        title = title,
        subtitle = subtitle
    ) +
    coord_flip()

    ggsave(
        top_ae_dotplot,
        filename = figure_path,
        width = 7,
        height = 5
    )

    return(top_ae_dotplot)

}


## -----------------------------------------
## Process
## -----------------------------------------


# load the data
adae <- pharmaverseadam::adae

# generate the figures
fig_ae_severity_distribution_by_treatment <- generate_ae_severity_barchart(
    data = adae,
    figure_path = snakemake@output[[1]]
)
fig_ae_most_frequent_adverse_events <- generate_ae_frequency_dotplot(
    data = adae,
    n_top = 10,
    figure_path = snakemake@output[[2]]
)

# close log file
log_close()