#include "cpu_module.h"
#include "actions/cpu_actions.h"
#include "actions/cpu_actions_utils.h"

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
        /* Accumulator mode operations */
        case 0x0A: return(CpuCycles){
            .actions = { acc_t0, acc_asl_t1 },
            .count = 2
        };
        case 0x4A: return(CpuCycles){
            .actions = { acc_t0, acc_lsr_t1 },
            .count = 2
        };
        case 0x2A: return(CpuCycles){
            .actions = { acc_t0, acc_rol_t1 },
            .count = 2
        };
        case 0x6A: return(CpuCycles){
            .actions = { acc_t0, acc_ror_t1 },
            .count = 2
        };
        /* Implied operations */
        case 0x18: return(CpuCycles){
            .actions = { imp_t0, imp_clc_t1 },
            .count = 2
        };
        case 0x38: return(CpuCycles){
            .actions = { imp_t0, imp_sec_t1 },
            .count = 2
        };
        case 0x58: return(CpuCycles){
            .actions = { imp_t0, imp_cli_t1 },
            .count = 2
        };
        case 0x78: return(CpuCycles){
            .actions = { imp_t0, imp_sei_t1 },
            .count = 2
        };
        case 0xB8: return(CpuCycles){
            .actions = { imp_t0, imp_clv_t1 },
            .count = 2
        };
        case 0xD8: return(CpuCycles){
            .actions = { imp_t0, imp_cld_t1 },
            .count = 2
        };
        case 0xF8: return(CpuCycles){
            .actions = { imp_t0, imp_sed_t1 },
            .count = 2
        };
        case 0xEA: return(CpuCycles){
            .actions = { imp_t0, imp_nop_t1 },
            .count = 2
        };
        case 0xAA: return(CpuCycles){
            .actions = { imp_t0, imp_tax_t1 },
            .count = 2
        };
        case 0x8A: return(CpuCycles){
            .actions = { imp_t0, imp_txa_t1 },
            .count = 2
        };
        case 0xCA: return(CpuCycles){
            .actions = { imp_t0, imp_dex_t1 },
            .count = 2
        };
        case 0xE8: return(CpuCycles){
            .actions = { imp_t0, imp_inx_t1 },
            .count = 2
        };
        case 0xA8: return(CpuCycles){
            .actions = { imp_t0, imp_tay_t1 },
            .count = 2
        };
        case 0x98: return(CpuCycles){
            .actions = { imp_t0, imp_tya_t1 },
            .count = 2
        };
        case 0x88: return(CpuCycles){
            .actions = { imp_t0, imp_dey_t1 },
            .count = 2
        };
        case 0xC8: return(CpuCycles){
            .actions = { imp_t0, imp_iny_t1 },
            .count = 2
        };
        case 0x40: return(CpuCycles){
            .actions = { imp_t0, imp_rti_t1, imp_rti_t2, imp_rti_t3, imp_rti_t4, imp_rti_t5 },
            .count = 6
        };
        case 0x60: return(CpuCycles){
            .actions = { imp_t0, imp_rts_t1, imp_rts_t2, imp_rts_t3, imp_rts_t4, imp_rts_t5 },
            .count = 6
        };
        case 0x9A: return(CpuCycles){
            .actions = { imp_t0, imp_txs_t1 },
            .count = 2
        };
        case 0xBA: return(CpuCycles){
            .actions = { imp_t0, imp_tsx_t1 },
            .count = 2
        };
        case 0x48: return(CpuCycles){
            .actions = { imp_t0, imp_pha_t1, imp_pha_t2 },
            .count = 3
        };
        case 0x68: return(CpuCycles){
            .actions = { imp_t0, imp_pla_t1, imp_pla_t2, imp_pla_t3, },
            .count = 4
        };
        case 0x08: return(CpuCycles){
            .actions = { imp_t0, imp_php_t1, imp_php_t2 },
            .count = 3
        };
        case 0x28: return(CpuCycles){
            .actions = { imp_t0, imp_plp_t1, imp_plp_t2, imp_plp_t3 },
            .count = 4
        };
        case 0x00: return(CpuCycles){
            .actions = { imp_t0, imp_brk_t1, imp_brk_t2, imp_brk_t3, imp_brk_t4, imp_brk_t5, imp_brk_t6 },
            .count = 7
        };
        /* TODO: rest modes */
    }
    return(CpuCycles){ .count = 0 };
}
