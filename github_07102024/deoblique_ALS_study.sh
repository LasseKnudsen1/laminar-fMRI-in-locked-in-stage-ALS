#Deoblique files
subject=(3)

for subj in ${subject[@]} ; do 
#set path and move to proper folder
printf -v root_dir "${HOME}/Desktop/ALS_study/S%02d" ${subj}
results_dir=${root_dir}/results

cd ${results_dir}
3drefit -deoblique MP2RAGE.nii
3drefit -deoblique MP2RAGE_INV2.nii
3drefit -deoblique FLAIR.nii
3drefit -deoblique SWI_calculated.nii
3drefit -deoblique SWI_projection.nii
3drefit -deoblique SWI_magn.nii
3drefit -deoblique SWI_phase.nii
3drefit -deoblique 4DAmpVASOt1_INV1.nii
3drefit -deoblique 4DAmpVASOt1_INV2.nii
3drefit -deoblique 4DPhaseVASOt1_INV1.nii
3drefit -deoblique 4DPhaseVASOt1_INV2.nii
3drefit -deoblique moma.nii

for run in 01 02; do
3drefit -deoblique 4DAmpBOLD_${run}.nii
3drefit -deoblique 4DPhaseBOLD_${run}.nii
done 


done