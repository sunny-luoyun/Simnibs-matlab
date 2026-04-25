function avg_TI = look_efield(TI_folder, m2m_folder, MNI_coords, radius)
% 计算指定 ROI 内的平均 TI 包络振幅，仅返回数值
    [~, folder_name] = fileparts(m2m_folder);
    if startsWith(folder_name, 'm2m_')
        subject = folder_name(5:end);
    else
        subject = folder_name;
    end

    mesh_file = fullfile(TI_folder, sprintf('%s_TIenvelope_only.msh', subject));
    if ~exist(mesh_file, 'file')
        error('找不到文件: %s', mesh_file);
    end

    head_mesh = mesh_load_gmsh4(mesh_file);
    gray_matter = mesh_extract_regions(head_mesh, 'region_idx', 2);
    if isempty(gray_matter) || isempty(gray_matter.element_data)
        error('灰质区域未找到或网格数据缺失');
    end

    subject_coords = mni2subject_coords(MNI_coords, m2m_folder);

    elm_centers = mesh_get_tetrahedron_centers(gray_matter);
    elm_vols = mesh_get_tetrahedron_sizes(gray_matter);
    distances = sqrt(sum((elm_centers - subject_coords).^2, 2));
    roi_mask = distances < radius;

    if ~any(roi_mask)
        warning('ROI 内没有元素，请检查半径或坐标');
        avg_TI = NaN;
        return;
    end

    field_name = 'maxTIamplitude';
    field_idx = get_field_idx(gray_matter, field_name, 'elements');
    if isempty(field_idx)
        error('网格中未找到字段: %s', field_name);
    end
    field = gray_matter.element_data{field_idx}.tetdata;

    avg_TI = sum(field(roi_mask) .* elm_vols(roi_mask)) / sum(elm_vols(roi_mask));
end