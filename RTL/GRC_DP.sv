module GRC_DP (

    input logic SYS_CLOCK,
    input logic DP_ARESET,

    input logic [`DATA_WIDTH-1:0] M_IN,
    input logic [`DATA_WIDTH-1:0] N_IN,

    input logic       MN_LOAD,
    input logic       COMPUTE_LOAD,
    input logic       T_SEL,
    input logic       T_LOAD,
    input logic [2:0] U_SEL,
    input logic       U_LOAD,
    input logic       OUT_LOAD,

    output logic R_LT_X1,
    output logic Q_EQ_0,
    output logic Q_EQ_1,
    output logic Q_EQ_2,
    output logic Q_EQ_3,
    output logic Q_EQ_4,
    output logic Q_EQ_5,
    output logic Q_EQ_6,

    output logic [`OUT_WIDTH-1:0] OUT_CODE,
    output logic [`LEN_WIDTH-1:0] OUT_LEN

);

//====================================================
// Input Registers
//====================================================

logic [`DATA_WIDTH-1:0] M_REG, N_REG;

always_ff @(posedge SYS_CLOCK or posedge DP_ARESET)
begin : INPUT_REGISTERS
    if (DP_ARESET) begin
        M_REG <= '0;
        N_REG <= '0;
    end else if (MN_LOAD) begin
        M_REG <= M_IN;
        N_REG <= N_IN;
    end
end : INPUT_REGISTERS

//====================================================
// Q=m/n, r=m-q*n, X=ceil(log2(n)), x1=2^X-n
//====================================================

function automatic logic [`X_WIDTH-1:0] clog2_f(input logic [`DATA_WIDTH-1:0] val);
    logic [`DATA_WIDTH-1:0] v;
    int i;
    begin
        clog2_f = '0;
        v = val - 1'b1;
        for (i = 0; i < `DATA_WIDTH; i++) begin
            if (v[i])
                clog2_f = i[`X_WIDTH-1:0] + 1'b1;
        end
    end
endfunction

logic [`DATA_WIDTH-1:0] Q_COMB, R_COMB, X1_COMB;
logic [`X_WIDTH-1:0]    X_COMB;

always_comb begin
    Q_COMB  = (N_REG != 0) ? (M_REG / N_REG) : '0;
    R_COMB  = (N_REG != 0) ? (M_REG - Q_COMB * N_REG) : '0;
    X_COMB  = clog2_f(N_REG);
    X1_COMB = (`DATA_WIDTH'(1) << X_COMB) - N_REG;
end

logic [`DATA_WIDTH-1:0] Q_REG, R_REG, X1_REG;
logic [`X_WIDTH-1:0]    X_REG;

always_ff @(posedge SYS_CLOCK or posedge DP_ARESET)
begin : COMPUTE_REGISTERS
    if (DP_ARESET) begin
        Q_REG  <= '0;
        R_REG  <= '0;
        X_REG  <= '0;
        X1_REG <= '0;
    end else if (COMPUTE_LOAD) begin
        Q_REG  <= Q_COMB;
        R_REG  <= R_COMB;
        X_REG  <= X_COMB;
        X1_REG <= X1_COMB;
    end
end : COMPUTE_REGISTERS

assign R_LT_X1 = (R_REG < X1_REG);

assign Q_EQ_0 = (Q_REG == 16'd0);
assign Q_EQ_1 = (Q_REG == 16'd1);
assign Q_EQ_2 = (Q_REG == 16'd2);
assign Q_EQ_3 = (Q_REG == 16'd3);
assign Q_EQ_4 = (Q_REG == 16'd4);
assign Q_EQ_5 = (Q_REG == 16'd5);
assign Q_EQ_6 = (Q_REG == 16'd6);

//====================================================
// t = r  or  t = r + x1   (truncated binary code, X or X-1 bits)
//====================================================

logic [`DATA_WIDTH-1:0] T_REG;
logic [`X_WIDTH-1:0]    T_LEN_REG;

always_ff @(posedge SYS_CLOCK or posedge DP_ARESET)
begin : T_REGISTER
    if (DP_ARESET) begin
        T_REG     <= '0;
        T_LEN_REG <= '0;
    end else if (T_LOAD) begin
        // T_SEL = R_LT_X1: true  -> short code, t=r,     length X-1
        //                  false -> long code,  t=r+x1,  length X
        T_REG     <= T_SEL ? R_REG : (R_REG + X1_REG);
        T_LEN_REG <= T_SEL ? (X_REG - 1'b1) : X_REG;
    end
end : T_REGISTER

//====================================================
// u = unary code of q, capped at 8 bits (no terminator) for q >= 7
//====================================================

function automatic logic [`U_WIDTH-1:0] unary_code_f(input logic [2:0] sel);
    case (sel)
        3'd0: unary_code_f = 8'b0000_0000;  // "0"
        3'd1: unary_code_f = 8'b0000_0010;  // "10"
        3'd2: unary_code_f = 8'b0000_0110;  // "110"
        3'd3: unary_code_f = 8'b0000_1110;  // "1110"
        3'd4: unary_code_f = 8'b0001_1110;  // "11110"
        3'd5: unary_code_f = 8'b0011_1110;  // "111110"
        3'd6: unary_code_f = 8'b0111_1110;  // "1111110"
        3'd7: unary_code_f = 8'b1111_1111;  // capped, q>=7, no terminator
        default: unary_code_f = 8'b0000_0000;
    endcase
endfunction

function automatic logic [3:0] unary_len_f(input logic [2:0] sel);
    case (sel)
        3'd0: unary_len_f = 4'd1;
        3'd1: unary_len_f = 4'd2;
        3'd2: unary_len_f = 4'd3;
        3'd3: unary_len_f = 4'd4;
        3'd4: unary_len_f = 4'd5;
        3'd5: unary_len_f = 4'd6;
        3'd6: unary_len_f = 4'd7;
        3'd7: unary_len_f = 4'd8;
        default: unary_len_f = 4'd1;
    endcase
endfunction

logic [`U_WIDTH-1:0] U_REG;
logic [3:0]         U_LEN_REG;

always_ff @(posedge SYS_CLOCK or posedge DP_ARESET)
begin : U_REGISTER
    if (DP_ARESET) begin
        U_REG     <= '0;
        U_LEN_REG <= '0;
    end else if (U_LOAD) begin
        U_REG     <= unary_code_f(U_SEL);
        U_LEN_REG <= unary_len_f(U_SEL);
    end
end : U_REGISTER

//====================================================
// Out = {u, t}, packed to its true (variable) bit length
//====================================================

logic [`OUT_WIDTH-1:0] u_ext, t_ext, mask;

always_comb begin
    u_ext = {{(`OUT_WIDTH-`U_WIDTH){1'b0}}, U_REG};
    t_ext = {{(`OUT_WIDTH-`DATA_WIDTH){1'b0}}, T_REG};
    mask  = (`OUT_WIDTH'(1) << T_LEN_REG) - 1'b1;
end

always_ff @(posedge SYS_CLOCK or posedge DP_ARESET)
begin : OUT_REGISTER
    if (DP_ARESET) begin
        OUT_CODE <= '0;
        OUT_LEN  <= '0;
    end else if (OUT_LOAD) begin
        // u occupies the high bits, t (masked to its own length) the low bits
        OUT_CODE <= (u_ext << T_LEN_REG) | (t_ext & mask);
        OUT_LEN  <= `LEN_WIDTH'(U_LEN_REG) + `LEN_WIDTH'(T_LEN_REG);
    end
end : OUT_REGISTER

endmodule : GRC_DP
