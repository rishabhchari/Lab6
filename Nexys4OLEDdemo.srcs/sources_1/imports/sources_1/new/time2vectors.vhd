library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity time2vectors is
  Port (clk,rst : in std_logic; 
        seconds : in std_logic_vector(6 downto 0); 
        minutes : in std_logic_vector(6 downto 0); 
        hours   : in std_logic_vector(4 downto 0); 
        con_sec_dig1 : out std_logic_vector(7 downto 0); 
        con_sec_dig2 : out std_logic_vector(7 downto 0); 
        con_min_dig1 : out std_logic_vector(7 downto 0); 
        con_min_dig2 : out std_logic_vector(7 downto 0); 
        con_hou_dig1 : out std_logic_vector(7 downto 0);    
        con_hou_dig2 : out std_logic_vector(7 downto 0));
end time2vectors;

architecture time2vectors of time2vectors is
signal sec_dig_1,sec_dig_2,min_dig_1,min_dig_2,hou_dig_1,hou_dig_2 : std_logic_vector(7 downto 0); 

begin

    process(clk,rst) 
    begin 
        if rst = '1' then 
            con_sec_dig1 <= (others => '0'); 
            con_sec_dig2 <= (others => '0'); 
            con_min_dig1 <= (others => '0'); 
            con_min_dig2 <= (others => '0'); 
            con_hou_dig1 <= (others => '0'); 
            con_hou_dig2 <= (others => '0'); 
        elsif(rising_edge(clk)) then 
            sec_dig_1 <= "0000" & seconds(3 downto 0);  
            min_dig_1 <= "0000" & minutes(3 downto 0);  
            hou_dig_1 <= "0000" & hours(3 downto 0);  
            
            sec_dig_2 <= "00000" & seconds(6 downto 4);
            min_dig_2 <= "00000" & minutes(6 downto 4); 
            hou_dig_2 <= "0000000" & hours(4); 
        
            con_sec_dig1 <= std_logic_vector(unsigned(sec_dig_1) + 48); 
            con_sec_dig2 <= std_logic_vector(unsigned(sec_dig_2) + 48); 
            con_min_dig1 <= std_logic_vector(unsigned(min_dig_1) + 48); 
            con_min_dig2 <= std_logic_vector(unsigned(min_dig_1) + 48); 
            con_hou_dig1 <= std_logic_vector(unsigned(hou_dig_1) + 48);
            con_hou_dig2 <= std_logic_vector(unsigned(hou_dig_2) + 48);  
            
        end if; 
    end process; 
end time2vectors;
