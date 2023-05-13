from snakemake.shell import shell
import pandas as pd
import tempfile
with tempfile.TemporaryDirectory() as tmpdir:
    shell("python workflow/scripts/gtftools.py --gene_length {tmpdir}/gene_length {snakemake.input[0]}")
    shell("python workflow/scripts/gtftools.py --gene {tmpdir}/gene {snakemake.input[0]}")

    g1 = pd.read_csv(f"{tmpdir}/gene",sep='\t',index_col=4,header=None)
    g1.columns = ["Chr","Start","Stop","Strand","Symbol","GeneType"]
    g2 = pd.read_csv(f"{tmpdir}/gene_length",sep='\t',index_col=0,usecols=["gene","merged"])

    g = pd.merge(g1,g2,left_index=True,right_index=True)
    g.insert(loc=0,column="Ensembl",value=g.index)
    g.rename(columns={"merged":"Length"},inplace=True)
    g.sort_values("Chr",inplace=True)

    g.to_csv(snakemake.output[0],index=False)
