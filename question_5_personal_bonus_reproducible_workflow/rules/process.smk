
"""
    WORKFLOW FOR SDTM TO FIGURES
"""

rule create_ds_domain:   
    output:
        "results/SDTM_DS_FINAL_RESULTS.csv"
    params:
        ct_file_path = config["ct_file_path"]
    log:
        "logs/create_ds_domain.log"
    conda:
        "/home/hoangdongnguyen/.local/share/mamba/envs/roche"
    script:
        "../modules/create_ds_domain.R"

rule create_adsl:   
    input:
        "results/SDTM_DS_FINAL_RESULTS.csv"
    output:
        "results/SDTM_ADSL_FINAL_RESULTS.csv"
    conda:
        "/home/hoangdongnguyen/.local/share/mamba/envs/roche"
    log:
        "logs/create_adsl.log"
    script:
        "../modules/create_adsl.R"

rule create_summary_tables:
    input:
        "results/SDTM_ADSL_FINAL_RESULTS.csv"
    output:
        "results/ae_table_treatment_emergent.html",
    conda:
        "/home/hoangdongnguyen/.local/share/mamba/envs/roche"
    log:
        "logs/create_summary_tables.log"
    script:
        "../modules/create_summary_tables.R"

rule create_figures:
    input:
        "results/SDTM_ADSL_FINAL_RESULTS.csv"
    output:
        "results/ae_severity_distribution_by_treatment.png",
        "results/ae_figure_dotplot_top_most_frequent_adverse_events.png"
    conda:
        "/home/hoangdongnguyen/.local/share/mamba/envs/roche"
    log:
        "logs/create_figures.log"
    script:
        "../modules/create_figures.R"

rule create_html_report:
    input:
        "results/SDTM_DS_FINAL_RESULTS.csv",
        "results/SDTM_ADSL_FINAL_RESULTS.csv",
        "results/ae_table_treatment_emergent.html",
        "results/ae_severity_distribution_by_treatment.png",
    output:
        "results/html_report.html"
    log:
        "logs/create_html_report.log"
    conda:
        "/home/hoangdongnguyen/.local/share/mamba/envs/roche"
    script:
        "../modules/create_html_report.R"