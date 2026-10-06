`timescale 1ns/1ps
// Parameter regression: per-bit mathematical oracle, independent of MUX cascade.
module dyn_shifter_parameter_check #(parameter int N=27, W=3)(output bit done=0);
    logic [N-1:0] data,left_out,right_zero,right_fill,right_arith;
    logic [W-1:0] amount;
    logic fill;
    dyn_left_shifter #(.N(N),.SHIFT_W(W)) dl(data,amount,left_out);
    dyn_right_shifter #(.N(N),.SHIFT_W(W)) dz(data,amount,1'b0,right_zero);
    dyn_right_shifter #(.N(N),.SHIFT_W(W)) df(data,amount,fill,right_fill);
    // Vary fill_val even in ARITH mode: it must be ignored.
    dyn_right_shifter #(.N(N),.SHIFT_W(W),.ARITH(1)) da(data,amount,fill,right_arith);
    function automatic [N-1:0] oracle(input bit left,input logic pad);
        logic [N-1:0] value;
        int index;
        for(int j=0;j<N;j++) begin
            index=left?j-int'(amount):j+int'(amount);
            value[j]=(index>=0 && index<N)?data[index]:(left?1'b0:pad);
        end
        return value;
    endfunction
    initial begin
        int seed,seeded,patterns;
        longint unsigned comparisons;
        if(!$value$plusargs("SEED=%d",seed)) seed=20261004;
        seed=seed+N*100+W;seeded=$urandom(seed);comparisons=0;
        patterns=(N<=8)?(1<<N):500;
        for(int p=0;p<patterns;p++) begin
            if(N<=8) data=p;
            else case(p%8)
                0:data='0;
                1:data='1;
                2:data=64'haaaaaaaaaaaaaaaa;
                3:data=64'h5555555555555555;
                4:data=64'h1<<(p%N);
                5:data=~(64'h1<<(p%N));
                default:data={$urandom,$urandom};
            endcase
            for(int f=0;f<2;f++) for(int sh=0;sh<(1<<W);sh++) begin
                fill=f;amount=sh;#1;
                if(left_out!==oracle(1,0) || right_zero!==oracle(0,0) ||
                   right_fill!==oracle(0,fill) || right_arith!==oracle(0,data[N-1]))
                    $fatal(1,"PARAM FAIL N=%0d W=%0d data=%h shift=%0d fill=%b",N,W,data,sh,fill);
                comparisons+=4;
            end
        end
        $display("PARAM PASS N=%0d SHIFT_W=%0d comparisons=%0d",N,W,comparisons);
        done=1;
    end
endmodule

module tb_dyn_shifter_parameters;
    wire [26:0] done;
    function automatic int width_at(input int i);
        case(i)
            0:return 1;1:return 2;2:return 3;3:return 8;4:return 27;
            5:return 31;6:return 32;7:return 33;default:return 64;
        endcase
    endfunction
    for(genvar i=0;i<9;i++) begin:g_width
        localparam int N=width_at(i),S=(N>1)?$clog2(N):1;
        for(genvar j=0;j<3;j++) begin:g_shift
            localparam int W=(j==0)?((S>1)?S-1:1):((j==1)?S:S+1);
            dyn_shifter_parameter_check #(.N(N),.W(W)) check_config(done[i*3+j]);
        end
    end
    initial begin
        wait(&done);
        $display("PARAMETER_MATRIX PASS configurations=27");$finish;
    end
    initial begin
        #1000000;$fatal(1,"parameter regression timeout");
    end
endmodule
