`timescale 1ns/1ps
module parser_vector_checker #(parameter int NB=8,ES=0)(output bit done=0);
    localparam int F=NB-3-ES,SW=$clog2(4*((NB-2)*(1<<ES))+4)+1;
    logic [NB-1:0] p;
    wire s,zero,nar;wire signed [SW-1:0] sf;wire [F-1:0] frac;
    posit_parser_comb #(.NB(NB),.ES(ES)) dut(
        .p(p),.s(s),.is_zero(zero),.is_nar(nar),.sf(sf),.frac(frac));
    initial begin
        string filename;int fd,read_count,sign_exp,zero_exp,nar_exp,sf_exp;
        logic [NB-1:0] p_exp;logic [F-1:0] frac_exp;
        logic signed [SW-1:0] sf_bits_exp;
        longint unsigned checks;
        filename=$sformatf("parser_%0d_%0d.txt",NB,ES);
        fd=$fopen(filename,"r");if(!fd) $fatal(1,"missing fixture %s",filename);
        checks=0;
        while(!$feof(fd)) begin
            read_count=$fscanf(fd,"%h %d %d %d %d %h\n",p_exp,sign_exp,zero_exp,nar_exp,sf_exp,frac_exp);
            if(read_count!=6) $fatal(1,"malformed fixture %s read=%0d",filename,read_count);
            sf_bits_exp=sf_exp;
            p=p_exp;#1;
            if(s!==sign_exp[0] || zero!==zero_exp[0] || nar!==nar_exp[0] ||
               sf!==sf_bits_exp || frac!==frac_exp)
                $fatal(1,"PARSER FAIL NB=%0d ES=%0d p=%h got s/z/n=%b%b%b sf=%0d f=%h expected=%0d/%0d/%0d sf=%0d f=%h",
                    NB,ES,p,s,zero,nar,sf,frac,sign_exp,zero_exp,nar_exp,sf_exp,frac_exp);
            ++checks;
            if(checks%100000==0) $display("CHECKPOINT NB=%0d ES=%0d checks=%0d",NB,ES,checks);
        end
        $fclose(fd);
        if((NB==8 && checks!=256) || (NB==16 && checks!=65536) || (NB==32 && checks!=1200010))
            $fatal(1,"incomplete fixture NB=%0d ES=%0d checks=%0d",NB,ES,checks);
        $display("PARSER PASS NB=%0d ES=%0d checks=%0d",NB,ES,checks);done=1;
    end
endmodule
module tb_posit_parser_comb;
    wire [3:0] done;
    parser_vector_checker #(.NB(8),.ES(0)) p8(done[0]);
    parser_vector_checker #(.NB(16),.ES(1)) p16(done[1]);
    parser_vector_checker #(.NB(32),.ES(2)) p32e2(done[2]);
    parser_vector_checker #(.NB(32),.ES(3)) p32e3(done[3]);
    initial begin wait(&done);$display("PARSER_COMB ALL PASS");$finish;end
    initial begin #2000000;$fatal(1,"parser timeout");end
endmodule
