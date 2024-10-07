%Pipeline for ALS study, writing start 15-08-2023. It is adjusted directly
%from 3T-LfMRI study. 
%% Set, check and move to path
clc; clear; close all
%Input subject information:
SOI=[3]; %Subject of interest
num_subjects=numel(SOI);
%Create structure with path for current subject and sessions:
for subj=SOI
    subjstruc(subj).subjectID=sprintf('S%02d', subj);
    subjstruc(subj).studyDir='/Users/au686880/Desktop/ALS_study/';
    subjstruc(subj).rootDir=[subjstruc(subj).studyDir subjstruc(subj).subjectID];
    subjstruc(subj).resultsDir=[subjstruc(subj).rootDir '/results'];
    subjstruc(subj).physDir=[subjstruc(subj).rootDir '/physRegressors'];
    subjstruc(subj).analysisDir=[subjstruc(subj).studyDir 'analyzed/' subjstruc(subj).subjectID];
end 
   
%% DICOM conversion
%Convert to nifti using convertjob.m

%% Deoblique files
%FIRST CREATE motion mask FOR SOI
%Then run deoblique_ALS_study.sh

%% Set origin
%Then use SPM checkreg to set origin of MP2RAGE to AC and change this for all
% other images as well, which is needed for cat12 to work properly. 

%Then run:
for i=SOI
cd(subjstruc(i).resultsDir)
mkdir ./originMatricies
movefile ./*.mat ./originMatricies
end
%% NORDIC
clc; close all
clearvars -except subjstruc SOI

ARG.make_complex_nii    = 1;
ARG.noise_volume_last   = 0;
ARG.full_dynamic_range = 0;
ARG.temporal_phase=1;
ARG.phase_filter_width=10;

for i=SOI
cd(subjstruc(i).resultsDir)

%Run FE=1
ARG.factor_error=1;
NIFTI_NORDIC_git('4DAmpBOLD_01.nii','4DPhaseBOLD_01.nii','NORDIC_BOLD_01',ARG);
NIFTI_NORDIC_git('4DAmpBOLD_02.nii','4DPhaseBOLD_02.nii','NORDIC_BOLD_02',ARG);

%Run FE=1.15
ARG.factor_error=1.15;
NIFTI_NORDIC_git('4DAmpBOLD_01.nii','4DPhaseBOLD_01.nii','NORDIC1_BOLD_01',ARG);
NIFTI_NORDIC_git('4DAmpBOLD_02.nii','4DPhaseBOLD_02.nii','NORDIC1_BOLD_02',ARG);
NIFTI_NORDIC_git('4DAmpVASOt1_INV1.nii','4DPhaseVASOt1_INV1.nii','NORDIC1_INV1t1',ARG);
NIFTI_NORDIC_git('4DAmpVASOt1_INV2.nii','4DPhaseVASOt1_INV2.nii','NORDIC1_INV2t1',ARG);

end

%% Realign func magn
clc; close all
clearvars -except subjstruc SOI
spm_figure('GetWin','Graphics');


%Set path to file that should be motion corrected and moma.nii
for i=SOI
cd(subjstruc(i).resultsDir)
BOLD_files_01='4DAmpBOLD_01.nii';
BOLD_files_02='4DAmpBOLD_02.nii';
moma_file='moma.nii';
%Then run motion correction:
% List of open inputs
jobfile = {'/Users/au686880/Desktop/fMRI_analysis/scripts/ALS_study/realignfunc_ALS_study_job.m'};
jobs = repmat(jobfile, 1, 1);
inputs = cell(3,1);
inputs{1,1} = cellstr(BOLD_files_01);
inputs{2,1} = cellstr(BOLD_files_02);
inputs{3,1} = cellstr(moma_file);

spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
end

%See parameters of algorithm (e.g. smoothness fwhm for moma in realignfunc_job.m

%% Realign func phase
clc; close all
clearvars -except subjstruc SOI

for i=SOI
cd(subjstruc(i).resultsDir)
%Copy .mat file to reslice NORDIC files using the same parameters as
%estimated with noNORDIC. 
copyfile('./4DAmpBOLD_01.mat','./NORDIC_BOLD_01magn.mat')
copyfile('./4DAmpBOLD_02.mat','./NORDIC_BOLD_02magn.mat')
copyfile('./4DAmpBOLD_01.mat','./NORDIC1_BOLD_01magn.mat')
copyfile('./4DAmpBOLD_02.mat','./NORDIC1_BOLD_02magn.mat')

RealignAmpAndPhase_ALS_study('4DAmpBOLD_01.nii','4DPhaseBOLD_01.nii','');
RealignAmpAndPhase_ALS_study('NORDIC_BOLD_01magn.nii','NORDIC_BOLD_01phase.nii','');
RealignAmpAndPhase_ALS_study('NORDIC1_BOLD_01magn.nii','NORDIC1_BOLD_01phase.nii','');

RealignAmpAndPhase_ALS_study('4DAmpBOLD_02.nii','4DPhaseBOLD_02.nii','','4DAmpBOLD_01.nii');
RealignAmpAndPhase_ALS_study('NORDIC_BOLD_02magn.nii','NORDIC_BOLD_02phase.nii','','NORDIC_BOLD_01magn.nii');
RealignAmpAndPhase_ALS_study('NORDIC1_BOLD_02magn.nii','NORDIC1_BOLD_02phase.nii','','NORDIC1_BOLD_01magn.nii');

movefile('./r4DAmpBOLD_01.nii','./rnoNORDIC_BOLD_01magn.nii')
movefile('./r4DAmpBOLD_02.nii','./rnoNORDIC_BOLD_02magn.nii')
movefile('./cr4DPhaseBOLD_01.nii','./crnoNORDIC_BOLD_01phase.nii')
movefile('./cr4DPhaseBOLD_02.nii','./crnoNORDIC_BOLD_02phase.nii')
%delete ./mean*_BOLD_*magn.nii ./mean4DAmpBOLD*.nii ./*Real*phase*.nii ./*Imag*phase*.nii ./Real*.mat ./Imag*.mat
end
%% Realign T1
%Run getT1Weighted.sh

%NOTE: For S01, which was used to make pipeline, the order of
%cat_matvec does not make a difference (output image is very close to being
%identical, we are on 4th or 5th decimal before there is a difference).
%I am pretty sure this is because motion is so small. Im not sure what the correct
%order is but it should make a difference in cases of more motion. Make
%sure to check that mean_rNORDIC1_INV2t1magn_al.nii and
%mean_rnoNORDIC_BOLD_01magn_al.nii are closely overlapping. 

%% Coreg MP2RAGE to T1_weighted
%REMEMBER TO SET SOI BEFORE and set initial matrix witj itk: 

%Then run the following in terminal:
% source ~/Desktop/fMRI_analysis/scripts/ALS_study/CoregMP2RAGE_ALS_study.sh
%% Get retroicor regressors
clc; close all
clearvars -except subjstruc SOI
num_runs=2;
for i=SOI
cd(subjstruc(i).resultsDir)
for run=1:num_runs
% The full path filemane of the eeg file vmrk and vhdr should be in the same directory
PHYSFILE        = sprintf('%s/ALS%04d.eeg',subjstruc(i).physDir,i);
% A file with defaults settings for the make_NVR program 
defaultsfile    = '/Users/au686880/Desktop/fMRI_analysis/scripts/ALS_study/getRetroicorRegressors/NVR_defaults.m';
% Add the FieldTrip directory to the path
FTDIR           = [spm('dir') '/external/fieldtrip/fileio'];
addpath(FTDIR)
% N.B. This is the number of volumes without triggers before the start of
% the acquisition should be 0 when the dummy volumes are actually recorded
DUMMY_VOLUMES   = 0 ;
TR              = 2.2;
% number og triggers in the series we are looking for.
SERIESVEC       = [484 484];
% one samples tolerance when finding the relevant samples in the vmrk file
% nescesary if the samliningrate is sufficiently high
TOL             = 1; 
%seconds of continued recording after scanning has ended. THIS may be needed for tcpco2
SPILLOVER       = 0; 
% NUM_SLICES and REF_SLICE is used to define the relative position in TR
% to use as reference for the RETROICOR correction (middle slice is
% typically prefered even for 3D acquisitions
NUM_SLICES      = 26;
REF_SLICE       = 13; %

% First we look for the samples in the eeg file which correspond to the
% acquired MRI data out.samples will contain the relevant samples for the
% requested SEREISVEC
out=findsamples(PHYSFILE,SERIESVEC,TOL,SPILLOVER,TR,DUMMY_VOLUMES,FTDIR);

% Then we run make_NVR on the first run with the defaults file and some less stationary
% parameters:
physstruct      = make_NVR('DEFAULTS_FILE',defaultsfile,...
                           'PHYS_FILE',PHYSFILE,...
                           'SAMPLEVEC',out.samples{run},...
                           'FTDIR',FTDIR,...
                           'DUMMY_VOLUMES',DUMMY_VOLUMES,...
                           'NUM_SLICES',NUM_SLICES,...
                           'REF_SLICE',REF_SLICE);

% Create a matrix with the RETROICOR regressors for pulse and respiration 2x5 of each                      
R=[physstruct.pulse_retroicor physstruct.resp_retroicor ];

% Skip the first 4 volumes and take into account the the last volumes were
% not reconstructed
R           = R(5:end,:);

names ={'PulseS1'...
    'PulseC1'...
    'PulseS2'...
    'PulseC2'...
    'PulseS3'...
    'PulseC3'...
    'PulseS4'...
    'PulseC4'...
    'PulseS5'...
    'PulseC5'...
    'RespS1'...
    'RespC1'...
    'RespS2'...
    'RespC2'...
    'RespS3'...
    'RespC3'...
    'RespS4'...
    'RespC4'...
    'RespS5'...
    'RespC5'};

save(['physRegressors_0' num2str(run) '.mat'], 'R', 'names')
end
end

%% Run phase regression 
clc; close all
clearvars -except subjstruc SOI
%This function first project out nuissance noise (X=spm_orth([FIRset moPar
%Retroicor HPfilt]) of both magnitude and phase timeseries. It then estimates the noiseRatio
%by taking the ratio of standard deviations of the magnitude and phase timeseries where both nuissance and paradigm is projected out. 
%it then runs deming phase regression on timeseries where only nuissance was removed, subtracts the macro components and writes
%the parameter estimate from the phase regression, micro/macro and cleaned magnitude and phase timeseries (nuissance projected out).  
for i=SOI
cd(subjstruc(i).resultsDir)
load('physRegressors_01.mat');
Create_Micro_Macro_deming_ALS_study('./rnoNORDIC_BOLD_01magn.nii','./crnoNORDIC_BOLD_01phase.nii',R,'./rp_4DAmpBOLD_01.txt')
Create_Micro_Macro_deming_ALS_study('./rNORDIC_BOLD_01magn.nii','./crNORDIC_BOLD_01phase.nii',R,'./rp_4DAmpBOLD_01.txt')
Create_Micro_Macro_deming_ALS_study('./rNORDIC1_BOLD_01magn.nii','./crNORDIC1_BOLD_01phase.nii',R,'./rp_4DAmpBOLD_01.txt')

load('physRegressors_02.mat');
Create_Micro_Macro_deming_ALS_study('./rnoNORDIC_BOLD_02magn.nii','./crnoNORDIC_BOLD_02phase.nii',R,'./rp_4DAmpBOLD_02.txt')
Create_Micro_Macro_deming_ALS_study('./rNORDIC_BOLD_02magn.nii','./crNORDIC_BOLD_02phase.nii',R,'./rp_4DAmpBOLD_02.txt')
Create_Micro_Macro_deming_ALS_study('./rNORDIC1_BOLD_02magn.nii','./crNORDIC1_BOLD_02phase.nii',R,'./rp_4DAmpBOLD_02.txt')

mkdir ./phaseRegOutputs
movefile('./A_*magn.nii','./phaseRegOutputs')
movefile('./B_*magn.nii','./phaseRegOutputs')
movefile('./noiseRatio_*magn.nii','./phaseRegOutputs')
movefile('./macro_*magn.nii','./phaseRegOutputs')
end

%% Statsjob
%REMEMBER TO SET SOI BEFORE: 

%Run the following in terminal:
% source ~/Desktop/fMRI_analysis/scripts/ALS_study/statsjob_ALS_study.sh

%% Segmentation of MP2RAGE
clc; close all
clearvars -except subjstruc SOI

for i=SOI
cd(subjstruc(i).resultsDir)
mkdir ./segmentation
movefile ./MP2RAGE.nii ./segmentation
cd ./segmentation
MP2RAGE_file='MP2RAGE.nii';
jobfile = {'/Users/au686880/Desktop/fMRI_analysis/scripts/ALS_study/catSegmentation_ALS_study_job.m'};
jobs = repmat(jobfile, 1, 1);
inputs = cell(1,1);
inputs{1,1} = cellstr(MP2RAGE_file);

spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});

end


%% Copy mat0 file from MP2RAGE_UNI_ND.nii
clc; close all
clearvars -except subjstruc SOI

for i=SOI
%First copy cat12 output files:
cd([subjstruc(i).resultsDir '/segmentation'])
copyfile('./mri/p0MP2RAGE.nii','./p0MP2RAGE_mat0corrected.nii')
copyfile('./mri/p1MP2RAGE.nii','./p1MP2RAGE_mat0corrected.nii')
copyfile('./mri/p2MP2RAGE.nii','./p2MP2RAGE_mat0corrected.nii')
copyfile('./mri/p3MP2RAGE.nii','./p3MP2RAGE_mat0corrected.nii')
copyfile('./mri/lh.ppMP2RAGE.nii','./lh.ppMP2RAGE_mat0corrected.nii')

W = spm_vol(spm_file('./MP2RAGE.nii')); %Img we want to copy from
N = cat(1,W.private);

fname = 'p0MP2RAGE_mat0corrected.nii'; %Image we want to copy to
ni = nifti(fname); 
ni.mat0 = N(1).mat0;
ni.mat_intent = N(1).mat_intent;
ni.mat0_intent = N(1).mat0_intent;

create(ni);


fname = 'p1MP2RAGE_mat0corrected.nii'; %Image we want to copy to
ni = nifti(fname); 
ni.mat0 = N(1).mat0;
ni.mat_intent = N(1).mat_intent;
ni.mat0_intent = N(1).mat0_intent;

create(ni);


fname = 'p2MP2RAGE_mat0corrected.nii'; %Image we want to copy to
ni = nifti(fname); 
ni.mat0 = N(1).mat0;
ni.mat_intent = N(1).mat_intent;
ni.mat0_intent = N(1).mat0_intent;

create(ni);


fname = 'p3MP2RAGE_mat0corrected.nii'; %Image we want to copy to
ni = nifti(fname); 
ni.mat0 = N(1).mat0;
ni.mat_intent = N(1).mat_intent;
ni.mat0_intent = N(1).mat0_intent;

create(ni);

fname = 'lh.ppMP2RAGE_mat0corrected.nii'; %Image we want to copy to
ni = nifti(fname); 
ni.mat0 = N(1).mat0;
ni.mat_intent = N(1).mat_intent;
ni.mat0_intent = N(1).mat0_intent;

create(ni);
end

%% Align cat12 output to functional space
%REMEMBER TO SET SOI BEFORE: 

%Run the following in terminal:
% source ~/Desktop/fMRI_analysis/scripts/ALS_study/alignCat12tofunc_ALS_study.sh
