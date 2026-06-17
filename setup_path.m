function setup_path()
rootDir = fileparts(mfilename('fullpath'));
folders = {
    'charm',
    'opt_eeg',
    'opt_ti_lf',
    'TI',
    };
addpath(rootDir);
for i = 1:numel(folders)
    d = fullfile(rootDir, folders{i});
    if exist(d, 'dir')
        addpath(d);
    end
end
end
