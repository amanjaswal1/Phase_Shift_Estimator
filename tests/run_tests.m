function run_tests()
%RUN_TESTS  Run every tests/test_*.m file and report PASS/FAIL.
%
%   Works in MATLAB (R2019b+) and GNU Octave (8+). From the repo root:
%       cd tests; run_tests
%   Throws an error at the end if any test failed (so CI marks the run red).

    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, '..', 'src'));
    if exist(fullfile(here, 'reference'), 'dir')
        addpath(fullfile(here, 'reference'));
    end

    files = dir(fullfile(here, 'test_*.m'));
    names = sort({files.name});
    n_fail = 0;
    fprintf('\nRunning %d tests\n', numel(names));
    fprintf('%s\n', repmat('-', 1, 60));
    for i = 1:numel(names)
        [~, fn] = fileparts(names{i});
        t0 = tic;
        try
            feval(fn);
            fprintf('PASS  %-40s %6.2f s\n', fn, toc(t0));
        catch err
            n_fail = n_fail + 1;
            fprintf('FAIL  %-40s\n      %s\n', fn, err.message);
        end
    end
    fprintf('%s\n', repmat('-', 1, 60));
    fprintf('%d passed, %d failed\n\n', numel(names) - n_fail, n_fail);
    if n_fail > 0
        error('run_tests:failed', '%d test(s) failed.', n_fail);
    end
end
