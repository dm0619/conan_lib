# Eigen

Conan 包名是 `eigen/5.0.1`，CMake 包名是 `Eigen3`，目标是 `Eigen3::Eigen`。Eigen 是纯头文件库，要求 C++14 或更高标准。安装会把头文件放入 Conan 缓存，模板代码在编译你的应用时实例化。

## 在本机运行已有的示例

根目录的 `examples/` 和 `profiles/` 用于本机验证。通过 Git 检出时，请按下文「接入自己的 CMake 项目」使用 Conan Home 中的 profile。本机示例使用 Windows x64、Visual Studio 2026 的 C++ 工作负载（MSVC v145）、Windows SDK、CMake 4.2 或更高版本以及 Conan 2。

如果本机的 `conan --version` 已显示适用的 Conan 2，可直接运行下一段。首次安装 Conan 时，可在仓库根目录用 CMD 执行以下命令，需要 Python 3 和可用的 pip 包源。

```cmd
py -m venv build\conan-venv
build\conan-venv\Scripts\activate.bat
python -m pip install conan==2.34.0
```

在仓库根目录用 CMD 逐条执行。每步成功后再继续。

```cmd
conan export ./third_party/eigen --version=5.0.1 --no-remote
conan install ./examples/eigen -pr:a ./profiles/windows-msvc195-x64-release --no-remote --build=missing -of ./build/eigen
cmake -S ./examples/eigen --preset conan-default
cmake --build ./build/eigen --config Release
build\eigen\Release\eigen_example.exe
```

预期输出为 `Eigen 5.0.1: 17 39`，表示示例计算的矩阵与向量乘积是 `(17, 39)`。安装过程中所需的 Eigen 文件都来自仓库；再次安装可复用本机缓存。

## 源码归档校验

仓库保存官方原始 [eigen-5.0.1.tar.gz](upstream/eigen-5.0.1.tar.gz) 和随版本发布的 [校验文件](upstream/eigen-5.0.1.tar.gz.sha256)。两者均可从 Eigen 项目独立下载。归档的官方 SHA-256 为 `e9c326dc8c05cd1e044c71f30f1b2e34a6161a3b6ecf445d56b53ff1669e3dec`。[官方下载](https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz) · [官方 SHA-256](https://gitlab.com/api/v4/projects/15462818/packages/generic/eigen/5.0.1/eigen-5.0.1.tar.gz.sha256)

[conandata.yml](conandata.yml) 按版本固定源码摘要。导出时校验工作区文件，每次 `conan install` 都重新读取并校验缓存中的原始压缩包，即使复用已安装的头文件包也会执行。文件缺失、归档内容变化或校验文件与固定值不符，都会终止安装。首次构建时，配方在解压前再次检查摘要，随后从构建目录打包头文件。

## 选择和收录版本

仓库目前收录 `5.0.1`。省略 `--version` 时，`conan export` 使用 `conandata.yml` 中的 `default_version`，当前同样为 `5.0.1`。显式指定版本时，配方只导出该版本的原始归档和校验文件，并把该版本的 `sources` 条目保存在缓存中。

要一次导出仓库收录的所有库和版本，请按[根目录使用说明](../../README.md#导出并安装)选择适合你的系统的脚本。

收录另一个适用同一构建逻辑的版本时，将官方原始归档及校验文件放入 `upstream/`，再在 `conandata.yml` 的 `sources` 中添加该版本。使用 `conan export ./third_party/eigen --version=<版本> --no-remote` 导出。在消费项目的 `[requires]` 中填写 `eigen/<版本>`，并同步该项目在 `find_package` 中声明的版本要求。不同项目可以从同一个 Conan 缓存选择各自的版本。同一个依赖图若要求两个不兼容的 Eigen 版本，需要先解决版本冲突。[Conan 版本冲突](https://docs.conan.io/2/tutorial/versioning/conflicts.html)

## 接入自己的 CMake 项目

在项目的 `conanfile.txt` 中加入依赖和生成器。已有同名段时，将相应的行追加到原有段中。

```ini
[requires]
eigen/5.0.1

[generators]
CMakeDeps
CMakeToolchain
```

在定义了 `my_app` 目标的 `CMakeLists.txt` 中加入：

```cmake
find_package(Eigen3 5.0.1 CONFIG REQUIRED)
target_compile_features(my_app PRIVATE cxx_std_14)
target_link_libraries(my_app PRIVATE Eigen3::Eigen)
```

在 C++ 文件中用 `#include <Eigen/Dense>` 即可访问矩阵和向量。若你的库在公开头文件中暴露 Eigen 类型，将该库目标上的依赖与 C++ 标准要求设为 `PUBLIC`，让下游目标继承它们。

导出、安装和运行 CMake 的完整命令见[根目录使用说明](../../README.md)。

## 来源与打包范围

- 2026-11-25 核实上游最新稳定版为 `5.0.1`，标签提交为 `bc3b39870ecb690a623a3f49149a358b95c5781d`。[Eigen 官网](https://libeigen.gitlab.io/) · [5.0.1 发布公告](https://libeigen.gitlab.io/news/eigen_5.0.1_released/)
- 本次使用原版源码，补丁数为零。配方安装 `Eigen/`、`unsupported/Eigen/`、上游签名文件和许可证。默认使用 Eigen 自带的计算实现。可选外部后端（如 MKL）需要消费项目另行提供。上游附带的独立 BLAS/LAPACK 二进制库不在此头文件包的范围内。[上游许可说明](https://gitlab.com/libeigen/eigen/-/blob/5.0.1/COPYING.README)
- 已在 Windows x64、Conan 2.34.0、CMake 4.4.5、MSVC 19.52、C++14、Release 上验证。空缓存安装后，608 个已安装文件与归档对应文件的内容一致，CMake 示例编译运行成功。改动工作区归档会阻止导出。改动缓存归档会阻止安装，包括缓存命中时。
- 在临时仓库副本中额外添加 5.0.0，验证两个版本可用同一配方分别导出、缓存和安装，对应的 CMake 示例均通过。5.0.0 仅用于这次验证。
