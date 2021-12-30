#!/bin/bash
# Script to carry out automated BAT imaging analysis 

# v5. Dec 29th, 2021 - Gayathri Raman Slight improvements in the script

# Initiate heainit before you run this script
# Download the BAT and auxil folder for the GRB data folder from quicklook
# https://swift.gsfc.nasa.gov/sdc/ql/
# Be on the location just above the GRB data folder

# User inputs here
#-----------------------------------

folder=GRB211229A_329_trig # GRB folder name which contains the tarred dataset
trigger_time=662441355.000  # Trigger time in MET 

#---------------------------------------------------


cd $folder
echo "------------------------"
echo "un-tarring the dataset"
echo "------------------------"
tar -xvf *.tar
cd 0*/bat/event



inp=$(ls *shpo_uf.evt*)
gunzip -k $inp  
uncomp_inp=$(ls *shpo_uf.evt)
maskfile=$(ls ../hk/sw*bdecb*)
detmask=$(ls ../hk/sw*bdqcb.hk.gz)
att=$(ls ../../auxil/sw*sat.fits*)

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






