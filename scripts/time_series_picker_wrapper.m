% This is a wrapper script for picking and saving voxel time series that
% belong to each ROI. Originally written by Onerva Korhonen 2014-07-14,
% modified 2016-02-25.

clear cfg
% subjects = {'/m/nbe/scratch/networks/aokorhon/HCP/unzipped/100307',
%             '/m/nbe/scratch/networks/aokorhon/HCP/unzipped/103414'};
        
d= dir('/m/cs/scratch/cs-e5700-2017-hcp/data/unzipped/*');
d = d(3:end);
for i=1:(length(d)-1)
    subjects{i} = sprintf('/m/cs/scratch/cs-e5700-2017-hcp/data/unzipped/%s',d(i).name);
end        
       
cfg.inputfile = '/downsampled_4mm_rest_LR.nii';

cfg.grey_matter_mask_names = {'group_grey_matter_mask-30-4mm.mat'}; %ready-made masks used to calculate adjacency matrices
cfg.roi_mask_names = {'group_roi_mask-30-4mm.mat'};

% ROIs for which the adjacency matrix will be calculated
cfg.adjacency_rois = {'all'};

cfg_par = bramila_parhandle(cfg,subjects); % reslices the cfg so that it can be used in parfor loop
for i = 1:length(subjects)
    cfg = cfg_par{i};
    subj = cfg.inputfolder; disp(['Data: ' subj]);
    cfg.grey_matter_mask_name = cfg.grey_matter_mask_names{1};
    cfg.roi_mask_name = cfg.roi_mask_names{1};
    input_path = [subj, cfg.inputfile, '.nii'];
    data = load_nii(input_path);
    cfg.vol = data.img;
    cfg = pick_and_save_voxel_ts(cfg);
end
