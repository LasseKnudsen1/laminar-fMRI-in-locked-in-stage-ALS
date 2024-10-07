TRACETYPE       ='BRAINPRODUCTS';


PULSE           ='ON';
RESP            ='ON';
ECG             ='OFF';

RVT             ='OFF'; %REMEMBER to test this!!!!!!!!!!!!!!!!
RESPXECG        ='OFF';
RESPXPULSE      ='OFF';

PULSE_ORDER     =5;
RESP_ORDER      =5;
ECG_ORDER       =5;

RESPXPULSE_ORDER=1;
RESPXECG_ORDER=1;

START_STAMP     ='MG_START';
STOP_STAMP      ='MG_STOP';

DUMMY_VOLUMES   ='DEFAULT';



% Leave these strings empty if tracetype is not BRAINPRODUCTS
RESPLABEL='RESP';
PULSELABEL='PLETH';
ECGLABEL='ECG';
SAMPLEVEC= [1:1200000];%the samplevec could include the dummy volumes if this is specified
FTDIR           = [spm('dir') '/external/fieldtrip/fileio'];


%%% Also remember to turn on peak detection (see later)
% end BRAINPRODUCTS


DICOM_FILE      ='';
PHYS_FILE       ='';
PHYS_DIR        ='/Data/physfiles/';
PHYS_FILTER     ='^mg_\d*_\d*.puls';
PHYS_DATE.YEAR_IDX=4:7;
PHYS_DATE.MONTH_IDX=8:9;
PHYS_DATE.DAY_IDX=10:11;
PHYS_DATE.HOUR_IDX=13:14;
PHYS_DATE.MINS_IDX=15:16;
PHYS_DATE.SEC_IDX=17:18;





TR=2.2;
NUM_VOLUMES=484;
NUM_SLICES=26;
REF_SLICE=13;


RESP_FILE='';
ECG_FILE='';
PULSE_FILE='';
RESP_ONSETS_FILE='';
ECG_ONSETS_FILE='';
PULSE_ONSETS_FILE='';


RVT_DELAY=-5:1:10;
RVT_DELAY=-10:0.5:30;
RVT_DELAY=[-10:1:30];

%These should be on if TRACETYPE is BRAINPRODUCTS
FIND_PULSEPEAKS='ON';
FIND_ECGPEAKS='OFF';
FIND_RESPPEAKS='ON';

%These filtersettings can be applied if FIND_*PEAKS is ON
CHEBY_ORDER=5; %Order of cheby2 filter
CHEBY_RIP=20; %Ripples in decibel start with 20
LP_PULSE='ON'; %use on if you want to filter pulse ts before peakdetection
LP_RESP='ON'; %use on if you want to filter resp ts before peakdetection
LP_ECG='ON'; %use on if you want to filter ecg ts before peakdetection
LP_PULSE_FSTOP=5; %lowpass filter the pulse at 5Hz
LP_RESP_FSTOP=3; %lowpass filter the resp at 5Hz
LP_ECG_FSTOP=5; %lowpass filter the ecg at 5Hz
%minimal peakinterval in seconds
PULSEPEAKS_INTERVAL=1/3; %assume that no-one has a pulse above 180bpm in the scanner
RESPPEAKS_INTERVAL=0.7; %assume each breath is at least ??s apart from the previous one 
ECGPEAKS_INTERVAL=1/3; %assume that no-one has a pulse above 180bpm in the scanner






DICOM_HDR=[];


FS_PULSE=[];
FS_RESP=[];
FS_ECG=[];


PULSEWARNING='';
RESPWARNING='';
ECGWARNING='';
PULSE_RAW=[];
RESP_RAW=[];
ECG_RAW=[];

PULSE_TS=[];
RESP_TS=[];
ECG_TS=[];

PULSE_PEAKS=[];
RESP_PEAKS=[];
ECG_PEAKS=[];

PULSE_ONSETS=[];
RESP_ONSETS=[];
ECG_ONSETS=[];

PULSE_PHASE=[];
RESP_PHASE=[];
ECG_PHASE=[];

PULSE_RETROICOR=[];
RESP_RETROICOR=[];
ECG_RETROICOR=[];

RESPXPULSE_RETROICOR=[];
RESPXECG_RETROICOR=[];


RESPAMP_TR=[];
RESPAMP=[];
RESP_PERIOD_TR=[];

RVT_RAW=[];
RVT_DELAYED=[];
DIFF_RVT_DELAYED=[];


