#ifndef __emu_module_h_
#define __emu_module_h_

#include "cpu_module.h"
#include "bus_module.h"

/* Emulator state */
typedef struct EmuState {
    CpuState *cpu;
    BusState *bus;

    /* Cycles that are left to execute
       after last opcode dispatch */
    CpuCycles cpu_cycles;
    uint8_t cpu_cycles_index;
} EmuState;

#endif /* __emu_module_h_ */
