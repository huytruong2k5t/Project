`timescale 1ns/1ps
module tb_week9_paper;
    logic [31:0] a,b;
    wire s_a,s_b,z_a,z_b,n_a,n_b;
    wire signed [10:0] sf_a,sf_b;
    wire [25:0] frac_a,frac_b;
    wire [12:0] mant_a,mant_b,x,y;
    logic force_a;
    wire [11:0] score_a,score_b;
    wire swapped;
    logic [12:0] mantissa;
    logic signed [7:0] exponent;
    logic neg,anchor;
    logic [13:0] acc;
    wire signed [7:0] power,exponent_next;
    wire [12:0] mantissa_next;
    wire negative_next,tail,error;
    wire [13:0] term,acc_next;
    logic [13:0] normalized;
    logic signed [10:0] sf_norm;
    wire [52:0] fraction;
    wire [31:0] result;
    wire [4:0] flags;
    wire sign;
    wire is_zero,is_nar;
    wire [4:0] flags_in;
    wire sticky;
    assign mant_a={1'b1,frac_a[25:14]};
    assign mant_b={1'b1,frac_b[25:14]};
    assign sign=s_a^s_b;
    assign fraction={normalized[11:0],41'b0};
    assign is_zero=1'b0;
    assign is_nar=1'b0;
    assign flags_in=5'b0;
    assign sticky=1'b0;
    posit_parser_comb #(.NB(32),.ES(3)) u_a (
        .p(a),.s(s_a),.is_zero(z_a),.is_nar(n_a),.sf(sf_a),.frac(frac_a)
    );
    posit_parser_comb #(.NB(32),.ES(3)) u_b (
        .p(b),.s(s_b),.is_zero(z_b),.is_nar(n_b),.sf(sf_b),.frac(frac_b)
    );
    paper_ops_comb u_ops (
        .mant_a(mant_a),.mant_b(mant_b),.force_a(force_a),.x_mant(x),.y_mant(y),
        .score_a(score_a),.score_b(score_b),.swapped(swapped)
    );
    paper_step_comb u_step (
        .mantissa(mantissa),.exponent(exponent),.negative_coefficient(neg),.anchor(anchor),
        .y_mant(y),.acc(acc),.power(power),.mantissa_next(mantissa_next),
        .exponent_next(exponent_next),.negative_next(negative_next),.term(term),
        .term_tail(tail),.acc_next(acc_next),.state_error(error)
    );
    posit_pack_comb #(.NB(32),.ES(3),.ROUND_MODE("TRUNC")) u_pack (
        .sign(sign),.is_zero(is_zero),.is_nar(is_nar),.sf(sf_norm),.frac(fraction),
        .sticky(sticky),.flags_in(flags_in),.d(result),.flags(flags)
    );
    always_comb begin
        normalized=acc_next;
        sf_norm=sf_a+sf_b+(anchor ? 11'sd1 : 11'sd0);
        for (int k=0;k<14;k++) begin
            if (normalized>=8192) begin
                normalized=normalized>>1;
                sf_norm=sf_norm+11'sd1;
            end else if (normalized!=0 && normalized<4096) begin
                normalized=normalized<<1;
                sf_norm=sf_norm-11'sd1;
            end
        end
    end
    initial begin
        int fd,rc,e_i,p_e,e_e,lut_fd,prefix,score_e,lut_rows;
        longint unsigned v[21:0];
        int rows, outputs,fig4;
        lut_fd=$fopen("paper_lut.txt","r");
        if(!lut_fd) $fatal(1,"missing PT2 table");
        lut_rows=0;
        force_a=0;
        while(!$feof(lut_fd)) begin
            rc=$fscanf(lut_fd,"%d %d\n",prefix,score_e);
            if(rc!=2) $fatal(1,"malformed PT2 table");
            a=32'h40000000 | (prefix<<19);
            b=a;
            #2;
            if(score_a!==score_e[11:0] || score_b!==score_e[11:0] || swapped!==0)
                $fatal(1,"PT2/tie mismatch prefix=%0d",prefix);
            lut_rows++;
        end
        $fclose(lut_fd);
        if(lut_rows!=128) $fatal(1,"incomplete PT2 table");
        $display("PAPER PT2 LUT PASS entries=%0d",lut_rows);
        fd=$fopen("paper.txt","r");
        if (!fd) $fatal(1,"missing paper fixture");
        rows=0; outputs=0; fig4=0;
        while (!$feof(fd)) begin
            rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h %d %d %h %h %h %h %d %h %h %h %h %h\n",
                v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],e_i,p_e,
                v[12],v[13],v[14],v[15],e_e,v[17],v[18],v[19],v[20],v[21]);
            if(rc!=22) $fatal(1,"malformed paper fixture");
            a=v[0][31:0]; b=v[1][31:0]; force_a=v[2][0]; mantissa=v[9][12:0];
            exponent=e_i[7:0]; neg=v[12][0]; anchor=v[13][0]; acc=v[14][13:0];
            #2;
            if (swapped!==v[3][0] || mant_a!==v[4][12:0] || mant_b!==v[5][12:0] ||
                y!==v[6][12:0] || score_a!==v[7][11:0] || score_b!==v[8][11:0] ||
                power!==p_e[7:0] || mantissa_next!==v[15][12:0] || exponent_next!==e_e[7:0] ||
                negative_next!==v[17][0] || acc_next!==v[18][13:0] || tail!==v[19][0] || error!==0)
                $fatal(1,"PAPER first mismatch commit=%0d a=%h b=%h acc=%h/%h m_next=%h/%h",
                    rows,a,b,acc_next,v[18],mantissa_next,v[15]);
            if(v[21][0]) begin
                if(result!==v[20][31:0]) $fatal(1,"PAPER output mismatch row=%0d got=%h exp=%h",rows,result,v[20]);
                outputs++;
                if(a==32'h1c900000 && b==32'h3c820000 && force_a) begin
                    if(result!==32'h1ae34000) $fatal(1,"Fig4 mismatch");
                    fig4++;
                end
            end
            rows++;
        end
        $fclose(fd);
        if(!fig4 || rows==0) $fatal(1,"incomplete paper fixture");
        $display("WEEK9 PAPER PASS commits=%0d outputs=%0d Fig4=%0d",rows,outputs,fig4);
        $finish;
    end
endmodule
