function getRim_ALS_study(GmWmBound,GmCsfBound,Pdepthmap)
%This function takes a cat12 depthmap and converts it into rim file in laynii
%format which can then be used to compute columns/layers maps

%Load depthmap generated with cat12:
V=spm_vol(Pdepthmap);
depthmap=spm_read_vols(V);

%make rims and fill with 3's:
tmp=depthmap;

depthmap(tmp<GmCsfBound)=1;
depthmap(tmp>GmWmBound)=2;
depthmap(tmp>=GmCsfBound & tmp<=GmWmBound)=3;


V.fname='./segmentationGuide.nii';

spm_write_vol(V,depthmap);


end