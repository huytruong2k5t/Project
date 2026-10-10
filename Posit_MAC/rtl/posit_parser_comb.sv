//-----------------------------------------------------------------------------
// File          : posit_parser_comb.sv
// Author(s)     : Codex, for Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-05
// Description   : Combinational Posit decoder, SPEC 5.2 / Norris-Kim Fig.5(a).
// No clock, pipeline, rounding or approximate input truncation.
// Contract: NB>=4, NB<=32, 0<=ES<=NB-4; canonical Zero/NaR outputs.
//-----------------------------------------------------------------------------
module posit_parser_comb #(
    parameter int NB=32,
    parameter int ES=2,
    parameter int FRAC_MAX=NB-3-ES,
    parameter int SF_W=$clog2(64'd4 * (longint'(NB) - 64'd2)*(64'd1<<ES)+64'd4)+1
)(
    input logic [NB-1:0] p,
    output wire s,
    output wire is_zero,
    output wire is_nar,
    output wire signed [SF_W-1:0] sf,
    output wire [FRAC_MAX-1:0] frac
);
    localparam int CNT_W=$clog2(NB-1);
    localparam int REG_W=CNT_W+1;
    typedef logic [CNT_W-1:0] count_value_t;
    localparam logic [CNT_W-1:0] MAX_COUNT = count_value_t'(NB-2);
    if(NB<4 || NB>32 || ES<0 || ES>NB-4 || FRAC_MAX!=NB-3-ES || SF_W<REG_W+ES)
        begin : g_invalid
            initial $fatal(1,"posit_parser_comb: unsupported parameters");
        end
    typedef logic signed [SF_W-1:0] sf_value_t;
    wire [NB-1:0] magnitude;
    wire r;
    wire [CNT_W-1:0] lod_count,lzd_count,cnt;
    wire lod_valid,lzd_valid;
    wire signed [REG_W-1:0] regime;
    wire [NB-4:0] payload;
    wire signed [SF_W-1:0] finite_sf;
    assign s=p[NB-1];
    assign is_zero=(p=={NB{1'b0}});
    assign is_nar=(p=={1'b1,{(NB-1){1'b0}}});
    assign magnitude=s?(~p+{{(NB-1){1'b0}},1'b1}):p;
    assign r=magnitude[NB-2];
    // Detector positions count repeated regime bits AFTER the first regime bit.
    lod_lzd_core #(.N(NB-2),.MODE(0),.S(CNT_W)) lod(
        .in(magnitude[NB-3:0]),.K(lod_count),.vld(lod_valid));
    lod_lzd_core #(.N(NB-2),.MODE(1),.S(CNT_W)) lzd(
        .in(magnitude[NB-3:0]),.K(lzd_count),.vld(lzd_valid));
    assign cnt=r?(lzd_valid?lzd_count:MAX_COUNT):
                 (lod_valid?lod_count:MAX_COUNT);
    // r=1: k=cnt; r=0: k=~{0,cnt}=-(cnt+1).
    assign regime=~({1'b0,cnt}^{REG_W{r}});
    // Drop sign, FRB and one more bit BEFORE the variable shift.
    // This equals shift rest by cnt, then drop the terminator (L1 formulation).
    dyn_left_shifter #(.N(NB-3),.SHIFT_W(CNT_W)) align_payload(
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
