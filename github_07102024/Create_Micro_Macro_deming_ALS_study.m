function Create_Micro_Macro_deming_ALS_study(PMagnitude,PPhase,R_retroicor,moFile)

if nargin < 4
    error('Need 4 inputs, magnitude and phase timeseries plus retroicor regressors and name of file containing motion parameters')
end

%% Filter and project out paradigm (magn, phase), retroicor (phase) and motion
%Create Nifti objects
Nmagnitude  = nifti(PMagnitude);
Nphase      = nifti(PPhase);

%Get size of data:
s           = Nmagnitude.dat.dim;

%Load data and reshape
YPhase      = reshape(Nphase.dat(:,:,:,:),[prod(s(1:3)) s(4)])';
YMagnitude  = reshape(Nmagnitude.dat(:,:,:,:),[prod(s(1:3)) s(4)])';


%Set up highpass filter
TR      = 2.2;
HParam  = 128;
K.RT=TR;
K.row=1:s(4);
K.HParam=HParam;
K=spm_filter(K);

%Load and setup motion regressors:
moPar=load(moFile);
%Get spin-History regressors:
moParDif=[zeros(1,size(moPar,2)); moPar(1:end-1,:)];
%Combine to 24 motion regressors:
R_motion=[moPar,moParDif,moPar.^2,moParDif.^2];


%Load FIR set:
SPM=load('~/Desktop/fMRI_analysis/scripts/ALS_study/SPM_FIR.mat');
SPM=SPM.SPM;

%The purpose now is to find the noise caused by retroicor and motion. We do
%this by making a fit with a FIR-set to model the paradigm and the motion
%and retroicor regressors. We orthogonalize it to make sure that the FIR
%set is allowed to explain all the paradigm variance, even if the motion
%regressors are correlated with the paradigm also. 
%Orthogonalize:
XRes=spm_orth([SPM.xX.X(:,1:40) R_motion R_retroicor K.X0]); %we dont want constant here.
betaMagnRes   = XRes\YMagnitude; % Fit GLM
betaPhaseRes   = XRes\YPhase; % Fit GLM

%Get fit of motion, retroicor, and HPfilt regressors which is the part
%of the signal explained by the nuissance regressors (with part correlated
%to paradigm removed). We will subtract these from the original timeseries
%later to remove nuissance noise from the timeseries before the deming
%regression:
NuisRegIdx =40+1:40+24+20+16;
FitNuisanceMagn = XRes(:,NuisRegIdx)*betaMagnRes(NuisRegIdx,:);
FitNuisancePhase = XRes(:,NuisRegIdx)*betaPhaseRes(NuisRegIdx,:);

%Now get full fit (paradigm plus nuissance regressors) which we subtract
%from original timeseries to estimate noise ratio:
FitFullMagn = XRes*betaMagnRes;
FitFullPhase = XRes*betaPhaseRes;

clear betaMagnRes betaPhaseRes
%Get noise-only timeseries
YNoiseMagn = YMagnitude-FitFullMagn;
YNoisePhase = YPhase-FitFullPhase;

clear FitFullMagn FitFullPhase
%Estimate noiseratio
noiseRatio = std(YNoiseMagn,[],1)./std(YNoisePhase,[],1);

clear YNoiseMagn YNoisePhase
%Remove physiological noise and drifts from original timeseries:
YMagnitude  = YMagnitude-FitNuisanceMagn;
YPhase      = YPhase-FitNuisancePhase;

clear FitNuisanceMagn FitNuisancePhase


%% Make phase regression
% Define index for Active and Passive condition (including rest).
idxA=find((repmat([ones(1,20) zeros(1,20)],[1 12])==1));
idxP=find((repmat([zeros(1,20) ones(1,20)],[1 12])==1));
idxvec ={idxA idxP};

Ymicro              = zeros(s(4),prod(s(1:3)));
yhat_deming         = zeros(s(4),prod(s(1:3)));

for condition = 1:numel(idxvec)
    %Prepare zero-arrays for speed:
    A(condition,:)                   = zeros(1,prod(s(1:3)));
    B(condition,:)                   = zeros(1,prod(s(1:3)));
    
    idx = idxvec{condition};

    %Phase regression:
    for voxnum = 1:size(YMagnitude,2)
        X                = YPhase(idx,voxnum)-mean(YPhase(idx,voxnum)); %Design matrix
        [beta, ~, ~, Yhat]= deming(X,YMagnitude(idx,voxnum),noiseRatio(voxnum)); %Apply deming regression
        yhat_deming(idx,voxnum)     = Yhat;
        
        A(condition,voxnum)        = beta(2);
        B(condition,voxnum)        = beta(1);
        Ymicro(idx,voxnum) = YMagnitude(idx,voxnum)-yhat_deming(idx,voxnum)+B(condition,voxnum);
    end

end


%% Write files
%Reshape back:
YMagnitude  = reshape(YMagnitude',s);
YPhase  = reshape(YPhase',s);
Ymicro  = reshape(Ymicro',s);
yhat_deming  = reshape(yhat_deming',s);
A  = reshape(A',s(1),s(2),s(3),numel(idxvec));
B  = reshape(B',s(1),s(2),s(3),numel(idxvec));
noiseRatio = reshape(noiseRatio',s(1),s(2),s(3));

%Write Cleaned magnitude/phase and micro/macro:
create4DNIFTI(spm_file(PMagnitude,'prefix','cleaned_'),YMagnitude,Nmagnitude,'Hpfilt retroicor motion Magnitude images')
create4DNIFTI(spm_file(PPhase,'prefix','cleaned_'),YPhase,Nphase,'Hpfilt retroicor motion phase images')

create4DNIFTI(spm_file(PMagnitude,'prefix','micro_'),Ymicro,Nmagnitude,'Micro timeseries')
create4DNIFTI(spm_file(PMagnitude,'prefix','macro_'),yhat_deming,Nmagnitude,'Macro timeseries')

%Write noise ratio:
NnoiseRatio = Nmagnitude;
NnoiseRatio.dat.fname=spm_file(PMagnitude,'prefix','noiseRatio_');
NnoiseRatio.dat.dim=[s(1) s(2) s(3)];
create4DNIFTI_1(spm_file(PMagnitude,'prefix','noiseRatio_'),noiseRatio,NnoiseRatio,'NoiseRatio')

%Write A, B and mask:
N3D         = Nmagnitude;
N3D.dat.dtype = [16 spm_platform('bigend')];
N3D.dat.scl_slope = [];
N3D.dat.scl_inter = [];
N3D.dat.dim = [N3D.dat.dim(1:3) numel(idxvec)];
create4DNIFTI_1(spm_file(PMagnitude,'prefix','A_'),A,N3D,'Macrovasular coefficient');
create4DNIFTI(spm_file(PMagnitude,'prefix','B_'),B,N3D,'Constant term');
end


function create4DNIFTI(fname,Dat4D,N,desc)
%-Create NifTI header
%--------------------------------------------------------------------------
ni         = nifti;
ni.dat     = file_array(fname,...
                        N(1).dat.dim,...
                       'INT16-LE',... %LK this is only difference from Create_Micro_Macro_deming.m
                        N(1).dat.offset,...
                        N(1).dat.scl_slope,...
                        N(1).dat.scl_inter);
ni.mat     = N(1).mat;
ni.mat0    = N(1).mat;
ni.descrip = desc;


% N(1).dat.dtype
% if ~isnan(RT)
%     ni.timing = struct('toffset',0, 'tspace',RT);
% end
create(ni);
disp('writing data to file')
ni.dat(:,:,:,:) = Dat4D;
end

function create4DNIFTI_1(fname,Dat4D,N,desc)
%-Create NifTI header
%--------------------------------------------------------------------------
ni         = nifti;
ni.dat     = file_array(fname,...
                        N(1).dat.dim,...
                       'FLOAT64-LE',... %Alternative FLOAT64-LE
                        N(1).dat.offset,...
                        N(1).dat.scl_slope,...
                        N(1).dat.scl_inter);
ni.mat     = N(1).mat;
ni.mat0    = N(1).mat;
ni.descrip = desc;


% N(1).dat.dtype
% if ~isnan(RT)
%     ni.timing = struct('toffset',0, 'tspace',RT);
% end
create(ni);
disp('writing data to file')
ni.dat(:,:,:,:) = Dat4D;
end