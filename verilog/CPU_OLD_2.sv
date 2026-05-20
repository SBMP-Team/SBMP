module CPU_OLD_2
(
    input logic btnA,
    input logic btnB,
    input logic btnUp,
    input logic btnDown,
    input logic btnLeft,
    input logic btnRight,
    input logic btnStart,
    input logic rst,
    input logic clk
);

    logic [15:0] memory [0:65535]; // 64KB of memory
    

    localparam [15:0] REG_CONTROLLER = 16'd0;
    localparam [15:0] REG_A = 16'd3;
    localparam [15:0] REG_B = 16'd4;
    localparam [15:0] REG_C = 16'd5;
    localparam [15:0] REG_XY = 16'd6; //low byte is X, high byte is Y
    localparam [15:0] REG_I = 16'd7;
    localparam [15:0] REG_I_LIMIT = 16'd8;
    localparam [15:0] REG_FLAGS = 16'd9;


    logic [15:0] PC = 16'd0;; // program counter

    logic[15:0] operand = 16'd0;; // current instruction
    logic[5:0] opcode; // current opcode
    logic operand_type; // 0 = hex, 1 = register
    logic isJump; // 0 = normal instruction, 1 = jump instruction
    logic[15:0] packed_opcode  = 16'd0; // opcode packed with operand type and jump flag for lookup
    
    logic WB_ENABLE = 1'd0;

    logic[15:0] writeback_target = 16'd0;
    logic[15:0] writeback_value = 16'd0;



    //ALU stuff
    logic [15:0] alu_out;
    logic [15:0] alu_a = 16'd0;
    logic [15:0] alu_b = 16'd0;
    logic [3:0] alu_op = 4'b1111; // ALU NOP so that it doesnt do anything by default
    ALU alu (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .out(alu_out)
    );


    //audio coprocessor stuff
    logic [7:0] audio_freq;
    logic [7:0] audio_dur;
    logic [15:0] packed_audio = 16'd0;
    assign audio_freq = packed_audio[7:0]; // lower byte is frequency
    assign audio_dur = packed_audio[15:8]; // upper byte is duration
    logic audio_play = 1'd0;
    logic audio_out, audio_busy;
    logic audio_clock;
    logic audio_reset;
    assign audio_clock = clk;
    assign audio_reset = rst;
    AudioCoprocessor audio (
        .clk(audio_clock),
        .rst(audio_reset),
        .freq(audio_freq),
        .duration(audio_dur),
        .play(audio_play),
        .audio_out(audio_out),
        .busy(audio_busy)
    );

    typedef enum logic { NORMAL, JUMP } jump_type;
    typedef enum logic { REG,HEX } operand_type_t; // lsb 0 = register, lsb 1 = binary
    typedef enum logic [6:0] {
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

    typedef enum logic [3:0] {  
        FETCH, // fetch instruction from memory
        DECODE, // decode instruction and prepare operands
        READ, // read memory if needed, skipped if not needed for cycle
        EXECUTE, // execute instruction
        WRITEBACK, // write results back to registers if needed
        ERROR, // fatal error, causes a NOP loop until reset
        WAIT // waits for an external event, such as the audio coprocessor finishing a note, before proceeding to FETCH
    } cpu_phase;

    typedef enum logic [3:0]{
        ALU_ADD,
        ALU_SUB,
        ALU_MUL,
        ALU_DIV,
        ALU_MOD,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_NOT,
        ALU_SHL,
        ALU_SHR,
        ALU_NOP=4'b1111
    } alu_op_t;

    cpu_phase current_phase;

    always_ff @( posedge clk or posedge rst ) begin : blockName
        if (rst) begin
            // reset logic here
            current_phase <= FETCH;
            PC <= 16'd512; // set PC to the value at 0x0001, aka pointer to where the ROM starts
            //reset all registers to zero
            memory[REG_A] <= 16'b0;
            memory[REG_B] <=16'b0;
            memory[REG_C] <=16'b0;
            memory[REG_XY] <=16'b0;
            memory[REG_I] <=16'b0;
            memory[REG_I_LIMIT] <=16'b0;
        end else begin
            //read controller pins and pack into controller_data
            memory[REG_CONTROLLER] <= {9'b0,btnA, btnB, btnUp, btnDown, btnLeft, btnRight, btnStart}; // pack controller inputs into a word
            
            case(current_phase)
                FETCH: begin
                    packed_opcode <= memory[PC];
                    operand <= memory[PC+1];
                    PC <= PC + 2;
                    current_phase <= DECODE;
                end
                DECODE: begin
                    opcode <= packed_opcode[7:2]; // extract opcode (bits 7-2)
                    operand_type <= packed_opcode[0]; // extract operand type (bit 1)
                    isJump <= packed_opcode[1]; // extract jump flag (bit 0)
                    current_phase <=READ;
                end
                READ: begin
                    if (operand_type == REG) begin
                        operand <= memory[operand];
                    end
                    current_phase <= EXECUTE;
                end
                EXECUTE: begin
                    //just implement ADA for now for debugging
                    case(packed_opcode[7:2])
                        NOP: begin
                            // do nothing
                            current_phase <= FETCH;
                        end
                        LDA: begin
                            WB_ENABLE <= 1'b1;
                            writeback_target <= REG_A;
                            writeback_value <= operand;
                            alu_op <= ALU_NOP;
                            current_phase <= WRITEBACK;
                        end
                        LDB: begin
                            WB_ENABLE <= 1'b1;
                            writeback_target <= REG_B;
                            writeback_value <=operand;
                            alu_op <= ALU_NOP;
                            current_phase <=WRITEBACK;
                        end
                        //arythmetic instructions
                        ADA: begin
                            WB_ENABLE <= 1'b1;
                            writeback_target <= REG_A;

                            alu_a <= memory[REG_A];
                            alu_b <= operand;
                            alu_op <= ALU_ADD;

                            current_phase <= WRITEBACK;
                        end
                        JMP: begin
                            PC <= operand;
                            current_phase <= FETCH;
                        end
                        BIZ: begin
                            if (memory[REG_A] == 1'b0) begin
                                PC <= operand;
                                current_phase <= FETCH;
                            end
                        end
                        BIO: begin
                            if (memory[REG_A]) begin
                                PC <= operand;
                                current_phase <=FETCH;
                            end
                        end

                        ADW: begin
                            packed_audio <= operand; // write operand to audio coprocessor input
                            audio_play <= 1; // trigger audio playback
                            current_phase <= WAIT; // wait for audio to finish before proceeding
                        end
                        default: begin
                            //invalid opcode, fatal error reset program.
                            current_phase <= ERROR;
                        end
                    endcase
                end
                WRITEBACK: begin
                    if (WB_ENABLE) begin
                        if (alu_op != ALU_NOP) begin
                            writeback_value <= alu_out;
                            WB_ENABLE <= 1'b0;
                        end
                        memory[writeback_target] <= writeback_value; // write the result back to the target register
                    end
                    current_phase <= FETCH;
                end
                ERROR: begin
                    // fatal error, set flag 13 high and stay here till exit
                    memory[REG_FLAGS][13] <= 1;
                end 
                WAIT: begin
                    if (audio_busy == 0) begin
                        current_phase <= FETCH;
                    end
                end
                default: begin
                    memory[REG_FLAGS][12] <= 1;
                end
            endcase
        end
    end
endmodule