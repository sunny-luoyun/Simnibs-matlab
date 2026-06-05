function setup_path()
rootDir = fileparts(mfilename('fullpath'));
folders = {
    'charm',
    'opt_eeg',
    'TI',
    };
addpath(rootDir);
for i = 1:numel(folders)
    addpath(fullfile(rootDir, folders{i}));
end
end
