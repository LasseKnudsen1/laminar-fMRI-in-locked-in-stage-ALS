function NVRstruct=make_NVR(varargin)
%% Nuisance Variable Regression
% This function returns a matlab structure which can be used to implement
% Nuisance Variable Regression in fMRI data. The syntax for the function is
%
% * syntax: NVRstruct=make_NVR(varargin)
%
% where vargin are key value pairs:
%
% * usage: NVRstruct=make_NVR('key1','value1','key2','value2')
%
% The function is convieniently used together with a defaults file
% which will set up various variables like in the following example:
%
% * NVR_struct=make_NVR('DEFAULTS_FILE','NVR_defaults','TR',2.33)
%
% will use the default values specified in the file "NVR_defaults" but with a TR value of 2.33s
%
% Currently the models described in the following papers are implemented
%
% References:
%
% * Birn RM, Diamond JB, Smith MA, Bandettini PA.
% Separating respiratory-variation-related fluctuations from neuronal-activity-related fluctuations in fMRI.
% Neuroimage. 2006 Jul 15;31(4):1536-48. Epub 2006 Apr 24.
%
% * Brooks J.C.W., Beckmann C.F., Miller K.L. , Wise R.G., Porro C.A., Tracey I., Jenkinson M.
% Physiological noise modelling for spinal functional magnetic resonance imaging studies
% NeuroImage in press: DOI: doi: 10.1016/j.neuroimage.2007.09.018
%
% * Glover GH, Li TQ, Ress D.
% Image-based method for retrospective correction of physiological motion effects in fMRI: RETROICOR.
% Magn Reson Med. 2000 Jul;44(1):162-7.
%
% * Lund TE, Madsen KH, Sidaros K, Luo WL, Nichols TE.
% Non-white noise in fMRI: does modelling have an impact?
% Neuroimage. 2006 Jan 1;29(1):54-66.
%
% * Wise RG, Ide K, Poulin MJ, Tracey I.
% Resting fluctuations in arterial carbon dioxide induce significant low frequency variations in BOLD signal.
% Neuroimage. 2004 Apr;21(4):1652-64.
%
%% Authors:
% Kristoffer H. Madsen Danish Research Centre for MR:
% kristofferm@magnet.drcmr.dk
% Torben E. Lund Center for Functionally Integrative Neuroscience (CFIN):
% torbenelund@mac.com


%Version history:
% 05302007 Cardiac (pulse oximetry)/respiration interaction added (KHM)

% 29062007 corrected higher harmonics error 4 regressors for each harmonic (KHM)

% 19112007 RETROICOR can now be used with a vector of REF_SLICE values (TL)

% 28112007 KM found a set of typos in RESPxPULSE and similar they are now
% changed to RESPXPULSE

% 07122007 Significant speedup approx. 2.5X for single slice, much more for
% multiple slices. Most significant changes include only reading in files
% once
% and changes around line 765-780 for more efficient MAX/MIN RESP AMPLITUDE
% estimation. (KHM)

% 10122007 A small change wich now expects the rtrig and ptrig to have
% comma dilimited data.

% 17122007 Changed mistake where RESP was mistakenly replaced with PHYS

% 22042008 Changed a bug where specified PULS_FS was not used

% 30042008 Introduced a feature for type TRACETYPE IOP, where the trigfiles
% are truncated if they are longer than the image acquisition

% 30062008 Extended documentation

% 07102008 Automatic peak-detection using lowpass filtering and  findpeaks
% (require sptool) (TL)

% 16082010 Added support for TRACETYPE CUSTOM functionallity similar to
% TRACETYPE GE but with different suffixes

% 21082014 Added support for TRACETYPE BRAINPRODUCTS the external functions
% movingmean and findpeaks are required for this option

% Supported TRACETYPES
TRACETYPES=[{'GE' 'SIEMENS' 'IOP' 'CUSTOM' 'BRAINPRODUCTS'}];

if nargin < 1
    help make_NVR
    return
end


%%%%%%%%%% Collect keywords and values from argument list %%%%%%%
if (nargin> 0 & rem(nargin,2) ~= 0)
    error('Input must be pairs of key and corresponding value')
end


for i=1:2:length(varargin)
    Keyword = varargin{i};
    Value = varargin{i+1};
    if isstr(Keyword)
        if strcmp(upper(Keyword),'DEFAULTS_FILE')
            DEFAULTS_FILE=Value;
            run(Value)
        end
    end
end


for i = 1:2:length(varargin) % for each Keyword
    Keyword = varargin{i};
    Value = varargin{i+1};
    if ~isstr(Keyword)
        fprintf('Keywords must be strings')
        return
    end
    Keyword = upper(Keyword); % convert upper or mixed case to lower
    
    %DEFAULTS_FILE
    if strcmp(Keyword,'DEFAULTS_FILE')
        display(['The following DEFAULTS_FILE is used: ' Value])
        
        %TRACETYPE
    elseif strcmp(Keyword,'TRACETYPE')
        if ~isstr(Value)
            error(['TRACETYPE must be a string e.g. ' TRACETYPES])
        else
            TRACETYPE= upper(Value);
            if ~sum(strcmp(TRACETYPE,TRACETYPES))
                error(['TRACETYPE: ' TRACETYPE 'is not yet supported, please send an email to one of the authors.'])
            end
        end
        
        %EGG
    elseif strcmp(Keyword,'ECG')
        if ~isstr(Value)
            error('ECG value must be ON or OFF')
        else
            Value = upper(Value);
            if strcmp(Value,'ON')
                ECG = Value;
                display('ECG is ON')
            elseif strcmp(Value,'OFF'),
                ECG = Value;
                display('ECG is OFF')
            else
                error('ECG value must be ON or OFF')
            end
        end
        
        %PULSE
    elseif strcmp(Keyword,'PULSE')
        if ~isstr(Value)
            error('PULSE value must be ON or OFF')
        else
            Value = upper(Value);
            if strcmp(Value,'ON')
                PULSE = Value;
                display('PULSE is ON')
            elseif strcmp(Value,'OFF'),
                PULSE = Value;
                display('PULSE is OFF')
            else
                error('PULSE value must be ON or OFF')
            end
        end
        
        %RESP
    elseif strcmp(Keyword,'RESP')
        if ~isstr(Value)
            error('RESP value must be ON, OFF or ESTIMATE')
        else
            Value = upper(Value);
            if ( strcmp(Value,'ON') |strcmp(Value,'OFF') | strcmp(Value,'ESTIMATE'))
                RESP = Value;
            else
                error('RESP value must be ON or OFF')
            end
        end
        
        %RESPXECG
    elseif strcmp(Keyword,'RESPXECG')
        if ~isstr(Value)
            error('RESPXECG value must be ON, OFF')
        else
            Value = upper(Value);
            if ( strcmp(Value,'ON') |strcmp(Value,'OFF'))
                RESPXECG = Value;
            else
                error('RESPXECG value must be ON or OFF')
            end
        end
        
        %RESPXPULSE
    elseif strcmp(Keyword,'RESPXPULSE')
        if ~isstr(Value)
            error('RESPXPULSE value must be ON, OFF')
        else
            Value = upper(Value);
            if ( strcmp(Value,'ON') |strcmp(Value,'OFF'))
                RESPXPULSE = Value;
            else
                error('RESPXPULSE value must be ON or OFF')
            end
        end
        
        
        %NVR
    elseif strcmp(Keyword,'NVR')
        if ~isstr(Value)
            error('NVR value must be ON or OFF')
        else
            Value = upper(Value);
            if ( strcmp(Value,'ON') |strcmp(Value,'OFF'))
                NVR = Value;
            else
                error('NVR value must be ON or OFF')
            end
        end
        
        
        
        
        
        %DUMMY_VOLUMES
    elseif strcmp(Keyword,'DUMMY_VOLUMES')
        if isstr(Value)
            Value=upper(Value)
            if ~strcmp(Value,'DEFAULT')
                error('DUMMY_VOLUMES must be integer or DEFAULT')
            end
        elseif rem(Value,1)
            error('DUMMY_VOLUMES must be integer or DEFAULT')
        end
        DUMMY_VOLUMES=Value;
        
        
        
        %TR
    elseif strcmp(Keyword,'TR')
        if isstr(Value)
            error('TR must be the repitition time in seconds')
        elseif ~isreal(Value)
            error('TR needs to be a real number')
        end
        TR=Value;
        
        
        %NUM_VOLUMES
    elseif strcmp(Keyword,'NUM_VOLUMES')
        if isstr(Value)
            error('NUM_VOLUMES must an integer')
        elseif rem(Value,1)
            error('NUM_VOLUMES must an integer')
        end
        NUM_VOLUMES=Value;
        
        %NUM_SLICES
    elseif strcmp(Keyword,'NUM_SLICES')
        if isstr(Value)
            error('NUM_SLICES must an integer')
        elseif rem(Value,1)
            error('NUM_SLICES must an integer')
        end
        NUM_SLICES=Value;
        
        
        %REF_SLICE
    elseif strcmp(Keyword,'REF_SLICE')
        if isstr(Value)
            error('REF_SLICE must an integer')
        elseif rem(Value,1)
            error('REF_SLICE must an integer')
        end
        REF_SLICE=Value;
        
        %ECG_ORDER
    elseif strcmp(Keyword,'ECG_ORDER')
        if isstr(Value)
            error('ECG_ORDER must an integer')
        elseif rem(Value,1)
            error('ECG_ORDER must an integer')
        end
        ECG_ORDER=Value;
        
        %PULSE_ORDER
    elseif strcmp(Keyword,'PULSE_ORDER')
        if isstr(Value)
            error('PULSE_ORDER must an integer')
        elseif rem(Value,1)
            error('PULSE_ORDER must an integer')
        end
        PULSE_ORDER=Value;
        
        %RESP_ORDER
    elseif strcmp(Keyword,'RESP_ORDER')
        if isstr(Value)
            error('RESP_ORDER must an integer')
        elseif rem(Value,1)
            error('RESP_ORDER must an integer')
        end
        RESP_ORDER=Value;
        
        %RVT_DELAY
    elseif strcmp(Keyword,'RVT_DELAY')
        if isstr(Value)
            error('RVT_DELAY must be the repitition time in seconds (it can be a vector)')
        elseif ~isreal(Value)
            error('RVT_DELAY needs to be a real number or a real vector')
        end
        TR=Value;
        
        %START_STAMP
    elseif strcmp(Keyword,'START_STAMP')
        START_STAMP=Value;
        
        %STOP_STAMP
    elseif strcmp(Keyword,'STOP_STAMP')
        STOP_STAMP=Value;
        
        %PHYS_FILE
    elseif strcmp(Keyword,'PHYS_FILE')
        PHYS_FILE=Value;
        
        %DICOM_FILE
    elseif strcmp(Keyword,'DICOM_FILE')
        DICOM_FILE=Value;
        
        %PHYS_DIR
    elseif strcmp(Keyword,'PHYS_DIR')
        PHYS_DIR=Value;
        
        %PHYS_DATE
    elseif strcmp(Keyword,'PHYS_DATE')
        PHYS_DIR=Value;
        %FS_PULS
    elseif strcmp(Keyword,'FS_PULS')
        FS_PULS=Value;
        
        %FS_RESP
    elseif strcmp(Keyword,'FS_RESP')
        FS_RESP=Value;
        
        %FS_ECG
    elseif strcmp(Keyword,'FS_ECG')
        FS_ECG=Value;
        
        %RVT
    elseif strcmp(Keyword,'RVT')
        RVT=Value;
        
        %RESPXPULSE_ORDER
    elseif strcmp(Keyword,'RESPXPULSE_ORDER')
        RESPXPULSE_ORDER=Value;
        
        %RESPXECG_ORDER
    elseif strcmp(Keyword,'RESPXECG_ORDER')
        RESPXECG_ORDER=Value;
        
        %FTDIR
    elseif strcmp(Keyword,'FTDIR')
        FTDIR=Value;
        
        %SAMPLEVEC
    elseif strcmp(Keyword,'SAMPLEVEC')
        SAMPLEVEC=Value;
        
        %FIND_PULSEPEAKS
    elseif strcmp(Keyword,'FIND_PULSEPEAKS')
        FIND_PULSEPEAKS=Value;
        
        %FIND_ECGPEAKS
    elseif strcmp(Keyword,'FIND_ECGPEAKS')
        FIND_ECGPEAKS=Value;
        
        %FIND_RESPPEAKS
    elseif strcmp(Keyword,'FIND_RESPPEAKS')
        FIND_RESPPEAKS=Value;
        
        %CHEBY_ORDER
    elseif strcmp(Keyword,'CHEBY_ORDER')
        CHEBY_ORDER=Value;
        
        %CHEBY_RIP
    elseif strcmp(Keyword,'CHEBY_RIP')
        CHEBY_RIP=Value;
        
        
        %PULSEPEAKS_INTERVAL
    elseif strcmp(Keyword,'PULSEPEAKS_INTERVAL')
        PULSEPEAKS_INTERVAL=Value;
        
        %ECGPEAKS_INTERVAL
    elseif strcmp(Keyword,'ECGPEAKS_INTERVAL')
        ECGPEAKS_INTERVAL=Value;
        
        %RESPPEAKS_INTERVAL
    elseif strcmp(Keyword,'RESPPEAKS_INTERVAL')
        RESPPEAKS_INTERVAL=Value;
        
        %LP_PULSE
    elseif strcmp(Keyword,'LP_PULSE')
        LPFILTER_PULSE=Value;
        
        %LP_PULSE_FSTOP
    elseif strcmp(Keyword,'LP_PULSE_FSTOP')
        LP_PULSE_FSTOP=Value;
        
        %LP_RESP
    elseif strcmp(Keyword,'LP_RESP')
        LPFILTER_RESP=Value;
        
        %LP_RESP_FSTOP
    elseif strcmp(Keyword,'LP_RESP_FSTOP')
        LP_RESP_FSTOP=Value;
        
        %LP_ECG
    elseif strcmp(Keyword,'LP_ECG')
        LPFILTER_ECG=Value;
        
        %LP_ECG_FSTOP
    elseif strcmp(Keyword,'LP_ECG_FSTOP')
        LP_ECG_FSTOP=Value;
        
        %ELSE
    else
        error(['Unknown flag: ' Keyword])
        
    end
end




%Get the filenames. Valid options are a filename or a dicom file and a directory with recordings


if ~isempty(PHYS_FILE)
    P_phys=PHYS_FILE;
    [PHYS_DIR,PHYS_FILE,EXT] = fileparts(PHYS_FILE);
    if strcmp(TRACETYPE,'SIEMENS')
        if ~(strcmp(EXT,'.resp') |strcmp(EXT,'.puls') |strcmp(EXT,'.ecg') )
            error('This does not appear to be a file of TRACETYPE SIEMENS')
        end
        
        if strcmp(PULSE,'ON')
            PULSE_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.puls']);
        end
        if strcmp(RESP,'ON')
            RESP_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.resp']);
        end
        if strcmp(ECG,'ON')
            ECG_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.ecg']);
        end
        
    elseif strcmp(TRACETYPE,'IOP')
        if ~(strcmp(EXT,'.rtrig') |strcmp(EXT,'.ptrig') |strcmp(EXT,'.rpts') )
            error('This does not appear to file of TRACETYPE IOP')
        end
        
        if strcmp(PULSE,'ON')
            PULSE_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.rpts']);
            PULSE_ONSETS_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.ptrig']);
        end
        if strcmp(RESP,'ON')
            RESP_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.rpts']);
            RESP_ONSETS_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.rtrig']);
        end
        if strcmp(ECG,'ON')
            error('ECG is not supported for this TRACETYPE')
        end
    elseif strcmp(TRACETYPE,'CUSTOM')
        if ~(strcmp(EXT,'.rtm') |strcmp(EXT,'.ptm') |strcmp(EXT,'.etm') |strcmp(EXT,'.rts') |strcmp(EXT,'.pts') |strcmp(EXT,'.ets') )
            error('This does not appear to file of TRACETYPE CUSTOM')
        end
        
        if strcmp(PULSE,'ON')
            PULSE_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.pts']);
            PULSE_ONSETS_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.ptm']);
        end
        if strcmp(RESP,'ON')
            RESP_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.rts']);
            RESP_ONSETS_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.rtm']);
        end
        if strcmp(ECG,'ON')
            ECG_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.ets']);
            ECG_ONSETS_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.etm']);
        end
    elseif strcmp(TRACETYPE,'BRAINPRODUCTS')
        if ~(strcmp(EXT,'.eeg') |strcmp(EXT,'.vmrk') |strcmp(EXT,'.vhdr'))
            error('This does not appear to file of TRACETYPE BRAINPRODUCTS')
        end
        
        if strcmp(PULSE,'ON') % The Brainproducts files have no onsets files
            PULSE_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.eeg']);
            PULSE_ONSETS_FILE='';
        end
        if strcmp(RESP,'ON')
            RESP_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.eeg']);
            RESP_ONSETS_FILE='';
        end
        if strcmp(ECG,'ON')
            ECG_FILE=fullfile(PHYS_DIR,[PHYS_FILE '.eeg']);
            ECG_ONSETS_FILE='';
        end
        
        
        
        
        
        
        
        
    elseif strcmp(TRACETYPE,'GE')
        i=findstr(PHYS_FILE,'_');
        if ~(strcmp(PHYS_FILE(1:i-1),'RespData')| strcmp(PHYS_FILE(1:i-1),'TrigResp')|strcmp(PHYS_FILE(1:i-1),'ECGData')|strcmp(PHYS_FILE(1:i-1),'TrigEcg') )
            error('This does not appear to file of TRACETYPE GE')
        end
        if strcmp(RESP,'ON')
            RESP_FILE=fullfile(PHYS_DIR,['RespData' PHYS_FILE(i:end)]);
            RESP_ONSETS_FILE=fullfile(PHYS_DIR,['TrigResp' PHYS_FILE(i:end)]);
        end
        if strcmp(ECG,'ON')
            ECG_FILE=fullfile(PHYS_DIR,['ECGData' PHYS_FILE(i:end)]);
            ECG_ONSETS_FILE=fullfile(PHYS_DIR,['TrigEcg' PHYS_FILE(i:end)]);
        end
        if strcmp(PULSE,'ON')
            PULSE_FILE=fullfile(PHYS_DIR,['ECGData' PHYS_FILE(i:end)]);
            PULSE_ONSETS_FILE=fullfile(PHYS_DIR,['TrigEcg' PHYS_FILE(i:end)]);
        end
    end
elseif xor(~isempty(DICOM_FILE),~isempty(DICOM_HDR))
    if (~isempty(DICOM_FILE) & ~isempty(PHYS_DIR)& ~isempty(PHYS_FILTER) & ~isempty(PHYS_DATE) & isempty(DICOM_HDR))
        if license('test','image_toolbox')
            DICOM_HDR=dicominfo(DICOM_FILE);
        elseif exist('spm_dicom_headers')
            DICOM_HDR=spm_dicom_headers(DICOM_FILE);
        else
            error('NO dicom reader found, please install one or use the DICOM_HDR option instead')
        end
        %get the physfile:
    elseif (~isempty(DICOM_HDR) & ~isempty(PHYS_DIR)& ~isempty(PHYS_FILTER) & ~isempty(PHYS_DATE) & isempty(DICOM_FILE))
        error('This feature is not yet implemented ... comming soon')
        %get the physfile
    end
elseif (~isempty(DICOM_FILE) & ~isempty(DICOM_HDR))
    error('Only one of the options DICOM_FILE and DICOM_HDR can be used')
else
    error('You forgot to provide a valid PHYS_FILE or (DICOM_IMAGE,PHYS_DIR,PHYS_FILTER,PHYS_DATE) or (DICOM_IMAGE,PHYS_DIR,PHYS_FILTER,PHYS_DATE) combination')
end

%Determine the number of dummy volumes
if strcmp(DUMMY_VOLUMES,'DEFAULT')
    if strcmp(TRACETYPE,'SIEMENS')
        %Siemens fills the first 3 seconds up with dummy volumes for all TR
        STOP=0;
        DUMMY_VOLUMES=1;
        while STOP~=1
            if DUMMY_VOLUMES*TR>3
                STOP=1;
            else
                DUMMY_VOLUMES=DUMMY_VOLUMES+1;
            end
        end
    else
        error('The option DEFAULT is NOT avialable for this TRACETYPE')
    end
end

if strcmp(TRACETYPE,'SIEMENS')
    
    %Load the pulse loggings
    
    if strcmp(PULSE,'ON')
        PULSE_RAW=textread(PULSE_FILE,'%s','delimiter','\n','whitespace','','bufsize',10000000);
        START=find(strcmp(PULSE_RAW,START_STAMP));
        STOP=find(strcmp(PULSE_RAW,STOP_STAMP));
        if isempty(START)
            PULSEWARNING=[PULSEWARNING 'No ' START_STAMP 'in .puls file'];
        end
        
        if isempty(STOP)
            PULSEWARNING=[PULSEWARNING ' No ' STOP_STAMP ' in .puls file. ']
            for j=STOP:length(PULSE_RAW)
                k=findstr(PULSE_RAW{j},'PULSE Freq Per: ');
                if ~isempty(k)
                    l=sscanf(PULSE_RAW{j}(k+15:end),'%f');
                    if l==[0 0]'
                        PULSEWARNING=['This file is incomplete. ' PULSEWARNING]
                    end
                end
            end
            if (isempty(FS_PULSE) & isempty(findstr(PULSEWARNING,'This file is incomplete. ')))
                PULSEWARNING=[PULSEWARNING 'Please provide sampling rate and I will try to procede. ']
            end
        end
        
        
        if isempty(findstr(PULSEWARNING,'This file is incomplete. '))
            PULSE_RAW=sscanf(PULSE_RAW{START+1},'%f');
            PULSE_RAW=PULSE_RAW(2:end-1); %Remove first value in the file (6002) and the last value (5002)
            PULSE_TS=PULSE_RAW(PULSE_RAW<5000);% create time_course without inserted peaks
            idx=find(PULSE_RAW==5000); %find siemens detected peaks
            PULSE_PEAKS=PULSE_RAW;
            PULSE_PEAKS(idx-1)=5000; %substitute signalvalue with peakvalue at the timepoint before the peak
            PULSE_PEAKS(idx)=[]; %erase old detected peaks
            
            if isempty(findstr(' in .resp file',PULSEWARNING))
                FS_PULSE=length(PULSE_TS)/(TR*(NUM_VOLUMES+DUMMY_VOLUMES)); %find samplingrate
            else
                if ~isempty(FS_PULSE)
                    display(['Your FS_PULSE of: ' num2str(FS_PULSE) 'Hz will be used'])
                else
                    PULSE='OFF';
                end
            end
            if ~strcmp(PULSE,'OFF')
                PULSE_ONSETS=find(PULSE_PEAKS==5000)/FS_PULSE; %find onsets in seconds
            end
        end
    end %(PULSE ON)
    
    %Load the respiration loggings
    if strcmp(RESP,'ON')
        RESP_RAW=textread(RESP_FILE,'%s','delimiter','\n','whitespace','','bufsize',10000000);
        START=find(strcmp(RESP_RAW,START_STAMP));
        STOP=find(strcmp(RESP_RAW,STOP_STAMP));
        if isempty(START)
            RESPWARNING=[RESPWARNING 'No ' START_STAMP 'in .resp file'];
        end
        
        if isempty(STOP)
            RESPWARNING=[RESPWARNING ' No ' STOP_STAMP ' in .resp file. ']
            for j=STOP:length(RESP_RAW)
                k=findstr(RESP_RAW{j},'RESP Freq Per: ');
                if ~isempty(k)
                    l=sscanf(RESP_RAW{j}(k+15:end),'%f');
                    if l==[0 0]'
                        RESPWARNING=['This file is incomplete. ' RESPWARNING]
                    end
                end
            end
            if (isempty(FS_RESP) & isempty(findstr(RESPWARNING,'This file is incomplete. ')))
                RESPWARNING=[RESPWARNING 'Please provide sampling rate and I will try to procede. ']
            end
        end
        
        
        if isempty(findstr(RESPWARNING,'This file is incomplete. '))
            RESP_RAW=sscanf(RESP_RAW{START+1},'%f');
            RESP_RAW=RESP_RAW(2:end-1); %Remove first value in the file (6002) and the last value (5002)
            RESP_TS=RESP_RAW(RESP_RAW<5000);% create time_course without inserted peaks
            idx=find(RESP_RAW==5000); %find siemens detected peaks
            RESP_PEAKS=RESP_RAW;
            RESP_PEAKS(idx-1)=5000; %substitute signalvalue with peakvalue at the timepoint before the peak
            RESP_PEAKS(idx)=[]; %erase old detected peaks
            
            if isempty(findstr(' in .resp file',RESPWARNING))
                FS_RESP=length(RESP_TS)/(TR*(NUM_VOLUMES+DUMMY_VOLUMES)); %find samplingrate
            else
                if ~isempty(FS_RESP)
                    display(['Your FS_RESP of: ' num2str(FS_RESP) 'Hz will be used'])
                else
                    RESP='OFF';
                end
            end
            if ~strcmp(RESP,'OFF')
                RESP_ONSETS=find(RESP_PEAKS==5000)/FS_RESP; %find onsets in seconds
            end
        end
    end %(RESP ON)
    
    %Load the ECG loggings
    if strcmp(ECG,'ON')
        ECG_RAW=textread(ECG_FILE,'%s','delimiter','\n','whitespace','','bufsize',10000000);
        START=find(strcmp(ECG_RAW,START_STAMP));
        STOP=find(strcmp(ECG_RAW,STOP_STAMP));
        if isempty(START)
            ECGWARNING=[ECGWARNING 'No ' START_STAMP 'in .ecg file'];
        end
        
        if isempty(STOP)
            ECGWARNING=[ECGWARNING ' No ' STOP_STAMP ' in .ecg file. ']
            for j=STOP:length(ECG_RAW)
                k=findstr(ECG_RAW{j},'ECG Freq Per: ');
                if ~isempty(k)
                    l=sscanf(ECG_RAW{j}(k+15:end),'%f');
                    if l==[0 0]'
                        ECGWARNING=['This file is incomplete. ' ECGWARNING]
                    end
                end
            end
            if (isempty(FS_ECG) & isempty(findstr(ECGWARNING,'This file is incomplete. ')))
                ECGWARNING=[ECGWARNING 'Please provide sampling rate and I will try to procede. ']
            end
        end
        
        
        if isempty(findstr(ECGWARNING,'This file is incomplete. '))
            ECG_RAW=sscanf(ECG_RAW{START+1},'%f');
            ECG_RAW=ECG_RAW(2:end-1); %Remove first value in the file (6002) and the last value (5002)
            idx=find(ECG_RAW==6000); %find siemens detected extra peaks (unique to the ECG recording)
            ECG_RAW(idx)=[];%erase extra peaks
            ECG_TS=ECG_RAW(ECG_RAW<5000);% create time_course without inserted peaks
            idx=find(ECG_RAW==5000); %find siemens detected peaks
            ECG_PEAKS=ECG_RAW;
            ECG_PEAKS(idx-1)=5000; %substitute signalvalue with peakvalue at the timepoint before the peak
            ECG_PEAKS(idx)=[]; %erase old detected peaks
            
            if isempty(findstr(' in .resp file',ECGWARNING))
                FS_ECG=length(ECG_TS)/(TR*(NUM_VOLUMES+DUMMY_VOLUMES)); %find samplingrate
            else
                if ~isempty(FS_ECG)
                    display(['Your FS_ECG of: ' num2str(FS_ECG) 'Hz will be used'])
                else
                    ECG='OFF';
                end
            end
            if ~strcmp(ECG,'OFF')
                ECG_ONSETS=find(ECG_PEAKS==5000)/FS_ECG; %find onsets in seconds
            end
        end
    end %(ECG ON)
    
elseif strcmp(TRACETYPE,'GE')
    
    if strcmp(PULSE,'ON')
        PULSE_TS=load(PULSE_FILE);
        FS_PULSE=length(PULSE_TS)/(NUM_VOLUMES+DUMMY_VOLUMES)/TR;
        PULSE_ONSETS=load(PULSE_ONSETS_FILE)/FS_PULSE;
    end
    if strcmp(RESP,'ON')
        RESP_TS=load(RESP_FILE);
        FS_RESP=length(RESP_TS)/(NUM_VOLUMES+DUMMY_VOLUMES)/TR;
        RESP_ONSETS=load(RESP_ONSETS_FILE)/FS_RESP;
    end
    if strcmp(ECG,'ON')
        ECG_TS=load(ECG_FILE);
        FS_ECG=length(ECG_TS)/(NUM_VOLUMES+DUMMY_VOLUMES)/TR;
        ECG_ONSETS=load(ECG_ONSETS_FILE)/FS_ECG;
    end
elseif strcmp(TRACETYPE,'IOP')
    [TIME JUNK RESP_TS PULSE_TS]=textread(PULSE_FILE,'','delimiter','\t','headerlines',7);
    if strcmp(PULSE,'ON')
        PULSE_TS=PULSE_TS(1:FS_PULSE*TR*(NUM_VOLUMES+DUMMY_VOLUMES)); %truncate the file to macth the total number of volumes
        [PULSE_ONSETS IBI]=textread(PULSE_ONSETS_FILE,'','delimiter',',','headerlines',1);
        PULSE_ONSETS=PULSE_ONSETS(PULSE_ONSETS<TR*(NUM_VOLUMES+DUMMY_VOLUMES));%truncate the file to macth the total number of volumes
    end
    if strcmp(RESP,'ON')
        RESP_TS=RESP_TS(1:FS_RESP*TR*(NUM_VOLUMES+DUMMY_VOLUMES)); %truncate the file to macth the total number of volumes
        [RESP_ONSETS IBI]=textread(RESP_ONSETS_FILE,'','delimiter',',','headerlines',1);
        RESP_ONSETS=RESP_ONSETS-0.2;% Move the IOP trigger 200ms back in time
        RESP_ONSETS=RESP_ONSETS(RESP_ONSETS<TR*(NUM_VOLUMES+DUMMY_VOLUMES));%truncate the file to macth the total number of volumes
    end
    if strcmp(ECG,'ON')
        display('ECG not suported for this TRACETYPE')
    end
    
elseif strcmp(TRACETYPE,'CUSTOM')
    
    if strcmp(PULSE,'ON')
        PULSE_TS=load(PULSE_FILE);
        FS_PULSE=length(PULSE_TS)/(NUM_VOLUMES+DUMMY_VOLUMES)/TR;
        PULSE_ONSETS=load(PULSE_ONSETS_FILE)/FS_PULSE;
    end
    if strcmp(RESP,'ON')
        RESP_TS=load(RESP_FILE);
        FS_RESP=length(RESP_TS)/(NUM_VOLUMES+DUMMY_VOLUMES)/TR;
        RESP_ONSETS=load(RESP_ONSETS_FILE)/FS_RESP;
    end
    if strcmp(ECG,'ON')
        ECG_TS=load(ECG_FILE);
        FS_ECG=length(ECG_TS)/(NUM_VOLUMES+DUMMY_VOLUMES)/TR;
        ECG_ONSETS=load(ECG_ONSETS_FILE)/FS_ECG;
    end
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% this is under cunstruction
    
elseif strcmp(TRACETYPE,'BRAINPRODUCTS')
    addpath(FTDIR);
    hdr=ft_read_header(fullfile(PHYS_DIR,[PHYS_FILE '.vhdr']));
    
    if strcmp(PULSE,'ON')
        idx = find(strcmp([{hdr.label{:}}], PULSELABEL));
        PULSE_TS=ft_read_data(PULSE_FILE,'chanindx',idx,...
            'begsample',SAMPLEVEC(1),'endsample',SAMPLEVEC(end));
        FS_PULSE=hdr.Fs;
        %PULSE_ONSETS will be found using findpeaks
    end
    if strcmp(RESP,'ON')
        idx = find(strcmp([{hdr.label{:}}], RESPLABEL))
        RESP_TS=-ft_read_data(RESP_FILE,'chanindx',idx,...
            'begsample',SAMPLEVEC(1),'endsample',SAMPLEVEC(end));
        FS_RESP=hdr.Fs;
        %RESP_ONSETS will be found using findpeaks
    end
    if strcmp(ECG,'ON')
        idx = find(strcmp([{hdr.label{:}}], ECGLABEL))
        ECG_TS=ft_read_data(ECG_FILE,'chanindx',idx,...
            'begsample',SAMPLEVEC(1),'endsample',SAMPLEVEC(end));
        FS_ECG=hdr.Fs;
        %ECG_ONSETS will be found using findpeaks
    end
    
    
    
    
    
    
    
    
    
end %(TRACETYPE)

if strcmp(RESP,'ESTIMATE')
    if strcmp(PULSE,'ON')
        display('The respiration will be estimated from the peak to peak variation in the pulse (NOT implemented yet)')
    elseif strcmp(ECG,'ON')
        display('The respiration will be estimated from the peak to peak variation in the ECG  (NOT implemented yet)')
    end
end

% This section uses MATLAB's findpeaks to determine peak locations
if strcmp(FIND_PULSEPEAKS,'ON')
    if strcmp(PULSE,'ON')
        if strcmp(LP_PULSE,'ON')
            FN=FS_PULSE/2;
            [B,A]=cheby2(CHEBY_ORDER,CHEBY_RIP,LP_PULSE_FSTOP/FN,'low');
            PULSE_TS = filtfilt(B,A,PULSE_TS);
        end
        %moving mean filter 100s
        %PULSE_TS=PULSE_TS-movingmean(PULSE_TS,(FS_PULSE*100)-1,2);
        
        
        mx=max(PULSE_TS);
        me=mean(PULSE_TS);
        interval=round(FS_PULSE*PULSEPEAKS_INTERVAL);
        [PEAKS PULSE_ONSETS]=findpeaks(PULSE_TS,'MINPEAKDISTANCE',interval,'MINPEAKHEIGHT',me);
        PULSE_ONSETS=PULSE_ONSETS/FS_PULSE;
    else
        error('PULSE must be set to ON')
    end
end

if strcmp(FIND_ECGPEAKS,'ON')
    if strcmp(ECG,'ON')
        if strcmp(LP_ECG,'ON')
            FN=FS_ECG/2;
            [B,A]=cheby2(CHEBY_ORDER,CHEBY_RIP,LP_ECG_FSTOP/FN,'low');
            ECG_TS = filtfilt(B,A,ECG_TS);
        end
        %moving mean filter 100s
        ECG_TS=ECG_TS-movingmean(ECG_TS,(FS_ECG*100)-1,2);
        
        mx=max(ECG_TS);
        me=mean(ECG_TS);
        interval=round(FS_ECG*ECGPEAKS_INTERVAL);
        [PEAKS ECG_ONSETS]=findpeaks(ECG_TS,'MINPEAKDISTANCE',interval,'MINPEAKHEIGHT',me);
        ECG_ONSETS=ECG_ONSETS/FS_ECG;
    else
        error('ECG must be set to ON')
    end
end


if strcmp(FIND_RESPPEAKS,'ON')
    if strcmp(RESP,'ON')
        if strcmp(LP_RESP,'ON')
            FN=FS_RESP/2;
            [B,A]=cheby2(CHEBY_ORDER,CHEBY_RIP,LP_RESP_FSTOP/FN,'low');
            RESP_TS_UNFILT=RESP_TS;
            RESP_TS = filtfilt(B,A,RESP_TS);
        end
        
        %moving mean filter 100s
        RESP_TS=RESP_TS-movingmean(RESP_TS,(FS_RESP*100)-1,2);
        
        mx=max(RESP_TS)
        mi=min(RESP_TS)
        if mx<-mi, RESP_TS=-RESP_TS;end
        me=mean(RESP_TS)
        
        interval=round(FS_RESP*RESPPEAKS_INTERVAL);
        [PEAKS RESP_ONSETS]=findpeaks(RESP_TS,'MINPEAKDISTANCE',interval,'MINPEAKHEIGHT',me);
        RESP_ONSETS=RESP_ONSETS/FS_RESP;
        if 1
           RESP_ONSETS=RESP_ONSETS-(2/FS_RESP);% Move the trigger 2 samples back in time 
        end
        if strcmp(TRACETYPE,'IOP')
            RESP_ONSETS=RESP_ONSETS-0.2;% Move the IOP trigger 200ms back in time
        end
    else
        error('RESP must be set to ON')
    end
end





% Here comes the standard RETROICOR regressors
% Inspired by Josephs et al 1997 and Glover et al. 2000
% This version does NOT use a special method for estimation the respiratory
% phase. This is the approach used in Lund et al. 2006

for ref=1:length(REF_SLICE)
    % Find the onsets for the reference slice. Note: NUM_VOLUMES is without DUMMY_VOLUMES
    FIRST_ONS=TR*(DUMMY_VOLUMES+((REF_SLICE(ref)-1)/NUM_SLICES));
    
    if REF_SLICE(ref)==1
        REF_SLICE_ONS=FIRST_ONS:TR:(NUM_VOLUMES+DUMMY_VOLUMES-1)*TR;
    elseif REF_SLICE(ref)>NUM_SLICES
        error('REF_SLICE must be a smaller than NUM_SLICES')
    elseif REF_SLICE(ref)>1
        REF_SLICE_ONS=FIRST_ONS:TR:(NUM_VOLUMES+DUMMY_VOLUMES)*TR;
    else
        error('REF_SLICE must be a positive integer')
    end
    
    if strcmp(PULSE,'ON')
        PULSE_PHASE=zeros(length(REF_SLICE_ONS),1);
        PULSE_RETROICOR=zeros(length(REF_SLICE_ONS),PULSE_ORDER*2);
        for i=1:length(REF_SLICE_ONS)
            [ttp idx2]=min(abs(REF_SLICE_ONS(i)-PULSE_ONSETS));
            if REF_SLICE_ONS(i)<PULSE_ONSETS(idx2)
                if idx2==1
                    ttp=REF_SLICE_ONS(i)-(PULSE_ONSETS(idx2)- ...
                        (PULSE_ONSETS(idx2)+PULSE_ONSETS(idx2+1)));
                    idx2=idx2+1;
                end
                ttp=REF_SLICE_ONS(i)-PULSE_ONSETS(idx2-1);
                idx2=idx2-1;
            end
            if idx2==length(PULSE_ONSETS)
                idx2=idx2-1;
            end
            PULSE_PHASE(i)=2*pi*ttp/(PULSE_ONSETS(idx2+1)-PULSE_ONSETS(idx2));
            for j=1:PULSE_ORDER
                PULSE_RETROICOR(i,2*j-1)=sin(PULSE_PHASE(i)*j);
                PULSE_RETROICOR(i,2*j)=cos(PULSE_PHASE(i)*j);
            end
        end
    end
    
    if strcmp(RESP,'ON')
        RESP_PHASE=zeros(length(REF_SLICE_ONS),1);
        RESP_RETROICOR=zeros(length(REF_SLICE_ONS),RESP_ORDER*2);
        for i=1:length(REF_SLICE_ONS)
            [ttp idx2]=min(abs(REF_SLICE_ONS(i)-RESP_ONSETS));
            if REF_SLICE_ONS(i)<RESP_ONSETS(idx2)
                if idx2==1
                    ttp=REF_SLICE_ONS(i)-(RESP_ONSETS(idx2)- ...
                        (RESP_ONSETS(idx2)+RESP_ONSETS(idx2+1)));
                    idx2=idx2+1;
                end
                ttp=REF_SLICE_ONS(i)-RESP_ONSETS(idx2-1);
                idx2=idx2-1;
            end
            if idx2==length(RESP_ONSETS)
                idx2=idx2-1;
            end
            RESP_PHASE(i)=2*pi*ttp/(RESP_ONSETS(idx2+1)-RESP_ONSETS(idx2));
            for j=1:RESP_ORDER
                RESP_RETROICOR(i,2*j-1)=sin(RESP_PHASE(i)*j);
                RESP_RETROICOR(i,2*j)=cos(RESP_PHASE(i)*j);
            end
        end
    end
    
    
    if strcmp(ECG,'ON')
        ECG_PHASE=zeros(length(REF_SLICE_ONS),1);
        ECG_RETROICOR=zeros(length(REF_SLICE_ONS),ECG_ORDER*2);
        for i=1:length(REF_SLICE_ONS)
            [ttp idx2]=min(abs(REF_SLICE_ONS(i)-ECG_ONSETS));
            if REF_SLICE_ONS(i)<ECG_ONSETS(idx2)
                if idx2==1
                    ttp=REF_SLICE_ONS(i)-(ECG_ONSETS(idx2)- ...
                        (ECG_ONSETS(idx2)+ECG_ONSETS(idx2+1)));
                    idx2=idx2+1;
                end
                ttp=REF_SLICE_ONS(i)-ECG_ONSETS(idx2-1);
                idx2=idx2-1;
            end
            if idx2==length(ECG_ONSETS)
                idx2=idx2-1;
            end
            ECG_PHASE(i)=2*pi*ttp/(ECG_ONSETS(idx2+1)-ECG_ONSETS(idx2));
            for j=1:ECG_ORDER
                ECG_RETROICOR(i,2*j-1)=sin(ECG_PHASE(i)*j);
                ECG_RETROICOR(i,2*j)=cos(ECG_PHASE(i)*j);
            end
        end
    end
    
    
    
    % The RVT regressor was suggested by Birn et al. 2006 and is based on work by Wise et al 2004
    if strcmp(RVT,'ON')
        if ~(strcmp(RESP,'ON')|strcmp(RESP,'ESTIMATE'))
            RVTWARNING='RVT regressor cannot be constructed RESP has to be ON or ESTIMATE';
            display(RVTWARNING)
        elseif strcmp(RVT,'ESTIMATE')
            RVTWARNING='RVT regressor cannot be constructed RESP has to be ON or ESTIMATE';
            display(RVTWARNING)
        else
            %only run redundant for first reference slice to reduce
            %computation time
            if ref==1
                % First we make a vector containing the breath to breath period and
                % frequency:
                BREATH_TO_BREATH_PERIOD=diff(RESP_ONSETS);
                BREATH_TO_BREATH_FREQUENCY=1./BREATH_TO_BREATH_PERIOD;
                
                % These frequencies are then associated with the timepoint between the
                % onsets:
                BREATH_TO_BREATH_FREQUENCY_ONSETS=RESP_ONSETS(1:end-1)+BREATH_TO_BREATH_PERIOD/2;
                
                TIME=(1:round(length(RESP_TS)))./FS_RESP;
                %TIME=(0:round(length(RESP_TS)-1))./FS_RESP;
                
                MINAMPTIME=zeros(1,length(RESP_ONSETS));
                MAXAMPTIME=zeros(1,length(RESP_ONSETS));
                MINAMP=zeros(1,length(RESP_ONSETS));
                MAXAMP=zeros(1,length(RESP_ONSETS));
                
                [MAXAMP(1) AMPIDX]=max(RESP_TS(1:round(min(find(TIME>=RESP_ONSETS(1))))));
                MAXAMPTIME(1)=TIME(1)+((AMPIDX-1)/FS_RESP);
                
                for j=2:length(RESP_ONSETS)
                    SIDX=find(TIME>=RESP_ONSETS(j-1) & TIME<=RESP_ONSETS(j));
                    [MAXAMP(j) AMPIDX]=max(RESP_TS(SIDX(2:end)));
                    MAXAMPTIME(j)=TIME(SIDX(2))+((AMPIDX-1)/FS_RESP);
                end
                
                for j=1:length(MAXAMPTIME)
                    if j==length(MAXAMPTIME)
                        SIDX=find(TIME>=MAXAMPTIME(j));
                    else
                        SIDX=find(TIME>=MAXAMPTIME(j) & TIME<=MAXAMPTIME(j+1));
                    end
                    [MINAMP(j) AMPIDX]=min(RESP_TS(SIDX(2:end)));
                    MINAMPTIME(j)=TIME(SIDX(2))+((AMPIDX-1)/FS_RESP);
                end
                
                if MAXAMPTIME(1)>3./FS_RESP
                    RESPAMP1=MAXAMP-MINAMP;
                    RESPAMP2=MAXAMP(2:end)-MINAMP(1:end-1);
                    MINAMPTIME=MINAMPTIME(:);
                    MAXAMPTIME=MAXAMPTIME(:);
                    RESPAMPTIME1=mean([MINAMPTIME MAXAMPTIME]');
                    RESPAMPTIME2=mean([MINAMPTIME(1:end-1) MAXAMPTIME(2:end)]');
                else
                    MAXAMPTIME(1)=[];
                    MAXAMP(1)=[];
                    RESPAMP1=MAXAMP-MINAMP(2:end);
                    RESPAMP2=MAXAMP-MINAMP(1:end-1);
                    MINAMPTIME=MINAMPTIME(:);
                    MAXAMPTIME=MAXAMPTIME(:);
                    RESPAMPTIME1=mean([MINAMPTIME(2:end) MAXAMPTIME]');
                    RESPAMPTIME2=mean([MINAMPTIME(1:end-1) MAXAMPTIME]');
                end
                RESPAMPTIME=[RESPAMPTIME1 RESPAMPTIME2];
                RESPAMP=[RESPAMP1 RESPAMP2];
                [RESPAMPTIME RESPSORTIDX]=sort(RESPAMPTIME);
                RESPAMP=RESPAMP(RESPSORTIDX);
                RESPAMP=RESPAMP(:);
            end
            
            RESPAMP_TR=interp1(RESPAMPTIME,RESPAMP,REF_SLICE_ONS,'nearest','extrap');
            RESPAMP_TR=RESPAMP_TR(:);
            
            RESP_PERIOD_TR=interp1(BREATH_TO_BREATH_FREQUENCY_ONSETS,1./BREATH_TO_BREATH_FREQUENCY,REF_SLICE_ONS,'nearest','extrap');
            RESP_PERIOD_TR=RESP_PERIOD_TR(:);
            
            RVT_RAW=RESPAMP_TR./RESP_PERIOD_TR-mean(RESPAMP_TR./RESP_PERIOD_TR);
            
            
            
            if ~isempty(RVT_DELAY)
                for i=1:length(RVT_DELAY)
                    RESPAMP_TR_SHIFT=interp1(RESPAMPTIME,RESPAMP,REF_SLICE_ONS-RVT_DELAY(i),'nearest','extrap');
                    RESP_PERIOD_TR_SHIFT=interp1(BREATH_TO_BREATH_FREQUENCY_ONSETS,1./BREATH_TO_BREATH_FREQUENCY,REF_SLICE_ONS-RVT_DELAY(i),'nearest','extrap');
                    RVT_DELAYED(:,i)=RESPAMP_TR_SHIFT./RESP_PERIOD_TR_SHIFT-mean(RESPAMP_TR_SHIFT./RESP_PERIOD_TR_SHIFT);
                end
                if length(RVT_DELAY)==1 % make delayed RVT and differential RVT
                    DIFF_RVT_DELAYED=[0 ;diff(RVT_DELAYED)];
                end
            end
        end
    end
    
    
    
    % The interaction regressors (between heartbeat and respiration is described
    % Brooks et al. NeuroImage doi: 10.1016/j.neuroimage.2007.09.018
    
    if strcmp(RESPXPULSE,'ON')
        if ~(strcmp(PULSE,'ON') & strcmp(RESP,'ON'))
            error('Both PULSE and RESP is needed')
        end
        for i=1:RESPXPULSE_ORDER
            RESPXPULSE_RETROICOR(:,4*i-3)=sin((PULSE_PHASE+RESP_PHASE)*i);
            RESPXPULSE_RETROICOR(:,4*i-2)=cos((PULSE_PHASE+RESP_PHASE)*i);
            RESPXPULSE_RETROICOR(:,4*i-1)=sin((PULSE_PHASE-RESP_PHASE)*i);
            RESPXPULSE_RETROICOR(:,4*i)=cos((PULSE_PHASE-RESP_PHASE)*i);
        end
    end
    
    if strcmp(RESPXECG,'ON')
        if ~(strcmp(ECG,'ON') & strcmp(RESP,'ON'))
            error('Both ECG and RESP is needed')
        end
        for i=1:RESPXECG_ORDER
            RESPXECG_RETROICOR(:,4*i-3)=sin((ECG_PHASE+RESP_PHASE)*i);
            RESPXECG_RETROICOR(:,4*i-2)=cos((ECG_PHASE+RESP_PHASE)*i);
            RESPXECG_RETROICOR(:,4*i-1)=sin((ECG_PHASE-RESP_PHASE)*i);
            RESPXECG_RETROICOR(:,4*i)=cos((ECG_PHASE-RESP_PHASE)*i);
        end
    end
    
    %Insert all values in the NVR structure
    
    NVRstruct(ref).tracetype=TRACETYPE;
    NVRstruct(ref).dicom_file=DICOM_FILE;
    NVRstruct(ref).phys_file=PHYS_FILE;
    NVRstruct(ref).phys_dir=PHYS_DIR;
    NVRstruct(ref).stop_stamp=STOP_STAMP;
    NVRstruct(ref).start_stamp=START_STAMP;
    
    NVRstruct(ref).TR=TR;
    NVRstruct(ref).num_slices=NUM_SLICES;
    NVRstruct(ref).num_volumes=NUM_VOLUMES;
    NVRstruct(ref).dummy_volumes=DUMMY_VOLUMES;
    NVRstruct(ref).ref_slice=REF_SLICE(ref);
    NVRstruct(ref).ref_slice_ons=REF_SLICE_ONS;
    
    NVRstruct(ref).pulse_logging=PULSE;
    NVRstruct(ref).pulse_order=PULSE_ORDER;
    NVRstruct(ref).pulse_file=PULSE_FILE;
    NVRstruct(ref).pulse_onsets_file=PULSE_ONSETS_FILE;
    NVRstruct(ref).fs_pulse=FS_PULSE;
    NVRstruct(ref).find_pulsepeaks=FIND_PULSEPEAKS;
    NVRstruct(ref).pulsewarning=PULSEWARNING;
    NVRstruct(ref).pulse_raw=PULSE_RAW;
    NVRstruct(ref).pulse_ts=PULSE_TS;
    NVRstruct(ref).pulse_peaks=PULSE_PEAKS;
    NVRstruct(ref).pulse_onsets=PULSE_ONSETS;
    NVRstruct(ref).pulse_phase=PULSE_PHASE;
    NVRstruct(ref).pulse_retroicor=PULSE_RETROICOR;
    
    
    
    NVRstruct(ref).respiration_logging=RESP;
    NVRstruct(ref).respiration_order=RESP_ORDER;
    NVRstruct(ref).resp_file=RESP_FILE;
    NVRstruct(ref).resp_onsets_file=RESP_ONSETS_FILE;
    NVRstruct(ref).rvt_delay=RVT_DELAY;
    NVRstruct(ref).fs_resp=FS_RESP;
    NVRstruct(ref).find_resppeaks=FIND_RESPPEAKS;
    NVRstruct(ref).respwarning=RESPWARNING;
    NVRstruct(ref).resp_raw=RESP_RAW;
    NVRstruct(ref).resp_ts=RESP_TS;
    NVRstruct(ref).resp_ts_unfilt=RESP_TS_UNFILT;
    NVRstruct(ref).resp_peaks=RESP_PEAKS;
    NVRstruct(ref).resp_onsets=RESP_ONSETS;
    NVRstruct(ref).resp_phase=RESP_PHASE;
    NVRstruct(ref).resp_retroicor=RESP_RETROICOR;
    
    
    
    NVRstruct(ref).ecg_logging=ECG;
    NVRstruct(ref).ecg_order=ECG_ORDER;
    NVRstruct(ref).ecg_file=ECG_FILE;
    NVRstruct(ref).ecg_onsets_file=ECG_ONSETS_FILE;
    NVRstruct(ref).fs_ecg=FS_ECG;
    NVRstruct(ref).find_ecgpeaks=FIND_ECGPEAKS;
    NVRstruct(ref).ecgwarning=ECGWARNING;
    NVRstruct(ref).ecg_raw=ECG_RAW;
    NVRstruct(ref).ecg_ts=ECG_TS;
    NVRstruct(ref).ecg_onsets=ECG_ONSETS;
    NVRstruct(ref).ecg_phase=ECG_PHASE;
    NVRstruct(ref).ecg_retroicor=ECG_RETROICOR;
    
    
    NVRstruct(ref).respamp_tr=RESPAMP_TR;
    NVRstruct(ref).respamp=RESPAMP;
    NVRstruct(ref).resp_period_tr=RESP_PERIOD_TR;
    NVRstruct(ref).rvt_raw=RVT_RAW;
    NVRstruct(ref).rvt_delayed=RVT_DELAYED;
    NVRstruct(ref).diff_rvt_delayed=DIFF_RVT_DELAYED;
    
    
    NVRstruct(ref).respxpuls_logging=RESPXPULSE;
    NVRstruct(ref).respxpuls_retroicor=RESPXPULSE_RETROICOR;
    
    NVRstruct(ref).respxecg_logging=RESPXECG;
    NVRstruct(ref).respxecg_retroicor=RESPXECG_RETROICOR;
    
end

% % % Just an idea: estimate resp from pulse or ecg
% if (strcmp(RESP,'ON') & strcmp(PULSE,'ON'))
%     t=[0:length(NVRstruct.resp_ts)-1]/NVRstruct.fs_resp;
%     figure,plot(t,NVRstruct.resp_ts)
%     hold on,
%     plot(t,interp1(NVRstruct.pulse_onsets(2:end),3000*diff(NVRstruct.pulse_onsets),t,'linear'),'r')
% end
