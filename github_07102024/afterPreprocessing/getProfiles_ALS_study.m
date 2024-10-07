
%% Load prepared variables into data structure
clear; clc; close all
subject=1;
num_conditions=2; %active and passive
ROIs=["ROI1" "ROI2"];
subjNames={'Late patient','Healthy control','Early patient'};

    for ROIcount=1:numel(ROIs)
        %active
        load(sprintf('/Users/au686880/Desktop/ALS_study/groupAnalysis/profiles_S%02d_active_%s.mat',subject,convertStringsToChars(ROIs(ROIcount))))
        data(ROIcount).active.betas=betas_NORDIC1;
        data(ROIcount).active.betas_micro=betas_micro_NORDIC1;
        data(ROIcount).active.betas_cleanedMagn=betas_cleanedMagn_NORDIC1;

        %passive
        load(sprintf('/Users/au686880/Desktop/ALS_study/groupAnalysis/profiles_S%02d_passive_%s.mat',subject,convertStringsToChars(ROIs(ROIcount))))
        data(ROIcount).passive.betas=betas_NORDIC1;
        data(ROIcount).passive.betas_micro=betas_micro_NORDIC1;
        data(ROIcount).passive.betas_cleanedMagn=betas_cleanedMagn_NORDIC1;


        %Common for active and passive:
        data(ROIcount).mean_EPI_magn=mean_EPI_magn;
        data(ROIcount).mask=mask;
        data(ROIcount).depthmap=depthmap;
        if subject==1
        data(ROIcount).highT1_1=T1_1;
        data(ROIcount).highT1_2=T1_2;
        data(ROIcount).highT1_3=T1_3;
        end
    end

clearvars -except data subject num_subjects num_conditions ROIs ROIcount subjNames


%% Get profiles
idx_run1=1:12;
idx_run2=13:24;
num_trials=numel(idx_run1)+numel(idx_run2);
stepsize=0.05;
lower_depth=0.075;
upper_depth=1-lower_depth;
if lower_depth-stepsize/2<0 || upper_depth+stepsize/2>1
    error('make sure desired upper and lower depths match stepsize')
end


for ROIcount=1:numel(ROIs)
    tmp_lower=lower_depth-stepsize/2;
    tmp_upper=tmp_lower+stepsize;
    tmp_depths=data(ROIcount).depthmap;
    if ROIcount==1
        run_idx=idx_run2; %when using ROI1 we want last half of trials
    elseif ROIcount==2
        run_idx=idx_run1; %when using ROI2 we want first half of trials
    end

    for layer=1:numel(lower_depth:stepsize:upper_depth)

        %Active
        tmp_active(ROIcount,layer,:)=mean(data(ROIcount).active.betas(tmp_depths>=tmp_lower & tmp_depths<tmp_upper,run_idx),1);
        tmp_active_micro(ROIcount,layer,:)=mean(data(ROIcount).active.betas_micro(tmp_depths>=tmp_lower & tmp_depths<tmp_upper,run_idx),1);
        tmp_active_cleanedMagn(ROIcount,layer,:)=mean(data(ROIcount).active.betas_cleanedMagn(tmp_depths>=tmp_lower & tmp_depths<tmp_upper,run_idx),1);

        %Passive
        tmp_passive(ROIcount,layer,:)=mean(data(ROIcount).passive.betas(tmp_depths>=tmp_lower & tmp_depths<tmp_upper,run_idx),1);
        tmp_passive_micro(ROIcount,layer,:)=mean(data(ROIcount).passive.betas_micro(tmp_depths>=tmp_lower & tmp_depths<tmp_upper,run_idx),1);
        tmp_passive_cleanedMagn(ROIcount,layer,:)=mean(data(ROIcount).passive.betas_cleanedMagn(tmp_depths>=tmp_lower & tmp_depths<tmp_upper,run_idx),1);

        %Mean EPI
        profiles_mean_EPI_magn(ROIcount,layer)=mean(mean(data(ROIcount).mean_EPI_magn(tmp_depths>=tmp_lower & tmp_depths<tmp_upper),1));

        if subject==1
        profiles_highT1_1(ROIcount,layer)=mean(mean(data(ROIcount).highT1_1(tmp_depths>=tmp_lower & tmp_depths<tmp_upper),1));
        profiles_highT1_2(ROIcount,layer)=mean(mean(data(ROIcount).highT1_2(tmp_depths>=tmp_lower & tmp_depths<tmp_upper),1));
        profiles_highT1_3(ROIcount,layer)=mean(mean(data(ROIcount).highT1_3(tmp_depths>=tmp_lower & tmp_depths<tmp_upper),1));
        end

        tmp_lower=tmp_lower+stepsize;
        tmp_upper=tmp_upper+stepsize;
    end
end


num_layers=size(tmp_active,2);
sampled_depths=lower_depth:stepsize:upper_depth;

%% Concatenate trials from each ROI:
profiles_active=squeeze(cat(3,tmp_active(1,:,:),tmp_active(2,:,:)));
profiles_active_micro=squeeze(cat(3,tmp_active_micro(1,:,:),tmp_active_micro(2,:,:)));
profiles_active_cleanedMagn=squeeze(cat(3,tmp_active_cleanedMagn(1,:,:),tmp_active_cleanedMagn(2,:,:)));

profiles_passive=squeeze(cat(3,tmp_passive(1,:,:),tmp_passive(2,:,:)));
profiles_passive_micro=squeeze(cat(3,tmp_passive_micro(1,:,:),tmp_passive_micro(2,:,:)));
profiles_passive_cleanedMagn=squeeze(cat(3,tmp_passive_cleanedMagn(1,:,:),tmp_passive_cleanedMagn(2,:,:)));

%% Get mean and stderr across trials functional
%Mean
acrossTrialMean_active=mean(profiles_active,2);
acrossTrialMean_active_micro=mean(profiles_active_micro,2);
acrossTrialMean_active_cleanedMagn=mean(profiles_active_cleanedMagn,2);

acrossTrialMean_passive=mean(profiles_passive,2);
acrossTrialMean_passive_micro=mean(profiles_passive_micro,2);
acrossTrialMean_passive_cleanedMagn=mean(profiles_passive_cleanedMagn,2);

%StdErr
acrossTrialStdErr_active=std(profiles_active,[],2)./sqrt(num_trials);
acrossTrialStdErr_active_micro=std(profiles_active_micro,[],2)./sqrt(num_trials);
acrossTrialStdErr_active_cleanedMagn=std(profiles_active_cleanedMagn,[],2)./sqrt(num_trials);

acrossTrialStdErr_passive=std(profiles_passive,[],2)./sqrt(num_trials);
acrossTrialStdErr_passive_micro=std(profiles_passive_micro,[],2)./sqrt(num_trials);
acrossTrialStdErr_passive_cleanedMagn=std(profiles_passive_cleanedMagn,[],2)./sqrt(num_trials);

%% Get mean across ROIs anatomical
%First get mean:
profile_mean_EPI_magn=squeeze(mean(profiles_mean_EPI_magn,1));

if subject==1
profile_highT1_1=squeeze(mean(profiles_highT1_1,1));
profile_highT1_2=squeeze(mean(profiles_highT1_2,1));
profile_highT1_3=squeeze(mean(profiles_highT1_3,1));
end

%% Plot functional profiles
lw=2; %linewidth
fontSize=15;
colorActive=[1 0.25 0];
colorPassive=[0 0.3 1];
colorWM=[248,255,127]./255;
colorVI=[255,204,127]./255;
colorVb=[136,255,127]./255;
colorVa=[255,127,255]./255;
colorSuperf=[134,255,255]./255;
colorCSF=[127,132,255]./255;

WMbound=0.15;
VIbound=0.375;
VAbound=0.675;
VBbound=VIbound+(VAbound-VIbound)/2;
Ibound=0.85;
facealpha=0.4; %transparency of patch

figure
set(gca,'FontSize',fontSize)
ylimits_micro=[0 3];
hold on
%set patches:
ylim(ylimits_micro); yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);

%plot functional profiles:
errorbar(sampled_depths,acrossTrialMean_active_micro,acrossTrialStdErr_active_micro,'r','linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_passive_micro,acrossTrialStdErr_passive_micro,'b','linewidth',lw)

%Insert CI95 for peak location (calculated below), 0.425=bin8, 0.475=bin9:
meanBootStrap=8.1006-1; %Calculated below (mean(samplePeaks_active)).
binToDepth=(max(sampled_depths)-min(sampled_depths))/(num_layers-1);
plot([0.425 0.475],[0.6 0.6],'r','LineWidth',lw+1);
plot([binToDepth*meanBootStrap+min(sampled_depths) binToDepth*meanBootStrap+min(sampled_depths)],[0.54 0.66],'k','linewidth',lw-1)

ylabel('Signal change (%)')
%legend('Attempted', 'Passive','location','north')
%title('Micro')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off


%% Plot anatomical profiles (and func included as subplot if S01)
lw=2;

if subject==1
%Highres T1 profiles:
profile_mean_highT1=mean([profile_highT1_1;profile_highT1_2;profile_highT1_3],1);
figure
subplot(3,1,1)
set(gca,'FontSize',fontSize)
hold on
%Set patches;
ylim([1 1.72]);yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
%Plot highres T1 profiles:
plot(sampled_depths,profile_highT1_1,'color',[0.4 0.4 0.4],'linewidth',lw)
plot(sampled_depths,profile_highT1_2,'color',[0.4 0.4 0.4],'linewidth',lw)
plot(sampled_depths,profile_highT1_3,'color',[0.4 0.4 0.4],'linewidth',lw)
plot(sampled_depths,profile_mean_highT1,'k-o','linewidth',lw)
ylabel('T1 (s)')
%title('Mean T1 highres')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

subplot(3,1,2)
%compute first derivative of profiles:
profile_dif_highT1_1=diff(profile_highT1_1);
profile_dif_highT1_2=diff(profile_highT1_2);
profile_dif_highT1_3=diff(profile_highT1_3);
profile_meanDif_highT1=mean([profile_dif_highT1_1;profile_dif_highT1_2;profile_dif_highT1_3],1);
profile_stdErrDif_highT1=std([profile_dif_highT1_1;profile_dif_highT1_2;profile_dif_highT1_3],[],1)./sqrt(3);
set(gca,'FontSize',fontSize)
hold on
%set patches:
ylim([-0.02 0.21]);yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
%plot first derivative profiles:
plot([0 1],[0 0],'k-','linewidth',lw-1)
errorbar(sampled_depths(1:end-1)+0.5*stepsize,profile_meanDif_highT1,profile_stdErrDif_highT1,'k-o','linewidth',lw)
ylabel('First derivative')
%title('Mean T1 highres diff')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

subplot(3,1,3)
set(gca,'FontSize',fontSize)
hold on
%set patches:
ylim(ylimits_micro);yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);

%plot functional profiles:
errorbar(sampled_depths,acrossTrialMean_active_micro,acrossTrialStdErr_active_micro,'r','linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_passive_micro,acrossTrialStdErr_passive_micro,'b','linewidth',lw)

%Insert CI95 for peak location (calculated below), 0.425=bin8, 0.475=bin9:
meanBootStrap=8.1006-1; %Calculated below (mean(samplePeaks_active)).
binToDepth=(max(sampled_depths)-min(sampled_depths))/(num_layers-1);
plot([0.425 0.475],[0.6 0.6],'r','LineWidth',lw+1);
plot([binToDepth*meanBootStrap+min(sampled_depths) binToDepth*meanBootStrap+min(sampled_depths)],[0.54 0.66],'k','linewidth',lw-1)
ylabel('Signal change (%)')

%legend('Attempted', 'Passive','location','north')
%title('Micro')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off
end


%% Make bar graphs M1S1Control analysis
%First load prepared mat-files and average across voxels in each ROI, and then get mean and stdErr across trials:

load(sprintf('/Users/au686880/Desktop/ALS_study/groupAnalysis/M1S1Control_S%02d_active.mat',subject))
data_M1S1Control(subject).M1S1Control_active_betas_micro=M1S1Control_betas_micro_NORDIC1;

load(sprintf('/Users/au686880/Desktop/ALS_study/groupAnalysis/M1S1Control_S%02d_passive.mat',subject))
data_M1S1Control(subject).M1S1Control_passive_betas_micro=M1S1Control_betas_micro_NORDIC1;

tmp_ROI=M1S1Control_ROI;
tmp_active_betas=data_M1S1Control(subject).M1S1Control_active_betas_micro;
tmp_passive_betas=data_M1S1Control(subject).M1S1Control_passive_betas_micro;

for largeROI=1:5 %M1=1, S1=2, control1=3, control2=4, control3=5
    M1S1Control_acrossVoxMean_active(largeROI,:)=mean(tmp_active_betas(tmp_ROI==largeROI,:),1);
    M1S1Control_acrossVoxMean_passive(largeROI,:)=mean(tmp_passive_betas(tmp_ROI==largeROI,:),1);

    M1S1Control_acrossTrialMean_active(largeROI)=mean(M1S1Control_acrossVoxMean_active(largeROI,:));
    M1S1Control_acrossTrialMean_passive(largeROI)=mean(M1S1Control_acrossVoxMean_passive(largeROI,:));

    M1S1Control_acrossTrialStdErr_active(largeROI)=std(M1S1Control_acrossVoxMean_active(largeROI,:))./sqrt(num_trials);
    M1S1Control_acrossTrialStdErr_passive(largeROI)=std(M1S1Control_acrossVoxMean_passive(largeROI,:))./sqrt(num_trials);
end

%Make bar graphs:
figure
widthBar=0.2;
hold on
barCounter=1;
for largeROI=1:5  %M1=1, S1=2, control1=3, control2=4, control3=5
    bar(barCounter/2-0.1,M1S1Control_acrossTrialMean_active(largeROI),'barwidth',widthBar,'facecolor',colorActive)
    bar(barCounter/2+0.1,M1S1Control_acrossTrialMean_passive(largeROI),'barwidth',widthBar,'facecolor',colorPassive)
    plot((barCounter/2-0.1)+0.01*randn(1,num_trials),M1S1Control_acrossVoxMean_active(largeROI,:),'.k','MarkerSize',15)
    plot((barCounter/2+0.1)+0.01*randn(1,num_trials),M1S1Control_acrossVoxMean_passive(largeROI,:),'.k','MarkerSize',15)
    errorbar(barCounter/2-0.1,M1S1Control_acrossTrialMean_active(largeROI),M1S1Control_acrossTrialStdErr_active(largeROI),'Color',[0.6 0.6 0.6],'linewidth',3)
    errorbar(barCounter/2+0.1,M1S1Control_acrossTrialMean_passive(largeROI),M1S1Control_acrossTrialStdErr_passive(largeROI),'Color',[0.6 0.6 0.6],'linewidth',3)
    barCounter=barCounter+1;
end
ylabel('Signal change (%)')
ylim([-0.3 1.5])
set(gca,'XTick',(1:5)./2)
set(gca,'XTickLabel',{'M1','S1','Control 1','Control 2','Control 3'})
set(gca,'FontSize',fontSize)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

%% Make bar graphs M1S1Control analysis 2dEPI (S01)
%First prepare 2dEPI in same way as above:
num_trials_2dEPI=5;
load('/Users/au686880/Desktop/ALS_study/groupAnalysis/M1S1Control_S01_active.mat')
data_M1S1Control(1).M1S1Control_active_betas_2dEPI=M1S1Control_betas_2dEPI_smooth;
    
load('/Users/au686880/Desktop/ALS_study/groupAnalysis/M1S1Control_S01_passive.mat')
data_M1S1Control(1).M1S1Control_passive_betas_2dEPI=M1S1Control_betas_2dEPI_smooth;
    
tmp_ROI=M1S1Control_ROI;
tmp_active_betas=data_M1S1Control(1).M1S1Control_active_betas_2dEPI;
tmp_passive_betas=data_M1S1Control(1).M1S1Control_passive_betas_2dEPI;

for largeROI=1:5 %M1=1, S1=2, control1=3, control2=4, control3=5
    M1S1Control_acrossVoxMean_active_2dEPI(1,largeROI,:)=mean(tmp_active_betas(tmp_ROI==largeROI,:),1);
    M1S1Control_acrossVoxMean_passive_2dEPI(1,largeROI,:)=mean(tmp_passive_betas(tmp_ROI==largeROI,:),1);

    M1S1Control_acrossTrialMean_active_2dEPI(1,largeROI)=mean(M1S1Control_acrossVoxMean_active_2dEPI(1,largeROI,:),3);
    M1S1Control_acrossTrialMean_passive_2dEPI(1,largeROI)=mean(M1S1Control_acrossVoxMean_passive_2dEPI(1,largeROI,:),3);

    M1S1Control_acrossTrialStdErr_active_2dEPI(1,largeROI)=std(M1S1Control_acrossVoxMean_active_2dEPI(1,largeROI,:),[],3)./sqrt(num_trials_2dEPI);
    M1S1Control_acrossTrialStdErr_passive_2dEPI(1,largeROI)=std(M1S1Control_acrossVoxMean_passive_2dEPI(1,largeROI,:),[],3)./sqrt(num_trials_2dEPI);
end


%Make bar graphs:
figure
hold on
barCounter=1;
for largeROI=1:2  %M1=1, S1=2, control1=3, control2=4, control3=5
    bar(barCounter/2-0.1,M1S1Control_acrossTrialMean_active_2dEPI(1,largeROI),'barwidth',widthBar,'facecolor',colorActive)
    bar(barCounter/2+0.1,M1S1Control_acrossTrialMean_passive_2dEPI(1,largeROI),'barwidth',widthBar,'facecolor',colorPassive)
    plot((barCounter/2-0.1)+0.01*randn(1,num_trials_2dEPI),squeeze(M1S1Control_acrossVoxMean_active_2dEPI(1,largeROI,:)),'.k','MarkerSize',20)
    plot((barCounter/2+0.1)+0.01*randn(1,num_trials_2dEPI),squeeze(M1S1Control_acrossVoxMean_passive_2dEPI(1,largeROI,:)),'.k','MarkerSize',20)
    errorbar(barCounter/2-0.1,M1S1Control_acrossTrialMean_active_2dEPI(1,largeROI),M1S1Control_acrossTrialStdErr_active_2dEPI(1,largeROI),'Color',[0.6 0.6 0.6],'linewidth',3)
    errorbar(barCounter/2+0.1,M1S1Control_acrossTrialMean_passive_2dEPI(1,largeROI),M1S1Control_acrossTrialStdErr_passive_2dEPI(1,largeROI),'Color',[0.6 0.6 0.6],'linewidth',3)
    barCounter=barCounter+1;
end
xlim([0.1 1.4])
ylim([-0.1 1.7])
ylabel('Signal change (%)')
%title(sprintf('%s low res',subjNames{1}))
set(gca,'XTick',(1:2)./2)
set(gca,'XTickLabel',{'M1','S1'})
set(gca,'FontSize',20)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

%% Plot micro, and cleanedMagn in same
figure
set(gca,'FontSize',fontSize)
ylimits_micro=[0 3.5];
ylimits_cleanedMagn=[0 5.5];
hold on
ylim(ylimits_cleanedMagn)
errorbar(sampled_depths,acrossTrialMean_active_micro,acrossTrialStdErr_active_micro,'r','linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_active_cleanedMagn,acrossTrialStdErr_active_cleanedMagn,'r--','linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_passive_micro,acrossTrialStdErr_passive_micro,'b','linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_passive_cleanedMagn,acrossTrialStdErr_passive_cleanedMagn,'b--','linewidth',lw)
plot([WMbound WMbound],gca().YLim,'k--','linewidth',lw) %vertical line at WM boundary
plot([Ibound Ibound],gca().YLim,'k--','linewidth',lw) %vertical line at I boundary
ylabel('Signal change (%)')
legend('Attempted phase regression','Attempted no phase regression','Passive phase regression','Passive no phase regression','location','north')
set(gca,'XTick',[WMbound/2 ...
    Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off


%% Run statistics
%1) 
%Evaluate whether attempted/passive movements have significant M1/S1 signal compared
%to control:
difs_aM1=M1S1Control_acrossVoxMean_active(1,:)-mean(M1S1Control_acrossVoxMean_active(3:5,:),1);
[~,p_aM1,CI_aM1,STATS_aM1] = ttest(difs_aM1);

difs_aS1=M1S1Control_acrossVoxMean_active(2,:)-mean(M1S1Control_acrossVoxMean_active(3:5,:),1);
[~,p_aS1,CI_aS1,STATS_aS1] = ttest(difs_aS1);

difs_pM1=M1S1Control_acrossVoxMean_passive(1,:)-mean(M1S1Control_acrossVoxMean_passive(3:5,:),1);
[~,p_pM1,CI_pM1,STATS_pM1] = ttest(difs_pM1);

difs_pS1=M1S1Control_acrossVoxMean_passive(2,:)-mean(M1S1Control_acrossVoxMean_passive(3:5,:),1);
[~,p_pS1,CI_pS1,STATS_pS1] = ttest(difs_pS1);

%Bonferroni:
N_bonf=4;
p_aM1_corrected=p_aM1*N_bonf;
p_aS1_corrected=p_aS1*N_bonf;
p_pM1_corrected=p_pM1*N_bonf;
p_pS1_corrected=p_pS1*N_bonf;


%2) 
%Evaluate M1/S1 ratio
difM1S1_highRes=M1S1Control_acrossVoxMean_active(1,:) - M1S1Control_acrossVoxMean_active(2,:);
difM1S1_lowRes=squeeze(M1S1Control_acrossVoxMean_active_2dEPI(1,1,:) - M1S1Control_acrossVoxMean_active_2dEPI(1,2,:));
[~,pM1S1_high,ciM1S1_high,statsM1S1_high] = ttest(difM1S1_highRes); %get confidence interval high
[~,pM1S1_low,ciM1S1_low,statsM1S1_low] = ttest(difM1S1_lowRes); %get confidence interval low
[~,pM1S1,ciM1S1,statsM1S1] = ttest2(difM1S1_highRes,difM1S1_lowRes);

figure
hold on
bar(0.5,mean(difM1S1_highRes),'barwidth',widthBar,'facecolor',[0.5 0.5 0.5])
bar(1,mean(difM1S1_lowRes),'barwidth',widthBar,'facecolor',[0.5 0.5 0.5])
plot(0.5+0.01*randn(1,numel(difM1S1_highRes)),difM1S1_highRes,'.k','MarkerSize',20)
plot(1+0.01*randn(1,numel(difM1S1_lowRes)),difM1S1_lowRes,'.k','MarkerSize',20)
errorbar(0.5,mean(difM1S1_highRes),std(difM1S1_highRes)./sqrt(numel(difM1S1_highRes)),'Color',[0.6 0.6 0.6],'linewidth',3)
errorbar(1,mean(difM1S1_lowRes),std(difM1S1_lowRes)./sqrt(numel(difM1S1_lowRes)),'Color',[0.6 0.6 0.6],'linewidth',3)
% xlim([0.1 1.4])
% ylim([-0.1 1.5])
ylabel('Signal change (%)')
set(gca,'XTick',[0.5,1])
set(gca,'XTickLabel',{'Laminar setup','Conventional setup'})
set(gca,'FontSize',20)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

%3)
%Assess significance of laminar profiles with cluster based permutation
%tests:
t_profile_active=acrossTrialMean_active_micro./acrossTrialStdErr_active_micro;
t_profile_passive=acrossTrialMean_passive_micro./acrossTrialStdErr_passive_micro;

%First visualize which individual clusters survives p<0.05 uncorrected:
dashLineValue=2.1; %23 DOF
figure
hold on
plot(sampled_depths,t_profile_active,'r*','linewidth',2)
plot(sampled_depths,t_profile_passive,'b*','linewidth',2)
plot([0 1],[dashLineValue dashLineValue],'k--')
xlabel('Cortical depth')
set(gca,'XTick',[WMbound/2 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','Va','CSF'})
xlabel('depth from WM to CSF')
ylabel('t-value')
xlim([0 1])
legend('active','passive')
title('t-values')
hold off

% Obtain permuted distribution of maximum tSums
num_permutations=10000; %see test_by_permutation_test.m
maxSums_permDistribution_active = permutation_test_4twoSidedALS_study(profiles_active_micro, zeros(size(profiles_active_micro)), num_permutations);
maxSums_permDistribution_passive = permutation_test_4twoSidedALS_study(profiles_passive_micro, zeros(size(profiles_passive_micro)), num_permutations);


%Compute p-value for clusters of interest and plot (ill do it individilly for each layer since all turned out p<0.05 uncorrected):
figure
plot([0 num_layers+1],[0.05 0.05],'--k')
hold on
for i=1:num_layers
insideClusterLayers=i; %Check in t-profile plot
summed_tval_cluster_active=sum(t_profile_active(insideClusterLayers));
summed_tval_cluster_passive=sum(t_profile_passive(insideClusterLayers));
p_clust_active=sum(abs(maxSums_permDistribution_active)>=abs(summed_tval_cluster_active))./num_permutations;
p_clust_passive=sum(abs(maxSums_permDistribution_passive)>=abs(summed_tval_cluster_passive))./num_permutations;
plot(i,p_clust_active,'r.')
plot(i,p_clust_passive,'b.')
end
hold off


%% Run bootstrapping for 95CI of deep layer peak bin:
depthsOfInterest=1:13; %We ignore superficial layers due to vascular bias

for i=1:10000
    %Draw random trials with replacement:
    tmp_trials_active=randi([1,num_trials],1,num_trials);
    %Average trials for current iteration:
    sampleAVG_profiles_active(:,i)=mean(profiles_active_micro(depthsOfInterest,tmp_trials_active),2);
    %Get peak depth for current iteration:
    [peakVal_active,idx_peakVal_active]=max(sampleAVG_profiles_active(:,i));
    samplePeaks_active(i)=idx_peakVal_active;
end

figure,histogram(samplePeaks_active)



%% Plot functional profiles each run separately
figure
subplot(2,1,1)
set(gca,'FontSize',fontSize)
hold on
%set patches:
ylim([-0.07,3.5]); yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
%Plot profiles:
plot(sampled_depths,acrossTrialMean_active_micro,'r','linewidth',lw)
plot(sampled_depths,profiles_active_micro(:,1:num_trials/2),'Color',[0.2 0.2 0.2])
plot(sampled_depths,profiles_active_micro(:,num_trials/2+1:num_trials),'Color',[0.6 0.6 0.6])
ylabel('Signal change (%)')
title('Micro attempted')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

subplot(2,1,2)
set(gca,'FontSize',fontSize)
hold on
%set patches:
ylim([-0.16,3.8]); yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
%Plot profiles:
plot(sampled_depths,acrossTrialMean_passive_micro,'b','linewidth',lw)
plot(sampled_depths,profiles_passive_micro(:,1:num_trials/2),'Color',[0.2 0.2 0.2])
plot(sampled_depths,profiles_passive_micro(:,num_trials/2+1:num_trials),'Color',[0.6 0.6 0.6])
ylabel('Signal change (%)')
title('Micro passive')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off


%% Plot absolute signal change profiles
%To test whether peak in deep layers was an "artefact" of the drop in
%baseline signal in deep layers due to iron accumulation we plot the
%absolute signal change profiles (where baseline signal is multiplied back
%onto the percent signal change profile). 
absChange_active_micro=(acrossTrialMean_active_micro/100).*profile_mean_EPI_magn';

figure
subplot(3,1,1)
hold on
ylim([650 1000]); yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
ylabel('a.u.')
title('Mean EPI profile')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'FontSize',fontSize)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
%Plot mean EPI profile
plot(sampled_depths,profile_mean_EPI_magn,'k','linewidth',lw)
hold off

subplot(3,1,2)
hold on
ylim([0 22]); yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
ylabel('a.u.')
title('Profile attempted absolute signal change')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'FontSize',fontSize)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
%plot absolute signal change profile:
plot(sampled_depths,absChange_active_micro,'r','linewidth',lw)
hold off 

subplot(3,1,3)
hold on
ylim([0 3.5]); yl=ylim; ys=[yl(1) yl(2) yl(2) yl(1)];
patch([0 0 WMbound WMbound],ys,'g','edgecolor','none','facecolor',colorWM,'facealpha',facealpha);
patch([WMbound WMbound VIbound VIbound],ys,'g','edgecolor','none','facecolor',colorVI,'facealpha',facealpha);
patch([VIbound VIbound VBbound VBbound],ys,'g','edgecolor','none','facecolor',colorVb,'facealpha',facealpha);
patch([VBbound VBbound VAbound VAbound],ys,'g','edgecolor','none','facecolor',colorVa,'facealpha',facealpha);
patch([VAbound VAbound Ibound Ibound],ys,'g','edgecolor','none','facecolor',colorSuperf,'facealpha',facealpha);
patch([Ibound Ibound 1 1],ys,'g','edgecolor','none','facecolor',colorCSF,'facealpha',facealpha);
ylabel('a.u.')
title('Normalized relative and absolute attempted profiles')
set(gca,'XTick',[WMbound/2, ...
                 WMbound+(VIbound-WMbound)/2,...
                 VIbound+(VBbound-VIbound)/2,...
                 VBbound+(VAbound-VBbound)/2,...
                 VAbound+(Ibound-VAbound)/2,...
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','VI','Vb','Va','III/II-I','CSF'})
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'FontSize',fontSize)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
%plot scaled versions of relative and absolute signal change profiles
plot(sampled_depths,absChange_active_micro./mean(absChange_active_micro),'r','linewidth',lw)
plot(sampled_depths,acrossTrialMean_active_micro./mean(acrossTrialMean_active_micro),'r--','linewidth',lw)
hold off






