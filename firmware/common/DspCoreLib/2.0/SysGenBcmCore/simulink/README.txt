##################################################################################################
File       : file:///afs/slac/g/reseng/svn/repos/LCLS_II/trunk/BCM/firmware/modules/DspCoreLib/SysGenBcmCore/simulink/README.txt
Author     : Larry Ruckman <ruckman@slac.stanford.edu>
Company    : SLAC National Accelerator Laboratory
Created    : 2016-02-26
Last update: 2016-02-26
##################################################################################################

#############################
## Building the SysGen Target
#############################

Step 1) Log into a SLAC System Generator Linux server (either rdusr217 or rdusr219):
   - Example:
      $ ssh rdusr219 -YC

Step 2) Check out the subversion repository:
   - Note: This step IS REQUIRED if it has not be done before.
   - Example:
      rdusr219 ~$ cd $home/projects
      rdusr219 ~$ svn checkout file:///afs/slac/g/reseng/svn/repos/LCLS_II/trunk/BCM/ BCM
      
Step 3) Check that the subversion repository is up-to-date:
   - Example:
      rdusr219 ~$ cd $home/projects
      rdusr219 ~$ svn update BCM/

Step 4) Setup the SysGen environment:      
   - Example:
      rdusr219 ~$ cd $home/projects/BCM/firmware/modules/DspCoreLib/
      rdusr219 ~$ source setup_env.csh 

Step 5) Open the System Generator Software
   - Example:   
      rdusr219 ~$ cd $home/projects/BCM/firmware/modules/DspCoreLib/SysGenBcmCore/simulink/
      rdusr219 ~$ sysgen
      
Step 6) Open the System Generator file
   A) Double click on "SysGenBcmCore.slx" on the left-hand side file navigator
   B) A System Generator GUI will pop up
   
Step 7) Develop and test the DSP core 
   - Example:  Add or remove ports
   - Example:  Matlab simulation
   
Step 8) Generate the Synthesized Checkpoint (.dcp) file
   A) Double click on the "System Generator" ICON
   B) In "Compilation", select the "Synthesized Checkpoint" option, then click "Apply" button
   C) Then click "Generate" button
   D) Wait for the compilation to complete
   
Step 9) Close the System Generator Software 
   A) Save your progress (CTRL + S)
   B) Close the System Generator GUI window
   B) Close the Matlab GUI window
   
Step 10) If you are ready to release, commit the code to SVN repository
   - Example:   
      rdusr219 ~$ cd $home/projects/BCM/firmware/modules/DspCoreLib/SysGenBcmCore/
      rdusr219 ~$ svn commit -m "Insert your commit message here"

###############################
## Building the Firmware Target
###############################

Step 1) Log into a SLAC System Generator Linux server (either rdusr217 or rdusr219):
   - Example:
      $ ssh rdusr219 -YC

Step 2) Check out the subversion repository:
   - Note: This step IS REQUIRED if it has not be done before.
   - Example:
      rdusr219 ~$ cd $home/projects
      rdusr219 ~$ svn checkout file:///afs/slac/g/reseng/svn/repos/LCLS_II/trunk/BCM/ BCM
      
Step 3) Check that the subversion repository is up-to-date:
   - Example:
      rdusr219 ~$ cd $home/projects
      rdusr219 ~$ svn update BCM/

Step 4) Setup the Vivado environment:      
   - Example:
      rdusr219 ~$ cd $home/projects/BCM/firmware/
      rdusr219 ~$ source setup_env.csh 

Step 5) Compile the .BIT and .MCS file
   - Example:   
      rdusr219 ~$ cd $home/projects/BCM/firmware/targets/AmcCarrierBcm/
      rdusr219 ~$ make
            
      At this point, two files will be copied into the 
      $home/projects/BCM/firmware/targets/AmcCarrierBcm/image directory: 
         AmcCarrierBcm_XXXXXXXX.bit
         AmcCarrierBcm_XXXXXXXX.mcs
      where XXXXXXXX is the firmware FPGA_VERSION_C constant in the 
      $home/projects/BCM/firmware/targets/AmcCarrierBcm/version.vhd file.
      The .bit file is the FPGA programming file.  
      The .mcs file is the FPGA's boot PROM programming file.        
      
Step 6) Optional: After compiling the .BIT and .MCS file, review the FPGA design report via the GUI:
   - Example:   
      rdusr219 ~$ cd $home/projects/BCM/firmware/targets/AmcCarrierBcm/
      rdusr219 ~$ make gui