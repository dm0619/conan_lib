# Conan 离线第三方依赖仓库

这个仓库提供第三方库的官方源码压缩包和 Conan 2 配方。先在本机导出配方，再到 C++ 项目里安装。Conan 从本机缓存构建缺少的包，并复用已有的匹配包。当前收录 [Eigen 5.0.1](third_party/eigen/README.md)，仓库可以为同一个库收录多个版本。

## 准备环境

- 把依赖仓库和你的 C++ 项目都检出到本机。下文假设两个目录相邻，项目目录名为 `my-project`。
- 准备 Conan 2，并确认 `conan --version` 能运行。导出脚本已用 Conan 2.34.0 验证。macOS 和 Linux 上还需要 `python3`。构建项目所需的编译器、SDK 和 CMake 也要提前安装。
- 安装命令使用 Conan Home 里的 `default` profile。若本机还没有它，运行一次 `conan profile detect`，并确认结果匹配项目工具链。使用其他 profile 时，可在安装命令里加上 `-pr:h <目标配置>` 和 `-pr:b <构建机配置>`。

## 导出并安装

从**依赖仓库根目录**开始，把示例里的 `my-project` 换成你的项目目录名。

**Windows 命令提示符（CMD）**

```cmd
export_all.bat
```

导出成功后，切换到 C++ 项目目录。确认进入项目目录后再运行安装命令。

```cmd
cd /d "..\my-project"
conan install . --no-remote --build=missing -of ./build
```

**macOS 和 Linux**

```sh
sh ./export_all.sh &&
  cd ../my-project &&
  conan install . --no-remote --build=missing -of ./build
```

- 两种导出脚本都从各库的 `conandata.yml` 读取已收录的版本并逐一导出。导出时校验仓库里的原始归档，再把配方和归档复制到 Conan 缓存。首次使用、更换缓存或更新依赖仓库后，重新运行导出脚本。
- `conan install .` 读取当前项目的 `conanfile.txt` 或 `conanfile.py`，按项目声明选择版本。`--no-remote` 让 Conan 只从本机缓存解析依赖，`--build=missing` 允许它从已导出的源码构建缺少的包。导出和安装用同一个 Conan Home。
- 安装时会重新校验 Conan 缓存中的原始压缩包，包括命中已构建的包时。`conandata.yml` 中的官方 URL 用于追溯归档来源。安装过程中使用随仓库分发的源码，GitLab 和 ConanCenter 可以保持断开。

Git 检出包含导出脚本、说明、配方和源码归档。根目录的 `examples/` 和 `profiles/` 是本机验证目录，下面的步骤使用你的项目和 Conan Home 中的 profile。

## 让 CMake 项目使用 Eigen

消费项目已有 `conanfile.txt` 时，把这些条目加入对应段落。

```ini
[requires]
eigen/5.0.1

[generators]
CMakeDeps
CMakeToolchain
```

消费项目使用 `conanfile.py` 时，可在现有配方中加入同等的依赖和生成器。最小配方如下。

```python
from conan import ConanFile


class ProjectDependencies(ConanFile):
    settings = "os", "arch", "compiler", "build_type"
    requires = "eigen/5.0.1"
    generators = "CMakeDeps", "CMakeToolchain"
```

在 `CMakeLists.txt` 中添加以下内容，将 `my_app` 换成项目里已经定义的目标。

```cmake
find_package(Eigen3 5.0.1 EXACT CONFIG REQUIRED)
target_compile_features(my_app PRIVATE cxx_std_14)
target_link_libraries(my_app PRIVATE Eigen3::Eigen)
```

代码中可以使用 `#include <Eigen/Dense>`。Eigen 是头文件库，`Eigen3::Eigen` 会向使用它的目标提供头文件路径。

以 Windows 上的 Visual Studio Release 构建为例，如果消费项目采用上述最小配方且没有自定义布局，安装成功后在 CMD 中运行以下命令。

```cmd
cmake --preset conan-default
cmake --build ./build --config Release
```

使用 Visual Studio 2026 的 CMake 生成器需要 CMake 4.2 或更新版本。macOS 和 Linux 上使用 Unix Makefiles 或 Ninja 时，若 profile 为 Release，Conan 默认生成 `conan-release` preset。

```sh
cmake --preset conan-release &&
  cmake --build --preset conan-release
```

如果项目定义了自己的布局或 preset，按 `conan install` 输出的配置和构建目录执行。

## 安装失败时

- **找不到配方或版本**。核对项目声明的版本与依赖仓库的 `conandata.yml`，并确认导出脚本已在当前 Conan Home 导出该版本。离线安装前要准备好全部依赖及其所需的构建工具。
- **导出时 SHA-256 不匹配**。从可信的 Git 提交恢复 `upstream/` 下的官方原始归档及校验文件，再执行导出。
- **安装时缓存归档损坏**。先确认工作区原件完整，再删除受影响版本的缓存。例如运行 `conan remove "eigen/5.0.1"` 并确认，随后重新导出和安装。这会移除该版本的已构建缓存包，下次安装时会重新构建。
