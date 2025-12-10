# Photom-Anterior_Insula_Conflict

This repository contains the analysis code and figures for the publication listed above. 
1. BTN_1_ extracts the data and divides them into traces based on the timestamps saved by TDT.
2. BTN_2_ sorts traces and combines them where necessary. It also performs z-scoring of the traces
3. BTN_3_ The main plotting scripts. The collect the relevant data for a given trial type, performs the statistics, and plots these as output
   - Calls createComparisonPlot.m for the actual plotting
5. BTN_4_ Calculates mean of the zScore traces in defined time windows