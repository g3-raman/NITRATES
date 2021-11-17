import numpy as np
import matplotlib.pyplot as plt
import astropy
import scipy
from astropy.io import fits
from numpy import *
import glob

from astropy.timeseries import LombScargle



#filelist=['/home/g3r/Post-doc/Postdoc_PSU/BAT_analysis/GRB200325A/00059179002/bat/event/grb-lc-15-30keV.fits','/home/g3r/Post-doc/Postdoc_PSU/BAT_analysis/GRB200325A/00059179002/bat/event/grb-lc-30-50keV.fits','/home/g3r/Post-doc/Postdoc_PSU/BAT_analysis/GRB200325A/00059179002/bat/event/grb-lc-50-150keV.fits','/home/g3r/Post-doc/Postdoc_PSU/BAT_analysis/GRB200325A/00059179002/bat/event/grb-lc-150-300keV.fits']

filelist=['grb-lc-15-25keV.fits','grb-lc-25-50keV.fits','grb-lc-50-100keV.fits','grb-lc-100-250keV.fits','grb-lc-250-350keV.fits', 'grb-lc-15-350keV.fits']

legends=['15-25 keV','25-50 keV','50-100 keV','100-250 keV','250-350 keV','15-350 keV']
#print(legends[0])

fig,axes = plt.subplots(nrows=len(filelist),sharex=True,ncols=1,figsize=(10,12))
   
#print(filelist)



for i,filename in enumerate(filelist):

#	print(filename.split('event')[1].split('.fits'))
	file=astropy.io.fits.open(filename)



	dataa=file['RATE'].data
	time=dataa.field(0)
	rate=dataa.field(1)
	err=dataa.field(2)


	axes[i].step(time,rate,ms=3,label=legends[i])
	axes[i].set_ylabel('rate(c/s)',fontsize=15)
	axes[i].legend()
	axes[i].tick_params(axis='both', labelsize=15)

axes[5].set_xlabel('time(s)',fontsize=15)


plt.tight_layout()
#plt.show()
fig.savefig('energy-resolved-lcs.png')

