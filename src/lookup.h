#ifndef LOOKUP_H
#define LOOKUP_H
#define OPCODE_MASK   0xFC  // 11111100
#define UNUSED_MASK   0x02  // 00000010
#define TYPE_MASK     0x01  // 00000001

#include <stdint.h>

uint8_t LookupOpcode(const char* Mnemonic);
const char* LookupMnemonic(uint8_t Opcode);
uint16_t LookUpMemoryOffset(const char Mnemonic[1]);


#endif