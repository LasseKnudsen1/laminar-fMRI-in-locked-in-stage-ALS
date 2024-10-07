#This script is to evaluate mean percent signal change within large M1 ROI, large S1 ROI and 3 random control regions. 
#I first get fresh rim-file (the one from column smooth is only middle/deep layers and the one for layer profiles is manually corrected with destruction of S1).
#Then I manually define ROI IN FSLeyes and remainder of analysis is done in prepare_getProfiles_ALS_study.m and getProfiles_ALS_study.m
subject=(1 2 3)
for subj in ${subject[@]} ; do  
	printf -v analysisDir "${HOME}/Desktop/ALS_study/analyzed/S%02d" ${subj}
	printf -v outputDir "${HOME}/Desktop/ALS_study/M1S1ControlAnalysis/S%02d" ${subj}
	cd ${outputDir}

#Get rim. I use 0.66 and 0.33 to only get voxels estimated to be GM:
matlab -r "getRim_ALS_study(0.66,0.33,'${analysisDir}/depth_map_resample.nii'); quit;"

#Rename
mv ./segmentationGuide.nii ./M1S1Control_rim.nii
done