function RealignAmpAndPhase_ALS_study(Pamp,Pphase,flags,refvol)
% syntax: RealignAmpAndPhase(Pamp,Pphase,flags,refvol)
% This function realigns the amplitude images in Pamp, transforms the Ppase
% image into a pair of Real and Imaginary images, reslices those and
% transforms back into polar cordinates. Timeseries are unwarped and no
% longer restricted to the interval [0 2pi] but can have values larger than
% 2pi=8192. A set if flags for the realignment estimation can be provided
% in the variable flags which can be skipped or left empty to use the
% defaults. If the images are to be resliced to an image from another
% session the variable refvol should contain 
% examples:
% To realign and reslice images from session 1 using default values:
% RealignAmpAndPhase('NORDICAmpBOLD1.nii','NORDICPhaseBOLD1.nii','')
% To realign and reslice images from session 2 and hereafter reslice them to the space of session 2 
% without reslicing the reference image again
% RealignAmpAndPhase('NORDICAmpBOLD2.nii','NORDICPhaseBOLD2.nii','','NORDICAmpBOLD1.nii')


if nargin>3
    refvol = spm_file(refvol,'ext','nii,1')
else
    refvol ='';
end

transmatfile = spm_file(Pamp,'ext','mat');

disp('Checking if matfile from realignment already exist')
if ~exist(transmatfile)
    disp('no matfile found, motion parameters will be estimated')    
    if nargin>2
        spm_realign(Pamp,flags);
    else
        spm_realign(Pamp);
    end
else
    disp('matfile found, and will be reused')
end

disp('Reslicing the amplitude image')
if ~isempty(refvol)
     resliceflag = struct('which',1,'mean',1);
     spm_reslice(char([cellstr(refvol) ;cellstr(Pamp)]),resliceflag)
else
     spm_reslice(Pamp)
end

disp('Get nifti header info and load the phase image')
phaseinfo   = niftiinfo(Pphase);
V           = single(niftiread(Pphase));

disp('Scaling the phase image')
V           = (V*phaseinfo.MultiplicativeScaling)+phaseinfo.AdditiveOffset;
Vrange      = (max(V(:))-min(V(:)));
V           = 2*pi*V/Vrange;

disp('Convert to rectangular coordinates and scale')
VReal       = uint16(((cos(V)*Vrange/2)+(Vrange/2))/2);
VImag       = uint16(((sin(V)*Vrange/2)+(Vrange/2))/2);

clear V

disp('Preparing header information')
realinfo                            = phaseinfo;
realinfo.Description                = 'Real part of phase image';
realinfo.AdditiveOffset             = -Vrange/2;
realinfo.MultiplicativeScaling      = 2;
realinfo.Datatype                  = 'uint16'; %LK

imaginfo                    = realinfo;
imaginfo.Description        = 'Imaginary part of phase image';

Prealname                   = spm_file(Pphase,'prefix','Real');
Prealmatname                = spm_file(Prealname,'ext','mat');
Pimagname                   = spm_file(Pphase,'prefix','Imag');
Pimagmatname                = spm_file(Pimagname,'ext','mat');

disp('Copying the mat files to real and imaginary images')
copyfile(transmatfile,Prealmatname);
copyfile(transmatfile,Pimagmatname);

disp('Saving  real and imaginary images')
niftiwrite(VReal,Prealname,realinfo);
niftiwrite(VImag,Pimagname,imaginfo);

clear VReal VImag



%disp('Reslicing real and imaginary images')
if nargin<4
if exist(refvol)
    resliceflag = struct('which',1,'mean',1);
    spm_reslice(char([cellstr(refvol) ;cellstr(Prealname)]),resliceflag);
    spm_reslice(char([cellstr(refvol) ;cellstr(Pimagname)]),resliceflag);
    disp('Images have been resliced to refvol')
else
    disp('Reslicing real and imaginary images')
    spm_reslice(Prealname);
    spm_reslice(Pimagname);
end
else
if exist('refvol')
    resliceflag = struct('which',1,'mean',1);
    spm_reslice(char([cellstr(refvol) ;cellstr(Prealname)]),resliceflag);
    spm_reslice(char([cellstr(refvol) ;cellstr(Pimagname)]),resliceflag);
    disp('Images have been resliced to refvol')
else
    disp('Reslicing real and imaginary images')
    spm_reslice(Prealname);
    spm_reslice(Pimagname);
end
end


disp('Load the resliced images')
VReal                       = single(niftiread(spm_file(Prealname,'prefix','r')));
VImag                       = single(niftiread(spm_file(Pimagname,'prefix','r')));

VReal                       = (VReal*realinfo.MultiplicativeScaling)+realinfo.AdditiveOffset;
VImag                       = (VImag*imaginfo.MultiplicativeScaling)+imaginfo.AdditiveOffset;



disp('Convert back to angle again')
VPhase                      = atan2(VImag,VReal);

disp('Move angles into 0-2pi range')
%VPhase                      = mod(VPhase + (2*pi),2*pi);
VPhase                      = mod(VPhase + (2*pi),2*pi); %for at flytte en evt kant midt i billedet

disp('Reshape and unwrap and Reshape back again')
s                           = size(VPhase);
VPhase                      = reshape(VPhase,[s(1)*s(2)*s(3) s(4)])';
VPhase                      = unwrap(VPhase);
VPhase                      = reshape(VPhase',[s(1) s(2) s(3) s(4)]);

disp('Scaling phase image')
VPhase                      = int16(4096*VPhase/(2*pi));

disp('Saving the realigned phase image')
phaseinfo.AdditiveOffset        = 0;
phaseinfo.MultiplicativeScaling = 2;
phaseinfo.Description           = 'Unwarped phase images 0-2*Pi+ 2*Pi=8192';
phaseinfo.Datatype              = 'int16'; %LK
Pphasename                      = spm_file(Pphase,'prefix','cr');
niftiwrite(VPhase,Pphasename,phaseinfo);


disp('Correcting mat0 in the nifti header') 
W                               = spm_vol(spm_file(Prealname,'prefix','r'));
N                               = cat(1,W.private);

fname                           = Pphasename;
ni                              = nifti(fname);
ni.mat0                         = N(1).mat0;
ni.mat_intent                   = N(1).mat_intent;
ni.mat0_intent                  = N(1).mat0_intent;

create(ni);



