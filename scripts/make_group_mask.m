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

% subjects = {'/m/nbe/scratch/networks/aokorhon/HCP/unzipped/100307',
%             '/m/nbe/scratch/networks/aokorhon/HCP/unzipped/103414'};
d= dir('/m/cs/scratch/cs-e5700-2017-hcp/data/unzipped/');
d = d(3:end);
for i=1:(length(d)-1)
    subjects{i} = sprintf('/m/cs/scratch/cs-e5700-2017-hcp/data/unzipped/%s',d(i).name);
end

[group_folder, ~, ~] = fileparts(subjects{1}); % all subject folders should be in a common project folder

TH = 30;
group_mask = [];
res = 4;
res_str = [num2str(res), 'mm'];
template = ['/m/cs/scratch/cs-e5700-2017/hcp/brain_networks/HO_masks/MNI152_T1_' res_str '_brain.nii'];
start_from_epi = 1; % set to 1 if you want to read individual ep masks, 0 if only create .mat files

%% reading individual masks, creating group mask

if start_from_epi
    for s = 1:length(subjects)
        subject_path = subjects{s};
        ind_mask = load_nii([subject_path '/brainmask_fs.4.nii']);
        if s == 1
            group_mask = ind_mask.img;
        else
            group_mask = group_mask .* ind_mask.img;
        end
    end

    save_nii(make_nii(group_mask, [res res res]), [group_folder '/masks/group_mask-' num2str(TH) '-' res_str '.nii'])

    % origin fix

    clear cfg
    cfg.target = [group_folder '/masks/group_mask-' num2str(TH) '-' res_str '.nii'];
    cfg.template = template;
    cfg = correct_origin(cfg);
else
    group_mask = load_nii([group_folder '/masks/group_mask-' num2str(TH) '-' res_str '.nii']);
    group_mask = group_mask.img;
end

epi_size = size(group_mask);

%% grey matter masks

boolean_grey_matter_mask = load_nii(['/m/cs/scratch/cs-e5700-2017/hcp/brain_networks/HO_masks/grey_matter-boolean_mask-maxprob-' num2str(TH) '-' res_str '.nii']);
grey_matter_mask = load_nii(['/m/cs/scratch/cs-e5700-2017/hcp/brain_networks/HO_masks/grey_matter-maxprob-' num2str(TH) '-' res_str '.nii']);

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

save_nii(make_nii(group_boolean_grey_matter, [res res res]), [group_folder '/masks/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '.nii']);
save_nii(make_nii(group_grey_matter, [res res res]), [group_folder '/masks/group_grey_matter_mask-' num2str(TH) '-' res_str '.nii']);

% origin fix

clear cfg
cfg.target = [group_folder '/masks/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
cfg.template = template;
cfg = correct_origin(cfg);
cfg.target = [group_folder '/masks/group_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
cfg = correct_origin(cfg);

% first a mask with all grey matter in one roi

clear cfg
cfg.imgsize = grey_mask_size;
cfg.roimask = [group_folder '/masks/group_boolean_grey_matter_mask-' num2str(TH) '-' res_str '.nii'];
group_grey_label = {'group_grey_matter'};
cfg.labels = group_grey_label;
cfg.res = res;
group_grey_matter_one_roi = bramila_make_roi_struct(cfg);

% changing the roi structure so that each voxel is a roi of its own
% (supported structure in brainnets)
mask_name = ['/m/cs/scratch/cs-e5700-2017/hcp/brain_networks/HO_masks/HO_' num2str(TH) '-' res_str '_grey_matter.mat'];
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
mask_path = [group_folder '/masks/group_grey_matter_mask-' num2str(TH) '-' res_str];
save(mask_path, 'group_grey_matter');

%% roi masks

roi_mask = load_nii(['/m/cs/scratch/cs-e5700-2017/hcp/brain_networks/HO_masks/HarvardOxford-maxprob-' num2str(TH) '-' res_str '.nii']);
roi_mask = roi_mask.img;

roi_mask_size = size(roi_mask);

if any(grey_mask_size < epi_size) % filling roi masks with 0's if epi < roi mask
    roi_mask(roi_mask_size(1) + 1, :, :) = 0;
    roi_mask(:, roi_mask_size(2) + 1, :) = 0;
    roi_mask(:, :, roi_mask_size(3) + 1) = 0;
end

group_roi = roi_mask .* group_mask;

save_nii(make_nii(group_roi, [res res res]), [group_folder '/masks/group_roi_mask-' num2str(TH) '-' res_str '.nii']);

% origin fix

clear cfg
cfg.target = [group_folder '/masks/group_roi_mask-' num2str(TH) '-' res_str '.nii'];
cfg.template = template;
cfg = correct_origin(cfg);

clear cfg
cfg.imgsize = roi_mask_size;
cfg.res = res;
cfg.roimask = [group_folder '/masks/group_roi_mask-' num2str(TH) '-' res_str '.nii'];
% getting correct labels
mask_name = ['/m/cs/scratch/cs-e5700-2017/hcp/brain_networks/HO_masks/HO_' num2str(TH) '-' res_str '_rois.mat'];
load(mask_name);
s = size(rois);
n_rois = max(s);
labels = cell(n_rois, 1);
for i = 1 : 1 : n_rois
    labels(i) = {rois(i).label};
end
cfg.labels=labels;
rois = bramila_make_roi_struct(cfg);
mask_path = [group_folder '/masks/group_roi_mask-' num2str(TH) '-' res_str];
save(mask_path, 'rois');
