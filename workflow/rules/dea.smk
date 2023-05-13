rule dea:
    input:
        "results/star/star.csv.gz"
    output:
        dea_res=report(expand("results/DEA/DEA_res_{_}.csv.gz",_=get_contrast()), caption="../report/dea.rst", category="DEA"),
        volcano=report(expand("results/DEA/Volcano_plot_{_}.pdf",_=get_contrast()), caption="../report/dea.rst", category="DEA"),
        ma=report(expand("results/DEA/MA_plot_{_}.pdf",_=get_contrast()), caption="../report/dea.rst", category="DEA"),
        norm_count="results/DEA/star_deseq_norm_count.csv.gz",
    params:
        contrast=config["dea"].get("dea_vs"),
        logFC=config["dea"].get("logFC"),
        pvalue=config["dea"].get("pvalue"),
        samples=samples,
    conda:
        "../envs/gene.yaml"
    threads: 16
    script:
        "../scripts/dea.py"