

Jan 26th 2022

Sorted several issues with running NITRATES latest pulled git version in the branch timepass (I should rename it).

Make sure you run run_grb2_open.sh which uses do_manage2_open.py if you want to use the open queue. 
Virtual core issue not yet resolved as of today, so that doesnt work.

Email sending works.
RATES jobs work, inFoV jobs work - Max TS all good. Need to still verify outFoV jobs
New responses are located here: /gpfs/group/jak51/default/responses/
No need to access scratch contents.
Outputs are stored: /storage/home/gzr5209/work/realtime_workdir/results 

Some weird issue: manager.log stop logging at some point even though code keeps running. 

Testing code on GRB220117 and GRB211219A





