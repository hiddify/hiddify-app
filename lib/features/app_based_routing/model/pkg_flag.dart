enum PkgFlag {
  userSelection(1 << 0),
  forceDeselection(1 << 1),
  autoSelection(1 << 2);

  final int value;
  const PkgFlag(this.value);

  bool check(int value) => (value & this.value) == this.value;

  int add(int value) {
    int nValue = value;
    if (this == userSelection) {
      nValue = forceDeselection.remove(nValue);
    } else if (this == forceDeselection) {
      nValue = userSelection.remove(nValue);
    }
    return nValue | this.value;
  }

  int remove(int value) => value & ~this.value;

  int toggle(int value) => value ^ this.value;

  static bool? checkboxValue(int flag) => switch (flag) {
    _ when forceDeselection.check(flag) => false,
    _ when autoSelection.check(flag) && !userSelection.check(flag) => null,
    _ when userSelection.check(flag) => true,
    _ => null,
  };
}
