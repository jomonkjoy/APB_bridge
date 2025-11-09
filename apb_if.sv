//============================================================
// File: apb_if.sv
// Description: AMBA APB4 Interface Definition
//============================================================

interface apb_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int STRB_WIDTH = DATA_WIDTH/8
) (
  input  logic pclk,
  input  logic presetn
);

  // ----------------------------------------
  // APB4 Signal Declarations
  // ----------------------------------------
  logic [ADDR_WIDTH-1:0] paddr;
  logic                  psel;
  logic                  penable;
  logic                  pwrite;
  logic [DATA_WIDTH-1:0] pwdata;
  logic [STRB_WIDTH-1:0] pstrb;     // Optional: APB4 write strobe
  logic [DATA_WIDTH-1:0] prdata;
  logic                  pready;
  logic                  pslverr;

  // ----------------------------------------
  // Master Modport
  // ----------------------------------------
  modport master (
    input  prdata,
    input  pready,
    input  pslverr,
    output paddr,
    output psel,
    output penable,
    output pwrite,
    output pwdata,
    output pstrb
  );

  // ----------------------------------------
  // Slave Modport
  // ----------------------------------------
  modport slave (
    input  paddr,
    input  psel,
    input  penable,
    input  pwrite,
    input  pwdata,
    input  pstrb,
    output prdata,
    output pready,
    output pslverr
  );

  // ----------------------------------------
  // Optional: Clocking block for TB usage
  // ----------------------------------------
`ifndef SYNTHESIS
  clocking cb @(posedge pclk);
    default input #1step output #1step;
    input  prdata, pready, pslverr;
    output paddr, psel, penable, pwrite, pwdata, pstrb;
  endclocking
`endif

endinterface
