library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity uart_rx is
generic (
c_clkfreq   : integer := 100_000_000;
c_baudrate  :  integer := 115_200
);

port (
clk     : in std_logic;
rx_i    : in std_logic;
dout    : out std_logic_vector (7 downto 0);
rx_done_tick    : out std_logic
);
end uart_rx;

architecture Behavioral of uart_rx is
type states is (S_IDLE, S_START, S_DATA, S_STOP);
signal state: states := S_IDLE;


constant timer_lim : integer := c_clkfreq / c_baudrate;
constant half_timer_lim : integer := c_clkfreq / (2 * c_baudrate);

signal bittimer : integer range 0 to timer_lim;
signal latch_dout : std_logic_vector (7 downto 0) := (others => '0');
signal index_dout : integer range 0 to 7 := 0;

begin
P_MAIN: process(clk)begin
if rising_edge(clk)then
    case state is
    when S_IDLE =>
        rx_done_tick <= '0';
        bittimer <= 0;
        index_dout <= 0;
        if (rx_i = '0') then
            state <= S_START;
        else
            state <= S_IDLE;
        end if;    
    when S_START => 
        if ( bittimer = half_timer_lim -1 )then
            bittimer <= 0;
            index_dout <= 0;
            state <= S_DATA;
        else
            bittimer <= bittimer + 1;
        end if;
    when S_DATA => 
        if (bittimer = timer_lim - 1 ) then
            if ( index_dout < 7 ) then
                latch_dout(index_dout) <= rx_i;
                index_dout <= index_dout + 1;
                bittimer <= 0;
                
            else
                latch_dout(index_dout) <= rx_i;
                state <= S_STOP;
                bittimer <= 0;
                index_dout <= 0; 
                
            end if;
        else
            bittimer <= bittimer + 1;
        end if;
    when S_STOP => 
        if (bittimer = timer_lim - 1) then
            state <= S_IDLE;
            dout <= latch_dout;
            bittimer <= 0;
            rx_done_tick <= '1';
            
        else
            bittimer <= bittimer + 1;
        end if;
    end case;
end if;
end process;

end Behavioral;
