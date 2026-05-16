#include "lookup.h"
#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[]) {
    FILE *fptr = fopen(argv[1], "r");
    printf("SBMP Compiler\n");
    printf("");
    char buffer[100];
    if (fptr == NULL) {
        printf("Error opening file %s \n", argv[1]);
        return 1;
    }

    while (fgets(buffer, 100, fptr)) {
        // printf("%s", buffer);
        // printf("Finding optocdes\n");
        //remove leading and trailing spaces, as well as any comments.
        char *token = strtok(buffer, "::");
        size_t i = 0;
        while (token[i] == ' ') {
            i++;
        }
        size_t len = strlen(token);
        memmove(token, token + i, len - i + 1);
        printf("Token after removing: %s\n", token);
    }

    fclose(fptr);


    return 0;
}
