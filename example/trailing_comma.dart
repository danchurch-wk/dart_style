class ExtremelyVerboseClassThatDoesntReallyHaveAPoint {
  ExtremelyVerboseClassThatDoesntReallyHaveAPoint(
    Object objectToPrintToStandardOutput,
    bool shouldActuallyPrintObjectToStandardOutput,
  ) {
    if (!shouldActuallyPrintObjectToStandardOutput) return;

    print(objectToPrintToStandardOutput);
  }
}

void main() {
  ExtremelyVerboseClassThatDoesntReallyHaveAPoint('', false);
}
