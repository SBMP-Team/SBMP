module CPU
(
    input logic btnA;
    input logic btnB;
    input logic btnUp;
    input logic btnDown;
    input logic btnLeft;
    input logic btnRight;
    input logic btnStart;
    input logic rst;
    input logic clk;
)
    //MEMORY
    logic [15:0] memory [0:65535];
    
    logic [15:0] pc;
    logic [15:0] ir;
    logic [5:0] opcode;
    logic [1:0] flags;
    logic [15:0] operand;
    assign opcode = ir[24:18];
    assign flags = ir[17:16];
    assign operand = ir[15:0];

    //ALU
    logic [15:0] alu_A, alu_b, alu_out;
    logic [3:0] alu_op;
    ALU alu (
        .a(alu_A),
        .b(alu_b),
        .op(alu_op),
        .out(alu_out)
    );
    typedef enum logic [1:0]{
        FETCH,
        EXECUTE
    } state_t;
    typedef enum logic [5:0]{
        //no op
        NOP,
        //reset
        RST,
        //load
        LDA,
        LDB,
        LDC,
        LDX,
        LDY,
        //store
        STA,
        STB,
        STC,
        STX,
        STY,
        STZ,
        //add
        ADA,
        ADB,
        ADC,
        ADX,
        ADY,
        //subtract
        SBA,
        SBB,
        SBC,
        SBX,
        SBY,
        //divide
        DVA,
        DVB,
        DVC,
        DVX,
        DVY,
        //modulo
        MDA,
        MDB,
        MDC,
        MDX,
        MDY,
        //multiply
        MXA,
        MXB,
        MXC,
        MXX,
        MXY,
        //iteration
        CLI,
        ITR,
        //branching
        BIZ,
        BIO,
        JMP,
        //audio
        ADN,
        ADW,
        //extras
        LAC
    } opcode_t;
    typedef enum logic [1:0]{
        REGULAR_BINARY,
        REGULAR_REGISTER,
        JUMP_BINARY,
        JUMP_REGISTER
    } flag_t;
    state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= memory[1]; //start execution at wherever the ROM offset is, this is stored in 0x1 aka register 1
            state <= FETCH;
        end else begin
            if (flags[12]) begin
                //program errored last cycle, clear out flag and continue
                flags[12] = 0;
            end
            if (flags[13]) begin
                //program encountered fatal error last cycle, halt execution until reset
                opcode=NOP;
            end
            case (state)
                FETCH: begin
                    ir[15:0]  <= memory[pc];
                    ir[31:16] <= memory[pc + 1];
                    pc <= pc + 2;
                    state <= EXECUTE;
                end
                EXECUTE: begin
                    case(opcode)
                        NOP: begin
                            //do nothing
                        end
                        RST: begin
                            memory[3] <= 16'd0; //clear register A
                            memory[4] <= 16'd0; //clear register B
                            memory[5] <= 16'd0; //clear register C
                            memory[6] <= 16'd0; //clear register X
                            memory[7] <= 16'd0; //clear register Y
                            memory[8] <= 16'd0; //clear register Z
                            memory[9] <= 16'd0; //clear register I
                            memory[10] <= 16'd0; //clear itteration limit register
                            memory[11] <= 16'd0; //clear flag register
                            pc <= memory[1]; //reset program counter to ROM offset
                        end
                        LDA: begin
                            //load value into a
                            case (flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[3] <= operand; //load operand into register A
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[3] <= memory[operand]; //load value from register specified by operand into register A
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDB: begin
                            //load value into b
                            case (flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[4] <= operand; //load operand into register B
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[4] <= memory[operand]; //load value from register specified by operand into register B
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDC: begin
                            //load value into c
                            case (flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[5] <= operand; //load operand into register C
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[5] <= memory[operand]; //load value from register specified by operand into register C
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDX: begin
                            //load value into x
                            case (flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[6] <= operand; //load operand into register X
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[6] <= memory[operand]; //load value from register specified by operand into register X
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDY: begin
                            //load value into y
                            case (flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[7] <= operand; //load operand into register Y
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[7] <= memory[operand]; //load value from register specified by operand into register Y
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end 
                            endcase
                        end
                        //skip stores cos idk what to do with them yet.



                        ADA: begin
                            //add to a
                            case (flag)
                                REGULAR_BINARY: begin
                                    //adding from a binary value, not a register
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= operand; //load operand into ALU input B
                                    alu_op <= 4'b0000; //set ALU to perform addition
                                    memory[3] <= alu_out; //store result back in register A
                                end
                                REGULAR_REGISTER: begin
                                    //adding from a register, not a binary value
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= memory[operand]; //load value from register specified by operand into ALU input B
                                    alu_op <= 4'b0000; //set ALU to perform addition
                                    memory[3] <= alu_out; //store result back in register A
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADB: begin
                            //add to B
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[4]
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[4] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[4];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[4] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADC: begin
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[5];
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[5] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[5];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[5] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADX: begin
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[6];
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[6] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[6];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[6] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADY: begin
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[7];
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[7] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[7];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[7] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        SBA: begin
                            //subtract from a
                            case (flag)
                                REGULAR_BINARY: begin
                                    //subtracting from a binary value, not a register
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= operand; //load operand into ALU input B
                                    alu_op <= 4'b0001; //set ALU to perform subtraction
                                    memory[3] <= alu_out; //store result back in register A
                                end
                                REGULAR_REGISTER: begin
                                    //subtracting from a register, not a binary value
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= memory[operand]; //load value from register specified by operand into ALU input B
                                    alu_op <= 4'b0001; //set ALU to perform subtraction
                                    memory[3] <= alu_out; //store result back in register A
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBB: begin
                            //subtract from b
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[4];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[4] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[4];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[4] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBC: begin
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[5];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[5] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[5];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[5] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBX: begin
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[6];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[6] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[6];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[6] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBY: begin
                            case(flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[7];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[7] <= alu_out;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[7];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[7] <= alu_out;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end

                    endcase
                end
            endcase
        end
    end

endmodule