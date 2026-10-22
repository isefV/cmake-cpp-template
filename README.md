# mylib

**mylib** is a C++20 library. *(Replace this line with what your library
does.)*

It builds as a **static or shared library**, on Windows and Linux, and can be
used from another CMake project through `find_package` or as part of it
(`add_subdirectory`, git submodule, `FetchContent`), including debugging into
its sources.

- Building, internals and contributing: [docs/README-Guideline.md](docs/README-Guideline.md)
- History of changes: [docs/README-Catalog.md](docs/README-Catalog.md)

```
mylib/
├── CMakeLists.txt       options, dependencies, library, install, tests, apps, docs
├── cmake/               one Find<Name>.cmake per dependency (GoogleTest, Boost, ImGui, ... see 6.), install rules
├── include/mylib/       public headers
├── src/                 the library's sources
├── apps/                example programs: app (mylib alone), one per library in cmake/ (options MYLIB_BUILD_APP_*)
├── tests/               GoogleTest tests (CTest)
├── docs/                README-Guideline.md, README-Catalog.md, Doxygen (MYLIB_BUILD_DOCS)
├── extern/              dependencies cloned by FetchContent (not in git)
├── README.md  LICENSE.md
└── .vscode/             tasks (build, clean, install) and their choices (build.json), launch configurations, settings
```

---

## 1. Start a new project from this template

1. Copy this folder (without `build/`, `install/` and the contents of
   `extern/`) and name it after your project.
2. Replace the name `mylib` / `MYLIB` everywhere, in file contents and in file
   and folder names. From the new folder, with your name in `$new`:

   **Windows (PowerShell):**

   ```powershell
   $old = 'mylib'; $new = 'myproject'
   Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\(build|install|extern|\.git)(\\|$)' } | ForEach-Object {
       $text = [IO.File]::ReadAllText($_.FullName)
       $renamed = $text -creplace $old, $new -creplace $old.ToUpper(), $new.ToUpper()
       if ($renamed -ne $text) { [IO.File]::WriteAllText($_.FullName, $renamed) }
   }
   Get-ChildItem -Recurse | Where-Object { $_.Name -cmatch $old } | Sort-Object { $_.FullName.Length } -Descending |
       Rename-Item -NewName { $_.Name -creplace $old, $new }
   ```

   **Linux (bash):**

   ```bash
   old=mylib new=myproject
   grep -rlI --exclude-dir={build,install,extern,.git} -e "$old" -e "${old^^}" . |
       xargs sed -i "s/$old/$new/g; s/${old^^}/${new^^}/g"
   find . -depth -name "*$old*" -not -path './build*' -not -path './extern/*' |
       while read -r p; do mv "$p" "$(dirname "$p")/$(basename "$p" | sed "s/$old/$new/g")"; done
   ```

3. Replace the example code in `include/<name>/<name>.hpp`, `src/` and
   `tests/`, set the description in `CMakeLists.txt` and this README, and
   choose a license in `LICENSE.md`.

## 2. Requirements

| | |
|---|---|
| C++ | C++20 |
| Compiler | MSVC (Visual Studio 2022/2026), GCC or Clang with C++20 support |
| CMake | 3.21 or newer |
| OS | Windows and Linux |
| Dependencies | Threads (system); GoogleTest for the tests, cloned with git into `extern/googletest` unless `GOOGLETEST_ROOT_DIR` names one you have (see [6. Dependencies](#6-dependencies)). The example apps' libraries only when their option is on |
| VS Code | Extensions C/C++ (`ms-vscode.cpptools`) and Command Variable (`rioj7.command-variable`, for the tasks); both offered by `.vscode/extensions.json` |

## 3. Build, test, install

In VS Code every step is a task: *Terminal › Run Task › CMake: ...*
(Ctrl+Shift+B = `CMake: build`). The tasks are plain `cmake` command lines;
they take their choices from [.vscode/build.json](.vscode/build.json), with
the [Command Variable](https://marketplace.visualstudio.com/items?itemName=rioj7.command-variable)
extension (`rioj7.command-variable`, offered by `.vscode/extensions.json`).
On Windows they load the Visual Studio developer environment themselves.

| Task | Asks | Does |
|---|---|---|
| `CMake: build` | target › build type › kit › linkage | configure `build/<kit>-<build type>-<linkage>`, build the target, point `build/current` at that folder |
| `CMake: clean` | build type › kit › linkage | delete that build folder |
| `CMake: install` | build type › kit › linkage | build the install target (the library) and install it to `install/<kit>-<linkage>` |

`.vscode/build.json` has one section per question: `targets`, `buildTypes`,
`kits`, `linkages`, each with its `items` and a `default` (offered first), and
`install.target`. An item's `cmake` is added to the configure command line:
a kit's compiler and generator, a linkage's `BUILD_SHARED_LIBS`, an app's
`MYLIB_BUILD_APP_*` option. tasks.json names nothing of this project, so the
three files (`tasks.json`, `build.json`, `extensions.json`) work in another
CMake project once `build.json` lists its targets.

An app target turns its option on in the build folder (its first build clones
its library into `extern/`). The linkage `shared` sets `BUILD_SHARED_LIBS=ON`:
mylib and the fetched libraries are built shared.

`build/current` is the folder built last: `.vscode/launch.json` has an entry
for every program (`App: ...`, `Tests: ...`) and starts it from that folder's
`bin/`. IntelliSense (`.vscode/settings.json`) reads its
`compile_commands.json`, and has the include paths of the project and of the
libraries in `extern/` for any other file.

The same in a terminal (Windows: a *Developer PowerShell for VS*):

```bash
cmake -S . -B build/msvc-Debug-static -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -DBUILD_SHARED_LIBS=OFF
cmake --build build/msvc-Debug-static                                   # library, tests, apps
ctest --test-dir build/msvc-Debug-static                                # tests
cmake --install build/msvc-Debug-static --prefix install/msvc-static   # package
```

Install Debug **and** Release into the same prefix; a consuming project then
picks the matching one. Static and shared go to different prefixes.

```
install/msvc-static/
├── include/mylib/...          public headers
├── lib/mylib.lib, mylibd.lib  libraries (shared: import libraries, plus bin/*.dll and bin/mylibd.pdb)
├── src/...                    library sources, for debugging into it (Debug install)
└── lib/cmake/mylib/           the CMake package: find_package(mylib)
```

## 4. Usage as a library

### A. As an installed package (`find_package`)

```cmake
cmake_minimum_required(VERSION 3.21)
project(my_app LANGUAGES CXX)

find_package(mylib CONFIG REQUIRED)
add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE mylib::mylib)

# Shared library on Windows: copy the DLLs next to the executable. (On Linux
# the program finds libmylib.so through the RPATH that CMake sets.)
if(WIN32 AND mylib_SHARED)
    add_custom_command(TARGET my_app POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory "${mylib_RUNTIME_DIR}" "$<TARGET_FILE_DIR:my_app>")
endif()
```

Configure with `-DCMAKE_PREFIX_PATH=<package folder>`. Debug builds link
`mylibd`, Release builds `mylib`.

**Debugging into the library.** The library's debug info names its sources
`\mylib\src\...` (GCC: `/mylib/src/...`) on every PC, and a Debug package
ships them in `src/`. Map that root to the package folder once:

```json
"sourceFileMap": { "\\mylib": "C:/libs/mylib" }
```

(GDB: `"/mylib"` as the key, or `set substitute-path /mylib C:/libs/mylib`.)
Then F11 on a mylib call opens the package's copy of the source.

### B. From the sources

```cmake
add_subdirectory(third_party/mylib)                    # a copy or git submodule
# or:
include(FetchContent)
FetchContent_Declare(mylib GIT_REPOSITORY <url> GIT_TAG <tag>)   # or SOURCE_DIR <folder>
FetchContent_MakeAvailable(mylib)

target_link_libraries(my_app PRIVATE mylib::mylib)
```

As part of another project only the library is built: tests, apps and
install rules are off (turn them on with `MYLIB_BUILD_TESTS`,
`MYLIB_BUILD_APPS`, `MYLIB_INSTALL`). [apps/consumer](apps/consumer) is a
complete consumer that builds both ways.

## 5. Build options

| CMake option | Default | Meaning |
|---|---|---|
| `MYLIB_BUILD_SHARED` | `OFF` (follows `BUILD_SHARED_LIBS`) | Shared instead of static library |
| `MYLIB_BUILD_TESTS` | `ON` when top-level | Tests |
| `MYLIB_BUILD_APPS` | `ON` when top-level | Programs in `apps/` |
| `MYLIB_BUILD_DOCS` | `OFF` | Target `docs` (Doxygen) |
| `MYLIB_INSTALL` | `ON` when top-level | Install rules and the CMake package |

With `MYLIB_BUILD_APPS`, each example below has its own option, `OFF` by
default: the first configure with one `ON` clones its library into `extern/`.
Each uses mylib together with that library; the command-line ones check their
result and are registered with CTest (`MYLIB_BUILD_TESTS`). The window ones
take `--frames <n>` to close after n frames.

| CMake option | Program (`apps/<folder>`) | Shows |
|---|---|---|
| `MYLIB_BUILD_APP_BOOST` | `mylib_boost` (`boost`) | Boost.ProgramOptions: `--from 1 --to 10` |
| `MYLIB_BUILD_APP_NLOHMANN_JSON` | `mylib_nlohmann_json` | Writing and reading JSON |
| `MYLIB_BUILD_APP_SML` | `mylib_sml` | A Boost.SML state machine (turnstile) |
| `MYLIB_BUILD_APP_TASKFLOW` | `mylib_taskflow` | Tasks that run in parallel, then combine |
| `MYLIB_BUILD_APP_ZEROMQ` | `mylib_zeromq` | libzmq C API: request and reply between threads |
| `MYLIB_BUILD_APP_CPPZMQ` | `mylib_cppzmq` | cppzmq: publish and subscribe with topics |
| `MYLIB_BUILD_APP_ARMADILLO` | `mylib_armadillo` | Matrices and vectors |
| `MYLIB_BUILD_APP_GOOGLETEST` | `mylib_googletest` | Fixtures, parameterized tests, GoogleMock matchers |
| `MYLIB_BUILD_APP_RAYLIB` | `mylib_raylib` | A window with a bouncing ball |
| `MYLIB_BUILD_APP_IMGUI` | `mylib_imgui` | A Dear ImGui window (GLFW, OpenGL 3) |
| `MYLIB_BUILD_APP_IMPLOT` | `mylib_implot` | A live ImPlot plot (GLFW, OpenGL 3) |

```powershell
cmake -S . -B build/apps -DMYLIB_BUILD_APP_IMGUI=ON -DMYLIB_BUILD_APP_TASKFLOW=ON
```

The variables of the dependencies (`GOOGLETEST_ROOT_DIR`, ...) belong to their
find modules, not to mylib: see the next section.

## 6. Dependencies

Every dependency of the library is found with `find_package(<Name>)` in the
top-level `CMakeLists.txt`; an example in `apps/` finds its own library in its
`CMakeLists.txt`. Each library gets one file, `cmake/Find<Name>.cmake`;
[cmake/FindGoogleTest.cmake](cmake/FindGoogleTest.cmake) is the example to
copy.

| Variable of `FindGoogleTest.cmake` | Default | Meaning |
|---|---|---|
| `GOOGLETEST_ROOT_DIR` | the environment variable of that name | A GoogleTest you have: an install prefix or a source tree |
| `GOOGLETEST_GIT_REPOSITORY` | `https://github.com/google/googletest.git` | Repository to clone when there is none |
| `GOOGLETEST_GIT_TAG` | `v1.18.0` | Tag or branch to clone |
| `GOOGLETEST_SOURCE_DIR` | `extern/googletest` | Where the clone goes |

Ready to use in `cmake/` (each file's header lists its variables and
options). Every one has the same four variables with its own prefix:
`<PREFIX>_ROOT_DIR`, `<PREFIX>_GIT_REPOSITORY`, `<PREFIX>_GIT_TAG`,
`<PREFIX>_SOURCE_DIR`.

| `find_package(...)` | Targets | Prefix | Default tag | Notes |
|---|---|---|---|---|
| `GoogleTest` | `GTest::gtest_main`, `GTest::gmock`, ... | `GOOGLETEST_` | `v1.18.0` | |
| `Boost COMPONENTS <libs>` | `Boost::headers`, `Boost::<lib>` | `BOOST_` | `boost-1.92.0` | git submodules; `BOOST_GIT_SUBMODULES` limits them |
| `nlohmann_json` | `nlohmann_json::nlohmann_json` | `NLOHMANN_JSON_` | `v3.12.0` | header-only |
| `sml` | `sml::sml` | `SML_` | `v1.2.0` | Boost.SML, header-only, needs no Boost |
| `Taskflow` | `Taskflow::Taskflow` | `TASKFLOW_` | `v4.1.0` | header-only |
| `raylib` | `raylib` | `RAYLIB_` | `6.2` | Linux: X11 development packages |
| `ZeroMQ` | `libzmq`, `libzmq-static` | `ZEROMQ_` | `v4.3.5` | libzmq, the C API |
| `cppzmq` | `cppzmq`, `cppzmq-static` | `CPPZMQ_` | `v4.11.0` | C++ API; finds `ZeroMQ` itself |
| `Armadillo` | `armadillo` | `ARMADILLO_` | `15.6.2` | uses BLAS/LAPACK when found; git on gitlab.com (where that can't be reached, a mirror in `ARMADILLO_GIT_REPOSITORY`) |
| `glfw3` | `glfw` | `GLFW3_` | `3.5.1` | windows for OpenGL; raylib uses it when both are in one project; Linux: X11 and Wayland development packages |
| `imgui` | `imgui::imgui` | `IMGUI_` | `v1.93.0` | made by the file; `IMGUI_BACKENDS` adds backends |
| `implot` | `implot::implot` | `IMPLOT_` | `v1.0` | made by the file; finds `imgui` itself |

The `<Name>` is the library's own package name, so `find_package()` and the
targets are the same whether the library is fetched or installed.

Rules for a `cmake/Find<Name>.cmake`:

1. **A find module per library.** The file is named `Find<Name>.cmake` and is
   used through `find_package(<Name>)`, never through `include()`. It ends
   with `find_package_handle_standard_args(<Name> ...)`, so `REQUIRED`,
   `QUIET` and a requested version work as for any other package.
2. **The library's own prefix.** Its variables start with the library's name
   in upper case: `GOOGLETEST_ROOT_DIR`, `GOOGLETEST_GIT_TAG`. Never `MYLIB_*`.
3. **Standalone.** The file uses no variable or option of this project (no
   `MYLIB_*`, no `PROJECT_SOURCE_DIR`); paths are relative to the file itself
   (`CMAKE_CURRENT_LIST_DIR`). Copied into another project's `cmake/` folder
   it works unchanged.
4. **`<NAME>_ROOT_DIR` first.** When that variable (cache, calling project or
   environment) names a folder holding the library, it is used from there.
   Otherwise the library is fetched; a `<NAME>_ROOT_DIR` that holds no such
   library gives a warning and is fetched as well.
5. **Fetched from its git repository into `extern/`.** `FetchContent` with
   `GIT_REPOSITORY` and `GIT_TAG` (a tag or branch: the clone is shallow)
   clones the library once into
   `extern/<name>`; later configures, in any build folder, use that copy.
   Delete `extern/<name>` to fetch again, for example after changing the tag.
6. **Standalone messages.** Messages start with the library's name
   (`GoogleTest: ...`) and name only the library's own variables, nothing of
   this project.
7. **Any git server.** `<NAME>_GIT_REPOSITORY` may name a mirror, also an
   offline one. The clone takes no submodules (`GIT_SUBMODULES ""`), except
   Boost's, whose relative URLs (`../config.git`) resolve on the same server.
8. **The library's settings stay local.** Settings for the library's own
   CMake (no tests, no examples) are normal variables set just before
   `FetchContent_MakeAvailable` and unset after it, never cache entries of the
   calling project.

A dependency of the installed library (a `PUBLIC` one, or any library a static
mylib links) is also found again by `cmake/mylibConfig.cmake.in` with
`find_dependency(<Name>)`; its `Find<Name>.cmake`, if it has one, is installed
next to the package (`cmake/mylib_install.cmake`). GoogleTest is used by the
tests only and needs neither.
