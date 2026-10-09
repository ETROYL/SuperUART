-- SPDX-License-Identifier: MIT
-- Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2023 01:35:25 PM
-- Design Name: 
-- Module Name: SplitReg8 - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SplitReg8 is
  Port (
    In0 : in std_logic_vector(7 downto 0);
    Out0 : out std_logic;
    Out1 : out std_logic;
    Out2 : out std_logic;
    Out3 : out std_logic;
    Out4 : out std_logic;
    Out5 : out std_logic;
    Out6 : out std_logic;
    Out7 : out std_logic    
   );
end SplitReg8;

architecture Behavioral of SplitReg8 is

begin
    Out0 <= In0(0);
    Out1 <= In0(1);
    Out2 <= In0(2);
    Out3 <= In0(3);
    Out4 <= In0(4);
    Out5 <= In0(5);
    Out6 <= In0(6);
    Out7 <= In0(7);

end Behavioral;
