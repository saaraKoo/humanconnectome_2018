function [mni_coords] = my_space2MNI(inds, res)
%MY_SPACE2MNI: transforms array indices (inds = [x y z] at resolution res into 
% MNI space

origin = [90, -126, -72];
m = [-1 * res, res, res];
mni_coords = m .* (inds - 1) + origin;


end

