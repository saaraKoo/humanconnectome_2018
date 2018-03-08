function [inds] = my_MNI2space(mni_coords, res)
%MY_MNI2SPACE transforms MNI coordinates to array indices (inds = [x, y,
%z]) at resolution res

origin = [90, 126, 72];
m = [1/res, 1/res, 1/res];
inds = floor(m .* (mni_coords + origin)) + 1;  

end

