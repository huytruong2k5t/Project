module tb_opt10a_prepare;
    wire [7:0] done;
    opt10a_prepare_checker #(.NB(4),.ES(0),.FIN(3)) u_0(.done(done[0]));
    opt10a_prepare_checker #(.NB(5),.ES(1),.FIN(3)) u_1(.done(done[1]));
    opt10a_prepare_checker #(.NB(8),.ES(0),.FIN(11)) u_2(.done(done[2]));
    opt10a_prepare_checker #(.NB(16),.ES(1),.FIN(25)) u_3(.done(done[3]));
    opt10a_prepare_checker #(.NB(32),.ES(2),.FIN(55)) u_4(.done(done[4]));
    opt10a_prepare_checker #(.NB(32),.ES(3),.FIN(53)) u_5(.done(done[5]));
    opt10a_prepare_checker #(.NB(17),.ES(5),.FIN(11)) u_6(.done(done[6]));
    opt10a_prepare_checker #(.NB(17),.ES(5),.FIN(63)) u_7(.done(done[7]));
    initial begin wait (&done); $display("PREPARE MATRIX PASS mismatches=0"); $finish; end
endmodule
