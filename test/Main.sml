val suites = SMLUnit.Test.TestList [
  NetHostDBTest.suite
]

val () =
  SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} suites

val () =
  OS.Process.exit OS.Process.success
