# lcls2-bcm
LCLS-II BCM Project for HPS common platform.

HPS common platform documentation can be found here:

> https://confluence.slac.stanford.edu/display/ppareg/LCLS-II+HPS+Common+Platform%3A+Documentation

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) Email Ben Reese (https://github.com/bengineerd) your github username and request to be added to the "lcls-hps" github group
> https://github.com/orgs/slaclab/teams/lcls-hps/repositories

3) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

4) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

5) Setup for large filesystems on github
> $ git lfs install

# Clone the GIT repository
> $ git clone --recursive git@github.com:slaclab/lcls2-bcm

# How to build the firmware

1) Setup Xilinx licensing
> In C-Shell: $ source lcls2-bcm/firmware/setup_env_slac.csh

> In Bash:    $ source lcls2-bcm/firmware/setup_env_slac.sh

2) If not done yet, make a symbolic link to the firmware/
> $ ln -s /u1/$USER/build lcls2-bcm/firmware/build

3) Go to the target directory and make the firmware:
> $ cd lcls2-bcm/firmware/targets/AmcCarrierBcm/
> $ make

4) Optional: Review the results in GUI mode
> $ make gui
