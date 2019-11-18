// irdartfmt -w -l 120 --fix-prefer-multiline-cascade

class ContextMenuGroup {
  void addExistingContextMenuItem(m) {}
  void addExistingContextMenuItems(m) {}
}

void main() {
  final menuGroups = [];
  dynamic items;

  menuGroups.add(
    new ContextMenuGroup()
      ..addExistingContextMenuItem(items.moveUp)
      ..addExistingContextMenuItems(items.moveDown),
  );

  menuGroups.add(new ContextMenuGroup()
    ..addExistingContextMenuItem(items.moveUp)
    ..addExistingContextMenuItem(items.moveDown));

  menuGroups.add(
    new ContextMenuGroup()
      ..addExistingContextMenuItem(items.moveUp)
      ..addExistingContextMenuItem(items.moveDown),
  );
}
