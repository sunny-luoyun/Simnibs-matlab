function e_field_gm = run_single_electrode_simulation(...
    m2m_folder, temp_dir, electrode_name, current_amp, ...
    shape, dimensions, thickness, ref_electrode)
% 对单个电极跑一次 tDCS 仿真，提取灰质 E-field
%
% 输入:
%   m2m_folder     : m2m 文件夹路径
%   temp_dir       : 临时输出目录
%   electrode_name : 电极名称
%   current_amp    : 电流幅值 (A)
%   shape          : 电极形状
%   dimensions     : 电极尺寸 [长, 短] (mm)
%   thickness      : 电极厚度 (mm)
%   ref_electrode  : 参考电极名称
%
% 输出:
%   e_field_gm     : [N_gm, 3] 灰质电场向量

    % 获取被试名
    [~, folder_name] = fileparts(m2m_folder);
    if startsWith(folder_name, 'm2m_')
        subject = folder_name(5:end);
    else
        subject = folder_name;
    end

    % 构建 SESSION
    S = sim_struct('SESSION');
    S.subpath = m2m_folder;
    S.pathfem = temp_dir;

    S.poslist{1} = sim_struct('TDCSLIST');
    S.poslist{1}.currents = [current_amp, -current_amp];

    S.poslist{1}.electrode(1).channelnr = 1;
    S.poslist{1}.electrode(1).centre = electrode_name;
    S.poslist{1}.electrode(1).shape = shape;
    S.poslist{1}.electrode(1).dimensions = dimensions;
    S.poslist{1}.electrode(1).thickness = thickness;

    S.poslist{1}.electrode(2).channelnr = 2;
    S.poslist{1}.electrode(2).centre = ref_electrode;
    S.poslist{1}.electrode(2).shape = shape;
    S.poslist{1}.electrode(2).dimensions = dimensions;
    S.poslist{1}.electrode(2).thickness = thickness;

    % 运行仿真
    run_simnibs(S);

    % 加载结果 (ch1 = 目标电极 +I 的贡献)
    msh_file = fullfile(temp_dir, sprintf('%s_TDCS_1_scalar.msh', subject));
    if ~exist(msh_file, 'file')
        error('仿真未生成结果文件: %s', msh_file);
    end

    m = mesh_load_gmsh4(msh_file);

    % 提取灰质 (region_idx=2)
    gm = mesh_extract_regions(m, 'region_idx', 2);
    if isempty(gm) || isempty(gm.element_data)
        error('灰质区域未找到');
    end

    % 提取电场 (元素基)
    field_idx = get_field_idx(gm, 'E', 'elements');
    e_field_gm = gm.element_data{field_idx}.tetdata;  % [N_gm, 3]

    % 清理仿真中间文件（只保留结果），节省磁盘
    try rmdir(fullfile(temp_dir, 'cache'), 's'); end
    try rmdir(fullfile(temp_dir, 'd2'), 's'); end
    try
        delete(fullfile(temp_dir, '*.log'));
        delete(fullfile(temp_dir, '*.txt'));
        delete(fullfile(temp_dir, '*.bin'));
        delete(fullfile(temp_dir, '*.dat'));
    end
end
