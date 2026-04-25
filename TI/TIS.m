function TIS(subpath, output_folder, currents, electrode_centres, shape, dimensions, thickness)
% RUN_TDCS_TI_SIMULATION 运行双电极对tDCS仿真并计算TI包络振幅
%   subpath:     输入文件夹路径，例如 '/Users/.../m2m_Sub001'
%   output_folder: 输出文件夹名称，例如 'TI'（相对路径，将创建于当前目录下）
%   currents:    1×2 数值数组，两个通道的电流值（A），例如 [0.002, -0.002]
%   electrode_centres: 2×2 cell，每个pair的两个电极中心坐标
%                    例如 {{'F3','F4'}, {'TP7','TP8'}}
%   shape:       电极形状字符串，例如 'ellipse'
%   dimensions:  1×2 数值数组，电极尺寸（mm），例如 [10,10]
%   thickness:   电极厚度（mm），例如 2
%
% 输出：在 output_folder 中生成两个仿真结果文件夹及一个名为
%       <subject>_TIenvelope_only.msh 的网格文件（TI包络振幅）。

    %% 1. 从输入路径提取被试名称（如 'Sub001'）
    [~, folder_name] = fileparts(subpath);
    % 假设文件夹名为 'm2m_Sub001'，提取 'm2m_' 之后的部分
    if startsWith(folder_name, 'm2m_')
        subject = folder_name(5:end);
    else
        subject = folder_name;  % 若没有前缀则直接使用
    end

    %% 2. 构建 SimNIBS 会话结构
    S = sim_struct('SESSION');
    S.subpath = subpath;
    S.pathfem = output_folder;

    % 第一电极对
    S.poslist{1} = sim_struct('TDCSLIST');
    S.poslist{1}.currents = currents;

    % 第一电极对中的两个电极
    S.poslist{1}.electrode(1).channelnr = 1;
    S.poslist{1}.electrode(1).centre = electrode_centres{1}{1};
    S.poslist{1}.electrode(1).shape = shape;
    S.poslist{1}.electrode(1).dimensions = dimensions;
    S.poslist{1}.electrode(1).thickness = thickness;

    S.poslist{1}.electrode(2).channelnr = 2;
    S.poslist{1}.electrode(2).centre = electrode_centres{1}{2};
    S.poslist{1}.electrode(2).shape = shape;
    S.poslist{1}.electrode(2).dimensions = dimensions;
    S.poslist{1}.electrode(2).thickness = thickness;

    % 第二电极对：复制第一对，只修改电极中心坐标
    S.poslist{2} = S.poslist{1};
    S.poslist{2}.electrode(1).centre = electrode_centres{2}{1};
    S.poslist{2}.electrode(2).centre = electrode_centres{2}{2};

    %% 3. 运行仿真
    run_simnibs(S);

    %% 4. 分析两个仿真结果，计算TI包络振幅
    % 构造两个 .msh 文件名
    msh1_name = fullfile(output_folder, sprintf('%s_TDCS_1_scalar.msh', subject));
    msh2_name = fullfile(output_folder, sprintf('%s_TDCS_2_scalar.msh', subject));

    m1 = mesh_load_gmsh4(msh1_name);
    m2 = mesh_load_gmsh4(msh2_name);

    % 移除电极区域（tetrahedra/triangles 属于电极的，确保两个网格具有相同数量的元素）
    m1 = mesh_extract_regions(m1, 'region_idx', [1:99, 1001:1099]);
    m2 = mesh_extract_regions(m2, 'region_idx', [1:99, 1001:1099]);

    % 计算TI包络振幅（每个元素上）
    maxTI = get_maxTI( ...
        m1.element_data{get_field_idx(m1, 'E', 'elem')}, ...
        m2.element_data{get_field_idx(m2, 'E', 'elem')} );

    %% 5. 保存仅含TI包络振幅的网格文件
    mout = m1;   % 复制几何骨架
    mout.element_data = {};
    mout.element_data{1} = maxTI;
    if ~isfield(mout.element_data{1}, 'name')
        mout.element_data{1}.name = 'maxTIamplitude';
    end
    outfile = fullfile(output_folder, sprintf('%s_TIenvelope_only.msh', subject));
    mesh_save_gmsh4(mout, outfile);
    % fprintf('TI包络振幅已保存至: %s\n', outfile);
end