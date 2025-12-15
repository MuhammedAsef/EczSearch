// lib/presentation/screens/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:il_ilce/il_ilce.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'pharmacy_list_screen.dart';
import '../../infrastructure/pharmacy/datasources/collectapi_pharmacy_remote_ds.dart';
import '../../infrastructure/pharmacy/datasources/pharmacy_local_ds.dart';
import '../../infrastructure/pharmacy/repositories/pharmacy_repository.dart';
import '../../core/settings/app_settings.dart';
import '../../core/services/location_service.dart';
import '../../core/ads/ad_helper.dart';
import '../../core/ads/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IlIlceController _controller = IlIlceController();
  late final PharmacyRepository _repo;

  bool _isLoading = false;
  bool _isLoadingNearest = false;

  bool _isLoadingNearby = false;
  String? _nearbyError;
  List<Map<String, dynamic>> _nearbyPharmacies = [];
  String? _nearbyCity;
  String? _nearbyDistrict;

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _repo = PharmacyRepository(
      remote: CollectApiPharmacyRemoteDataSource(),
      local: PharmacyLocalDataSource(),
    );

    _loadNearbyPharmacies();

    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }


  Future<void> _showInterstitialIfReady() async {
    final ad = _interstitialAd;

    
    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    ad.show();
    _interstitialAd = null;

    await completer.future;
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<bool> _hasConnection() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  Future<void> _loadNearbyPharmacies() async {
    final t = AppSettings.I.t;
    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
    });

    try {
      final hasNet = await _hasConnection();
      if (!hasNet) {
        throw Exception(t('noInternetCache'));
      }

      
      final Position pos = await LocationService.getCurrentLocation();

      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
        localeIdentifier: 'tr_TR',
      );

      if (placemarks.isEmpty) {
        throw Exception('Adres bilgisi alınamadı.');
      }

      final place = placemarks.first;
      final city = (place.administrativeArea ?? '').trim();
      final district =
          (place.subAdministrativeArea ?? place.locality ?? '').trim();

      if (city.isEmpty || district.isEmpty) {
        throw Exception('Konumdan il/ilçe bilgisi çözümlenemedi.');
      }

      final list = await _repo.getDutyPharmacies(
        city: city,
        district: district,
      );

      if (list.isEmpty) {
        throw Exception('Konumunuza göre nöbetçi eczane bulunamadı.');
      }

      final withDistance = list.map<Map<String, dynamic>>((p) {
        final lat = p['lat'] as double?;
        final lng = p['lng'] as double?;
        double? dist;
        if (lat != null && lng != null) {
          dist = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            lat,
            lng,
          ); 
        }
        return {
          ...p,
          'distance': dist,
        };
      }).toList();

      withDistance.sort((a, b) {
        final da = a['distance'] as double?;
        final db = b['distance'] as double?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      if (!mounted) return;
      setState(() {
        _nearbyPharmacies = withDistance;
        _nearbyCity = city.toUpperCase();
        _nearbyDistrict = district.toUpperCase();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearbyError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingNearby = false;
      });
    }
  }

  Future<void> _fetchAndNavigate({required bool openNearestHint}) async {
    final String city = _controller.selectedCity.city;
    final String district = _controller.selectedCity.district;
    final t = AppSettings.I.t;

    if (city.isEmpty || district.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('pleaseSelectCityDistrict'))),
      );
      return;
    }

    setState(() {
      if (openNearestHint) {
        _isLoadingNearest = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final hasNet = await _hasConnection();
      if (!hasNet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('noInternetCache'))),
        );
      }

      final list =
          await _repo.getDutyPharmacies(city: city, district: district);

      if (!mounted) return;

      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasNet ? t('noDutyFound') : t('noCacheCheckConnection'),
            ),
          ),
        );
        return;
      }

      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingNearest = false;
        });
      }

      
      await _showInterstitialIfReady();
      if (!mounted) return;

      
      await Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'pharmacy_list'),
          builder: (_) => PharmacyListScreen(
            city: city.toUpperCase(),
            district: district.toUpperCase(),
            pharmacies: list,
          ),
        ),
      );

      if (openNearestHint && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('nearestHint'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingNearest = false;
      });
    }
  }

  Future<void> _onSearch() async => _fetchAndNavigate(openNearestHint: false);

  Widget _buildNearbyTab(BuildContext context) {
    final t = AppSettings.I.t;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t('nearbyTitle'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('nearbySubtitle'),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoadingNearby ? null : _loadNearbyPharmacies,
                icon: const Icon(Icons.refresh),
                label: Text(t('nearbyRetry')),
              ),
              const SizedBox(width: 8),
              if (_nearbyCity != null && _nearbyDistrict != null)
                Chip(
                  avatar: const Icon(Icons.place, size: 16),
                  label: Text('${_nearbyCity!} / ${_nearbyDistrict!}'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingNearby
                ? const Center(child: CircularProgressIndicator())
                : _nearbyError != null
                    ? Center(
                        child: Text(
                          _nearbyError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      )
                    : _nearbyPharmacies.isEmpty
                        ? Center(
                            child: Text(
                              t('nearbyEmpty'),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _nearbyPharmacies.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final p = _nearbyPharmacies[i];
                              final name = (p['name'] ?? 'Eczane').toString();
                              final addr = (p['address'] ?? '').toString();
                              final dist = p['distance'] as double?;
                              String distText = '';
                              if (dist != null) {
                                if (dist < 1000) {
                                  distText = '${dist.toStringAsFixed(0)} m';
                                } else {
                                  distText = '${(dist / 1000).toStringAsFixed(1)} km';
                                }
                              }

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(name),
                                  subtitle: Text(
                                    distText.isEmpty ? addr : '$addr\nUzaklık: $distText',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    await _showInterstitialIfReady();
                                    if (!context.mounted) return;

                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PharmacyListScreen(
                                          city: _nearbyCity ?? '',
                                          district: _nearbyDistrict ?? '',
                                          pharmacies: _nearbyPharmacies,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab(BuildContext context) {
    final t = AppSettings.I.t;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              t('findPharmacyTitle'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('findPharmacySubtitle'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      t('cityDistrictSelection'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IlIlceDropDown(controller: _controller),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('find')),
                    onPressed: _isLoading ? null : _onSearch,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('listInfo'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppSettings.I.t;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EczSearch'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.my_location),
                text: t('tabNearby'),
              ),
              Tab(
                icon: const Icon(Icons.search),
                text: t('tabSearch'),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildNearbyTab(context),
                  _buildSearchTab(context),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const SafeArea(
                top: false,
                child: SizedBox(
                  height: 60,
                  child: Center(
                    child: BannerAdWidget(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
