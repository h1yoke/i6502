#include "cpu_actions.h"
#include "cpu_actions_utils.h"
#include "cpu_module.h"
#include "bus_module.h"

#include <stdint.h>

void acc_t0(CpuState *state) {
    state->register_pc++;
}

void acc_asl_t1(CpuState *state) {
    uint8_t prev_value = state->register_a;

    (void)bus_read(state->bus, state->register_pc);

    state->register_a <<= 1;
    state->register_ps = (state->register_ps & ~C_MASK) | (prev_value & 0b10000000 ? C_MASK : 0);
    apply_nz(state, state->register_a);
}

void acc_lsr_t1(CpuState *state) {
    uint8_t prev_value = state->register_a;

    (void)bus_read(state->bus, state->register_pc);

    state->register_a >>= 1;
    state->register_ps = (state->register_ps & ~C_MASK) | (prev_value & C_MASK);
    apply_nz(state, state->register_a);
}

void acc_rol_t1(CpuState *state) {
    uint8_t prev_value = state->register_a;

    (void)bus_read(state->bus, state->register_pc);
    // carry shifts into pos 0, pos 7 shift to carry
    state->register_a = (state->register_a << 1) | (state->register_ps & C_MASK);
    state->register_ps = (state->register_ps & ~C_MASK) | (prev_value & 0b10000000 ? C_MASK : 0);
    apply_nz(state, state->register_a);
}

void acc_ror_t1(CpuState *state) {
    uint8_t prev_value = state->register_a;

    (void)bus_read(state->bus, state->register_pc);
    // carry shifts into pos 7, pos 0 shift to carry
    state->register_a = (state->register_a >> 1) | (state->register_ps & C_MASK ? 0b10000000 : 0);
    state->register_ps = (state->register_ps & ~C_MASK) | (prev_value & C_MASK);
    apply_nz(state, state->register_a);
}
