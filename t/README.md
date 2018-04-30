## Running the tests

All tests can be run in parrallel with

    prove -j8 t/

### Test options

Most tests can be run with the options provided by
[Config::Model::Tester::Setup](https://metacpan.org/pod/Config::Model::Tester::Setup):

* `-trace`: show more information
* `-error`: show stack stace in case of error
* `-log`: Enable logs (you may need to tweak `~/.log4config-model` to get more trace.
   See [cme/Logging](https://metacpan.org/pod/distribution/App-Cme/bin/cme#Logging) for more details.

### model_tests.t

This test is set of subtests made of test cases. It accepts arguments
to limit the test to one subtest and one test case:

    perl t/model_test.t [ --log ] [--error] [--trace] [ subtest [ test_case ] ]

See [Config::Model::Tester](https://metacpan.org/pod/Config::Model::Tester) for more details.

### Running with prove

You can run all tests with

    prove -j8 t/

To run with local files:

    prove -l -j8 t/

You can pass parameter to test files with:

    prove -l t/ :: --log



