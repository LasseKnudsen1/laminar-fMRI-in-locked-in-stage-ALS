subject=(3)

for subj in ${subject[@]}; do
#set paths
study_dir="${HOME}/Desktop/ALS_study"
printf -v results_dir "${study_dir}/S%02d/results" ${subj}
printf -v analysisDir "${study_dir}/analyzed/S%02d" ${subj}

## ==================== Coregister cat12 to EPI (ANTS) =================#
cd ${results_dir}
#Apply the transforms and reslice:
antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./segmentation/p1MP2RAGE_mat0corrected.nii \
-r ${analysisDir}/T1_weighted_resample.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o ${analysisDir}/GM_resample.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./segmentation/p2MP2RAGE_mat0corrected.nii \
-r ${analysisDir}/T1_weighted_resample.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o ${analysisDir}/WM_resample.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./segmentation/p3MP2RAGE_mat0corrected.nii \
-r ${analysisDir}/T1_weighted_resample.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o ${analysisDir}/CSF_resample.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./segmentation/lh.ppMP2RAGE_mat0corrected.nii \
-r ${analysisDir}/T1_weighted_resample.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o ${analysisDir}/depth_map_resample.nii
done

