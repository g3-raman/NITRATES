#!/bin/bash

batml_path='/storage/home/gzr5209/work/BatML_code_work/NITRATES/'
ht_path=$batml_path'HeasoftTools/'
sub_path=$batml_path'submission_scripts/'

#workdir='/storage/home/gzr5209/work/bat-data/'
#workdir='/storage/home/gzr5209/work/realtime_workdir/result/'
workdir='/gpfs/group/jak51/default/gzr5209/realtime_results/'

ratespbs='/storage/home/gzr5209/work/BatML_code_work/NITRATES/submission_scripts/pyscript_template_rhel7_g3.pbs'

drmdir='/storage/home/gzr5209/work/drms/'

export PYTHONPATH=$batml_path:$PYTHONPATH
export PYTHONPATH=$ht_path:$PYTHONPATH


HEADAS=/storage/home/gzr5209/work/Softwares/heasoft/heasoft-6.28/x86_64-pc-linux-gnu-libc2.17
export HEADAS
alias heainit='/storage/home/gzr5209/work/Softwares/heasoft/heasoft-6.28/x86_64-pc-linux-gnu-libc2.17/headas-init.sh'

. $HEADAS/headas-init.sh


export CALDB=/storage/home/gzr5209/work/Softwares/CALDB
source $CALDB/software/tools/caldbinit.sh

export HEADASNOQUERY=
export HEADASPROMPT=/dev/null

export PFILES="/tmp/$$.tmp/pfiles;$HEADAS/syspfiles"


#HEADAS=/storage/work/jjd330/heasoft/heasoft-6.24/x86_64-pc-linux-gnu-libc2.12
#export HEADAS
#. $HEADAS/headas-init.sh

# CALDB stuff
#CALDB=/storage/work/jjd330/caldb_files; export CALDB
#source $CALDB/software/tools/caldbinit.sh

#export HEADASNOQUERY=
#export HEADASPROMPT=/dev/null

#export PFILES="/tmp/$$.tmp/pfiles;$HEADAS/syspfiles"

# evfname=$1
# dmask=$2
# attfname=$3
# trigtime=$4
# gwname=$5

trigtime=$1
gwname=$2


#------------------------------------
#Adding these lines on Jan 21st, 2021

# first arg is the trigger time in either isot or MET
trigtime=$1
# gwname is the name of the event/analysis
# it'll be the name of the directory inside workdir and used for job names
gwname=$2
# file name of the event file to use
evfname=$3
# file name of the detmask to use
dmask=$4
# file name of the attitude to use
attfname=$5
# file names can also be urls
#-----------------------------------



# if [ "$#" -ne 2 ]; then
#     nimgs=$3
# else
#     nimgs=60
# fi

Nratejobs=16 # commenting out on Jan 24th 2022
twind=20.0
tmin=-20.0
Ntdbls=6

# $Njobs=

workdir=$workdir$gwname
if [ ! -d "$workdir" ]; then
  mkdir $workdir
fi

if [ "$#" -ne 5 ]; then
    mintbin=$6
else
    mintbin=0.256
fi


mintbin=0.256

echo $trigtime
echo $workdir
echo $Nratejobs
echo $twind
echo 'mintbin=' $mintbin

cd $batml_path

curdir=$(pwd)

echo $curdir

echo $$ > $workdir'/run_stuff.pid'

python mkdb.py --trig_time $trigtime --work_dir $workdir --drm_dir $drmdir

cd $workdir
#cd $obsid


# Imaging --------

trigger_time=$trigtime
inp=$evfname
detmask=$dmask
att=$att

#-----------------------------------------------------------

echo "Number of time trials = 7"
#nt=7

time_bins_array=( 0.01 0.02 0.05 0.1 0.2 0.5 1.0 )
energy_array=(10-350 15-300 20-250 50-150)

#time_ele=${time_bins_array[nt]}



for i in "${time_bins_array[@]}"
do
	for j in "${energy_array[@]}"
	do 

		echo "------------------------"
		echo "Analysis for time bin size of " $i "and energy range " $j
		echo "------------------------"


		echo " extract light curve and run batbblocks to get tstart and tstop"


#num3=50.0
#num4=50.0

		num3=80.0
		num4=80.0

		tstart_lcurve=`expr "$trigger_time - $num3 " | bc`
		tstop_lcurve=`expr "$trigger_time + $num4 " | bc`


		batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc.fits detmask=$detmask outtype=LC timedel=$i timebinalg=u energybins=$j weighted=NO outunits=COUNTS clobber=YES

		battblocks grb-lc.fits grb-bb-lc.fits durfile=burst_dur.gti


		ftlist burst_dur.gti+1 include='TSTART' outfile=tstart.txt k
		tstart=$(awk '{print $3}' tstart.txt)
		#echo $tstart

		ftlist burst_dur.gti+1 include='TSTOP' outfile=tstop.txt k
		tstop=$(awk '{print $3}' tstop.txt)
		#echo $tstop

		tstart_fgnd=$tstart
		tstop_fgnd=$tstop


		num1=80.0
		num2=20.0

		tstart_bkg=`expr "$tstart_fgnd - $num1 " | bc`
		tstop_bkg=`expr "$tstart_fgnd - $num2 " | bc`



		echo "------------------------"
		echo "-------- foreground and bkg dpi images using batbinevt----------------"

		batbinevt tstart=$tstart_fgnd tstop=$tstop_fgnd infile=$inp outfile=grb.dpi  detmask=$detmask outtype=DPI timedel=0 timebinalg=u energybins=$j weighted=NO outunits=COUNTS clobber=YES

		batbinevt tstart=$tstart_bkg tstop=$tstop_bkg infile=$inp outfile=grb-bkg.dpi  detmask=$detmask outtype=DPI timedel=0 timebinalg=u energybins=$j weighted=NO outunits=COUNTS clobber=YES

		echo "------------------------"
		echo "-------- batfft - creating bkg subtracted sky images----------------"


		batfftimage detmask=$detmask aperture = "CALDB:DETECTION" infile=grb.dpi outfile=grb_backsub.img attitude=$att 

		echo "------------------------"
		echo "-------- batcelldetect - finding sources and their SNRs----------------"


		batcelldetect grb_backsub.img srclists.fits 3.5


		echo "Analysis complete for time bin size of " $i " and energy range " $j


		#echo "tstart=", $tstart, "tstop=", $tstop

		echo "tstart foreground=" $tstart_fgnd "tstop foreground = " $tstop_fgnd "tstart bkg =" $tstart_bkg "tstop bkg = " $tstop_bkg

		rm -rf tstart.txt tstop.txt grb-lc.fits burst_dur.gti grb-bb-lc.fits grb.dpi grb-bkg.dpi grb_backsub.img srclists.fits 

		echo "------------------------"

	done

done




#----------------




#python $batml_path'do_data_setup.py' --work_dir $workdir --trig_time $trigtime --search_twind $twind --min_dt $tmin --Ntdbls $Ntdbls --min_tbin $mintbin  --evfname $evfname --dmask $dmask --att_fname $attfname --acs_fname $attfname
#if [ -f "filter_evdata.fits" ]; then
#   python $batml_path'do_full_rates.py' --min_tbin $mintbin > full_rates.out 2>&1 &
 
#    python $batml_path'do_manage2_open.py' --GWname $gwname --rhel7 --do_bkg --do_rates --do_llh --queue open --N_infov_jobs 96 --N_outfov_jobs 24 > manager.out 2>&1 &
    #python $batml_path'do_manage2.py' --GWname $gwname --rhel7 --do_bkg --do_rates --do_llh > manager.out 2>&1 &
#fi

cd $curdir
