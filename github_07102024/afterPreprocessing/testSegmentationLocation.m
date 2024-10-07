clear; clc; close all
%% Test what depth GM/WM and GM/CSF borders correspond to based on cat12
%Load GM_resample, ROI and depthmap
subjects=[1,2];

depthmap_cat12=[];
depthmap_laynii=[];
counter=1;
for subj=subjects
analysisDir=['/Users/au686880/Desktop/ALS_study/analyzed/S' sprintf('%02d',subj) '/getROI'];
tmp_depthmap_cat12=spm_read_vols(spm_vol([analysisDir '/../depth_map_resample.nii']));
tmp_depthmap_laynii=single(spm_read_vols(spm_vol([analysisDir '/segmentation_metric_equidist.nii'])));
ROI1=spm_read_vols(spm_vol([analysisDir '/ROI1.nii']));
ROI2=spm_read_vols(spm_vol([analysisDir '/ROI2.nii']));
ROI=ROI1+ROI2;

%Reshape and mask:
s=size(tmp_depthmap_cat12);
tmp_depthmap_cat12=reshape(tmp_depthmap_cat12,s(1)*s(2)*s(3),1);
tmp_depthmap_laynii=reshape(tmp_depthmap_laynii,s(1)*s(2)*s(3),1);
ROI=reshape(ROI,s(1)*s(2)*s(3),1);

%Remove voxels outside segmentation and ROI:
idx=find(ROI>0 & tmp_depthmap_laynii>0);
tmp_depthmap_cat12=tmp_depthmap_cat12(idx,1);
tmp_depthmap_laynii=tmp_depthmap_laynii(idx,1);

%Combine across subjects:
depthmap_cat12=[depthmap_cat12; tmp_depthmap_cat12];
depthmap_laynii=[depthmap_laynii; tmp_depthmap_laynii];
counter=counter+1;
end

%% Plot cat12 depths as a function of GM:
beta=robustfit(depthmap_cat12,depthmap_laynii,'ols');
x=0:0.001:1;
y=x*beta(2)+beta(1);
hold on
plot(depthmap_cat12,depthmap_laynii,'.r')
plot(x,y,'b','linewidth',3)
plot([0.33 0.33],[0 1],'k--')
plot([0.66 0.66],[0 1],'k--')
hold off
xlabel('Value depthmap cat12')
ylabel('Value depthmap laynii')
xlim([0 1])
ylim([0 1])
title(sprintf('Subject %d',subj))


