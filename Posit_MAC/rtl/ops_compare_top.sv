// OPS-only comparison. Identical registered boundaries for both policies.
// POLICY=0: reconstructed n=2 seven-bit predictor; POLICY=1: twelve-bit popcount.
module ops_compare_top #(parameter POLICY = 0) (
    input wire clk, input wire rst,
    input wire [11:0] fraction_a, input wire [11:0] fraction_b,
    output reg swap_o
);
    reg [11:0] a_q, b_q;
    wire swap_comb;
    function automatic [6:0] predict_error(input [6:0] f);
        begin
            case (f)
            7'd0: predict_error = 7'd0;
            7'd1: predict_error = 7'd0;
            7'd2: predict_error = 7'd0;
            7'd3: predict_error = 7'd1;
            7'd4: predict_error = 7'd0;
            7'd5: predict_error = 7'd1;
            7'd6: predict_error = 7'd2;
            7'd7: predict_error = 7'd1;
            7'd8: predict_error = 7'd0;
            7'd9: predict_error = 7'd1;
            7'd10: predict_error = 7'd2;
            7'd11: predict_error = 7'd3;
            7'd12: predict_error = 7'd4;
            7'd13: predict_error = 7'd3;
            7'd14: predict_error = 7'd2;
            7'd15: predict_error = 7'd1;
            7'd16: predict_error = 7'd0;
            7'd17: predict_error = 7'd1;
            7'd18: predict_error = 7'd2;
            7'd19: predict_error = 7'd3;
            7'd20: predict_error = 7'd4;
            7'd21: predict_error = 7'd5;
            7'd22: predict_error = 7'd6;
            7'd23: predict_error = 7'd7;
            7'd24: predict_error = 7'd8;
            7'd25: predict_error = 7'd7;
            7'd26: predict_error = 7'd6;
            7'd27: predict_error = 7'd5;
            7'd28: predict_error = 7'd4;
            7'd29: predict_error = 7'd3;
            7'd30: predict_error = 7'd2;
            7'd31: predict_error = 7'd1;
            7'd32: predict_error = 7'd0;
            7'd33: predict_error = 7'd1;
            7'd34: predict_error = 7'd2;
            7'd35: predict_error = 7'd3;
            7'd36: predict_error = 7'd4;
            7'd37: predict_error = 7'd5;
            7'd38: predict_error = 7'd6;
            7'd39: predict_error = 7'd7;
            7'd40: predict_error = 7'd8;
            7'd41: predict_error = 7'd9;
            7'd42: predict_error = 7'd10;
            7'd43: predict_error = 7'd11;
            7'd44: predict_error = 7'd12;
            7'd45: predict_error = 7'd13;
            7'd46: predict_error = 7'd14;
            7'd47: predict_error = 7'd15;
            7'd48: predict_error = 7'd16;
            7'd49: predict_error = 7'd15;
            7'd50: predict_error = 7'd14;
            7'd51: predict_error = 7'd13;
            7'd52: predict_error = 7'd12;
            7'd53: predict_error = 7'd11;
            7'd54: predict_error = 7'd10;
            7'd55: predict_error = 7'd9;
            7'd56: predict_error = 7'd8;
            7'd57: predict_error = 7'd7;
            7'd58: predict_error = 7'd6;
            7'd59: predict_error = 7'd5;
            7'd60: predict_error = 7'd4;
            7'd61: predict_error = 7'd3;
            7'd62: predict_error = 7'd2;
            7'd63: predict_error = 7'd1;
            7'd64: predict_error = 7'd0;
            7'd65: predict_error = 7'd1;
            7'd66: predict_error = 7'd2;
            7'd67: predict_error = 7'd3;
            7'd68: predict_error = 7'd4;
            7'd69: predict_error = 7'd5;
            7'd70: predict_error = 7'd6;
            7'd71: predict_error = 7'd7;
            7'd72: predict_error = 7'd8;
            7'd73: predict_error = 7'd9;
            7'd74: predict_error = 7'd10;
            7'd75: predict_error = 7'd11;
            7'd76: predict_error = 7'd12;
            7'd77: predict_error = 7'd13;
            7'd78: predict_error = 7'd14;
            7'd79: predict_error = 7'd15;
            7'd80: predict_error = 7'd16;
            7'd81: predict_error = 7'd15;
            7'd82: predict_error = 7'd14;
            7'd83: predict_error = 7'd13;
            7'd84: predict_error = 7'd12;
            7'd85: predict_error = 7'd11;
            7'd86: predict_error = 7'd10;
            7'd87: predict_error = 7'd9;
            7'd88: predict_error = 7'd8;
            7'd89: predict_error = 7'd7;
            7'd90: predict_error = 7'd6;
            7'd91: predict_error = 7'd5;
            7'd92: predict_error = 7'd4;
            7'd93: predict_error = 7'd3;
            7'd94: predict_error = 7'd2;
            7'd95: predict_error = 7'd1;
            7'd96: predict_error = 7'd0;
            7'd97: predict_error = 7'd1;
            7'd98: predict_error = 7'd2;
            7'd99: predict_error = 7'd3;
            7'd100: predict_error = 7'd4;
            7'd101: predict_error = 7'd5;
            7'd102: predict_error = 7'd6;
            7'd103: predict_error = 7'd7;
            7'd104: predict_error = 7'd8;
            7'd105: predict_error = 7'd7;
            7'd106: predict_error = 7'd6;
            7'd107: predict_error = 7'd5;
            7'd108: predict_error = 7'd4;
            7'd109: predict_error = 7'd3;
            7'd110: predict_error = 7'd2;
            7'd111: predict_error = 7'd1;
            7'd112: predict_error = 7'd0;
            7'd113: predict_error = 7'd1;
            7'd114: predict_error = 7'd2;
            7'd115: predict_error = 7'd3;
            7'd116: predict_error = 7'd4;
            7'd117: predict_error = 7'd3;
            7'd118: predict_error = 7'd2;
            7'd119: predict_error = 7'd1;
            7'd120: predict_error = 7'd0;
            7'd121: predict_error = 7'd1;
            7'd122: predict_error = 7'd2;
            7'd123: predict_error = 7'd1;
            7'd124: predict_error = 7'd0;
            7'd125: predict_error = 7'd1;
            7'd126: predict_error = 7'd1;
            7'd127: predict_error = 7'd1;
            default: predict_error = 7'd0;
            endcase
        end
    endfunction
    function automatic [3:0] popcount12(input [11:0] f);
        reg [1:0] g0,g1,g2,g3;
        reg [2:0] h0,h1;
        begin
            g0 = {1'b0,f[0]} + {1'b0,f[1]} + {1'b0,f[2]};
            g1 = {1'b0,f[3]} + {1'b0,f[4]} + {1'b0,f[5]};
            g2 = {1'b0,f[6]} + {1'b0,f[7]} + {1'b0,f[8]};
            g3 = {1'b0,f[9]} + {1'b0,f[10]} + {1'b0,f[11]};
            h0 = {1'b0,g0} + {1'b0,g1};
            h1 = {1'b0,g2} + {1'b0,g3};
            popcount12 = {1'b0,h0} + {1'b0,h1};
        end
    endfunction
    generate
        if (POLICY == 0) begin: g_predict
            assign swap_comb = predict_error(b_q[11:5]) < predict_error(a_q[11:5]);
        end else begin: g_minpop
            assign swap_comb = popcount12(b_q) < popcount12(a_q);
        end
    endgenerate
    always @(posedge clk) begin
        if (rst) begin a_q <= 0; b_q <= 0; swap_o <= 0; end
        else begin a_q <= fraction_a; b_q <= fraction_b; swap_o <= swap_comb; end
    end
endmodule
