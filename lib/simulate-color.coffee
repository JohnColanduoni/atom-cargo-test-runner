UNDERLINE_REGEX = /\^(\~)+/g
ERROR_REGEX = /error(?=:)/g
WARNING_REGEX = /warning(?=:)/g
TEST_FAILED_REGEX = /FAILED$/mg
TEST_PASSED_REGEX = /ok$/mg

module.exports.simulateColor = (data) ->
  data
    .replace(UNDERLINE_REGEX, '<span class="source-underline">$&</span>')
    .replace(ERROR_REGEX, '<span class="error">$&</span>')
    .replace(WARNING_REGEX, '<span class="warning">$&</span>')
    .replace(TEST_FAILED_REGEX, '<span class="test-failed">$&</span>')
    .replace(TEST_PASSED_REGEX, '<span class="test-passed">$&</span>')
