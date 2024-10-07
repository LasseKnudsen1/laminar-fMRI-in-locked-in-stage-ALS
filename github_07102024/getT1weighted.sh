subject=(3)

for subj in ${subject[@]} ; do 
#set paths
study_dir="${HOME}/Desktop/ALS_study"
printf -v results_dir "${study_dir}/S%02d/results" ${subj}
printf -v analysisDir "${study_dir}/analyzed/S%02d" ${subj}
T1weighted_dir=${results_dir}/getT1weighted

#Move VASO files to its own directory for clarity:
cd ${results_dir}
mkdir ./getT1weighted
mv ./NORDIC1_INV*t1*.nii ./getT1weighted

# Register volumes to first within modality (contrast INV1 or INV2):
cd ${T1weighted_dir}
3dvolreg -verbose -zpad 2 -base NORDIC1_INV1t1magn.nii'[0]' \
    -prefix tmp_rNORDIC1_INV1t1magn.nii -overwrite \
    -1Dfile dfile.INV1t1magn.1D \
    -1Dmatrix_save mat.INV1t1magn.vr.aff12.1D \
    NORDIC1_INV1t1magn.nii

3dvolreg -verbose -zpad 2 -base NORDIC1_INV2t1magn.nii'[0]' \
    -prefix tmp_rNORDIC1_INV2t1magn.nii -overwrite \
    -1Dfile dfile.INV2t1magn.1D \
    -1Dmatrix_save mat.INV2t1magn.vr.aff12.1D \
    NORDIC1_INV2t1magn.nii

#Compute means and check that they are exactly on top of each other (why wouldnt they - base images are acquired within a few seconds of each other):
3dTstat -prefix mean_rNORDIC1_INV1t1magn.nii tmp_rNORDIC1_INV1t1magn.nii
3dTstat -prefix mean_rNORDIC1_INV2t1magn.nii tmp_rNORDIC1_INV2t1magn.nii

#Now register not-nulled VASO image to mean functional:
3dTstat -prefix mean_rnoNORDIC_BOLD_01magn.nii ${results_dir}/rnoNORDIC_BOLD_01magn.nii

align_epi_anat.py -dset1 mean_rNORDIC1_INV2t1magn.nii -dset2 mean_rnoNORDIC_BOLD_01magn.nii -dset1to2 -cost lpa \
    -dset1_strip 3dAutomask \
    -dset2_strip 3dAutomask \
    -volreg off -tshift off \
    -suffix _al

#Now apply all transformations in one go, reslice functional timeseries and compute the T1_weighted image:
#NOTE IF PROBLEMS, MAYBE ORDER HERE IS WRONG? NOT SURE HOW CAT_MATVEC ORDERS THINGS. MAKE SURE OUTPUT LOOKS GOOD!
cat_matvec -ONELINE mean_rNORDIC1_INV2t1magn_al_mat.aff12.1D mat.INV1t1magn.vr.aff12.1D > mat.finalINV1.1D
cat_matvec -ONELINE mean_rNORDIC1_INV2t1magn_al_mat.aff12.1D mat.INV2t1magn.vr.aff12.1D > mat.finalINV2.1D

3dAllineate -base mean_rnoNORDIC_BOLD_01magn.nii \
    -input NORDIC1_INV1t1magn.nii \
    -1Dmatrix_apply mat.finalINV1.1D  \
    -prefix rNORDIC1_INV1t1magn_al.nii

3dAllineate -base mean_rnoNORDIC_BOLD_01magn.nii \
    -input NORDIC1_INV2t1magn.nii \
    -1Dmatrix_apply mat.finalINV2.1D  \
    -prefix rNORDIC1_INV2t1magn_al.nii

#Compute mean images for quality control:
3dTstat -mean -prefix mean_rNORDIC1_INV1t1magn_al.nii rNORDIC1_INV1t1magn_al.nii
3dTstat -mean -prefix mean_rNORDIC1_INV2t1magn_al.nii rNORDIC1_INV2t1magn_al.nii 

#Compute T1_weighted:
mkdir ${analysisDir}
3dTcat -prefix tmp_combined.nii rNORDIC1_INV1t1magn_al.nii rNORDIC1_INV2t1magn_al.nii  -overwrite
3dTstat -cvarinvNOD -prefix ${analysisDir}/T1_weighted.nii tmp_combined.nii 
3dresample -dxyz 0.2 0.2 0.82 -rmode Cu -prefix ${analysisDir}/T1_weighted_resample.nii -input ${analysisDir}/T1_weighted.nii

#Clean up
trash ./tmp_*.nii
trash ./mean_*.BRIK
trash ./mean_*.HEAD
done


