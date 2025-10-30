// ============================================================================
// Parameterized APB Bridge with Address Decoding
// Supports multiple slaves with configurable base addresses and masks
// ============================================================================

module apb_bridge #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int NUM_SLAVES = 4,
    // Base addresses for each slave (array)
    parameter bit [ADDR_WIDTH-1:0] BASE_ADDR [NUM_SLAVES] = '{
        32'h0000_0000,  // Slave 0
        32'h0000_1000,  // Slave 1
        32'h0000_2000,  // Slave 2
        32'h0000_3000   // Slave 3
    },
    // Address masks for each slave (typically size - 1 for power of 2 sizes)
    parameter bit [ADDR_WIDTH-1:0] ADDR_MASK [NUM_SLAVES] = '{
        32'h0000_0FFF,  // 4KB for Slave 0
        32'h0000_0FFF,  // 4KB for Slave 1
        32'h0000_0FFF,  // 4KB for Slave 2
        32'h0000_0FFF   // 4KB for Slave 3
    }
) (
    // Clock and Reset
    input  logic                    pclk,
    input  logic                    presetn,
    
    // APB Master Interface (from system bus)
    input  logic [ADDR_WIDTH-1:0]   paddr,
    input  logic                    psel,
    input  logic                    penable,
    input  logic                    pwrite,
    input  logic [DATA_WIDTH-1:0]   pwdata,
    input  logic [DATA_WIDTH/8-1:0] pstrb,
    input  logic [2:0]              pprot,
    output logic [DATA_WIDTH-1:0]   prdata,
    output logic                    pready,
    output logic                    pslverr,
    
    // APB Slave Interfaces (to peripherals)
    output logic [ADDR_WIDTH-1:0]   paddr_s  [NUM_SLAVES],
    output logic                    psel_s   [NUM_SLAVES],
    output logic                    penable_s,
    output logic                    pwrite_s,
    output logic [DATA_WIDTH-1:0]   pwdata_s,
    output logic [DATA_WIDTH/8-1:0] pstrb_s,
    output logic [2:0]              pprot_s,
    input  logic [DATA_WIDTH-1:0]   prdata_s [NUM_SLAVES],
    input  logic                    pready_s [NUM_SLAVES],
    input  logic                    pslverr_s[NUM_SLAVES]
);

    // ========================================================================
    // Internal Signals
    // ========================================================================
    
    logic [NUM_SLAVES-1:0] slave_select;
    logic [NUM_SLAVES-1:0] slave_select_reg;
    logic                  valid_slave;
    logic                  decode_error;
    
    // ========================================================================
    // Address Decoder
    // Checks if address falls within any slave's address range
    // ========================================================================
    
    always_comb begin
        slave_select = '0;
        valid_slave = 1'b0;
        
        for (int i = 0; i < NUM_SLAVES; i++) begin
            // Check if address matches: (addr & ~mask) == (base & ~mask)
            if ((paddr & ~ADDR_MASK[i]) == (BASE_ADDR[i] & ~ADDR_MASK[i])) begin
                slave_select[i] = 1'b1;
                valid_slave = 1'b1;
            end
        end
    end
    
    // Decode error if psel is active but no valid slave
    assign decode_error = psel && !valid_slave;
    
    // ========================================================================
    // Register slave selection during SETUP phase
    // This maintains slave select stable during ACCESS phase
    // ========================================================================
    
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            slave_select_reg <= '0;
        end else if (psel && !penable) begin
            // SETUP phase - latch the slave selection
            slave_select_reg <= slave_select;
        end
    end
    
    // ========================================================================
    // APB Slave Interface Generation
    // ========================================================================
    
    // Address and control signals (broadcast to all slaves)
    always_comb begin
        for (int i = 0; i < NUM_SLAVES; i++) begin
            // Localize address to slave's address space
            paddr_s[i] = paddr - BASE_ADDR[i];
            
            // psel is only asserted for the selected slave
            if (penable) begin
                // ACCESS phase - use registered selection
                psel_s[i] = slave_select_reg[i];
            end else begin
                // SETUP phase - use current selection
                psel_s[i] = slave_select[i] && psel;
            end
        end
    end
    
    // Common control signals (same for all slaves)
    assign penable_s = penable;
    assign pwrite_s  = pwrite;
    assign pwdata_s  = pwdata;
    assign pstrb_s   = pstrb;
    assign pprot_s   = pprot;
    
    // ========================================================================
    // Response Multiplexing
    // Select response from the active slave
    // ========================================================================
    
    always_comb begin
        prdata  = '0;
        pready  = 1'b1;  // Default ready
        pslverr = 1'b0;
        
        if (decode_error) begin
            // Address decode error
            prdata  = '0;
            pready  = 1'b1;
            pslverr = 1'b1;
        end else begin
            // Multiplex response from selected slave
            for (int i = 0; i < NUM_SLAVES; i++) begin
                if (slave_select_reg[i]) begin
                    prdata  = prdata_s[i];
                    pready  = pready_s[i];
                    pslverr = pslverr_s[i];
                end
            end
        end
    end
    
    // ========================================================================
    // Assertions for Verification
    // ========================================================================
    
    `ifdef ASSERT_ON
    
    // Only one slave should be selected at a time
    property p_one_hot_select;
        @(posedge pclk) disable iff (!presetn)
        psel |-> $onehot0(slave_select);
    endproperty
    assert_one_hot: assert property(p_one_hot_select)
        else $error("Multiple slaves selected simultaneously!");
    
    // Slave select should remain stable during transaction
    property p_stable_select;
        @(posedge pclk) disable iff (!presetn)
        (psel && penable) |-> $stable(slave_select_reg);
    endproperty
    assert_stable: assert property(p_stable_select)
        else $error("Slave select changed during transaction!");
    
    // APB protocol: penable follows psel
    property p_apb_protocol;
        @(posedge pclk) disable iff (!presetn)
        $rose(penable) |-> $past(psel);
    endproperty
    assert_protocol: assert property(p_apb_protocol)
        else $error("APB protocol violation: penable without psel!");
    
    `endif
    
endmodule
