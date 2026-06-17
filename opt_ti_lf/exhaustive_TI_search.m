function [best_ind, best_fit, best_info] = exhaustive_TI_search(...
    fields_constant, electrode_names, geo_cache, currents, ...
    target_strength, penalty_lambda, output_root)
% 穷举所有电极组合，找全局最优 TI 电极配置
%
% 输入:
%   fields_constant : parallel.pool.Constant 封装的预计算电场
%   electrode_names : {N_elec} 电极名称
%   geo_cache       : ROI 几何缓存
%   currents        : [I, -I] 电流值
%   target_strength : 靶区目标场强 (V/m)
%   penalty_lambda  : 惩罚系数
%   output_root     : 输出文件夹（保存全部结果的 CSV）
%
% 输出:
%   best_ind  : 最优 4 电极 cell array
%   best_fit  : 最优适应度
%   best_info : 详细信息

    N = length(electrode_names);
    I = currents(1);

    all_combos = nchoosek(1:N, 4);
    M = size(all_combos, 1);
    fprintf('  电极池: %d 个, 组合数: %d\n', N, M);

    batch_size = 20000;
    num_batches = ceil(M / batch_size);
    fprintf('  分 %d 批 (每批 %d), 开始穷举搜索...\n\n', num_batches, batch_size);

    % ── DataQueue 实时推送进度 ──
    dq = parallel.pool.DataQueue;
    t_start = tic;

    afterEach(dq, @(global_i) ...
        fprintf('  · 进度: %d / %d (%.1f%%) | 已用: %.0f 秒\n', ...
            global_i, M, global_i / M * 100, toc(t_start)));

    % ── CSV: 写入表头 ──
    csv_path = fullfile(output_root, 'exhaustive_results.csv');
    fid_csv = fopen(csv_path, 'w');
    fprintf(fid_csv, 'Fitness,roi_avg,rest_avg,C1E1,C1E2,C2E1,C2E2\n');
    fclose(fid_csv);

    % ── 批式穷举搜索 ──
    overall_best_fit = -inf;
    overall_best_idx = 0;

    data_mb = N * size(geo_cache.gm_volumes, 1) * 3 * 8 / 1e6;
    fprintf('  → 正在向 worker 广播数据 (%.0f MB)...\n', data_mb);

    for b = 1:num_batches
        start_idx = (b-1) * batch_size + 1;
        end_idx = min(b * batch_size, M);
        n_in_batch = end_idx - start_idx + 1;
        fprintf('  批 %d/%d: 评估 %d 个组合...\n', b, num_batches, n_in_batch);

        batch_fitness = zeros(n_in_batch, 1);
        batch_roi_avg  = zeros(n_in_batch, 1);
        batch_rest_avg = zeros(n_in_batch, 1);
        batch_indices  = zeros(n_in_batch, 4);

        parfor j = 1:n_in_batch
            combo_idx = all_combos(start_idx + j - 1, :);
            i1 = combo_idx(1); i2 = combo_idx(2);
            i3 = combo_idx(3); i4 = combo_idx(4);

            fields = fields_constant.Value;

            E1 = squeeze(fields(i1, :, :)) - squeeze(fields(i2, :, :));
            E2 = squeeze(fields(i3, :, :)) - squeeze(fields(i4, :, :));
            TI = get_maxTI(E1, E2);

            gm_vols = geo_cache.gm_volumes;
            roi_mask = geo_cache.roi_mask;

            roi_avg = sum(TI(roi_mask) .* gm_vols(roi_mask)) / geo_cache.roi_volume;
            rest_avg = sum(TI(geo_cache.non_roi_mask) .* gm_vols(geo_cache.non_roi_mask)) / geo_cache.non_roi_volume;

            if ~isnan(roi_avg) && ~isnan(rest_avg) && rest_avg > 1e-12
                F = roi_avg / rest_avg;
                penalty = penalty_lambda * max(0, target_strength - roi_avg)^2;
                batch_fitness(j) = F - penalty;
            else
                batch_fitness(j) = -1e6;
            end
            batch_roi_avg(j) = roi_avg;
            batch_rest_avg(j) = rest_avg;
            batch_indices(j, :) = combo_idx;

            % 每 5000 组合推送一次进度
            global_i = start_idx + j - 1;
            if mod(global_i, 5000) == 0
                send(dq, global_i);
            end
        end

        % 本批最优
        [max_in_batch, local_idx] = max(batch_fitness);
        if max_in_batch > overall_best_fit
            overall_best_fit = max_in_batch;
            overall_best_idx = start_idx + local_idx - 1;
        end

        % 追加写入本批结果到 CSV
        fid_csv = fopen(csv_path, 'a');
        for j = 1:n_in_batch
            c = batch_indices(j, :);
            fprintf(fid_csv, '%.6f,%.6f,%.6f,%s,%s,%s,%s\n', ...
                batch_fitness(j), batch_roi_avg(j), batch_rest_avg(j), ...
                electrode_names{c(1)}, electrode_names{c(2)}, ...
                electrode_names{c(3)}, electrode_names{c(4)});
        end
        fclose(fid_csv);

        elapsed = toc(t_start);
        pct = b / num_batches * 100;
        eta = elapsed / b * (num_batches - b);

        if overall_best_idx > 0
            best_combo = all_combos(overall_best_idx, :);
            best_str = strjoin(electrode_names(best_combo), ',');
        else
            best_str = '—';
        end

        fprintf('  ▶ 批 %d/%d (%d%%) | 最优: %.4f [%s] | 已用: %.0f 秒 | ETA: %.0f 秒\n', ...
            b, num_batches, round(pct), overall_best_fit, best_str, elapsed, eta);
    end

    % ── 输出结果 ──
    fprintf('\n');
    if overall_best_idx > 0
        best_idx = all_combos(overall_best_idx, :);
        best_ind = electrode_names(best_idx);
        best_fit = overall_best_fit;

        % 最终详细评估
        fields = fields_constant.Value;
        E1 = squeeze(fields(best_idx(1), :, :)) - squeeze(fields(best_idx(2), :, :));
        E2 = squeeze(fields(best_idx(3), :, :)) - squeeze(fields(best_idx(4), :, :));
        TI = get_maxTI(E1, E2);
        [peak_val, peak_idx] = max(TI);
        gm_vols = geo_cache.gm_volumes;
        roi_avg = sum(TI(geo_cache.roi_mask) .* gm_vols(geo_cache.roi_mask)) / geo_cache.roi_volume;
        rest_avg = sum(TI(geo_cache.non_roi_mask) .* gm_vols(geo_cache.non_roi_mask)) / geo_cache.non_roi_volume;
        fwhm = peak_val / 2;
        above_fwhm = TI >= fwhm;
        focus_vol_total = sum(gm_vols(above_fwhm));
        roi_above = above_fwhm & geo_cache.roi_mask;
        focus_vol_roi = sum(gm_vols(roi_above));
        focus_ratio = focus_vol_roi / focus_vol_total;
        roi_TI = TI(geo_cache.roi_mask);
        mod_depth = (max(roi_TI) - min(roi_TI)) / roi_avg;

        best_info = struct();
        best_info.roi_avg = roi_avg;
        best_info.rest_avg = rest_avg;
        best_info.focus_ratio = focus_ratio * 100;
        best_info.mod_depth = mod_depth;
        best_info.focus_vol_total = focus_vol_total;
        best_info.peak_mni = geo_cache.gm_centers(peak_idx, :);
    else
        best_ind = {};
        best_fit = -inf;
        best_info = struct();
    end

    fprintf('  ✅ 穷举完成! 总耗时: %.1f 秒\n', toc(t_start));
end
