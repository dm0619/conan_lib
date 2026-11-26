from pathlib import Path

from conan import ConanFile
from conan.errors import ConanException
from conan.tools.build import check_min_cppstd
from conan.tools.files import check_sha256, copy, trim_conandata, unzip


class EigenConan(ConanFile):
    name = "eigen"
    homepage = "https://libeigen.gitlab.io/"
    license = "MPL-2.0"
    description = "C++ template library for linear algebra"
    package_type = "header-library"
    settings = "compiler"
    no_copy_source = True

    def set_version(self):
        self.version = self.version or self.conan_data["default_version"]

    def _verified_archive(self):
        sources = self.conan_data["sources"]
        version = str(self.version)
        if version not in sources:
            supported = ", ".join(sorted(sources))
            raise ConanException(f"Eigen version {version} is not listed in conandata.yml. Available: {supported}")
        source = sources[version]
        archive = Path(self.recipe_folder) / "upstream" / source["filename"]
        sha256 = source["sha256"]
        checksum = archive.with_name(archive.name + ".sha256")
        if checksum.read_text(encoding="ascii").split() != [sha256, archive.name]:
            raise ConanException(f"{checksum} does not match the pinned SHA-256 for {archive.name}")
        check_sha256(self, str(archive), sha256)
        self.output.info(f"Verified SHA-256 {sha256}  {archive}")
        return archive

    def export(self):
        archive = self._verified_archive()
        relative_path = archive.relative_to(self.recipe_folder).as_posix()
        # Recipe exports are available to validate() on binary cache hits.
        copy(self, relative_path, src=self.recipe_folder, dst=self.export_folder)
        copy(self, relative_path + ".sha256", src=self.recipe_folder, dst=self.export_folder)
        trim_conandata(self)

    def validate(self):
        self._verified_archive()
        if self.settings.compiler.get_safe("cppstd"):
            check_min_cppstd(self, "14")

    def package_id(self):
        self.info.clear()

    def package(self):
        upstream = Path(self.build_folder) / "eigen-src"
        archive = self._verified_archive()
        unzip(self, str(archive), str(upstream), strip_root=True)
        include = Path(self.package_folder) / "include" / "eigen3"
        for directory in ("Eigen", "unsupported/Eigen"):
            copy(self, "*", src=upstream / directory, dst=include / directory,
                 excludes=("CMakeLists.txt", "*/CMakeLists.txt"))
        copy(self, "signature_of_eigen3_matrix_library", src=upstream, dst=include, excludes=("*/*",))
        licenses = Path(self.package_folder) / "licenses"
        copy(self, "LICENSE", src=upstream, dst=licenses, excludes=("*/*",))
        copy(self, "COPYING.*", src=upstream, dst=licenses, excludes=("*/*",))

    def package_info(self):
        self.cpp_info.includedirs = ["include/eigen3"]
        self.cpp_info.bindirs = []
        self.cpp_info.libdirs = []
        self.cpp_info.set_property("cmake_file_name", "Eigen3")
        self.cpp_info.set_property("cmake_target_name", "Eigen3::Eigen")
