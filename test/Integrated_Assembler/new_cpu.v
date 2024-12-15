module cpu (
    input wire clk,        
    input wire reset,       
    input wire wakeup,      
    output wire [3:0] acc   
);

    reg [3:0] PC;           // Program Counter
    reg [7:0] IR;           // Instruction Register (8-bit wide)
    reg [3:0] R0, R1;       // General purpose registers
    reg [3:0] ACC;          // Accumulator
    reg [3:0] memory [0:15];// Simple 4-bit memory for instructions
    reg [3:0] data_memory [0:15]; // Data memory
    reg [3:0] alu_out;      // Output of ALU
    reg [3:0] opcode, operand;
    reg [1:0] state;        // States
    reg [1:0] Data_PC;
    
    // States for instruction cycle
    parameter FETCH = 2'b00, DECODE = 2'b01, EXECUTE = 2'b10, SLEEP = 2'b11;

    
    always @(*) begin
        case(opcode)
            4'b0010: alu_out = R0 + R1;  // ADD
            4'b0011: alu_out = R0 - R1;  // SUB
            4'b0100: alu_out = R0 & R1;  // AND
            4'b0101: alu_out = R0 | R1;  // OR
            4'b0111: alu_out = ~(R0 ^ R1); // XNOR
            default: alu_out = 4'b0000;  // Default NOP
        endcase
    end

    // Control Unit FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 4'b0000;
            Data_PC <= 2'b00;
            ACC <= 4'b0000;
            IR <= 8'b00000000;
            state <= FETCH;
        end else begin
            case (state)
                FETCH: begin
                    IR <= {memory[PC + 1], memory[PC]};  // Fetch instruction
                    PC <= PC + 2;                        // Increment PC by 2
                    state <= DECODE;
                end
                DECODE: begin
                    opcode <= IR[3:0];      // Decode the opcode
                    operand <= IR[7:4];     // Decode the operand
                    if (opcode == 4'b1000)  // Sleep opcode to enter sleep state
                        state <= SLEEP;
                    else
                        state <= EXECUTE;
                end
                EXECUTE: begin
                    case (opcode)
                        4'b0000: state <= FETCH;  // NOP: go back to fetch


                        4'b0001: begin            // LOAD constant to ACC
                            ACC <= operand;
                            data_memory[Data_PC] <= operand;
                            Data_PC <= Data_PC + 1;      // Increment Data_PC for next load
                            if (Data_PC == 2'b10)        // Reset Data_PC if both R0 and R1 are loaded
                                Data_PC <= 2'b00;
                            state <= FETCH;
                        end


                        4'b0010, 4'b0011, 4'b0100, 4'b0101, 4'b0111: begin  // ALU operations
                            R0 <= data_memory[0];
                            R1 <= data_memory[1];  
                            @(posedge clk) 
                            begin 
                                ACC <= alu_out;
                                state <= FETCH;
                            end
                        end


                        4'b0110: begin            // STORE ACC to memory
                            data_memory[operand] <= ACC;
                            state <= FETCH;
                        end


                        4'b0111: begin            // JMP to address
                            PC <= operand;
                            state <= FETCH;
                        end


                        default: state <= FETCH;  


                    endcase
                end


                SLEEP: begin
                    if (wakeup)                  
                        state <= FETCH;
                end

                
            endcase
        end
    end

    assign acc = ACC;  // Output the current value of ACC

endmodule
