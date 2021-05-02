--------------------------------------------------------------------------------
--
--   FileName:         pmod_real_time_clock.vhd
--   Dependencies:     i2c_master.vhd (Version 2.2)
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 12/18/2020 Scott Larson
--     Initial Public Release
-- 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY pmod_real_time_clock IS
  GENERIC(
    sys_clk_freq : INTEGER := 125_000_000);               --input clock speed from user logic in Hz
  PORT(
    clk           : IN    STD_LOGIC;                     --system clock
    reset_n       : IN    STD_LOGIC;                     --asynchronous active-low reset
    scl           : INOUT STD_LOGIC;                     --I2C serial clock
    sda           : INOUT STD_LOGIC;                     --I2C serial data
    i2c_ack_err   : OUT   STD_LOGIC;                     --I2C slave acknowledge error flag
    set_clk_ena   : IN    STD_LOGIC;                     --set clock enable
    set_seconds   : IN    STD_LOGIC_VECTOR(6 DOWNTO 0);  --seconds to set clock to
    set_minutes   : IN    STD_LOGIC_VECTOR(6 DOWNTO 0);  --minutes to set clock to
    set_hours     : IN    STD_LOGIC_VECTOR(4 DOWNTO 0);  --hours to set clock to
    set_am_pm     : IN    STD_LOGIC;                     --am/pm to set clock to, am = '0', pm = '1'
    set_weekday   : IN    STD_LOGIC_VECTOR(2 DOWNTO 0);  --weekday to set clock to
    set_day       : IN    STD_LOGIC_VECTOR(5 DOWNTO 0);  --day of month to set clock to
    set_month     : IN    STD_LOGIC_VECTOR(4 DOWNTO 0);  --month to set clock to
    set_year      : IN    STD_LOGIC_VECTOR(7 DOWNTO 0);  --year to set clock to
    set_leapyear  : IN    STD_LOGIC;                     --specify if setting is a leapyear ('1') or not ('0')
    seconds       : OUT   STD_LOGIC_VECTOR(6 DOWNTO 0);  --clock output time: seconds
    minutes       : OUT   STD_LOGIC_VECTOR(6 DOWNTO 0);  --clock output time: minutes
    hours         : OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);  --clock output time: hours
    am_pm         : OUT   STD_LOGIC;                     --clock output time: am/pm (am = '0', pm = '1')
    weekday       : OUT   STD_LOGIC_VECTOR(2 DOWNTO 0);  --clock output time: weekday
    day           : OUT   STD_LOGIC_VECTOR(5 DOWNTO 0);  --clock output time: day of month
    month         : OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);  --clock output time: month
    year          : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0)); --clock output time: year
END pmod_real_time_clock;

ARCHITECTURE behavior OF pmod_real_time_clock IS
  TYPE machine IS(start, route, set_clock, read_clock, output_result); --needed states
  SIGNAL state       : machine;                        --state machine
  SIGNAL i2c_ena     : STD_LOGIC;                      --i2c enable signal
  SIGNAL i2c_addr    : STD_LOGIC_VECTOR(6 DOWNTO 0);   --i2c address signal
  SIGNAL i2c_rw      : STD_LOGIC;                      --i2c read/write command signal
  SIGNAL i2c_data_wr : STD_LOGIC_VECTOR(7 DOWNTO 0);   --i2c write data
  SIGNAL i2c_data_rd : STD_LOGIC_VECTOR(7 DOWNTO 0);   --i2c read data
  SIGNAL i2c_busy    : STD_LOGIC;                      --i2c busy signal
  SIGNAL busy_prev   : STD_LOGIC;                      --previous value of i2c busy signal
  SIGNAL set_clk_req : STD_LOGIC;                      --set clock request flag
  SIGNAL wr_buffer   : STD_LOGIC_VECTOR(55 DOWNTO 0);  --data buffer to write to real time clock
  SIGNAL rd_buffer   : STD_LOGIC_VECTOR(55 DOWNTO 0);  --data buffer read from real time clock
  
  COMPONENT i2c_master IS
    GENERIC(
      input_clk : INTEGER;  --input clock speed from user logic in Hz
      bus_clk   : INTEGER); --speed the i2c bus (scl) will run at in Hz
    PORT(
      clk       : IN     STD_LOGIC;                     --system clock
      reset_n   : IN     STD_LOGIC;                     --active low reset
      ena       : IN     STD_LOGIC;                     --latch in command
      addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0);  --address of target slave
      rw        : IN     STD_LOGIC;                     --'0' is write, '1' is read
      data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);  --data to write to slave
      busy      : OUT    STD_LOGIC;                     --indicates transaction in progress
      data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  --data read from slave
      ack_error : BUFFER STD_LOGIC;                     --flag if improper acknowledge from slave
      sda       : INOUT  STD_LOGIC;                     --serial data output of i2c bus
      scl       : INOUT  STD_LOGIC);                    --serial clock output of i2c bus
  END COMPONENT;

BEGIN

  --instantiate the i2c master
  i2c_master_0:  i2c_master
    GENERIC MAP(input_clk => sys_clk_freq, bus_clk => 400_000)
    PORT MAP(clk => clk, reset_n => reset_n, ena => i2c_ena, addr => i2c_addr,
             rw => i2c_rw, data_wr => i2c_data_wr, busy => i2c_busy,
             data_rd => i2c_data_rd, ack_error => i2c_ack_err, sda => sda,
             scl => scl);       
         
  PROCESS(clk, reset_n)
    VARIABLE busy_cnt : INTEGER RANGE 0 TO 8 := 0;               --counts the busy signal transistions during one transaction
    VARIABLE counter  : INTEGER RANGE 0 TO sys_clk_freq/10 := 0; --counts 100ms to wait before communicating
  BEGIN
    IF(reset_n = '0') THEN               --reset activated
      counter := 0;                        --clear wait counter
      i2c_ena <= '0';                      --clear i2c enable
      busy_cnt := 0;                       --clear busy counter
      set_clk_req <= '0';                  --clear set clock request flag
      wr_buffer <= (OTHERS => '0');        --clear write buffer
      rd_buffer <= (OTHERS => '0');        --clear read buffer
      state <= start;                      --return to start state
    ELSIF(clk'EVENT AND clk = '1') THEN  --rising edge of system clock
      CASE state IS                        --state machine
      
        --give RTC 100ms to power up before communicating
        WHEN start =>
          IF(set_clk_ena = '1') THEN           --request to set the clock received
            set_clk_req <= '1';                  --latch in set clock request to flag
          END IF;
          IF(counter < sys_clk_freq/10) THEN   --100ms not yet reached
            counter := counter + 1;              --increment counter
          ELSE                                 --100ms reached
            counter := 0;                        --clear counter
            state <= route;                      --initate prepare to receive commands
          END IF;
       
        --determine write/read and route to desired state
        WHEN route =>
          IF(set_clk_req = '1' OR set_clk_ena = '1') THEN  --set clock requested
            wr_buffer <= set_year & "00" & set_leapyear & set_month & "00" & set_day & "00000" &            --latch in time and date to set
                         set_weekday & "01" & set_am_pm & set_hours & '0' & set_minutes & '1' & set_seconds;
            state <= set_clock;                              --execute the write transaction
          ELSE                                             --set clock not requested
            state <= read_clock;                             --execute the read transaction
          END IF;
       
        --set the clock with the user specified data
        WHEN set_clock =>
          set_clk_req <= '0';                          --reset set_clk_req flag
          busy_prev <= i2c_busy;                       --capture the value of the previous i2c busy signal
          IF(busy_prev = '0' AND i2c_busy = '1') THEN  --i2c busy just went high
            busy_cnt := busy_cnt + 1;                    --counts the times busy has gone from low to high during transaction
          END IF;
          CASE busy_cnt IS                             --busy_cnt keeps track of which command we are on
            WHEN 0 =>                                    --no command latched in yet
              i2c_ena <= '1';                              --initiate the transaction
              i2c_addr <= "1101111";                       --set the address of the temp sensor
              i2c_rw <= '0';                               --command 1 is a write
              i2c_data_wr <= "00000000";                   --set register address to the Time Register
            WHEN 1 =>                                    --1st busy high: command 1 latched, okay to issue command 2
              i2c_data_wr <= wr_buffer(7 DOWNTO 0);        --start the oscillator and set seconds
            WHEN 2 =>                                    --2nd busy high: command 2 latched, okay to issue command 3
              i2c_data_wr <= wr_buffer(15 DOWNTO 8);       --start the oscillator and set seconds
            WHEN 3 =>                                    --3rd busy high: command 3 latched, okay to issue command 4
              i2c_data_wr <= wr_buffer(23 DOWNTO 16);      --start the oscillator and set seconds
            WHEN 4 =>                                    --4th busy high: command 4 latched, okay to issue command 5
              i2c_data_wr <= wr_buffer(31 DOWNTO 24);      --start the oscillator and set seconds
            WHEN 5 =>                                    --5th busy high: command 5 latched, okay to issue command 6
              i2c_data_wr <= wr_buffer(39 DOWNTO 32);      --start the oscillator and set seconds
            WHEN 6 =>                                    --6th busy high: command 6 latched, okay to issue command 7
              i2c_data_wr <= wr_buffer(47 DOWNTO 40);      --start the oscillator and set seconds
            WHEN 7 =>                                    --7th busy high: command 7 latched, okay to issue command 8
              i2c_data_wr <= wr_buffer(55 DOWNTO 48);
            WHEN 8 =>                                    --8th busy high: command 8 latched
              i2c_ena <= '0';                              --deassert enable to stop transaction after command 8
              IF(i2c_busy = '0') THEN                      --transaction complete
                busy_cnt := 0;                               --reset busy_cnt for next transaction
                state <= route;                              --return to ready state for further commands
              END IF;
            WHEN OTHERS => NULL;
          END CASE;
      
        --retrieve time and date
        WHEN read_clock =>
          IF(set_clk_ena = '1') THEN                   --request to set the clock received
            set_clk_req <= '1';                          --latch in set clock request to flag
          END IF;
          busy_prev <= i2c_busy;                       --capture the value of the previous i2c busy signal
          IF(busy_prev = '0' AND i2c_busy = '1') THEN  --i2c busy just went high
            busy_cnt := busy_cnt + 1;                    --counts the times busy has gone from low to high during transaction
          END IF;
          CASE busy_cnt IS                             --busy_cnt keeps track of which command we are on
            WHEN 0 =>                                  --no command latched in yet
              i2c_ena <= '1';                            --initiate the transaction
              i2c_addr <= "1101111";                     --set the address of the slave
              i2c_rw <= '0';                             --command 1 is a write
              i2c_data_wr <= "00000000";                 --set register address to be read
            WHEN 1 =>                                  --1st busy high: command 1 latched, okay to issue command 2
              i2c_rw <= '1';                             --command 2 is a read (addr stays the same)
            WHEN 2 =>                                  --2nd busy high: command 2 latched, okay to issue command 3
              IF(i2c_busy = '0') THEN                    --indicates data read in command 2 is ready
                rd_buffer(7 DOWNTO 0) <= i2c_data_rd;      --retrieve data from command 2
              END IF;
            WHEN 3 =>                                  --3rd busy high: command 3 latched, okay to issue command 4
              IF(i2c_busy = '0') THEN                    --indicates data read in command 3 is ready
                rd_buffer(15 DOWNTO 8) <= i2c_data_rd;    --retrieve data from command 3
              END IF;
            WHEN 4 =>                                  --4th busy high: command 4 latched, okay to issue command 5
              IF(i2c_busy = '0') THEN                    --indicates data read in command 4 is ready
                rd_buffer(23 DOWNTO 16) <= i2c_data_rd;    --retrieve data from command 4
              END IF;
            WHEN 5 =>                                  --5th busy high: command 5 latched, okay to issue command 6
              IF(i2c_busy = '0') THEN                    --indicates data read in command 5 is ready
                rd_buffer(31 DOWNTO 24) <= i2c_data_rd;    --retrieve data from command 5
              END IF;
            WHEN 6 =>                                  --6th busy high: command 6 latched, okay to issue command 7
              IF(i2c_busy = '0') THEN                    --indicates data read in command 6 is ready
                rd_buffer(39 DOWNTO 32) <= i2c_data_rd;    --retrieve data from command 6
              END IF;
            WHEN 7 =>                                  --7th busy high: command 7 latched, okay to issue command 8
              IF(i2c_busy = '0') THEN                    --indicates data read in command 7 is ready
                rd_buffer(47 DOWNTO 40) <= i2c_data_rd;    --retrieve data from command 7
              END IF;
            WHEN 8 =>                                  --8th busy high: command 8 latched, ready to stop
              i2c_ena <= '0';                            --deassert enable to stop transaction after command 4
              IF(i2c_busy = '0') THEN                    --indicates data read in command 8 is ready
                rd_buffer(55 DOWNTO 48) <= i2c_data_rd;    --retrieve data from command 8
                busy_cnt := 0;                             --reset busy_cnt for next transaction
                state <= output_result;                    --transaction complete, go to next state in design
              END IF;
            WHEN OTHERS => NULL;
          END CASE;
     
        --output retrieved time and date data
        WHEN output_result =>
          IF(set_clk_ena = '1') THEN           --request to set the clock received
            set_clk_req <= '1';                  --latch in set clock request to flag
          END IF;
          seconds <= rd_buffer(6 DOWNTO 0);    --output seconds
          minutes <= rd_buffer(14 DOWNTO 8);   --output minutes
          hours <= rd_buffer(20 DOWNTO 16);    --output hours
          am_pm <= rd_buffer(21);              --output am/pm
          weekday <= rd_buffer(26 DOWNTO 24);  --output weekday
          day <= rd_buffer(37 DOWNTO 32);      --output day of month
          month <= rd_buffer(44 DOWNTO 40);    --output month
          year <= rd_buffer(55 DOWNTO 48);     --output year
          state <= route;                      --return to routing state

        --default to start state
        WHEN OTHERS =>
          state <= start;

      END CASE;
    END IF;
  END PROCESS;   
END behavior;

