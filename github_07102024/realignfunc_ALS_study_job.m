%-----------------------------------------------------------------------
% Job saved on 15-Aug-2023 10:10:13 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'BOLDmagn_01';
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {'<UNDEFINED>'};
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'BOLDmagn_02';
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {'<UNDEFINED>'};
matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'moma';
matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {'<UNDEFINED>'};
matlabbatch{4}.spm.spatial.smooth.data(1) = cfg_dep('Named File Selector: moma(1) - Files', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{4}.spm.spatial.smooth.fwhm = [120 120 0];
matlabbatch{4}.spm.spatial.smooth.dtype = 64;
matlabbatch{4}.spm.spatial.smooth.im = 0;
matlabbatch{4}.spm.spatial.smooth.prefix = 's';
matlabbatch{5}.spm.spatial.realign.estwrite.data{1}(1) = cfg_dep('Named File Selector: BOLDmagn_01(1) - Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.spatial.realign.estwrite.data{2}(1) = cfg_dep('Named File Selector: BOLDmagn_02(1) - Files', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.quality = 1;
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.sep = 1;
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.fwhm = 1;
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.interp = 4;
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.weight(1) = cfg_dep('Smooth: Smoothed Images', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{5}.spm.spatial.realign.estwrite.roptions.which = [0 1];
matlabbatch{5}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{5}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{5}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{5}.spm.spatial.realign.estwrite.roptions.prefix = 'estimated_';
