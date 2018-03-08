% This function picks and saves the time series of voxels that belong into
% ROIs defined in cfg.rois_to_use. The saved time series can be further
% processed in Python. Function saves two files:
% 1) a structure of ROI and voxel
% time series, where ROI time series are defined as an average of voxels
% in the ROI and voxel time series are ordered by their ROI identity.
% 2) an info file containing ROI onset indices (index of first voxel that belongs
% to the ROI), ROI names, indices (in original image) of voxels in each ROI,
% ROI maps (coordinates of voxels in each ROI in original image), and ROI
% sizes (in voxels). Time series belonging to a ROI are between onset and
% onset + size.
% Created by Onerva Korhonen 2014-10-16

function cfg = pick_and_save_voxel_ts(cfg)

[group_folder, ~, ~] = fileparts(cfg.inputfolder);
group_mask_folder = [group_folder '/masks'];

roi_mask_name = cfg.roi_mask_name;
roi_mask_file = fullfile(group_mask_folder, roi_mask_name);

fprintf('Starting voxel picking, roi mask file: %s\n', roi_mask_file);

load(roi_mask_file);
group_roi = rois;
[x, y, z, t] = size(cfg.vol);
slice_size = x*y*z;

if strcmp(cfg.adjacency_rois{1}, 'all')
    rois_to_use = {};
    for i = 1:1:max(size(group_roi))
        rois_to_use{i} = group_roi(i).label;
    within_roi_adjmats = cell(length(rois_to_use) + 2, 1);
    end
else
    rois_to_use = cfg.adjacency_rois;
end

roi_indices = zeros(size(rois_to_use));
roi_ts = zeros(length(rois_to_use), t);
voxel_indices_per_roi = cell(length(rois_to_use) + 1, 1);
roi_maps = cell(length(rois_to_use), 1);

if strcmp(cfg.adjacency_rois{1}, 'all')
    roi_indices = 1:1:max(size(group_roi));
else
    for i = 1:1:max(size(group_roi)) 
        ind = find(strcmp(group_roi(i).label, rois_to_use));
        if ~ isempty(ind);
            roi_indices(ind(1)) = i;
        end
    end
end

roi_sizes = zeros(1, length(roi_indices));

for i = 1:1:length(roi_indices)
    roi_index = roi_indices(i);
    if ~ roi_index == 0
        roi_map = group_roi(roi_index).map; % roi_map contains coordinates of roi voxels in 3D (original image, cfg.vol)
        roi_offset_indices = (roi_map(:,3)-1)*y*x + (roi_map(:,2)-1)*x + roi_map(:,1); % transforming 3D indices into 1D
        roi_linear_indices = repmat(squeeze(roi_offset_indices),1,t);
        roi_steps = repmat((0:slice_size:(t-1)*slice_size),length(roi_offset_indices),1); % voxels belonging to the same roi appear at same 3D coordinates at each t
        roi_linear_indices = roi_linear_indices + roi_steps;
        roi_voxel_ts = cfg.vol(roi_linear_indices);
        roi_ts(i, :) = mean(roi_voxel_ts, 1);
        voxel_indices_per_roi{i, 1} = roi_linear_indices(:, 1); % voxel_indices_per_roi contains the 1D indices that refer to cfg.vol at t = 0
        roi_maps{i, 1} = roi_map;
        roi_sizes(i) = max(size(roi_map, 1));
    else
        roi_offset_indices = [];
        roi_voxel_ts = [];
        fprintf('Warning! %s not found!', rois_to_use{i});
    end
    if i == 1
        cfg.roi_voxel_ts = roi_voxel_ts;
    else
        cfg.roi_voxel_ts = cat(1, cfg.roi_voxel_ts, roi_voxel_ts);
    end
end

roi_voxel_ts = cfg.roi_voxel_ts;

roi_voxel_data = {};
roi_voxel_data.roi_ts = roi_ts;
roi_voxel_data.roi_voxel_ts = roi_voxel_ts;

if strcmp(cfg.adjacency_rois{1}, 'all')
    roi_voxel_ts_info_name = ['roi_voxel_ts_all_rois_info.mat'];
    roi_voxel_ts_name = ['roi_voxel_ts_all_rois.mat'];
else
    roi_voxel_ts_info_name = ['roi_voxel_ts_info.mat'];
    roi_voxel_ts_name = ['roi_voxel_ts.mat'];
end

roi_voxel_ts_path = fullfile([cfg.inputfolder], roi_voxel_ts_name);
save(roi_voxel_ts_path, 'roi_voxel_data');

roi_voxel_ts_info_path = fullfile([cfg.inputfolder], roi_voxel_ts_info_name);
roi_voxel_ts_info = {};
roi_voxel_ts_info.roi_onset_indices = [1, cumsum(roi_sizes) + 1]; % indices of the first voxel of each roi in roi_voxel_ts
roi_voxel_ts_info.rois = rois_to_use;
roi_voxel_ts_info.voxel_indices_per_roi = voxel_indices_per_roi;
roi_voxel_ts_info.roi_maps = roi_maps;
roi_voxel_ts_info.roi_sizes = roi_sizes;
save(roi_voxel_ts_info_path, 'roi_voxel_ts_info');

end





   
   


 

