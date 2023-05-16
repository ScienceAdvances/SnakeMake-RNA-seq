import numpy as np
import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version
from pathlib import Path

min_version("7.25.0")

report: "../report/workflow.rst"

container: "mambaorg/micromamba:1.4.2"

#=====================================================
# validate config.yaml file and samples.csv file
#=====================================================

configfile: "config/config.yaml"

validate(config, schema="../schemas/config.schema.yaml")

samples = pd.read_csv(config["samples"], dtype=str,sep='\t',header=0).fillna(value="")
if not "Unit" in samples.columns:
    samples.loc[:,"Unit"]=""
samples.loc[:,"Unit"] = [f"_{x}" if x else x for x in samples.Unit]
samples.set_index(keys=["Sample", "Unit"], drop=False,inplace=True)

samples.index = samples.index.set_levels(
	[i.astype(str) for i in samples.index.levels]
)  # enforce str in index
# if units are not none, add a _ prefix
fastqs = config["fastqs"].get("dir")
if config["fastqs"].get("pe"):
	fq1=[f"{fastqs}/{x}{y}_1.fastq.gz" for x,y in zip(samples.Sample,samples.Unit)]
	fq2=[f"{fastqs}/{x}{y}_2.fastq.gz" for x,y in zip(samples.Sample,samples.Unit)]
	samples.insert(loc=0,column="fq2",value=fq2)
	samples.insert(loc=0,column="fq1",value=fq1)
else:
	fq1=[f"{fastqs}/{x}{y}.fastq.gz" for x,y in zip(samples.Sample,samples.Unit)]
	samples.insert(loc=0,column="fq1",value=fq1)

validate(samples, schema="../schemas/samples.schema.yaml")
# validate(samples, schema="workflow/schemas/samples.schema.yaml")

#=====================================================
# Wildcard constraints
#=====================================================

wildcard_constraints:
	s="|".join(samples.index.get_level_values(0)),
	u="|".join(samples.index.get_level_values(1))

#=====================================================
# Helper functions
#=====================================================

def get_genome_prefix(config):
	"""genome files prefix"""
	g=config["genome"]
	p="{0}/{1}_{2}_{3}_".format(g['dir'],g['species'].capitalize(),g['build'],g['release'])
	return p
genome_prefix=get_genome_prefix(config)

def get_fastq(wildcards):
	"""Get fastq files of given sample and unit."""
	fastqs = samples.loc[(wildcards.s, wildcards.u), ]
	if config["fastqs"].get("pe"):
		return [fastqs.fq1, fastqs.fq2]
	return [fastqs.fq1]

def get_trimmed_fastq(wildcards):
	"""Get trimmed reads of given sample and unit."""
	fastqs = samples.loc[wildcards.s, :]
	if config["fastqs"].get("pe"):
		# paired-end sample
		fq1=expand("results/trimmed/{{s}}_{_}_1.fastq.gz",_=fastqs.Unit)
		fq2=expand("results/trimmed/{{s}}_{_}_2.fastq.gz",_=fastqs.Unit)
		return {"fq1":fq1,"fq2":fq2}
	# single end sample
	return {"fq1":expand("results/trimmed/{{s}}_{_}.fastq.gz",_=fastqs.Unit)}

def get_contrast():
	vs = config["dea"]["dea_vs"]
	return ["_VS_".join(x) for x in vs]
