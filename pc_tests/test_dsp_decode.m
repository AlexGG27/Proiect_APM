function ok = test_dsp_decode()
mode_agc = 0;
mode_ale = 1;
mode_mf = 2;
mode_bypass = 3;

cases = {
    hex2dec('C0'), mode_agc, 0, 'agc_left';
    hex2dec('C1'), mode_ale, 0, 'ale_left';
    hex2dec('C2'), mode_mf, 0, 'mf_left';
    hex2dec('C8'), mode_agc, 1, 'agc_right';
    hex2dec('C9'), mode_ale, 1, 'ale_right';
    hex2dec('CA'), mode_mf, 1, 'mf_right';
    hex2dec('00'), mode_bypass, 0, 'invalid_bypass'
};

ok = true;

for k = 1:size(cases, 1)
    command = cases{k, 1};
    expected_mode = cases{k, 2};
    expected_channel = cases{k, 3};
    label = cases{k, 4};

    [mode_value, channel_value] = decode_command(command);

    if mode_value == expected_mode && channel_value == expected_channel
        fprintf('PASS %s\n', label);
    else
        fprintf('FAIL %s\n', label);
        ok = false;
    end
end

if ok
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

    function [mode_value, channel_value] = decode_command(command)
        valid_mask = hex2dec('C0');
        valid_bits = hex2dec('C0');
        id_mask = hex2dec('07');
        channel_mask = hex2dec('08');

        channel_value = bitshift(bitand(command, channel_mask), -3);

        if bitand(command, valid_mask) ~= valid_bits
            mode_value = mode_bypass;
            channel_value = 0;
            return;
        end

        mode_value = bitand(command, id_mask);
        if mode_value >= 3
            mode_value = mode_bypass;
        end
    end
end
