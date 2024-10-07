subject=(3)

for subj in ${subject[@]}; do
## ==================== Coregister T1 to EPI (ANTS) =================#
study_dir="${HOME}/Desktop/ALS_study"
printf -v results_dir "${study_dir}/S%02d/results" ${subj}
printf -v analysisDir "${study_dir}/analyzed/S%02d" ${subj}

cd ${results_dir}

# Call ANTS registration after manually making the initial parameter file called initial_matrix.txt. This is the estimation step:
#https://github.com/ANTsX/ANTs/wiki/Anatomy-of-an-antsRegistration-call
antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 1 \
--output [registered_,registered_Warped.nii.gz,registered_InverseWarped.nii.gz] \
--interpolation BSpline[5] \
--use-histogram-matching 0 \
--initial-moving-transform ${analysisDir}/initial_matrix.txt \
--winsorize-image-intensities [0.005,0.995] \
--transform Rigid[0.05] \
--metric MI[${analysisDir}/T1_weighted.nii,./MP2RAGE.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
--transform Affine[0.1] \
--metric MI[${analysisDir}/T1_weighted.nii,./MP2RAGE.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
--transform SyN[0.1,2,0] \
--metric CC[${analysisDir}/T1_weighted.nii,./MP2RAGE.nii,1,2] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox



#Apply the transforms and reslice:
antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./MP2RAGE.nii \
-r ${analysisDir}/T1_weighted.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o T1_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./MP2RAGE.nii \
-r ${analysisDir}/T1_weighted_resample.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o T1_al_resample.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./MP2RAGE.nii \
-r ./MP2RAGE.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o T1_al_origGrid.nii

#Move coregistered T1 to analysis directoy
mv ./T1_al*nii ${analysisDir}

done