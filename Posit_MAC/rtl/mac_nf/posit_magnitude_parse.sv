//-----------------------------------------------------------------------------
// File          : posit_magnitude_parse.sv
// Author(s)     : Codex, for Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-05
// Description   : Combinational Posit decoder, SPEC 5.2 / Norris-Kim Fig.5(a).
// No clock, pipeline, rounding or approximate input truncation.
// Contract: NB>=4, NB<=32, 0<=ES<=NB-4; canonical Zero/NaR outputs.
// $Log: 2026-10-16: XOR-normalized tail shares one LOD; no interface change.
//-----------------------------------------------------------------------------
module posit_magnitude_parse (
    input logic [31:0] p,
    input logic sign_i,
    output wire s,
    output wire is_zero,
    output wire is_nar,
    output wire signed [10:0] sf,
    output wire [25:0] frac
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    // NB: 32 (original).
    localparam int NB = 32;
    // ES: 2 (original).
    localparam int ES = 3;
    // FRAC_MAX: NB-3-ES (original).
    localparam int FRAC_MAX = 26;
    // SF_W: $clog2(64'd4 * (longint'(NB) - 64'd2)*(64'd1<<ES)+64'd4)+1 (original).
    localparam int SF_W = 11;

    localparam int CNT_W=5; // $clog2(NB-1)
    localparam int REG_W=6; // CNT_W+1
    typedef logic [CNT_W-1:0] count_value_t;
    localparam logic [CNT_W-1:0] MAX_COUNT = count_value_t'(NB-2);
    if(NB<4 || NB>32 || ES<0 || ES>NB-4 || FRAC_MAX!=NB-3-ES || SF_W<REG_W+ES)
        begin : g_invalid
            initial $fatal(1,"posit_parser_comb: unsupported parameters");
        end
    typedef logic signed [SF_W-1:0] sf_value_t;
    wire [NB-1:0] magnitude;
    wire r;
    wire [NB-3:0] terminator_bits;
    wire [CNT_W-1:0] terminator_count;
    wire [CNT_W-1:0] cnt;
    wire terminator_valid;
    wire signed [REG_W-1:0] regime;
    wire [NB-4:0] payload;
    wire signed [SF_W-1:0] finite_sf;
    assign s = is_nar || (!is_zero && sign_i);
    assign is_zero=(p=={NB{1'b0}});
    assign is_nar=(p=={1'b1,{(NB-1){1'b0}}});
    assign magnitude = p;
    assign r=magnitude[NB-2];
    // Exclude the first regime bit; XOR maps either terminator polarity to 1.
    // Keep the original magnitude on the exponent/fraction payload path.
    assign terminator_bits = magnitude[NB-3:0] ^ {(NB-2){r}};

    lod_lzd_core  u_regime_detector (
        .in  (terminator_bits),
        .K   (terminator_count),
        .vld (terminator_valid)
    );

    // The detector returns K=0 on invalid; parser no-terminator means NB-2.
    assign cnt = terminator_valid ? terminator_count : MAX_COUNT;
    // r=1: k=cnt; r=0: k=~{0,cnt}=-(cnt+1).
    assign regime=~({1'b0,cnt}^{REG_W{r}});
    // Drop sign, FRB and one more bit BEFORE the variable shift.
    // This equals shift rest by cnt, then drop the terminator (L1 formulation).
    dyn_left_shifter  align_payload(
        .in(magnitude[NB-4:0]),.b(cnt),.out(payload));
    if(ES==0) begin:g_es0
        assign finite_sf=sf_value_t'(regime);
    end else begin:g_exponent
        wire [ES-1:0] exponent=payload[NB-4 -: ES];
        // Signed concatenation: k*2^ES+e. Assignment sign extends to SF_W.
        assign finite_sf=sf_value_t'($signed({regime,exponent}));
    end
    assign sf=(is_zero || is_nar)?{SF_W{1'b0}}:finite_sf;
    // Hidden bit omitted; variable fraction length is already zero-padded at LSB.
    assign frac=(is_zero || is_nar)?{FRAC_MAX{1'b0}}:payload[FRAC_MAX-1:0];
endmodule
