#28-11-2023: This code is to align ALS patient high-res MP2RAGE data from session 2 to the first session so we can get T1 profiles. 

study_dir="${HOME}/Desktop/ALS_study/analyzed/S01/highResMP2RAGE"
cd ${study_dir}

## ==================== Run deobloque to avoid problems with transformation matrices =================#
3drefit -deoblique ./MP2RAGE*.nii
3drefit -deoblique ./T1map*.nii
3drefit -deoblique ./M0map*.nii

## ==================== Coregister highres3 and highres 2 to highres1 =================#
#First find parameters from highres1 to lowres_sess2:
antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 1 \
--output [./transforms/registered2to1_,./transforms/registered_Warped2to1.nii.gz,./transforms/registered_InverseWarped2to1.nii.gz] \
--interpolation BSpline[5] \
--use-histogram-matching 0 \
--winsorize-image-intensities [0.005,0.995] \
--transform Rigid[0.05] \
--metric MI[MP2RAGE1.nii,MP2RAGE2.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmask.nii \
--transform Affine[0.1] \
--metric MI[MP2RAGE1.nii,MP2RAGE2.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmask.nii \
--transform SyN[0.1,2,0] \
--metric MI[MP2RAGE1.nii,MP2RAGE2.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmask.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./MP2RAGE2.nii \
-r ./MP2RAGE1.nii \
-t ./transforms/registered2to1_1Warp.nii.gz \
-t ./transforms/registered2to1_0GenericAffine.mat \
-o tmp_MP2RAGE2_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./T1map2.nii \
-r ./MP2RAGE1.nii \
-t ./transforms/registered2to1_1Warp.nii.gz \
-t ./transforms/registered2to1_0GenericAffine.mat \
-o tmp_T1map2_al.nii

antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 1 \
--output [./transforms/registered3to1_,./transforms/registered_Warped3to1.nii.gz,./transforms/registered_InverseWarped3to1.nii.gz] \
--interpolation BSpline[5] \
--use-histogram-matching 0 \
--winsorize-image-intensities [0.005,0.995] \
--transform Rigid[0.05] \
--metric MI[MP2RAGE1.nii,MP2RAGE3.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmask.nii \
--transform Affine[0.1] \
--metric MI[MP2RAGE1.nii,MP2RAGE3.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmask.nii \
--transform SyN[0.1,2,0] \
--metric MI[MP2RAGE1.nii,MP2RAGE3.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmask.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./MP2RAGE3.nii \
-r ./MP2RAGE1.nii \
-t ./transforms/registered3to1_1Warp.nii.gz \
-t ./transforms/registered3to1_0GenericAffine.mat \
-o tmp_MP2RAGE3_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./T1map3.nii \
-r ./MP2RAGE1.nii \
-t ./transforms/registered3to1_1Warp.nii.gz \
-t ./transforms/registered3to1_0GenericAffine.mat \
-o tmp_T1map3_al.nii


## ==================== Compute mean across all highres and align to T1_al from sess1 =================#
3dmean -prefix tmp_meanMP2RAGE.nii MP2RAGE1.nii tmp_MP2RAGE2_al.nii tmp_MP2RAGE3_al.nii

antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 1 \
--output [./transforms/registeredMeanToEPI_,./transforms/registered_WarpedMeanToEPI.nii.gz,./transforms/registered_InverseWarpedMeanToEPI.nii.gz] \
--interpolation BSpline[5] \
--use-histogram-matching 0 \
--initial-moving-transform ./initial_matrix_MeanToEPI.txt \
--winsorize-image-intensities [0.005,0.995] \
--transform Rigid[0.05] \
--metric MI[../T1_al.nii,tmp_meanMP2RAGE.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmaskEPI.nii \
--transform Affine[0.1] \
--metric MI[../T1_al.nii,tmp_meanMP2RAGE.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmaskEPI.nii \
--transform SyN[0.1,2,0] \
--metric CC[../T1_al.nii,tmp_meanMP2RAGE.nii,1,2] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x brainmaskEPI.nii


antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i MP2RAGE1.nii \
-r ../T1_al_resample.nii \
-t ./transforms/registeredMeanToEPI_1Warp.nii.gz \
-t ./transforms/registeredMeanToEPI_0GenericAffine.mat \
-o MP2RAGE1_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i T1map1.nii \
-r ../T1_al_resample.nii \
-t ./transforms/registeredMeanToEPI_1Warp.nii.gz \
-t ./transforms/registeredMeanToEPI_0GenericAffine.mat \
-o T1map1_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i MP2RAGE2.nii \
-r ../T1_al_resample.nii \
-t ./transforms/registeredMeanToEPI_1Warp.nii.gz \
-t ./transforms/registeredMeanToEPI_0GenericAffine.mat \
-t ./transforms/registered2To1_1Warp.nii.gz \
-t ./transforms/registered2To1_0GenericAffine.mat \
-o MP2RAGE2_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i T1map2.nii \
-r ../T1_al_resample.nii \
-t ./transforms/registeredMeanToEPI_1Warp.nii.gz \
-t ./transforms/registeredMeanToEPI_0GenericAffine.mat \
-t ./transforms/registered2To1_1Warp.nii.gz \
-t ./transforms/registered2To1_0GenericAffine.mat \
-o T1map2_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i MP2RAGE3.nii \
-r ../T1_al_resample.nii \
-t ./transforms/registeredMeanToEPI_1Warp.nii.gz \
-t ./transforms/registeredMeanToEPI_0GenericAffine.mat \
-t ./transforms/registered3To1_1Warp.nii.gz \
-t ./transforms/registered3To1_0GenericAffine.mat \
-o MP2RAGE3_al.nii

antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i T1map3.nii \
-r ../T1_al_resample.nii \
-t ./transforms/registeredMeanToEPI_1Warp.nii.gz \
-t ./transforms/registeredMeanToEPI_0GenericAffine.mat \
-t ./transforms/registered3To1_1Warp.nii.gz \
-t ./transforms/registered3To1_0GenericAffine.mat \
-o T1map3_al.nii


