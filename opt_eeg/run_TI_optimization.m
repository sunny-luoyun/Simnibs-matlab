function run_TI_optimization(m2m_folder, output_root, mni_target, ...
    roi_radius, currents, shape, dimensions, thickness, electrode_pool, ...
    population_size, max_generations, crossover_rate, mutation_rate, ...
    elite_size, parallel_workers, w1, w2, w3, target_strength, penalty_lambda)
% RUN_TI_OPTIMIZATION  使用给定参数启动 TI 电极优化
%
% 输入参数与 UI 界面字段一一对应，由 opt_eeg 回调传入。
% 所有输入均为必要参数，无默认值（由 UI 提供）。

    log_file = fullfile(output_root, 'ga_log.txt');
    checkpoint_file = fullfile(output_root, 'ga_checkpoint.mat');

    % ========== 初始化 ==========
    if ~exist(output_root, 'dir')
        mkdir(output_root);
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
    required_files = {'TIS.m', 'look_efield.m', 'eval_individual.m'};
    addAttachedFiles(pool, required_files);
    spmd
        addpath(pwd);
    end

    % ========== 定义适应度函数句柄 ==========
    eval_func = @(ind) eval_individual(ind, m2m_folder, output_root, mni_target, ...
        roi_radius, currents, shape, dimensions, thickness, ...
        w1, w2, w3, target_strength, penalty_lambda);

    % ========== 运行遗传算法 ==========
    [best_ind, best_fit] = genetic_algorithm_core(eval_func, electrode_pool, ...
        population_size, max_generations, crossover_rate, mutation_rate, ...
        elite_size, checkpoint_file, log_file);

    if ~isempty(best_ind)
        fprintf('最优电极组合: %s\n', strjoin(best_ind, ','));
        fprintf('最优适应度: %f\n', best_fit);
    else
        fprintf('未找到任何有效个体。\n');
    end
end