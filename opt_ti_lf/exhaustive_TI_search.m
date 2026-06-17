function [best_ind, best_fit, best_info] = exhaustive_TI_search(...
    fields_file, fields_roi, electrode_names, geo_cache_constant, ...
    currents, target_strength, penalty_lambda, output_root, N_gm, N_elec)
% 两阶段穷举 TI 搜索：
%   Stage A — ROI-only 快速筛查（1609 节点），选出 Top 候选
%   Stage B — 全脑精确评估 Top 候选，保证精度不损失
%
% 输入:
%   fields_file     : 全脑电场二进制 memmapfile ([N_gm, 3, N_elec])
%   fields_roi      : ROI-only 电场 [N_elec, N_roi, 3]（内存常驻，极小）
%   electrode_names : {N_elec} 电极名称
%   geo_cache_constant: parallel.pool.Constant(geo_cache)
%   currents        : [I, -I] 电流值
%   target_strength : 靶区目标场强 (V/m)
%   penalty_lambda  : 惩罚系数
%   output_root     : 输出文件夹
%   N_gm            : 灰质单元总数
%   N_elec          : 电极数
%
% 输出:
%   best_ind  : 最优 4 电极 cell array
%   best_fit  : 最优适应度
%   best_info : 详细信息结构体

    N = N_elec;
    I = currents(1);

    all_combos = nchoosek(1:N, 4);
    M = size(all_combos, 1);
    fprintf('  电极池: %d 个, 组合数: %d\n', N, M);

    % ── 预取 ROI 几何（避免 parfor 反复切片 geo_cache） ──
    g0 = geo_cache_constant.Value;
    N_roi = sum(g0.roi_mask);
    gm_vols_roi = g0.gm_volumes(g0.roi_mask);
    roi_volume = g0.roi_volume;

    % ========== Stage A: ROI-only 快速筛查 ==========
    fprintf('\n  ── Stage A: ROI-only 快速筛查 (%d 灰质单元) ──\n', N_roi);

    batch_size = 10000;
    num_batches = ceil(M / batch_size);
    fprintf('  分 %d 批 (每批 %d)\n\n', num_batches, batch_size);

    dq = parallel.pool.DataQueue;
    t_a = tic;

    afterEach(dq, @(global_i) ...
        fprintf('  · 进度: %d / %d (%.1f%%) | 已用: %.0f 秒\n', ...
            global_i, M, global_i / M * 100, toc(t_a)));

    fields_roi_constant = parallel.pool.Constant(fields_roi);
    vols_roi_constant = parallel.pool.Constant(gm_vols_roi);
    roi_vol_const = parallel.pool.Constant(roi_volume);

    all_scores = zeros(M, 1);

    for b = 1:num_batches
        start_idx = (b-1) * batch_size + 1;
        end_idx = min(b * batch_size, M);
        n_in_batch = end_idx - start_idx + 1;
        fprintf('  批 %d/%d: 筛查 %d 个组合 (ROI-only)...\n', b, num_batches, n_in_batch);

        batch_scores = zeros(n_in_batch, 1);

        parfor j = 1:n_in_batch
            combo_idx = all_combos(start_idx + j - 1, :);
            i1 = combo_idx(1); i2 = combo_idx(2);
            i3 = combo_idx(3); i4 = combo_idx(4);

            Fr = fields_roi_constant.Value;
            E1 = squeeze(Fr(i1,:,:)) - squeeze(Fr(i2,:,:));
            E2 = squeeze(Fr(i3,:,:)) - squeeze(Fr(i4,:,:));

            TI = get_maxTI(E1, E2);
            roi_avg = sum(TI .* vols_roi_constant.Value) / roi_vol_const.Value;
            batch_scores(j) = roi_avg;

            global_i = start_idx + j - 1;
            if mod(global_i, 10000) == 0
                send(dq, global_i);
            end
        end

        all_scores(start_idx:end_idx) = batch_scores;

        elapsed = toc(t_a);
        pct = b / num_batches * 100;
        eta = elapsed / b * (num_batches - b);
        fprintf('  ▶ 批 %d/%d (%d%%) | 本批 Top: %.4f V/m | 已用: %.0f 秒 | ETA: %.0f 秒\n', ...
            b, num_batches, round(pct), max(batch_scores), elapsed, eta);
    end

    top_k = min(1000, M);
    [~, sort_idx] = sort(all_scores, 'descend');
    top_indices = sort_idx(1:top_k);
    if M > 0
        fprintf('\n  ✅ Stage A 完成: %d → %d 候选 | Top roi_avg: %.4f V/m | 用时: %.1f 秒\n', ...
            M, top_k, all_scores(top_indices(1)), toc(t_a));
    end

    % ========== Stage B: 全脑精确评估 Top K ==========
    fprintf('\n  ── Stage B: 全脑精确评估 Top %d ──\n', top_k);

    overall_best_fit = -inf;
    overall_best_idx = 0;

    batch_size_b = 250;
    num_batches_b = ceil(top_k / batch_size_b);

    csv_path = fullfile(output_root, 'exhaustive_results.csv');
    data_mb = N * N_gm * 3 * 8 / 1e6;
    fprintf('  → 全脑电场 memmapfile: %.0f MB (仅评估 %d 个候选)\n', data_mb, top_k);

    t_b = tic;

    for b = 1:num_batches_b
        start_idx = (b-1) * batch_size_b + 1;
        end_idx = min(b * batch_size_b, top_k);
        n_in_batch = end_idx - start_idx + 1;

        batch_fitness = zeros(n_in_batch, 1);
        batch_roi = zeros(n_in_batch, 1);
        batch_rest = zeros(n_in_batch, 1);
        batch_focus_ratio = zeros(n_in_batch, 1);
        batch_mod_depth = zeros(n_in_batch, 1);
        batch_focus_vol = zeros(n_in_batch, 1);
        batch_peak_mni = zeros(n_in_batch, 3);
        batch_idx = zeros(n_in_batch, 4);

        parfor j = 1:n_in_batch
            combo_idx = all_combos(top_indices(start_idx + j - 1), :);
            i1 = combo_idx(1); i2 = combo_idx(2);
            i3 = combo_idx(3); i4 = combo_idx(4);

            [E1, E2] = get_field_slices(fields_file, i1, i2, i3, i4, N_gm, N);
            TI = get_maxTI(E1, E2);

            g = geo_cache_constant.Value;
            ra = sum(TI(g.roi_mask) .* g.gm_volumes(g.roi_mask)) / g.roi_volume;
            rast = sum(TI(g.non_roi_mask) .* g.gm_volumes(g.non_roi_mask)) / g.non_roi_volume;

            if ~isnan(ra) && ~isnan(rast) && rast > 1e-12
                F = ra / rast;
                penalty = penalty_lambda * max(0, target_strength - ra)^2;
                batch_fitness(j) = F - penalty;

                [peak_val, peak_idx] = max(TI);
                fwhm = peak_val / 2;
                above_fwhm = TI >= fwhm;
                fv = sum(g.gm_volumes(above_fwhm));
                roi_above = above_fwhm & g.roi_mask;
                focus_vol_roi = sum(g.gm_volumes(roi_above));
                fr = focus_vol_roi / fv;
                roi_TI = TI(g.roi_mask);
                md = (max(roi_TI) - min(roi_TI)) / ra;

                batch_focus_ratio(j) = fr;
                batch_mod_depth(j) = md;
                batch_focus_vol(j) = fv;
                batch_peak_mni(j, :) = g.gm_centers(peak_idx, :);
            else
                batch_fitness(j) = -1e6;
                batch_focus_ratio(j) = 0;
                batch_mod_depth(j) = 0;
                batch_focus_vol(j) = 0;
                batch_peak_mni(j, :) = [0, 0, 0];
            end
            batch_roi(j) = ra;
            batch_rest(j) = rast;
            batch_idx(j, :) = combo_idx;
        end

        % 本批最优
        [max_in_batch, local_idx] = max(batch_fitness);
        if max_in_batch > overall_best_fit
            overall_best_fit = max_in_batch;
            overall_best_idx = top_indices(start_idx + local_idx - 1);
        end

        % 追加写入 CSV
        fid_csv = fopen(csv_path, 'a');
        for j = 1:n_in_batch
            c = batch_idx(j, :);
            fprintf(fid_csv, '%.6f,%.6f,%.6f,%.4f,%.4f,%.1f,%.4f,%.4f,%.4f,%s,%s,%s,%s\n', ...
                batch_fitness(j), batch_roi(j), batch_rest(j), ...
                batch_focus_ratio(j), batch_mod_depth(j), batch_focus_vol(j), ...
                batch_peak_mni(j,1), batch_peak_mni(j,2), batch_peak_mni(j,3), ...
                electrode_names{c(1)}, electrode_names{c(2)}, ...
                electrode_names{c(3)}, electrode_names{c(4)});
        end
        fclose(fid_csv);

        elapsed_b = toc(t_b);
        if overall_best_idx > 0
            best_combo = all_combos(overall_best_idx, :);
            best_str = strjoin(electrode_names(best_combo), ',');
        else
            best_str = '—';
        end
        fprintf('  ▶ 批 %d/%d | 当前最优: %.4f [%s] | 已用: %.0f 秒\n', ...
            b, num_batches_b, overall_best_fit, best_str, elapsed_b);
    end

    % ── 结果整理 ──
    total_a = toc(t_a);
    total_b = toc(t_b);
    fprintf('\n  ✅ 穷举完成! 总耗时: %.1f 秒 (Stage A: %.0f 秒 + Stage B: %.0f 秒)\n', ...
        total_a + total_b, total_a, total_b);

    if overall_best_idx > 0
        best_idx = all_combos(overall_best_idx, :);
        best_ind = electrode_names(best_idx);
        best_fit = overall_best_fit;

        [E1, E2] = get_field_slices(fields_file, ...
            best_idx(1), best_idx(2), best_idx(3), best_idx(4), N_gm, N);
        TI = get_maxTI(E1, E2);
        clear E1 E2;

        g = geo_cache_constant.Value;
        [peak_val, peak_idx] = max(TI);
        roi_avg = sum(TI(g.roi_mask) .* g.gm_volumes(g.roi_mask)) / g.roi_volume;
        rest_avg = sum(TI(g.non_roi_mask) .* g.gm_volumes(g.non_roi_mask)) / g.non_roi_volume;
        fwhm = peak_val / 2;
        above_fwhm = TI >= fwhm;
        focus_vol_total = sum(g.gm_volumes(above_fwhm));
        roi_above = above_fwhm & g.roi_mask;
        focus_vol_roi = sum(g.gm_volumes(roi_above));
        focus_ratio = focus_vol_roi / focus_vol_total;
        roi_TI = TI(g.roi_mask);
        mod_depth = (max(roi_TI) - min(roi_TI)) / roi_avg;
        peak_center = g.gm_centers(peak_idx, :);
        clear TI g;

        best_info = struct();
        best_info.roi_avg = roi_avg;
        best_info.rest_avg = rest_avg;
        best_info.focus_ratio = focus_ratio * 100;
        best_info.mod_depth = mod_depth;
        best_info.focus_vol_total = focus_vol_total;
        best_info.peak_mni = peak_center;
    else
        best_ind = {};
        best_fit = -inf;
        best_info = struct();
    end
end


function [E1, E2] = get_field_slices(fields_file, i1, i2, i3, i4, N_gm, N_elec)
% 子函数：各 worker persistent 缓存 memmapfile，零拷贝读取 4 电极切片
    persistent mmf
    if isempty(mmf)
        mmf = memmapfile(fields_file, 'Format', ...
            {'double', [N_gm, 3, N_elec], 'f'});
    end
    f = mmf.Data.f;
    E1 = f(:, :, i1) - f(:, :, i2);
    E2 = f(:, :, i3) - f(:, :, i4);
end
