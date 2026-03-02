# Roche Analytical Data Science Programmer - Coding Assessment
## Overview

This repository contains the source code, logs, and outputs for the Roche Coding Assessment. The project focuses on transforming raw clinical data into CDISC-compliant SDTM and ADaM datasets and generating a clinical summary of Treatment-Emergent Adverse Events (TEAEs).



## Project Structure

```
.
├── question_1_sdtm
│   ├── 01_create_ds_domain.R
│   ├── data
│   │   ├── sdtm_ct.csv
│   │   └── Subject_Disposition_aCRF.pdf
│   ├── log
│   │   ├── 01_create_ds_domain.log
│   │   └── 01_create_ds_domain.msg
│   └── SDTM_DS_FINAL_RESULTS.csv
│
├── question_2_adam
│   ├── 01_create_adsl.R
│   ├── ADSL_FINAL_RESULTS.csv
│   └── log
│       ├── 01_create_adsl.log
│       └── 01_create_adsl.msg
│
├── question_3_tlg
│   ├── 01_create_ae_summary_table.R
│   ├── 02_create_visualizations.R
│   ├── ae_figure_dotplot_top_most_frequent_adverse_events.png
│   ├── ae_severity_distribution_by_treatment.png
│   ├── ae_table_treatment_emergent.html
│   └── log
│       ├── 01_create_ae_summary_table.log
│       ├── 01_create_ae_summary_table.msg
│       ├── 02_create_visualizations.log
│       └── 02_create_visualizations.msg
└── README.md
```

## Key Technical Implementations
#### 1. SDTM Mapping ({sdtm.oak})

    Using the {sdtm.oak} package, we transformed the ds_raw dataset into the ds domain.

    Controlled Terminology: Handled non-conformant strings (e.g., "Randomized", "Screen Failure") by normalizing them to CDISC standards or mapping them to OTHER with details preserved in DSMODIFY.


#### 2. ADaM Derivations ({admiral})

    TRTSDTM: Derived the first exposure date from the EX domain. Applied logic to impute missing time to 00:00:00 while ensuring the TRTSTMF (Imputation Flag) remained blank if only seconds were missing, per study specifications.

    LSTAVLDT: Built a "Last Known Alive" date by evaluating four distinct data sources (VS, AE, DS, and EX) using derive_vars_extreme_event().


#### 3. Clinical Reporting ({gtsummary} & {ggplot2})

    TEAE Table: Generated an FDA-standard summary table sorted using gtsummary. Sort by frequencies AETERM and AESOC. 

    Visualization: Developed a reusable {ggplot2} functions generates figures:
    - AE Severity barchart for AE Severity distribution by treatment.
    - AE Dot Plot for the Top 10 AEs, sorted by frequency.

    Incidence Analysis: Calculated 95% Confidence Intervals using the Exact Clopper-Pearson method for proportions and Poisson logic for incidence rates.

## How to Run

    Ensure you have R version 4.1+ installed.

    Install required libraries:
    R

    install.packages(c("tidyverse", "admiral", "sdtm.oak", "gtsummary" "logr")) + dependencies.

    Clone this repository:
    Bash

    git clone https://github.com/hoang31/roche_coding_assessment.git

    Run the scripts in order (01 through 03). Check the logs/ folder to verify execution success.
    

## Exemple of execution
```{r}
conda activate your_roche_r_env
Rscript question_1_sdtm/01_create_ds_domain.R # this will create the SDTM_DS_FINAL_RESULTS.csv
```

## Compliance

All code follows Pharmaverse best practices, focusing on traceability, modularity, and adherence to CDISC SDTM IG 3.4 and ADaM IG 1.3 standards.

## Improvements - if more time is available
