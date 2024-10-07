subject=(3)
versions=("noNORDIC" "NORDIC" "NORDIC1")

for subj in ${subject[@]}; do
study_dir="${HOME}/Desktop/ALS_study"
printf -v results_dir "${study_dir}/S%02d/results" ${subj}
printf -v analysisDir "${study_dir}/analyzed/S%02d" ${subj}
cd ${results_dir}
mkdir ${analysisDir}/extraMaps

for version in ${versions[@]}; do
## ==================== scale timeseries ==================== ##
# Scale each voxel time series to have a mean of 100
# Be sure no negatives creep in, and subject to a range of [0,200]
# Apply extents mask again after smoothing
#.volreg vs .blur. To get clear retinotopic map, it is better not to smooth in volume
for run in 01 02; do
    3dTstat -prefix tmp.mean.nii -overwrite \
        -mean r${version}_BOLD_${run}magn.nii

    3dTstat -prefix tmp.mean_micro.nii -overwrite \
        -mean micro_r${version}_BOLD_${run}magn.nii
    
    3dTstat -prefix tmp.mean_cleanedMagn.nii -overwrite \
        -mean cleaned_r${version}_BOLD_${run}magn.nii

    3dcalc -a r${version}_BOLD_${run}magn.nii -b tmp.mean.nii \
        -expr 'min(200, a/b*100)*step(a)*step(b)' \
        -prefix tmp.scaled_r${version}_BOLD_${run}magn.nii -overwrite

    3dcalc -a micro_r${version}_BOLD_${run}magn.nii -b tmp.mean_micro.nii \
        -expr 'min(200, a/b*100)*step(a)*step(b)' \
        -prefix tmp.scaled_micro_r${version}_BOLD_${run}magn.nii -overwrite

    3dcalc -a cleaned_r${version}_BOLD_${run}magn.nii -b tmp.mean_cleanedMagn.nii \
        -expr 'min(200, a/b*100)*step(a)*step(b)' \
        -prefix tmp.scaled_cleaned_r${version}_BOLD_${run}magn.nii -overwrite
done

## ==================== Run GLM to get betas ==================== ##
#Note that polort 0 means only implement constant regressor, dont add regressors fr low frequency noise like drifts (already projected out in create_micro_macro.
#stim_times_IM means estimate a beta for each block.
TR=2.2  

 3dDeconvolve \
     -force_TR $TR -mask brainmaskCorrected.nii \
     -input tmp.scaled_micro_r${version}_BOLD_01magn.nii tmp.scaled_micro_r${version}_BOLD_02magn.nii \
     -polort 0 \
     -local_times \
     -num_stimts 2 \
     -stim_times_IM 1 ~/Desktop/fMRI_analysis/scripts/ALS_study/stim_times_attempted.txt 'BLOCK(22,1)' \
     -stim_label 1 AttemptedTap \
     -stim_times_IM 2 ~/Desktop/fMRI_analysis/scripts/ALS_study/stim_times_passive.txt 'BLOCK(22,1)' \
     -stim_label 2 PassiveTap \
     -jobs 4 \
     -xjpeg designMat \
     -nofullf_atall \
     -bucket tmp.betas_micro_${version}.nii \
     -overwrite

 3dDeconvolve \
     -force_TR $TR -mask brainmaskCorrected.nii \
     -input tmp.scaled_cleaned_r${version}_BOLD_01magn.nii tmp.scaled_cleaned_r${version}_BOLD_02magn.nii \
     -polort 0 \
     -local_times \
     -num_stimts 2 \
     -stim_times_IM 1 ~/Desktop/fMRI_analysis/scripts/ALS_study/stim_times_attempted.txt 'BLOCK(22,1)' \
     -stim_label 1 AttemptedTap \
     -stim_times_IM 2 ~/Desktop/fMRI_analysis/scripts/ALS_study/stim_times_passive.txt 'BLOCK(22,1)' \
     -stim_label 2 PassiveTap \
     -jobs 4 \
     -xjpeg designMat \
     -nofullf_atall \
     -bucket tmp.betas_cleanedMagn_${version}.nii \
     -overwrite


## ==================== Get betas file each condition ==================== ##
3dTcat -prefix betas_micro_active_${version}.nii tmp.betas_micro_${version}.nii'[0..23]'
3dTcat -prefix betas_micro_passive_${version}.nii tmp.betas_micro_${version}.nii'[24..47]'

3dTcat -prefix betas_cleanedMagn_active_${version}.nii tmp.betas_cleanedMagn_${version}.nii'[0..23]'
3dTcat -prefix betas_cleanedMagn_passive_${version}.nii tmp.betas_cleanedMagn_${version}.nii'[24..47]'


## ==================== Calculate tSNR maps ==================== ##
3dtstat -cvarinv -prefix tsnr_${version}_r.nii r${version}_BOLD_01magn.nii

## ==================== Resample betas maps ==================== ##
3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix betas_micro_active_${version}_resample.nii -input betas_micro_active_${version}.nii
3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix betas_micro_passive_${version}_resample.nii -input betas_micro_passive_${version}.nii

3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix betas_cleanedMagn_active_${version}_resample.nii -input betas_cleanedMagn_active_${version}.nii
3dresample -master ${analysisDir}/T1_weighted_resample.nii -rmode Cu -prefix betas_cleanedMagn_passive_${version}_resample.nii -input betas_cleanedMagn_passive_${version}.nii

