library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity uart_tx is
generic (
c_clkfreq   : integer := 100_000_000;
c_baudrate  : integer := 115_200;
c_stopbit   : integer := 2
);

port (
clk     : in std_logic;
din     : in std_logic_vector (7 downto 0);
tx_start_bit : in std_logic;
tx_o    : out std_logic;
tx_done_tick_o : out std_logic
);
end uart_tx;

architecture Behavioral of uart_tx is
type states is (S_IDLE, S_START, S_DATA, S_STOP);
signal state : states := S_IDLE;

constant bit_timer_lim : integer := c_clkfreq/c_baudrate;
constant bit_stop_lim  : integer := c_stopbit * c_clkfreq/c_baudrate;

signal latch_din : std_logic_vector (7 downto 0) := (others => '0');
signal bittimer : integer range 0 to bit_stop_lim;
signal index_din : integer range 0 to 8 := 0;
begin  
P_MAIN: process(clk) begin
if (rising_edge(clk)) then
    case state is
        when S_IDLE =>
            tx_done_tick_o <= '0';
            bittimer <= 0;
            index_din <= 0;
            tx_o <= '1';
            if (tx_start_bit = '1') then
                latch_din <= din;
                state <= S_START;
            else 
                state <= S_IDLE;
            end if;
            
        when S_START =>
            tx_done_tick_o <= '0';
            tx_o <= '0';
            if (bittimer = bit_timer_lim - 1) then
                index_din <= 1;
                bittimer <= 0;
                tx_o <= latch_din(0);
                state <= S_DATA;
                
            else
                bittimer <= bittimer + 1;
            end if; 
        when S_DATA => 
            if (index_din < 8) then
                if (bittimer = bit_timer_lim - 1) then
                    tx_o <= latch_din(index_din);
                    bittimer <= 0;
                    index_din <= index_din + 1;
                else
                    
                    bittimer <= bittimer + 1;
                end if;
            else
                if (bittimer = bit_timer_lim - 1) then
                    
                    bittimer <= 0;
                    tx_o <= '1';
                    state <= S_STOP;
                else
                    
                    bittimer <= bittimer + 1;
                end if;
            end if;
        when S_STOP =>
            if (bittimer = bit_stop_lim - 1) then
                index_din <= 0;
                tx_done_tick_o <= '1';
                bittimer <= 0;
                
                state <= S_IDLE;
            else
                bittimer <= bittimer + 1;
            end if;
    end case;
end if;
end process;

end Behavioral;
