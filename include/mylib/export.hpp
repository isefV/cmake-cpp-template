#pragma once

/**
 * @file export.hpp
 * @brief Symbol visibility macros for building and consuming mylib as a
 *        static or shared library.
 *
 * Build-system contract (see src/CMakeLists.txt):
 *
 * - MYLIB_SHARED            defined for the library and for every consumer
 *                           when mylib is built as a shared library;
 * - MYLIB_BUILDING_LIBRARY  defined only while compiling mylib itself.
 *
 * With a static library neither macro is defined and MYLIB_API expands to
 * nothing.
 */

#if defined(MYLIB_SHARED)
#if defined(_WIN32) || defined(__CYGWIN__)
#if defined(MYLIB_BUILDING_LIBRARY)
#define MYLIB_API __declspec(dllexport)
#else
#define MYLIB_API __declspec(dllimport)
#endif
#elif defined(__GNUC__) || defined(__clang__)
#define MYLIB_API __attribute__((visibility("default")))
#else
#define MYLIB_API
#endif
#else
#define MYLIB_API
#endif
