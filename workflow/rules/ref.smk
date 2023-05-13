rule get_genome:
	output:
		genome_prefix+"genome.fa"
	log:
		"logs/genome/get_genome.log"
	retries: 50
	params:
		species=config["genome"].get("species"),
		datatype=config["genome"].get("datatype"),
		build=config["genome"].get("build"),
		release=config["genome"].get("release"),
	cache:
		"omit-software"
	wrapper:
		config["warpper_mirror"]+"bio/reference/ensembl-sequence"

rule get_annotation:
	output:
		genome_prefix+"annotation.gtf"
	retries: 50
	params:
		species=config["genome"].get("species"),
		release=config["genome"].get("release"),
		build=config["genome"].get("build"),
		flavor=config["genome"].get("flavor"),  # optional, e.g. chr_patch_hapl_scaff, see Ensembl FTP.
		# branch="plants",  # optional: specify branch
	log:
		"logs/genome/get_annotation.log"
	cache: 
		"omit-software"
	wrapper:
		config["warpper_mirror"]+"bio/reference/ensembl-annotation"

rule genome_faidx:
	input:
		genome_prefix+"genome.fa",
	output:
		genome_prefix+"genome.fa.fai",
	log:
		"logs/genome/genome_faidx.log",
	wrapper:
		config["warpper_mirror"]+"bio/samtools/faidx"

# https://stackoom.com/en/question/3ykjq
rule star_index:
	input:
		fasta=genome_prefix+"genome.fa",
		gtf=genome_prefix+"annotation.gtf",
	output:
	   directory(genome_prefix+"STAR")
	cache: 
		"omit-software"
	message:
		"STAR index"
	threads: 16
	log:
		"logs/genome/star_index.log",
	wrapper:
		config["warpper_mirror"]+"bio/star/index"

rule gene_info:
	input:
		genome_prefix+"annotation.gtf"
	output:
		genome_prefix+"gene_info.csv.gz"
	conda:
		"../envs/gene.yaml"
	script:
		"../scripts/gene_info.py"