#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <libgen.h>
#include <mach-o/dyld.h>

int main(int argc, char *argv[]) {
    char exePath[4096];
    uint32_t size = sizeof(exePath);
    if (_NSGetExecutablePath(exePath, &size) != 0) return 1;

    char exeDir[4096];
    strncpy(exeDir, exePath, sizeof(exeDir) - 1);
    char *dir = dirname(exeDir);

    char helper[4096];
    snprintf(helper, sizeof(helper), "%s/continueSessionHelper", dir);

    execv(helper, argv);
    perror("execv failed");
    return 1;
}
