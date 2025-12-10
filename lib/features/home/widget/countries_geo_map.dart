import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart';

/// Interactive world map widget using countries_world_map library.
///
/// Features:
/// - Displays world map with country highlighting
/// - Shows animated position indicator on precise city location
/// - Uses latitude/longitude for accurate positioning with Web Mercator projection
/// - Default zoom to visualize specific region/corner of country
/// - Smooth transitions when location changes (e.g., on VPN connect)
/// - Interactive country selection
///
/// Coordinate System:
/// - Uses Web Mercator projection (EPSG:3857) matching countries_world_map SimpleMap
/// - Normalized coordinates: (0.0, 0.0) = top-left, (1.0, 1.0) = bottom-right
/// - Longitude: -180° to 180° maps to X: 0.0 to 1.0
/// - Latitude: 85.0511°N to 85.0511°S maps to Y: 0.0 to 1.0 (Mercator limits)
/// - Position indicator uses same projection for perfect alignment
class CountriesGeoMap extends HookConsumerWidget {
  const CountriesGeoMap({
    super.key,
    this.ipInfo,
    this.previousIpInfo,
    required this.isConnected,
    this.selectedCountryCode,
  });

  final IpInfo? ipInfo;
  final IpInfo? previousIpInfo;
  final bool isConnected;
  final String? selectedCountryCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectionTheme = theme.extension<ConnectionButtonTheme>();

    // Animation controller for smooth transitions
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );

    // Zoom animation controller
    final zoomController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    // Pulsing animation controller for country color
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Transformation controller for zoom
    final transformationController = useMemoized(
      () => TransformationController(),
    );

    // Track previous location for animation and maintain last known position
    final lastIpInfo = useRef<IpInfo?>(previousIpInfo);
    final displayIpInfo = useState<IpInfo?>(ipInfo);

    // Track previous connection state to detect changes
    final wasConnected = useRef<bool>(isConnected);

    // Track if we've received IP info after connection
    final hasReceivedIpAfterConnect = useRef<bool>(false);

    // Update display IP info when new data arrives
    useEffect(() {
      if (ipInfo != null) {
        displayIpInfo.value = ipInfo;
        if (lastIpInfo.value?.countryCode != ipInfo?.countryCode || lastIpInfo.value?.city != ipInfo?.city) {
          lastIpInfo.value = ipInfo;
          animationController.forward(from: 0.0);
          // Mark that we've received new IP info (deferred to avoid setState during build)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            hasReceivedIpAfterConnect.value = true;
          });
        }
      }
      return null;
    }, [ipInfo?.countryCode, ipInfo?.city]);

    // Reset the flag when connection state changes
    useEffect(() {
      if (wasConnected.value != isConnected) {
        // Defer to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          hasReceivedIpAfterConnect.value = false;
        });
      }
      return null;
    }, [isConnected]);

    // Track previous selected country to detect changes
    final previousSelectedCountry = useRef<String?>(null);

    // Handle zoom based on IP location or selected country
    // Keep zoom on last checked country even when disconnected
    useEffect(() {
      // Prioritize selected country code over IP-based location
      final countryCode = selectedCountryCode ?? ipInfo?.countryCode;

      // Always zoom when selected country changes, or when we have a new country code
      if (countryCode != null && countryCode.isNotEmpty) {
        // Check if this is a new country selection
        final isNewSelection = selectedCountryCode != null && selectedCountryCode != previousSelectedCountry.value;
        final isNewIpLocation = selectedCountryCode == null && ipInfo?.countryCode != previousSelectedCountry.value;

        if (isNewSelection || isNewIpLocation || previousSelectedCountry.value == null) {
          previousSelectedCountry.value = countryCode;

          Future.delayed(const Duration(milliseconds: 150), () {
            if (!context.mounted) return;

            // Zoom to country whenever we have a country code
            _animateToCountryRegion(
              context,
              transformationController,
              zoomController,
              countryCode,
            );
          });
        }
      }

      wasConnected.value = isConnected;
      return null;
    }, [selectedCountryCode, ipInfo?.countryCode]);

    // Cleanup
    useEffect(() {
      return () {
        transformationController.dispose();
      };
    }, []);

    // Colors for map - Use same teal color for both connected and disconnected
    final idleColor = connectionTheme?.idleColor ?? const Color(0xFF0D9A8D); // Teal
    final currentColor = idleColor; // Always use teal color

    final previousColor = theme.colorScheme.secondary.withOpacity(0.2);
    final defaultColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    final borderColor = theme.colorScheme.outline.withOpacity(0.15);

    // Wrap in AnimatedBuilder to rebuild when pulse animation changes
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        // Build color map for countries - Color by connection status
        final Map<String, Color> countryColors = {};

        // If a country is selected from the locations list, highlight it instead of IP-based location
        final selectedCountry = selectedCountryCode;
        if (selectedCountry != null && selectedCountry.isNotEmpty) {
          // Use LOWERCASE country code as required by countries_world_map package
          final countryKey = selectedCountry.toLowerCase();

          // Create pulsing effect with semi-transparent colors
          const baseOpacity = 0.6; // Semi-transparent base
          const pulseRange = 0.3; // Pulse intensity (60% to 90%)

          // Animate opacity between baseOpacity and baseOpacity + pulseRange
          final animatedOpacity = baseOpacity + (pulseController.value * pulseRange);
          final highlightColor = currentColor.withOpacity(animatedOpacity);

          countryColors[countryKey] = highlightColor;
        } else {
          // Highlight previous country (before connection) - very subtle
          final prevCountry = previousIpInfo?.countryCode;
          if (prevCountry != null && prevCountry.isNotEmpty && prevCountry != ipInfo?.countryCode) {
            // Use LOWERCASE country code as required by countries_world_map package
            countryColors[prevCountry.toLowerCase()] = previousColor;
          }

          // Highlight current country from IPInfo (where connection is active)
          // Color intensity based on connection status - GREEN when connected, BLUE when idle
          final currCountry = ipInfo?.countryCode;

          if (currCountry != null && currCountry.isNotEmpty) {
            // Use LOWERCASE country code as required by countries_world_map package
            final countryKey = currCountry.toLowerCase();

            // Create pulsing effect with semi-transparent colors
            // Always use the same pulse intensity regardless of connection state
            const baseOpacity = 0.6; // Semi-transparent base
            const pulseRange = 0.3; // Pulse intensity (60% to 90%)

            // Animate opacity between baseOpacity and baseOpacity + pulseRange
            final animatedOpacity = baseOpacity + (pulseController.value * pulseRange);
            final highlightColor = currentColor.withOpacity(animatedOpacity);

            countryColors[countryKey] = highlightColor;
          }
        }

        // Use LayoutBuilder to get actual screen dimensions for responsive map
        return LayoutBuilder(
          builder: (context, constraints) {
            // Use actual available dimensions - map will be responsive
            final mapWidth = constraints.maxWidth;
            final mapHeight = constraints.maxHeight;

            return Stack(
              children: [
                // Interactive viewer for zoom and pan to country
                InteractiveViewer(
                  transformationController: transformationController,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  boundaryMargin: EdgeInsets.zero,
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // World map (bottom layer) - FORCE exact dimensions
                        Positioned.fill(
                          child: SizedBox(
                            width: mapWidth,
                            height: mapHeight,
                            child: FittedBox(
                              fit: BoxFit.fill, // Force map to fill exact dimensions
                              child: SizedBox(
                                width: mapWidth,
                                height: mapHeight,
                                child: SimpleMap(
                                  instructions: SMapWorld.instructionsMercator,
                                  defaultColor: defaultColor,
                                  colors: countryColors,
                                  countryBorder: CountryBorder(
                                    color: borderColor,
                                    width: 0.5,
                                  ),
                                  callback: (id, name, tapDetails) {
                                    // Log country tap to see what IDs SimpleMap uses
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Location info badge (top-left) - Disabled for now, kept for future use
                // Note: Positioned must be direct child of Stack, cannot wrap with Visibility
                // Uncomment below to enable:
                // Positioned(
                //   top: 16,
                //   left: 16,
                //   child: IgnorePointer(
                //     ignoring: false,
                //     child: _LocationInfoBadge(
                //       ipInfo: ipInfo,
                //       isConnected: isConnected,
                //     ).animate().fadeIn(duration: 600.ms).slide(
                //           begin: const Offset(0, -0.5),
                //           duration: 600.ms,
                //           curve: Curves.easeOut,
                //         ),
                //   ),
                // ),

                // Connection status overlay (top-right) - Outside InteractiveViewer for proper z-index
                if (previousIpInfo != null && ipInfo != null && previousIpInfo?.countryCode != ipInfo?.countryCode)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IgnorePointer(
                      ignoring: false,
                      child: _ConnectionStatusBadge(
                        from: previousIpInfo!.countryCode,
                        to: ipInfo!.countryCode,
                        isConnected: isConnected,
                      ).animate().fadeIn(duration: 600.ms).slide(
                            begin: const Offset(0, -0.5),
                            duration: 600.ms,
                            curve: Curves.easeOut,
                          ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Animate zoom out to default position (no zoom)
  void _animateToDefaultPosition(
    TransformationController controller,
    AnimationController animController,
  ) {
    final targetMatrix = Matrix4.identity(); // Reset to no zoom/pan

    // Animate the transformation
    final startMatrix = controller.value;

    animController.reset();
    animController.forward();

    void listener() {
      final t = Curves.easeInOut.transform(animController.value);
      controller.value = _lerpMatrix(startMatrix, targetMatrix, t);
    }

    animController.addListener(listener);
    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animController.removeListener(listener);
      }
    });
  }

  /// Animate zoom to country region using region-based zoom
  /// NL -> Europe, US -> America, etc.
  /// Independent of window size
  void _animateToCountryRegion(
    BuildContext context,
    TransformationController controller,
    AnimationController animController,
    String countryCode,
  ) {
    // Get region info for the country
    final regionInfo = _getCountryRegion(countryCode.toUpperCase());
    if (regionInfo == null) {
      return;
    }

    // Convert region center to normalized map position (0.0-1.0)
    // Using Web Mercator projection
    final x = (regionInfo.centerLon + 180.0) / 360.0;

    final latRad = regionInfo.centerLat * math.pi / 180.0;
    final y = 0.5 - (math.log(math.tan(math.pi / 4.0 + latRad / 2.0)) / (2.0 * math.pi));

    // Build transformation matrix that's independent of viewport size
    // The key is to use normalized coordinates and let InteractiveViewer handle the rest
    final targetMatrix = Matrix4.identity()
      ..translate(0.5 - x, 0.5 - y) // Center the region
      ..scale(regionInfo.zoomLevel);

    // Animate the transformation
    final startMatrix = controller.value;

    animController.reset();
    animController.forward();

    void listener() {
      final t = Curves.easeInOut.transform(animController.value);
      controller.value = _lerpMatrix(startMatrix, targetMatrix, t);
    }

    animController.addListener(listener);
    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animController.removeListener(listener);
      }
    });
  }

  /// Get region info for a country (region name, center coordinates, zoom level)
  /// Returns null if country not found
  ({String name, double centerLat, double centerLon, double zoomLevel})? _getCountryRegion(String countryCode) {
    // Map countries to their regions with appropriate zoom levels
    // NL -> Europe, US -> North America, etc.
    final regions = <String, ({String name, double centerLat, double centerLon, double zoomLevel})>{
      // Europe - zoom to show European region
      'NL': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Netherlands
      'DE': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Germany
      'FR': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // France
      'GB': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // United Kingdom
      'ES': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Spain
      'IT': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Italy
      'SE': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Sweden
      'NO': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Norway
      'FI': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Finland
      'DK': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Denmark
      'PL': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Poland
      'CH': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Switzerland
      'AT': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Austria
      'BE': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Belgium
      'PT': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Portugal
      'GR': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Greece
      'CZ': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Czech Republic
      'RO': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Romania
      'HU': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Hungary
      'IE': (name: 'Europe', centerLat: 50.0, centerLon: 10.0, zoomLevel: 3.0), // Ireland

      // North America - zoom to show North American region
      'US': (name: 'North America', centerLat: 39.0, centerLon: -98.0, zoomLevel: 2.8), // United States
      'CA': (name: 'North America', centerLat: 56.0, centerLon: -106.0, zoomLevel: 2.5), // Canada
      'MX': (name: 'North America', centerLat: 23.0, centerLon: -102.0, zoomLevel: 2.5), // Mexico

      // South America - zoom to show South American region
      'BR': (name: 'South America', centerLat: -15.0, centerLon: -60.0, zoomLevel: 2.5), // Brazil
      'AR': (name: 'South America', centerLat: -15.0, centerLon: -60.0, zoomLevel: 2.5), // Argentina
      'CL': (name: 'South America', centerLat: -15.0, centerLon: -60.0, zoomLevel: 2.5), // Chile
      'CO': (name: 'South America', centerLat: -15.0, centerLon: -60.0, zoomLevel: 2.5), // Colombia
      'PE': (name: 'South America', centerLat: -15.0, centerLon: -60.0, zoomLevel: 2.5), // Peru

      // Asia - zoom to show Asian region
      'CN': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // China
      'JP': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Japan
      'IN': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // India
      'KR': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // South Korea
      'TH': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Thailand
      'VN': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Vietnam
      'MY': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Malaysia
      'ID': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Indonesia
      'PH': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Philippines
      'SG': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Singapore
      'HK': (name: 'Asia', centerLat: 35.0, centerLon: 105.0, zoomLevel: 2.5), // Hong Kong

      // Middle East - zoom to show Middle East region
      'TR': (name: 'Middle East', centerLat: 30.0, centerLon: 45.0, zoomLevel: 2.8), // Turkey
      'SA': (name: 'Middle East', centerLat: 30.0, centerLon: 45.0, zoomLevel: 2.8), // Saudi Arabia
      'AE': (name: 'Middle East', centerLat: 30.0, centerLon: 45.0, zoomLevel: 2.8), // UAE
      'IL': (name: 'Middle East', centerLat: 30.0, centerLon: 45.0, zoomLevel: 2.8), // Israel

      // Africa - zoom to show African region
      'ZA': (name: 'Africa', centerLat: 0.0, centerLon: 20.0, zoomLevel: 2.5), // South Africa
      'EG': (name: 'Africa', centerLat: 0.0, centerLon: 20.0, zoomLevel: 2.5), // Egypt

      // Oceania - zoom to show Oceania region
      'AU': (name: 'Oceania', centerLat: -25.0, centerLon: 135.0, zoomLevel: 2.5), // Australia
      'NZ': (name: 'Oceania', centerLat: -25.0, centerLon: 135.0, zoomLevel: 2.5), // New Zealand

      // Russia - special case, large country
      'RU': (name: 'Russia', centerLat: 60.0, centerLon: 100.0, zoomLevel: 2.0), // Russia
    };

    return regions[countryCode];
  }

  /// Animate zoom to specific location
  /// Interpolate between two matrices
  Matrix4 _lerpMatrix(Matrix4 a, Matrix4 b, double t) {
    final result = Matrix4.zero();
    for (var i = 0; i < 16; i++) {
      result[i] = a[i] + (b[i] - a[i]) * t;
    }
    return result;
  }
}

/// Animated position indicator that shows current location on the map
class _LocationInfoBadge extends StatelessWidget {
  const _LocationInfoBadge({
    required this.ipInfo,
    required this.isConnected,
  });

  final IpInfo? ipInfo;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle null ipInfo - show loading state
    if (ipInfo == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Detecting location...',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Build location text
    final locationParts = <String>[];
    if (ipInfo!.city != null && ipInfo!.city!.isNotEmpty) {
      locationParts.add(ipInfo!.city!);
    }
    if (ipInfo!.region != null && ipInfo!.region!.isNotEmpty && ipInfo!.region != ipInfo!.city) {
      locationParts.add(ipInfo!.region!);
    }
    locationParts.add(ipInfo!.countryCode.toUpperCase());

    final locationText = locationParts.join(', ');

    // Build detailed tooltip
    final tooltipParts = <String>[];
    if (ipInfo!.city != null && ipInfo!.city!.isNotEmpty) {
      tooltipParts.add('City: ${ipInfo!.city}');
    }
    if (ipInfo!.region != null && ipInfo!.region!.isNotEmpty) {
      tooltipParts.add('Region: ${ipInfo!.region}');
    }
    tooltipParts.add('Country: ${ipInfo!.countryCode.toUpperCase()}');
    if (ipInfo!.latitude != null && ipInfo!.longitude != null) {
      tooltipParts.add('Coordinates: ${ipInfo!.latitude!.toStringAsFixed(4)}, ${ipInfo!.longitude!.toStringAsFixed(4)}');
    }
    tooltipParts.add('IP: ${ipInfo!.ip}');
    if (ipInfo!.org != null) {
      tooltipParts.add('ISP: ${ipInfo!.org}');
    }

    final tooltipText = tooltipParts.join('\n');

    return Tooltip(
      message: tooltipText,
      preferBelow: true,
      verticalOffset: 10,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isConnected ? theme.colorScheme.primary.withOpacity(0.7) : theme.colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isConnected ? theme.colorScheme.primary.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 20,
                color: isConnected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                if (ipInfo!.latitude != null && ipInfo!.longitude != null)
                  Text(
                    '${ipInfo!.latitude!.toStringAsFixed(2)}°, ${ipInfo!.longitude!.toStringAsFixed(2)}°',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge showing current location (city, country) with colored indicator
class _LocationBadge extends StatelessWidget {
  const _LocationBadge({
    required this.ipInfo,
    required this.color,
    required this.isConnected,
  });

  final IpInfo ipInfo;
  final Color color;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build location text
    final locationParts = <String>[];
    if (ipInfo.city != null && ipInfo.city!.isNotEmpty) {
      locationParts.add(ipInfo.city!);
    }
    if (ipInfo.region != null && ipInfo.region!.isNotEmpty && ipInfo.region != ipInfo.city) {
      locationParts.add(ipInfo.region!);
    }
    locationParts.add(ipInfo.countryCode.toUpperCase());

    final locationText = locationParts.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing indicator dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.3, 1.3),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locationText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              if (ipInfo.latitude != null && ipInfo.longitude != null)
                Text(
                  '${ipInfo.latitude!.toStringAsFixed(4)}°, ${ipInfo.longitude!.toStringAsFixed(4)}°',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge showing connection status and location change
class _ConnectionStatusBadge extends StatelessWidget {
  const _ConnectionStatusBadge({
    required this.from,
    required this.to,
    required this.isConnected,
  });

  final String from;
  final String to;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            from.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            to.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

