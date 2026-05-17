#include "lookup.h"
#include <stdio.h>
#include <stdint.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    FILE *File = fopen(argv[1], "rb");
    if (!File) {
        fprintf(stderr, "Error: Could not open file '%s'\n", argv[1]);
        return 1;
    }

    uint8_t Memory[65536][3];

    uint16_t Addr = 0;
    uint8_t Buf[3];
    while (fread(Buf, 1, 3, File) == 3) {
        Memory[Addr][0] = Buf[0];
        Memory[Addr][1] = Buf[1];
        Memory[Addr][2] = Buf[2];
        Addr++;
    }

    fclose(File);

    uint16_t PC = Memory[1];

    while (!(PC < 0 || PC > Memory[2])) {
        switch (Memory[PC][1] & 0b11111100) {
            case 0b00000000: // NOP
                break;
            case 0b00000100: // RST
                if (argc < 2) {
                    fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
                    return 1;
                }

                FILE *File = fopen(argv[1], "rb");
                if (!File) {
                    fprintf(stderr, "Error: Could not open file '%s'\n", argv[1]);
                    return 1;
                }

                Addr = 0;
                while (fread(Buf, 1, 3, File) == 3) {
                    Memory[Addr][0] = Buf[0];
                    Memory[Addr][1] = Buf[1];
                    Memory[Addr][2] = Buf[2];
                    Addr++;
                }
                PC = 512;

            // -- Load --
            case 0b00001000: // LDA
                break;
            case 0b00001100: // LDB
                break;
            case 0b00010000: // LDC
                break;
            case 0b00010100: // LDX
                break;
            case 0b00011000: // LDY
                break;

            // -- Store --
            case 0b00011100: // STA
                break;
            case 0b00100000: // STB
                break;
            case 0b00100100: // STC
                break;
            case 0b00101000: // STX
                break;
            case 0b00101100: // STY
                break;
            case 0b00110000: // STZ
                break;

            // -- Addition --
            case 0b00110100: // ADA
                break;
            case 0b00111000: // ADB
                break;
            case 0b00111100: // ADC
                break;
            case 0b01000000: // ADX
                break;
            case 0b01000100: // ADY
                break;

            // -- Subtraction --
            case 0b01001000: // SBA
                break;
            case 0b01001100: // SBB
                break;
            case 0b01010000: // SBC
                break;
            case 0b01010100: // SBX
                break;
            case 0b01011000: // SBY
                break;

            // -- Integer Division --
            case 0b01011100: // DVA
                break;
            case 0b01100000: // DVB
                break;
            case 0b01100100: // DVC
                break;
            case 0b01101000: // DVX
                break;
            case 0b01101100: // DVY
                break;

            // -- Modulus --
            case 0b01110000: // MDA
                break;
            case 0b01110100: // MDB
                break;
            case 0b01111000: // MDC
                break;
            case 0b01111100: // MDX
                break;
            case 0b10000000: // MDY
                break;

            // -- Multiplication --
            case 0b10000100: // MXA
                break;
            case 0b10001000: // MXB
                break;
            case 0b10001100: // MXC
                break;
            case 0b10010000: // MXX
                break;
            case 0b10010100: // MXY
                break;

            // -- Iteration --
            case 0b10011000: // CLI
                break;
            case 0b10011100: // ITR
                break;

            // -- Branching --
            case 0b10100000: // BIZ
                break;
            case 0b10100100: // BIO
                break;
            case 0b10101000: // JMP
                break;

            // -- Audio --
            case 0b10101100: // ADN
                break;
            case 0b10110000: // ADW
                break;

            // -- Extras --
            case 0b10110100: // LAC
                break;

            default:
                fprintf(stderr, "Unknown Opcode: 0x%02X At PC: %u\n", Memory[PC][1], PC);
                break;
        }
        PC++;
    }

    return 0;
}