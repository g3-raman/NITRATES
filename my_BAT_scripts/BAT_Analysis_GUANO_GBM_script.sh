#!/bin/bash
# Script to carry out automated BAT analysis for Swift GUANO GRBs - light curves and spectral extraction

# v4. Oct 12, 2021 - Gayathri Raman

# Initiate heainit before you run this script
# Download the BAT and auxil folder for the GRB data folder from quicklook
# https://swift.gsfc.nasa.gov/sdc/ql/
# Be on the location just above the GRB data folder

# User inputs here
#-----------------------------------
#echo "Hi there! Which GRB would you ike to analyze today?"
#read folder
#folder=GRB200216A # GRB folder name which contains the tarred dataset

#echo "Whats the trigegr time?"
#read trigger_time
#trigger_time=603536865.4  # Trigger time in MET 
#603536865.4
#603536869.444

#---------------------------------------------------
n=5

grb_array=("GRB200216A" "GRB200228A" "GRB200325A" "GRB200405B" "GRB200623A" "GRB200714E" "GRB200716A" "GRB200809B" "GRB201008A" "GRB201128B" "GRB201216A" "GRB201228B" "GRB210323B" "GRB210421B" "GRB210605B" "GRB210606A" "GRB210622A" "GRB210626A" "GRB210706A" "GRB210827A")

triggertime_array=("603536869.444000" "604565937.511000" "606799135.656000" "607751642.718" "614575105.162000" "616444530.284000" "616555622.291000" "618680512.430000" "623846281.769000" "628278877.061000" "629838057.164000" "630861731.232000" "638193839.717000" "640695308.884000" "644597785.144000" "644644589.147000" "646018382.239000" "646388202.263000" "647252296.321000" "651751191.622000")

#arr=("GRB200809B")
grb_ele=${grb_array[n]}

#triggertime_array=("618680512.430000")

trigger_time=${triggertime_array[n]}
echo "starting"



#echo ${arr[0]}

j=0
echo "j outside=" $j

for i in "${grb_ele[@]}"

do 
	echo $i
	cd $i
	echo "------------------------"
	echo "un-tarring the dataset", $i
	echo "------------------------"
	tar -xvf *.tar
	cd 0*/bat/event
	ls *po_uf.evt.gz > filelist.txt
	cp ../../../../plot_code.py .


	inp=$(ls *shpo_uf.evt*)
	gunzip -k $inp  
	uncomp_inp=$(ls *shpo_uf.evt)
	maskfile=$(ls ../hk/sw*bdecb*)
	detmask=$(ls ../hk/sw*bdqcb.hk.gz)
	att=$(ls ../../auxil/sw*sat.fits*)

	#-----------------------------------------------------------
	echo " extract light curves in all bands"
	echo "j inside the lopp=" $j
	
#	trigger_time=${triggertime_array[j]} #commenting for now

	echo "trigger time = " $trigger_time

	num3=100.0
	num4=100.0

	tstart_lcurve=`expr "$trigger_time - $num3 " | bc`
	tstop_lcurve=`expr "$trigger_time + $num4 " | bc`


	batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-15-350keV.fits detmask=$detmask outtype=LC timedel=0.1 timebinalg=u energybins=15-350 weighted=NO outunits=COUNTS clobber=YES

	battblocks grb-lc-15-350keV.fits grb-bb-lc.fits durfile=burst_dur.gti

	# energy resolved light curves
	echo "Energy resolved light curves-------------"
	batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-15-25keV.fits detmask=$detmask outtype=LC timedel=0.1 timebinalg=u energybins=15-25 weighted=NO outunits=COUNTS clobber=YES

	batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-25-50keV.fits detmask=$detmask outtype=LC timedel=0.1 timebinalg=u energybins=25-50 weighted=NO outunits=COUNTS clobber=YES

	batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-50-100keV.fits detmask=$detmask outtype=LC timedel=0.1 timebinalg=u energybins=50-100 weighted=NO outunits=COUNTS clobber=YES


#	battblocks grb-lc-50-100keV.fits grb-bb-lc.fits durfile=burst_dur.gti

	batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-100-250keV.fits detmask=$detmask outtype=LC timedel=0.1 timebinalg=u energybins=100-250 weighted=NO outunits=COUNTS clobber=YES


	batbinevt tstart=$tstart_lcurve tstop=$tstop_lcurve infile=$inp outfile=grb-lc-250-350keV.fits detmask=$detmask outtype=LC timedel=0.1 timebinalg=u energybins=250-350 weighted=NO outunits=COUNTS clobber=YES


	# Using battblocks obtained peak algorithm to define start and stop time that is required as GTIs for spectra


	

	ftlist burst_dur.gti+1 include='TSTART' outfile=tstart.txt k
	tstart_gti=$(awk '{print $3}' tstart.txt)
	echo "Tstart gti=" $tstart_gti
	#tstart=653758790.500
	ftlist burst_dur.gti+1 include='TSTOP' outfile=tstop.txt k
	tstop_gti=$(awk '{print $3}' tstop.txt)
	#tstop=653758791.500
	echo "Tstop gti=" $tstop_gti
	

	duration=`expr "$tstop_gti - $tstart_gti " | bc`
	echo $i $duration >> ../../../../duration.txt	


	python plot_code.py

	echo "Saved energy reolved light curve fits files and image..."

	echo "------------------------"
	echo "trying maskweighting before spectrum stage..."
	echo "------------------------"

	#echo "making dpi..."
	batbinevt infile=$inp outfile=grb.dpi outtype=DPI timedel=0 timebinalg=u energybins=- weighted=NO outunits=COUNTS clobber=YES
	#echo "making hotpixel file grb.mask.."
	bathotpix infile=grb.dpi outfile=grb.mask detmask=$maskfile clobber=YES

	
	
	ra_array=("311.4378" "333.8928" "31.7203" "62.7894" "242.0952" "196.8656" "139.348" "15.9406" "161.744" "339.354" "201.4872" "35.5939" "259.664" "270.817" "15.732" "170.904" "233.117" "221.6199" "312.0124" "174.9181" )	
	dec_array=("-11.658" "-42.9443" "-31.816" "-51.5326" "53.4678" "-51.6403" "-16.712" "-73.8459" "46.101" "-49.246" "36.3116" "56.0148" "15.677" "56.828" "6.467" "0.718" "-26.213" "-1.1512" "13.3079" "55.7858")

	ra=${ra_array[n]}	

	dec=${dec_array[n]}	


#	ra=${ra_array[j]}
#	dec=${dec_array[j]}

	echo "RA=" $ra
	echo "Dec=" $dec



	batmaskwtevt detmask=grb.mask infile=$uncomp_inp attitude=$att ra=$ra dec=$dec clobber=YES auxfile=sw_bevtr.fits
	#batmaskwtevt detmask=master.detmask infile=$uncomp_inp attitude=$att ra=$ra dec=$dec clobber=YES
	#echo "------------------------"
	#echo "Finished BAT task batmaskwtevt (doesnt make a new file, just adds a maskwt column to the original event file.. ) "
	echo "------------------------"

	#echo "Extracting spectra for the GTI identified by battblocks..using maskweighted event file (again shady)..."

	batbinevt tstart=$tstart_gti tstop=$tstop_gti infile=$uncomp_inp outfile=src_spec.pha detmask=$detmask outtype=pha timedel=0 timebinalg=u energybins=CALDB:80

	num5=5.0

	tstop_gti_for_bkg=`expr "$tstart_gti - $num5 " | bc`



	batbinevt tstart=$tstop_gti_for_bkg tstop=$tstart_gti infile=$uncomp_inp outfile=bkg_spec.pha detmask=$detmask outtype=pha timedel=0 timebinalg=u energybins=CALDB:80

	#echo "spectra created"

	#echo "------------------------"

	#echo "Use aux file to update keywords.."

	batupdatephakw src_spec.pha sw_bevtr.fits
	batupdatephakw bkg_spec.pha sw_bevtr.fits

	#echo "Systematic error vector"

	batphasyserr src_spec.pha CALDB
	batphasyserr bkg_spec.pha CALDB

	batdrmgen src_spec.pha response.rsp NONE

	echo "corrections done to the spectra and response generated"

	echo "----------------------------"
	echo "Now go and fit in xspec"
	echo "----------------------------"

	cd ../../../../
	((j=j+1))	
done 












