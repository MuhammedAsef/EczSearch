// lib/presentation/screens/pharmacy_list_screen.dart
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../../core/utils/pharmacy_helper.dart';
import '../../core/settings/app_settings.dart';

class PharmacyListScreen extends StatefulWidget {
  final String city;
  final String district;
  final List<Map<String, dynamic>> pharmacies;

  const PharmacyListScreen({
    super.key,
    required this.city,
    required this.district,
    required this.pharmacies,
  });

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  bool _isFindingNearest = false;

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<void> _safeLaunch(Uri uri) async {
    try {
      final ok = await canLaunchUrl(uri);
      if (!ok) throw AppSettings.I.t('openFailed');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppSettings.I.t('openFailed')}: $e')),
      );
    }
  }

  Future<void> _callNumber(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone')),
      );
      return;
    }
    await _safeLaunch(Uri(scheme: 'tel', path: normalized));
  }

  Future<void> _openMapChooser(Map<String, dynamic> p) async {
    final t = AppSettings.I.t;

    final name = (p['name'] ?? '').toString();
    final addr = (p['address'] ?? '').toString();
    final lat = _toDouble(p['lat'] ?? p['latitude']);
    final lng = _toDouble(p['lng'] ?? p['longitude']);

    final queryText = Uri.encodeComponent(
      [if (name.isNotEmpty) name, if (addr.isNotEmpty) addr].join(' '),
    );

    Uri _googleUrl() => (lat != null && lng != null)
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$queryText');

    Future<void> _openYandex() async {
      final native = (lat != null && lng != null)
          ? Uri.parse('yandexmaps://maps.yandex.com/?pt=$lng,$lat&z=16')
          : Uri.parse('yandexmaps://?text=$queryText');
      final web = (lat != null && lng != null)
          ? Uri.parse('https://yandex.com/maps/?ll=$lng%2C$lat&z=16&mode=search')
          : Uri.parse('https://yandex.com/maps/?text=$queryText&mode=search');

      if (await canLaunchUrl(native)) {
        await _safeLaunch(native);
      } else {
        await _safeLaunch(web);
      }
    }

    Future<void> _openApple() async {
      final native = (lat != null && lng != null)
          ? Uri.parse('maps://?q=$lat,$lng')
          : Uri.parse('maps://?q=$queryText');
      final web = (lat != null && lng != null)
          ? Uri.parse('http://maps.apple.com/?q=$lat,$lng')
          : Uri.parse('http://maps.apple.com/?q=$queryText');

    if (await canLaunchUrl(native)) {
        await _safeLaunch(native);
      } else {
        await _safeLaunch(web);
      }
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.redAccent),
                  title: Text(t('openWithGoogleMaps')),
                  onTap: () async {
                    await _safeLaunch(_googleUrl());
                    if (mounted) Navigator.pop(ctx);
                  },
                ),
                if (!kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS))
                  ListTile(
                    leading: const Icon(Icons.map_outlined, color: Colors.orange),
                    title: Text(t('openWithYandexMaps')),
                    onTap: () async {
                      await _openYandex();
                      if (mounted) Navigator.pop(ctx);
                    },
                  ),
                if (!kIsWeb && io.Platform.isIOS)
                  ListTile(
                    leading: const Icon(Icons.navigation_outlined, color: Colors.blue),
                    title: Text(t('openWithAppleMaps')),
                    onTap: () async {
                      await _openApple();
                      if (mounted) Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInMaps(Map<String, dynamic> p) async {
    await _openMapChooser(p);
  }
  

  Future<bool> _ensureLocationPermission() async {
    final t = AppSettings.I.t;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('needLocationPermission'))),
      );
      return false;
    }
    return true;
  }

  Future<void> _findNearestAndOpen() async {
    final t = AppSettings.I.t;
    setState(() => _isFindingNearest = true);
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;

      final position = await LocationService.getCurrentLocation();
      final myLat = position.latitude;
      final myLng = position.longitude;

      final withCoords = widget.pharmacies.where((p) {
        final latVal = p['lat'] ?? p['latitude'];
        final lngVal = p['lng'] ?? p['longitude'];
        return latVal != null && lngVal != null;
      }).toList();

      if (withCoords.isEmpty) {
        final uri = Uri.parse('https://www.google.com/maps/search/eczane/@$myLat,$myLng,14z');
        await _safeLaunch(uri);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('noCoordUsedNearbySearch'))),
        );
        return;
      }

      Map<String, dynamic>? nearest;
      double minDist = double.infinity;

      for (final p in withCoords) {
        final lat = _toDouble(p['lat'] ?? p['latitude']);
        final lng = _toDouble(p['lng'] ?? p['longitude']);
        if (lat == null || lng == null) continue;

        final d = Geolocator.distanceBetween(myLat, myLng, lat, lng);
        if (d < minDist) {
          minDist = d;
          nearest = p;
        }
      }

      if (nearest == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('calcNearestFailed'))),
        );
        return;
      }

      await _openMapChooser(nearest);

      if (!mounted) return;
      final name = (nearest['name'] ?? '').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('nearestPharmacyPrefix')}${name.isEmpty ? 'Pharmacy' : name}')),
      );
    } finally {
      if (mounted) setState(() => _isFindingNearest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppSettings.I.t;
    final items = widget.pharmacies;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.city} / ${widget.district} - ${t('dutyPharmacies')}'),
        actions: [
          IconButton(
            tooltip: t('nearestOpenTooltip'),
            onPressed: _isFindingNearest ? null : _findNearestAndOpen,
            icon: _isFindingNearest
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = items[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A885),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (p['name'] ?? 'Pharmacy').toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('address'), style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text((p['address'] ?? '').toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.phone_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('phone'), style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text((p['phone'] ?? '').toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callNumber(p['phone']?.toString()),
                          icon: const Icon(Icons.call),
                          label: Text(t('call')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openInMaps(p),
                          icon: const Icon(Icons.near_me),
                          label: Text(t('viewOnMap')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
