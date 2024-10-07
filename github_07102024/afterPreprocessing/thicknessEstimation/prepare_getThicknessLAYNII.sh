#Prepare the files needed to get cortical thickness in hand knob ROI
subj=2
printf -v analysisDir "/Users/au686880/Desktop/ALS_study/analyzed/S%02d/getROI" ${subj}
outputDir=${analysisDir}/thickness
cd ${outputDir}

#Get thickness with laynii. First resample segmentation file to 0.2 mm iso, then compute thickness and then resample thickness file back. 
#100 smoothing iterations should be reasonable. 
3dresample -dxyx 0.2 0.2 0.2 -rmode NN -prefix ${outputDir}/segmentation_resampleIso.nii -input ${analysisDir}/segmentation.nii
LN2_LAYERS -rim segmentation_resampleIso.nii -thickness -iter_smooth 100
3dresample -master ${analysisDir}/ROI1.nii -rmode NN -prefix thickness.nii -input segmentation_resampleIso_thickness.nii

