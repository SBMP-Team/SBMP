#ifndef LOOKUP_H
#define LOOKUP_H

#include <stdint.h>

uint8_t LookupOpcode(const char* Mnemonic);
const char* LookupMnemonic(uint8_t Opcode);

#endif