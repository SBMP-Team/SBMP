module ALU (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [3:0]  op,

    output logic [15:0] out
);

always_comb begin
    //some of these are unused and may be implemented into the ISA in the future
    unique case (op)
        4'b0000: out = a + b;        // ADD
        4'b0001: out = a - b;        // SUB
        4'b0010: out = a * b;        // MUL
        4'b0011: out = (b == 0) ? 16'd0 : a / b; //DIV
        4'b0100: out = (b == 0) ? 16'd0 : a % b; //MOD
        4'b0101: out = a & b;        // AND
        4'b0110: out = a | b;        // OR
        4'b0111: out = a ^ b;        // XOR
        4'b1000: out = ~a;           // NOT
        4'b1001: out = a << b[3:0];  // SHL
        4'b1010: out = a >> b[3:0];  // SHR
        default:  out = 16'd0;
    endcase
end

endmodule