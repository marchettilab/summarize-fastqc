#!/bin/bash
#
# Abstract: Script that summarizes many fastqc reports 
# Author: Sara Haines
# Last Revised: Time-stamp: <2015-08-26 11:37:48 haines>
#
# Idea based on this post in BioStars -- 
#   "We have a script that will run fastqc and generate a summary report 
#    with the images from all the fastq files it was run on." 
#    -- https://www.biostars.org/p/141797/#141967
# 
# Creates summary html report for multiple sample fastqc output.
# 
# load modules
module load imagemagick

# source subroutines needed for this script
source summarize_fastqc_subroutines.sh

# ensure that indir and glob is unset
unset indir
unset glob

function display_usage {
    echo "Usage: source summarize_fastqc.sh [-h] [-v][-d=path] [-g=glob]"
    echo "     -h|--help                display this help"
    echo "     -v|--verbose             turn on verbose mode"
    echo "     -d|--directory=path      path to folder of fastqc files"
    echo "     -g|--glob=glob           glob used to help select certain files"
    echo 
    echo "For example, "
    echo "  [unix]$ source summarize_fastqc.sh -d=./fastqc -g=*R1_outP*"
    echo "  [unix]$ source summarize_fastqc.sh --directory=./fastqc --glob=*R1*"
    echo 
    echo "This script will generate a summary html report in [path] "
    echo "for the type of files found with [file-glob] of mulitple fastq reports"
    echo 
    echo "Test listing of files you want to summarize, with same path and glob string"
    echo "  [unix]$ ls ./fastqc/*R1_outP*"
    echo 
    echo " ------------------------------------------------------------------- "
}

# if not enough inputs print usage
if [ $# -lt 2 ] ; then display_usage ; exit 0 ; fi

indir=""
glob=""
verbose=0

for i in "$@"; do
    case $i in
	-d*|--directory*)
	    indir="${i#*=}"
	    shift # past argument=value
	    ;;
	-g*|--glob*)
	    glob="${i#*=}"
	    shift # past argument=value
	    ;;
	-v|--verbose)
	    verbose=1
	    shift # past argument with no value
	    ;;
	-h|--help)
	    display_usage
	    #return
	    #shift # past argument with no value
        exit 0
 	    ;;
	*)
	    display_usage
	    #return
        exit 0
            # unknown option
	    ;;
    esac
done


# if [ -n "$1" ]
# then 
#     indir=$1
# fi

# if [ -n "$2" ]
# then 
#     glob=$2
# fi

# if not defined then don't continue
if [[  -z "$indir" || -z "$glob" ]]; then
    echo " ------------------------------- "
    echo " One of these is null "
    echo " --directory=$indir"
    echo " --glob=$glob"
    echo " ------------------------------- "
    display_usage
    return
fi

# generate summary report in same directory as input
# indir=./fastqc # for testing
outdir=${indir}
outtype=${glob//\*/}
outhtml=${outdir}/${outtype}_summary_report.html

zips=$(ls ${indir}/${glob}.zip)
# echo $zips

echo "Generate summary reports for ..."
for i in ${zips}; do
    if [ $verbose == 1 ]; then 
	echo ... $(basename $i .fq_fastqc.zip)
    fi
done

# unzip each of the fastq folders, to extract
# fastqc details and create thumbnails of images to generate the report
echo "Unzipping folders ..."
fastqdirs=""
for i in ${zips}; do
    if [ $verbose == 1 ]; then echo "... $i" ; fi
    unzip -d $outdir -o $i &>/dev/null
    fastqdirs="${fastqdirs} ${i%.zip}"
done

if [ $verbose == 1 ]; then echo $fastqdirs ; fi

# generate thumbs of images
echo "Creating thumbnails of images ..."
for i in ${fastqdirs}; do
    if [ $verbose == 1 ]; then echo "... $i/Images" ; fi
    make_thumbs $i/Images
done

echo "Generating the report -- ${outhtml} ..."

# start a new html report (overwrite previous file if exists)
echo "<html>" > ${outhtml}

# add some style for tables
echo "<head>" >> ${outhtml}
echo "<style>" >> ${outhtml}
css=$(css_style)
echo "${css}" >> ${outhtml}
echo "</style>" >> ${outhtml}
echo "</head>" >> ${outhtml}
echo "<body>" >> ${outhtml}

# append first table onto the report
# generate the summary table from *_fastqc/fastqc_data.txt
headers=(Sample Total_Sequences Sequences_flagged_as_poor Sequence_Length Percent_GC)
ths=$(table_header "${headers[@]}")
trs=$(fill_summary_table "${fastqdirs[@]}")
table="<table>${ths}${trs}</table>"

echo "${table}" >> ${outhtml}
echo "<br>" >> ${outhtml}

# generate the summary plots from *_fastqc/Images/thumbs.*.png
headers=(sample base_qual tile_qual seq_qual seq_cont seq_GC len_dist seq_dup adap_cont kmers)
ths=$(table_header "${headers[@]}")
trs=$(fill_thumb_table "${fastqdirs[@]}")
table="<table>${ths}${trs}</table>"

# append second table onto the report
echo "${table}" >> ${outhtml}

# end of html and some help
help=$(help_links)
echo "${help}" >> ${outhtml}
echo "<hr>" >> ${outhtml}
echo "Report Generated: $(date)" >> ${outhtml}
echo "</body>" >> ${outhtml}
echo "</html>" >> ${outhtml}

echo "Cleaning up ..."
for i in $fastqdirs; do
    if [ $verbose == 1 ]; then echo "... $i" ; fi
    rm -rf $i 
done

# ensure that blob is unset
# unset glob

echo "Done!"
