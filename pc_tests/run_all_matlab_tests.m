function ok = run_all_matlab_tests()
ok = true;

fprintf('Running MATLAB/Octave project tests...\n');

if ~test_stm32_logic()
    ok = false;
end

if ~test_dsp_decode()
    ok = false;
end

fprintf('You can also run the algorithm example scripts from:\n');
fprintf('  Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab\n');
fprintf('  test_AGC.m\n');
fprintf('  test_ALE.m\n');
fprintf('  test_MF.m\n');

if ok
    fprintf('ALL MATLAB TESTS PASSED\n');
else
    fprintf('SOME MATLAB TESTS FAILED\n');
end
end
