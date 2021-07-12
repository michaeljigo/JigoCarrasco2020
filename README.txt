These directories contain the raw data and behavioral analyses for the paper:

            Michael Jigo, Marisa Carrasco; Differential impact of exogenous and endogenous attention 
            on the contrast sensitivity function across eccentricity. Journal of Vision 2020;20(6):11. 
            doi: https://doi.org/10.1167/jov.20.6.11.


-----------------------------------------
---------- Recreate figures -------------
-----------------------------------------

All necessary functions are located in the "analyses" directory for the respective experiment.

To recreate a figure run the command within the square brackets:
   Experiment 1:
      - Figure 3a    [figure3('exo')]
      - Figure 3b    [figure3('endo')]
      - Figure 4a    [figure4('exo')]
      - Figure 4b    [figure4('endo')]
      - Figure 5     [figure5]
      - Figure 6a    [figure6('exo')]
      - Figure 6b    [figure6('endo')]
   
   Experiment 2:
      - Figure 8     [figure8]
      - Figure 9     [figure9]
      - Figure 10a   [figure10('exo')]
      - Figure 10b   [figure10('endo')]
      - Figure 4b    [figure4('endo')]
      - Figure 5     [figure5]
      - Figure 6a    [figure6('exo')]
      - Figure 6b    [figure6('endo')]



-----------------------------------------
------------- Data analyses -------------
-----------------------------------------

All necessary functions are located in the "analyses" directory for the respective experiment.

To re-run data fitting, run the command "do_fits".



-----------------------------------------
---------- Directory structure ----------
-----------------------------------------

Each directory (exp1, exp2) has the following structure:
Key: |--  = directory branch
     |--> = description of files contained in directory

|-- exp1
|   |-- endo
|   |   |-- data 
|   |   |   |-- subdirectories contain MGL output (.stim), eyetracking (.edf) files
|   |   |   |   |-- fullModel
|   |   |   |       |--> best-fitting model parameters (.mat) to recreate figures in paper
|   |   |   |   
|   |   |-- stim
|   |   |   |--> functions (.m) that run the experimental protocol
|   |   |
|   |   |
|   |-- exo (identical structure as endo above)
|   |   |
|   |   |
|   |-- analyses
|   |   |-> functions that perform analyses and recreate figures in the paper.
|   |   |-- helperFun
|   |   |   |--> functions (.m) that facilitate the main analyses
|   |
|-- manuscript
|   |-> final manuscript files (and drafts)


Experiment 1 (exp1) and Experiment 2 (exp2) have an identical directory structure.
