#This script is to get ROI localized, compute depthmaps etc. 
subj=3

study_dir="${HOME}/Desktop/ALS_study"
printf -v results_dir "${study_dir}/S%02d/results" ${subj}
printf -v analysisDir "${study_dir}/analyzed/S%02d" ${subj}
outputDir=${analysisDir}/getROI
#mkdir ${outputDir}

cd ${outputDir}
#Get resampled mean EPI image both magn and phase (phase has nice contrast for segmentation):
#Magn:
cp ${results_dir}/getT1weighted/mean_rnoNORDIC_BOLD_01magn.nii ${outputDir}
3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix mean_rnoNORDIC_BOLD_01magn_resample.nii -input mean_rnoNORDIC_BOLD_01magn.nii

#Phase:
3dTstat -mean -prefix mean_cleaned_crNORDIC1_BOLD_01phase.nii ${results_dir}/cleaned_crNORDIC1_BOLD_01phase.nii'[0..19]'
3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix mean_cleaned_crNORDIC1_BOLD_01phase_resample.nii -input mean_cleaned_crNORDIC1_BOLD_01phase.nii


#Get mean activation maps:
3dTstat -mean -prefix tmp_mean_active_01.nii ${analysisDir}/extraMaps/betas_cleanedMagn_active_NORDIC1.nii'[0..11]'
3dTstat -mean -prefix tmp_mean_active_02.nii ${analysisDir}/extraMaps/betas_cleanedMagn_active_NORDIC1.nii'[12..23]'

3dTstat -mean -prefix tmp_mean_passive_01.nii ${analysisDir}/extraMaps/betas_cleanedMagn_passive_NORDIC1.nii'[0..11]'
3dTstat -mean -prefix tmp_mean_passive_02.nii ${analysisDir}/extraMaps/betas_cleanedMagn_passive_NORDIC1.nii'[12..23]'

3dmean -prefix beta_meanActivePassive_01_NORDIC1.nii tmp_mean_active_01.nii tmp_mean_passive_01.nii
3dmean -prefix beta_meanActivePassive_02_NORDIC1.nii tmp_mean_active_02.nii tmp_mean_passive_02.nii

3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix beta_meanActivePassive_01_NORDIC1_resample.nii -input beta_meanActivePassive_01_NORDIC1.nii
3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix beta_meanActivePassive_02_NORDIC1_resample.nii -input beta_meanActivePassive_02_NORDIC1.nii


# #=========== Get rim file, compute layers==========#:
#Get rim. I use 0.72 to extend a bit into WM and i use 0.265 to extend a bit into CSF. This file needs manual correction.  
matlab -r "getRim_ALS_study(0.72,0.265,'../depth_map_resample.nii'); quit;"

#Draw segmentation and get layers:
LN2_LAYERS -rim segmentation.nii -nr_layers 10 -equivol







trash ./tmp*.nii
