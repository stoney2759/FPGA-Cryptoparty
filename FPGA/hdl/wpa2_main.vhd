--------------------------------------------------------------------------------
--                        wpa2_main.vhd
--    Master file, starting at PBKDF2 and cascading down
--    Copyright (C) 2016  Jarrett Rainier
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha1_pkg.all;


entity wpa2_main is

port(
    clk_i           : in    std_ulogic;
    rst_i           : in    std_ulogic;
    start_i          : in    std_ulogic;
    ssid_dat_i      : in    ssid_data;
    data_dat_i      : in    packet_data;
    anonce_dat      : in    nonce_data;
    cnonce_dat      : in    nonce_data;
    amac_dat        : in    mac_data;
    cmac_dat        : in    mac_data;
    mk_initial      : in   mk_data;
    mk_end          : in   mk_data;
    mk_dat_o        : out   mk_data;
    mk_valid_o      : out   std_ulogic;
    wpa2_complete_o : out   std_ulogic
    );
end wpa2_main;

architecture RTL of wpa2_main is
    
    -- Fixed input format for benchmarking
    -- Generates sample passwords of ten ascii digits, 0-f
    component gen_tenhex
    port(
        clk_i          : in    std_ulogic;
        rst_i          : in    std_ulogic;
        load_i          : in    std_ulogic;
        start_i          : in    std_ulogic;
        start_val_i    : in    mk_data;
        end_val_i    : in    mk_data;
        complete_o     : out    std_ulogic;
        dat_mk_o       : out    mk_data
    );
    end component;
    
    component pbkdf2_main is
    port(
        clk_i               : in    std_ulogic;
        rst_i               : in    std_ulogic;
        load_i              : in    std_ulogic;
        mk_i                : in    mk_data;
        ssid_i              : in    ssid_data;
        dat_o               : out    w_output;
        valid_o             : out    std_ulogic   
    );
    end component;
    
    component wpa2_compare_test
    port(
        clk_i           : in    std_ulogic;
        rst_i           : in    std_ulogic;
        mk_dat_i        : in    mk_data;
        data_dat_i      : in    w_input;
        pke_dat_i       : in    w_input;
        mic_dat_i       : in    w_input;
        pmk_dat_o       : out   pmk_data;
        pmk_valid_o     : out   std_ulogic
    );
    end component;
    
    
    signal w: w_input;
    signal w_temp: w_input;
    
    --signal mk_init_load: std_ulogic;
    signal mk: mk_data;
    signal pmk: pmk_data;
    
    --signal i : integer range 0 to 4;
    
    signal gen_complete: std_ulogic := '0';
    signal comp_complete: std_ulogic := '0';
    signal running: std_ulogic := '0';
    signal load_gen: std_ulogic := '0';
    signal start_gen: std_ulogic := '0';
 
    signal pbkdf_valid              : std_ulogic;
    signal pbkdf_load              : std_ulogic := '0';
    signal pbkdf_mk                : mk_data;
    signal pbkdf_ssid              : ssid_data;
    signal pbkdf_dat               : w_output;
    
begin

    gen1: gen_tenhex port map (clk_i,rst_i,load_gen,start_gen,mk_initial,mk_end,gen_complete,mk);
    pbkdf2: pbkdf2_main port map (clk_i,rst_i, pbkdf_load, pbkdf_mk, pbkdf_ssid, pbkdf_dat, pbkdf_valid);
    comp1: wpa2_compare_test port map (clk_i,rst_i,mk,w,w,w,pmk,comp_complete);


    process(clk_i)   
    begin
        if (clk_i'event and clk_i = '1') then
            if rst_i = '1' then
                wpa2_complete_o <= '0';
                running <= '0';
                --mk_init_load <= '1';
            else
                if start_i = '1' then
                    running <= '1';
                    load_gen <= '1';
                elsif load_gen = '1' then
                    load_gen <= '0';
                    start_gen <= '1';
                else
                    start_gen <= '0';
                end if;
                --mk_init_load <= '0';
                if gen_complete = '1' or comp_complete = '1' then
                    wpa2_complete_o <= '1';
                    running <= '0';
                else
                    wpa2_complete_o <= '0';
                end if;             
            end if;
        end if;
    end process;
    
    
    mk_valid_o <= comp_complete;   

end RTL; 