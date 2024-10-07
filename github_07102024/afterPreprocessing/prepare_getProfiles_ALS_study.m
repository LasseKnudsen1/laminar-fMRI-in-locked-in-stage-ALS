clear; clc; close all
subjects=[1];
for subj=subjects
    for condition=["active","passive"]
        for ROI=["ROI1" "ROI2"]
            clearvars -except subj condition ROI
            %% Main analysis
            betasDir=sprintf('/Users/au686880/Desktop/ALS_study/analyzed/S%02d/extraMaps',subj);
            roiDir=sprintf('/Users/au686880/Desktop/ALS_study/analyzed/S%02d/getROI',subj);
            swiDir=sprintf('/Users/au686880/Desktop/ALS_study/alignSWI/S%02d',subj);
            M1S1ControlDir=sprintf('/Users/au686880/Desktop/ALS_study/M1S1ControlAnalysis/S%02d',subj);
            cd(betasDir)

            %Load files:
            betas_noNORDIC=single(spm_read_vols(spm_vol(['./betas_' convertStringsToChars(condition) '_noNORDIC_resample.nii'])));
            betas_NORDIC=single(spm_read_vols(spm_vol(['./betas_' convertStringsToChars(condition) '_NORDIC_resample.nii'])));
            betas_NORDIC1=single(spm_read_vols(spm_vol(['./betas_' convertStringsToChars(condition) '_NORDIC1_resample.nii'])));

            betas_micro_noNORDIC=single(spm_read_vols(spm_vol(['./betas_micro_' convertStringsToChars(condition) '_noNORDIC_resample.nii'])));
            betas_micro_NORDIC=single(spm_read_vols(spm_vol(['./betas_micro_' convertStringsToChars(condition) '_NORDIC_resample.nii'])));
            betas_micro_NORDIC1=single(spm_read_vols(spm_vol(['./betas_micro_' convertStringsToChars(condition) '_NORDIC1_resample.nii'])));

            betas_cleanedMagn_noNORDIC=single(spm_read_vols(spm_vol(['./betas_cleanedMagn_' convertStringsToChars(condition) '_noNORDIC_resample.nii'])));
            betas_cleanedMagn_NORDIC=single(spm_read_vols(spm_vol(['./betas_cleanedMagn_' convertStringsToChars(condition) '_NORDIC_resample.nii'])));
            betas_cleanedMagn_NORDIC1=single(spm_read_vols(spm_vol(['./betas_cleanedMagn_' convertStringsToChars(condition) '_NORDIC1_resample.nii'])));

            mean_EPI_magn=single(spm_read_vols(spm_vol([roiDir '/mean_rnoNORDIC_BOLD_01magn_resample.nii'])));


            %Load layers and mask:
            depthmap=single(spm_read_vols(spm_vol([roiDir '/segmentation_metric_equidist.nii'])));
            mask=single(spm_read_vols(spm_vol([roiDir '/' convertStringsToChars(ROI) '.nii'])));


            %Mask and reshape
            %Reshape to vector format:
            s=size(betas_micro_noNORDIC);
            betas_noNORDIC=reshape(betas_noNORDIC,s(1)*s(2)*s(3),s(4));
            betas_NORDIC=reshape(betas_NORDIC,s(1)*s(2)*s(3),s(4));
            betas_NORDIC1=reshape(betas_NORDIC1,s(1)*s(2)*s(3),s(4));

            betas_micro_noNORDIC=reshape(betas_micro_noNORDIC,s(1)*s(2)*s(3),s(4));
            betas_micro_NORDIC=reshape(betas_micro_NORDIC,s(1)*s(2)*s(3),s(4));
            betas_micro_NORDIC1=reshape(betas_micro_NORDIC1,s(1)*s(2)*s(3),s(4));

            betas_cleanedMagn_noNORDIC=reshape(betas_cleanedMagn_noNORDIC,s(1)*s(2)*s(3),s(4));
            betas_cleanedMagn_NORDIC=reshape(betas_cleanedMagn_NORDIC,s(1)*s(2)*s(3),s(4));
            betas_cleanedMagn_NORDIC1=reshape(betas_cleanedMagn_NORDIC1,s(1)*s(2)*s(3),s(4));

            mean_EPI_magn=reshape(mean_EPI_magn,s(1)*s(2)*s(3),1);

            depthmap=reshape(depthmap,s(1)*s(2)*s(3),1);
            mask=reshape(mask,s(1)*s(2)*s(3),1);

            %Find indices of voxels within ROI and remove all voxels outside ROI:
            idx=find(mask>0 & depthmap>0);
            betas_noNORDIC=betas_noNORDIC(idx,:);
            betas_NORDIC=betas_NORDIC(idx,:);
            betas_NORDIC1=betas_NORDIC1(idx,:);

            betas_micro_noNORDIC=betas_micro_noNORDIC(idx,:);
            betas_micro_NORDIC=betas_micro_NORDIC(idx,:);
            betas_micro_NORDIC1=betas_micro_NORDIC1(idx,:);

            betas_cleanedMagn_noNORDIC=betas_cleanedMagn_noNORDIC(idx,:);
            betas_cleanedMagn_NORDIC=betas_cleanedMagn_NORDIC(idx,:);
            betas_cleanedMagn_NORDIC1=betas_cleanedMagn_NORDIC1(idx,:);

            mean_EPI_magn=mean_EPI_magn(idx,1);

            depthmap=depthmap(idx,1);
            mask=mask(idx,1);

            % Get highres T1 from sess2 patient:
            if subj==1
            T1_1=spm_read_vols(spm_vol('/Users/au686880/Desktop/ALS_study/analyzed/S01/highResMP2RAGE/T1map1_al.nii'));
            T1_2=spm_read_vols(spm_vol('/Users/au686880/Desktop/ALS_study/analyzed/S01/highResMP2RAGE/T1map2_al.nii'));
            T1_3=spm_read_vols(spm_vol('/Users/au686880/Desktop/ALS_study/analyzed/S01/highResMP2RAGE/T1map3_al.nii'));

            %Reshape:
            T1_1=reshape(T1_1,s(1)*s(2)*s(3),1);
            T1_2=reshape(T1_2,s(1)*s(2)*s(3),1);
            T1_3=reshape(T1_3,s(1)*s(2)*s(3),1);
           
            %Mask:
            T1_1=T1_1(idx,1);
            T1_2=T1_2(idx,1);
            T1_3=T1_3(idx,1);
            end


            %% Save
            outputDir='/Users/au686880/Desktop/ALS_study/groupAnalysis';
            outputName=sprintf('%s/profiles_S%02d_%s_%s.mat',outputDir,subj,condition,convertStringsToChars(ROI));
            save(outputName,...
                's','idx','mask','depthmap',...
                'betasDir','outputDir','outputName',...
                'betas_noNORDIC','betas_NORDIC','betas_NORDIC1', ...
                'betas_micro_noNORDIC','betas_micro_NORDIC','betas_micro_NORDIC1', ...
                'betas_cleanedMagn_noNORDIC','betas_cleanedMagn_NORDIC','betas_cleanedMagn_NORDIC1', ...
                'mean_EPI_magn')

            if subj==1
            save(outputName,'T1_1','T1_2','T1_3','-append')  
            end
        end


        %% M1S1ControlAnalysis
        %Load segmentation file from M1S1ControlAnalysis folder. Also load large ROI and the same betas as in main
        %analysis which now need to be idx-masked by this new large ROI
        M1S1Control_betas_micro_noNORDIC=single(spm_read_vols(spm_vol(['./betas_micro_' convertStringsToChars(condition) '_noNORDIC_resample.nii'])));
        M1S1Control_betas_micro_NORDIC=single(spm_read_vols(spm_vol(['./betas_micro_' convertStringsToChars(condition) '_NORDIC_resample.nii'])));
        M1S1Control_betas_micro_NORDIC1=single(spm_read_vols(spm_vol(['./betas_micro_' convertStringsToChars(condition) '_NORDIC1_resample.nii'])));

        M1S1Control_betas_cleanedMagn_noNORDIC=single(spm_read_vols(spm_vol(['./betas_cleanedMagn_' convertStringsToChars(condition) '_noNORDIC_resample.nii'])));
        M1S1Control_betas_cleanedMagn_NORDIC=single(spm_read_vols(spm_vol(['./betas_cleanedMagn_' convertStringsToChars(condition) '_NORDIC_resample.nii'])));
        M1S1Control_betas_cleanedMagn_NORDIC1=single(spm_read_vols(spm_vol(['./betas_cleanedMagn_' convertStringsToChars(condition) '_NORDIC1_resample.nii'])));

        M1S1Control_rim=single(spm_read_vols(spm_vol([M1S1ControlDir '/M1S1Control_rim.nii'])));
        M1S1Control_ROI=single(spm_read_vols(spm_vol([M1S1ControlDir '/largeROI.nii'])));

        %Mask and reshape
        M1S1Control_betas_micro_noNORDIC=reshape(M1S1Control_betas_micro_noNORDIC,s(1)*s(2)*s(3),s(4));
        M1S1Control_betas_micro_NORDIC=reshape(M1S1Control_betas_micro_NORDIC,s(1)*s(2)*s(3),s(4));
        M1S1Control_betas_micro_NORDIC1=reshape(M1S1Control_betas_micro_NORDIC1,s(1)*s(2)*s(3),s(4));

        M1S1Control_betas_cleanedMagn_noNORDIC=reshape(M1S1Control_betas_cleanedMagn_noNORDIC,s(1)*s(2)*s(3),s(4));
        M1S1Control_betas_cleanedMagn_NORDIC=reshape(M1S1Control_betas_cleanedMagn_NORDIC,s(1)*s(2)*s(3),s(4));
        M1S1Control_betas_cleanedMagn_NORDIC1=reshape(M1S1Control_betas_cleanedMagn_NORDIC1,s(1)*s(2)*s(3),s(4));

        M1S1Control_rim=reshape(M1S1Control_rim,s(1)*s(2)*s(3),1);
        M1S1Control_ROI=reshape(M1S1Control_ROI,s(1)*s(2)*s(3),1);

        idx_M1S1Control=find(M1S1Control_rim==3 & M1S1Control_ROI>0);
        M1S1Control_betas_micro_noNORDIC=M1S1Control_betas_micro_noNORDIC(idx_M1S1Control,:);
        M1S1Control_betas_micro_NORDIC=M1S1Control_betas_micro_NORDIC(idx_M1S1Control,:);
        M1S1Control_betas_micro_NORDIC1=M1S1Control_betas_micro_NORDIC1(idx_M1S1Control,:);

        M1S1Control_betas_cleanedMagn_noNORDIC=M1S1Control_betas_cleanedMagn_noNORDIC(idx_M1S1Control,:);
        M1S1Control_betas_cleanedMagn_NORDIC=M1S1Control_betas_cleanedMagn_NORDIC(idx_M1S1Control,:);
        M1S1Control_betas_cleanedMagn_NORDIC1=M1S1Control_betas_cleanedMagn_NORDIC1(idx_M1S1Control,:);

        M1S1Control_rim=M1S1Control_rim(idx_M1S1Control,1);
        M1S1Control_ROI=M1S1Control_ROI(idx_M1S1Control,1);

        %Get 2dEPI for S01:
        if subj==1
            M1S1Control_betas_2dEPI=single(spm_read_vols(spm_vol(['../2dEPI/betas_' convertStringsToChars(condition) '_2dEPI_al_resample.nii'])));
            M1S1Control_betas_2dEPI_smooth=single(spm_read_vols(spm_vol(['../2dEPI/betas_' convertStringsToChars(condition) '_2dEPI_al_resample_smooth.nii'])));
            
            s_2dEPI=size(M1S1Control_betas_2dEPI);
            M1S1Control_betas_2dEPI=reshape(M1S1Control_betas_2dEPI,s_2dEPI(1)*s_2dEPI(2)*s_2dEPI(3),s_2dEPI(4));
            M1S1Control_betas_2dEPI_smooth=reshape(M1S1Control_betas_2dEPI_smooth,s_2dEPI(1)*s_2dEPI(2)*s_2dEPI(3),s_2dEPI(4));
            
            M1S1Control_betas_2dEPI=M1S1Control_betas_2dEPI(idx_M1S1Control,:);
            M1S1Control_betas_2dEPI_smooth=M1S1Control_betas_2dEPI_smooth(idx_M1S1Control,:);

            %Save
            outputDir='/Users/au686880/Desktop/ALS_study/groupAnalysis';
            outputName=sprintf('%s/M1S1Control_S%02d_%s.mat',outputDir,subj,condition);
            save(outputName,...
                'M1S1Control_betas_micro_noNORDIC','M1S1Control_betas_micro_NORDIC','M1S1Control_betas_micro_NORDIC1',...
                'M1S1Control_betas_cleanedMagn_noNORDIC','M1S1Control_betas_cleanedMagn_NORDIC','M1S1Control_betas_cleanedMagn_NORDIC1','M1S1Control_rim','M1S1Control_ROI',...
                'M1S1Control_betas_2dEPI','M1S1Control_betas_2dEPI_smooth')
        else

            %Save
            outputDir='/Users/au686880/Desktop/ALS_study/groupAnalysis';
            outputName=sprintf('%s/M1S1Control_S%02d_%s.mat',outputDir,subj,condition);
            save(outputName,...
                'M1S1Control_betas_micro_noNORDIC','M1S1Control_betas_micro_NORDIC','M1S1Control_betas_micro_NORDIC1',...
                'M1S1Control_betas_cleanedMagn_noNORDIC','M1S1Control_betas_cleanedMagn_NORDIC','M1S1Control_betas_cleanedMagn_NORDIC1','M1S1Control_rim','M1S1Control_ROI')
        end

    end
end