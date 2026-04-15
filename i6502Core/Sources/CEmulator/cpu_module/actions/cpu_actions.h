#ifndef __cpu_actions_h_
#define __cpu_actions_h_

#include "cpu_module.h"

/* MARK: - RESET actions */
void reset_t0(CpuState *state);
void reset_t1(CpuState *state);
void reset_t2(CpuState *state);
void reset_t3(CpuState *state);
void reset_t4(CpuState *state);
void reset_t5(CpuState *state);
void reset_t6(CpuState *state);

/* MARK: - IRQ actions */
void irq_t0(CpuState *state);
void irq_t1(CpuState *state);
void irq_t2(CpuState *state);
void irq_t3(CpuState *state);
void irq_t4(CpuState *state);
void irq_t5(CpuState *state);
void irq_t6(CpuState *state);

/* MARK: - NMI actions */
void nmi_t0(CpuState *state);
void nmi_t1(CpuState *state);
void nmi_t2(CpuState *state);
void nmi_t3(CpuState *state);
void nmi_t4(CpuState *state);
void nmi_t5(CpuState *state);
void nmi_t6(CpuState *state);

/* MARK: - immediate actions */
void imm_t0(CpuState *state);
void imm_adc_t1(CpuState *state);
void imm_sbc_t1(CpuState *state);
void imm_and_t1(CpuState *state);
void imm_ora_t1(CpuState *state);
void imm_eor_t1(CpuState *state);
void imm_cmp_t1(CpuState *state);
void imm_cpx_t1(CpuState *state);
void imm_cpy_t1(CpuState *state);
void imm_lda_t1(CpuState *state);
void imm_ldx_t1(CpuState *state);
void imm_ldy_t1(CpuState *state);

#endif /* __cpu_actions_h_ */
