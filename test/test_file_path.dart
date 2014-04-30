import "dart:io";
import "package:globbing/file_path.dart";
import "package:unittest/unittest.dart";

void main() {
  testExpand();
}

void testExpand() {
  // $key
  var key = Platform.environment.keys.first;
  var value = Platform.environment[key];
  var path = "\$${key}";
  var result = FilePath.expand(path);
  var expected = value;
  expect(result, expected, reason: path);

  // $key/1
  path = "\$${key}/1";
  result = FilePath.expand(path);
  expected = "$value/1";
  expect(result, expected, reason: path);

  // []$key]1
  path = "[]\$${key}]1";
  result = FilePath.expand(path);
  expected = "[]\$$key]1";
  expect(result, expected, reason: path);

  // []$key]/1
  path = "[]\$${key}]/1";
  result = FilePath.expand(path);
  expected = "[]\$$key]/1";
  expect(result, expected, reason: path);

  // [$key]$key/1
  path = "[\$${key}]\$$key/1";
  result = FilePath.expand(path);
  expected = "[\$$key]$value/1";
  expect(result, expected, reason: path);

  // $1
  path = "\$/1";
  result = FilePath.expand(path);
  expected = "\$/1";
  expect(result, expected, reason: path);

  // $/1
  path = "\$/1";
  result = FilePath.expand(path);
  expected = "\$/1";
  expect(result, expected, reason: path);

  // $lower_case/1
  path = "\$lower_case/1";
  result = FilePath.expand(path);
  expected = "\$lower_case/1";
  expect(result, expected, reason: path);

  // $1START_WITH_DIGIT/1
  path = "\$1START_WITH_DIGIT/1";
  result = FilePath.expand(path);
  expected = "\$1START_WITH_DIGIT/1";
  expect(result, expected, reason: path);

  // $HOMElower/1
  path = "\$HOMElower/1";
  var home = FilePath.expand("~");
  result = FilePath.expand(path);
  expected = "${home}lower/1";
  expect(result, expected, reason: path);
}