----------------------------------------------------------------------------
--  FPGA Lab 701 - Clock Generator
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Creates clocks for system timing
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

-- For ODDRs
library UNISIM;
use UNISIM.VComponents.all;     -- Contains ODDRs for clock forwarding

----------------------------------------------------------------------------
-- Entity definition
entity clock_generation is
    Port (  sysclk_i : in STD_LOGIC; -- Should be 12.288 MHz
	
            ac_adc_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_bclk_o : out STD_LOGIC; -- Should be MCLK/4
            bclk_o : out STD_LOGIC;
            ac_dac_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_mclk_o : out STD_LOGIC; 
            mclk_o : out STD_LOGIC; -- Should be 12.288 MHz, but with ODDR
			unbuffered_clk_reg : out STD_LOGIC);  -- Should be LRCLOCK without ODDR
end clock_generation;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of clock_generation is

----------------------------------------------------------------------------
-- Define Components
----------------------------------------------------------------------------
-- Clock wizard
component clk_wiz_0
    Port (  
        clk_in1  : in std_logic;
        
        clk_out1 : out std_logic); 
end component;

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- MCLK (clock wizard) signals
signal unbuffered_mclk : std_logic := '0';

-- BCLK Values
constant BCLK_DIVISOR : integer := 4/2; -- Accounting for inherent division by 2
constant BCLK_COUNT_BITS : integer := integer(ceil(log2(real(BCLK_DIVISOR))));
signal bclock_counter : unsigned(BCLK_COUNT_BITS-1 downto 0) := (others => '0');
signal unbuffered_bclk : std_logic := '0';

-- BCLK Values
constant LRCLK_DIVISOR : integer := 64/2; -- Tied to BCLK; accounting for inherent division by 2
constant LRCLK_COUNT_BITS : integer := integer(ceil(log2(real(LRCLK_DIVISOR))));
signal lrclock_counter : unsigned(LRCLK_COUNT_BITS-1 downto 0) := (others => '0');
signal unbuffered_lrclk : std_logic := '0';

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- MCLK clock counter
mclock_generator : clk_wiz_0
    port map (
        clk_in1 => sysclk_i,
        
        clk_out1 => unbuffered_mclk
    );
    
--------------------------------------------------------------------------
-- BIT CLOCK
bclk_gen : process(unbuffered_mclk)
begin
    if rising_edge(unbuffered_mclk) then
    
        -- Manage bclock counter, with rollover
        if (bclock_counter = BCLK_DIVISOR-1) then 
            bclock_counter <= (others => '0');   -- reset
        else
            bclock_counter <= bclock_counter + 1; -- increment
        end if;
        
        -- Flip value if we hit the counter limit
        if (bclock_counter = BCLK_DIVISOR-1) then 
            unbuffered_bclk <= not unbuffered_bclk;
        end if;
    end if;
end process bclk_gen;

----------------------------------------------------------------------------
-- LR/WS CLOCK
lrclk_gen : process(unbuffered_bclk)
begin
    if falling_edge(unbuffered_bclk) then
        
        -- Manage lrclock coutner, with rollover
        if (lrclock_counter = LRCLK_DIVISOR-1) then 
            lrclock_counter <= (others => '0');   -- reset
        else
            lrclock_counter <= lrclock_counter + 1; -- increment
        end if;
        
        -- Flip value if we hit the counter limit
        if (lrclock_counter = LRCLK_DIVISOR-1) then 
            unbuffered_lrclk <= not unbuffered_lrclk;
        end if;
    end if;
end process lrclk_gen;

----------------------------------------------------------------------------
-- CLOCK BUFFERS  
-- MCLOCK  
mclock_forward_oddr : ODDR
generic map(
    DDR_CLK_EDGE => "SAME_EDGE", -- Opposite or same edge
    INIT => '0', -- Intitial value for Q
    SRTYPE => "SYNC") -- Reset type
port map (
    Q => ac_mclk_o, -- DDR Output
    C => unbuffered_mclk, -- Clock input
    CE => '1', -- Clock enable input
    D1 => '1', -- Data input(pos)
    D2 => '0', -- Data input(neg)
    R => '0', -- Reset input
    S => '0'); -- Set input
 
-- BCLOCK  
bclk_forward_oddr : ODDR
generic map(
    DDR_CLK_EDGE => "SAME_EDGE", -- Opposite or same edge
    INIT => '0', -- Intitial value for Q
    SRTYPE => "SYNC") -- Reset type
port map (
    Q => ac_bclk_o, -- DDR Output
    C => unbuffered_bclk, -- Clock input
    CE => '1', -- Clock enable input
    D1 => '1', -- Data input(pos)
    D2 => '0', -- Data input(neg)
    R => '0', -- Reset input
    S => '0'); -- Set input

-- LRCLOCK - ADC
adc_lrclk_forward_oddr : ODDR
generic map(
    DDR_CLK_EDGE => "SAME_EDGE", -- Opposite or same edge
    INIT => '0', -- Intitial value for Q
    SRTYPE => "SYNC") -- Reset type
port map (
    Q => ac_adc_lrclk_o, -- DDR Output
    C => unbuffered_lrclk, -- Clock input
    CE => '1', -- Clock enable input
    D1 => '1', -- Data input(pos)
    D2 => '0', -- Data input(neg)
    R => '0', -- Reset input
    S => '0'); -- Set input

-- LRCLOCK - DAC
dac_lrclk_forward_oddr : ODDR
generic map(
    DDR_CLK_EDGE => "SAME_EDGE", -- Opposite or same edge
    INIT => '0', -- Intitial value for Q
    SRTYPE => "SYNC") -- Reset type
port map (
    Q => ac_dac_lrclk_o, -- DDR Output
    C => unbuffered_lrclk, -- Clock input
    CE => '1', -- Clock enable input
    D1 => '1', -- Data input(pos)
    D2 => '0', -- Data input(neg)
    R => '0', -- Reset input
    S => '0'); -- Set input

-- Output unbuffered values as well
mclk_o <= unbuffered_mclk;
unbuffered_clk_reg <= unbuffered_lrclk;
bclk_o <= unbuffered_bclk;

end Behavioral;