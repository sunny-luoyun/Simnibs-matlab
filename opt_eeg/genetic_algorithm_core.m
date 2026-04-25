function [best_individual, best_fitness] = genetic_algorithm_core(...
    fitness_func, electrode_pool, population_size, max_generations, ...
    crossover_rate, mutation_rate, elite_size, checkpoint_file, log_file_path)
% GENETIC_ALGORITHM_CORE  遗传算法框架（电极优化）
%   fitness_func     : 适应度函数句柄 @(individual) -> scalar fitness
%   electrode_pool   : 所有可用电极名称的 cell array
%   其余参数同原版含义
%   checkpoint_file  : 检查点 .mat 路径
%   log_file_path    : 日志文件路径

    num_electrodes = 4;  % 固定为4电极

    % ---- 加载检查点 or 初始化 ----
    [population, fitness, start_generation, fitness_cache, ...
     global_best_individual, global_best_fitness] = load_state(checkpoint_file);

    log_fid = fopen(log_file_path, 'a');
    if log_fid == -1
        error('无法打开日志文件: %s', log_file_path);
    end
    fprintf(log_fid, 'Starting GA...\n');

    if isempty(population)
        population = init_pop(population_size, electrode_pool, num_electrodes);
        start_generation = 0;
        fitness = [];
        global_best_individual = [];
        global_best_fitness = -inf;
    end

    % ---- 主循环 ----
    for gen = start_generation : (max_generations - 1)
        fprintf(log_fid, '\nGeneration %d:\n', gen+1);

        % 计算适应度（利用缓存）
        [fitness, eval_info] = calculate_fitness(population, fitness_func, fitness_cache, log_fid);
        % 在此之后立即打印本代所有个体的详信息（控制台 + 日志）
        fprintf('------------  Generation %d 详情  ------------\n', gen+1);
        for i = 1:length(population)
            key = cell2str(population{i});
            fit = fitness(i);
            if ~isempty(fieldnames(eval_info{i}))  % 有额外信息才打印
                fprintf('%-25s  fit=%+.4f  roi_avg=%.4f  focus_ratio=%.2f%%  mod_depth=%.3f  focus_vol=%.1f mm³  peak_mni=[%.1f %.1f %.1f]\n', ...
                    key, fit, eval_info{i}.roi_avg, eval_info{i}.focus_ratio, ...
                    eval_info{i}.mod_depth, eval_info{i}.focus_vol_total, eval_info{i}.peak_mni);
            else
                fprintf('%-25s  fit=%+.4f  (cached)\n', key, fit);
            end
        end
        fprintf('---------------------------------------------\n');
                [max_fit, idx] = max(fitness);
        this_best_info = eval_info{idx};
        if ~isempty(this_best_info) && isfield(this_best_info, 'roi_avg')
            fprintf(log_fid, 'Best in this generation: %s, Fitness: %.4f, roi_avg: %.4f, focus_ratio: %.2f%%, mod_depth: %.3f\n', ...
                cell2str(population{idx}), max_fit, ...
                this_best_info.roi_avg, this_best_info.focus_ratio, this_best_info.mod_depth);
        else
            fprintf(log_fid, 'Best in this generation: %s, Fitness: %.4f (cached, no extra info)\n', ...
                cell2str(population{idx}), max_fit);
        end

        % 更新全局最优
        if max_fit > global_best_fitness
            global_best_fitness = max_fit;
            global_best_individual = population{idx};
            fprintf(log_fid, 'New global best found: %s -> Fitness: %.4f, roi_avg: %.4f, focus_ratio: %.2f%%, mod_depth: %.3f\n', ...
            cell2str(global_best_individual), global_best_fitness, ...
            this_best_info.roi_avg, this_best_info.focus_ratio, this_best_info.mod_depth);
        end

        % ---- 精英保留 + 生成下一代 ----
        [~, sort_idx] = sort(fitness, 'descend');
        elite_pop = population(sort_idx(1:elite_size));   % cell array

        selected = selection(population, fitness, 0, log_fid);
        parent_pool = selected(1:end-elite_size);
        offspring = crossover(parent_pool, crossover_rate, num_electrodes, electrode_pool);
        mutated = mutate(offspring, mutation_rate, electrode_pool, num_electrodes);
        population = [elite_pop; mutated];

        % 保存检查点（包含全局最优）
        save_state(population, fitness, gen+1, fitness_cache, ...
                   global_best_individual, global_best_fitness, checkpoint_file);
    end

    % 最终输出全局最优
    best_individual = global_best_individual;
    best_fitness = global_best_fitness;
    if ~isempty(best_individual)
        fprintf(log_fid, '\nOptimization finished.\nGlobal best: %s, Fitness: %f\n', ...
            cell2str(best_individual), best_fitness);
    else
        fprintf(log_fid, '\nNo valid individual found.\n');
    end
    fclose(log_fid);
end

% ================== 辅助函数 ==================

function pop = init_pop(sz, pool, n)
    pop = cell(sz, 1);
    seen = containers.Map('KeyType','char','ValueType','logical');
    count = 0;
    while count < sz
        idx = randperm(length(pool), n);
        ind = sort(pool(idx));
        key = strjoin(ind, ',');
        if ~isKey(seen, key)
            count = count + 1;
            pop{count} = ind;
            seen(key) = true;
        end
    end
end

function s = cell2str(c)
    s = strjoin(c, ',');
end

function [fitness, info] = calculate_fitness(pop, func, cache, fid)
% 现在 func 应该返回 [f, info] 两个输出
% 新增输出 info : 一个 cell 数组，长度与 pop 相同，每个元素是一个结构体（来自 eval_individual）

    N = length(pop);
    fitness = zeros(1, N);
    info = cell(1, N);          % 新增
    uncached_idx = [];
    for i = 1:N
        key = cell2str(pop{i});
        if isKey(cache, key)
            fitness(i) = cache(key);
            % 缓存命中的个体没有额外信息，给个空结构体
            info{i} = struct();
            fprintf(fid, 'Cached: %s -> %f\n', key, fitness(i));
        else
            uncached_idx(end+1) = i;
        end
    end

    if ~isempty(uncached_idx)
        M = length(uncached_idx);
        temp_fit = zeros(1, M);
        temp_info = cell(1, M);     % 存储额外信息
        pop_uncached = pop(uncached_idx);

        parfor j = 1:M
            [temp_fit(j), temp_info{j}] = func(pop_uncached{j});  % 调用返回两个值
        end

        % 放回原数组
        fitness(uncached_idx) = temp_fit;
        info(uncached_idx)    = temp_info;

        for j = 1:M
            idx = uncached_idx(j);
            key = cell2str(pop{idx});
            cache(key) = fitness(idx);
            fprintf(fid, 'Evaluated: %s -> %f\n', key, fitness(idx));
        end
    end
end

function selected = selection(pop, fit, elite, fid)
    N = length(pop);
    selected = cell(N, 1);
    tour_size = 3;

    if elite > 0
        [~, sort_idx] = sort(fit, 'descend');
        for e = 1:min(elite, N)
            selected{e} = pop{sort_idx(e)};
        end
        start_idx = elite + 1;
    else
        start_idx = 1;
    end

    for i = start_idx:N
        candidates = randi(N, tour_size, 1);
        [~, best] = max(fit(candidates));
        selected{i} = pop{candidates(best)};
    end
end

function offspring = crossover(selected, rate, n, pool)
    N = length(selected);
    offspring = cell(N, 1);
    i = 1;
    while i <= N
        if i+1 <= N && rand() < rate
            p1 = selected{i};
            p2 = selected{i+1};
            cp = randi([1 n-1]);
            child1 = [p1(1:cp), p2(cp+1:end)];
            child2 = [p2(1:cp), p1(cp+1:end)];
            child1 = repair_individual(child1, pool, n);
            child2 = repair_individual(child2, pool, n);
            offspring{i}   = sort(child1);
            offspring{i+1} = sort(child2);
            i = i + 2;
        else
            offspring{i} = selected{i};
            i = i + 1;
        end
    end
end

function pop = mutate(pop, rate, pool, n)
    for i = 1:length(pop)
        if rand() < rate
            ind = pop{i};
            mut_point = randi(n);
            available = setdiff(pool, ind);
            if isempty(available)
                continue;
            else
                ind{mut_point} = available{randi(length(available))};
                pop{i} = sort(repair_individual(ind, pool, n));
            end
        end
    end
end

function new_ind = repair_individual(ind, pool, n)
    [unique_elec, ia] = unique(ind, 'stable');
    if length(unique_elec) == n
        new_ind = ind;
        return;
    end
    new_ind = unique_elec;
    available = setdiff(pool, new_ind);
    needed = n - length(new_ind);
    if length(available) < needed
        warning('电极池不足以修复个体，返回未修复个体');
        new_ind = ind;   % 返回原个体，避免中断GA
        return;
    end
    add_idx = randperm(length(available), needed);
    add = available(add_idx);
    new_ind = [new_ind, add];
end

% ---------- 检查点操作 ----------
function [pop, fit, gen, cache, global_best_ind, global_best_fit] = load_state(file)
    if exist(file, 'file')
        data = load(file);
        pop = data.population;
        fit = data.fitness;
        gen = data.generation;
        if isempty(data.cache_keys)
            cache = containers.Map('KeyType','char','ValueType','double');
        else
            cache = containers.Map(data.cache_keys, data.cache_values);
        end

        % 恢复全局最优（兼容旧检查点文件缺少该字段）
        if isfield(data, 'global_best_individual')
            global_best_ind = data.global_best_individual;
        else
            global_best_ind = [];
        end
        if isfield(data, 'global_best_fitness')
            global_best_fit = data.global_best_fitness;
        else
            global_best_fit = -inf;
        end
    else
        pop = {};
        fit = [];
        gen = 0;
        cache = containers.Map('KeyType','char','ValueType','double');
        global_best_ind = [];
        global_best_fit = -inf;
    end
end

function save_state(pop, fit, gen, cache, global_best_ind, global_best_fit, file)
    population = pop;      
    fitness = fit;         
    generation = gen;      
    cache_keys = keys(cache);
    cache_values = values(cache);
    global_best_individual = global_best_ind; 
    global_best_fitness = global_best_fit;   
    save(file, 'population', 'fitness', 'generation', 'cache_keys', 'cache_values', ...
              'global_best_individual', 'global_best_fitness');
end