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
            con_sec_dig1 <= std_logic_vector(to_unsigned((to_integer(unsigned(seconds)) mod 10),8) + 48);  
            con_min_dig1 <= std_logic_vector(to_unsigned((to_integer(unsigned(minutes)) mod 10),8) + 48);  
            con_hou_dig1 <= std_logic_vector(to_unsigned((to_integer(unsigned(hours)) mod 10),8) + 48);  
            
            if unsigned(seconds) < to_unsigned(10,7) then 
                con_sec_dig2 <= X"30";
            elsif unsigned(seconds) < to_unsigned(20,7) then 
                con_sec_dig2 <= X"31"; 
            elsif unsigned(seconds) < to_unsigned(30,7) then 
                con_sec_dig2 <= X"32";
            elsif unsigned(seconds) < to_unsigned(40,7) then 
                con_sec_dig2 <= X"33";
            elsif unsigned(seconds) < to_unsigned(50,7) then 
                con_sec_dig2 <= X"34";
            elsif unsigned(seconds) < to_unsigned(60,7) then 
                con_sec_dig2 <= X"35"; 
            end if; 
            
            if unsigned(minutes) < to_unsigned(10,7) then 
                con_min_dig2 <= X"30";
            elsif unsigned(minutes) < to_unsigned(20,7) then 
                con_min_dig2 <= X"31"; 
            elsif unsigned(minutes) < to_unsigned(30,7) then 
                con_min_dig2 <= X"32";
            elsif unsigned(minutes) < to_unsigned(40,7) then 
                con_min_dig2 <= X"33";
            elsif unsigned(minutes) < to_unsigned(50,7) then 
                con_min_dig2 <= X"34";
            elsif unsigned(minutes) < to_unsigned(60,7) then 
                con_min_dig2 <= X"35"; 
            end if;                

            if unsigned(hours) < to_unsigned(10,5) then 
                con_hou_dig2 <= X"30";
            elsif unsigned(hours) < to_unsigned(20,5) then 
                con_hou_dig2 <= X"31"; 
            end if;
        
        end if; 
    end process; 
end time2vectors;
