% A script for creating group grey matter and roi masks (products of
% individual and atlas masks).
% After running the script, move group_grey_matter_mask.mat and
% group_roi_mask.mat files into the group folder!
% Last modified by OK 2014-07-03: changed grey matter mask so that each
% voxel is a roi of its own
% OK 2014-07-14: from 2 mm to 4 mm masks
% OK 2014-07-21: from 4 mm masks to general res
% OK 2014-07-24: replaced bramila_makeRoiStruct with
% my_bramila_make_RoiStruct to use general space2MNI transform
% OK 2014-07-28: added zero filling to masks to match epi size + option to
% run without reading epi to create .mat masks
% OK 2015-03-05: changed paths to point to grey matter masks where
% hemispheres are separeted

close all, clear all

%addpath(genpath('/m/nbe/scratch/braindata/shared/toolboxes/bramila/bramila'));
addpath(genpath('/m/cs/scratch/cs-e5700-2017/hcp/toolboxes/NIfTI_20140122'));
addpath(genpath('/m/cs/scratch/cs-e5700-2017/hcp/toolboxes/bramila'));

subjects = {'/m/nbe/scratch/networks/aokorhon/HCP/unzipped/100307',
            '/m/nbe/scratch/networks/aokorhon/HCP/unzipped/103414'};


[group_folder, ~, ~] = fileparts(subjects{1}); % all subject folders should be in a common project folder
ind_mask_path = '/brainmask_fs.4.nii'; % TODO: update paths
group_folder_out = '/m/cs/scratch/cs-e5700-2018/hcp/';
mask_folder = '/masks_with_HO';

ho_ref_folder = '/m/cs/scratch/cs-e5700-2018/hcp/humanconnectome_2018/HO_masks/with_subcortl_cerebellum';
brainnetome_ref_folder = '/m/cs/scratch/cs-e5700-2018/hcp/humanconnectome_2018/brainnetome-masks';

TH = 30;
group_mask = [];
res = 4;
res_str = [num2str(res), 'mm'];
template = ['/m/cs/scratch/cs-e5700-2017/hcp/humanconnectome_2018/HO_masks/MNI152_T1_4mm_brain.nii'];
start_from_epi = 1; % set to 1 if you want to read individual ep masks, 0 if only create .mat files
include_subcortex = true;
include_cerebellum = true;
atlas = 'ho'; % which atlas to use for producing the group masks, options: 'ho', 'brainnetome'

missing_rois = [120]; % indices of ROIs that are not present at the selected probability; needed to get correct labels (relates to HO mask at 30% probability)

%% reading individual masks, creating group mask

if strcmp(atlas, 'ho')
    nii_path = [group_folder_out mask_folder '/group_mask-' num2str(TH) '-' res_str '.nii'];
elseif strcmp(atlas, 'brainnetome')
    nii_path = [group_folder_out mask_folder '/group_mask-' res_str '.nii'];
end

if start_from_epi
    for s = 1:length(subjects)
        disp(s);
        subject_path = subjects{s};
        ind_mask = load_nii([subject_path ind_mask_path]);
        if s == 1
            group_mask = ind_mask.img;
        else
            group_mask = group_mask .* ind_mask.img;
        end
    end
    
    save_nii(make_nii(group_mask, [res res res]), nii_path)

    % origin fix

    clear cfg
    cfg.target = nii_path; %[group_folder_out mask_folder '/group_mask-' num2str(TH) '-' res_str '.nii'];
    cfg.template = template;
    cfg = my_correct_origin(cfg);
else
    group_mask = load_nii(nii_path);
    group_mask = group_mask.img;
end

epi_size = size(group_mask);

if strcmp(atlas, 'ho') % Brainnetome doesn't offer grey matter masks => grey matter group masks only created for HO
    if include_subcortex
        if include_cerebellum
            boolean_mask_name = [ho_ref_folder '/grey_matter-boolean_mask-maxprob-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum.nii'];
            voxel_mask_name = [ho_ref_folder '/grey_matter-maxprob-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum.nii'];
        else
            boolean_mask_name = [ho_ref_folder '/grey_matter-boolean_mask-maxprob-' num2str(TH) '-' res_str '_with_subcortl.nii'];
            voxel_mask_name = [ho_ref_folder '/grey_matter-maxprob-' num2str(TH) '-' res_str '_with_subcortl.nii'];
        end
    elseif include_cerebellum
        boolean_mask_name = [ho_ref_folder '/grey_matter-boolean_mask-maxprob-' num2str(TH) '-' res_str '_with_cerebellum.nii'];
        voxel_mask_name = [ho_ref_folder '/grey_matter-maxprob-' num2str(TH) '-' res_str '_with_cerebellum.nii'];
    else
        boolean_mask_name = [ho_ref_folder '/grey_matter-boolean_mask-maxprob-' num2str(TH) '-' res_str '.nii'];
        voxel_mask_name = [ho_ref_folder '/grey_matter-maxprob-' num2str(TH) '-' res_str '.nii'];
    end

    boolean_grey_matter_mask = load_nii(boolean_mask_name);
    grey_matter_mask = load_nii(voxel_mask_name);

    boolean_grey_matter_mask = boolean_grey_matter_mask.img;
    grey_matter_mask = grey_matter_mask.img;

    grey_mask_size = size(grey_matter_mask);
    d = epi_size - grey_mask_size;

    if any(grey_mask_size < epi_size) % filling grey matter masks with 0's if epi > grey matter mask
        boolean_grey_matter_mask(grey_mask_size(1) + d(1), :, :) = 0;
        boolean_grey_matter_mask(:, grey_mask_size(2) + d(2), :) = 0;
        boolean_grey_matter_mask(:, :, grey_mask_size(3) + d(3)) = 0;
        grey_matter_mask(grey_mask_size(1) + 1, :, :) = 0;
        grey_matter_mask(:, grey_mask_size(2) + 1, :) = 0;
        grey_matter_mask(:, :, grey_mask_size(3) + 1) = 0;
    end

    group_boolean_grey_matter = boolean_grey_matter_mask .* group_mask;
    group_grey_matter = grey_matter_mask .* group_mask;

    if include_subcortex
        if include_cerebellum
            group_boolean_mask_name = [group_folder_out mask_folder '/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum.nii'];
            group_voxel_mask_name = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum.nii'];
        else
            group_boolean_mask_name = [group_folder_out mask_folder '/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '_with_subcortl.nii'];
            group_voxel_mask_name = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '_with_subcortl.nii'];
        end
    elseif include_cerebellum
        group_boolean_mask_name = [group_folder_out mask_folder '/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '_with_cerebellum.nii'];
        group_voxel_mask_name = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '_with_cerebellum.nii'];
    else
        group_boolean_mask_name = [group_folder_out mask_folder '/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
        group_voxel_mask_name = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
    end

    save_nii(make_nii(group_boolean_grey_matter, [res res res]), group_boolean_mask_name);
    save_nii(make_nii(group_grey_matter, [res res res]), group_voxel_mask_name);

    % origin fix

    clear cfg
    cfg.target = group_boolean_mask_name; %'/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
    cfg.template = template;
    cfg = my_correct_origin(cfg);
    cfg.target = group_voxel_mask_name; %'/group_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
    cfg = my_correct_origin(cfg);

    % first a mask with all grey matter in one roi

    clear cfg
    cfg.imgsize = grey_mask_size;
    cfg.roimask = group_boolean_mask_name; %'/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
    group_grey_label = {'group_grey_matter'};
    cfg.labels = group_grey_label;
    cfg.res = res;
    group_grey_matter_one_roi = my_bramila_makeRoiStruct(cfg);

    % changing the roi structure so that each voxel is a roi of its own
    % (supported structure in brainnets)
    if include_subcortex
        if include_cerebellum
            mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_grey_matter_with_subcortl_and_cerebellum.mat'];
        else
            mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_grey_matter_with_subcortl.mat'];
        end
    elseif include_cerebellum
        mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_grey_matter_with_cerebellum.mat'];
    else
        mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_grey_matter.mat'];
    end

    load(mask_name);
    % the correct label is picked by searching the location of group grey
    % matter voxels in the HO grey matter map
    nonzero_grey_matter_vals = grey_matter_mask(find(grey_matter_mask > 0)); 
    nonzero_group_grey_matter_vals = group_grey_matter(find(group_grey_matter > 0));
    [tf, loc] = ismember(nonzero_group_grey_matter_vals, nonzero_grey_matter_vals);
    tf = find(tf);
    grey_matter_label_indices = unique(loc(tf), 'first');
    grey_matter_labels = {};
    s = size(grey_matter_label_indices);
    nrows = s(1);
    for label_index = 1 : 1 : nrows
        grey_matter_labels(label_index) = grey_matter(grey_matter_label_indices(label_index)).label;
    end

    group_grey_matter = {};
    one_roi_map = group_grey_matter_one_roi.map;
    s = size(one_roi_map);
    nrows = s(1);
    for voxel_ind = 1 : 1 : nrows
        group_grey_matter(voxel_ind).map = one_roi_map(voxel_ind, :);
        group_grey_matter(voxel_ind).centroid = one_roi_map(voxel_ind, :);
        group_grey_matter(voxel_ind).label = grey_matter_labels(voxel_ind);
        [mnix mniy mniz] = bramila_space2MNI(group_grey_matter(voxel_ind).centroid(1), group_grey_matter(voxel_ind).centroid(2), group_grey_matter(voxel_ind).centroid(3));
        group_grey_matter(voxel_ind).centroidMNI = [mnix mniy mniz];
    end

    if include_subcortex
        if include_cerebellum
            mask_path = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum'];
        else
            mask_path = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '_with_subcortl'];
        end
    elseif include_cerebellum
        mask_path = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str '_with_cerebellum'];
    else
        mask_path = [group_folder_out mask_folder '/group_grey_matter_mask-' num2str(TH) '-' res_str];
    end

    save(mask_path, 'group_grey_matter');
end

%% roi masks

if strcmp(atlas, 'ho') % Brainnetome masks already include subcortical areas and cerebellum, no need to add them separately
    if include_subcortex
        if include_cerebellum
            roi_mask = load_nii([ho_ref_folder '/HarvardOxford-maxprob-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum.nii']);
        else
            roi_mask = load_nii([ho_ref_folder '/HarvardOxford-maxprob-' num2str(TH) '-' res_str '_with_subcortl.nii']);
        end
    elseif include_cerebellum
        roi_mask = load_nii([ho_ref_folder '/HarvardOxford-maxprob-' num2str(TH) '-' res_str '_with_cerebellum.nii']);
    else
        roi_mask = load_nii([ho_ref_folder '/HarvardOxford-maxprob-' num2str(TH) '-' res_str '.nii']);
    end
elseif strcmp(atlas,'brainnetome')
    roi_mask = load_nii([brainnetome_ref_folder '/BNA-MPM_thr25_4mm.nii']);
end

roi_mask = roi_mask.img;

roi_mask_size = size(roi_mask);

if any(roi_mask_size < epi_size) % filling roi masks with 0's if epi < roi mask
    roi_mask(roi_mask_size(1) + 1, :, :) = 0;
    roi_mask(:, roi_mask_size(2) + 1, :) = 0;
    roi_mask(:, :, roi_mask_size(3) + 1) = 0;
end

group_roi = roi_mask .* group_mask;

unique_roi_indices = unique(group_roi);
unique_roi_indices = unique_roi_indices(2:end); 
n_rois = max(size(unique_roi_indices));

% Removing "gaps" caused by ROIs that are not present at the given
% probability; needed for picking correct labels later on.
for i = 1:n_rois
    for j = 1:length(missing_rois)
        if unique_roi_indices(i) > missing_rois(j)
            unique_roi_indices(i) = unique_roi_indices(i) - 1;
        end
    end
end

if include_subcortex || strcmp(atlas,'brainnetome')
    if include_cerebellum || strcmp(atlas,'brainnetome')
        group_roi_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum.nii'];
    else
        group_roi_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '_with_subcortl.nii'];
    end
elseif include_cerebellum
    group_roi_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '_with_cerebellum.nii'];
else
    group_roi_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '.nii'];
end

save_nii(make_nii(group_roi, [res res res]), group_roi_path);

% origin fix

clear cfg
cfg.target = group_roi_path; %[group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '.nii'];
cfg.template = template;
cfg = my_correct_origin(cfg);

clear cfg
cfg.imgsize = roi_mask_size;
cfg.res = res;
cfg.roimask = group_roi_path; %[group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '.nii'];
% getting correct labels
if strcmp(atlas, 'ho')
    if include_subcortex
        if include_cerebellum
            mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_rois_with_subcortl_and_cerebellum.mat'];
        else
            mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_rois_with_subcortl.mat'];
        end
    elseif include_cerebellum
        mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_rois_with_cerebellum.mat'];
    else
        mask_name = [ho_ref_folder '/HO_' num2str(TH) '-' res_str '_rois.mat'];
    end
elseif strcmp(atlas,'brainnetome')
    mask_name = [brainnetome_ref_folder '/brainnetome_thr25_4mm_rois.mat'];
end

load(mask_name);
labels = cell(n_rois, 1); 
for i = 1:n_rois
    labels(i) = {rois(unique_roi_indices(i)).label};
end

cfg.labels=labels;
rois = my_bramila_makeRoiStruct(cfg);

if include_subcortex || strcmp(atlas,'brainnetome')
    if include_cerebellum
        mask_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '_with_subcortl_and_cerebellum'];
    else
        mask_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '_with_subcortl'];
    end
elseif include_cerebellum
    mask_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str '_with_cerebellum'];
else
    mask_path = [group_folder_out mask_folder '/group_roi_mask-' num2str(TH) '-' res_str];
end

save(mask_path, 'rois');

