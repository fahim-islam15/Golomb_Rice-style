module GRC_FSM (

    input logic SYS_CLOCK,
    input logic FSM_ARESET,

    input logic START,

    input logic R_LT_X1,
    input logic Q_EQ_0,
    input logic Q_EQ_1,
    input logic Q_EQ_2,
    input logic Q_EQ_3,
    input logic Q_EQ_4,
    input logic Q_EQ_5,
    input logic Q_EQ_6,

    output logic       MN_LOAD,
    output logic       COMPUTE_LOAD,
    output logic       T_SEL,
    output logic       T_LOAD,
    output logic [2:0] U_SEL,
    output logic       U_LOAD,
    output logic       OUT_LOAD,
    output logic       DONE

);

//====================================================
// State Variables
//====================================================

logic [`STATE_WIDTH-1:0] P_STATE, N_STATE;

// One state per ASM-chart box
localparam logic [`STATE_WIDTH-1:0]
    S_IDLE    = 5'b00000,  // Start
    S_INPUT   = 5'b00001,  // Input m, n
    S_COMPUTE = 5'b00010,  // Q=m/n, r=m-q*n, X=log2(n), x1=2^X-n
    S_COMPARE = 5'b00011,  // If r < x1
    S_TSET    = 5'b00100,  // t=r  or  t=r+x1
    S_Q0      = 5'b00101,  // If q=0  -> U=0
    S_Q1      = 5'b00110,  // If q=1  -> U=10
    S_Q2      = 5'b00111,  // If q=2  -> U=110
    S_Q3      = 5'b01000,  // If q=3  -> U=1110
    S_Q4      = 5'b01001,  // If q=4  -> U=11110
    S_Q5      = 5'b01010,  // If q=5  -> U=111110
    S_Q6      = 5'b01011,  // If q=6  -> U=1111110
    S_UMAX    = 5'b01100,  // q>=7 (capped) -> U=11111111
    S_OUTPUT  = 5'b01101,  // Out = {u,t}  (OUT_CODE register captures on the way out of this state)
    S_DONE    = 5'b01110;  // OUT_CODE is now valid -> assert DONE

//====================================================
// NEXT STATE LOGIC
//====================================================

always_comb begin : NEXT_STATE_LOGIC

    N_STATE = P_STATE;

    case (P_STATE)

        S_IDLE:
            N_STATE = START ? S_INPUT : S_IDLE;

        S_INPUT:
            N_STATE = S_COMPUTE;

        S_COMPUTE:
            N_STATE = S_COMPARE;

        S_COMPARE:
            N_STATE = S_TSET;

        S_TSET:
            N_STATE = S_Q0;

        S_Q0:
            N_STATE = Q_EQ_0 ? S_OUTPUT : S_Q1;

        S_Q1:
            N_STATE = Q_EQ_1 ? S_OUTPUT : S_Q2;

        S_Q2:
            N_STATE = Q_EQ_2 ? S_OUTPUT : S_Q3;

        S_Q3:
            N_STATE = Q_EQ_3 ? S_OUTPUT : S_Q4;

        S_Q4:
            N_STATE = Q_EQ_4 ? S_OUTPUT : S_Q5;

        S_Q5:
            N_STATE = Q_EQ_5 ? S_OUTPUT : S_Q6;

        S_Q6:
            N_STATE = Q_EQ_6 ? S_OUTPUT : S_UMAX;

        S_UMAX:
            N_STATE = S_OUTPUT;

        S_OUTPUT:
            N_STATE = S_DONE;

        S_DONE:
            N_STATE = S_IDLE;

        default:
            N_STATE = S_IDLE;

    endcase

end : NEXT_STATE_LOGIC

//====================================================
// OUTPUT LOGIC
//====================================================

always_comb begin : OUTPUT_LOGIC

    // Default values
    MN_LOAD      = 0;
    COMPUTE_LOAD = 0;
    T_SEL        = 0;
    T_LOAD       = 0;
    U_SEL        = 3'd0;
    U_LOAD       = 0;
    OUT_LOAD     = 0;
    DONE         = 0;

    case (P_STATE)

        // Input m, n
        S_INPUT: begin
            MN_LOAD = 1;
        end

        // Q=m/n, r=m-q*n, X=log2(n), x1=2^X-n
        S_COMPUTE: begin
            COMPUTE_LOAD = 1;
        end

        // t=r or t=r+x1
        S_TSET: begin
            T_SEL  = R_LT_X1;
            T_LOAD = 1;
        end

        // Unary-code ladder for q
        S_Q0: begin
            U_SEL  = 3'd0;
            U_LOAD = Q_EQ_0;
        end

        S_Q1: begin
            U_SEL  = 3'd1;
            U_LOAD = Q_EQ_1;
        end

        S_Q2: begin
            U_SEL  = 3'd2;
            U_LOAD = Q_EQ_2;
        end

        S_Q3: begin
            U_SEL  = 3'd3;
            U_LOAD = Q_EQ_3;
        end

        S_Q4: begin
            U_SEL  = 3'd4;
            U_LOAD = Q_EQ_4;
        end

        S_Q5: begin
            U_SEL  = 3'd5;
            U_LOAD = Q_EQ_5;
        end

        S_Q6: begin
            U_SEL  = 3'd6;
            U_LOAD = Q_EQ_6;
        end

        // q >= 7, capped unary code
        S_UMAX: begin
            U_SEL  = 3'd7;
            U_LOAD = 1;
        end

        // Out = {u,t}
        S_OUTPUT: begin
            OUT_LOAD = 1;
        end

        // OUT_CODE register is now valid
        S_DONE: begin
            DONE = 1;
        end

        default: ;

    endcase

end : OUTPUT_LOGIC

//====================================================
// PRESENT STATE REGISTER
//====================================================

always_ff @(posedge SYS_CLOCK or posedge FSM_ARESET)
begin : PRESENT_STATE_REGISTER

    if (FSM_ARESET)
        P_STATE <= S_IDLE;
    else
        P_STATE <= N_STATE;

end : PRESENT_STATE_REGISTER

endmodule : GRC_FSM
