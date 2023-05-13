rule star_align:
    input:
        unpack(get_trimmed_fastq),
        # use a list for multiple fastq files for one sample
        # usually technical replicates across lanes/flowcells
        # #optional paired end reads needs to be ordered so each item in the two lists match
        idx=genome_prefix+"STAR", # path to STAR reference genome index
    output:
        # see STAR manual for additional output files
        aln="results/star/{s}_sortedByCoord.bam",
        log="logs/star/{s}.log",
        sj="results/star/{s}_splice_junctions.tsv",
        reads_per_gene="results/star/{s}_ReadsPerGene.tsv",
    params:
        extra="--outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts --twopassMode Basic" # optional parameters
    threads: 16
    wrapper:
        config["warpper_mirror"]+"bio/star/align"

rule merge_count:
    input:
        expand("results/star/{s}_ReadsPerGene.tsv",s=samples.Sample)
    output:
        temp("results/star/star_count.csv.gz")
    conda:
        "../envs/gene.yaml"
    params:
        samples.Sample
    script:
        "../scripts/merge_count.py"

rule normalise:
    input:
        counts="results/star/star_count.csv.gz",
        info=genome_prefix+"gene_info.csv.gz"
    output:
        report("results/star/star.csv.gz", caption="../report/normalise.rst",category="STRA-Count")
    conda:
        "../envs/gene.yaml"
    script:
        "../scripts/normalise.py"