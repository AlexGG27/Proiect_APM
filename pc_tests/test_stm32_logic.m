function ok = test_stm32_logic()
state_wait_release = 0;
state_wait_press = 1;
state_transmit = 2;

ok = true;

if run_case([hex2dec('C0') hex2dec('C0') hex2dec('C0')], [1 1 1], 0, 0, 0)
    fprintf('PASS idle_does_not_transmit\n');
else
    fprintf('FAIL idle_does_not_transmit\n');
    ok = false;
end

if run_case([hex2dec('C0') hex2dec('C0') hex2dec('C0') hex2dec('C0')], [0 1 1 0], 1, hex2dec('C0'), hex2dec('C0'))
    fprintf('PASS agc_left_transmit\n');
else
    fprintf('FAIL agc_left_transmit\n');
    ok = false;
end

if run_case([hex2dec('CA') hex2dec('CA') hex2dec('CA')], [0 1 0], 1, hex2dec('CA'), hex2dec('CA'))
    fprintf('PASS mf_right_transmit\n');
else
    fprintf('FAIL mf_right_transmit\n');
    ok = false;
end

if ok
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

    function pass = run_case(bus_values, prg_levels, expected_tx, expected_led, expected_pcda)
        state = state_wait_release;
        sampled_command = uint8(0);
        last_led = uint8(0);
        last_pcda = uint8(0);
        tx_count = 0;

        for idx = 1:numel(bus_values)
            sampled_command = uint8(bus_values(idx));
            prg = prg_levels(idx);

            switch state
                case state_wait_release
                    if prg == 0
                        state = state_wait_press;
                    end
                case state_wait_press
                    if prg ~= 0
                        state = state_transmit;
                    end
                case state_transmit
                    last_led = sampled_command;
                    last_pcda = sampled_command;
                    tx_count = tx_count + 1;
                    state = state_wait_release;
            end
        end

        pass = tx_count == expected_tx && last_led == uint8(expected_led) && last_pcda == uint8(expected_pcda);
    end
end
