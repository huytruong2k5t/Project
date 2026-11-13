// Compact exact signed term descriptor; grid2^-480, FULL_TERM26/Q24.
module quire_align_comb (
    input logic [25:0] magnitude,
    input logic sign,
    input logic signed [10:0] sf,
    output logic [26:0] coefficient,
    output logic [4:0] word_index,
    output logic [5:0] bit_offset,
    output logic align_error
);
    logic signed [11:0] shift_amount;
    logic [25:0] aligned_magnitude;
    logic [25:0] discarded_mask;
    logic [9:0] positive_shift;
    always_comb begin
        shift_amount = {sf[10],sf} + 12'sd456;
        aligned_magnitude = magnitude;
        discarded_mask = '0;
        positive_shift = '0;
        align_error = 1'b0;
        if (magnitude != 26'b0) begin
            if (shift_amount < 0) begin
                if (shift_amount <= -12'sd26) align_error = 1'b1;
                else begin
                    discarded_mask = ~(26'h3ffffff << (-shift_amount));
                    align_error = |(magnitude & discarded_mask);
                    aligned_magnitude = magnitude >> (-shift_amount);
                end
            end else if (shift_amount > 12'sd945) align_error = 1'b1;
            else positive_shift = shift_amount[9:0];
        end
        coefficient = sign ? (~{1'b0,aligned_magnitude} + 27'd1)
                           : {1'b0,aligned_magnitude};
        word_index = 5'(positive_shift / 10'd36);
        bit_offset = 6'(positive_shift % 10'd36);
        if (align_error) coefficient = '0;
    end
endmodule
