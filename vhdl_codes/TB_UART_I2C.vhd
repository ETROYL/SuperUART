----------------------------------------------------------------------------------
-- Company: ETROYL
-- Engineer: Dr. Ir. Siavash Ardekani
-- 
-- Create Date: 11/06/2023 01:23:48 PM
-- Design Name: 
-- Module Name: TB_SUART - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_UART_I2C is
--  Port ( );
end TB_UART_I2C;

architecture Behavioral of TB_UART_I2C is
component MAIN_BD1 is
    port (
    ext_RSTn  : in STD_LOGIC;
    XU9_LED2  : out STD_LOGIC_VECTOR(0 downto 0);
    ST1_CLK100 : in STD_LOGIC;
    UART_RX : in std_logic;
    UART_TX : out std_logic;
    SDA_i : in std_logic;
    SDA_o : out std_logic;
    SDA_t : out std_logic;
    SCL : out std_logic
    );    
end component MAIN_BD1;

signal CLK: std_logic := '0';
signal RX: std_logic := '1';
signal XU9_LED2: STD_LOGIC_VECTOR ( 0 to 0 );
signal SDA_i: std_logic;
signal SDA_o: std_logic;
signal SDA_t: std_logic;
signal SCL: std_logic;
signal UART_TX: std_logic;
signal clk_suart: std_logic := '0';
signal start_bit: std_logic:= '0';
signal stop_bit: std_logic:= '0';
signal RX_array : std_logic_vector(255 downto 0);


signal i: integer range 1 to 8 := 1;
signal k: integer range 1 to 32 := 1;
signal wait_is_done : std_logic := '0';

begin

--RX_array <= X"5514563700F8A0B0C0D00000CC0AA55A03A5B5C5D500A508FFBC151526A0B003"; -- msb first
RX_array <= X"5514563700F8A5B5C5D50000CC0AA55A03A5B5C5D500A508FFBC151526A0B003"; -- msb first

  BD: MAIN_BD1
    port map (
      ext_RSTn             => '1',
      XU9_LED2             => XU9_LED2,
      ST1_CLK100           => CLK,
      UART_RX              => RX,
      UART_TX              => UART_TX,
      SDA_i                  => SDA_i,
      SDA_o                  => SDA_o,
      SDA_t                  => SDA_t,
      SCL                  => SCL
    );

CLK <= not CLK after 5 ns;
clk_suart <= not clk_suart after 542.53 ns;

process
begin
    wait_is_done <= '0';
    wait for 100 us;
    wait_is_done <= '1';  
    wait;  
end process;

process(clk_suart)
begin
if (rising_edge(clk_suart) and k <= 31 and wait_is_done = '1') then
    if start_bit = '0' then
        RX <= '0';
        start_bit <= '1';
    elsif (i <= 8) then
        RX <= RX_array(255-k*8+i);
        i <= i + 1;
    elsif (stop_bit = '0') then
        RX <= '1';
        stop_bit <= '1';
    else
        i <= 1;
        k <= k + 1;
        start_bit <= '0';
        stop_bit <= '0';
    end if;
end if;
end process;

process
begin
SDA_i <= '1';
wait for 340 us;
SDA_i <= '0';
wait for 10 us;
SDA_i <= '1';
wait for 80 us;
SDA_i <= '0';
wait for 10 us;
SDA_i <= '1';
wait for 205 us;
SDA_i <= '0';
wait for 10 us;
SDA_i <= '1';
wait for 80 us;
SDA_i <= '0';
wait for 10 us;
SDA_i <= '1';
wait for 80 us;
SDA_i <= '0';
wait for 10 us;
SDA_i <= '1';

wait;
end process;

end Behavioral;
