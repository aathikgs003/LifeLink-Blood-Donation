import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';

class DonorMapScreen extends StatefulWidget {
  const DonorMapScreen({super.key});

  @override
  State<DonorMapScreen> createState() => _DonorMapScreenState();
}

class _DonorMapScreenState extends State<DonorMapScreen> {
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Mumbai
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donors Near You')),
      body: Stack(
        children: [
          const GoogleMap(
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                        child:
                            Icon(Icons.favorite, color: AppColors.primaryRed)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('12 Donors found',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Within 5km radius',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiaryDark)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () => context.push(AppRoutes.advancedSearch),
                        child: const Text('List View')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
