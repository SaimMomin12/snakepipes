##umi_tools###############

if config['UMIBarcode']:
    if pairedEnd:
        rule umi_extract:
            input:
                r1 = "originalFASTQ/downsample_{sample}"+reads[0]+".fastq.gz" if downsample else "originalFASTQ/{sample}"+reads[0]+".fastq.gz",
                r2 = "originalFASTQ/downsample_{sample}"+reads[1]+".fastq.gz" if downsample else "originalFASTQ/{sample}"+reads[1]+".fastq.gz"
            output:
                r1 = "FASTQ/{sample}"+reads[0]+".fastq.gz",
                r2 = "FASTQ/{sample}"+reads[1]+".fastq.gz"
            params:
                bcpattern = str(bcPattern)
            log:
                out = "FASTQ/logs/{sample}_log.out",
                err = "FASTQ/logs/{sample}_log.err"
            conda: config["CONDA_SHARED_ENV"]
            shell:"""
                umi_tools extract -I {input.r1} --read2-in={input.r2} \
                --bc-pattern={params.bcpattern} --bc-pattern2={params.bcpattern}\
                --stdout={output.r1} \
                --read2-out={output.r2} -L {log.out} -E {log.err}
                """

    else:
        rule umi_extract:
            input:
                r1 = "originalFASTQ/downsample_{sample}"+reads[0]+".fastq.gz" if downsample else "originalFASTQ/{sample}"+reads[0]+".fastq.gz",
            output:
                r1 = "FASTQ/{sample}"+reads[0]+".fastq.gz",
            params:
                bcpattern = str(bcPattern)
            log:
                out = "FASTQ/logs/{sample}_log.out",
                err = "FASTQ/logs/{sample}_log.err"
            conda: config["CONDA_SHARED_ENV"]
            shell: """
                umi_tools extract -I {input.r1} --stdout={output.r1} \
                --bc-pattern={params.bcpattern} -L {log.out} -E {log.err}
                """

else:
    rule FASTQ1:
          input:
              "originalFASTQ/downsample_{sample}"+config['reads'][0]+".fastq.gz" if config['downsample'] else "originalFASTQ/{sample}"+config['reads'][0]+".fastq.gz"
          output:
              "FASTQ/{sample}"+config['reads'][0]+".fastq.gz"
          shell: """
                ln -s ../{input} {output}
          """

    if config['pairedEnd'] or config['pipeline']=="scrna-seq":
        rule FASTQ2:
            input:
                "originalFASTQ/downsample_{sample}"+config['reads'][1]+".fastq.gz" if config['downsample'] else "originalFASTQ/{sample}"+config['reads'][1]+".fastq.gz"
            output:
                "FASTQ/{sample}"+config['reads'][1]+".fastq.gz"
            shell: """
                ln -s ../{input} {output}
          """

#If DNA-mapping:
if config['UMIDedup']:
    rule filter_reads_umi:
        input:
            bamfile = "filtered_bam/{sample}.filtered.tmp.bam" if aligner == "Bowtie2" else aligner+"/{sample}.bam",
            indexfile = "filtered_bam/{sample}.filtered.tmp.bam.bai" if aligner == "Bowtie2" else aligner+"/{sample}.bam.bai"
        output:
            bamfile = "filtered_bam/{sample}.filtered.bam"
        params:
            umitools_options = str(UMIDedupOpts or ''),
            umitools_paired = "--paired " if pairedEnd else " ",
            umi_sep = str(UMIDedupSep),
        log:
            out = "filtered_bam/logs/umi_dedup.{sample}.out",
            err = "filtered_bam/logs/umi_dedup.{sample}.err"
        conda: config['CONDA_SHARED_ENV']
        shell: """
            umi_tools dedup -I {input.bamfile} \
            -S {output.bamfile} -L {log.out} -E {log.err} \
            --umi-separator {params.umi_sep} \
            {params.umitools_paired} {params.umitools_options}
            """
else:
    if config['aligner'] == "Bowtie2":
        rule filter_reads:
            input:
                bamfile = "filtered_bam/{sample}.filtered.tmp.bam"
            output:
                bamfile = "filtered_bam/{sample}.filtered.bam"
            shell: """
                   mv {input.bamfile} {output.bamfile}
                   """

    elif not config['aligner']=="bwameth" :
        rule filter_reads:
            input:
                bamfile = config['aligner']+"/{sample}.bam"
            output:
                bamfile = "filtered_bam/{sample}.filtered.bam"
            shell: """
                ln -s ../{input} {output}
          """

if not config['aligner']=="bwameth":
    rule samtools_index_filtered:
        input:
            "filtered_bam/{sample}.filtered.bam"
        output:
            "filtered_bam/{sample}.filtered.bam.bai"
        log: "filtered_bam/logs/{sample}.index.log"
        conda: config['CONDA_SHARED_ENV']
        shell: "samtools index {input} 2> {log}"
