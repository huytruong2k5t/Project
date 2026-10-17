module tb_opt09_product #(parameter int CASES=100000);
    wire [7:0] done;
    opt09_product_checker #(.NB(8),.ES(0),.CASES(CASES)) u_8r(.done(done[0]));
    opt09_product_checker #(.NB(16),.ES(1),.CASES(CASES)) u_16r(.done(done[1]));
    opt09_product_checker #(.NB(32),.ES(2),.CASES(CASES)) u_32r(.done(done[2]));
    opt09_product_checker #(.NB(32),.ES(3),.CASES(CASES)) u_33r(.done(done[3]));
    opt09_product_checker #(.NB(8),.ES(0),.CASES(CASES),.ROUND_MODE("TRUNC")) u_8t(.done(done[4]));
    opt09_product_checker #(.NB(16),.ES(1),.CASES(CASES),.ROUND_MODE("TRUNC")) u_16t(.done(done[5]));
    opt09_product_checker #(.NB(32),.ES(2),.CASES(CASES),.ROUND_MODE("TRUNC")) u_32t(.done(done[6]));
    opt09_product_checker #(.NB(32),.ES(3),.CASES(CASES),.ROUND_MODE("TRUNC")) u_33t(.done(done[7]));
    initial begin
        wait (&done);
        $display("PRODUCT MATRIX PASS mismatches=0");
        $finish;
    end
endmodule
