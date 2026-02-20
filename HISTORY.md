# Changelog


## 4.0.5 (2026-02-20)

#### Other

* Better support for events. 



## v4.0.4 (2026-02-19)

#### New

* Add endpoint to json editor, 

* Add more inbounds(TPROXY, REDIRECT DIRECT) disable pause on desktop. 

* Add ios limits and fix workflow. 

* Better connection management. 

* Add up/down and active profile in android notification. 

* Add HiddifyRPC in android. 

* Add extra security mode. 

* Add fragment button. 

* Add remote config support. 

* Add better platform management. 

* Update the ios interface. 

* Add some more checks. 

* Add real active tag. 

* Upgrade flutter and libs. 

* Add quick setting, organize settings, fix reconnect bug, remove profile tab in mobile, use hiddifynextx forfetch profile in xray mode, update flutter. 

* Refactor configs to better visualisation. 

* Update ci. 

* Upgrade dependencies. 

* Redesign core interface. 

* Add detailed  ipinfo. 

* Redisgn ip panel. 

* Add auto start for mac. 

* Add support for auto start in macos. 

* Add org flag. 

#### Changes

* Remove platform widget. 

* Disable HTTP subscribe link as they create great issue. 

* Some refactor. 

#### Fix

* Issue in profile editor, better error display. 

* Issues. 

* Update build matrix to include Android and Windows targets. 

* Version issue. 

* Update step name for Flutter setup in build workflow. 

* Correct syntax for conditional in Flutter setup for arm64. 

* Update Flutter setup condition for non-linux-arm64 platforms. 

* Bug. 

* Prepare. 

* Remove unused variables for zip file path in windows release process. 

* Update app icon type to use stock icon for consistency. 

* Update AppImage build command to disable appstream and correct file move. 

* Downgrade `sentry_flutter` to remove jni dependency (avoids forced JDK installation) 

* Update AppImage post-processing steps and improve Docker volume mounts. 

* Update build targets for Android to include AAB format and fix windows-install-deps. 

* Sticky notif. 

* Update macOS version from 13 to 15 in build workflow. 

* Replace flutter_distributor with fastforge for macOS and iOS packaging. 

* Improve sh compatibility. 

* Change variable assignment from := to = for consistency in Makefile. 

* Update sed command definition for Windows compatibility. 

* Workflow. 

* Workflow. 

* Persistent data after uninstalling Windows EXE. 

* Issue in ios and imrpove stablity. 

* Android bug. 

* Notification AND VPN MODE  in android. 

* Font json editor. 

* Ios. 

* Per app proxy. 

* Tile service. 

* Windows build issue. 

* Typo. 

* Bugs and improvement. 

* Select tag bug. 

* Makefile path issue in Windows OS. 

* Linux installation. 

* Ios build. 

* Bug. 

* Interface change and warp crash. 

* Quicktile bug and update to singbox 10.3. 

* Bug? 

* Macos. 

* Macos build. 

* Emoji in profile and proxies. 

* No commit message. 

* Ios. 

* Ios interface. 

* Name changing. 

* Typos for ios. 

#### Other

* Merge branch 'new-design-v2' 

* Fix arm build. 

* Refactor: update InboundOptions fields and translations for direct and redirect ports. 

* Add naive. 

* Fix. 

* Update. 

* Merge pull request #36 from veto9292/new-design-v2. 
  _CI_

* Feat: add supported MIME types for app links on Linux AppImage. 

* Refactor: rename macOS and iOS install dependencies targets and update activation command. 

* Speedup ci. 

* Merge. 

* Feat: enhance logging in Makefile with color-coded output. 

* Feat: add post-processing for Windows portable zip release. 

* Fix CI: "copy to out" for "windows" 

* Fix CI: Copy to out Windows. 

* Fix CI: skipping chmod for tar. 

* Fix CI: NDK version. 

* Fix CI: linux AppImage build. 

* Fix CI: linxu AppImage build. 

* If: REQUIRED_VER in Makefile. 

* Update: hiddify-core.diff. 

* Generate: proto files. 

* Add protoc_plugin activation to linux-install-deps. 

* Fix CI "Build platform" 

* Fix CI "Setup dependencies" 

* Fix connection change issue and more and more optimisation. 

* Update psiphon add new dns manager, fix ios ipv6 issue. 

* Add proxy usage bytes, psiphon and more and more. 

* New balancer approach. 

* Better proxy,fix ios. 

* New add amnezia, wiregaurd raw config, wiregaurd noise. 

* Add inner proxy link, add debounce. 

* Revert makefile. 

* Fixes and improvements. 

* Update ios. 

* Better android vpn service start and fix bugs. 

* Update android codes to latest singbox. 

* Update macos. 

* Update fultter. 

* Merge. 

* Merge pull request #34 from veto9292/small-fix/fastforge-apk-release. 
  _fastforge migration (android, windows, linux) | storage and path | format codebase | upgrade flutter | flutter discontinued package | dart style | restore window state on Desktops | fastforge release-apk (small fix)_

* Merge remote-tracking branch 'h/new-design-v2' into small-fix/fastforge-apk-release. 

* Remove forgotten test parameter. 

* Implement window state persistence and position validation - Added `saveWindowState` to persist window size, position, and maximized state. - Added `initWindowState` to restore window bounds with safety checks. - Implemented `checkWindowVisibility` to prevent off-screen startup in multi-monitor setups. 

* Calling saveWindowState in onWindow (Resized, Moved, Maximize, Unmaximize) methods. 

* Add window (position, size, maximize) preferences to general_preferences. 

* Relocate 'window silent start' logic to window_notifier.dart. 

* Installing 'screen_retriever' package. 

* Format .dart files. 

* Fix dart formatter width. 

* Replace flutter_markdown with flutter_markdown_plus and update version in pubspec.yaml; adjust pubspec.lock accordingly. 

* Upgrade Flutter and SDK versions; update NDK and Kotlin plugin versions; refresh package dependencies in pubspec.lock. 

* Added 'Hiddify Dev Windows Portable' config to launch.json for easier testing and development of the Windows Portable version. 

* Migrate release builds to fastforge and overhaul Linux/Docker systems. 
  _This major update migrates all release pipelines (except macOS/iOS) to fastforge and completely overhauls the Linux build process.

### Migration to fastforge
- Migrated all release commands to fastforge for consistency and better management.
- Replaced legacy build scripts with fastforge commands for Windows, Linux, and Android.
- Android APK/AAB builds now utilize fastforge instead of raw commands.

### Linux Build Refactor
- Introduced `linux-release-docker` command.
- Updated `linux-release-appimage` with new post-build scripts.
- Implemented `Linux Install Deps` script:
  - Automatically prepares the environment (Ubuntu/WSL).
  - Clones Flutter SDK from GitHub (stable branch) instead of downloading the archive.
  - Checks out the specific Flutter version defined in `pubspec.yaml` using `Linux Flutter Sync`.
  - Installs required dependencies from `linux_deps.list`.
- Rewrote AppImage packaging:
  - Manually constructs the AppImage directory structure.
  - Injects a custom `AppRun` script.
  - Implements a self-contained portable data structure:
    - Creates `hiddify.appimage.home` directory alongside the AppImage.
    - Stores configuration and user data within this directory to keep the system clean.

### Dockerized Build System
- Added `linux-release-docker` for building Linux artifacts without a local Linux environment.
- Caches Flutter SDK and Pub packages via Docker volumes to speed up subsequent builds.
- Outputs artifacts to `dist_docker` directory on the host machine.

### Windows Improvements
- Updated `windows-release-zip` to include the `portable` environment variable for portable builds.

### Other Changes
- Added `linux_deps.list` to centralize dependency management.
- Added `linux-flutter-sync` to `linux-prepare` command.
- Introduced `LINUX_DEPS` variable to extract package list from `linux_deps.list`.
- Introduced `REQUIRED_VER` variable to extract Flutter version from `pubspec.yaml`.
- Added `linux-flutter-sync` command to ensure the installed Flutter version matches `pubspec.yaml`._

* - Update getDatabaseDirectory to support portable mode based on the `` env var. - Create 'hiddify_portable_data' in the app directory if running in portable mode. - Add 'checkDirectoryAccess' to verify read/write permissions for the portable data folder. - Fallback to the default system path if write access to the portable directory is denied. 

* - Add  environment variable to identify the Windows portable version - This variable is set during the 'windows-release-zip' build process. 

* On Linux, left-clicking the tray icon opens the context menu instead of triggering `onTrayIconMouseDown`. Added a "Dashboard" menu item as a workaround to allow users to open the app window. 

* - Ignore MSIX self-signed keys to prevent accidental commit of secrets - Add dist_docker directory (Docker build output) to ignored paths. 

* - Enable Linux artifact building without requiring a local Linux environment (e.g., WSL or native Ubuntu) - Designed to be executed via the 'linux-release-docker' command in the Makefile. 

* Add some comments. 

* Pin Flutter SDK version and register new icon asset - Explicitly define Flutter SDK version in pubspec.yaml for consistency. - Note: This version is critical as it is parsed by Makefile and Dockerfile to setup the build environment. - Add 'ic_launcher_border.png' to the assets list. 

* Created a dedicated list file for Linux dependencies and integrated it into both Dockerfile and Makefile. 

* Switched to C++17 to ensure better compatibility with modern libraries and potential future dependencies. 

* Add some comments. 

* Update AppImage configuration in make_config.yaml - Remove app_run_file parameter (AppRun is now injected post-build) - Fix icon path - Update AppRun: Add install_integration to setup icons and create local .desktop entry with correct Exec path - Ensure index.theme creation if missing. 

* Update deb configuration in make_config.yaml - Add comments for supported_mime_type parameter - Add user data cleanup script to postuninstall_scripts - Update postinstall_scripts to set StartupWMClass to app.hiddify.com and remove conflicting hiddify.desktop from .local. 

* We decided to remove RPM packaging for the following reasons: - Flutter officially supports Debian-based systems only. - Persistent issues with dependency linking. - High maintenance overhead (requires Fedora environment setup). - Successful builds do not guarantee runtime stability on Red Hat-based systems. 

* Update MSIX config in make_config.yaml - Complete the list of supported languages - Add commented-out parameters for self-signed certificate. 

* Update exe configuration in make_config.yaml - Update publisher_url from hiddify-next to hiddify-app - Fix app_icon.ico path - Complete list of setup locales - Remove redundant 'executable_name' and 'output_base_file_name' parameters. 

* Synchronizing main_prod.dart with main.dart. 

* Removing "distribute_options.yaml" because we are using "fastforge package" command and "distribute_options.yaml" is realated to "fastforge release" command. 

* Fixing riverpod issue with adding "agreed" parameter to recurcise method (applyConfigOption) and using this paramter instead of reading provider state in next call. 

* Small fix/ using _prefs instead of ref.read. 

* "not important" formating text for better understaning changes in next commits. 

* Renaming db name and import path. 

* Removing "DbV1" provider and renamign "DbV2" to "Db" 

* Renaming "db_v2" to "db" and using this "db" as main database by adding onUpgrade and increasing "schemaVersion" to 5 and fixing directory issue by adding "native" parameter to "driftDatabase" method. 

* Generation new steps.dart for new database. 

* Removing migration helper for copying data from "db_v1" to "db_v2" 

* "not important" formating text for better understaning changes in next commit. 

* Updating "test\drift". auto generated with drift_dev. 

* Moving "db_v1" schemas to "schemas\db" and generation "schema_v5" 

* Removing "db_v2" and rename "db_v1" to "db" 

* Merge branch 'new-design-v2' into remove/geo-assets. 

* Update release files. 

* Improve notification AND VPN MODE  in android. 

* Merge pull request #30 from veto9292/remove/geo-assets. 
  _Remove/geo assets_

* Removing "get-geo-assets" target from "Makefile" 

* Removing "MissingGeoAssets" from "ConnectionFailure" 

* Moving "GeoAssetType" to "db_v1" 

* Removing translations related to "geo-assets" 

* Removing lib\features\geo_asset. 

* Merge pull request #29 from veto9292/fix/reported-issues-v1. 
  _Fix/reported issues v1_

* Update/test file. auto generated with drift_dev. 

* Update/ using DbV2 instead of AppDatabase. 

* Comment geo asset data 'mapper | source' 

* New/ run db migration from v1 to v2 in bootstrap. 

* New/ db migration helper from v1 to v2. 

* Improve/ renaming. add dbV2 provider. 

* New/creating db_v2 that equals db_v1 v5 schema. downgrade db_v1 to v4 schema. merging tables logics with db logics. 

* Update/schemas move db schema to new location and regenerate db_v1 schema_v4. 

* Update/build.yaml add 'db v2' path to drift_dev. changing drift_dev path (schema_dir, db_v1). 

* Fix/ with the new version of go_router, there is no need to add a navigatorKey to StatefulShellBranch to preserve its state. 

* Small fix/warnings "unnecessary_underscores" 

* Fix/ fixing prevent closing branch issue... removing "back_button_interceptor" and "prevent_closing_branch.dart"... upgrading go_router to 16.2.4 and using "PopScope" instead of "back_button_interceptor" package. 

* Small fix/ add: Warp, Fragment, and Padding icons in Settings option. Change the icon for the 'Padding-Size' option. 

* Update macos. 

* Merge pull request #28 from veto9292/chore/upgrade-flutter-version. 
  _Chore/upgrade flutter version_

* Resolve dependency conflicts for Flutter upgrade. 
  _Upgraded development dependencies to support the Flutter SDK migration
from version 3.32.5 to 3.35.4 and resolve version solving failures._

* Merge pull request #27 from veto9292/feature/i18n-refactor. 
  _Feature/i18n refactor_

* Small fix/ update pages.profiles.updateSub to updateSubscriptions. "Update connection profiles" => "Update subscriptions" 

* Refactor(localization): Sync codebase with new i18n structure. 
  _This commit adapts the application's source code to the newly restructured and renamed translation files. It ensures all UI text is correctly referenced and improves how feedback messages are handled.

- Updated all translation keys throughout the source code to align with the new nested structure.
- Added and corrected translations for user-facing toasts to provide appropriate success and failure feedback (e.g., for import/export actions).
- Implemented logic to display newly added translations where they were previously missing._

* Refactor(i18n): Restructure and clean up localization files. 
  _- Restructured keys into a feature-based nested format for better maintainability.
- Renamed files from strings_[locale] to [locale].i18n.json to fix tooling warnings.
- Removed the unused Sorani Kurdish (ckb) locale._

* New/ auto generated by "dart run slang configure" 

* Upgrade/ slang(4.4.0 to 4.5.1) slang_flutter(4.4.0 to 4.8.0) 

* Update workflow. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #26 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ profile_parser_test file was updated based on the changes in 'ProfileParser' 

* Update/ Improved UI/UX and aligned it with the manual section of the 'Add Profile' modal. 

* Update/ using loadingState instead of (save, update, delete & isBusy). ProfileDetailsPage is now used only for editing. The profile_details_notifier was completely rewritten, and the logic for applying and saving changes has been greatly simplified. 

* Update/ using Material icons instead of FluentIcons. 

* Update/ UI improvment. 

* Delete profile_local_override.dart. 

* Small fix/ using Material Icons instead of Cupertino Icons. 

* Update, fix/ fixed 'Free' profiles not updating and made minor changes to align with AddProfileNotifier.addManual. 

* Update, fix/ using Material icons instead of FluentIcons. Fixed the bottom sheet not closing when showing profileDetails. 

* Update/ rename method and use url to upsert. 

* Update/ rename methods. 

* Small fix. 

* Update/ moved part of the deleteProfile logic to ProfileDataSource. replaced the abortConnection method with toggleConnection. 

* Update/ updated AddProfileNotifier methods. added a Tile for isAutoUpdateDisable and to display the auto-update status. made minor changes to the Add button logic. 

* Update/ prevented error display on HTTP request cancellation. removed commented-out code. separated profile addition methods (addClipboard, addManual). rewrote the add method based on profileRepository changes and removed the renaming logic. canceled the request when AddProfileNotifier is disposed. 

* Update/ added profileParser and removed httpClient from the profileRepository's input parameters, adding profileParser as the new input parameter. 

* Update/ removed the local-override logic that was previously added to watchActiveProfile for preserving userOverride. added renaming logic to the insert operation; if a name is duplicated, random numbers are appended to the end (using getByName) so the user can differentiate. added logic to check for a profile's existence before editing. to manage the active profile during deletion, the isActive parameter is received. If the profile being deleted is active, another profile is selected as active after its removal. 

* Update/ passing the profile object to connect and reconnect. 

* Update/ parameters of the connect and reconnect methods were changed for simplicity. Commented-out code was removed. applyConfigOption was rewritten to align with the profileOverride changes. 

* Refactor/ deleted methods include (getByName, addByUrl, updateContent, addByContent, updateSubscription, add, patch, fetch). upsertRemote: Handles both creation and updating of remote profiles from a single entry point. It checks for an existing profile via URL to prevent duplicates. addLocal: Allows for creating profiles directly from local string content. offlineUpdate: Enables offline modifications by re-parsing the profile with new content while preserving existing headers. validateConfig: The logic has been updated to correctly handle and apply configuration overrides, which were previously ignored. removed the 'http_client' dependency from the repository. This responsibility has been moved to the 'profile_parser' to better separate concerns. a previously public field has been made private. the 'setActive' and 'deleteById' methods have been formally defined in the abstract interface. 

* Refactor/ converts the static 'ProfileParser' into a service class with access to Riverpod's 'ref'. adds 'addRemote', 'addLocal', 'updateRemote', and 'offlineUpdate' methods using 'fpdart'. moves profile download logic from 'profile_repository' to 'ProfileParser' and rewrites it with 'fpdart'. adds error handling for user-cancelled downloads. reads 'useXrayCoreWhenPossible' directly from 'ref' instead of passing all settings. changes the 'parse' method's input to 'ProfileEntity', simplifying the return logic with 'profile.map'. updates the name parser hierarchy to use the link protocol as a fallback. adds logic to disable profile auto-updates via user override. 

* Remove/ move 'protocol' method from 'link_parsers' to 'profile_parser' 

* Update/ removed 'toEntry' and 'subInfoPatch' methods from 'ProfileEntity'. added 'toInsertEntry' and 'toUpdateEntry' methods and replaced 'map' with 'switch'. added 'userOverride' and 'populatedHeaders' to the 'toEntity' method and renamed 'testUrl' to 'profileOverride'. 

* Update/ renamed 'testUrl' to 'profileOverride'. added a default value of 'Duration.zero' to 'updateInterval'. add/ added 'userOverride' and 'populatedHeaders' to the remote and local models. added a 'UserOverride' model with a version structure to ensure backward compatibility in the future. added isAutoUpdateDisable with default(false) to 'userOverride' 

* Update/ changes to 'ConfigOptionRepository' class: made 'getConfigOptions' private. renamed method 'getFullSingboxConfigOption' to 'fullOptions'. added method 'fullOptionsOverrided', which applies 'profileOverride' to the 'config options' before they're sent. improved error handling with 'fpdart'. 

* Update/ add 'ConfigOptionFailure' to 'ProfileFailure.invalidConfig' parameters to easily convert 'ConfigOptionFailure' to 'ProfileFailure'. add 'cancelByUser' for when an HTTP request is cancelled by the user(this helps to distinguish the error and prevent its display) 

* Update/ add 'ConfigOptionFailure' to 'ConnectionFailure.invalidConfigOption' parameters to easily convert 'ConfigOptionFailure' to 'ConnectionFailure' 

* Update/ schema_v5 test file(auto generated by drift_dev) 

* Delete/ old drift test files. 

* Update/ adding columns(userOverride, populatedHeaders) to profile table in db. renaming test_url column to profileOverride. app_database.steps.dart & drift_schema_v5.json is auto generated by drift_dev. 

* Update/ en, fa translations. add(general.auto, profile.add.disableAutoUpdate, failure.profiles.canceledByUser). update(profile.detailsForm.updateInterval). 

* Update/ supporting deselected state for Per-app porxy apps in UI. 

* Update/ bump target/compileSdk to 36; align AGP/Kotlin. 

* Fix/ deprecated warning. 

* New/ apps auto selection modal. features: auto update, reset to default, changing update interval, enable or disable auto-selection, perform now. 

* Update/ using db for managing state. moving and removing providers. adding shareOnGithub to notifier. removing installed apps notifier provider. 

* Update/ notifying user and disabling auto-selection after a region change. 

* New/ activating and managing the per-app proxy auto-selection service. 

* New/ managing loading for asynchronous operations. 

* New/ this service is initialized in app.dart and is responsible for auto-update functionality for auto-selection feature. It is also in charge of updating the active list in prefs. 

* Update/ new sort logic with 4 priority. using hooks for getting and managing installed apps. auto sort feature. adding scroll to top feature. adding loading for share to all. adding FAB for auto selection modal. 

* Fix/ AppProxyMode not found error. 

* New/ AppProxyDao is for interacting with the AppProxyEntries table. 

* Update/ change return types from List to Set. removing share method from repository. renaming methods. using AppProxyMode instead of PerAppProxyMode. 

* New/ appProxyDataSourceProvider. 

* New/remove/ adding AppPackageInfo as a replacement for InstalledPackageInfo to store installed apps. 

* New/ per_app_proxy_backup model is used for import & export. 

* New/ adding AppProxyMode alongside PerAppProxyMode; the difference is the lack of an off state. 

* New/ PkgFlag, managing bit-flags for selected apps in per-app-proxy. 

* Update/ import UI and logic for add_profile_modal.dart. 

* New/update/ moving per_app_proxy_include_list & per_app_proxy_exclude_list to Preferences. adding auto_apps_selection_update_interval & auto_apps_selection_last_update. renaming autoSelectionAppsRegion to autoAppsSelectionRegion. 

* New/ drift migration test files (generated by drift_dev) 

* Add/update/fix/remove/ adding AppProxyEntries to db tables, fixing AppDatabase constructor, adding from4To5 and increasing schemaVersion to 5, generating drit_schema_v5 with drift_dev, removing database_connection.dart. 

* New/ app_database.steps.dart generated by drift_dev. 

* Move file/ moving drift schema from schemas\ to schemas\app_database. 

* New/ adding AppProxyEntries to db tables. 

* Fix/ adding translationsProvider to bootstrap. 

* Update/ en, fa translations new: autoSelection(performNow, resetToDefault) network.share(alreadyInAuto) update: network(clearSelection) autoSelection(dialogTitle, msg, success, regionNotFound) network.share(emptyList) 

* Update/ adding database and schema dir to drift_dev in build.yaml. 

* New/ drift migration test files (generated by drift_dev) 

* Adding method to RuleEnum for getting index of key. 

* Updating en, fa translations. Using " instead of ( for autoSelection.dialogTitle. Adding positiveBtnTxt to per-app proxy share dialog. 

* Improving error management and preventing possible crash for auto_selection_repository. 

* Changing text "Share" to "Share To All" in per-app proxy. 

* Displaying a notification dialog before sharing selected apps. 

* Updation en, fa translations Adding title, dialogTitle, msg to settings.network.share. 

* Merge branch 'fix/reported-issues' of https://github.com/veto9292/hiddify-next-ios into fix/reported-issues. 

* Suggesting auto selection apps when changing region. 

* Improving naming and logic in 'per_app_proxy_page.dart' and adding auto selection, share, import/export to the menu, sorting selected items, using menu for mode selection, setting 'hideSystemApps' with a chip. 

* Improving naming and logic in 'per_app_proxy_notifier.dart' and adding methods (share, clearSelection, autoSelection, export clipboard/file, import clipboard/file). 

* Add auto selection data provider and repository To get the list of proxy/bypass applications from GitHub and share the selected list as an issue. 

* Removing per_app_proxy_data_providers & per_app_proxy_repository Instead, the `installed_apps` package is used. 

* Using MenuAnchor instead of PopupMenuButton in settings_page. 

* Updating en & fa translations adding (import, export, share) to general adding (autoSelection, share, import, export) to setting.network. 

* Adding 'auto_selection_apps_region' to 'general_preferences.dart' 

* Changing the order of buttons in ConfirmationDialog. 

* Renaming 'okText' to 'positiveBtnTxt' for confirmation dialog. 

* Merge pull request #25 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Merge branch 'new-design-v2' into fix/reported-issues. 

* Better log page, upgrade to flutter 3.32.4. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #24 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Merge. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Update flutter. 

* Fixing setSkipTaskbar in macOS and renaming WindowNotifier methods. 

* Updating  window_manager & tray_manager packages. 

* Remove experimental feature references from settings pages and related files. 

* Renaming 'inbound_options.dart' to 'inbound_options_page.dart' 

* Using 'profileDataSourceProvider' instead of 'profileRepositoryProvider' in 'active_profile_notifier.dart' to prevent redundant builds. 

* Removing 'distinct()' from 'profile_repository.dart' and adding it to 'profile_data_source.dart' to prevent emitting extra events. 

* Removing 'async' from 'SingConfigOption' and using watch instead of read. 

* Removing extra file. 

* Preventing redundant builds in 'routing_config_notifier.dart' when the last profile is deleted and 'Breakpoint' is 'isMobile'. 

* Fixing SideBarStatsOverview issue. 

* Removing 'flutter_adaptive_scaffold' and using Flutter SDK. Updating logic related to 'Breakpoint'. 

* Using 'Breakpoint' instead of Breakpoints in 'flutter_adaptive_scaffold' method. 

* Using 'Breakpoint' instead of Breakpoints in 'flutter_adaptive_scaffold' method. 

* Removing 'branchNavKey' and using new 'Breakpoint' logic instead of 'isSmallActive'. 

* Updating 'ActiveBreakpointNotifier' update logic. 

* Renaming 'is_small_active' to 'active_breakpoint_notifier'. Adding 'Breakpoint' class for storing breakpoint and helper methods for detecting the active breakpoint. Changing 'ActiveBreakpointNotifier' output to 'Breakpoint' and adding a provider named 'isMobileBreakpoint'. 

* Commenting out 'PopupCountNotifier'. 

* Using 'rootNavKey' instead of 'branchNavKey'. 

* Using 'rootNavKey' instead of 'branchNavKey' and commenting out 'PopupCountNotifier' methods. 

* Removing flutter_adaptive_scaffold from pubspec. 

* Updating Flutter to 3.32.5 and upgrading pub. Updating intl to 0.20.2. Solving pub get issue by adding humanizer version 3.0.1 instead of getting from GitHub. 

* Organizing per app proxy page. 

* Fix import and use read instead of watch. 

* Unifying the status bar and system navigation bar color with the scaffold color. 

* Fixing profile disappearance (when the profile being updated is selected as the active profile) 

* Improving popup hiding nav bar animation(temporary) 

* Fixing Segmented Button UI in Quick Setting Modal. 

* Fixing routing config rebuilding when deleting profile. 

* Fixing bottom sheet overlapping with keyboard. 

* Fix warp secure lable for connection button. 

* Improve warp generation toast, merge warp loading logic in warp_option_notifier.dart. 

* Improve out animation for bottom sheet when popup is showing. 

* Fix toast direction, removing context from "in_app_notification_controller", add dismissAll() to _show. 

* Removing toast handler from "profiles_modal" and "profiles_page", move toast handler for success or failure profiles update to "profiles_update_notifier" 

* Preventing redundant builds by removing duplicate events from the stream and using "hasAnyProfileProvider" in routing_config_notifier.dart. 

* Adding ToastificationWrapper for showing toast without context. 

* Renaming and organizing files and classes related to "Profiles" 

* Merge pull request #23 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Move popup_count_notifier from dialog_notifier to dedicated file. 

* Rename riverpod_listenable to refresh_listenable. 

* Remove disabled parameter from SideBarStatsOverview. 

* Removing unnecessary files. 

* Remove CustomAlertDialog from alerts.dart (move it to the dialog/widgets) 

* Using dialog notifier, using new global key. 

* Fix bottom sheet typo, rename root nav key. 

* Merge config options with settings feature. 

* Rewriting all items in settings, adding icons, organizing folder structure and files. 

* Rename settings_repository to battery_optimization_repository. 

* Fix imports. 

* Fix imports. 

* Fix imports. 

* Move WarpLicenseDialog.dart to dialog\widgets, fixing import warning dialog_notifier.dart. 

* Move quick settings modal to botto_sheets\widgets, fixing import warning in bottom_sheets_notifier.dart. 

* Show toast instead of dialog for warp success generation. 

* Fix platform_settings_notifier async issue, applying name changes, manage loading state, rewriting platform_settings_tiles and fixing loading. 

* Rename settings_repository to battery_optimization_repository rename settings_data_providers to battery optimization_provider move files. 

* Using dialog notifier, moving SettingTextDialog to dialog/widgets. 

* Using dialog notifier moving SettingsRadioDialog to dialog/widgets. 

* Using dialog notifier, moving setting_checkbox to dialog/widgets. 

* Using dialog notifier. 

* Using dialog notifier. 

* Using dialog notifier. 

* Moving proxy-info dialog to the dialog notifier, using goNamed. 

* Fix bottom sheet typo, using goNamed, using dialog notifier. 

* Using dialog notifier, add ref to _launchUrlWithCheck method. 

* Renaming ProfilesOverviewPage to ProfilesPage, fix bottom sheet typo, use context.goNamed, removing autoImplyLeading "becase routing is fixed" 

* Using dialog notifier. 

* Using dialog notifier. 

* Fix imports. 

* Fix ref and imports. 

* Using dialog notifier. 

* Using dialog notifier. 

* Set return type for dialog. 

* Renaming LogsOverviewPage to LogsPage, use AppBar instead NestedScrollView. 

* Add const to constructor, romoving SafeArea to solve UI issue,  preventing operations during loading. 

* Commenting unused widget, fix bottom sheet typo. 

* Remove showAddProfile and url parameter from HomePage this logic is moved to the redirect in routing-config-notifier. 

* Using dialog notififer, remove showExperimentalNotice "moved to dialog notifier" 

* Using dialog notifier, move showExperimenNotice logic to dialog-notifier. 

* Fix import. 

* Using dialog notifier, changing icons, dynamic icon for theme mode. 

* Fix imports, using dialog notifier. 

* Fix imports, set return type for showing dialog. 

* Fix imports. 

* Move new_version_dialog.dart to lib\core\router\dialog\widgets. 

* Fix ref warning. 

* Move about_page.dart to lib\features\about\widget. 

* PreventClosingApp in routing_config_notifier.dart is used for preventing the branch from closing. It transfers the user to Home route after preventing the closing. 

* Is_small_active.dart IsSmallActive is true when the breakpoint is in the small range, and false otherwise. app.dart Updating the router provider. Assigning a value to IsSmallActive. useEffect has been used for improving performance. 

* CustomTransition is used for adding animation to pages in routing_config_notifier.dart. The purpose of creating this class is to prevent boilerplate code. 

* RoutingConfigNotifier returns a RoutingConfig which is used for updating rConfig in GoRouterNotifier. The structure of routes is defined in RoutingConfigNotifier. The redirect method is defined in RoutingConfigNotifier. By listening to other providers, a new list of routes can be returned dynamically. 

* An instance of RefreshListenable is passed to refreshListenable in GoRouterNotifier. If the notifyListeners method is called, the anonymous redirect function in RoutingConfig is executed. By using ref, a specific provider is listened to, and if it changes, the provider's value is stored globally in a variable, and notifyListeners is called. 

* GoRouterNotifier creates the GoRouter instance that is passed to MaterialApp.router. It holds a RoutingConfig within itself, which gets its value updated by listening to RoutingConfigNotifier. With changes to RoutingConfig, the app's routes will change dynamically. 

* Move dialogs from project to lib\core\router\dialog\widgets fix navigation logic for dialogs add translations. 

* Adding the _show method for managing the number of popups, reducing boilerplate code, and managing context move all dialog to this notifier explicitly specifying a return type. 

* Fix typo(buttom to bottom), adding the _show method for managing the number of popups, reducing boilerplate code, and managing context. 

* Fix import, fix Ref warning, remove "error dialog", changing context that are used for displaying toast. 

* Fix warning/ Ref, import, async. 

* My_adaptive_layout.dart is a shell for the main navigator which is used inside StatefulShellRoute in go_router shell_route_action.dart, which stores information related to each action in my_adaptive_layout.dart. 

* Move my_app_links.dart to lib\core\router\deep_linking. 

* Remove/ app_router.dart, router.dart, routes.dart. 

* New/ move url_protocol to lib\core\router\deep_linking\url_protocol. 

* Update/ translations(en, fa) general.save general.close unknownDomains.title unknownDomains.youAreAboutToVisit unknownDomains.thisWebsiteIsNotInOurTrustedList. 

* Add/ back_button_interceptor package to pubspec, update AndroidManifest (platform-specific setting) 

* Update go_router and flutter_adaptive_scaffold packages, remove go_router_builder package. 

* New/ show "qr dialog" for "allow connection from LAN" 

* Improve/ add comment for network_info_plus package. 

* Add/ network_info_plus package. 

* Small fix/ profile tile radius issue. 

* New/ merge warp license aggrement, seprate warp options logic, move license agreement to connection button and connection repo and more... 

* New/ add missing warp license to connection_failure. 

* Small fix/ warnings & rename testUrl to override. 

* Improve/ add showWarpLicense & showWarpConfig dialog to dialog_notifier. 

* Add translations/ failure.warp.missingLicense & missingLicenseMsg. 

* Small fix/ rename testUrl to override. 

* Fix/ warp license agreeement focus, rename intro page const. 

* Improve/ focus logic for intro page. 

* Fix/ adding a timer for syncing status with changes outside the app. 

* Small fix/ add gap to app bar actions. 

* Small fix/ add gap to app bar action. 

* Fix/ fix warnings, fix focus issue, removing extra code related to focus management. 

* Small fix/ settings_inpu_dialog warnings. 

* Fix slider focus for settings_inpu_dialog.dart SettingsSliderDialog. 

* Small fix/ add-profile slider focus. 

* Fix/ prevent scope switch while overlay is displayed. 

* Remove/ add_manual_profile_modal.dart. 

* Fix/ focus issue for adaptive-scaffold, add keyboard const, fix adaptive_root_scaffold warnings. 

* Small fix/ connection button focus color. 

* Small fix/ improve home_page logic and ui. 

* Fix/rewrite intro_page & fix rich text focus, remove _dynamicRootKey, add intro const. 

* Small fix/ hide adaptive scaffold from intro, fix warnings for routes.dart. 

* Fix/ merge add profile with manual modal(logic & ui), fix cancel for manual. 

* Small fix/ config_options_page(async await) 

* Small fix/ warning(use StringBuffer instead of String) 

* Small fix/ import warning. 

* Small fix/ log message. 

* Package update/ launch_at_startup. 

* Small fix/ fix waring for config_options_page. 

* Merge pull request #22 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ update profile_parser_test. 

* Small fix/ free profile typo. 

* Merge pull request #21 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ neededFeatures(warp to warp_over_proxies) 

* Fix/ free profile typo. 

* New/ overriding profile name and options locally and remotely(profile, fragment, name) 

* Update. 

* Update core. 

* Update flutter. 

* Update pipeline. 

* Change default connection test url to apple. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #20 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ prefer_const_constructors. 

* Small fix/ prefer_final_locals. 

* Small fix/ remove commented imports. 

* Small fix/ remove unused_import. 

* Fix/ UI blocking during connection. 

* Feature/ support for enable-warp in profile headers. 

* Improve/ sync tray begavior in macOS with other Desktops. 

* Improve/ add support for custom scheme in flutter. 

* Setup/ add schemes for Windows. 

* Setup/ add schemes for Linux. 

* Setup/ add schemes for macOS. 

* Setup/ add schemes for iOS. 

* Setup/ add schemes for Android. 

* Feature/ ability to delete active profile. 

* Improve/ show sort profile dialog. 

* Small fix/ format source code, fix warning. 

* Small fix/ 'no active profile' dialog boxConstraints. 

* Moving interrupt handling in proxy reception to core. 

* Update to fultter 3.29.3. 

* Add profilename in start. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #19 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ tray manager logic, bootstrap import. 

* Fix tray_manager, logic rewrite. 

* Fix proxy_overview_page performance issue, improve UI. 

* Hide back button for profiles_overview_page. 

* Improve ux and logic for add_profile_modal by showing region specific message (translation changed) 

* Custom scheme setup for registration in Windows OS (unpackaged app) 

* Setup app_links for flutter, merge app_links with go_router. 

* Setup app_links package for Linux. 

* Setup app_links package for macOS. 

* Setup app_links package for Windows OS. 

* Improve performance. 

* Add upload to app-draft. 

* Improve windows luncher. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #18 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Create custom_text_scroll, fix ButtonSegment over flow. 

* Fix loading height for add_profile_modal. 

* Justification is not possible, remove WrapAlignment.spaceBetween. 

* Remove percent_indicator_premium, fix profile_tile RemainingTrafficIndicator. 

* Fix per_app_proxy performance issue. 

* Remove protocol_handler from Windows and macOS. 

* Fix macos. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #17 from veto9292/fix/reported-issues2. 
  _Fix/reported issues2_

* Fix deep link query-parameter. 

* Fix go router refreshListenable. 

* Handle deep link with go router. 

* Remove protocol_handler, deep_link_notifier. 

* Fix bottom sheets padding. 

* Fix per app proxy error. 

* Edit routes location. 

* Fix canChangeOption. 

* Fix ChoicePreferenceWidget enable (Enable WARP/Detour Mode) 

* Hide auto generated back button for settings page. 

* Return to home page from settings page when back button pressed. 

* Improve ux, preventing back when user intent to work with slider. 

* Preventing delete selected profile. 

* Update deoebdebcies. 

* Merge pull request #15 from veto9292/fix/reported-issues. 
  _fix reported issues and add en, fa translations_

* Fix reported issues and add en, fa translations. 

* Improve android stability. 

* Upgrade flutter to 3.29.1. 

* Update ios macos. 

* Merge pull request #14 from veto9292/fix/proto-and-sentry. 
  _Fix/proto and sentry_

* Remove protoc_builder. 

* Add .sentry-native to .gitignore. 

* Delete .sentry-native folder. 

* Fix route_rule.pb.dart import. 

* Merge pull request #13 from veto9292/feature/route-rule. 
  _Feature/route rule_

* Route rule(not complete) 

* Add route rule regex validators. 

* Add riverpod_observer for better debugging. 

* Config-option file import/export. 

* Custom okText for confirmationDialog and fix content constraints. 

* Add package to pubspec.yaml(file_picker, installed_apps, recase) 

* Fix android. 

* Move proto to core. 

* Merge pull request #12 from veto9292/fix/add-profile. 
  _empty region in free config mean all, fix grid crossAxisCount for single item_

* Empty region mean all, fix grid crossAxisCount for single item. 

* Merge pull request #11 from veto9292/update/add-profile. 
  _update/add_profile_modal_

* Update/add_profile_modal add/free profiles to add_profile_modal remove/http package from pubspec.yaml. 

* Merge pull request #8 from veto9292/fix/makefile. 
  _fix: makefile path issue in Windows OS_

* Merge pull request #10 from veto9292/feature/route-rule. 
  _add: proto packages & route_rule.proto file_

* Add: proto packages & route_rule.proto file. 

* Fix windows compile. 

* Improve ios  and windows. 

* Disallow delete active profile. 

* Better connection management, add bounce and show connection error. 

* Make easier access for quick setuo. 

* Refactor config options. 

* Update pods. 

* Update sentry. 

* Update. 

* Update sqlite3 dependency. 

* Update flutter. 

* Handle profile size. 

* Support correctly ios. 

* Update android libs. 

* Update packages. 

* Show error incase of fail. 

* Upgrade flutter. 

* Some refactor. 

* Refactor router. 

* Refactor: routes. 

* Update. 

* Merge branch 'ios' into new-design-v2. 

* Update dialog to platform dialog. 

* Merge remote-tracking branch 'origin/main' into ios. 

* Update. 

* Update. 

* Merge branch 'fix-latest' into new-design. 

* Update packages and fix web issues. 

* V3. 

* New UI design. 

* Merge remote-tracking branch 'origin/main' into ios-pv. 

* Add make with love in intro. 

* Improve ios UI and integrate it with os. 

* Update. 

* Update ios. 

* Remove 'needed_features' from free_configs. 

* Update free_configs. 

* Update cron schedule and add operations limit. 

* Modify stale.yml for cron schedule and messages. 
  _Updated the stale issue workflow to change the cron schedule and modify the stale issue message and timing._

* Update warp configuration with new server entries. 

* Update profile title in warp configuration. 

* Add new warp configurations and psiphon links. 

* Update title in free_configs for Warp profile. 

* Remove unused configurations for Insta-Youtube and Ainita. 
  _Removed several configurations related to Insta-Youtube and Ainita.net, including their titles, sublinks, tags, and consent messages._

* Change region from '-' to 'k' in free_configs. 
  _Updated region values from '-' to 'k' for two configurations._

* Add Mahsa profile configuration file. 

* Add Mahsa configuration profile to free_configs. 

* Update free_configs. 

* Update warp configuration with new detour format. 

* Update free_configs. 

* Update free_configs. 

* Create ainita. 

* Update free_configs. 

* Chore: update translations with Fink 🐦 

* Update super_fragment. 

* Update super_fragment. 

* Update super_fragment. 

* Update super_fragment. 

* Rename super_fragment.json to super_fragment. 

* Update super_fragment.json. 

* Create super_fragment.json. 

* Update free_configs. 

* Update free_configs. 

* Create free_configs. 

* Update fragment. 

* Update fragment. 

* Update fragment. 

* Create fragment. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README_cn.md. 

* Update README_br.md. 

* Update README.md. 

* Merge pull request #1475 from simonkimi/main. 
  _Profile Tile InkWell Overflow Fix_

* Fix profile_tile clipBehavior. 

* Update README.md. 

* Merge pull request #1464 from kekomenos/patch-1. 
  _Update README.md_

* Update README.md. 
  _<!-- Copy-paste in your Readme.md file -->

<a href="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history?repo_id=643504282" target="_blank" style="display: block" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=643504282&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Star History of hiddify/hiddify-app" src="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=643504282&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->_

* Update README.md. 

* Create README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Merge pull request #1438 from proninyaroslav/linux-fix-silent. 
  _[Linux] Fix minimize to tray (silent start) option_

* [Linux] Fix minimize to tray if the option is enabled. 

* Update LICENSE.md. 

* Update CONTRIBUTING.md. 

* Update README.md. 

* Merge pull request #1403 from ldm0206/main. 
  _Update translations zh-CN_

* Chore: update translations with Fink 🐦 



## v2.5.7 (2024-10-03)

#### Other

* Merge pull request #1382 from TheLastFlame/main. 
  _Remembering window closing action_

* Feat: add action options for closing the application. 

* Chore: update .gitignore to exclude /data directory. 

* Refactor: replace HookConsumerWidget with ConsumerWidget and add ThemeModePrefTile. 



## v2.5.6 (2024-10-02)

#### Fix

* Version bug. 

* Version bug. 



## v2.5.5 (2024-09-29)

#### Other

* Merge pull request #1368 from tarzst/main. 
  _Update RU translations_

* Chore: update translations with Fink 🐦 



## v2.5.2 (2024-09-29)

#### Fix

* Typo. 



## v2.5.1 (2024-09-29)

#### Fix

* Exception. 

* Version. 



## v2.5.0 (2024-09-28)

#### Other

* Merge pull request #1335 from laperuz92/patch-1. 
  _Update russian translations_

* Update russian translations. 

* Merge pull request #1328 from yxiZo/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #1322 from andythesilly/main. 
  _set edgeToEdge ui mode_

* Chore: update translations with Fink 🐦 

* Set edgeToEdge ui mode. 



## v2.3.1 (2024-09-07)

#### Fix

* Android. 

#### Other

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Change name to hiddifypackettunnel. 

* Fix android build issue. 



## v2.3.0 (2024-09-02)

#### New

* Add brazil region. 

#### Fix

* Black screenn when press back button. 

#### Other

* Hide back icon when no back. 

* Merge pull request #1277 from sillydillydiddy/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #1282 from vedantmgoyal9/patch-1. 
  _Update winget-releaser to latest_

* Update winget.yml. 

* Update winget.yml. 

* Update winget-releaser to latest. 

* Merge pull request #1278 from tensionc/main. 
  _fix: Black screenn when press back button_

* Merge remote-tracking branch 'origin/main' 

* Update warp. 

* Update warp. 

* Revert: Keep button, add judgment. 



## v2.2.0 (2024-08-21)

#### New

* Add several values for dns and url test in auto complete mode. 

* Add use xray core option. 

#### Changes

* Default tun mode to gvisor. 

#### Fix

* Bug. 

* Some hard coded items. 

* Apple bug. 

* Bug of back button in rtl flutter 3.24. 

* Naming of links containing &&detour. 

#### Other

* Better auto complete. 

* Remove hindi. 

* Update flutter to 3.24. 

* Merge pull request #1217 from lexxfin/main. 
  _chore: update translations with Fink 🐦_

* Chore: update translations with Fink 🐦 

* Merge pull request #1210 from bLueriVerLHR/main. 
  _Fix typo in stats_repository.dart_

* Fix typo in stats_repository.dart. 

* Chore: update translations with Fink 🐦 

* Include app configs before validaing proxies. 

* Chore: update translations with Fink 🐦 

* Change default warp mode to m4. 



## v2.1.5 (2024-08-05)

#### Fix

* Vpn service issue. 

#### Other

* Revert android changes. 

* Fix warp generation. 

* Try fix vpn. 

* Check macos. 

* Disable mac. 

* Revert changes to android vpn service. 

* Better tryicons. 



## v2.1.4 (2024-08-05)

#### New

* Add exit dialog when press close button. 

* Colorized tray icon. 

#### Fix

* Some bugs. 

* Bugs in tray icon. 

* Fr trnalsation. 

* Translate bug. 

* Single instance flutter in linux? 

#### Other

* Less retry for ipinfo. 

* Add french lang. 

* Test icon linux? 

* Connection button by proxy status indicator, change connected to connecting when timeout. 

* Formated export in json editor. 

* Merge pull request #1174 from Hannisiddiqui/main. 
  _Wanted to add hindi language for indian users_

* Inlang/manage: add languageTag hi. 

* Inlang/manage: install module. 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Update warp. 

* Update release_message.md. 



## v2.1.1 (2024-08-02)

#### New

* Add turkey region. 

#### Other

* Add change log. 



## v2.1.0 (2024-08-02)

#### New

* Add invalid config label. 

#### Fix

* Error migrating from v3 to v4 database. 

* Url test issues, avoid multiple test, and change outbound on test. 

* Loop in android. 

#### Other

* Merge pull request #1162 from soyangelromero/main. 
  _Update translations EN - ES_

* Chore: update translations with Fink 🐦 

* Merge pull request #1154 from MR-TZ-dev/main. 
  _fix: error migrating from v3 to v4 database._

* Better get requests. 

* Fix; font. 



## v2.0.4 (2024-07-31)

#### New

* Add rich config editor. 



## v2.0.3 (2024-07-30)

#### Fix

* Bug. 



## v2.0.2 (2024-07-30)

#### Other

* Better editor. 



## v2.0.1 (2024-07-30)

#### Fix

* Ios build issue. 

* Ios bug. 

* Some bugs in configs and fix core bugs. 

* Editor text mode bug. 

#### Other

* Update. 

* Better json editor. 

* Test. 

* Use latest macos for build ios. 

* Test ios. 



## v2.0.0 (2024-07-30)

#### New

* Add json editor and editing configs <3. 

* Add custom url-test for each repository. 

#### Fix

* Link validator. 

* Provis? 

* Ios. 

#### Other

* Update warp. 

* Fix? 

* Ios? 

* Fix ios? 

* Fix bug. 



## v1.9.1 (2024-07-28)

#### New

* Add auto build for ios. 

* Add xray type. 

#### Fix

* Add warp issue. 

#### Other

* Revert to sdk 34. 

* Enable resolve-destination and ipv6 by default. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1108 from SonzaiEkkusu/main. 
  _Update Translations for Region Indonesia (id)_

* Update Translations for Region Indonesia (id) 

* Reset direct dns when region  change. 

* Update sdk to 35. 

* Better xray support. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1106 from amirsaam/main. 
  _General iOS Maintain_

* General iOS Maintain. 



## v1.9.0 (2024-07-25)

#### New

* Add10000 to all ports for prevenging permission error. add warp from github repository except for china. 

#### Fix

* Fixed problem not launching on Ubuntu 24.04 LTS. 

#### Other

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1084 from MR-TZ-dev/fix/linuxLaunchFix. 
  _fix: fixed problem not launching on Ubuntu 24.04 LTS._

* Merge pull request #1092 from Metozak/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #1097 from SonzaiEkkusu/main. 
  _Add Indonesia region_

* Add Indonesia region. 

* Add core to 1.9.0. 

* Upgrade flutter. 

* Merge pull request #1073 from keyang556/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Update warp. 

* Update warp2. 

* Update warp2. 



## v1.7.0 (2024-07-17)

#### New

* Add more warp modes, handle both ipv4 and ipv6 in wireguard, add customizable size and more. 

#### Other

* Update warp2. 

* Create warp2. 

* Update warp. 



## v1.6.3 (2024-07-14)

#### Other

* Make pre-release by default. 



## v1.6.2 (2024-07-14)

#### Fix

* Qrcode issue and update qrcode lib. 

* Scanner. 

#### Other

* Renew warp configs on adding. 



## v1.6.1 (2024-07-14)

#### New

* Add knocker parameters. 

#### Fix

* Release issue. 

* Qrcode issue. 

#### Other

* Android. 

* Upgrade flutter. 

* Update flutter and make connection more smooth. 

* Show info dialog when reconnecting. 

* Merge pull request #1050 from itispey/dev-test. 
  _Reconnect automatically after changing service-mode_

* Reconnect automatically after changing service-mode. 

* Merge pull request #1053 from maxyxyd/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Merge pull request #1043 from nidghogg/main. 
  _Fixed camera permission handling for QR_

* Merge branch 'main' of https://github.com/nidghogg/hiddify-next. 

* Fixed Camera permission handling for QR. 



## v1.5.0 (2024-07-09)

#### Fix

* Test bug for geoassets. 

* Remove geoassets. 

#### Other

* Fix intro page buug. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1004 from Kianmehrgit/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #993 from fodhelper/fix-urltest-fails. 
  _Fix URLTest Fails_

* Update config_option_repository.dart. 

* Merge pull request #966 from SoranTabesh/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #965 from SoranTabesh/patch-1. 
  _Update locale_extensions.dart_

* Update locale_extensions.dart. 

* Merge pull request #988 from Amirali-Amirifar/fix-changelog-update-years. 
  _Fix CHANGELOG year_

* Fix CHANGELOG year. 
  _see diff._

* Merge pull request #934 from amirsaam/main. 
  _General iOS Maintaining_

* General iOS Maintaining. 

* Refactor. 

* Add basic routing options, auto update routing assets,use ruleset, remove geo assets. 



## v1.4.0 (2024-06-02)

#### Fix

* Naming bug. 

* Bug. 

* Bug. 

* Ios. 

* Lang. 

* Bug. 

* Make dark tray icon windows-only. 

#### Other

* Merge pull request #817 from felixhaeberle/main. 
  _Update translations_

* Merge branch 'main' into main. 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Merge pull request #811 from amirsaam/main. 
  _New Bundle + Pods + PrivacyAPIs_

* Privacy Targets. 

* Privacy Declaration. 

* New Bundle + Pods. 

* Merge branch 'android-fix-action-bug' 

* Downgrade flutter. 

* Master. 

* Downgrade to 3.22.0. 

* Upgrade flutter. 

* Update to flutter 3.21. 

* Update. 

* Downgrade flutter. 

* Temporary disbale apk build. 

* Update. 

* Update. 

* Test. 

* Update. 

* Update. 

* Upgrade gradle version. 

* Tmp test. 

* Add more log. 

* Update flutter action. 

* Add debug and ios. 

* Fix lang update. 

* Merge pull request #778 from Pikman/main. 
  _Update translations_

* Merge branch 'main' into main. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Merge pull request #894 from xmha97/main. 
  _Capitalize the installation folder_

* Update make_config.yaml. 

* Merge pull request #902 from MrIbrahem/main. 
  _Update ar translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #4 from MrIbrahem/patch-1. 
  _Patch 1_

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Update make_config.yaml. 

* Update settings.json. 

* Update locale_extensions.dart. 

* Merge pull request #3 from MrIbrahem/patch-1. 
  _Update strings_ar.i18n.json_

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Merge pull request #2 from MrIbrahem/patch-1. 
  _Create strings_ar.i18n.json_

* Create strings_ar.i18n.json. 

* Merge pull request #814 from keyang556/main. 
  _Update Traditional Chinese translations_

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Add warp config, update to flutter 1.22. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Merge pull request #770 from alkstsgv/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Test. 

* Merge pull request #751 from sky96111/main. 
  _fix: make auto dark tray icon windows-only_

* Merge pull request #737 from SoranTabesh/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Rename strings_ckb-KU.i18n.json to strings_ckb-KUR.i18n.json. 

* Update settings.json. 

* Fink 🐦: update translations. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update core. 

* Merge pull request #726 from HSSkyBoy/main. 
  _inlang: update zh-TW transition_

* Update zh-TW transition. 

* Merge pull request #705 from iamgiko/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Update LICENSE.md. 

* Update LICENSE.md. 

* Update README_ru.md. 

* Update README_ja.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #698 from betaxab/p1. 
  _inlang: update translations_

* Inlang: update translations. 



## v1.1.1 (2024-03-20)

#### New

* Add tproxy. 

#### Fix

* Gvisor. 

* Issue. 

#### Other

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #696 from HSSkyBoy/main. 
  _Update translations (zh_TW and zh_CN)_

* 更新 strings_zh-TW.i18n.json. 

* 更新 strings_zh-TW.i18n.json. 

* Update strings_zh-TW.i18n.json. 

* 更新 strings_zh-TW.i18n.json. 

* Change APP name. 

* 更新 strings_zh-TW.i18n.json. 

* 更新 strings_zh-CN.i18n.json. 

* Bump version. 

* Merge pull request #692 from sky96111/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Merge pull request #686 from sky96111/main. 
  _feat: Use dark tray icon in light theme_

* Feat: dark tray icon in light theme. 

* Merge pull request #690 from imshahab/m3-dynamic-theme. 
  _Implement Material 3 dynamic theming_

* Implement Material 3 dynamic theming. 

* Merge pull request #685 from Nyar233/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Merge pull request #682 from alirezafarvardin/main. 
  _Update translation (Persian)_

* Merge branch 'main' into main. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 



## v1.0.0 (2024-03-18)

#### New

* Add review. 

#### Fix

* Isssue with singbox 1.8.9. 

* Ios. 

* Implementation. 

* Test, update to singbox 1.8.9. 

* Bug in warp config. 

#### Other

* Update release_message.md. 

* Update README.md. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README.md. 

* Update release_message.md. 

* Update README.md. 

* Fix postServiceClose implementation. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Fink 🐦: update translations. 

* Remove mux. 

* Merge branch 'pr/alikhabazian/668-1' 

* Resolve qr code permssion issue. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #668 from alikhabazian/newyear. 
  _add image field to ConnectionButton_

* Add useImage feild for change image in every newyear and increase quality. 

* Add image field to ConnectionButton. 

* Update. 

* Merge pull request #653 from alirezafarvardin/main. 
  _Update translations_

* Inlang/manage: add languageTag zh-TW. 

* Inlang/manage: add languageTag zh-CN. 

* Inlang/manage: add languageTag tr. 

* Inlang/manage: add languageTag ru. 

* Inlang/manage: add languageTag pt-BR. 

* Inlang/manage: add languageTag id. 

* Inlang/manage: add languageTag es. 

* Inlang/manage: remove languageTag es. 

* Inlang/manage: add languageTag es. 

* Inlang/manage: remove languageTag zh-CN. 

* Inlang/manage: remove languageTag id. 

* Inlang/manage: remove languageTag ru. 

* Inlang/manage: remove languageTag tr. 

* Inlang/manage: remove languageTag es. 

* Inlang/manage: remove languageTag zh-TW. 

* Inlang/manage: remove languageTag pt-BR. 

* Merge branch 'hiddify:main' into main. 

* Fink 🐦: update translations. 

* Test flight only release. 

* Add core grpc server. 



## v0.17.12 (2024-03-14)

#### New

* Refactor testflight. 

* Add installation dependencies for apple. 

* Add ios build process. 

* Add Indonesian language. 

* Add hiddifycli and resolve all false positve from anti virus, auto exit during installation. 

* Add support for flag emoji in proxy names. 

* Add version draft. 

* Auto replace signed exec. 

* Update to singboc 1.8.7. 

* Enable tunnel service again, add signing, msix, more log less info. 

* Add ipwho.is. 

* Use timezone for location detector. 

* Add warp fake packet delay, add warp detour, add new ipinfo api. 

#### Fix

* Apple release. 

* Bug. 

* No commit message. 

* Release to ios. 

* Ios publishing. 

* Var. 

* Var. 

* Vaiable issue. 

* Potential fix to issue in some windows? 

* Msix package. 

* Signing. 

* Version. 

* Pub get issue? 

* Build. 

* Flag. 

* Ip flag. 

* Bug in versioned draft. 

* Invalid version string for draft. 

* Action bugs. 

* Signing. 

* Signing. 

* Cert? 

* Generate Warp Config on iOS. 
  _+ pod install new packages_

* Msix issue. 

* Appimage fixed. issue: #513. 

* Name. 

* Intro page bug and fakepacket delay bug. 

* Exception reporting on failing in getting ip. 

* Exception when there is no active profile. 

* Ip info. 

* Build bug. 

* Translation bug, disable signing for pull req. 

* Bug in change interface listener. 

* Update download paths in release page. 

* Logo, add name for hiddify warp sub. 

#### Other

* Update. 

* Update. 

* Update. 

* Update. 

* Update. 

* Disable: permission handler for windows. 

* Disable redundent action run for release. 

* Merge pull request #647 from hiddify/ios. 
  _Ios_

* Upload versioned. 

* Update. 

* Update. 

* Update ios release. 

* Upload to appstore in macos. 

* Test testflight upload. 

* Fix name issue. 

* Update. 

* Update. 

* Update. 

* Add provisioning profiles. 

* Add SingBoxPacketTunnel. 

* Update. 

* Update. 

* Add prereq of ios. 

* Allow ci build from all branches. 

* Revert changes for test. 

* Test disabling system tray. 

* A test for possible bug in some windows. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update signing. 

* Downgrade flutter action. 

* Merge pull request #621 from hei-hilman/main. 
  _add new translation (Indonesian)_

* Add indonesian translation. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Fix qr code scanner. 

* Change translation keys. 

* Change experimental feature notice. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Change sidebar stats. 

* Add emoji font for flags. 

* Use software rendering for windows. may resolve white screen? 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Refactor config options. 

* Merge branch 'be1c1bb580ec039044e8057ae1469153008cdb4d' 

* Add reconnect and animations to connection button. 

* Add quick settings. 

* Update release_message.md. 

* Bump Flutter (v3.19) and dependencies. 

* Remove redundant logs. 

* Change db initialization. 

* Remove draft version. 

* Make it universal for all os. 

* Add versioned draft. 

* Simple debug to bug of some windows. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Add Config options import. 

* Disable signing. 

* Add hide icon from dock on mac. 

* Add reconnect alert for config options. 

* Refactor preferences. 

* Merge pull request #585 from amirsaam/main. 

* Update msix. 

* Merge pull request #577 from Aryangh1379/Hiddify-develop. 

* Merge pull request #572 from Aryangh1379/Hiddify-develop. 
  _Hiddify develop_

* Forgot to remove -x from !#/bin/bash :) 

* Add AppRun parameters - provided a help menu. 

* Temporary disable windows service. 

* Update README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README_br.md. 

* Merge pull request #532 from mascenaa/main. 
  _Add README in Portuguese_

* Adding a README in Portuguese. 

* Merge pull request #556 from Aryangh1379/Hiddify-develop. 
  _AppRun file error fixed. AppImage now is usable_

* AppRun file error fixed. AppImage now is usable. 

* Merge pull request #549 from pierrot-p/main. 
  _[PT-BR]  inlang: Added missing translations_

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Merge pull request #546 from nya-main/main. 
  _update translations(CN)_

* Manually repair an entry. 

* Inlang: update translations. 

* Merge pull request #547 from amirsaam/main. 
  _macOS AppIcon_

* MacOS AppIcon. 

* Add timezone based region detection. 

* Url test is only valid for group not a single proxy. 

* Potentioal fix for crash in some windows. 

* Bump libcore. 

* Excluding aab from building draft. 

* Remove aab draft build. 

* Change warp options. 

* Fix Portuguese locale. 

* Add build test. 

* Update dependencies. 

* Change ip error. 

* Remove extra warp configs. 

* Update README_ru.md. 

* Merge pull request #509 from nevazno00/patch-1. 
  _Update README_ru.md_

* Update README_ru.md. 

* Merge pull request #527 from mascenaa/main. 
  _Add a PT-BR Translate file._

* Add a PT-BR Translate file. 

* Merge pull request #508 from kouhe3/zh-cn-i18n-patch-2. 
  _strings_zh-CN.i18n.json_

* Merge branch 'main' into zh-cn-i18n-patch-2. 

* Merge pull request #523 from nya-main/main. 
  _Update translations_

* Merge branch 'main' into main. 

* Merge pull request #528 from KintaMiao/main. 
  _Update translations_

* Inlang: update translations. 

* Inlang: update translations. 

* Fix build. 

* Add more haptic feedback. 

* Zh-cn translate. 

* Detailed subscription info. 

* Add detailed subscription info. 

* Fix test. 

* Add ci test. 

* Add warp config generator. 

* Update changelog. 

* Change ip refresh. 

* Add auto ip check option. 

* Change ip error refresh button. 

* Change mapping. 

* Fix issue in installing packages in ubuntu. 

* Fix connection on desktop. 

* Change interval mapping. 

* Fix chinese locale. 

* Add haptic feedback. 

* Format zh-CN.i18n.json And remove duplicate. 

* Merge pull request #410 from junlin03/main. 
  _更新繁體中文翻譯_

* Merge branch 'main' into main. 

* Merge pull request #482 from guoard/fix/downlaod_path. 
  _fix: update download paths in release page_

* Merge pull request #481 from amirsaam/main. 
  _Bugs in config_option_entity.dart_

* Update config_option_entity.dart. 

* Bugs in config_option_entity.dart. 

* Change mapping and bug fixes. 

* Change icons. 

* Improve ping indicator. 

* Change service mode choices. 

* Fix ip widget directionality. 

* Merge branch 'main' into main. 

* Inlang: update translations. 



## v0.15.8 (2024-02-14)

#### New

* Update icon. 

* Add seperated VPN service mode. 

* Add some example of new warp configs. 

* Update active profile and its ping, 

* Change app icon to stable. 

* Add unavailble mark, fix: windows release bug. 

#### Changes

* Change name to Hiddify. 

#### Fix

* Appimage tunnel service bug. 

#### Other

* Change ip obscure. 

* Improve accessibility. 

* Change service error handling. 

* Fix connection info. 

* Fix widget build conflict. 

* Revert build image for appimage to 22.04. 

* Update README_cn.md. 

* Update README.md. 

* Update README.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #454 from amirsaam/main. 
  _Update iOS Icons_

* AppIcon Update. 

* Update iOS Icons. 

* Add proxy http adapter. 

* Fix android service mode. 

* Merge pull request #453 from amirsaam/main. 
  _Update Makefile_

* Update Makefile. 

* Change routing setup. 

* Fix connection info ui. 

* Make ip private for both footer and sidebar. 

* Make ip anonymous. 

* Add syncthing ignore files. 

* Add desktop active proxy info. 

* Add active proxy delay indicator. 

* Fix commands. 

* Change translation fallback strategy. 

* Update CONTRIBUTING.md. 

* Merge pull request #439 from amirsaam/main. 
  _Fix iOS Logger_

* Fix iOS Logger. 



## v0.15.6 (2024-02-09)

#### New

* Add macos pkg file and remove zip wrapper. 

* Add custom AppRun: need forked distributor. 

* Add intro based on user lang and region. 

* Hide hidden nodes. 

* Move running admin service to core. 

* Display go errors. 

* Add tunnel service for windows and linux. 

* Show groups always on top. 

* Change update time when selected. 

* Make activated profile always in top. 

* Add postfix to name if it is not unique. 

* Add link parser and allow custom configs to be imported. 

#### Changes

* Use our flutter distrobutor version and downgrade windows version (possible fix of build error) 

#### Fix

* Unix copy bug. 

* Build linux. 

* Dynamic varible in github action. 

* Windows? 

* Windows build? 

* Typo. 

* Windows build. 

* Appimage build and add make req for linux. 

* Service location bug in linux. 

* Update of protocol handler. 

* Bug in logging go erros. 

* Check core before release. 

#### Other

* Refactor  build. 

* Add debug build for windows. 

* Rerun windows without cache. 

* Add ios connection info. 

* Fix ui inconsistency. 

* Fix local build commands. 

* Fix android bugs. 

* Add connection info footer. 

* Add ip info fetcher. 

* Merge pull request #416 from EbrahimTahernejad/patch-1. 
  _Make logger global_

* Use shared instance of logs to log. 

* Added shared instance for LogsEventHandler. 

* Merge pull request #414 from amirsaam/main. 
  _Log for iOS by @ Akuma_

* Log for iOS by @ Akuma. 

* Add ios command client. 

* Change make flags. 

* Change the name of tunnel service to HiddifyService. 

* Make makefile cross platform. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add cloudflare warp options. 

* Temporary disable app image build. 

* Change again to ubuntu 22.04. 

* Update ci.yml. 

* Disable tunnel service for mac. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Remove unnecessary dependencies. 

* Fix mobile routing behavior. 

* Bump java version. 

* Update dependencies. 

* Fix intro page margin. 

* Send panic to sentry. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #371 from eltociear/add_ja-readme. 
  _Add Japanese README_

* Add Japanese README. 

* Merge pull request #389 from leic4u/patch-1. 
  _Update README_cn.md_

* Update README_cn.md. 

* Update README.md. 

* Add mux to experiments && update translations. 



## v0.15.4 (2024-01-26)

#### Fix

* Fragment bug. 



## v0.15.3 (2024-01-26)

#### New

* Add warp option (experimental) 

#### Fix

* Typo. 

#### Other

* Bump to singbox 1.8.4, and fix bugs. 

* Refactor makefile. 

* Update Hiddify Packages. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update to core 0.12.1, singbox 1.8.2. 

* Update build.yml. 

* Make 1.1.1.1 as default dns server. 

* Speed up ping. 

* Update libcore. 



## v0.14.20 (2024-01-21)

#### Other

* Update feature_request.yaml. 

* Update bug_report.yaml. 



## v0.14.11 (2024-01-20)

#### New

* Add deb and rpm build. 

#### Fix

* Versioning issue in ios singbox platform extension. 

* Release bug. 

* Release bug. 

* Build linux. 

* Stats bug in iOS. 

* Some bugs in ios. 

#### Other

* Merge pull request #351 from amirsaam/main. 
  _use universal bundleid from base.xconfig_

* Use universal bundleid from base.xconfig. 

* Merge pull request #350 from amirsaam/main. 
  _ios log handler base functionality_

* Log handler base functionality. 
  _+ fix makefile ios-temp-prepare upgrading pub
+ remove tvOS from libcore local spm
+_

* Add mux options. 

* Add mux. 

* Update release_message.md. 

* Update build.yml. 

* Update changelog. 

* Update readme. 

* Fix ios stats. 

* Add reset tunnel option on ios. 

* Update build.yml. 

* Fix release. 

* Fix release. 

* FIX: RELEASE BUG. 

* Fix release bug in macos. 

* Update build.yml. 

* Update build.yml. 

* Update build.yml. 

* Update dependencies. 

* Fix not releasing linux packages. 

* Merge pull request #347 from amirsaam/main. 
  _fix connection bug after bundle update_

* Fix connection bug after bundle update. 

* Merge pull request #345 from amirsaam/main. 
  _update to latest itunes connect_

* Update to latest itunes connect. 

* Revert changes for swift package. 

* Merge pull request #344 from amirsaam/main. 
  _switch to local spm to load libcore_

* Merge branch 'main' of https://github.com/amirsaam/hiddify-next. 

* Merge branch 'hiddify:main' into main. 

* Remove tvOS in singbox target. 

* Remove tvOS, previously added apple vision for ipad. 

* Handle xcode crash. 

* Switch to local spm. 

* Fix make ios. 

* Bumpcore version to v0.11. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #343 from amirsaam/main. 
  _url scheme +  target dependency + general update_

* Merge branch 'hiddify:main' into main. 

* Add url scheme. 

* Update Package.resolved. 

* Target dependancy + pod update, package resolve. 

* Remove hiddify://import/ from export option. 

* Merge pull request #342 from amirsaam/main. 
  _getting libcore from spm, adding landscape mode_

* Merge branch 'main' of https://github.com/amirsaam/hiddify-next. 

* Delete pubspec.lock. 

* Revert some changers. 
  _This reverts some of commit dde7c2419a12e0f36976f4c0ff8e66d882ec62ac._

* Update pod, getting libcore from spm, adding landscape mode. 

* Change profile options modal. 

* Fix infinite sub expire date (#334) 
  _* Fix infinite sub expire date

* fix expire

* fix build

* refactor

* make it better readable

* Fix infinite sub

* Add test for infinite sub

---------_

* Fix fragment bugs. 

* Merge pull request #340 from amirsaam/main. 
  _fix ui not showing connected after relaunch_

* Fix ui not showing connected after relaunch. 

* Merge pull request #338 from amirsaam/main. 
  _add push notification entitlement_

* Merge branch 'main' of https://github.com/amirsaam/hiddify-next. 

* Add config export on ios. 

* Fix ios connection status on app restart. 

* Add push notification entitlement. 

* Fix attempt. 

* Fix. 

* Fix ci again. 

* Fix ci tag matching. 

* Fix ci. 

* Change logger to print in console. 

* Change routing assets order. 

* Change options description. 

* Fix ci tag pattern. 

* Fix ci. 

* Change workflows. 

* Add missing es translations. 

* Inlang: update translations. 

* Fix infinite sub traffic. 

* Fix bugs. 

* Fix modal text alignment. 

* Merge pull request #329 from amirsaam/newMain. 
  _revert landscape mode_

* Revert landscape mode. 

* Merge pull request #328 from amirsaam/main. 
  _remove unnecessary force unwrap, libcore linking add landscape mode_

* Remove unnecessary force unwrap, libcore linking add landscape mode, 

* Change ios method error handling. 

* Fix bugs. 

* Remove custom_lint. 

* Add vscode launch config macos designed for ipad. 

* Fix ios flutter plugins. 

* Fix ios core name. 

* Merge pull request #323 from amirsaam/main. 
  _better fix for vpn connecting_

* Better fix for vpn connecting. 

* Merge pull request #321 from amirsaam/main. 
  _match exportOptions identifiers with project_

* Fixing not connecting to vpn. 

* Match exportOptions identifiers with project. 

* Merge pull request #319 from amirsaam/main. 
  _fix vpn profile not being created + changing run to release_

* Fix vpn profile not being created + changing run to release. 

* Merge pull request #318 from amirsaam/main. 
  _ios fix?_

* Ios fix? 

* Fix build. 

* Fix windows deep link. 

* Merge pull request #316 from amirsaam/main. 
  _Update pubspec.lock_

* Update pubspec.lock. 

* Merge pull request #315 from amirsaam/main. 
  _add back cupertino_http_

* Add back cupertino_http. 

* Update. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Update appcast. 



## v0.13.6 (2024-01-07)

#### Other

* Fix build. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Fix qr scanner links. 

* Update changelog. 

* Update core (sing-box v1.7.8) 

* Update dependencies. 

* Remove unused dependencies. 

* Refactor service wrappers. 

* Update. 

* Update ios. 

* Change default connection test url. 

* Fix android service mode switch. 

* Add profile fetch cancel. 

* Add update all subscriptions. 

* Fix profile update service. 

* Inlang: update translations. 

* Change app http client. 

* Inlang: update translations. 

* Fix bugs. 

* Add experimental flag to new config options. 

* Add connection from lan option. 

* Add dns routing option. 

* Add bypass lan option. 

* Fix profile edit with new url. 

* Change tls tricks settings section name. 

* Fix db migration bug. 

* Bump version. 

* Fix minor bugs. 

* Remove desktop auto connect. 

* Add experimental feature notice. 

* Update README.md. 

* Update README.md. 

* Fix multi instance on windows. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update README_cn.md. 

* Update README_cn.md. 
  _Some proxy software such as clash do not have official Chinese names and use English by default._

* Add experimental flag in settings ui. 

* Fix inlang setup. 

* Remove robocopy. 

* Fix build. 

* Fix windows portable again. 

* Update changelog. 

* Add android high refresh rate support. 

* Refactor desktop window management and tray. 

* Fix macOS restore from dock. 

* Add desktop shortcuts. 



## v0.12.3 (2023-12-28)

#### Changes

* Fix inconsistent channel naming. 

#### Fix

* Set codec for stream handlers. 

* Ios launch bug. 

#### Other

* Add Afghanistan region. 

* Fix packaging bug. 

* Fix windows packaging. 

* Fix bugs. 

* Change minimum macos version in docs. 

* Add version to desktop window. 

* [fix]: SettingsPickerDialog pop exception. 

* Update ios. 

* Ios: add /platform event channel. 

* Feat: Added stats stream for ios. 

* Feat: Added stats stream for ios. 

* Update ios. 

* Update ios. 

* Update ios. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Ios update. 



## v0.12.2 (2023-12-23)

#### Other

* Remove native http client (temporarily) 

* Update dependencies. 

* Update core (sing-box v1.7.6) 

* Fix bugs. 

* Update core (sing-box v1.7.5) 

* Change initialization and logging. 



## v0.12.1 (2023-12-21)

#### Other

* Fix preferences initialization error. 

* Bump android sdk version. 

* Fix android service mode. 

* Change privacy policy url. 

* Update appcast. 



## v0.12.0 (2023-12-20)

#### New

* Add support for hysteria and wg. 

* Add user-agent like clash sing-box for better compatibility. 

* Send all releases to beta by default. 

#### Fix

* Bug in  windows portable. 

* Linux parse. 

#### Other

* Add hiddify/iimport schema. 

* Fix chinese inlang url. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README.md. 

* Update README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update changelog. 

* Change memory limit on desktop. 

* Remove locale name provider. 

* Fix service mode. 

* Add android dynamic notification. 

* Add android stats channel. 

* Fix translation generator. 

* Add config option reset. 

* Add missing routing asset warning. 

* Fix text input traversal. 

* Add basic d-pad support. 

* Fix tray initialization bug. 

* Update LICENSE.md. 

* Update LICENSE.md. 

* Update LICENSE.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README.md. 

* Add preferences migration. 

* Fix tray behavior. 

* Fix intro routing bug. 

* Fix macos build. 

* Fix macos name. 

* Fix macos icon. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update ios. 

* Update ios. 

* Update ios. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Fix build. 

* Change entrypoint. 

* Add TLS trick config options. 

* Update ios. 

* Update platform interface. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Update dev-i.yml. 

* Update dev-i.yml. 

* Update pubspec.yaml. 

* Create dev-i.yml. 

* Update changelog. 

* Update dependencies. 

* Update core (singbox v1.7) 

* Fix status mapper. 

* Refactor. 

* Refactor logs. 

* Remove unused clash api. 

* Update core (singbox 1.7.0-rc.2) 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Refactor router. 

* Refactor profiles. 

* Update changelog. 

* Fix chinese typography bug. 

* Add soffchen geo assets. 

* Refactor geo assets. 

* Update dependencies. 

* Bump ci sdk version. 

* Bump sdk version. 

* Update README.md. 

* Update README_fa.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README.md. 

* Update README.md. 

* Update release_message.md. 

* Update appcast. 

* Merge pull request #189 from jomertix/main. 
  _Update ru strings_

* Nothing changed strings_tr.i18n.json. 

* Nothing changed strings_fa.i18n.json. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update. 



## v0.11.1 (2023-11-19)

#### Other

* Fix android manifest. 

* Fix documentation. 

* Update release_message.md. 



## v0.11.0 (2023-11-19)

#### New

* Add ic_launcher for android tv. 

* Publish dev release to seperate channel. 

* Add winget. 

* Add prepare to make file. 

#### Fix

* Build-linux-libs. 

* Build. 

* Naming issue. 

* Winget release. 

* Action version. 

* Winget publish. 

* Build error. 

* No commit message. 

* Build. 

* Bug. 

* Build. 

* Distutils. 

* No commit message. 

#### Other

* Change default direct dns. 

* Revert "new: add ic_launcher for android tv" 
  _This reverts commit 49bb62c8289d0885a762e01b7f0785690a7d3af7._

* Change ir region rules. 

* Merge pull request #179 from betaxab/main. 
  _Update translations_

* Inlang: update translations. 

* Add recommended geo assets. 

* Add error handling for geo assets. 

* Fix build. 

* Add geo assets settings. 

* Fix bug in strings_tr.i18n.json. 

* Merge pull request #173 from hasankarli/main. 
  _Update Turkish translations_

* Inlang: update translations. 

* Merge pull request #169 from solokot/main. 
  _Update Russian translation_

* Merge branch 'main' into main. 

* Merge pull request #168 from jomertix/main. 
  _inlang: update translations_

* Inlang: update translations. 

* Merge pull request #172 from Locas56227/main. 
  _Fix and improve Chinese README_

* Fix and improve Chinese README. 

* Update build.yml. 

* Update appcast. 

* Add navigation to system tray. 

* Update Russian translation. 
  _and partially revert ugly inlang changes_

* Change http adapter. 

* Add independent dns cache option. 

* Fix bottom navigation bar accessibility. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update release_message.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #165 from huajizhige/main. 
  _Improve translation_

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update appcast. 

* Fix release command. 

* Add subscription qr code share. 

* Improve qr code scanner ux. 

* Fix code typo. 

* Ci: ignore appcast. 

* Merge pull request #164 from jomertix/main. 
  _Update ru string_

* Update strings_ru.i18n.json. 
  _Fix translation_

* Update strings_ru.i18n.json. 
  _Fix translate_

* Merge pull request #162 from solokot/main. 
  _Update strings_ru_

* Update strings_ru. 
  _Fix google translate_

* Merge pull request #161 from Aloxaf/Aloxaf-patch-1. 
  _fix: build-linux-libs_

* Add sub link share. 

* Fix bootstrap bug. 

* Add proxy tag dialog. 

* Add export config to clipboard. 

* Add geoassessts to makefile prepare. 

* Merge pull request #155 from solokot/main. 
  _Update strings_ru_

* Update strings_ru. 

* Add service mode and strict route. 

* Add basic privilege check. 

* Fix ui bugs. 

* Remove unnecessary preferences. 

* Fix config preferences. 

* Update changelog. 

* Update core to v0.8.0. 

* Fix manual update checker. 

* Fix logs page scroll. 

* Fix android service restart. 

* Fix android service revoke. 

* Change toast. 

* Fix linting and cleanup. 

* Remove execute config as is. 

* Update dependencies. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #138 from huajizhige/main. 
  _inlang: update translations_

* Inlang: update translations. 

* Update. 

* Fix. 

* Fix. 

* Test. 

* Merge pull request #137 from huajizhige/patch-1. 
  _Update README_cn.md_

* Update README_cn.md. 
  _Improve translation_

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Fix. 

* Update. 

* Fix. 

* Fix build. 

* Add distutils. 

* Improve Android TV. 

* Update. 

* Add. 

* Fix appcast url. 

* Add appcast. 

* Add auto connect on start. 

* Merge pull request #123 from Nyar233/main. 
  _Update translations_

* Inlang: update translations. 

* Update release_message.md. 

* Update release_message.md. 

* Merge pull request #115 from solokot/main. 
  _Update Russian: fix google translate_

* Update Russian: fix google translate. 

* Merge pull request #113 from Nyar233/main. 
  _inlang: update translations_

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Change system tray options. 

* Add core mode. 

* Add sidebar stats for large screens. 

* Update dependencies. 

* Change router for different screen size. 

* Merge pull request #108 from Hiiirad/patch-1. 
  _Update auto_translator.py to fix the Path Traversal Vulnerability_

* Update auto_translator.py to fix the Path Traversal Vulnerability. 



## v0.10.0 (2023-10-27)

#### New

* Add ios core library to the project. 

#### Fix

* Ipa. 

#### Other

* Remove reconnect on auto profile update. 

* Update changelog. 

* Add selected tag for selector outbounds. 

* Add core debug flag. 

* Add url test delay color. 

* Change info logs. 

* Delete .github/help/linux/آموزش هیدیفای‌نکست فارسی لینوکس.desktop. 

* Delete .github/help/mac-windows/آموزش هیدیفای‌نکست فارسی.url. 

* Update dependencies. 

* Change pre release update checking off. 

* Add terms and privacy to about page. 

* Add memory limit option. 

* Change directory management. 

* Comment ios. 

* Change app id. 

* Merge pull request #98 from GFWFighter/main. 
  _Initial iOS version_

* Merge pull request #1 from GFWFighter/ios. 
  _iOS_

* Merge branch 'main' into ios. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #95 from solokot/main. 
  _Update Russian_

* Update Russian. 
  _Mainly fix google translate of  new worlds_

* Change logging. 

* Change changelog workflow. 

* Add russia region. 

* Change theme prefs. 

* Merge pull request #90 from solokot/main. 
  _Russian translation: fix some mistakes_

* Russian translation: fix some mistakes. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Add rules. 

* Update LICENSE.md. 

* Inlang: update translations. 

* Merge pull request #85 from leic4u/main. 
  _Update README_cn.md_

* Update README_cn.md. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add inlang translations. 

* Add inlang project and remove localize. 

* Merge pull request #82 from Iam54r1n4/main. 
  _add inlang translator_

* Update: fr_FR.json. 

* Add: french language. 

* Add: inlang translation files(incomplete) 

* Add: setup inlang translation. 

* Merge pull request #74 from lifeindarkside/patch-1. 
  _Update strings_ru.i18n.json_

* Update strings_ru.i18n.json. 
  _Update some wrong interpretation_

* Update README_ru.md. 

* Update README_cn.md. 

* Update README.md. 

* First working version. 

* Underlying VPN Logic. 

* Initialize Packet Tunnel + Config. 

* Update Tutorial_For_HiddifyNext_Linux.desktop. 

* Update Tutorial_For_HiddifyNext.url. 

* Update آموزش هیدیفای‌نکست فارسی.url. 

* Update آموزش هیدیفای‌نکست فارسی لینوکس.desktop. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_cn.md. 



## v0.9.2 (2023-10-15)

#### Other

* Fix ndk setup. 

* Fix android arm bug. 



## v0.9.1 (2023-10-15)

#### Other

* Update README_cn.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Delete docs/file. 

* Google play badge. 

* Delete docs/google-play-badge1.png. 

* Upload google play badge. 

* Create file. 

* Delete docs/google-play-badge.png. 

* Fix ci. 

* Change ndk setup. 

* Update dependencies. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Change desktop error handling. 

* Fix android bugs. 

* Update README.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Delete Russian_Flag.png. 

* Add Russian flag. 

* Delete docs/file. 

* Create README_ru.md. 

* Delete REAMME_ru.md. 

* Create REAMME_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update file. 

* Uplaod a badge for google play. 

* Delete google-play-badge.png. 

* Add files via upload. 

* Create file. 

* Delete docs/google-play-badge.png. 

* Delete google-play-badge.png. 

* Add files via upload. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Create Chinese README_cn.md. 



## v0.8.12 (2023-10-13)

#### Fix

* Typo. 

* Bug. 

* Release names. 

#### Other

* Update readme. 

* Update core. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #56 from solokot/main. 
  _Improvement of Russian translation_

* Improvement of Russian translation. 
  _Basically a replacement for machine automatic translation_

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Fix bugs. 

* Change android signing. 

* Update README.md. 

* Update readme. 

* Update contribution guide. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update release_message.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update release template. 



## v0.8.11 (2023-10-08)

#### Changes

* Remove auto release message. 



## v0.8.10 (2023-10-08)

#### Fix

* Release changelog. 



## v0.8.9 (2023-10-08)

#### Fix

* Missing libs. 



## v0.8.8 (2023-10-08)

#### Fix

* Release bug. 



## v0.8.7 (2023-10-08)

#### Fix

* Release message. 



## v0.8.6 (2023-10-08)

#### Fix

* Windows build. 

* Build issue. 

#### Other

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Update release_message.md. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Update release_message.md. 

* Update README.md. 

* Update README_fa.md. 

* Delete docs/note. 

* Add files via upload. 

* Create note. 

* Update contribute.md. 

* Update README.md. 

* Delete assets/images/google-play-badge.png. 

* Update README_fa.md. 

* Update README.md. 

* Update release_message.md. 

* Update release_message.md. 

* Update release_message.md. 

* Fix build. 



## v0.8.5 (2023-10-07)

#### Fix

* Bug. 



## v0.8.4 (2023-10-07)

#### Fix

* Translate. 



## v0.8.3 (2023-10-07)

#### Other

* Add release message  and help. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Fix bugs. 

* Update release_message.md. 

* Update release_message.md. 

* Update README_fa.md. 

* Update README.md. 

* Update release_message.md. 

* Update release_message.md. 

* Create release_message.md. 

* Add google play badge to assets. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Create contribute.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Add feature request template. 

* Fix issue template. 

* Add issue template. 



## v0.8.2 (2023-10-07)

#### Fix

* Hysteria2 and some links. 

#### Other

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Create README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 
  _Add some features to the readme_

* Add debug export to clipboard. 



## v0.8.1 (2023-10-06)

#### New

* Add chinese lang. 

#### Fix

* Chinese translation. 

#### Other

* Update core 0.5.1. 

* Fix floating number sub info header. 

* Add russian. 

* Add google play descriptions. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 



## v0.8.0 (2023-10-05)

#### New

* Add russian lang. 

#### Other

* Add proxy tag sanitization. 

* Fix bugs. 

* Add ignore app update version. 

* Add new protocols to link parser. 

* Auto update translations on release. 

* Update translation. 

* Remove param in ru translation. 



## v0.7.2 (2023-10-04)

#### Other

* Fix bugs. 



## v0.7.1 (2023-10-03)

#### Other

* Fix log and analytics bugs. 



## v0.7.0 (2023-10-03)

#### New

* Add support of some exception panel with zero usage. 

#### Other

* Fix translation bug. 

* Improve error handling and presentation. 

* Add retry for network ops. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add local profile. 

* Add auto translator. 

* Add auto translate. 



## v0.6.0 (2023-09-30)

#### Other

* Fix minor bugs. 

* Add scheduled profile update. 

* Update dependencies. 

* Refactor profile details page. 



## v0.5.11 (2023-09-22)

#### Other

* Fix android bundle abi. 

* Bump core version. 



## v0.5.10 (2023-09-22)

#### Other

* Fix minor bugs. 

* Fix profile update bug. 



## v0.5.9 (2023-09-22)

#### Other

* Add build number. 



## v0.5.8 (2023-09-22)

#### New

* Add crashlytics. 

* Add support for base64 sublink for header from content. 

* Add profile headers from comments in response! good for hosting in github and show information. 

* Automated version release. 

* Send release versions only to play market add pre-release version. 

#### Changes

* Change invalid dns 235.5.5.5 to 8.8.8.8. 

#### Fix

* Improve routing accessibility and logs. 

* Minor bugs. 

* Prefs persistence. 

* Crashlytics. 

* App update url. 

* Small profiles. 

* Makefile vars. 

* Adaptive icon. 

* Pre-release. 

* Typo in adaptive icon. 

* If .dev is exist in the version do not show update needed. 

* Keep the link as it is. fix the issue with & 

* Dependency issue. 

* Remove extra print. 

* Bug in get headers from body. 

* Bug ini ci to google play. 

* Tag version issue. 

* Ci bug. 

* Remove comments. 

* Bug. 

#### Other

* Fix ci. 

* Fix false-positive error reports. 

* Change build setup. 

* Fix minor bugs. 

* Refactor app update. 

* Fix sentry dart plugin upload. 

* Fix ci debug symbols upload. 

* Add sentry provider observer. 

* Ci: add sentry debug info upload. 

* Update dependencies and general fixes. 

* Chore: bump agp version. 

* Ci: fix env. 

* Ci: add dsn env. 

* Feat: add region and terms to intro. 

* Update ci.yml. 

* Build: add sentry dsn. 

* Feat: add intro screen. 

* Feat: add sentry. 

* Ci: bump macos version. 

* Feat: update profile when adding preexisting url. 

* Publish draft even with error. 

* Update version of core. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add firebase. 

* Update translation. 

* Refactor: version presentation. 

* Perf: improve header parser. 

* Feat: remove check for updates in market releases. 

* Better manage the market release. 

* Update. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Improve accessability. 

* Fix per-app proxy selection. 

* Add android per-app proxy. 

* Add basic flavors. 

* Update Makefile. 

* Update ci.yml. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update ci.yml. 

* Update README.md. 

* Add accessability semantics. 

* Add support for fragment in the url. 



## v0.1.0 (2023-09-11)

#### New

* Add signing to android. 

* Add android universal build also. 

* Add change in network entitlements. 

* Change logo icon to next. 

* Add cache for speed up build process. 

* Add windows portable version. 

* Add libclash. 

* Add as draft release. 

* Make better ci and building applications. 

#### Changes

* Change windows logo. 

* Change macos build  to flutter_distributor. 

* Remove x86 builds since flutter does not support. 

* Add x64 to the name. 

* Update makefile. 

#### Fix

* Space bugs in some panels. 

* Aab. 

* Aab build. 

* Universal sign. 

* KeystoreProperties. 

* Name issue. 

* Revert package name change. 

* Name. 

* Geosite download. 

* Windows portable bug. 

* Change name bug. 

* Setup exe files. 

* Libclash.so. 

* Linux AppImage. 

* Error. 

* Category in linux. 

* Add fuse for linux. 

* Icon. 

* Linux logo. 

* Android. 

* Makefile error. 

#### Other

* Release v0.1.0. 

* Fix ci build. 

* Update ci. 

* Add core version. 

* Fix barrel file. 

* Change proxies lifecycle. 

* Add service restart. 

* Remove notification service. 

* Change android notification permission. 

* Add android service restart. 

* Change mark new profile active. 

* Handle unlimited. 

* Update upload download link stats. 

* Update Translations. 

* Remove // TODO add content disposition parsing. 

* Add content-disposition for profile title. 

* Update README.md. 

* Add hysteria2. 

* Fix android build connection. 

* Add android connection shortcut. 

* Add desktop autostart. 

* Add android boot receiver. 

* Add android proxy service. 

* Add android battery optimizations settings. 

* Change sharedpreferences to unify with android. 

* Add vclibs. 

* Update dependencies. 

* Add submodule. 

* Fix translation code gen. 

* Change prefs. 

* Change default config options. 

* Remove string casing. 

* Update ci.yml. 

* Remove caching. 

* Change core prefs to use code generation. 

* Fix custom lint. 

* Fix general issues. 

* Remove vclibs. 

* Update README.md. 

* Fix blank screen. 

* Add proxies sort. 

* Refactor preferences. 

* Update dependencies. 

* Add more config options to settings. 

* Add tun implementation option. 

* Add android power manager. 

* Add android quick tile. 

* Fix macos dependencies. 

* Fix mac build. 

* Fix build. 

* Change system tray icon. 

* Fix riverpod code generation. 

* Remove unnecessary config options. 

* Add accessability semantics. 

* Update dependencies. 

* Add config options. 

* Add pref utilities. 

* Add stats overview. 

* Update Translations. 

* Fix android outbounds view. 

* Remove unnecessary options. 

* Change proxies flow. 

* Add android command client support. 

* Update README.md. 

* Add status command receiver. 

* Add hiddify deeplink. 

* Add macos deeplink support. 

* Add singbox deeplink. 

* Change error prompts. 

* Fix url parser. 

* Remove unnecessary prefs. 

* Update dependencies. 

* Make AppImage zipped for preserving permission in linux. 

* Add user agent. 

* Fix uri launch. 

* Update ci flutter version. 

* Fix macos silent start. 

* Change proxies page. 

* Fix desktop connection error msg. 

* Add button tooltips. 

* Fix logging. 

* Create dependabot.yml. 

* Create CODE_OF_CONDUCT.md. 

* Fix aab. 

* Add aab file. 

* Change windows-portable name to HiddifyNext-portable. 

* Add debug mode. 

* Add misc settings ui. 

* Remote unnecessary logs. 

* Add misc preferences. 

* Add directory options. 

* Fix linux build. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Fix android builds. 

* Fix android splash screen. 

* Update icons. 

* Fix windows executable build. 

* Remove unnecessary build steps. 

* Remove build number from appbar. 

* Update readme. 

* Change desktop directories. 

* Remove desktop notifications. 

* Force same version code for all platforms. 

* Add more logs. 

* Add log timestamp. 

* Update icons. 

* Remove drawer branding. 

* Add download section in readme. 

* Fix name of universal apk. 

* Fix order. 

* Update readme. 

* Update logging. 

* Update geo assets url. 

* Change linux directories. 

* Update icon. 

* Update icon. 

* Update logo for all platforms. 

* Revert name in macos. 

* Temporary disable app sandbox. 

* Change name. 

* Update Release.entitlements to fix binding issue. 

* Merge pull request #5 from evstegneych/main. 
  _add macos option_

* Add macos option. 

* Update ci flutter version. 

* Update kotlin version. 

* Update other dependencies. 

* Update dependencies. 

* Update flutter version. 

* Update LICENSE.md. 

* Add build option for ios but not tested. 

* Return: build for all. 

* Fix build for macos. 

* Fix ci. 

* Migrate to singbox. 

* Fix routing. 

* Fix connection button text casing. 

* Add update checking. 

* Add separate page for clash overrides. 

* Add version number to appbar. 

* Add more icons. 

* Add sort limited profiles last. 

* Fix profile sort icon. 

* Fix profile traffic ratio. 

* Add profiles sort option. 

* Refactor profile addition flow. 

* Add extra profile metadata. 

* Fix linux deep link service. 

* Refactor profile tile. 

* Add locale based font. 

* Fix linux startup. 

* Update dependencies. 

* Add about page. 

* Fix linux notifications. 

* Build all. 

* Hard coding. 

* Add png. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update Makefile. 

* Fix makefile. 

* Fix actions. 

* Fix actions. 

* Fix actions. 

* Update build setup. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Create LICENSE.md. 

* Add core submodule. 

* Remove core libs. 

* Update Makefile. 

* Update Makefile. 

* Remove c install. 

* Update make. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Add Persian font. 

* Update dependencies. 

* Update to libclash. 

* Add cache. 

* Add: new action. 

* Add write permission. 

* Fix. 

* Modify. 

* Fix. 

* Update. 

* Fix android build. 

* Fix code gen bug. 

* Update ci.yml. 

* Update ci.yml. 

* Fix CI. 

* Fix CI. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Update ci.yml. 

* Update ci.yml. 

* Fix CI. 

* Update ci.yml. 

* Update ci.yml. 

* Add CI. 

* Add silent start for desktop. 

* Update readme. 

* Add headless mode to desktop. 

* Update dependencies. 

* Add distribution setup for windows. 

* Add Farsi(fa) language. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Initial commit. 

* Initial. 



