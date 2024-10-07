clear; clc; close all
MP2RAGE.B0=3;           % in Tesla
MP2RAGE.TR=5;           % MP2RAGE TR in seconds
MP2RAGE.TRFLASH=8.96e-3; % TR of the GRE readout
MP2RAGE.TIs=[0.7 2.5];% inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
SlicesPerSlab =128;
PartialFourierInSlice = 0.75;
MP2RAGE.NZslices= SlicesPerSlab * [PartialFourierInSlice-0.5  0.5];
MP2RAGE.FlipDegrees=[4 5];% Flip angle of the two readouts in degrees

cd('/Users/au686880/Desktop/ALS_study/analyzed/S01/highResMP2RAGE')
images=     {'MP2RAGE1.nii',...
             'MP2RAGE2.nii',...
             'MP2RAGE3.nii'};

images_INV2={'MP2RAGE1_INV2.nii',...
             'MP2RAGE2_INV2.nii',...
             'MP2RAGE3_INV2.nii'};

outputNames={'1.nii',...
             '2.nii'....
             '3.nii'};

for img = 1:numel(images)
%Make sure multiplicative scaling and additive offset isnt a problem:
info1=niftiinfo(images{img});
info2=niftiinfo(images_INV2{img});
Y1=single(niftiread(images{img}));
Y2=single(niftiread(images_INV2{img}));

Y1=Y1.*info1.MultiplicativeScaling+info1.AdditiveOffset;
Y2=Y2.*info2.MultiplicativeScaling+info2.AdditiveOffset;

info1.MultiplicativeScaling=1;
info1.AdditiveOffset=0;
info1.Datatype='single';
info2.MultiplicativeScaling=1;
info2.AdditiveOffset=0;
info2.Datatype='single';

niftiwrite(Y1,images{img},info1)
niftiwrite(Y2,images_INV2{img},info2)

%Run Jose code:
MP2RAGEnii = load_untouch_nii(images{img});
MP2RAGEINV2nii = load_untouch_nii(images_INV2{img});
[T1map, M0map, R1map]=T1M0estimateMP2RAGE(MP2RAGEnii,MP2RAGEINV2nii,MP2RAGE);


save_untouch_nii(T1map,['T1map' outputNames{img}])
save_untouch_nii(M0map,['M0map' outputNames{img}])
end
