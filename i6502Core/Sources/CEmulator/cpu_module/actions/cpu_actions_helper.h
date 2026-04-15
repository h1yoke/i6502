#ifndef __cpu_actions_helper_h_
#define __cpu_actions_helper_h_

#include "cpu_module.h"

#include <stdint.h>

/* PS register masks */
#define N_MASK 0b10000000 /* Negative flag */
#define V_MASK 0b01000000 /* Overflow flag */
#define S_MASK 0b00010000 /* Skip (unused) flag */
#define B_MASK 0b00010000 /* Break flag */
#define I_MASK 0b00000100 /* Interrupt disabled flag */
#define Z_MASK 0b00000010 /* Zero flag */
#define C_MASK 0b00000001 /* Carry flag */

/* Common functions */
void apply_adc(CpuState *state, uint8_t value);
void apply_sbc(CpuState *state, uint8_t value);
void apply_cmp(CpuState *state, uint8_t lhs, uint8_t rhs);
void apply_nz(CpuState *state, uint8_t value);

#endif /* __cpu_actions_helper_h_ */
