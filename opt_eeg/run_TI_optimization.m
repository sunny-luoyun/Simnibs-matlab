function run_TI_optimization(m2m_folder, output_root, mni_target, ...
    roi_radius, currents, shape, dimensions, thickness, electrode_pool, ...
    population_size, max_generations, crossover_rate, mutation_rate, ...
    elite_size, parallel_workers, target_strength, penalty_lambda, patience)
% RUN_TI_OPTIMIZATION  使用给定参数启动 TI 电极优化
%
% 输入参数与 UI 界面字段一一对应，由 opt_eeg 回调传入。
% 所有输入均为必要参数，无默认值（由 UI 提供）。

    setup_path();
    log_file = fullfile(output_root, 'ga_log.txt');
    checkpoint_file = fullfile(output_root, 'ga_checkpoint.mat');
    eval_log_file = fullfile(output_root, 'evaluated_individuals.csv'); 

    % ========== 初始化 ==========
    if ~exist(output_root, 'dir')
        mkdir(output_root);
    end

    % 写入 CSV 参数注释（文件开头）
    fid_csv = fopen(eval_log_file, 'w');
    if fid_csv ~= -1
        fprintf(fid_csv, '# Simulation Parameters:\n');
        fprintf(fid_csv, '# m2m_folder: %s\n', m2m_folder);
        fprintf(fid_csv, '# MNI Target: [%.1f, %.1f, %.1f]\n', mni_target(1), mni_target(2), mni_target(3));
        fprintf(fid_csv, '# ROI Radius: %.1f mm\n', roi_radius);
        fprintf(fid_csv, '# Currents: %+.4f A\n', currents(1));
        fprintf(fid_csv, '# Electrode Shape: %s\n', shape);
        fprintf(fid_csv, '# Electrode Dimensions: %.1f x %.1f mm\n', dimensions(1), dimensions(2));
        fprintf(fid_csv, '# Electrode Thickness: %.1f mm\n', thickness);
        fprintf(fid_csv, '# Electrode Pool: %s\n', strjoin(electrode_pool, ', '));
        fprintf(fid_csv, '# Population Size: %d\n', population_size);
        fprintf(fid_csv, '# Max Generations: %d\n', max_generations);
        fprintf(fid_csv, '# Crossover Rate: %.2f\n', crossover_rate);
        fprintf(fid_csv, '# Mutation Rate: %.2f\n', mutation_rate);
        fprintf(fid_csv, '# Elite Size: %d\n', elite_size);
        fprintf(fid_csv, '# Parallel Workers: %d\n', parallel_workers);
        fprintf(fid_csv, '# Target Strength: %.2f V/m\n', target_strength);
        fprintf(fid_csv, '# Penalty Lambda: %.1f\n', penalty_lambda);
        fprintf(fid_csv, '# Patience: %d\n', patience);
        fprintf(fid_csv, 'C1E1,C1E2,C2E1,C2E2,Fitness,roi_avg,rest_avg,focus_ratio,mod_depth,focus_vol_total,peak_mni_x,peak_mni_y,peak_mni_z\n');
        fclose(fid_csv);
    else
        warning('无法创建 CSV 文件: %s', eval_log_file);
    end

    % 启动并行池
    pool = gcp('nocreate');
    if isempty(pool)
        pool = parpool(parallel_workers);
    elseif pool.NumWorkers ~= parallel_workers
        delete(pool);
        pool = parpool(parallel_workers);
    end

    % ========== 确保 Worker 能访问依赖文件 ==========
    required_files = {'TIS.m', 'look_efield.m', 'eval_individual.m', 'setup_path.m'};
    addAttachedFiles(pool, required_files);
    spmd
        setup_path();
    end

    % ========== 定义适应度函数句柄 ==========
    eval_func = @(ind) eval_individual(ind, m2m_folder, output_root, mni_target, ...
        roi_radius, currents, shape, dimensions, thickness, ...
        target_strength, penalty_lambda);

    % ========== 运行遗传算法 ==========
    [best_ind, best_fit] = genetic_algorithm_core(eval_func, electrode_pool, ...
        population_size, max_generations, crossover_rate, mutation_rate, ...
        elite_size, checkpoint_file, log_file, eval_log_file, patience);

    if ~isempty(best_ind)
        fprintf('最优电极组合: %s\n', strjoin(best_ind, ','));
        fprintf('最优适应度: %f\n', best_fit);
    else
        fprintf('未找到任何有效个体。\n');
    end
end