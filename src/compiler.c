#include "lookup.h"
#include "Constants.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void print_bits(uint8_t value) {
    for (int i = 7; i >= 0; i--) {
        printf("%d", (value >> i) & 1);
    }
}
void print_16_bits(uint16_t value) {
    for (int i = 15; i >= 0; i--) {
        printf("%d", (value >> i) & 1);
    }
}
void write_instruction(FILE *f, uint8_t opcode, uint16_t operand) {
    fputc(opcode, f);

    fputc(operand & 0xFF, f);       // low byte
    fputc((operand >> 8) & 0xFF, f); // high byte
}

int main(int argc, char* argv[]) {
    FILE *fptr = fopen(argv[1], "r");
    FILE *outfptr = fopen(argv[2], "wb");
    if (fptr == NULL) {
        printf("Error opening file %s \n", argv[1]);
        return 1;
    }
    if (outfptr == NULL) {
        printf("Error opening file %s \n", argv[2]);
        fclose(fptr);
    }


    char **lines = NULL;
    size_t lineCount = 0;

    char buffer[1024];

    while (fgets(buffer, sizeof(buffer), fptr)) {
        // Remove newline if present
        buffer[strcspn(buffer, "\n")] = '\0';

        // Resize array
        char **temp = realloc(lines, sizeof(char*) * (lineCount + 1));
        if (!temp) {
            perror("realloc failed");
            fclose(fptr);
            return 1;
        }

        lines = temp;

        // Allocate and copy line
        lines[lineCount] = malloc(strlen(buffer) + 1);
        strcpy(lines[lineCount], buffer);

        lineCount++;
    }

    fclose(fptr);

    OptcodePair* instructions = malloc(sizeof(OptcodePair) * lineCount);
    size_t instructionsCount = 0;
    // Example usage
    for (size_t i = 0; i < lineCount; i++) {
        char* line = lines[i];
        size_t len = strlen(line);
        size_t j = 0;

        char *token = strtok(line, "::");
        if (token == NULL) {
            continue;
        }
        while (token[j] == ' '){
            j++;
        }
        memmove(token, token + j, len - j + 1);
        j = strlen(token);
        while (j > 0 && token[j - 1] == ' ') {
            j--;
        }
        token[j] = '\0';

        if (token[0] != '\0') {
            char optcode[4];
            char data[9];
            printf("LINE %lu: %s\n", i, line);
            if (strcmp(token,"start") == 0) continue;
            sscanf(token, "%3s %8s", optcode, data);
            printf("OPTCODE: %s\n", optcode);
            printf("DATA: %s\n", data);
            instructionsCount++;

            OptcodePair* tmp = realloc(instructions,
                sizeof(OptcodePair) * instructionsCount);

            if (!tmp) {
                perror("realloc failed");
                goto error;
            }

            instructions = tmp;

            OptcodePair* opt = &instructions[instructionsCount - 1];
            opt->opcode = LookupOpcode(optcode);
            if (data[0] == '#') {
                if (data[1] == '$') {
                    // Interpret as binary data, remove the last first two characters and continue
                    const char *bin = data + 2;
                    uint16_t value = 0;
                    for (int k = 0; bin[k]; k++) {

                        value <<=1;
                        if (bin[k] =='1') value |=1;
                        else if (bin[k] !='0'){
                            printf("Error decoding binary data, unexpected character %c", bin[k]);
                            goto error;
                        }
                    }
                    opt->operand = value;
                    opt->opcode =opt->opcode | 0x01;
                }
                else {
                    //interpret as HEX
                    opt->operand = (uint16_t) strtol(data+1, NULL,0);
                    opt->opcode = opt->opcode| 0x01;
                }
            }
            if (data[0] == '$') {
                if (data[1] == '#') {
                    const char *bin = data + 2;
                    uint16_t value = 0;
                    for (int k = 0; bin[k]; k++) {

                        value <<=1;
                        if (bin[k] =='1') value |=1;
                        else if (bin[k] !='0'){
                            printf("Error decoding binary data, unexpected character %c", bin[k]);
                            goto error;
                        }
                    }
                    opt->operand = value;
                    opt->opcode =opt->opcode | 0x01;
                }
                else {
                    //assume register
                    if (data[1]!='0' && data[2]!='x') {
                        printf("Assuming register letter, parsing...\n");
                        uint16_t memoryOffset = LookUpMemoryOffset(&data[1]);
                        opt->operand = memoryOffset;
                    }
                    else {
                        opt->operand = (uint16_t) strtol(data+1, NULL,0);

                    }
                }
            }
        }


    }
    for (size_t i = 0; i < instructionsCount; i++) {
        OptcodePair *ins = &instructions[i];

        printf("OPCODE: ");
        print_bits(ins->opcode);
        printf("\n");
        printf("OPERAND:");
        print_16_bits(ins->operand);
        printf("\n");

        write_instruction(outfptr, ins->opcode, ins->operand);

    }
    fclose(outfptr);

    // Cleanup
    for (size_t i = 0; i < lineCount; i++) {
        free(lines[i]);
    }

    free(lines);
    free(instructions);
    fclose(fptr);
    return 0;
error:
for (size_t i = 0; i < lineCount; i++) {
    free(lines[i]);
}
    free(lines);
    free(instructions);
    fclose(fptr);
    return 1;
}

