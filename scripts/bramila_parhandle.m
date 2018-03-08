function cfg = bramila_parhandle(varargin)
% BRAMILA_PARHANDLE - Checks for parallelization possibilities in current
% preprocessing configuration and reslices the cfg subjectwise.
% It uses the function testGrid from ISC toolbox.
%   - Usage:
%   cfg = bramila_parhandle(cfg,subjects)
%   cfg = bramila_parhandle(cfg,subjects,subjects_out)
%   - Input:
%   cfg is a struct with following parameters
%       subjects = cell array with paths to folders containing epi.nii and
%       bet.nii
%       cfg = other preprocessing settings
%   - Output:
%       cfg = cell array containing resliced cfg, where cfg{1}.inputfolder is
%       filled with individual subject folder
%	Last edit: EG 2014-07-14

cfg = varargin{1};
subjects = varargin{2};

% fix the backward compatibility regarding subjects_out=subjects
if(nargin==3)
	subjects_out = varargin{3};
else
	subjects_out = subjects;
end

% You need the ISC toolbox to run the below
gridtype = testGrid; % used to decide, whether to use matlabpool (dione, for example) or slurm (triton)
Nsub=length(subjects);



%%if(strcmp(gridtype,'slurm'))
        %disp('You have slurm, running things on cluster!')
    %else
        %if matlabpool('size') == 0; % if matlab pool is not open
            %disp('You have no slurm, but you can use matlabpool')
            %parpool
        %else
            %disp('matlabpool already open')
        %end
    %end
%end

% Build individual cfg for each subject to run them in loop
tempcfg = cfg; 
tempcfg.gridtype = gridtype;
cfg = [];
for i = 1:Nsub
    cfg{i} = tempcfg;
    cfg{i}.inputfolder = subjects{i};
	cfg{i}.outputfolder = subjects_out{i};
end
