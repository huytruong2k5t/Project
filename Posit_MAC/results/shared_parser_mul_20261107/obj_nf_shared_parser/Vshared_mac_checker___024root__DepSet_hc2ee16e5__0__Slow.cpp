// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vshared_mac_checker.h for the primary calling header

#include "Vshared_mac_checker__pch.h"
#include "Vshared_mac_checker___024root.h"

VL_ATTR_COLD void Vshared_mac_checker___024root___eval_static(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_static\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vshared_mac_checker___024root___eval_final(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_final\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__stl(Vshared_mac_checker___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vshared_mac_checker___024root___eval_phase__stl(Vshared_mac_checker___024root* vlSelf);

VL_ATTR_COLD void Vshared_mac_checker___024root___eval_settle(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_settle\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vshared_mac_checker___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../../../tb/shared_mac_checker.sv", 7, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vshared_mac_checker___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__stl(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___dump_triggers__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vshared_mac_checker___024root___stl_sequent__TOP__0(Vshared_mac_checker___024root* vlSelf);

VL_ATTR_COLD void Vshared_mac_checker___024root___eval_stl(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vshared_mac_checker___024root___stl_sequent__TOP__0(vlSelf);
    }
}

extern const VlUnpacked<CData/*2:0*/, 1024> Vshared_mac_checker__ConstPool__TABLE_had6e93ec_0;
extern const VlUnpacked<CData/*4:0*/, 1024> Vshared_mac_checker__ConstPool__TABLE_h5d6c9829_0;

VL_ATTR_COLD void Vshared_mac_checker___024root___stl_sequent__TOP__0(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___stl_sequent__TOP__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    SData/*10:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__ = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage1 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage2 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage3 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage4;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage4 = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__ = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage1 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage2 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage3 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage4;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage4 = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__ = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage1 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage2 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage3 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage4;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage4 = 0;
    CData/*3:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_count;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_count = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid = 0;
    CData/*4:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__scale_sum;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__scale_sum = 0;
    SData/*15:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__7__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__7__KET__ = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__5__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__5__KET__ = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__3__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__3__KET__ = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__1__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__1__KET__ = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__3__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__3__KET__ = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__1__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__1__KET__ = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0283__029__BRA__1__KET__;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0283__029__BRA__1__KET__ = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0281__029;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0281__029 = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0282__029;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0282__029 = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0283__029;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0283__029 = 0;
    IData/*25:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage0;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage0 = 0;
    IData/*25:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage1 = 0;
    IData/*25:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage2 = 0;
    CData/*4:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0 = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1 = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2 = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3 = 0;
    CData/*4:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt = 0;
    IData/*30:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage1 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage2 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage3 = 0;
    IData/*28:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage4;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage4 = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_0;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_0 = 0;
    SData/*11:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_1 = 0;
    IData/*30:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__shifted_full;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__shifted_full = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__raw_tail;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__raw_tail = 0;
    IData/*30:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage0;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage0 = 0;
    IData/*30:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage1 = 0;
    IData/*30:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage2 = 0;
    IData/*30:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage3 = 0;
    CData/*0:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s4_lod__DOT__lost_carry;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s4_lod__DOT__lost_carry = 0;
    IData/*29:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage0;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage0 = 0;
    IData/*29:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage1 = 0;
    IData/*29:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage2 = 0;
    IData/*29:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage3 = 0;
    CData/*4:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0 = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1 = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2 = 0;
    QData/*58:0*/ shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3 = 0;
    IData/*29:0*/ __VdfgRegularize_hd87f99a1_1_0;
    __VdfgRegularize_hd87f99a1_1_0 = 0;
    IData/*29:0*/ __VdfgRegularize_hd87f99a1_2_0;
    __VdfgRegularize_hd87f99a1_2_0 = 0;
    IData/*29:0*/ __VdfgRegularize_hd87f99a1_3_0;
    __VdfgRegularize_hd87f99a1_3_0 = 0;
    CData/*3:0*/ __VdfgRegularize_hd87f99a1_7_0;
    __VdfgRegularize_hd87f99a1_7_0 = 0;
    CData/*2:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__Vfuncout = 0;
    CData/*5:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v = 0;
    CData/*2:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__Vfuncout = 0;
    CData/*5:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v = 0;
    CData/*2:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__Vfuncout = 0;
    CData/*5:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v = 0;
    CData/*2:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__Vfuncout = 0;
    CData/*5:0*/ __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v = 0;
    SData/*9:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    SData/*9:0*/ __Vtableidx2;
    __Vtableidx2 = 0;
    // Body
    vlSelfRef.core_done = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__done_q;
    vlSelfRef.core_magnitude = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q;
    vlSelfRef.core_iterations = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__iterations_done_q;
    vlSelfRef.core_cut = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q;
    vlSelfRef.core_input_cut = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_cut;
    vlSelfRef.core_sign = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sign;
    vlSelfRef.core_scale = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf;
    vlSelfRef.commit_valid = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_valid;
    vlSelfRef.commit_first = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_first;
    vlSelfRef.commit_last = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_last;
    vlSelfRef.commit_iteration = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_iteration;
    vlSelfRef.d = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__d_q;
    vlSelfRef.flags = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_q;
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__next_count 
        = (0xfU & ((IData)(1U) + (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_zero 
        = (1U & ((~ (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q 
                     >> 0x1fU)) & (~ (IData)((0U != 
                                              (0x7fffffffU 
                                               & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_nar 
        = ((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q 
            >> 0x1fU) & (~ (IData)((0U != (0x7fffffffU 
                                           & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q)))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sf_inc_d 
        = (0x7ffU & ((IData)(1U) + (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sf_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_d 
        = (0U != vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q);
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_sf 
        = (0x7ffU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_sf_q) 
                     + (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_sf_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__regime 
        = (0x3fU & (~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q) 
                       ^ (- (IData)((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_first_regime_bit_q))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__regime 
        = (0x3fU & (~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q) 
                       ^ (- (IData)((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_first_regime_bit_q))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__regime 
        = (0x3fU & (~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q) 
                       ^ (- (IData)((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_first_regime_bit_q))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_d 
        = (0x7fffffffU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sub_q)
                           ? ((0x20000000U | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_x_frac_q 
                                              << 3U)) 
                              - vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_q)
                           : ((0x20000000U | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_x_frac_q 
                                              << 3U)) 
                              + vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_d 
        = (((((((((0x40000000U == (0x40000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)) 
                  | (0x20000000U == (0x60000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                 | (0x10000000U == (0x70000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                | (0x8000000U == (0x78000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
               | (0x4000000U == (0x7c000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
              | (0x2000000U == (0x7e000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
             | (0x1000000U == (0x7f000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
            | (0x800000U == (0x7f800000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)))
            ? ((0x40000000U == (0x40000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                ? 0U : ((0x20000000U == (0x60000000U 
                                         & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                         ? 1U : ((0x10000000U == (0x70000000U 
                                                  & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                  ? 2U : ((0x8000000U 
                                           == (0x78000000U 
                                               & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                           ? 3U : (
                                                   (0x4000000U 
                                                    == 
                                                    (0x7c000000U 
                                                     & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                    ? 4U
                                                    : 
                                                   ((0x2000000U 
                                                     == 
                                                     (0x7e000000U 
                                                      & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                     ? 5U
                                                     : 
                                                    ((0x1000000U 
                                                      == 
                                                      (0x7f000000U 
                                                       & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                      ? 6U
                                                      : 7U)))))))
            : (((((((((0x400000U == (0x7fc00000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)) 
                      | (0x200000U == (0x7fe00000U 
                                       & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                     | (0x100000U == (0x7ff00000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                    | (0x80000U == (0x7ff80000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                   | (0x40000U == (0x7ffc0000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                  | (0x20000U == (0x7ffe0000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                 | (0x10000U == (0x7fff0000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                | (0x8000U == (0x7fff8000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)))
                ? ((0x400000U == (0x7fc00000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                    ? 8U : ((0x200000U == (0x7fe00000U 
                                           & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                             ? 9U : ((0x100000U == 
                                      (0x7ff00000U 
                                       & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                      ? 0xaU : ((0x80000U 
                                                 == 
                                                 (0x7ff80000U 
                                                  & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                 ? 0xbU
                                                 : 
                                                ((0x40000U 
                                                  == 
                                                  (0x7ffc0000U 
                                                   & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                  ? 0xcU
                                                  : 
                                                 ((0x20000U 
                                                   == 
                                                   (0x7ffe0000U 
                                                    & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                   ? 0xdU
                                                   : 
                                                  ((0x10000U 
                                                    == 
                                                    (0x7fff0000U 
                                                     & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                    ? 0xeU
                                                    : 0xfU)))))))
                : (((((((((0x4000U == (0x7fffc000U 
                                       & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)) 
                          | (0x2000U == (0x7fffe000U 
                                         & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                         | (0x1000U == (0x7ffff000U 
                                        & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                        | (0x800U == (0x7ffff800U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                       | (0x400U == (0x7ffffc00U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                      | (0x200U == (0x7ffffe00U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                     | (0x100U == (0x7fffff00U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))) 
                    | (0x80U == (0x7fffff80U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)))
                    ? ((0x4000U == (0x7fffc000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                        ? 0x10U : ((0x2000U == (0x7fffe000U 
                                                & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                    ? 0x11U : ((0x1000U 
                                                == 
                                                (0x7ffff000U 
                                                 & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                ? 0x12U
                                                : (
                                                   (0x800U 
                                                    == 
                                                    (0x7ffff800U 
                                                     & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                    ? 0x13U
                                                    : 
                                                   ((0x400U 
                                                     == 
                                                     (0x7ffffc00U 
                                                      & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                     ? 0x14U
                                                     : 
                                                    ((0x200U 
                                                      == 
                                                      (0x7ffffe00U 
                                                       & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                      ? 0x15U
                                                      : 
                                                     ((0x100U 
                                                       == 
                                                       (0x7fffff00U 
                                                        & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                       ? 0x16U
                                                       : 0x17U)))))))
                    : ((0x40U == (0x7fffffc0U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                        ? 0x18U : ((0x20U == (0x7fffffe0U 
                                              & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                    ? 0x19U : ((0x10U 
                                                == 
                                                (0x7ffffff0U 
                                                 & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                ? 0x1aU
                                                : (
                                                   (8U 
                                                    == 
                                                    (0x7ffffff8U 
                                                     & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                    ? 0x1bU
                                                    : 
                                                   ((4U 
                                                     == 
                                                     (0x7ffffffcU 
                                                      & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                     ? 0x1cU
                                                     : 
                                                    ((2U 
                                                      == 
                                                      (0x7ffffffeU 
                                                       & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q))
                                                      ? 0x1dU
                                                      : 
                                                     ((1U 
                                                       == vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)
                                                       ? 0x1eU
                                                       : 0U))))))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_q;
    if ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q))) {
        if ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d = 0U;
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_d = 0U;
        } else if ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d = 0U;
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_d = 0U;
        } else {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_d = 1U;
        }
    } else if ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q))) {
        if ((1U & (~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q)))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d = 0x10U;
        }
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_d 
            = ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q))
                ? 0x7fffffffU : 0x80000000U);
    } else {
        if ((1U & (~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q)))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d 
                = ((0x1dU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d)) 
                   | (2U & ((((0xfffffffeU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_q)) 
                              | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_q) 
                                 << 1U)) | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_q) 
                                            << 1U)) 
                            | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_q) 
                               << 1U))));
        }
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_d 
            = ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q))
                ? 0U : ((0x7fffffffU == vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q)
                         ? 0x7fffffffU : ((0U != vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q)
                                           ? (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q 
                                              + ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_q) 
                                                 & (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q 
                                                    | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_q) 
                                                       | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_q)))))
                                           : 1U)));
    }
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_q;
    if ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q))) {
        if ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d = 0U;
        } else if ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d = 0U;
        }
    } else if ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q))) {
        if ((1U & (~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q)))) {
            vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d = 0x10U;
        }
    } else if ((1U & (~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q)))) {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d 
            = ((0x1dU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d)) 
               | (2U & ((((0xfffffffeU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_q)) 
                          | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_guard_bit_q) 
                             << 1U)) | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_round_bit_q) 
                                        << 1U)) | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_q) 
                                                   << 1U))));
    }
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_valid 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2) 
           & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q) 
              >> 4U));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__exhausted 
        = (0U == ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q) 
                  & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q) 
                     - (IData)(1U))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s4_lod__DOT__lost_carry 
        = (IData)((0x40000001U == (0x40000001U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_d 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_zero_q)) 
                 & (~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_zero_q))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__bypass 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_nar_q) 
           | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_nar_q) 
              | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_nar_q) 
                 | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_zero_q) 
                    | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_zero_q)))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__raw_tail 
        = (0U != (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q 
                  & (((((((0x1bU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                          << 0x18U) | ((0x1aU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                       << 0x17U)) | 
                        (((0x19U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                          << 0x16U) | ((0x18U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                       << 0x15U))) 
                       | (((0x17U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                           << 0x14U) | (((0x16U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                         << 0x13U) 
                                        | ((0x15U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                           << 0x12U)))) 
                      | ((((0x14U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                           << 0x11U) | (((0x13U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                         << 0x10U) 
                                        | ((0x12U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                           << 0xfU))) 
                         | (((0x11U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                             << 0xeU) | (((0x10U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                          << 0xdU) 
                                         | ((0xfU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                            << 0xcU))))) 
                     | (((((0xeU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                           << 0xbU) | (((0xdU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                        << 0xaU) | 
                                       ((0xcU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                        << 9U))) | 
                         (((0xbU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                           << 8U) | (((0xaU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                      << 7U) | ((9U 
                                                 < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                                << 6U)))) 
                        | ((((8U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                             << 5U) | (((7U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                        << 4U) | ((6U 
                                                   < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                                  << 3U))) 
                           | (((5U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                               << 2U) | (((4U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)) 
                                          << 1U) | 
                                         (3U < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q)))))))));
    __Vtableidx2 = (((VL_GTS_III(11, 0x710U, (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf)) 
                      << 9U) | (((VL_LTS_III(11, 0xf0U, (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf)) 
                                  | ((0U != vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q) 
                                     | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sticky))) 
                                 << 8U) | (VL_LTES_III(11, 0xf0U, (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf)) 
                                           << 7U))) 
                    | (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_zero) 
                        << 6U) | ((((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_nar) 
                                    | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_flags) 
                                       >> 4U)) << 5U) 
                                  | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_flags))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_d 
        = Vshared_mac_checker__ConstPool__TABLE_had6e93ec_0
        [__Vtableidx2];
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_d 
        = Vshared_mac_checker__ConstPool__TABLE_h5d6c9829_0
        [__Vtableidx2];
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__magnitude 
        = ((vlSelfRef.a ^ (- (IData)((vlSelfRef.a >> 0x1fU)))) 
           + VL_SHIFTR_III(32,32,32, vlSelfRef.a, 0x1fU));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__magnitude 
        = ((vlSelfRef.b ^ (- (IData)((vlSelfRef.b >> 0x1fU)))) 
           + VL_SHIFTR_III(32,32,32, vlSelfRef.b, 0x1fU));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__magnitude 
        = ((vlSelfRef.c ^ (- (IData)((vlSelfRef.c >> 0x1fU)))) 
           + VL_SHIFTR_III(32,32,32, vlSelfRef.c, 0x1fU));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage0 
        = (0x3ffffffU & ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale))
                          ? VL_SHIFTR_III(26,26,32, 
                                          ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q) 
                                           << 0xcU), 1U)
                          : ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q) 
                             << 0xcU)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_accum__DOT__extended_sum 
        = (0x7ffffffU & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_first)
                           ? ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q) 
                              << 0xcU) : vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q) 
                         + vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_term));
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v 
        = (0x3fU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q));
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__Vfuncout 
        = (7U & ((((((1U & (IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v)) 
                     + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v) 
                              >> 1U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v) 
                                                >> 2U))) 
                   + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v) 
                            >> 3U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v) 
                                              >> 4U))) 
                 + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__v) 
                          >> 5U))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_a_lo 
        = __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__0__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v 
        = (0x3fU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q) 
                    >> 6U));
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__Vfuncout 
        = (7U & ((((((1U & (IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v)) 
                     + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v) 
                              >> 1U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v) 
                                                >> 2U))) 
                   + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v) 
                            >> 3U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v) 
                                              >> 4U))) 
                 + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__v) 
                          >> 5U))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_a_hi 
        = __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__1__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v 
        = (0x3fU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q));
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__Vfuncout 
        = (7U & ((((((1U & (IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v)) 
                     + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v) 
                              >> 1U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v) 
                                                >> 2U))) 
                   + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v) 
                            >> 3U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v) 
                                              >> 4U))) 
                 + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__v) 
                          >> 5U))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_b_lo 
        = __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__2__Vfuncout;
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v 
        = (0x3fU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q) 
                    >> 6U));
    __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__Vfuncout 
        = (7U & ((((((1U & (IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v)) 
                     + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v) 
                              >> 1U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v) 
                                                >> 2U))) 
                   + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v) 
                            >> 3U))) + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v) 
                                              >> 4U))) 
                 + (1U & ((IData)(__Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__v) 
                          >> 5U))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_b_hi 
        = __Vfunc_shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__popcount6__3__Vfuncout;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage1 
        = (0x1fffffffU & ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_payload_seed_q, 1U)
                           : vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_payload_seed_q));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage1 
        = (0x1fffffffU & ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_payload_seed_q, 1U)
                           : vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_payload_seed_q));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage1 
        = (0x1fffffffU & ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_payload_seed_q, 1U)
                           : vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_payload_seed_q));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage0 
        = (0x3fffffffU & ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q))
                           ? VL_SHIFTL_III(30,30,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_q, 1U)
                           : vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_q));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__is_init 
        = ((0U == (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q)) 
           | (0U == (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__limit_q)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage0 
        = (0x7fffffffU & ((1U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q))
                           ? VL_SHIFTR_III(31,31,32, 
                                           (0x20000000U 
                                            | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q 
                                               << 3U)), 1U)
                           : (0x20000000U | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q 
                                             << 3U))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_zero_d 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q)) 
                 & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_q)) 
                    | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_both_zero_q))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT____VdfgRegularize_h4bbb6d19_0_0 
        = ((IData)(vlSelfRef.rst_n) & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2));
    if ((0x2000000U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q)) {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
            = (0x3ffffffU & VL_SHIFTL_III(26,26,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q, 1U));
        shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm 
            = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf_inc_q;
    } else {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
            = (0x3ffffffU & VL_SHIFTL_III(26,26,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q, 2U));
        shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm 
            = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf;
    }
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_0 
        = ((0x800U & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q) 
                      << 1U)) | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_1 
        = ((0x800U & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q) 
                      << 1U)) | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in 
        = (1U | (0x7ffffffeU & ((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q 
                                 << 1U) ^ (0xfffffffeU 
                                           & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset 
        = (0x1fU & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                     >> 3U) ^ (- (IData)((1U & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                >> 0xaU))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_ready 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2) 
           & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q)) 
              & (0xcU >= (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__n_q))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_valid_q)) 
                 | (IData)(vlSelfRef.out_ready)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad = 0U;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad 
        = ((0xfU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad)) 
           | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q) 
              << 4U));
    vlSelfRef.add_lzc = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_d;
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_d 
        = ((0x3ffffffcU & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q) 
           | ((2U & ((0xfffffffeU & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q) 
                     | ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s4_lod__DOT__lost_carry) 
                        << 1U))) | (1U & vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_d 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_tail_q) 
           | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s4_lod__DOT__lost_carry));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_d 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_d) 
           & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sign_q) 
              != (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sign_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_tail_d 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q) 
           & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q) 
              | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__raw_tail)));
    vlSelfRef.pack_special = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_d;
    __VdfgRegularize_hd87f99a1_1_0 = (0x3fffffffU & 
                                      (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__magnitude 
                                       ^ (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__magnitude 
                                          >> 1U)));
    __VdfgRegularize_hd87f99a1_2_0 = (0x3fffffffU & 
                                      (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__magnitude 
                                       ^ (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__magnitude 
                                          >> 1U)));
    __VdfgRegularize_hd87f99a1_3_0 = (0x3fffffffU & 
                                      (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__magnitude 
                                       ^ (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__magnitude 
                                          >> 1U)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage1 
        = (0x3ffffffU & ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale))
                          ? VL_SHIFTR_III(26,26,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage0, 2U)
                          : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage0));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__choose_b 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_q) 
           & ((0xfU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_b_lo) 
                       + (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_b_hi))) 
              < (0xfU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_a_lo) 
                         + (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_a_hi)))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage2 
        = (0x1fffffffU & ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage1, 2U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage1));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage2 
        = (0x1fffffffU & ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage1, 2U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage1));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage2 
        = (0x1fffffffU & ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage1, 2U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage1));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage1 
        = (0x3fffffffU & ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q))
                           ? VL_SHIFTL_III(30,30,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage0, 2U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage0));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__is_last 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__is_init) 
           | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__exhausted) 
              | ((0xfU & ((IData)(1U) + (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q))) 
                 >= (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__limit_q))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage1 
        = (0x7fffffffU & ((2U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q))
                           ? VL_SHIFTR_III(31,31,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage0, 2U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage0));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_sign_d 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q) 
           | ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_zero_d)) 
              & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sign_q)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_flags_d 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q)
            ? 0x10U : ((0xcU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q)) 
                       | ((2U & ((0xfffffffeU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q)) 
                                 | (((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_zero_d)) 
                                     & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_q)) 
                                    << 1U))) | (1U 
                                                & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q)))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__clear_val 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q) 
           | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_zero_d));
    vlSelfRef.out_valid = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT____VdfgRegularize_h4bbb6d19_0_0) 
                           & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2) 
                              & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_valid_q)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba 
        = (0xfffU & ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_1) 
                     - (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_0)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab 
        = (0xfffU & ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_0) 
                     - (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT____VdfgRegularize_hd5170277_0_1)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt 
        = (((((((((0x40000000U == (0x40000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)) 
                  | (0x20000000U == (0x60000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                 | (0x10000000U == (0x70000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                | (0x8000000U == (0x78000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
               | (0x4000000U == (0x7c000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
              | (0x2000000U == (0x7e000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
             | (0x1000000U == (0x7f000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
            | (0x800000U == (0x7f800000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)))
            ? ((0x40000000U == (0x40000000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                ? 0U : ((0x20000000U == (0x60000000U 
                                         & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                         ? 1U : ((0x10000000U == (0x70000000U 
                                                  & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                  ? 2U : ((0x8000000U 
                                           == (0x78000000U 
                                               & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                           ? 3U : (
                                                   (0x4000000U 
                                                    == 
                                                    (0x7c000000U 
                                                     & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                    ? 4U
                                                    : 
                                                   ((0x2000000U 
                                                     == 
                                                     (0x7e000000U 
                                                      & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                     ? 5U
                                                     : 
                                                    ((0x1000000U 
                                                      == 
                                                      (0x7f000000U 
                                                       & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                      ? 6U
                                                      : 7U)))))))
            : (((((((((0x400000U == (0x7fc00000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)) 
                      | (0x200000U == (0x7fe00000U 
                                       & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                     | (0x100000U == (0x7ff00000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                    | (0x80000U == (0x7ff80000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                   | (0x40000U == (0x7ffc0000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                  | (0x20000U == (0x7ffe0000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                 | (0x10000U == (0x7fff0000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                | (0x8000U == (0x7fff8000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)))
                ? ((0x400000U == (0x7fc00000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                    ? 8U : ((0x200000U == (0x7fe00000U 
                                           & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                             ? 9U : ((0x100000U == 
                                      (0x7ff00000U 
                                       & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                      ? 0xaU : ((0x80000U 
                                                 == 
                                                 (0x7ff80000U 
                                                  & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                 ? 0xbU
                                                 : 
                                                ((0x40000U 
                                                  == 
                                                  (0x7ffc0000U 
                                                   & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                  ? 0xcU
                                                  : 
                                                 ((0x20000U 
                                                   == 
                                                   (0x7ffe0000U 
                                                    & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                   ? 0xdU
                                                   : 
                                                  ((0x10000U 
                                                    == 
                                                    (0x7fff0000U 
                                                     & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                    ? 0xeU
                                                    : 0xfU)))))))
                : (((((((((0x4000U == (0x7fffc000U 
                                       & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)) 
                          | (0x2000U == (0x7fffe000U 
                                         & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                         | (0x1000U == (0x7ffff000U 
                                        & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                        | (0x800U == (0x7ffff800U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                       | (0x400U == (0x7ffffc00U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                      | (0x200U == (0x7ffffe00U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                     | (0x100U == (0x7fffff00U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))) 
                    | (0x80U == (0x7fffff80U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)))
                    ? ((0x4000U == (0x7fffc000U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                        ? 0x10U : ((0x2000U == (0x7fffe000U 
                                                & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                    ? 0x11U : ((0x1000U 
                                                == 
                                                (0x7ffff000U 
                                                 & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                ? 0x12U
                                                : (
                                                   (0x800U 
                                                    == 
                                                    (0x7ffff800U 
                                                     & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                    ? 0x13U
                                                    : 
                                                   ((0x400U 
                                                     == 
                                                     (0x7ffffc00U 
                                                      & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                     ? 0x14U
                                                     : 
                                                    ((0x200U 
                                                      == 
                                                      (0x7ffffe00U 
                                                       & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                      ? 0x15U
                                                      : 
                                                     ((0x100U 
                                                       == 
                                                       (0x7fffff00U 
                                                        & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                       ? 0x16U
                                                       : 0x17U)))))))
                    : ((0x40U == (0x7fffffc0U & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                        ? 0x18U : ((0x20U == (0x7fffffe0U 
                                              & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                    ? 0x19U : ((0x10U 
                                                == 
                                                (0x7ffffff0U 
                                                 & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                ? 0x1aU
                                                : (
                                                   (8U 
                                                    == 
                                                    (0x7ffffff8U 
                                                     & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                    ? 0x1bU
                                                    : 
                                                   ((4U 
                                                     == 
                                                     (0x7ffffffcU 
                                                      & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                     ? 0x1cU
                                                     : 
                                                    ((2U 
                                                      == 
                                                      (0x7ffffffeU 
                                                       & shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in))
                                                      ? 0x1dU
                                                      : 
                                                     ((1U 
                                                       == shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__detector_in)
                                                       ? 0x1eU
                                                       : 0U))))))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_d 
        = (1U & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sticky) 
                 | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                    | ((((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                         >> 2U) & (0x1eU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                       | ((((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                            >> 1U) & (0x1dU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                          | (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                              & (0x1cU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                             | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                  >> 0x1cU) & (0x1bU 
                                               < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                     >> 0x1bU) & (0x1aU 
                                                  < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                   | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                        >> 0x1aU) & 
                                       (0x19U < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                      | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                           >> 0x19U) 
                                          & (0x18U 
                                             < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                         | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                              >> 0x18U) 
                                             & (0x17U 
                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                            | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                 >> 0x17U) 
                                                & (0x16U 
                                                   < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                               | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                    >> 0x16U) 
                                                   & (0x15U 
                                                      < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                  | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                       >> 0x15U) 
                                                      & (0x14U 
                                                         < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                     | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                          >> 0x14U) 
                                                         & (0x13U 
                                                            < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                        | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                             >> 0x13U) 
                                                            & (0x12U 
                                                               < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                           | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                >> 0x12U) 
                                                               & (0x11U 
                                                                  < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                              | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                   >> 0x11U) 
                                                                  & (0x10U 
                                                                     < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                 | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                      >> 0x10U) 
                                                                     & (0xfU 
                                                                        < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                    | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                         >> 0xfU) 
                                                                        & (0xeU 
                                                                           < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                       | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                            >> 0xeU) 
                                                                           & (0xdU 
                                                                              < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                          | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                               >> 0xdU) 
                                                                              & (0xcU 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                             | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 0xcU) 
                                                                                & (0xbU 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 0xbU) 
                                                                                & (0xaU 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 0xaU) 
                                                                                & (9U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 9U) 
                                                                                & (8U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 8U) 
                                                                                & (7U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 7U) 
                                                                                & (6U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 6U) 
                                                                                & (5U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 5U) 
                                                                                & (4U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 4U) 
                                                                                & (3U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 3U) 
                                                                                & (2U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 2U) 
                                                                                & (1U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | ((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q 
                                                                                >> 1U) 
                                                                                & (0U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))))))))))))))))))))))))))))))))))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0 
        = ((1U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)(((0x20U & ((~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                               >> 0xaU)) 
                                           << 5U)) 
                                 | ((0x10U & ((~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                  >> 0xaU)) 
                                              << 4U)) 
                                    | ((8U & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                              >> 7U)) 
                                       | (7U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf))))))) 
                << 0x35U) | ((QData)((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q)) 
                             << 0x18U)) : (((QData)((IData)(
                                                            ((0x10U 
                                                              & ((~ 
                                                                  ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                                   >> 0xaU)) 
                                                                 << 4U)) 
                                                             | ((8U 
                                                                 & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                                    >> 7U)) 
                                                                | (7U 
                                                                   & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf)))))) 
                                            << 0x36U) 
                                           | ((QData)((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q)) 
                                              << 0x19U)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_retire 
        = (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2) 
            & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_valid_q)) 
           & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2) 
               & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_valid_q)) 
              & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_ready) 
                 & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2) 
                    & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_valid_q)))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_ready)));
    __Vtableidx1 = (((VL_GTS_III(11, 0x710U, (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm)) 
                      << 9U) | (((VL_LTS_III(11, 0xf0U, (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm)) 
                                  | (0U != vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac)) 
                                 << 8U) | (VL_LTES_III(11, 0xf0U, (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm)) 
                                           << 7U))) 
                    | (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__zero_q) 
                        << 6U) | (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__nar_q) 
                                   << 5U) | (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__nar_q) 
                                              | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__zero_q))
                                              ? 0U : 
                                             ((((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_cut) 
                                                | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q)) 
                                               << 1U) 
                                              | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_d 
        = Vshared_mac_checker__ConstPool__TABLE_had6e93ec_0
        [__Vtableidx1];
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_d 
        = Vshared_mac_checker__ConstPool__TABLE_h5d6c9829_0
        [__Vtableidx1];
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset 
        = (0x1fU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                     >> 3U) ^ (- (IData)((1U & ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                >> 0xaU))))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__1__KET__ 
        = (IData)((0U != (0xcU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__3__KET__ 
        = (IData)((0U != (0xc0U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__5__KET__ 
        = (IData)((0U != (0xc00U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__7__KET__ 
        = (IData)((0U != (0xc000U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    vlSelfRef.add_sub = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_d;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__ 
        = (IData)((0U != (0x3fffc000U & __VdfgRegularize_hd87f99a1_1_0)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__ 
        = (IData)((0U != (0x3fffc000U & __VdfgRegularize_hd87f99a1_2_0)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__ 
        = (IData)((0U != (0x3fffc000U & __VdfgRegularize_hd87f99a1_3_0)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage2 
        = (0x3ffffffU & ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale))
                          ? VL_SHIFTR_III(26,26,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage1, 4U)
                          : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage1));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__y 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__bypass)
            ? 0U : (0x1000U | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__choose_b)
                                ? (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q)
                                : (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage3 
        = (0x1fffffffU & ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage2, 4U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage2));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage3 
        = (0x1fffffffU & ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage2, 4U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage2));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage3 
        = (0x1fffffffU & ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage2, 4U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage2));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage2 
        = (0x3fffffffU & ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q))
                           ? VL_SHIFTL_III(30,30,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage1, 4U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage1));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage2 
        = (0x7fffffffU & ((4U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q))
                           ? VL_SHIFTR_III(31,31,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage1, 4U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage1));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_sticky_d 
        = ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__clear_val)) 
           & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_q));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_sf_d 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__clear_val)
            ? 0U : (0x7ffU & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sf_inc_q) 
                              - (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__retire 
        = ((IData)(vlSelfRef.out_valid) & (IData)(vlSelfRef.out_ready));
    if ((0x800U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab))) {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_d 
            = (0x1fU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba));
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_d 
            = ((~ ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba) 
                   >> 0xbU)) & (IData)(((0U != (0x7e0U 
                                                & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba))) 
                                        | (0x1cU < 
                                           (0x1fU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ba))))));
    } else {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_d 
            = (0x1fU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab));
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_d 
            = ((~ ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab) 
                   >> 0xbU)) & (IData)(((0U != (0x7e0U 
                                                & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab))) 
                                        | (0x1cU < 
                                           (0x1fU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab))))));
    }
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__choose_a 
        = ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_zero_q)) 
           & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_zero_q) 
              | ((~ ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__diff_ab) 
                     >> 0xbU)) & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q) 
                                   != (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q)) 
                                  | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_frac_q 
                                     >= vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_frac_q)))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__regime 
        = (0x3fU & (~ ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt) 
                       ^ (- (IData)((1U & (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q 
                                           >> 0x1eU)))))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage1 
        = (0x1fffffffU & ((1U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt))
                           ? VL_SHIFTL_III(29,29,32, vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q, 1U)
                           : vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1 
        = ((2U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((3U & (- (IData)((1U 
                                                  & (~ 
                                                     ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                      >> 0xaU)))))))) 
                << 0x39U) | (0x1ffffffffffffffULL & 
                             (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0 
                              >> 2U))) : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0);
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__launch 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_retire) 
           & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_ready));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_retire)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_retire)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_retire)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pack_ready 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2) 
           & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_ready));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_d 
        = ((((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
             >> 2U) & (0x1eU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
           | ((((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                >> 1U) & (0x1dU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
              | (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                  & (0x1cU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                 | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                      >> 0x19U) & (0x1bU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                    | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                         >> 0x18U) & (0x1aU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                       | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                            >> 0x17U) & (0x19U < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                          | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                               >> 0x16U) & (0x18U < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                             | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                  >> 0x15U) & (0x17U 
                                               < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                     >> 0x14U) & (0x16U 
                                                  < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                   | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                        >> 0x13U) & 
                                       (0x15U < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                      | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                           >> 0x12U) 
                                          & (0x14U 
                                             < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                         | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                              >> 0x11U) 
                                             & (0x13U 
                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                            | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                 >> 0x10U) 
                                                & (0x12U 
                                                   < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                               | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                    >> 0xfU) 
                                                   & (0x11U 
                                                      < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                  | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                       >> 0xeU) 
                                                      & (0x10U 
                                                         < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                     | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                          >> 0xdU) 
                                                         & (0xfU 
                                                            < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                        | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                             >> 0xcU) 
                                                            & (0xeU 
                                                               < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                           | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                >> 0xbU) 
                                                               & (0xdU 
                                                                  < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                              | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                   >> 0xaU) 
                                                                  & (0xcU 
                                                                     < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                 | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                      >> 9U) 
                                                                     & (0xbU 
                                                                        < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                    | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                         >> 8U) 
                                                                        & (0xaU 
                                                                           < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                       | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                            >> 7U) 
                                                                           & (9U 
                                                                              < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                          | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                               >> 6U) 
                                                                              & (8U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                             | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                                >> 5U) 
                                                                                & (7U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                                >> 4U) 
                                                                                & (6U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                                >> 3U) 
                                                                                & (5U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                                >> 2U) 
                                                                                & (4U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                                >> 1U) 
                                                                                & (3U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))) 
                                                                                | (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac 
                                                                                & (2U 
                                                                                < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset)))))))))))))))))))))))))))))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0 
        = ((1U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))
            ? ((QData)((IData)((((~ ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                     >> 0xaU)) << 0x1fU) 
                                | ((0x40000000U & (
                                                   (~ 
                                                    ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                     >> 0xaU)) 
                                                   << 0x1eU)) 
                                   | ((0x20000000U 
                                       & ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                          << 0x13U)) 
                                      | ((0x1c000000U 
                                          & ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                             << 0x1aU)) 
                                         | vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac)))))) 
               << 0x1bU) : (((QData)((IData)(((0x10U 
                                               & ((~ 
                                                   ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                    >> 0xaU)) 
                                                  << 4U)) 
                                              | ((8U 
                                                  & ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                     >> 7U)) 
                                                 | (7U 
                                                    & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm)))))) 
                             << 0x36U) | ((QData)((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac)) 
                                          << 0x1cU)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__1__KET__ 
        = ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__3__KET__) 
           | (0U != (0x30U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__3__KET__ 
        = ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__7__KET__) 
           | (0U != (0x3000U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__cnt_d 
        = (0x1fU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__)
                      ? (((0U != (0xfU & (__VdfgRegularize_hd87f99a1_1_0 
                                          >> 0x1aU)))
                           ? ((2U & ((~ (IData)((0U 
                                                 != 
                                                 (3U 
                                                  & (__VdfgRegularize_hd87f99a1_1_0 
                                                     >> 0x1cU))))) 
                                     << 1U)) | (IData)(
                                                       ((~ 
                                                         (__VdfgRegularize_hd87f99a1_1_0 
                                                          >> 0x1dU)) 
                                                        & (0x8000000U 
                                                           != 
                                                           (0x18000000U 
                                                            & __VdfgRegularize_hd87f99a1_1_0)))))
                           : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_1_0 
                                              >> 0x16U)))
                               ? ((2U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (3U 
                                                      & (__VdfgRegularize_hd87f99a1_1_0 
                                                         >> 0x18U))))) 
                                         << 1U)) | (IData)(
                                                           ((~ 
                                                             (__VdfgRegularize_hd87f99a1_1_0 
                                                              >> 0x19U)) 
                                                            & (0x800000U 
                                                               != 
                                                               (0x1800000U 
                                                                & __VdfgRegularize_hd87f99a1_1_0)))))
                               : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_1_0 
                                                  >> 0x12U)))
                                   ? ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_1_0 
                                                             >> 0x14U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_1_0 
                                                   >> 0x15U)) 
                                                 & (0x80000U 
                                                    != 
                                                    (0x180000U 
                                                     & __VdfgRegularize_hd87f99a1_1_0)))))
                                   : ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_1_0 
                                                             >> 0x10U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_1_0 
                                                   >> 0x11U)) 
                                                 & (0x8000U 
                                                    != 
                                                    (0x18000U 
                                                     & __VdfgRegularize_hd87f99a1_1_0)))))))) 
                         | VL_SHIFTL_III(6,6,32, ((2U 
                                                   & ((~ (IData)(
                                                                 (0U 
                                                                  != 
                                                                  (0x3fc00000U 
                                                                   & __VdfgRegularize_hd87f99a1_1_0)))) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & ((~ (IData)(
                                                                   (0U 
                                                                    != 
                                                                    (0xfU 
                                                                     & (__VdfgRegularize_hd87f99a1_1_0 
                                                                        >> 0x1aU))))) 
                                                        & ((~ (IData)(
                                                                      (0U 
                                                                       != 
                                                                       (0xfU 
                                                                        & (__VdfgRegularize_hd87f99a1_1_0 
                                                                           >> 0x12U))))) 
                                                           | (0U 
                                                              != 
                                                              (0xfU 
                                                               & (__VdfgRegularize_hd87f99a1_1_0 
                                                                  >> 0x16U))))))), 2U))
                      : (((0U != (0xfU & (__VdfgRegularize_hd87f99a1_1_0 
                                          >> 0xaU)))
                           ? ((2U & ((~ (IData)((0U 
                                                 != 
                                                 (3U 
                                                  & (__VdfgRegularize_hd87f99a1_1_0 
                                                     >> 0xcU))))) 
                                     << 1U)) | (IData)(
                                                       ((~ 
                                                         (__VdfgRegularize_hd87f99a1_1_0 
                                                          >> 0xdU)) 
                                                        & (0x800U 
                                                           != 
                                                           (0x1800U 
                                                            & __VdfgRegularize_hd87f99a1_1_0)))))
                           : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_1_0 
                                              >> 6U)))
                               ? ((2U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (3U 
                                                      & (__VdfgRegularize_hd87f99a1_1_0 
                                                         >> 8U))))) 
                                         << 1U)) | (IData)(
                                                           ((~ 
                                                             (__VdfgRegularize_hd87f99a1_1_0 
                                                              >> 9U)) 
                                                            & (0x80U 
                                                               != 
                                                               (0x180U 
                                                                & __VdfgRegularize_hd87f99a1_1_0)))))
                               : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_1_0 
                                                  >> 2U)))
                                   ? ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_1_0 
                                                             >> 4U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_1_0 
                                                   >> 5U)) 
                                                 & (8U 
                                                    != 
                                                    (0x18U 
                                                     & __VdfgRegularize_hd87f99a1_1_0)))))
                                   : ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & __VdfgRegularize_hd87f99a1_1_0)))) 
                                             << 1U)) 
                                      | (IData)((1U 
                                                 == 
                                                 (3U 
                                                  & __VdfgRegularize_hd87f99a1_1_0))))))) 
                         | VL_SHIFTL_III(6,6,32, ((2U 
                                                   & ((~ (IData)(
                                                                 (0U 
                                                                  != 
                                                                  (0x3fc0U 
                                                                   & __VdfgRegularize_hd87f99a1_1_0)))) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & ((~ (IData)(
                                                                   (0U 
                                                                    != 
                                                                    (0xfU 
                                                                     & (__VdfgRegularize_hd87f99a1_1_0 
                                                                        >> 0xaU))))) 
                                                        & ((~ (IData)(
                                                                      (0U 
                                                                       != 
                                                                       (0xfU 
                                                                        & (__VdfgRegularize_hd87f99a1_1_0 
                                                                           >> 2U))))) 
                                                           | (0U 
                                                              != 
                                                              (0xfU 
                                                               & (__VdfgRegularize_hd87f99a1_1_0 
                                                                  >> 6U))))))), 2U))) 
                    | VL_SHIFTL_III(6,6,32, (3U & (~ 
                                                   (2U 
                                                    | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__)))), 4U)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__cnt_d 
        = (0x1fU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__)
                      ? (((0U != (0xfU & (__VdfgRegularize_hd87f99a1_2_0 
                                          >> 0x1aU)))
                           ? ((2U & ((~ (IData)((0U 
                                                 != 
                                                 (3U 
                                                  & (__VdfgRegularize_hd87f99a1_2_0 
                                                     >> 0x1cU))))) 
                                     << 1U)) | (IData)(
                                                       ((~ 
                                                         (__VdfgRegularize_hd87f99a1_2_0 
                                                          >> 0x1dU)) 
                                                        & (0x8000000U 
                                                           != 
                                                           (0x18000000U 
                                                            & __VdfgRegularize_hd87f99a1_2_0)))))
                           : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_2_0 
                                              >> 0x16U)))
                               ? ((2U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (3U 
                                                      & (__VdfgRegularize_hd87f99a1_2_0 
                                                         >> 0x18U))))) 
                                         << 1U)) | (IData)(
                                                           ((~ 
                                                             (__VdfgRegularize_hd87f99a1_2_0 
                                                              >> 0x19U)) 
                                                            & (0x800000U 
                                                               != 
                                                               (0x1800000U 
                                                                & __VdfgRegularize_hd87f99a1_2_0)))))
                               : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_2_0 
                                                  >> 0x12U)))
                                   ? ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_2_0 
                                                             >> 0x14U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_2_0 
                                                   >> 0x15U)) 
                                                 & (0x80000U 
                                                    != 
                                                    (0x180000U 
                                                     & __VdfgRegularize_hd87f99a1_2_0)))))
                                   : ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_2_0 
                                                             >> 0x10U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_2_0 
                                                   >> 0x11U)) 
                                                 & (0x8000U 
                                                    != 
                                                    (0x18000U 
                                                     & __VdfgRegularize_hd87f99a1_2_0)))))))) 
                         | VL_SHIFTL_III(6,6,32, ((2U 
                                                   & ((~ (IData)(
                                                                 (0U 
                                                                  != 
                                                                  (0x3fc00000U 
                                                                   & __VdfgRegularize_hd87f99a1_2_0)))) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & ((~ (IData)(
                                                                   (0U 
                                                                    != 
                                                                    (0xfU 
                                                                     & (__VdfgRegularize_hd87f99a1_2_0 
                                                                        >> 0x1aU))))) 
                                                        & ((~ (IData)(
                                                                      (0U 
                                                                       != 
                                                                       (0xfU 
                                                                        & (__VdfgRegularize_hd87f99a1_2_0 
                                                                           >> 0x12U))))) 
                                                           | (0U 
                                                              != 
                                                              (0xfU 
                                                               & (__VdfgRegularize_hd87f99a1_2_0 
                                                                  >> 0x16U))))))), 2U))
                      : (((0U != (0xfU & (__VdfgRegularize_hd87f99a1_2_0 
                                          >> 0xaU)))
                           ? ((2U & ((~ (IData)((0U 
                                                 != 
                                                 (3U 
                                                  & (__VdfgRegularize_hd87f99a1_2_0 
                                                     >> 0xcU))))) 
                                     << 1U)) | (IData)(
                                                       ((~ 
                                                         (__VdfgRegularize_hd87f99a1_2_0 
                                                          >> 0xdU)) 
                                                        & (0x800U 
                                                           != 
                                                           (0x1800U 
                                                            & __VdfgRegularize_hd87f99a1_2_0)))))
                           : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_2_0 
                                              >> 6U)))
                               ? ((2U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (3U 
                                                      & (__VdfgRegularize_hd87f99a1_2_0 
                                                         >> 8U))))) 
                                         << 1U)) | (IData)(
                                                           ((~ 
                                                             (__VdfgRegularize_hd87f99a1_2_0 
                                                              >> 9U)) 
                                                            & (0x80U 
                                                               != 
                                                               (0x180U 
                                                                & __VdfgRegularize_hd87f99a1_2_0)))))
                               : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_2_0 
                                                  >> 2U)))
                                   ? ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_2_0 
                                                             >> 4U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_2_0 
                                                   >> 5U)) 
                                                 & (8U 
                                                    != 
                                                    (0x18U 
                                                     & __VdfgRegularize_hd87f99a1_2_0)))))
                                   : ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & __VdfgRegularize_hd87f99a1_2_0)))) 
                                             << 1U)) 
                                      | (IData)((1U 
                                                 == 
                                                 (3U 
                                                  & __VdfgRegularize_hd87f99a1_2_0))))))) 
                         | VL_SHIFTL_III(6,6,32, ((2U 
                                                   & ((~ (IData)(
                                                                 (0U 
                                                                  != 
                                                                  (0x3fc0U 
                                                                   & __VdfgRegularize_hd87f99a1_2_0)))) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & ((~ (IData)(
                                                                   (0U 
                                                                    != 
                                                                    (0xfU 
                                                                     & (__VdfgRegularize_hd87f99a1_2_0 
                                                                        >> 0xaU))))) 
                                                        & ((~ (IData)(
                                                                      (0U 
                                                                       != 
                                                                       (0xfU 
                                                                        & (__VdfgRegularize_hd87f99a1_2_0 
                                                                           >> 2U))))) 
                                                           | (0U 
                                                              != 
                                                              (0xfU 
                                                               & (__VdfgRegularize_hd87f99a1_2_0 
                                                                  >> 6U))))))), 2U))) 
                    | VL_SHIFTL_III(6,6,32, (3U & (~ 
                                                   (2U 
                                                    | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__)))), 4U)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__cnt_d 
        = (0x1fU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__)
                      ? (((0U != (0xfU & (__VdfgRegularize_hd87f99a1_3_0 
                                          >> 0x1aU)))
                           ? ((2U & ((~ (IData)((0U 
                                                 != 
                                                 (3U 
                                                  & (__VdfgRegularize_hd87f99a1_3_0 
                                                     >> 0x1cU))))) 
                                     << 1U)) | (IData)(
                                                       ((~ 
                                                         (__VdfgRegularize_hd87f99a1_3_0 
                                                          >> 0x1dU)) 
                                                        & (0x8000000U 
                                                           != 
                                                           (0x18000000U 
                                                            & __VdfgRegularize_hd87f99a1_3_0)))))
                           : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_3_0 
                                              >> 0x16U)))
                               ? ((2U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (3U 
                                                      & (__VdfgRegularize_hd87f99a1_3_0 
                                                         >> 0x18U))))) 
                                         << 1U)) | (IData)(
                                                           ((~ 
                                                             (__VdfgRegularize_hd87f99a1_3_0 
                                                              >> 0x19U)) 
                                                            & (0x800000U 
                                                               != 
                                                               (0x1800000U 
                                                                & __VdfgRegularize_hd87f99a1_3_0)))))
                               : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_3_0 
                                                  >> 0x12U)))
                                   ? ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_3_0 
                                                             >> 0x14U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_3_0 
                                                   >> 0x15U)) 
                                                 & (0x80000U 
                                                    != 
                                                    (0x180000U 
                                                     & __VdfgRegularize_hd87f99a1_3_0)))))
                                   : ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_3_0 
                                                             >> 0x10U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_3_0 
                                                   >> 0x11U)) 
                                                 & (0x8000U 
                                                    != 
                                                    (0x18000U 
                                                     & __VdfgRegularize_hd87f99a1_3_0)))))))) 
                         | VL_SHIFTL_III(6,6,32, ((2U 
                                                   & ((~ (IData)(
                                                                 (0U 
                                                                  != 
                                                                  (0x3fc00000U 
                                                                   & __VdfgRegularize_hd87f99a1_3_0)))) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & ((~ (IData)(
                                                                   (0U 
                                                                    != 
                                                                    (0xfU 
                                                                     & (__VdfgRegularize_hd87f99a1_3_0 
                                                                        >> 0x1aU))))) 
                                                        & ((~ (IData)(
                                                                      (0U 
                                                                       != 
                                                                       (0xfU 
                                                                        & (__VdfgRegularize_hd87f99a1_3_0 
                                                                           >> 0x12U))))) 
                                                           | (0U 
                                                              != 
                                                              (0xfU 
                                                               & (__VdfgRegularize_hd87f99a1_3_0 
                                                                  >> 0x16U))))))), 2U))
                      : (((0U != (0xfU & (__VdfgRegularize_hd87f99a1_3_0 
                                          >> 0xaU)))
                           ? ((2U & ((~ (IData)((0U 
                                                 != 
                                                 (3U 
                                                  & (__VdfgRegularize_hd87f99a1_3_0 
                                                     >> 0xcU))))) 
                                     << 1U)) | (IData)(
                                                       ((~ 
                                                         (__VdfgRegularize_hd87f99a1_3_0 
                                                          >> 0xdU)) 
                                                        & (0x800U 
                                                           != 
                                                           (0x1800U 
                                                            & __VdfgRegularize_hd87f99a1_3_0)))))
                           : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_3_0 
                                              >> 6U)))
                               ? ((2U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (3U 
                                                      & (__VdfgRegularize_hd87f99a1_3_0 
                                                         >> 8U))))) 
                                         << 1U)) | (IData)(
                                                           ((~ 
                                                             (__VdfgRegularize_hd87f99a1_3_0 
                                                              >> 9U)) 
                                                            & (0x80U 
                                                               != 
                                                               (0x180U 
                                                                & __VdfgRegularize_hd87f99a1_3_0)))))
                               : ((0U != (0xfU & (__VdfgRegularize_hd87f99a1_3_0 
                                                  >> 2U)))
                                   ? ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & (__VdfgRegularize_hd87f99a1_3_0 
                                                             >> 4U))))) 
                                             << 1U)) 
                                      | (IData)(((~ 
                                                  (__VdfgRegularize_hd87f99a1_3_0 
                                                   >> 5U)) 
                                                 & (8U 
                                                    != 
                                                    (0x18U 
                                                     & __VdfgRegularize_hd87f99a1_3_0)))))
                                   : ((2U & ((~ (IData)(
                                                        (0U 
                                                         != 
                                                         (3U 
                                                          & __VdfgRegularize_hd87f99a1_3_0)))) 
                                             << 1U)) 
                                      | (IData)((1U 
                                                 == 
                                                 (3U 
                                                  & __VdfgRegularize_hd87f99a1_3_0))))))) 
                         | VL_SHIFTL_III(6,6,32, ((2U 
                                                   & ((~ (IData)(
                                                                 (0U 
                                                                  != 
                                                                  (0x3fc0U 
                                                                   & __VdfgRegularize_hd87f99a1_3_0)))) 
                                                      << 1U)) 
                                                  | (1U 
                                                     & ((~ (IData)(
                                                                   (0U 
                                                                    != 
                                                                    (0xfU 
                                                                     & (__VdfgRegularize_hd87f99a1_3_0 
                                                                        >> 0xaU))))) 
                                                        & ((~ (IData)(
                                                                      (0U 
                                                                       != 
                                                                       (0xfU 
                                                                        & (__VdfgRegularize_hd87f99a1_3_0 
                                                                           >> 2U))))) 
                                                           | (0U 
                                                              != 
                                                              (0xfU 
                                                               & (__VdfgRegularize_hd87f99a1_3_0 
                                                                  >> 6U))))))), 2U))) 
                    | VL_SHIFTL_III(6,6,32, (3U & (~ 
                                                   (2U 
                                                    | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_regime_detector__DOT__g_group4__DOT__valid_tree__0282__029__BRA__3__KET__)))), 4U)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__term 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_init)
            ? 0U : (0x3ffffffU & ((8U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale))
                                   ? VL_SHIFTR_III(26,26,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage2, 8U)
                                   : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_shift__DOT__stage2)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage4 
        = (0x1fffffffU & ((8U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage3, 8U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage3));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage4 
        = (0x1fffffffU & ((8U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage3, 8U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage3));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage4 
        = (0x1fffffffU & ((8U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage3, 8U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage3));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage3 
        = (0x3fffffffU & ((8U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q))
                           ? VL_SHIFTL_III(30,30,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage2, 8U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage2));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage3 
        = (0x7fffffffU & ((8U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q))
                           ? VL_SHIFTR_III(31,31,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage2, 8U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage2));
    vlSelfRef.add_shift = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_d;
    vlSelfRef.add_clamped = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_d;
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage2 
        = (0x1fffffffU & ((2U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage1, 2U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage1));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2 
        = ((4U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((0xfU & (- (IData)(
                                                   (1U 
                                                    & (~ 
                                                       ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                        >> 0xaU)))))))) 
                << 0x37U) | (0x7fffffffffffffULL & 
                             (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1 
                              >> 4U))) : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1);
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_ready)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_ready)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_ready)));
    vlSelfRef.pack_sample = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_valid) 
                             & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pack_ready));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready4 
        = (1U & ((~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q) 
                     >> 4U)) | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pack_ready)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1 
        = ((2U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((3U & (- (IData)((1U 
                                                  & (~ 
                                                     ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                      >> 0xaU)))))))) 
                << 0x39U) | (0x1ffffffffffffffULL & 
                             (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0 
                              >> 2U))) : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage0);
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0283__029__BRA__1__KET__ 
        = (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__3__KET__) 
            | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__5__KET__)) 
           | (0U != (0x300U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__payload 
        = (0x1fffffffU & ((0x10U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage4, 0x10U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__u_align_payload__DOT__stage4));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__payload 
        = (0x1fffffffU & ((0x10U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage4, 0x10U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__u_align_payload__DOT__stage4));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__payload 
        = (0x1fffffffU & ((0x10U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage4, 0x10U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__u_align_payload__DOT__stage4));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT____Vcellout__u_left_shift__out 
        = (0x3fffffffU & ((0x10U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q))
                           ? VL_SHIFTL_III(30,30,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage3, 0x10U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__u_left_shift__DOT__stage3));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__shifted_full 
        = (0x7fffffffU & ((0x10U & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q))
                           ? VL_SHIFTR_III(31,31,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage3, 0x10U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__u_right_shift__DOT__stage3));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage3 
        = (0x1fffffffU & ((4U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage2, 4U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage2));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3 
        = ((8U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((0xffU & (- (IData)(
                                                    (1U 
                                                     & (~ 
                                                        ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                         >> 0xaU)))))))) 
                << 0x33U) | (0x7ffffffffffffULL & (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2 
                                                   >> 8U)))
            : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2);
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready3 
        = (1U & ((~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q) 
                     >> 3U)) | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready4)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2 
        = ((4U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((0xfU & (- (IData)(
                                                   (1U 
                                                    & (~ 
                                                       ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                        >> 0xaU)))))))) 
                << 0x37U) | (0x7fffffffffffffULL & 
                             (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1 
                              >> 4U))) : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage1);
    __VdfgRegularize_hd87f99a1_7_0 = ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0283__029__BRA__1__KET__)
                                       ? ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__3__KET__)
                                           ? ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__7__KET__)
                                               ? ((0x8000U 
                                                   & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                   ? 0U
                                                   : 1U)
                                               : (2U 
                                                  | ((0x2000U 
                                                      & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                      ? 0U
                                                      : 1U)))
                                           : (4U | 
                                              ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__5__KET__)
                                                ? (
                                                   (0x800U 
                                                    & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                    ? 0U
                                                    : 1U)
                                                : (2U 
                                                   | ((0x200U 
                                                       & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                       ? 0U
                                                       : 1U)))))
                                       : (8U | ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__1__KET__)
                                                 ? 
                                                ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__3__KET__)
                                                  ? 
                                                 ((0x80U 
                                                   & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                   ? 0U
                                                   : 1U)
                                                  : 
                                                 (2U 
                                                  | ((0x20U 
                                                      & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                      ? 0U
                                                      : 1U)))
                                                 : 
                                                (4U 
                                                 | ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__1__KET__)
                                                     ? 
                                                    ((8U 
                                                      & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                      ? 0U
                                                      : 1U)
                                                     : 
                                                    (2U 
                                                     | ((2U 
                                                         & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))
                                                         ? 0U
                                                         : 1U)))))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid 
        = ((((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0283__029__BRA__1__KET__) 
             | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0282__029__BRA__1__KET__)) 
            | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__tree_vld__0281__029__BRA__1__KET__)) 
           | (0U != (3U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_lod__DOT__g_baseline__DOT__data_pad))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_d 
        = (((((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q)) 
              & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q))
              ? (0x3fffffffU & (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__shifted_full 
                                >> 1U)) : 0U) << 1U) 
           | ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q) 
              & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q) 
                 | (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__shifted_full 
                    | (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s2_align__DOT__raw_tail)))));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage4 
        = (0x1fffffffU & ((8U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage3, 8U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage3));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__shifted 
        = ((0x10U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((0xffffU & (- (IData)(
                                                      (1U 
                                                       & (~ 
                                                          ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf) 
                                                           >> 0xaU)))))))) 
                << 0x2bU) | (0x7ffffffffffULL & (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3 
                                                 >> 0x10U)))
            : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3);
    vlSelfRef.add_lzc_sample = (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q) 
                                 >> 2U) & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready3));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready2 
        = (1U & ((~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q) 
                     >> 2U)) | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready3)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3 
        = ((8U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((0xffU & (- (IData)(
                                                    (1U 
                                                     & (~ 
                                                        ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                         >> 0xaU)))))))) 
                << 0x33U) | (0x7ffffffffffffULL & (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2 
                                                   >> 8U)))
            : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage2);
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0281__029 
        = (0xfffU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid) 
                      & (IData)(__VdfgRegularize_hd87f99a1_7_0))
                      ? VL_SHIFTL_III(12,12,32, (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q), 2U)
                      : VL_SHIFTL_III(12,12,32, (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q), 1U)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__payload 
        = (0x1fffffffU & ((0x10U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__cnt))
                           ? VL_SHIFTL_III(29,29,32, shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage4, 0x10U)
                           : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__align_payload__DOT__stage4));
    vlSelfRef.pack_rounding = ((0xcU & ((IData)((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__shifted 
                                                 >> 0x1bU)) 
                                        << 2U)) | (
                                                   (2U 
                                                    & ((IData)(
                                                               (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__shifted 
                                                                >> 0x1aU)) 
                                                       << 1U)) 
                                                   | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_d)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready1 
        = (1U & ((~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q) 
                     >> 1U)) | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready2)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__shifted 
        = ((0x10U & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__offset))
            ? (((QData)((IData)((0xffffU & (- (IData)(
                                                      (1U 
                                                       & (~ 
                                                          ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sf_norm) 
                                                           >> 0xaU)))))))) 
                << 0x2bU) | (0x7ffffffffffULL & (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3 
                                                 >> 0x10U)))
            : shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__u_payload_shift__DOT__stage3);
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0282__029 
        = (0xfffU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid) 
                      & ((IData)(__VdfgRegularize_hd87f99a1_7_0) 
                         >> 1U)) ? VL_SHIFTL_III(12,12,32, (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0281__029), 2U)
                      : (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0281__029)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_count 
        = ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid)
            ? (IData)(__VdfgRegularize_hd87f99a1_7_0)
            : 0U);
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__scale_sum 
        = (0x1fU & ((IData)(1U) + ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q) 
                                   + (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_count))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready0 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready1)));
    shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0283__029 
        = (0xfffU & (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid) 
                      & ((IData)(__VdfgRegularize_hd87f99a1_7_0) 
                         >> 2U)) ? VL_SHIFTL_III(12,12,32, (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0282__029), 4U)
                      : (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0282__029)));
    if (shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid) {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__next_scale 
            = (0xfU & (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__scale_sum));
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_next 
            = (0xfffU & ((0xcU <= (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_count))
                          ? 0U : (((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid) 
                                   & ((IData)(__VdfgRegularize_hd87f99a1_7_0) 
                                      >> 3U)) ? VL_SHIFTL_III(12,12,32, (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0283__029), 8U)
                                   : (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__u_shift__DOT__g_multi_bit__DOT__stage__0283__029))));
    } else {
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__next_scale 
            = (0xfU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q));
        vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_next 
            = (0xfffU & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q));
    }
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_error 
        = (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q) 
            & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__is_init)) 
               & ((0xcU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q)) 
                  | ((IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__leading_valid) 
                     & (0xcU < (IData)(shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_sac__DOT__scale_sum)))))) 
           | ((vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_accum__DOT__extended_sum 
               >> 0x1aU) & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_valid)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_ready 
        = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2) 
           & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready0));
    vlSelfRef.core_error = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_error;
    vlSelfRef.add_sample = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q) 
                            & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_ready));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_parse_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_ready)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_parse_ready)));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_ready 
        = (1U & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_valid_q)) 
                 | (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_ready)));
    vlSelfRef.in_ready = ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT____VdfgRegularize_h4bbb6d19_0_0) 
                          & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2) 
                             & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pack_ready) 
                                & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2) 
                                    & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_ready)) 
                                   & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2) 
                                       & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_ready)) 
                                      & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2) 
                                          & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_ready)) 
                                         & ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_ready) 
                                            & (((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2) 
                                                & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_ready)) 
                                               & ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q)) 
                                                  & ((1U 
                                                      >= (IData)(vlSelfRef.cfg_ops)) 
                                                     & (0xcU 
                                                        >= (IData)(vlSelfRef.cfg_n))))))))))));
    vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_accept 
        = ((IData)(vlSelfRef.in_valid) & (IData)(vlSelfRef.in_ready));
}

VL_ATTR_COLD void Vshared_mac_checker___024root___eval_triggers__stl(Vshared_mac_checker___024root* vlSelf);

VL_ATTR_COLD bool Vshared_mac_checker___024root___eval_phase__stl(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_phase__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vshared_mac_checker___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vshared_mac_checker___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__ico(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___dump_triggers__ico\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VicoTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__act(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___dump_triggers__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.meta_sync2)\n");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
    if ((8ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 3 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.reset_bridge_q)\n");
    }
    if ((0x10ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 4 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_a.meta_sync2)\n");
    }
    if ((0x20ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 5 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_b.meta_sync2)\n");
    }
    if ((0x40ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 6 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_c.meta_sync2)\n");
    }
    if ((0x80ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 7 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_core.meta_sync2)\n");
    }
    if ((0x100ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 8 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_product_pack.meta_sync2)\n");
    }
    if ((0x200ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 9 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_add.meta_sync2)\n");
    }
    if ((0x400ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 10 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_pack.meta_sync2)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__nba(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___dump_triggers__nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.meta_sync2)\n");
    }
    if ((4ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
    if ((8ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 3 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.reset_bridge_q)\n");
    }
    if ((0x10ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 4 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_a.meta_sync2)\n");
    }
    if ((0x20ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 5 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_b.meta_sync2)\n");
    }
    if ((0x40ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 6 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_c.meta_sync2)\n");
    }
    if ((0x80ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 7 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_core.meta_sync2)\n");
    }
    if ((0x100ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 8 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_product_pack.meta_sync2)\n");
    }
    if ((0x200ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 9 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_add.meta_sync2)\n");
    }
    if ((0x400ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 10 is active: @(negedge shared_mac_checker.g_nf.dut.u_wrapper.u_pack.meta_sync2)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vshared_mac_checker___024root___ctor_var_reset(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___ctor_var_reset\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst_n = VL_RAND_RESET_I(1);
    vlSelf->in_valid = VL_RAND_RESET_I(1);
    vlSelf->in_ready = VL_RAND_RESET_I(1);
    vlSelf->a = VL_RAND_RESET_I(32);
    vlSelf->b = VL_RAND_RESET_I(32);
    vlSelf->c = VL_RAND_RESET_I(32);
    vlSelf->cfg_n = VL_RAND_RESET_I(4);
    vlSelf->cfg_ops = VL_RAND_RESET_I(2);
    vlSelf->out_valid = VL_RAND_RESET_I(1);
    vlSelf->out_ready = VL_RAND_RESET_I(1);
    vlSelf->d = VL_RAND_RESET_I(32);
    vlSelf->flags = VL_RAND_RESET_I(5);
    vlSelf->core_done = VL_RAND_RESET_I(1);
    vlSelf->core_magnitude = VL_RAND_RESET_I(26);
    vlSelf->core_iterations = VL_RAND_RESET_I(4);
    vlSelf->core_cut = VL_RAND_RESET_I(1);
    vlSelf->core_input_cut = VL_RAND_RESET_I(1);
    vlSelf->core_sign = VL_RAND_RESET_I(1);
    vlSelf->core_scale = VL_RAND_RESET_I(11);
    vlSelf->core_error = VL_RAND_RESET_I(1);
    vlSelf->commit_valid = VL_RAND_RESET_I(1);
    vlSelf->commit_first = VL_RAND_RESET_I(1);
    vlSelf->commit_last = VL_RAND_RESET_I(1);
    vlSelf->commit_iteration = VL_RAND_RESET_I(4);
    vlSelf->pack_sample = VL_RAND_RESET_I(1);
    vlSelf->pack_special = VL_RAND_RESET_I(3);
    vlSelf->pack_rounding = VL_RAND_RESET_I(4);
    vlSelf->add_sample = VL_RAND_RESET_I(1);
    vlSelf->add_shift = VL_RAND_RESET_I(5);
    vlSelf->add_clamped = VL_RAND_RESET_I(1);
    vlSelf->add_sub = VL_RAND_RESET_I(1);
    vlSelf->add_lzc = VL_RAND_RESET_I(5);
    vlSelf->add_lzc_sample = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_frac_q = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_zero = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_nar = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_parse_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_frac_q = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__add_valid = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sign = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_zero = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_nar = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sticky = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_flags = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__n_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_accept = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pair_retire = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__y = VL_RAND_RESET_I(13);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_sf = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__retire = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_error = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__bypass = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sign = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_cut = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf_inc_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__prepack_frac = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_flags_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__pack_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT____VdfgRegularize_h4bbb6d19_0_0 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__magnitude = VL_RAND_RESET_I(32);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__cnt_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_s_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_first_regime_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_payload_seed_q = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__payload = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__regime = VL_RAND_RESET_I(6);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_s_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q = VL_RAND_RESET_I(12);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_tail_cut_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__magnitude = VL_RAND_RESET_I(32);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__cnt_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_s_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_first_regime_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_payload_seed_q = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__payload = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__regime = VL_RAND_RESET_I(6);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_s_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q = VL_RAND_RESET_I(12);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_tail_cut_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__magnitude = VL_RAND_RESET_I(32);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__cnt_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_s_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_first_regime_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_payload_seed_q = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__payload = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__regime = VL_RAND_RESET_I(6);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_s_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_q = VL_RAND_RESET_I(12);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_lo_q = VL_RAND_RESET_I(14);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_a_lo = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_a_hi = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_b_lo = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__cnt_b_hi = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_ops__DOT__choose_b = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q = VL_RAND_RESET_I(13);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__launch = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q = VL_RAND_RESET_I(12);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__limit_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_next = VL_RAND_RESET_I(12);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__next_scale = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__exhausted = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__is_init = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__next_count = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__is_last = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_valid = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_first = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_last = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_init = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_iteration = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_cut = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__term = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_valid = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_first = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_last = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_cut = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_iteration = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_term = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__iterations_done_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__done_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__u_accum__DOT__extended_sum = VL_RAND_RESET_I(27);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_d = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q = VL_RAND_RESET_I(31);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_d = VL_RAND_RESET_I(32);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q = VL_RAND_RESET_I(32);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__u_prepare__DOT__shifted = VL_RAND_RESET_Q(59);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__regime = VL_RAND_RESET_I(6);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_parse__DOT__payload = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready4 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready3 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__ready0 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_x_frac_q = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_flags_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_d = VL_RAND_RESET_I(31);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_tail_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_x_frac_q = VL_RAND_RESET_I(26);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_q = VL_RAND_RESET_I(31);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_tail_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sub_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sf_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_both_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_flags_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_d = VL_RAND_RESET_I(31);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sf_inc_d = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q = VL_RAND_RESET_I(31);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sf_inc_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_tail_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_both_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_flags_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_d = VL_RAND_RESET_I(30);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_q = VL_RAND_RESET_I(30);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sf_inc_q = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_both_zero_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q = VL_RAND_RESET_I(4);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_sign_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_zero_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_sticky_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_sf_d = VL_RAND_RESET_I(11);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s5_flags_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q = VL_RAND_RESET_I(29);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s1_prepare__DOT__choose_a = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT____Vcellout__u_left_shift__out = VL_RAND_RESET_I(30);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__u_s5_norm__DOT__clear_val = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync1 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2 = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_d = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_d = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_mag_trunc_q = VL_RAND_RESET_I(31);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_guard_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_round_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sign_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q = VL_RAND_RESET_I(3);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_d = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_valid_q = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__d_q = VL_RAND_RESET_I(32);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_q = VL_RAND_RESET_I(5);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_ready = VL_RAND_RESET_I(1);
    vlSelf->shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__u_prepare__DOT__shifted = VL_RAND_RESET_Q(59);
    vlSelf->__Vintraval_ha2b41170__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h59ccdbf8__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_he0c49a4a__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h8d49a9b7__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h7d6575b5__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h04d6713f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hf4929546__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd6e1fcd6__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hf476d154__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd3869371__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h6751e570__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hcf37a440__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h70b3556b__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hbbbe6f5f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h413b7d0d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hab538da8__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h2d306e88__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h943d89e5__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h943e2312__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h458ac7da__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_hd7bd7feb__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_ha3129ae8__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd0a2a032__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_he46cbe78__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h3bfdfab9__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h085dabc1__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hf39655e1__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_ha2d6405d__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h4bfd8fb5__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_hca45a503__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hca44f8b8__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h88cf2bb9__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd71cdb2d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hb1540ed6__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hf1a8f13e__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_hb2e7edd0__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_h3cfc0f55__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_h97014a6f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h39b29c89__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h572e7450__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h6945df4f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h090ff3b2__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_hac615f2a__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h4fa5b5e7__0 = VL_RAND_RESET_I(29);
    vlSelf->__Vintraval_hc51caf44__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0d6eb68f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_he5f793be__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hc280c445__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h114e8927__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h4913fdf6__0 = VL_RAND_RESET_I(12);
    vlSelf->__Vintraval_h1fb8578e__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hc7ce1d07__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h4d009faa__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h41299715__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h9f3941c0__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hb1218897__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_he5498c62__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hbd21842d__0 = VL_RAND_RESET_I(29);
    vlSelf->__Vintraval_hb2625146__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h70840449__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hcfca8622__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hdc07095d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_ha1830bee__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h4b9b6093__0 = VL_RAND_RESET_I(12);
    vlSelf->__Vintraval_he2d3334e__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_ha279e4fc__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h3cd5a785__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h068cb7e1__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hc30e4366__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h2cadbdaa__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_h43e2012e__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hb329c532__0 = VL_RAND_RESET_I(29);
    vlSelf->__Vintraval_he65d5a18__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h191cc917__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h248d66b1__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h30f4343f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hfb038429__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h1ec9ae67__0 = VL_RAND_RESET_I(12);
    vlSelf->__Vintraval_hc405a269__0 = VL_RAND_RESET_I(14);
    vlSelf->__Vintraval_h41b79cf1__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h41c6c006__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h5385dd6e__0 = VL_RAND_RESET_I(13);
    vlSelf->__Vintraval_h035c06ac__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h3a5785f0__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_hf368c251__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hc1af8749__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd0335c43__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h869f09ba__0 = VL_RAND_RESET_I(12);
    vlSelf->__Vintraval_he4adc086__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_he582982b__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h10d40b18__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h812002ee__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h7b9025e2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd155a727__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h1940b3d3__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h63ea55ee__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h1e872215__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_he4a4e858__0 = VL_RAND_RESET_I(12);
    vlSelf->__Vintraval_hf19e7a0a__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h1312d77b__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_hd032beb6__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0f189bc3__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0af13aa0__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h35be6ad6__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h3a8b4125__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hb1c8298a__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_hba10d792__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_h0dcc12b7__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0923f157__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_h4067bc35__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h17396284__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h789c8e3f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h70b56657__0 = VL_RAND_RESET_I(31);
    vlSelf->__Vintraval_h4c70e25d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hcb0c2e69__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h2f96d46d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0973fdd3__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hdd1a3427__0 = VL_RAND_RESET_I(3);
    vlSelf->__Vintraval_hac2377c9__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_ha8c51840__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h53d41d1a__0 = VL_RAND_RESET_I(32);
    vlSelf->__Vintraval_h8c0f5e32__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_he00810c2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hcbfe9518__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hf6074332__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_h2069d248__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_h522918a1__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_h16f80043__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0de6946a__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h96830c30__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_habf1dbc6__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h3e51b512__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_hfe8d6df7__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h52098261__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_ha601e8aa__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h8d9c622d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0ec378bd__0 = VL_RAND_RESET_I(26);
    vlSelf->__Vintraval_h980d62ca__0 = VL_RAND_RESET_I(31);
    vlSelf->__Vintraval_h288f6904__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h446b862c__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h6a1e9665__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h7580903f__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h7d279864__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h9149521c__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h41454575__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h8d88b19d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hb79ba5a7__0 = VL_RAND_RESET_I(31);
    vlSelf->__Vintraval_hbc85404f__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h687f4577__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hc507418f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hb609be6b__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h2fef74a4__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0147ab02__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h8dacc82d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hc50e960b__0 = VL_RAND_RESET_I(30);
    vlSelf->__Vintraval_h9120aac3__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_h660f1651__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h529de5b4__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h48cf7735__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_h028e5512__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h847109ab__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h3d92def3__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h85a368f0__0 = VL_RAND_RESET_I(4);
    vlSelf->__Vintraval_h87644f54__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h5f79f516__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h5d6336ab__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h394134f5__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h1fe3fd31__0 = VL_RAND_RESET_I(11);
    vlSelf->__Vintraval_hd4daff45__0 = VL_RAND_RESET_I(29);
    vlSelf->__Vintraval_h08760444__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h81796dad__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_h8af10f6e__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0c115ca0__0 = VL_RAND_RESET_I(31);
    vlSelf->__Vintraval_h612b37fc__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h5ff7a435__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h0c5b6a0f__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_hd62dc97d__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_ha60fe8f0__0 = VL_RAND_RESET_I(3);
    vlSelf->__Vintraval_h36f79a3a__0 = VL_RAND_RESET_I(5);
    vlSelf->__Vintraval_h3222a8d6__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vintraval_h1b3d3278__0 = VL_RAND_RESET_I(32);
    vlSelf->__Vintraval_h26795787__0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync1__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync1__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync1__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q__v1 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__n_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__n_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf_inc_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf_inc_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_frac_q__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q__v1 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_frac_q__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_flags_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_flags_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__busy_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__c_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__n_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__ops_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf_inc_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_valid_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__product_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__norm_flags_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_s_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_s_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q__v0 = VL_RAND_RESET_I(12);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_tail_cut_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_tail_cut_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_s_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_is_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p2_tail_cut_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_s_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_s_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_first_regime_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_first_regime_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_payload_seed_q__v0 = VL_RAND_RESET_I(29);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_payload_seed_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_s_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_is_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_cnt_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_first_regime_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__p1_payload_seed_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_s_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_s_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q__v0 = VL_RAND_RESET_I(12);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_tail_cut_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_tail_cut_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_s_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_is_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p2_tail_cut_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_s_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_s_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_first_regime_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_first_regime_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_payload_seed_q__v0 = VL_RAND_RESET_I(29);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_payload_seed_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_s_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_is_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_cnt_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_first_regime_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__p1_payload_seed_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_s_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_s_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_q__v0 = VL_RAND_RESET_I(12);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_lo_q__v0 = VL_RAND_RESET_I(14);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_lo_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_s_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_is_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p2_frac_lo_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_s_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_s_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_first_regime_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_first_regime_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_payload_seed_q__v0 = VL_RAND_RESET_I(29);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_payload_seed_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_s_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_is_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_cnt_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_first_regime_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__p1_payload_seed_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q__v1 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q__v0 = VL_RAND_RESET_I(13);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sign__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sign__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_cut__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_cut__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_valid__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_valid__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q__v0 = VL_RAND_RESET_I(12);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__limit_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__limit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_first__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_first__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_last__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_last__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_init__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_init__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_iteration__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_iteration__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_cut__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_cut__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q__v1 = VL_RAND_RESET_I(12);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q__v1 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q__v1 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q__v1 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_valid__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_valid__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_first__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_first__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_last__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_last__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_cut__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_cut__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_iteration__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_iteration__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_term__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_term__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__done_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__done_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__iterations_done_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__iterations_done_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__busy_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__y_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sign__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_sf__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_cut__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__emitting_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__fx_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__scale_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__count_q__v2 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__limit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_valid__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_first__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_last__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_init__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_scale__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_iteration__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t1_cut__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_valid__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_first__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_last__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_cut__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_iteration__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__t2_term__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__acc_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__iterations_done_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__approx_cut_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__done_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q__v0 = VL_RAND_RESET_I(32);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__sign_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p2_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__d_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__flags_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__sign_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q__v0 = VL_RAND_RESET_I(31);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q__v0 = VL_RAND_RESET_I(3);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_x_frac_q__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_x_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_flags_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_flags_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v1 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_x_frac_q__v0 = VL_RAND_RESET_I(26);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_x_frac_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_q__v0 = VL_RAND_RESET_I(31);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_tail_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_tail_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sub_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sub_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sf_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sf_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_both_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_both_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_flags_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_flags_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v2 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v2 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q__v0 = VL_RAND_RESET_I(31);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sf_inc_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sf_inc_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_tail_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_tail_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_both_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_both_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_flags_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_flags_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v3 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v3 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_q__v0 = VL_RAND_RESET_I(30);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sf_inc_q__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sf_inc_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_both_zero_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_both_zero_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q__v0 = VL_RAND_RESET_I(4);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v4 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v4 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sign__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sign__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_zero__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_zero__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_nar__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_nar__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf__v0 = VL_RAND_RESET_I(11);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q__v0 = VL_RAND_RESET_I(29);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sticky__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sticky__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_flags__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_flags__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__valid_q__v5 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_x_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_y_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_shift_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_clamped_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_nz_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sub_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_both_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s1_flags_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_x_frac_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_y_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_tail_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sub_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_sf_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_both_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s2_flags_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_mag_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sf_inc_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_tail_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_both_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s3_flags_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_seed_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_count_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nz_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sticky_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sf_inc_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_both_zero_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_nar_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__s4_flags_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sign__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_zero__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_nar__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sf__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__frac_hi_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_sticky__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__sum_flags__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__d_q__v0 = VL_RAND_RESET_I(32);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__d_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p2_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__d_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__flags_q__v1 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_valid_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_valid_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_mag_trunc_q__v0 = VL_RAND_RESET_I(31);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_mag_trunc_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_guard_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_guard_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_round_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_round_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sign_q__v0 = VL_RAND_RESET_I(1);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sign_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q__v0 = VL_RAND_RESET_I(3);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q__v0 = 0;
    vlSelf->__VdlyVal__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_q__v0 = VL_RAND_RESET_I(5);
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_q__v0 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_valid_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_mag_trunc_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_guard_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_round_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_sign_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_q__v1 = 0;
    vlSelf->__VdlySet__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_q__v1 = 0;
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2__0 = VL_RAND_RESET_I(1);
}
