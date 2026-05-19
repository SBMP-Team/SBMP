module CPU_OLD
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
    logic [31:0] ir;
    logic [5:0] opcode;
    logic [1:0] opcode_flag;
    logic [15:0] operand;
    logic [15:0] flags;
    assign flags = memory[11];
    assign opcode = ir[24:18];
    assign opcode_flag = ir[17:16];
    assign operand = ir[15:0];

    logic [15:0] wait_frames;

    //ALU
    logic [15:0] alu_A, alu_b, alu_out;
    logic [3:0] alu_op;
    ALU alu (
        .a(alu_A),
        .b(alu_b),
        .op(alu_op),
        .out(alu_out)
    );
    logic [15:0] audio_out;
    logic audio_busy;
    logic audio_play;
    logic [15:0] audio_op;
    

    AudioCoprocessor audio_coprocessor (
        .clk(clk),
        .rst(rst),
        .freq(audio_op[7:0]), //frequency stored in register A
        .duration(audio_op[15:8]), //duration stored in register B
        .play(audio_play),
        .audio_out(audio_out),
        .busy(audio_busy)
    );
    typedef enum logic [1:0]{
        FETCH,
        EXECUTE,
        WAIT_AUDIO,
        ERROR_LOOP
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
                state <= FETCH;
            end
            if (flags[13]) begin
                //program encountered fatal error last cycle, halt execution until reset
                state <= ERROR_LOOP;
            end
            case (state)
                FETCH: begin
                    ir[15:0]  <= memory[pc];
                    ir[31:16] <= memory[pc + 1];
                    pc <= pc + 2;
                    state <= EXECUTE;
                end
                EXECUTE: begin
                    if (wait_frames > 0) begin
                        wait_frames <= wait_frames - 1;
                        opcode <= NOP; //waiting till done, aka NOP loop
                    end
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
                            state <= FETCH; //go back to fetching instructions
                        end
                        LDA: begin
                            //load value into a
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[3] <= operand; //load operand into register A
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[3] <= memory[operand]; //load value from register specified by operand into register A
                                    state <= FETCH; //go back to fetching instructions
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDB: begin
                            //load value into b
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[4] <= operand; //load operand into register B
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[4] <= memory[operand]; //load value from register specified by operand into register B
                                    state <= FETCH; //go back to fetching instructions
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDC: begin
                            //load value into c
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[5] <= operand; //load operand into register C
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[5] <= memory[operand]; //load value from register specified by operand into register C
                                    state <= FETCH; //go back to fetching instructions
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDX: begin
                            //load value into x
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[6] <= operand; //load operand into register X
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[6] <= memory[operand]; //load value from register specified by operand into register X
                                    state <= FETCH; //go back to fetching instructions
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        LDY: begin
                            //load value into y
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //loading from a binary value, not a register
                                    memory[7] <= operand; //load operand into register Y
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //loading from a register, not a binary value
                                    memory[7] <= memory[operand]; //load value from register specified by operand into register Y
                                    state <= FETCH; //go back to fetching instructions
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
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //adding from a binary value, not a register
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= operand; //load operand into ALU input B
                                    alu_op <= 4'b0000; //set ALU to perform addition
                                    memory[3] <= alu_out; //store result back in register A
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //adding from a register, not a binary value
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= memory[operand]; //load value from register specified by operand into ALU input B
                                    alu_op <= 4'b0000; //set ALU to perform addition
                                    memory[3] <= alu_out; //store result back in register A
                                    state <= FETCH; //go back to fetching instructions
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADB: begin
                            //add to B
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[4]
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[4] <= alu_out;
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[4];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADC: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[5];
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[5];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADX: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[6];
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[6];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        ADY: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[7];
                                    alu_b <= operand;
                                    alu_op <= 4'b0000;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[7];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0000;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        SBA: begin
                            //subtract from a
                            case (opcode_flag)
                                REGULAR_BINARY: begin
                                    //subtracting from a binary value, not a register
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= operand; //load operand into ALU input B
                                    alu_op <= 4'b0001; //set ALU to perform subtraction
                                    memory[3] <= alu_out; //store result back in register A
                                    state <= FETCH; //go back to fetching instructions
                                end
                                REGULAR_REGISTER: begin
                                    //subtracting from a register, not a binary value
                                    alu_A <= memory[3]; //load register A into ALU input A
                                    alu_b <= memory[operand]; //load value from register specified by operand into ALU input B
                                    alu_op <= 4'b0001; //set ALU to perform subtraction
                                    memory[3] <= alu_out; //store result back in register A
                                    state <= FETCH; //go back to fetching instructions
                                end
                                //jump registers invalid here, error out if attempted
                                default : begin
                                     flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBB: begin
                            //subtract from b
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[4];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[4];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBC: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[5];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[5];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBX: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[6];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[6];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        SBY: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[7];
                                    alu_b <= operand;
                                    alu_op <= 4'b0001;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[7];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0001;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        DVA: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[3];
                                    alu_b <= operand;
                                    alu_op <= 4'b0011;
                                    memory[3] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[3];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0011;
                                    memory[3] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        DVB: begin
                            case(opcode_flag) 
                                REGULAR_BINARY:begin
                                    alu_A <= memory[4];
                                    alu_b <= operand;
                                    alu_op <= 4'b0011;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[4];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0011;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        DVC: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[5];
                                    alu_b <= operand;
                                    alu_op <= 4'b0011;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[5];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0011;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        DVX: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[6];
                                    alu_b <= operand;
                                    alu_op <= 4'b0011;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[6];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0011;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        DVY: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[7];
                                    alu_b <= operand;
                                    alu_op <= 4'b0011;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[7];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0011;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag
                                end
                            endcase
                        end
                        MDA: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[3];
                                    alu_b <= operand;
                                    alu_op <= 4'b0100;
                                    memory[3] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[3];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0100;
                                    memory[3] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MDB: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[4];
                                    alu_b <= operand;
                                    alu_op <= 4'b0100;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[4];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0100;
                                    memory[4] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MDC: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[5];
                                    alu_b <= operand;
                                    alu_op <= 4'b0100;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[5];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0100;
                                    memory[5] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MDX: begin
                            case (opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[6];
                                    alu_b <= operand;
                                    alu_op <= 4'b0100;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[6];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0100;
                                    memory[6] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end  
                            endcase
                        end
                        MDY: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[7];
                                    alu_b <= operand;
                                    alu_op <= 4'b0100;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[7];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0100;
                                    memory[7] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end

                        MXA: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[8];
                                    alu_b <= operand;
                                    alu_op <= 4'b0010;
                                    memory[8] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[8];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0010;
                                    memory[8] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MXB: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[9];
                                    alu_b <= operand;
                                    alu_op <= 4'b0010;
                                    memory[9] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[9];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0010;
                                    memory[9] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MXC: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[10];
                                    alu_b <= operand;
                                    alu_op <= 4'b0010;
                                    memory[10] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[10];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0010;
                                    memory[10] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MXX: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[11];
                                    alu_b <= operand;
                                    alu_op <= 4'b0010;
                                    memory[11] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[11];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0010;
                                    memory[11] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        MXY: begin
                            case(opcode_flag)
                                REGULAR_BINARY:begin
                                    alu_A <= memory[12];
                                    alu_b <= operand;
                                    alu_op <= 4'b0010;
                                    memory[12] <= alu_out;
                                    state <= FETCH;
                                end
                                REGULAR_REGISTER:begin
                                    alu_A <= memory[12];
                                    alu_b <= memory[operand];
                                    alu_op <= 4'b0010;
                                    memory[12] <= alu_out;
                                    state <= FETCH;
                                end
                                //jumps not valid here, error out if attempted
                                default: begin
                                        flags[12] = 1; //set error flag 
                                end
                            endcase
                        end
                        CLI: begin
                            //clear itterator
                            memory[9] <= 16'd0;
                            state <= FETCH;
                        end
                        ITR: begin
                            //itterate itterator
                            memory[9] <= memory[9] + 16'd1;
                            //checks if it passes itteration limit
                            if (memory[9] > memory[10]) begin
                                memory[9] <= 16'd0;
                                flag[1] = 1; //set itteration limit passed flag
                            end
                            state <= FETCH;

                        end
                        BIZ: begin
                            //branch if zero, jump to operand if a is zero
                            if (memory[3] == 16'd0) begin
                                pc <= operand;
                            end
                            state <= FETCH;
                        end
                        BIO: begin
                           if (memory[3][0] == 1'b1) begin
                                pc <= operand;
                            end
                            state <= FETCH;
                        end
                        ADN: begin
                            if(!audio_busy) begin
                                audio_op <= operand;
                                audio_play <= 1; //tell audio coprocessor to start playing
                            end else begin
                                flags[12] = 1; //set error flag, audio coprocessor is busy
                            end
                            state <= FETCH;
                        end
                        ADW: begin
                            audio_op <= operand;
                            state <= WAIT_AUDIO; //wait for audio coprocessor to finish before executing next instruction
                            audio_play <= 1; //tell audio coprocessor to start playing
                        end
                        WAT:begin
                            wait_frames <= operand; //load number of frames to wait into wait_frames register
                            state <= FETCH;
                        end
                        LAC:begin
                            //load current memory address of instruction into A
                            memory[3] <=pc
                            state <= FETCH;
                        end

                        default: begin
                            //invalid opcode, error out
                            flags[13] = 1; //set fatal error flag
                        end
                    endcase
                end
                WAIT_AUDIO: begin
                    //wait for audio coprocessor to finish, then return to fetch state
                    if (!audio_busy) begin
                        state <= FETCH;
                    end
                end
                ERROR_LOOP: begin
                    //do nothing, program has encountered fatal error
                end
                default: begin
                    //invalid state, error out
                    flags[13] = 1; //set fatal error flag
                end
            endcase
        end
    end

endmodule