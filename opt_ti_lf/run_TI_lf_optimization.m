function run_TI_lf_optimization(m2m_folder, output_root, mni_target, ...
    roi_radius, currents, shape, dimensions, thickness, electrode_pool, ...
    population_size, max_generations, crossover_rate, mutation_rate, ...
    elite_size, parallel_workers, target_strength, penalty_lambda, patience, search_mode)
% 基于预计算电场的 TI 电极优化（仅需一次逐电极 FEM 预计算）
%
% 流程:
%   Phase 0 — 从电极池移除参考电极 Oz
%   Phase 1 — 预计算各电极电场（逐电极 FEM，parfor 并发）
%   Phase 2 — 预计算 geo_cache（ROI 掩膜等）
%   Phase 3 — 遗传算法优化（查表叠加，毫秒级）

    setup_path();
    ref_electrode = 'Oz';
    current_amp = currents(1);
    cache_dir = fullfile(output_root, 'electrode_cache');
    log_file = fullfile(output_root, 'lf_ga_log.txt');
    checkpoint_file = fullfile(output_root, 'lf_ga_checkpoint.mat');
    eval_log_file = fullfile(output_root, 'lf_evaluated_individuals.csv');

    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════╗\n');
    fprintf('║         TI 导联场优化流水线                          ║\n');
    fprintf('╚══════════════════════════════════════════════════════╝\n');
    fprintf('  被试: %s\n', m2m_folder);
    fprintf('  靶区: [%.1f, %.1f, %.1f] mm, 半径: %.1f mm\n', ...
        mni_target(1), mni_target(2), mni_target(3), roi_radius);
    fprintf('  电流: ±%.4f A\n', current_amp);
    fprintf('  参考电极: %s\n', ref_electrode);
    fprintf('  电极池: %d 个电极\n', length(electrode_pool));
    fprintf('  种群: %d, 代数: %d\n', population_size, max_generations);
    fprintf('\n');

    % ========== Phase 0: 预处理 ==========
    fprintf('══════════════ Phase 0/3: 预处理 ════════════════════\n');

    % 从电极池移除参考电极
    if any(strcmp(electrode_pool, ref_electrode))
        fprintf('  参考电极 %s 在电极池中，自动移除\n', ref_electrode);
        electrode_pool = setdiff(electrode_pool, {ref_electrode});
        fprintf('  有效电极池: %d 个\n', length(electrode_pool));
    end

    if length(electrode_pool) < 4
        error('移除参考后有效电极不足 4 个');
    end

    % 创建输出目录
    if ~exist(output_root, 'dir'); mkdir(output_root); end
    if ~exist(cache_dir, 'dir'); mkdir(cache_dir); end

    % ========== Phase 1: 预计算电极电场 ==========
    fprintf('\n══════════════ Phase 1/3: 预计算电极电场 ════════════\n');

    % 启动并行池（预计算使用）
    pool = gcp('nocreate');
    if isempty(pool)
        fprintf('  启动并行池 (%d workers)...\n', parallel_workers);
        pool = parpool(parallel_workers);
    elseif pool.NumWorkers ~= parallel_workers
        delete(pool);
        pool = parpool(parallel_workers);
    end

    % 确保 worker 能访问 SimNIBS 和我们的函数
    addAttachedFiles(pool, {
        'run_single_electrode_simulation.m', ...
        'eval_individual_lf.m', ...
        'exhaustive_TI_search.m', ...
        'setup_path.m'
        });
    simnibs_path = fileparts(which('run_simnibs'));
    spmd
        setup_path();
        if ~isempty(simnibs_path)
            addpath(simnibs_path);
        end
    end

    [fields, gm_centers, gm_volumes, electrode_names, ref_electrode] = ...
        precompute_electrode_fields(m2m_folder, cache_dir, electrode_pool, ...
        current_amp, shape, dimensions, thickness, ref_electrode, parallel_workers);

    % ========== Phase 2: 预计算 geo_cache ==========
    fprintf('\n══════════════ Phase 2/3: 预计算 ROI 缓存 ════════════\n');
    t_start = tic;

    % MNI → subject 空间
    subj_center = mni2subject_coords(mni_target, m2m_folder);
    fprintf('  ROI 中心 (subject 空间): [%.1f, %.1f, %.1f]\n', subj_center);

    % ROI 掩膜
    dists = sqrt(sum((gm_centers - subj_center).^2, 2));
    roi_mask = dists < roi_radius;
    non_roi_mask = ~roi_mask;

    geo_cache = struct();
    geo_cache.roi_mask = roi_mask;
    geo_cache.non_roi_mask = non_roi_mask;
    geo_cache.gm_volumes = gm_volumes;
    geo_cache.gm_centers = gm_centers;
    geo_cache.roi_volume = sum(gm_volumes(roi_mask));
    geo_cache.non_roi_volume = sum(gm_volumes(non_roi_mask));

    fprintf('  %d 个灰质单元, ROI 内: %d (%.1f mm³), ROI 外: %d (%.1f mm³)\n', ...
        length(gm_volumes), sum(roi_mask), geo_cache.roi_volume, ...
        sum(non_roi_mask), geo_cache.non_roi_volume);
    fprintf('  用时: %.2f 秒\n', toc(t_start));

    % ========== Phase 3: 运行 GA ==========
    fprintf('\n══════════════ Phase 3/3: 遗传算法优化 ═══════════════\n');

    % 建立电极名→索引映射
    elec_to_idx = containers.Map();
    for i = 1:length(electrode_names)
        elec_to_idx(electrode_names{i}) = i;
    end

    % 按搜索模式分流
    switch search_mode
        case 'exhaustive'
            fprintf('  搜索方式: 穷举搜索\n\n');

            % ── 将电场写入二进制共享文件，避免每个 worker 持完整副本 ──
            N_elec = size(fields, 1);
            N_gm = size(fields, 2);
            fields_file = fullfile(output_root, 'fields.bin');
            file_gb = N_elec * N_gm * 3 * 8 / 1e9;
            fprintf('  写入电场共享文件 (%d 电极 × %d 灰质单元, %.1f GB)...\n', ...
                N_elec, N_gm, file_gb);

            fid = fopen(fields_file, 'wb');
            assert(fid ~= -1, '无法创建电场共享文件: %s', fields_file);
            data = permute(fields, [2, 3, 1]);  % [N_gm, 3, N_elec] 连续布局
            fwrite(fid, data, 'double');
            fclose(fid);
            clear data fields;  % 释放客户端内存

            % geo_cache 封为 Constant，避免 parfor 反复序列化
            geo_cache_constant = parallel.pool.Constant(geo_cache);

            [best_ind, best_fit, best_info] = exhaustive_TI_search(...
                fields_file, electrode_names, geo_cache_constant, currents, ...
                target_strength, penalty_lambda, output_root, N_gm, N_elec);

            % 清理共享文件
            try delete(fields_file); end

        otherwise
            fprintf('  GA 初始化完成，开始优化...\n');
            fprintf('  如果卡住，请确认 workers 内存足够 (>4GB/worker)\n\n');

            % 用 parallel.pool.Constant 广播大数组
            fields_constant = parallel.pool.Constant(fields);

            % 适应度函数句柄
            eval_func = @(ind) eval_individual_lf(ind, fields_constant, ...
                elec_to_idx, geo_cache, currents, target_strength, penalty_lambda);

            [best_ind, best_fit] = genetic_algorithm_core(...
                eval_func, electrode_names, ...
                population_size, max_generations, crossover_rate, mutation_rate, ...
                elite_size, checkpoint_file, log_file, eval_log_file, patience);
    end

    % ========== 输出结果 ==========
    fprintf('\n══════════════════════════════════════════════════════\n');
    if ~isempty(best_ind)
        fprintf('  ✅ 优化完成！\n');
        fprintf('  最优电极组合: %s\n', strjoin(best_ind, ','));
        fprintf('  最优适应度:   %.4f\n', best_fit);

        % 获取详细信息（穷举已带回，GA 需要多算一次）
        if exist('best_info', 'var') && ~isempty(fieldnames(best_info))
            final_info = best_info;
        else
            [~, final_info] = eval_func(best_ind);
        end

        fprintf('  ROI 平均场强: %.4f V/m\n', final_info.roi_avg);
        fprintf('  背景平均场强: %.4f V/m\n', final_info.rest_avg);
        fprintf('  聚焦比:       %.2f%%\n', final_info.focus_ratio);
        fprintf('  聚焦体积:     %.1f mm³\n', final_info.focus_vol_total);
    else
        fprintf('  ❌ 未找到有效个体\n');
    end
    fprintf('══════════════════════════════════════════════════════\n\n');
end
