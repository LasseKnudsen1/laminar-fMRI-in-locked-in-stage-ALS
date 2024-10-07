Analysis code used in "Laminar fMRI in the locked-in stage of amyotrophic lateral sclerosis shows preserved activity in layer Vb of primary motor cortex" (uploaded 07102024)

Code used for preprocessing is in the root directory (follow Pipeline_ALS_study.m), which describes the order step by step. 

afterPreprocessing folder contains code used to generate laminar profiles and run statistical analyses (prepare_getProfiles_ALS_Study, getProfiles_ALS_study, permutation_test_4twoSidedALS_study) and some additional scripts to prepare segmentations, depth maps and ROIs (getROI, testSegmentationLocation, getRim_ALS_study, M1S1ControlAnalysis.sh). 

The highresMP2RAGE folder contains scripts to prepare and align quantitative T1 maps to EPI space. The thicknessEstimation folder contains scripts to estimate cortical thickness in an ROI. 

If questions or similar, please feel free to contact Lasse Knudsen at lasse.knudsen96@gmail.com