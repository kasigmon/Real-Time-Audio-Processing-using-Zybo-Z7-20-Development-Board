----------------------------------------------------------------------------
--  FPGA Lab 601 - AXI FIFO Wrapper
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
-- Description: Wrapper for AXI FIFO System
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axis_fifo_wrapper is
	generic (
		DATA_WIDTH	: integer	:= 32;
		FIFO_DEPTH	: integer	:= 1024
	);
	port (
	
		-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     :  in std_logic;                                    -- Clock
		s00_axis_aresetn  :  in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  :  in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    :  in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    :  in std_logic;
		s00_axis_tvalid   :  in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     :  in std_logic;                                    -- Clock
		m00_axis_aresetn  :  in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   :  in std_logic
	);
end axis_fifo_wrapper;
----------------------------------------------------------------------------------
architecture Behavioral of axis_fifo_wrapper is
----------------------------------------------------------------------------------
-- Define constants
----------------------------------------------------------------------------------
signal reset_signal : std_logic := '1';
signal empty_signal, full_signal, valid_signal : std_logic := '0';

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Define AXI FIFO Wrapper
component axis_fifo is
    Generic (
        FIFO_DEPTH : integer := FIFO_DEPTH;
        DATA_WIDTH : integer := DATA_WIDTH);
    Port ( 
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        -- Write channel
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Read channel
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_valid_o  : out std_logic;
        
        -- Status flags
        empty_o         : out std_logic;
        full_o          : out std_logic);   
end component axis_fifo;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Signal Instantiations
----------------------------------------------------------------------------
-- Treating entire setup as one stream, allowable per Coursera
m00_axis_tlast <= '0';
-- Reversing reset given FIFO System
reset_signal <= not s00_axis_aresetn;
-- Forwarding through tstrb
m00_axis_tstrb <= s00_axis_tstrb;
-- Not ready to be read when we're empty
m00_axis_tvalid <= '0' when (empty_signal = '1') or (reset_signal = '1') else '1';
-- Not ready to read when full
s00_axis_tready <= '0' when (full_signal = '1') or (reset_signal = '1') else '1';

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------   
-- FIFO instance
axi_stream_fifo : axis_fifo
    port map ( 
        clk_i => s00_axis_aclk, -- Same clock
        reset_i => reset_signal, -- Same reset
        wr_en_i => s00_axis_tvalid, -- Write Enable
        wr_data_i => s00_axis_tdata, -- Data input
        rd_en_i => m00_axis_tready,
        rd_data_o => m00_axis_tdata,
        rd_valid_o => valid_signal, 
        empty_o => empty_signal,
        full_o => full_signal);

end Behavioral;