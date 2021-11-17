#!/bin/sh
# Script to carry out automated BAT imaging analysis 

# v1. July 22, 2021 - Gayathri Raman

# Script wont take heainit - dont know why, so initiate heainit before you run this script
# Be on the location just above the GRB data folder
# Download the GRB event data folder
# Removed the usage of parameter files and specified details right here- you can hose to generate a dpi or spectrum or light curve..make sure you change the batbinevt line here accordingly



#heainit
folder=GRB200325A

cd $folder
echo "------------------------"
echo "un-tarring the dataset"
echo "------------------------"
tar -xvf *.tar
cd 0*/bat/event
#cp ../../../../inp1.txt .
ls *po_uf.evt.gz > filelist.txt
echo "------------------------"
echo "Starting all BAT codes"
echo "------------------------"
echo "------------------------"
echo "Running batbinevt and generating the dpi"
echo "------------------------"
#batbinevt < inp1.txt # can avoid usage of parameter files by running full command line tasks
inp=$(ls *shpo_uf.evt*)
batbinevt infile=$inp outfile=grb.dpi outtype=DPI timedel=0 timebinalg=u energybins=- weighted=NO outunits=COUNTS clobber=YES
echo "------------------------"
echo "Finished  BAT tasks - batbinevt"
echo "------------------------"
#cp ../../../../inp_mask.txt .
# commenting this step for now
maskfile=$(ls ../hk/sw*bdecb*)
detmask=$(ls ../hk/sw*bdqcb.hk.gz)
#batdetmask date=total.dpi outfile=master.detmask clobbe=YES detmask=$maskfile
#echo "------------------------"
#echo "Finished  BAT tasks - batbinevt batdetmask"
echo "------------------------"
#bathotpix detmask=../hk/sw00039764004bdecb.hk.gz < inp_mask.txt
#bathotpix infile=total.dpi outfile=total.qmap detmask=master.detmask clobber=YES
bathotpix infile=grb.dpi outfile=grb.mask detmask=$maskfile clobber=YES
echo "------------------------"
echo "Finished  BAT task batbinevt and bathotpix"
echo "------------------------"
echo "------------------------"
att=$(ls ../../auxil/sw*sat.fits*)
#ra=
#dec=
# SO this works.. now to get only the value to a variable
echo "------------------------"
gunzip -k $inp  # De-compressing input file for this step..it doesnt run otherwise
uncomp_inp=$(ls *shpo_uf.evt)
ftlist $inp+1 k include='RA_OBJ' outfile=ra.txt
ftlist $inp+1 k include='DEC_OBJ' outfile=dec.txt
ra=$(awk '{print $3}' ra.txt)
dec=$(awk '{print $3}' dec.txt)
batmaskwtevt detmask=grb.mask infile=$uncomp_inp attitude=$att ra=$ra dec=$dec clobber=YES
#batmaskwtevt detmask=master.detmask infile=$uncomp_inp attitude=$att ra=$ra dec=$dec clobber=YES
echo "------------------------"
echo "Finished BAT task batmaskwtevt also"
echo "------------------------"

echo "Not Generating images - batbinevt and batfftimage"
#batbinevt detmask=grb.mask infile=$uncomp_inp outfile=grb_4.dpi outtype=DPI timedel=0 timebinalg=u energybins=15-25, 25-50, 50-100, 100-350

#batfftimage detmask=grb.mask infile=$uncomp_inp outfile=grb_4.img attitude=$att pcodemap=yes pcodethresh=0.01

#echo "------------------------"
#echo "batfftimage also done"
#echo "------------------------"

echo "Generating light curves in different energy bands - 15-50,50-100,100-150 keV"
echo "Using batbinevt again.."
# Note: the uncompressed .evt file contains a new column called MAST WT

#batbinevt infile=$uncomp_inp outfile=lightcurve15-50keV.lc outtype=LC timedel=0.1 timebinalg=u energybins=15-50 detmask=grb.mask clobber=YES

#batbinevt infile=$uncomp_inp outfile=lightcurve50-100keV.lc outtype=LC timedel=0.1 timebinalg=u energybins=50-100 detmask=grb.mask clobber=YES

#batbinevt infile=$uncomp_inp outfile=lightcurve100-150keV.lc outtype=LC timedel=0.1 timebinalg=u energybins=100-150 detmask=grb.mask clobber=YES

batbinevt infile=$uncomp_inp outfile=lightcurve15-50keV.lc outtype=LC timedel=0.1 timebinalg=u energybins=15-50 detmask=$detmask clobber=YES

batbinevt infile=$uncomp_inp outfile=lightcurve50-100keV.lc outtype=LC timedel=0.1 timebinalg=u energybins=50-100 detmask=$detmask clobber=YES

batbinevt infile=$uncomp_inp outfile=lightcurve100-150keV.lc outtype=LC timedel=0.1 timebinalg=u energybins=100-150 detmask=$detmask clobber=YES

echo "------------------------"
echo "Multi-band light curves created"
echo "------------------------"

pwd 

#cd $folder/*/bat/event
#ls *.lc > lightcurves.lis
#lcurve nser=1 cfile1="@lightcurves.lis" window="-" dtnb=0.2 nbint=200000 outfile="-" plot=yes plotdev="/xw"












