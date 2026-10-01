module GRC_TOP (

    input logic SYS_CLOCK,
    input logic ARESET,

    input logic                  START,
    input logic [`DATA_WIDTH-1:0] M_IN,
    input logic [`DATA_WIDTH-1:0] N_IN,

    output logic [`OUT_WIDTH-1:0] OUT_CODE,
    output logic [`LEN_WIDTH-1:0] OUT_LEN,
    output logic                 DONE

);

logic       MN_LOAD, COMPUTE_LOAD, T_SEL, T_LOAD, U_LOAD, OUT_LOAD;
logic [2:0] U_SEL;
logic       R_LT_X1;
logic       Q_EQ_0, Q_EQ_1, Q_EQ_2, Q_EQ_3, Q_EQ_4, Q_EQ_5, Q_EQ_6;

GRC_FSM u_FSM (
    .SYS_CLOCK    (SYS_CLOCK),
    .FSM_ARESET   (ARESET),
    .START        (START),
    .R_LT_X1      (R_LT_X1),
    .Q_EQ_0       (Q_EQ_0),
    .Q_EQ_1       (Q_EQ_1),
    .Q_EQ_2       (Q_EQ_2),
    .Q_EQ_3       (Q_EQ_3),
    .Q_EQ_4       (Q_EQ_4),
    .Q_EQ_5       (Q_EQ_5),
    .Q_EQ_6       (Q_EQ_6),
    .MN_LOAD      (MN_LOAD),
    .COMPUTE_LOAD (COMPUTE_LOAD),
    .T_SEL        (T_SEL),
    .T_LOAD       (T_LOAD),
    .U_SEL        (U_SEL),
    .U_LOAD       (U_LOAD),
    .OUT_LOAD     (OUT_LOAD),
    .DONE         (DONE)
);

GRC_DP u_DP (
    .SYS_CLOCK    (SYS_CLOCK),
    .DP_ARESET    (ARESET),
    .M_IN         (M_IN),
    .N_IN         (N_IN),
    .MN_LOAD      (MN_LOAD),
    .COMPUTE_LOAD (COMPUTE_LOAD),
    .T_SEL        (T_SEL),
    .T_LOAD       (T_LOAD),
    .U_SEL        (U_SEL),
    .U_LOAD       (U_LOAD),
    .OUT_LOAD     (OUT_LOAD),
    .R_LT_X1      (R_LT_X1),
    .Q_EQ_0       (Q_EQ_0),
    .Q_EQ_1       (Q_EQ_1),
    .Q_EQ_2       (Q_EQ_2),
    .Q_EQ_3       (Q_EQ_3),
    .Q_EQ_4       (Q_EQ_4),
    .Q_EQ_5       (Q_EQ_5),
    .Q_EQ_6       (Q_EQ_6),
    .OUT_CODE     (OUT_CODE),
    .OUT_LEN      (OUT_LEN)
);

endmodule : GRC_TOP
