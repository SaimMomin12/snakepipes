## sleuth (on Salmon)
## requires the checkpoint rule defined in DESeq2.multipleComp.snakefile

sample_name = os.path.splitext(os.path.basename(sampleSheet))[0]

rule sleuth_Salmon:
    input:
        quant_files = expand("Salmon/{sample}/abundance.h5", sample=samples),
        t2g = "Annotation/genes.filtered.t2g",
        sampleSheet = lambda wildcards: checkpoints.split_sampleSheet.get(compGroup=wildcards.compGroup).output
    output:
         "{}/so.rds".format(get_outdir("sleuth_Salmon",sleuth_salmon + ".{compGroup}.tsv"))
    benchmark:
        "sleuth_Salmon_{}/.benchmark/sleuth.Salmon.benchmark".format(sample_name + ".{compGroup}")
    params:
        script=os.path.join(maindir, "shared", "rscripts", "sleuth.R"),
        indir = os.path.join(outdir,"Salmon"),
        outdir = os.path.join(outdir,"sleuth_Salmon_{}".format(os.path.splitext(os.path.basename(str(sampleSheet)))[0]+".{compGroup}")),
        sampleSheet = lambda wildcards,input: os.path.join(outdir,str(input.sampleSheet)),
        fdr = 0.05,
    log:
        out = "sleuth_Salmon_{}/logs/sleuth.out".format(os.path.splitext(os.path.basename(str(sampleSheet)))[0]+".{compGroup}"),
        err = "sleuth_Salmon_{}/logs/sleuth.err".format(os.path.splitext(os.path.basename(str(sampleSheet)))[0]+".{compGroup}")
    conda: CONDA_RNASEQ_ENV
    shell:
        "Rscript {params.script} "
        "{params.sampleSheet} "
        "{params.indir} "
        "{params.outdir} "
        "{params.fdr} " + os.path.join(outdir,"{input.t2g}") +
        " >{log.out} 2>{log.err}"
