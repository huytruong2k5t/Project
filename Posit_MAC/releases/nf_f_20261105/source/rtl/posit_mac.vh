//-----------------------------------------------------------------------------
// File          : posit_mac.vh
// Author(s)     : Dan Huy
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-01
//
// Description   : Top-level header file containing global defines and macros
//                 according to Digital Design Guidelines.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: $

`ifndef POSIT_MAC_VH
`define POSIT_MAC_VH

// Clock-to-Q delay for simulation models
`ifndef CK2Q
`define CK2Q #1
`endif

// Flags bit indices
`define FLAG_NAR         4
`define FLAG_SAT_MAX     3
`define FLAG_SAT_MIN     2
`define FLAG_INEXACT     1
`define FLAG_APPROX_CUT  0

`endif // POSIT_MAC_VH
