/**
 * Wrapper to provide UTF-8 support for lua and luac on Windows.
 *
 * Copyright (c) 2018 Peter Wu <peter@lekensteyn.nl>
 * SPDX-License-Identifier: (GPL-2.0-or-later OR MIT)
 */

#ifdef _WIN32
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

extern int main_utf8(int argc, char *argv[]);

int wmain(int argc, wchar_t *argv[]) {
    char **argv_utf8 = (char **)calloc(argc + 1, sizeof(char *));
    if (!argv_utf8) {
        fprintf(stderr, "cannot allocate memory for arguments\n");
        return EXIT_FAILURE;
    }
    for (int i = 0; i < argc; i++) {
        int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, argv[i], -1, NULL, 0, NULL, NULL);
        if (size == 0) {
            fprintf(stderr, "Invalid character in argument %d\n", i);
            return EXIT_FAILURE;
        }

        argv_utf8[i] = (char *)malloc(size);
        if (!argv_utf8[i]) {
            fprintf(stderr, "cannot allocate memory for argument %d\n", i);
            return EXIT_FAILURE;
        }
        if (!WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, argv[i], -1, argv_utf8[i], size, NULL, NULL)) {
            fprintf(stderr, "Invalid character in argument %d\n", i);
            return EXIT_FAILURE;
        }
    }
    int ret = main_utf8(argc, argv_utf8);
    for (int i = 0; i < argc; i++) {
        free(argv_utf8[i]);
    }
    free(argv_utf8);
    return ret;
}
#endif
