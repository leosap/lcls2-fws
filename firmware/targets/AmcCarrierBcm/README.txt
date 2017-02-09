###############################################################################################################
File       : file:///afs/slac/g/reseng/svn/repos/LCLS_II/trunk/BCM/firmware/targets/AmcCarrierBcm/README.txt
Author     : Larry Ruckman <ruckman@slac.stanford.edu>
Company    : SLAC National Accelerator Laboratory
Created    : 2016-01-15
Last update: 2016-01-15
###############################################################################################################

The following is instructions of how to build the AmcCarrierBcm target firmware.
      
########################
## Building the firmware
########################

Step 1) Log into your favorite SLAC Linux server:
   - Example:
      $ ssh rdusr219 -YC

Step 2) Check out the subversion repository:
   - Note: This step IS REQUIRED if it has not be done before.
   - Example:
      rdusr219 ~$ cd $home/projects
      rdusr219 ~$ svn checkout file:///afs/slac/g/reseng/svn/repos/LCLS_II/trunk/trunk/BCM/ BCM
      
Step 3) Check that the subversion repository is up-to-date:
   - Example:
      rdusr219 ~$ cd $home/projects
      rdusr219 ~$ svn update BCM/
            
Step 4) Setup the firmware environment:      
   - Example:
      rdusr219 ~$ cd $home/projects/BCM/firmware/
      rdusr219 ~$ source setup_env.csh 
   - Note: This .csh script will do the following:
      A) Makes an output build directory in the Linux server's /u1 hard drive mount
      B) Makes a symbolic link from this checkout SVN source tree 
         to the /u1's output build directory
      C) Sets up your Xilinx licensing
      
Step 5) Compile the firmware code:
   - Example:   
      rdusr219 ~$ cd $home/projects/BCM/firmware/targets/AmcCarrierBcm/
      rdusr219 ~$ make clean; make

########################################################################      
## At this point, two files will be copied into the 
## $home/projects/BCM/firmware/targets/AmcCarrierBcm/image directory: 
##    AmcCarrierBcm_XXXXXXXX.bit
##    AmcCarrierBcm_XXXXXXXX.mcs
## where XXXXXXXX is the firmware FPGA_VERSION_C constant in the 
## $home/projects/BCM/firmware/targets/AmcCarrierBcm/version.vhd file.
## The .bit file is the FPGA programming file.  
## The .mcs file is the FPGA's boot PROM programming file.       
########################################################################      

Optional Step 6) View your Vivado project in GUI mode
   - Example:   
      rdusr219 ~$ cd $home/projects/BCM/firmware/targets/AmcCarrierBcm/
      rdusr219 ~$ make gui
      