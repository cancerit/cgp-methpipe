# cgp-methpipe

This repository contains the tools used in Sanger's Cancer, Ageing and Somatic
Mutation group's methylation pipeline, containerised using Docker.

## Usage

```
docker run --rm cgp-methpipe:${VERSION} ${COMMAND}
```

### Commands

- fastqc
- cutadapt
- trim_galore
- bismark
- deduplicate_bismark
- bismark_methylation_extractor
- bismark2report
- bismark2summary
- samtools
- hisat2
- bwa
- bwameth.py
- picard
- MethylDackel
- qualimap
- preseq
- multiqc
- runMethPipe.sh

