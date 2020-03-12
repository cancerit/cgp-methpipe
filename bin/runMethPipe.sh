#/bin/bash
#Extraction of the methylseq Nextflow pipeline (v 1.4.0)
#Requires a pair of fastq files and a reference directory that
#has been prepared with Bismark

usage()
{
    echo "usage: runMethPipe  output-dir fastq1 fastq2 reference-dir [ number-of-CPUs ]"
}

if ! [[ "$#" == 4 || "$#" == 5 ]] ; then
  echo
  usage
  echo
  exit
fi

OUTD=$1
FASTQ1=$2
FASTQ2=$3
REF=$4

if [ -z "$5" ]; then
  CPUs=16 #doesn't seem to scale very well beyond this
  else
  CPUs=$5
fi

if [ ! -d "$OUTD" ]; then
  echo "Output directory not found"
  exit 1
fi
cd $OUTD

if  [ ! -f "$FASTQ1" ]; then
  echo "Fastq1 not found"
  exit 1
fi

if  [ ! -f "$FASTQ2" ]; then
  echo "Fastq2 not found"
  exit 1
fi

if [ ! -d "$REF" ]; then
  echo "Reference directory not found"
  exit 1
fi

DIR1=$(dirname $FASTQ1)
DIR2=$(dirname $FASTQ2)

NAME1=$(basename $FASTQ1 .fastq.gz)
NAME2=$(basename $FASTQ2 .fastq.gz)



C='\033[0;35m'
NC='\033[0m'
echomsg() { echo -e "${C}$@${NC}"; }
echomsg "Started on Fastqc"
(T0=`date +%s`; fastqc --quiet -o $OUTD --threads 2 $DIR1/$NAME1.fastq.gz $DIR2/$NAME2.fastq.gz;T1=`date +%s`; echomsg "Completed Fastqc... $(($T1-$T0)) sec.") &
PID1=$!

echomsg "Started on trim_galore"; T0=`date +%s`
trim_galore --paired --fastqc --dont_gzip  --clip_r1 6 --clip_r2 6 --three_prime_clip_r1 2 --three_prime_clip_r2 2 $DIR1/$NAME1.fastq.gz $DIR2/$NAME2.fastq.gz #could be sped up by using threading
T1=`date +%s`;echomsg "Completed trim_galore... $(($T1-$T0)) sec."
wait $PID1

#markdown_to_html.r output.md results_description.html

echomsg "Started bismark alignment"; T0=`date +%s`
#Threads used are about 5/2*multicore , Mem ~ 10G * multicore
bismark -1 ${NAME1}_val_1.fq -2 ${NAME2}_val_2.fq  --bowtie2 --bam --multicore $((2*$CPUs/5)) --genome $REF
T1=`date +%s`;echomsg "Completed bismark alignment... $(($T1-$T0)) sec."
rm -f ${NAME1}_val_1.fq
rm -f ${NAME2}_val_2.fq

echomsg "Started preseq calculation"
BAM=${NAME1}_val_1_bismark_bt2_pe.bam
BAMO=${NAME1}_val_1_bismark_bt2_pe.sorted.bam
(T0=`date +%s`; samtools sort $BAM -@$(($CPUs/2)) -o $BAMO; preseq lc_extrap -v -B $BAMO -o ${NAME1}_val_1_bismark_bt2_pe.ccurve.txt; T1=`date +%s`; echomsg "Completed preseq calculation... $(($T1-$T0)) sec."; rm -f $BAMO ) &
PID1=$!

echomsg "Started bismark summary"; T0=`date +%s`
bismark2summary
T1=`date +%s`;echomsg "Completed bismark summary... $(($T1-$T0)) sec."

echomsg "Started bismark deduplication"; T0=`date +%s`
deduplicate_bismark -p --bam $BAM
T1=`date +%s`;echomsg "Completed bismark deduplication... $(($T1-$T0)) sec."

rm -f $BAM 
BAM=${NAME1}_val_1_bismark_bt2_pe.deduplicated.bam

BAMO=${NAME1}_val_1_bismark_bt2_pe.deduplicated.sorted.bam
DIRO=${NAME1}_val_1_bismark_bt2_pe.deduplicated_qualimap

echomsg "Started qualimap calculation";T0=`date +%s`
samtools sort $BAM -@ $(($CPUs/2)) -o $BAMO; qualimap bamqc  -bam $BAMO -outdir $DIRO --collect-overlap-pairs --java-mem-size=48G  -nt $(($CPUs/2)); T1=`date +%s`; 
echomsg "Completed qualimap calculation... $(($T1-$T0)) sec."; rm -f $BAMO

wait $PID1

#methXtract seems to cap off at 12 CPUs
if [ $CPUs -gt 12 ]; then
  NCPU=12
  else
  NCPU=$CPUs
fi
echomsg "Started bismark methXtract"; T0=`date +%s`
bismark_methylation_extractor  --buffer_size 46G --ignore_r2 2 --ignore_3prime_r2 2  --bedGraph  --counts  --gzip -p --no_overlap  --report --multicore $NCPU $BAM
T1=`date +%s`;echomsg "Completed bismark methXtract... $(($T1-$T0)) sec."

NN=${NAME1}_val_1_bismark_bt2_pe
NA=${NAME1}_val_1_bismark_bt2_PE
echomsg "Started bismark report"; T0=`date +%s`
bismark2report --alignment_report ${NA}_report.txt -dedup_report ${NN}.deduplication_report.txt --splitting_report ${NN}.deduplicated_splitting_report.txt --mbias_report ${NN}.deduplicated.M-bias.txt
T1=`date +%s`;echomsg "Completed bismark report... $(($T1-$T0)) sec."


echomsg "Started multiqc"; T0=`date +%s`
multiqc -f --title \"$NAME1\" --filename ${NAME1}_multiqc_report .  -m custom_content -m picard -m qualimap -m bismark -m samtools -m preseq -m cutadapt -m fastqc ## --config multiqc_config.yaml
T1=`date +%s`;echomsg "Completed multiqc... $(($T1-$T0)) sec."

