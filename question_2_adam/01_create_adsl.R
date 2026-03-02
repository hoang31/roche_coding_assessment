
## -----------------------------------------
## Log File
## -----------------------------------------

library(logr)
log_open("./01_create_adsl.log")

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
#library(metatools)




## -----------------------------------------
## Process
## -----------------------------------------

# load the data
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae
suppdm <- pharmaversesdtm::suppdm

# When SAS datasets are imported into R using haven::read_sas(), missing
# character values from SAS appear as "" characters in R, instead of appearing
# as NA values. Further details can be obtained via the following link:
# https://pharmaverse.github.io/admiral/articles/admiral.html#handling-of-missing-values
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)
suppdm <- convert_blanks_to_na(suppdm)


## -----
## Derive Variables - AGEGR9 and AGEGR9N - derived from AGE in DM data
## -----

# Lookup table for AGEGR9 and AGEGR9N
agegr1_lookup <- exprs(
    ~condition,            ~AGEGR9,     ~AGEGR9N,
    is.na(AGE),            "Missing",   4,
    AGE < 18,              "<18",       1,
    between(AGE, 18, 50),  "18-50",     2,
    AGE > 50,              ">50",       3
)

# merge the lookup table with the DM dataset
adsl <- derive_vars_cat(
    dataset = dm,
    definition = agegr1_lookup
)


## -----
## Derive Variables - TRTSDTM and TRTSTMF - derived from EXSTDTC in EX data
## -----


ex_ext <- ex %>%
    derive_vars_dtm(
        dtc = EXSTDTC,
        new_vars_prefix = "EXST",
        time_imputation = "first",
        highest_imputation = "h"
    ) %>%
    mutate(
        # Handel when only the second is missing 
        # logic: if the n char is equal to 16 (length 16 like YYYY-MM-DDTHH:MM such as 2014-04-14T10:38)
        #then the TMF should be blank.
        EXSTTMF = if_else(nchar(EXSTDTC) == 16, NA_character_, EXSTTMF)
    )
    
# treatment start
adsl <- adsl %>%
    derive_vars_merged(
        dataset_add = ex_ext,
        filter_add = 
            (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) &
            !is.na(EXSTDTM) &
            (nchar(EXSTDTC) >= 10), # check if the EXSTDTC is complete
        new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
        order = exprs(EXSTDTM, EXSEQ),
        mode = "first",
        by_vars = exprs(STUDYID, USUBJID)
    )

# treatment end - for next question
adsl <- adsl %>%
    derive_vars_merged(
        dataset_add = ex_ext,
        filter_add = 
            (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) & !is.na(EXENDTC) & (nchar(EXSTDTC) >= 10),
        order = exprs(EXENDTC, EXSEQ),
        mode = "last",
        by_vars = exprs(STUDYID, USUBJID),
        new_vars = exprs(TRTEDTM = EXENDTC)
    )



## -----
## Derive Variables - ITTFL - derived from DM
## -----

ittfl_lookup <- exprs(
    ~condition,            ~ITTFL,
    !is.na(ARM),           "Y",
    is.na(ARM),            "N",
)

adsl <- derive_vars_cat(
    dataset = adsl,
    definition = ittfl_lookup
)


### -----
### Derive Variables - LSTAVLDT - derived from VS data
### -----


# 1) columns to be used: VS.VSSTRESC, VS.VSSTRESN, VS.VSDTC
event_vs <- event(
    dataset_name = "vs",
    condition = !((is.na(VSSTRESN)) & (is.na(VSSTRESC))) & !(is.na(VSDTC)),
    order = exprs(VSDTC, VSSEQ),
    mode = "last",
    set_values_to = exprs(LSTAVLDT = convert_dtc_to_dt(VSDTC), DTHDOM = "VS")
)

# 2) columns to be used: AE.AESTDTC
ae <- ae %>% # Impute values to avoid NA
    derive_vars_dt(
        dtc = AESTDTC,
        new_vars_prefix = "LAE",
        date_imputation = "first",
        highest_imputation = "M"
    )

event_ae <- event(
    dataset_name = "ae",
    condition = !is.na(LAEDT),
    order = exprs(LAEDT, AESEQ),
    mode = "last",
    set_values_to = exprs(LSTAVLDT = convert_dtc_to_dt(as.character(LAEDT)), DTHDOM = "AE")
)

# 3) DS.DSSTDTC
event_ds <- event(
    dataset_name = "ds",
    order = exprs(DSSTDTC, DSSEQ),
    mode = "last",
    set_values_to = exprs(LSTAVLDT = convert_dtc_to_dt(DSSTDTC), DTHDOM = "DS")
)

# 4) ADSL.TRTEDTM
event_adsl <- event(
    dataset_name = "adsl",
    condition = !is.na(TRTEDTM),
    order = exprs(TRTEDTM),
    mode = "last",
    set_values_to = exprs(LSTAVLDT = convert_dtc_to_dt(TRTEDTM), DTHDOM = "ADSL")
)


# Get the max of the date, which will be the LSTAVLDT
adsl <- adsl %>%
    derive_vars_extreme_event(
        by_vars = exprs(STUDYID, USUBJID),
        events = list(
            event_vs,
            event_ae,
            event_ds,
            event_adsl
        ),
        source_datasets = list(
            vs = vs,
            ae = ae,
            ds = ds,
            adsl = adsl
        ),
        tmp_event_nr_var = event_nr,
        order = exprs(LSTAVLDT, event_nr),
        mode = "last",
        new_vars = exprs(LSTAVLDT, DTHDOM)
    )

write_csv(adsl, "ADSL_FINAL_RESULTS.csv")
log_close()