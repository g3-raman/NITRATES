#!/bin/sh
# Script to carry out automated BAT imaging analysis 

# v4. Oct 12th, 2021 - Gayathri Raman Slight improvements in the script - battblocks much better now

# Initiate heainit before you run this script
# Download the BAT and auxil folder for the GRB data folder from quicklook
# https://swift.gsfc.nasa.gov/sdc/ql/
# Be on the location just above the GRB data folder

# User inputs here
#-----------------------------------
#echo "Hi there! Which GRB would you ike to analyze today?"
#read folder
folder=GRB_6thNov_Integral # GRB folder name which contains the tarred dataset

#echo "Whats the trigegr time?"
#read trigger_time
trigger_time=657866251.000 # Trigger time in MET 



#---------------------------------------------------


cd $folder
echo "------------------------"
echo "un-tarring the dataset"
echo "------------------------"
tar -xvf *.tar
cd 0*/bat/event
ls *po_uf.evt.gz > filelist.txt
cp ../../../../formatting_lc.pco .
cp ../../../../plot_code.py .


inp=$(ls *shpo_uf.evt*)
gunzip -k $inp  
uncomp_inp=$(ls *shpo_uf.evt)
maskfile=$(ls ../hk/sw*bdecb*)
detmask=$(ls ../hk/sw*bdqcb.hk.gz)
att=$(ls ../../auxil/sw*sat.fits*)

#-----------------------------------------------------------
echo " extract light curve and run batbblocks to get tstart and tstop"



#num3=50.0
#num4=50.0

num3=200.0
num4=200.0

tstart_lcurve=`expr "$trigger_time - $num3 " | bc`
tstop_lcurve=`expr "$trigger_time + $num4 " | bc`


batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc.fits detmask=$detmask outtype=LC timedel=0.05 timebinalg=u energybins=10-350 weighted=NO outunits=COUNTS clobber=YES

battblocks grb-lc.fits grb-bb-lc.fits durfile=burst_dur.gti


# energy resolved light curves
echo "Energy resolved light curves-------------"
batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-15-25keV.fits detmask=$detmask outtype=LC timedel=0.05 timebinalg=u energybins=15-25 weighted=NO outunits=COUNTS clobber=YES

batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-25-50keV.fits detmask=$detmask outtype=LC timedel=0.05 timebinalg=u energybins=25-50 weighted=NO outunits=COUNTS clobber=YES

batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-50-100keV.fits detmask=$detmask outtype=LC timedel=0.05 timebinalg=u energybins=50-100 weighted=NO outunits=COUNTS clobber=YES

#battblocks grb-lc-50-100keV.fits grb-bb-lc.fits durfile=burst_dur.gti

batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-100-250keV.fits detmask=$detmask outtype=LC timedel=0.05 timebinalg=u energybins=100-250 weighted=NO outunits=COUNTS clobber=YES


batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-250-350keV.fits detmask=$detmask outtype=LC timedel=0.05 timebinalg=u energybins=250-350 weighted=NO outunits=COUNTS clobber=YES



ftlist burst_dur.gti+1 include='TSTART' outfile=tstart.txt k
tstart=$(awk '{print $3}' tstart.txt)
echo $tstart
#tstart=653758790.500
ftlist burst_dur.gti+1 include='TSTOP' outfile=tstop.txt k
tstop=$(awk '{print $3}' tstop.txt)
#tstop=653758791.500
echo $tstop

tstart_fgnd=$tstart
tstop_fgnd=$tstop




num1=80.0
num2=20.0

#num1=80.0
#num2=10.0

tstart_bkg=`expr "$tstart_fgnd - $num1 " | bc`
tstop_bkg=`expr "$tstart_fgnd - $num2 " | bc`



echo "------------------------"
echo "-------- foreground and bkg dpi images using batbinevt----------------"

batbinevt tstart=$tstart_fgnd tstop=$tstop_fgnd infile=$inp outfile=grb.dpi  detmask=$detmask outtype=DPI timedel=0 timebinalg=u energybins=50-195 weighted=NO outunits=COUNTS clobber=YES

batbinevt tstart=$tstart_bkg tstop=$tstop_bkg infile=$inp outfile=grb-bkg.dpi  detmask=$detmask outtype=DPI timedel=0 timebinalg=u energybins=50-195 weighted=NO outunits=COUNTS clobber=YES

echo "------------------------"
echo "-------- batfft - creating bkg subtracted sky images----------------"


batfftimage detmask=$detmask aperture = "CALDB:DETECTION" infile=grb.dpi outfile=grb_backsub.img attitude=$att 

echo "------------------------"
echo "-------- batcelldetect - finding sources and their SNRs----------------"


batcelldetect grb_backsub.img srclists.fits 3.5


echo "Analysis complete"

#fdump 
echo "Plotting-- "

#echo "tstart=", $tstart, "tstop=", $tstop

echo "tstart foreground=" $tstart_fgnd "tstop foreground = " $tstop_fgnd "tstart bkg =" $tstart_bkg "tstop bkg = " $tstop_bkg

python plot_code.py









