#include "emulator.h"
#include "emu_module.h"
#include "bus_module.h"
#include "cpu_module.h"

#include <stdint.h>
#include <stdlib.h>

/* MARK: - Emulator initializer & deinitializer */

EmulatorState * emu_create() {
    EmulatorState *state = malloc(sizeof(EmulatorState));
    state->bus = bus_create();
    state->cpu = cpu_create();

    state->cpu->bus = state->bus;

    state->cpu_cycles = (CpuCycles){ .count = 0 };
    state->cpu_cycles_index = 0;

    return state;
}

void emu_destroy(EmulatorState *state) {
    cpu_destroy(state->cpu);
    bus_destroy(state->bus);

    free(state);
}

/* MARK: - Emulator actions */

void emu_reset(EmulatorState *state) {
    cpu_reset(state->cpu);
}

void emu_cycle(EmulatorState *state) {
    if (state->cpu_cycles_index < state->cpu_cycles.count) {
        CpuAction cpu_action = state->cpu_cycles.actions[state->cpu_cycles_index];

        cpu_action(state->cpu);
    } else {
        /* TODO: nmi and irq goes here */

        state->cpu_cycles = cpu_decode(state->cpu);
        state->cpu_cycles_index = 0;
    }
}

/* MARK: - Emulator exposed logic */

uint8_t emu_read(EmulatorState *state, uint16_t address) {
    return bus_read(state->bus, address);
}

void emu_write(EmulatorState *state, uint16_t address, uint8_t value) {
    bus_write(state->bus, address, value);
}
