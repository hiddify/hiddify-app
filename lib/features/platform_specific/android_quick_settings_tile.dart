// void setTileLable(Tile tile, WidgetRef ref) {
//   final t = ref.watch(translationsProvider).requireValue;
//   final connectionStatus = ref.watch(connectionNotifierProvider);
//   final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
//   tile.label = activeProfile?.name ?? t.general.appTitle;

//   final activeProxy = ref.watch(activeProxyNotifierProvider);
//   final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

//   tile.subtitle = switch (connectionStatus) {
//     AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
//     AsyncData(value: Connected()) => "{delay}ms",
//     _ => "",
//   };
// }

// // QuickSettings setup
// void setupQuickSettings(WidgetRef ref) {
//   final connectionStatus = ref.read(connectionNotifierProvider.notifier);
//   @pragma("vm:entry-point")
//   Tile onTileClicked(Tile tile) {
//     final t = ref.read(translationsProvider).requireValue;

//     final oldStatus = tile.tileStatus;
//     connectionStatus.toggleConnection();
//     if (oldStatus == TileStatus.active) {
//       tile.tileStatus = TileStatus.inactive;
//       tile.subtitle = t.connection.disconnecting;
//     } else {
//       tile.tileStatus = TileStatus.active;
//       tile.subtitle = t.connection.connecting;
//     }
//     return tile;
//   }

//   @pragma("vm:entry-point")
//   Tile onTileAdded(Tile tile) {
//     setTileLable(tile, ref);
//     return tile;
//   }

//   @pragma("vm:entry-point")
//   void onTileRemoved() {
//     print("Tile removed");
//   }

//   QuickSettings.setup(
//     onTileClicked: onTileClicked,
//     onTileAdded: onTileAdded,
//     onTileRemoved: onTileRemoved,
//   );

//   final t = ref.read(translationsProvider).requireValue;

//   QuickSettings.addTileToQuickSettings(label: t.general.appTitle, drawableName: "ic_launcher");
// }
