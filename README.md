# SimNIBS MATLAB工具集

基于SimNIBS的脑磁刺激分析工具集，提供TMS/DBS刺激模拟、结构分割和电极位置优化功能。

## 功能模块

### 1. 结构像分割 (Charm)
- **功能**: 脑部MRI影像处理工具，支持T1/T2影像文件输入
- **特性**: 可视化分割结果，支持自定义输出路径和受试者命名
- **用途**: 为后续模拟提供精准的脑部结构参考

### 2. TI模拟
- **功能**: TMS刺激模拟计算工具
- **特性**:
  - 支持多种电极形状（圆形、方形、椭圆）
  - 可配置刺激半径、深度和尺寸
  - MNI坐标输入支持
  - 实时电场场强监控
- **用途**: 计算脑部电场分布

### 3. TI优化 (Opt_EEG)
- **功能**: 基于遗传算法的电极位置优化工具
- **特性**:
  - 两种优化模式：电极点位优化、坐标点位优化
  - 支持遗传算法参数调节
  - 支持ROI目标强度和惩罚权重
  - 并行计算加速
- **用途**: 寻找最优电极位置，最大化刺激效率

## 系统要求

- **MATLAB**: R2018b或更高版本
- **必需工具箱**:
  - Statistics and Machine Learning Toolbox
  - Parallel Computing Toolbox (推荐)
- **外部依赖**:
  - SimNIBS

## 安装与运行

### 克隆仓库
```bash
git clone https://github.com/sunny-luoyun/Simnibs-matlab.git
cd Simnibs-matlab
```

### 启动应用
在MATLAB命令窗口中运行：
```matlab
simnibs
```

### 路径设置
项目自动通过`setup_path.m`配置路径，无需手动添加。如需添加新模块，请在`setup_path.m`的`folders`列表中添加：

```matlab
folders = {
    'charm',      % 结构像分割
    'opt_eeg',    % TI优化
    'TI',         % TI模拟
    'your_module' % 新模块
};
```

## 更新检查

项目支持自动更新检查功能：
- 启动时会自动检查本地版本与远程仓库的commit差异
- 发现新版本时会提示更新
- 支持自动拉取更新或下载zip包更新
