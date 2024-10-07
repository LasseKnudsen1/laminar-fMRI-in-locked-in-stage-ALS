clear; clc; close all
subject=2;
%% Get cortical thickness
analysisDir=sprintf('/Users/au686880/Desktop/ALS_study/analyzed/S%02d/getROI',subject);
ROI1=spm_read_vols(spm_vol([analysisDir '/ROI1.nii']));
ROI2=spm_read_vols(spm_vol([analysisDir '/ROI2.nii']));
depth=spm_read_vols(spm_vol([analysisDir '/segmentation_metric_equidist.nii']));
thickness=spm_read_vols(spm_vol([analysisDir '/thickness/thickness.nii']));

%Reshape and mask:
s=size(ROI1);
ROI1=reshape(ROI1,s(1)*s(2)*s(3),1);
ROI2=reshape(ROI2,s(1)*s(2)*s(3),1);
depth=reshape(depth,s(1)*s(2)*s(3),1);
thickness=reshape(thickness,s(1)*s(2)*s(3),1);

%Remove voxels outisde ROI and outside GM (0.15 WM/GM boundary, 0.85
%GM/CSF)
idx=find((ROI1 > 0 | ROI2 > 0) & (depth>0.15 & depth <=0.85));
thickness=thickness(idx,1);

%multiply by 0.7 as only 70% of the depth is in GM. 
mean_thickness=mean(thickness*0.7);
std_thickness=std(thickness*0.7);