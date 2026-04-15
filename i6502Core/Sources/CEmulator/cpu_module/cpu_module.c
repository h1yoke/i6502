#include "cpu_module.h"
#include "actions/cpu_actions.h"
#include "actions/cpu_actions_helper.h"

#include <stdint.h>
#include <stdlib.h>

/* MARK: - 6502 initializer & deinitializer */

CpuState * cpu_create() {
    CpuState *state = malloc(sizeof(CpuState));
    state->register_pc = rand();
    state->register_sp = rand();
    state->register_ps = rand() | I_MASK;
    state->register_a = rand();
    state->register_x = rand();
    state->register_y = rand();
    return state;
}

void cpu_destroy(CpuState *cpu) {
    free(cpu);
}

/* MARK: - 6502 actions */

CpuCycles cpu_nmi(CpuState *state) {
    return (CpuCycles){
        .actions = { nmi_t0, nmi_t1, nmi_t2, nmi_t3, nmi_t4, nmi_t5, nmi_t6 },
        .count = 7
    };
}

CpuCycles cpu_reset(CpuState *state) {
    return (CpuCycles){
        .actions = { reset_t0, reset_t1, reset_t2, reset_t3, reset_t4, reset_t5, reset_t6 },
        .count = 7
    };
}

CpuCycles cpu_irq(CpuState *state) {
    return (CpuCycles){
        .actions = { irq_t0, irq_t1, irq_t2, irq_t3, irq_t4, irq_t5, irq_t6 },
        .count = 7
    };
}

CpuCycles cpu_decode(CpuState *state) {
    uint8_t opcode = bus_read(state->bus, state->register_pc);

    switch (opcode) {
        /* Immediate mode operations */
        case 0x69: return (CpuCycles){
            .actions = { imm_t0, imm_adc_t1 },
            .count = 2
        };
        case 0x29: return(CpuCycles){
            .actions = { imm_t0, imm_and_t1 },
            .count = 2
        };
        case 0x09: return(CpuCycles){
            .actions = { imm_t0, imm_ora_t1 },
            .count = 2
        };
        case 0x49: return(CpuCycles){
            .actions = { imm_t0, imm_eor_t1 },
            .count = 2
        };
        case 0xC9: return(CpuCycles){
            .actions = { imm_t0, imm_cmp_t1 },
            .count = 2
        };
        case 0xE0: return(CpuCycles){
            .actions = { imm_t0, imm_cpx_t1 },
            .count = 2
        };
        case 0xC0: return(CpuCycles){
            .actions = { imm_t0, imm_cpy_t1 },
            .count = 2
        };
        case 0xA9: return(CpuCycles){
            .actions = { imm_t0, imm_lda_t1 },
            .count = 2
        };
        case 0xA2: return(CpuCycles){
            .actions = { imm_t0, imm_ldx_t1 },
            .count = 2
        };
        case 0xA0: return(CpuCycles){
            .actions = { imm_t0, imm_ldy_t1 },
            .count = 2
        };
        /* TODO: rest modes */
    }
    return(CpuCycles){ .count = 0 };
}
