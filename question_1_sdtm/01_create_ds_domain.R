
## -----------------------------------------
## Log File
## -----------------------------------------

library(logr)
log_open("./01_create_ds_domain.log")


## -----------------------------------------
## Load the libraries 
## -----------------------------------------

library(tidyverse)
library(admiral)
library(gt)
library(readr)
library(pharmaverseraw)
library(sdtm.oak)
options(width=550)


## -----------------------------------------
## Loading the data
## -----------------------------------------


# Load the CT file
study_ct <- read_csv("./data/sdtm_ct.csv") # relative path to ct file

# Read the domain
dm <- pharmaversesdtm::dm

# Load the ds raw data
ds_raw <- pharmaverseraw::ds_raw

# Create the oak_id_vars
ds_raw <- ds_raw %>%
    generate_oak_id_vars(
        pat_var = "PATNUM",
        raw_src = "ds_raw"
    )


## -----------------------------------------
## Variable mapping and derivation
## -----------------------------------------

## -----
# Variable mapping and derivation
## -----

# Derive Topic Variable - DSDECOD
ds <- assign_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727"
)
write_csv(ds, "SDTM_DS.csv")


# Map the other variables
ds <- ds %>%
    assign_datetime(
        raw_dat = ds_raw,
        raw_var = "IT.DSSTDAT",
        tgt_var = "DSSTDTC",
        raw_fmt = c("m-d-y"),
        id_vars = oak_id_vars()
    ) %>%
    assign_no_ct(
        raw_dat = condition_add(
            ds_raw,
            is.na(ds_raw$OTHERSP)
        ),
        raw_var = "IT.DSDECOD",
        tgt_var = "DSDECOD",
        id_vars = oak_id_vars()
    ) %>%
    hardcode_no_ct(
        raw_dat = condition_add(
            ds_raw,
            ds_raw$IT.DSDECOD == "Randomized"
        ),
        raw_var = "IT.DSDECOD",
        tgt_var = "DSCAT",
        tgt_val = "PROTOCOL MILESTONE",
        id_vars = oak_id_vars()
    ) %>%
    hardcode_no_ct(
        raw_dat = condition_add(
            ds_raw,
            ds_raw$IT.DSDECOD != "Randomized"
        ),
        raw_var = "IT.DSDECOD",
        tgt_var = "DSCAT",
        tgt_val = "DISPOSITION EVENT",
        id_vars = oak_id_vars()
    ) %>%
    assign_no_ct(
        raw_dat = condition_add(
            ds_raw,
            !is.na(ds_raw$OTHERSP)
        ),
        raw_var = "OTHERSP",
        tgt_var = "DSDECOD",
        #ct_spec = study_ct,
        #ct_clst = "C66727",
        id_vars = oak_id_vars()
    ) %>%




    assign_no_ct(
        raw_dat = condition_add(
            ds_raw,
            !is.na(ds_raw$OTHERSP)
        ),
        raw_var = "OTHERSP",
        tgt_var = "DSTERM",
        id_vars = oak_id_vars()
    ) %>%
    hardcode_no_ct(
        raw_dat = condition_add(
            ds_raw,
            !is.na(ds_raw$OTHERSP)
        ),
        raw_var = "OTHERSP",
        tgt_var = "DSCAT",
        tgt_val = "OTHER EVENT",
        id_vars = oak_id_vars()
    ) %>%
    assign_no_ct(
        raw_dat = condition_add(
            ds_raw,
            is.na(ds_raw$OTHERSP)
        ),
        raw_var = "IT.DSTERM",
        tgt_var = "DSTERM",
        id_vars = oak_id_vars()
    ) %>%
    assign_datetime(
        raw_dat = ds_raw,
        raw_var = c("DSDTCOL", "DSTMCOL"),
        tgt_var = "DSDTC",
        raw_fmt = c("m-d-y", "H:M"),
        id_vars = oak_id_vars()
    )

# Map values in INSTANCE to VISIT (not from eCRF file)
ds <- ds %>%
    assign_ct(
        raw_dat = ds_raw,
        raw_var = "INSTANCE",
        tgt_var = "VISIT",
        ct_spec = study_ct,
        ct_clst = "VISIT",
        id_vars = oak_id_vars()
    )

# Get the columns for STUDYID, DOMAIN and USUBJID
ds <- ds %>%
    dplyr::mutate(
        STUDYID = ds_raw$STUDY,
        DOMAIN = "DS",
        USUBJID = paste0("01-", ds_raw$PATNUM),
    )

# Create SDTM derived variables
ds <- ds %>%
    derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSTERM")
    )

ds <- ds %>%
    derive_study_day(
        sdtm_in = .,
        dm_domain = dm,
        tgdt = "DSSTDTC",
        refdt = "RFXSTDTC",
        study_day_var = "DSSTDY"
    )

## Get the VISITNUM from VISIT

## visit lookup table
visit_lookup <- tibble::tribble(
    ~VISITNUM,  ~VISIT,
    1,          "SCREENING 1",
    2,          "BASELINE",
    3,          "WEEK 2",
    4,          "WEEK 4",
    5,          "WEEK 6",
    6,          "WEEK 8",
    7,          "WEEK 12",
    8,          "WEEK 16",
    9,          "WEEK 20",
    10,         "WEEK 24",
    11,         "WEEK 26",
    12,         "AMBUL ECG REMOVAL",
    13,         "RETRIEVAL",
    101.1,      "UNSCHEDULED 1.1",
    104.1,      "UNSCHEDULED 4.1",
    105.1,      "UNSCHEDULED 5.1",
    106.1,      "UNSCHEDULED 6.1",
    108.2,      "UNSCHEDULED 8.2",
    113.1,      "UNSCHEDULED 13.1"
)
ds <- ds %>%
    derive_vars_merged(
    dataset_add = visit_lookup,
    by_vars = exprs(VISIT)
    )


# selection of columns
ds <- ds %>%
    select(
        "STUDYID",
        "DOMAIN",
        "USUBJID",
        "DSSEQ",
        "DSTERM",
        "DSDECOD",
        "DSCAT",
        "VISITNUM",
        "VISIT",
        "DSDTC",
        "DSSTDTC",
        "DSSTDY"
    )

write_csv(ds, "SDTM_DS_FINAL_RESULTS.csv")



log_close()