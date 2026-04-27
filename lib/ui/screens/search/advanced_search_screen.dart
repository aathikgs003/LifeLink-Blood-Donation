import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/service_providers.dart';
import '../../../models/donor/donor_model.dart';
import '../../../models/enums.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DonorModel> _results = [];
  bool _isLoading = false;
  BloodGroup? _selectedGroup;

  void _handleSearch(String query) async {
    if (query.length < 3 && _selectedGroup == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await ref.read(donorServiceProvider).searchDonors(
            bloodGroup: _selectedGroup,
            city: query.isNotEmpty ? query : null,
          );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          _buildSearchHeaderByGroup(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeaderByGroup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Search Donors',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _handleSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by city name...',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.location_on, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withAlpha(51),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Colors.white, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BloodGroup.values.map((bg) {
                final isSelected = _selectedGroup == bg;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(bg.displayName),
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryRed : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white.withAlpha(25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none),
                    onSelected: (val) {
                      setState(() => _selectedGroup = val ? bg : null);
                      _handleSearch(_searchController.text);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded,
              size: 80, color: AppColors.textTertiaryLight),
          SizedBox(height: 16),
          Text('Find compatible donors',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Enter a city or select a blood group',
              style: TextStyle(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final donor = _results[index];
        return Card(
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(25),
                  shape: BoxShape.circle),
              child: Center(
                  child: Text(donor.bloodGroup.displayName,
                      style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold))),
            ),
            title: Text(donor.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${donor.city}, ${donor.state}'),
            trailing:
                const Icon(Icons.send_rounded, color: AppColors.primaryRed),
            onTap: () => _showDonorContact(donor),
          ),
        );
      },
    );
  }

  void _showDonorContact(DonorModel donor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donor.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood group: ${donor.bloodGroup.displayName}'),
            Text('City: ${donor.city}'),
            Text(
                'Phone: ${donor.phone?.isNotEmpty == true ? donor.phone : 'Not provided'}'),
            Text('Email: ${donor.email}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
