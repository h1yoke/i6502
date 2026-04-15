#include "cpu_actions_utils.h"
#include "cpu_module.h"

#include <stdint.h>

void apply_adc(CpuState *state, uint8_t operand) {
    uint8_t carry = state->register_ps & C_MASK;
    uint16_t sum = (uint16_t)state->register_a + operand + carry;
    uint8_t overflow = (state->register_a ^ sum) & (operand ^ sum) & N_MASK;

    state->register_a = (uint8_t)sum;

    state->register_ps = (state->register_ps & ~(N_MASK | V_MASK | Z_MASK | C_MASK))
        | ((sum >> 8) & C_MASK)
        | ((state->register_a == 0) ? Z_MASK : 0)
        | (overflow ? V_MASK : 0)
        | (state->register_a & N_MASK);
}

void apply_sbc(CpuState *state, uint8_t operand) {}

void apply_cmp(CpuState *state, uint8_t lhs, uint8_t rhs) {
    uint16_t result = (uint16_t)lhs - rhs;

    state->register_ps = (state->register_ps & ~(N_MASK | Z_MASK | C_MASK))
        | ((uint8_t)result & N_MASK)
        | ((uint8_t)result == 0 ? Z_MASK : 0)
        | (lhs >= rhs ? C_MASK : 0);
}

void apply_nz(CpuState *state, uint8_t value) {
    state->register_ps = (state->register_ps & ~(N_MASK | Z_MASK))
        | (value & N_MASK)
        | (value == 0 ? Z_MASK : 0);
}
