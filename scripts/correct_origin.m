function cfg = my_correct_origin(cfg)
% MY_CORRECT_ORIGIN corrects the origin and coordinate system of a nii
% created by make_nii to the same as in template
%   INPUT:
%   cfg.target = path of nii to correct
%   cfg.ref = path of template
% Copied from my_bramila_preprocessor by OK 2014-07-24.

target = load_nii(cfg.target);
ref=load_nii(cfg.template);
target.hdr.dime.pixdim = ref.hdr.dime.pixdim;
target.hdr.dime.scl_slope = ref.hdr.dime.scl_slope;
target.hdr.dime.xyzt_units = ref.hdr.dime.xyzt_units;
target.hdr.hist = ref.hdr.hist;
target.original.hdr.dime.pixdim = ref.original.hdr.dime.pixdim;
target.original.hdr.dime.scl_slope = ref.original.hdr.dime.scl_slope;
target.original.hdr.dime.xyzt_units = ref.original.hdr.dime.xyzt_units;
target.original.hdr.hist = ref.original.hdr.hist;
save_nii(target, cfg.target);

end

