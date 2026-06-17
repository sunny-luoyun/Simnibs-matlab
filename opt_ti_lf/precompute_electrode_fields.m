function [fields, gm_centers, gm_volumes, electrode_names, ref_electrode] = ...
    precompute_electrode_fields(m2m_folder, cache_dir, electrode_pool, ...
    current_amp, shape, dimensions, thickness, ref_electrode, parallel_workers)
% 对电极池中每个电极预计算灰质电场（与公共参考电极配对）
% 利用 parfor 多线程并发加速
%
% 输入:
%   m2m_folder      : m2m 文件夹路径
%   cache_dir       : 缓存目录
%   electrode_pool  : 电极名称 cell array
%   current_amp     : 电流幅值 (A)
%   shape           : 电极形状
%   dimensions      : 电极尺寸 [长, 短] (mm)
%   thickness       : 电极厚度 (mm)
%   ref_electrode   : 公共参考电极名称 (如 'Oz')
%   parallel_workers: 并行线程数
%
% 输出:
%   fields          : [N_elec, N_gm, 3] 预计算电场
%   gm_centers      : [N_gm, 3] 灰质单元中心
%   gm_volumes      : [N_gm, 1] 灰质单元体积
%   electrode_names : {N_elec} 电极名称
%   ref_electrode   : 参考电极名称

    fprintf('══════════════════════════════════════════════════════\n');
    fprintf('  预计算电极电场 (参考: %s)\n', ref_electrode);
    fprintf('══════════════════════════════════════════════════════\n');

    % ── 从电极池中移除参考电极 ──
    pool = setdiff(electrode_pool, {ref_electrode});
    n_elec = length(pool);
    fprintf('  电极池: %d 个 (移除参考 %s)\n', n_elec, ref_electrode);

    if n_elec < 4
        error('有效电极不足 4 个（移除参考后），无法优化');
    end

    % ── 检查缓存 ──
    cache_file = fullfile(cache_dir, 'electrode_fields.mat');
    subject_name = get_subject_name(m2m_folder);

    if exist(cache_file, 'file')
        fprintf('  找到缓存: %s\n', cache_file);
        loaded = load(cache_file);
        % 验证缓存是否匹配
        if isequal(loaded.electrode_names, pool) && ...
           strcmp(loaded.ref_electrode, ref_electrode)
            fields = loaded.fields;
            gm_centers = loaded.gm_centers;
            gm_volumes = loaded.gm_volumes;
            electrode_names = loaded.electrode_names;
            fprintf('  缓存有效，跳过预计算\n');
            return;
        else
            fprintf('  缓存不匹配（电极池或参考已变化），重新预计算\n');
        end
    end

    if ~exist(cache_dir, 'dir'); mkdir(cache_dir); end

    % ── 先跑第一个电极获取网格几何信息 ──
    fprintf('\n  第一步: 获取灰质网格几何信息...\n');
    first_elec = pool{1};
    first_temp = fullfile(cache_dir, '__first_run__');
    if ~exist(first_temp, 'dir'); mkdir(first_temp); end

    try
        run_single_electrode_simulation(m2m_folder, first_temp, ...
            first_elec, current_amp, shape, dimensions, thickness, ref_electrode);
    catch ME
        rmdir(first_temp, 's');
        rethrow(ME);
    end

    % 从第一个结果中提取灰质几何
    m = mesh_load_gmsh4(fullfile(first_temp, ...
        sprintf('%s_TDCS_1_scalar.msh', subject_name)));
    gm = mesh_extract_regions(m, 'region_idx', 2);

    gm_centers = mesh_get_tetrahedron_centers(gm);
    gm_volumes = mesh_get_tetrahedron_sizes(gm);
    n_gm = length(gm_volumes);
    fprintf('  灰质单元数: %d\n', n_gm);

    % 清理第一个临时目录
    rmdir(first_temp, 's');

    % ── 并行预计算其余电极 ──
    fprintf('\n  第二步: 并行预计算 %d 个电极 (workers=%d)...\n', n_elec, parallel_workers);

    % 分配 tempdir 根目录
    temp_root = fullfile(cache_dir, 'temp_runs');
    if ~exist(temp_root, 'dir'); mkdir(temp_root); end

    % 准备 parfor 参数
    elec_list = pool;
    current_amps = repmat(current_amp, n_elec, 1);

    % 为 parfor 构建结果容器
    results = cell(n_elec, 1);

    parfor i = 1:n_elec
        elec = elec_list{i};
        temp_dir = fullfile(temp_root, sprintf('run_%s', elec));
        if ~exist(temp_dir, 'dir'); mkdir(temp_dir); end

        try
            efield = run_single_electrode_simulation(...
                m2m_folder, temp_dir, elec, current_amp, ...
                shape, dimensions, thickness, ref_electrode);
            results{i} = efield;

            % 清理（保留少量调试信息）
            try rmdir(fullfile(temp_dir, 'cache'), 's'); end
            try rmdir(fullfile(temp_dir, 'd2'), 's'); end

            fprintf('  [%d/%d] %s 完成\n', i, n_elec, elec);
        catch ME
            warning('  [%d/%d] %s 失败: %s', i, n_elec, elec, ME.message);
            results{i} = [];
        end
    end

    % ── 组装结果 ──
    fprintf('\n  第三步: 组装结果...\n');
    n_success = 0;
    for i = 1:n_elec
        if ~isempty(results{i})
            n_success = n_success + 1;
        end
    end

    if n_success < 4
        error('成功电极数 %d < 4，无法优化', n_success);
    end

    % 过滤失败电极
    valid_idx = find(~cellfun(@isempty, results));
    electrode_names = elec_list(valid_idx);
    n_valid = length(valid_idx);

    fields = zeros(n_valid, n_gm, 3);
    for j = 1:n_valid
        i = valid_idx(j);
        fields(j, :, :) = results{i};
    end

    fprintf('  成功: %d / %d 电极\n', n_valid, n_elec);

    % ── 保存缓存 ──
    fprintf('  保存缓存: %s\n', cache_file);
    save(cache_file, 'fields', 'gm_centers', 'gm_volumes', ...
        'electrode_names', 'ref_electrode', '-v7.3');

    % ── 清理临时目录 ──
    try rmdir(temp_root, 's'); end

    fprintf('  ✅ 预计算完成\n');
    fprintf('══════════════════════════════════════════════════════\n\n');
end


function name = get_subject_name(m2m_folder)
    [~, folder_name] = fileparts(m2m_folder);
    if startsWith(folder_name, 'm2m_')
        name = folder_name(5:end);
    else
        name = folder_name;
    end
end
