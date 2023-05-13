rule samtools_flagstat:
	input:
		"results/star/{s}_sortedByCoord.bam"
	output:
		temp("results/qc/{s}.bam.flagstat")
	log:
		"logs/samtools_flagstat/{s}.log"
	wrapper:
		config["warpper_mirror"]+"bio/samtools/flagstat"

rule align_multiqc:
	input:
		expand("results/qc/{s}.bam.flagstat", s=samples.index.get_level_values(0))
	output:
		"report/align_multiqc.html"
	log:
		"logs/align_multiqc.log"
	wrapper:
		config["warpper_mirror"]+"bio/multiqc"

rule fastp_multiqc:
	input:
		expand("report/{s}_{u}.fastp.json", s=samples.Sample,u=samples.Unit)
	output:
		"report/fastp_multiqc.html"
	log:
		"logs/fastp/fastp_multiqc.log"
	wrapper:
		config["warpper_mirror"]+"bio/multiqc"

rule qc_plot:
	input:
		"results/star/star.csv.gz"
	output:
		report("report/qc_plot.pdf", caption="../report/qc_plot.rst", category="Quanlity Control")
	params:
		n_gene=config["qc_plot"].get("n_genes"),
		ellipses=config["qc_plot"].get("ellipses"),
		ellipse_size=config["qc_plot"].get("ellipse_size"),
		group=samples.Group,
		sample_order=samples.Sample,
	conda:
		"../envs/qc_plot.yaml"
	script:
		"../scripts/qc_plot.R"