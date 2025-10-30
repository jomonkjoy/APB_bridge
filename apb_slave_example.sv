// ============================================================================
// Example Slave Module (for testing)
// ============================================================================

module apb_slave_example #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int NUM_REGS = 4
) (
    input  logic                    pclk,
    input  logic                    presetn,
    input  logic [ADDR_WIDTH-1:0]   paddr,
    input  logic                    psel,
    input  logic                    penable,
    input  logic                    pwrite,
    input  logic [DATA_WIDTH-1:0]   pwdata,
    input  logic [DATA_WIDTH/8-1:0] pstrb,
    output logic [DATA_WIDTH-1:0]   prdata,
    output logic                    pready,
    output logic                    pslverr
);

    logic [DATA_WIDTH-1:0] registers [NUM_REGS];
    logic [ADDR_WIDTH-1:0] addr_index;
    
    assign addr_index = paddr[ADDR_WIDTH-1:2]; // Word-aligned
    assign pready = 1'b1; // Always ready
    assign pslverr = (addr_index >= NUM_REGS); // Error if out of range
    
    // Write operation
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (int i = 0; i < NUM_REGS; i++) begin
                registers[i] <= '0;
            end
        end else if (psel && penable && pwrite && !pslverr) begin
            for (int i = 0; i < DATA_WIDTH/8; i++) begin
                if (pstrb[i]) begin
                    registers[addr_index][i*8 +: 8] <= pwdata[i*8 +: 8];
                end
            end
        end
    end
    
    // Read operation
    always_comb begin
        if (psel && !pwrite && !pslverr) begin
            prdata = registers[addr_index];
        end else begin
            prdata = '0;
        end
    end

endmodule
