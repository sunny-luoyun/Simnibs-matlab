# SimNIBS MATLAB工具集

基于SimNIBS的脑磁刺激分析工具集

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


## 更多文档

项目详细的方法学说明请参阅 [GitHub Wiki](https://github.com/sunny-luoyun/Simnibs-matlab/wiki)
