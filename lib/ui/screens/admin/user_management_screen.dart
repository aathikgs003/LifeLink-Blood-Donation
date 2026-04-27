import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../models/enums.dart';
import '../../../models/user/user_model.dart';
import '../../../providers/service_providers.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();

  bool _isSearching = false;
  String _query = '';

  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  String _selectedBloodGroup = 'all';
  String _selectedProfile = 'all';

  int _currentPage = 1;
  int _pageSize = 10;

  bool _isLoadingPage = false;
  String? _loadError;
  bool _hasMore = true;
  bool _usingClientFilterFallback = false;

  final Map<int, List<UserModel>> _pageCache = {};
  final Map<int, DocumentSnapshot<Map<String, dynamic>>?> _pageLastDoc = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _resetAndLoadFirstPage());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basePage = _pageCache[_currentPage] ?? const <UserModel>[];
    final pageUsers = basePage.where(_matchesClientFilters).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search name or email...',
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim().toLowerCase();
                  });
                },
              )
            : const Text('User Management'),
        actions: [
          IconButton(
            tooltip: 'Advanced filters',
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _query = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSummary(pageUsers.length),
          const Divider(height: 1),
          Expanded(child: _buildBody(pageUsers)),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildBody(List<UserModel> pageUsers) {
    if (_isLoadingPage && _pageCache[_currentPage] == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _pageCache[_currentPage] == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadPage(_currentPage, forceReload: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (pageUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _resetAndLoadFirstPage,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No users found on this page for selected filters.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _resetAndLoadFirstPage,
      child: ListView.builder(
        itemCount: pageUsers.length,
        itemBuilder: (context, index) {
          final user = pageUsers[index];
          final bool isDonor = user.role == UserRole.donor;
          final ageText = user.metadata['age'] ?? '-';
          final cityText = user.metadata['city'] ?? '-';

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                (user.fullName ?? 'U').trim().substring(0, 1).toUpperCase(),
              ),
            ),
            title: Text(user.fullName ?? 'Unnamed User'),
            subtitle: Text('${user.email}\nAge: $ageText • City: $cityText'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(user.role.displayName),
              backgroundColor: isDonor
                  ? AppColors.primaryRed.withAlpha(25)
                  : (user.role == UserRole.admin
                      ? Colors.amber.withAlpha(25)
                      : AppColors.info.withAlpha(25)),
            ),
            onTap: () => _showUserDetails(user),
          );
        },
      ),
    );
  }

  Future<void> _resetAndLoadFirstPage() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _loadError = null;
      _usingClientFilterFallback = false;
      _pageCache.clear();
      _pageLastDoc.clear();
    });
    await _loadPage(1, forceReload: true);
  }

  Future<void> _loadPage(int page, {bool forceReload = false}) async {
    if (_isLoadingPage) return;

    if (!forceReload && _pageCache.containsKey(page)) {
      setState(() {
        _currentPage = page;
      });
      return;
    }

    final adminService = ref.read(adminServiceProvider);
    final startAfterDoc = page == 1 ? null : _pageLastDoc[page - 1];

    if (page > 1 && startAfterDoc == null && !_pageCache.containsKey(page)) {
      return;
    }

    setState(() {
      _isLoadingPage = true;
      _loadError = null;
    });

    try {
      final result = await adminService.fetchUsersPage(
        pageSize: _pageSize,
        startAfterDoc: startAfterDoc,
        role: _selectedRole,
        status: _selectedStatus,
        profile: _selectedProfile,
        city: _cityController.text.trim(),
        bloodGroup: _selectedBloodGroup,
      );

      if (!mounted) return;
      setState(() {
        _pageCache[page] = result.users;
        _pageLastDoc[page] = result.lastDoc;
        _currentPage = page;
        _hasMore = result.hasMore;
        _usingClientFilterFallback = false;
      });
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        try {
          final fallbackResult = await adminService.fetchUsersPage(
            pageSize: _pageSize,
            startAfterDoc: startAfterDoc,
            role: 'all',
            status: 'all',
            profile: 'all',
            city: '',
            bloodGroup: 'all',
          );

          if (!mounted) return;
          setState(() {
            _pageCache[page] = fallbackResult.users;
            _pageLastDoc[page] = fallbackResult.lastDoc;
            _currentPage = page;
            _hasMore = fallbackResult.hasMore;
            _usingClientFilterFallback = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Using client-side fallback while Firestore index is unavailable.',
              ),
            ),
          );
          return;
        } catch (_) {
          // Continue to generic error message.
        }
      }

      if (!mounted) return;
      setState(() {
        _loadError =
            'Could not fetch users. If this is the first run, Firestore may require an index for selected filters.\n$e';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Could not fetch users. If this is the first run, Firestore may require an index for selected filters.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
        });
      }
    }
  }

  Widget _buildFilterSummary(int visibleCount) {
    final chips = <Widget>[];

    if (_selectedRole != 'all') chips.add(_filterChip('Role: $_selectedRole'));
    if (_selectedStatus != 'all') {
      chips.add(_filterChip('Status: $_selectedStatus'));
    }
    if (_selectedProfile != 'all') {
      chips.add(_filterChip('Profile: $_selectedProfile'));
    }
    if (_selectedBloodGroup != 'all') {
      chips.add(_filterChip('Blood: $_selectedBloodGroup'));
    }
    if (_cityController.text.trim().isNotEmpty) {
      chips.add(_filterChip('City: ${_cityController.text.trim()}'));
    }
    if (_minAgeController.text.trim().isNotEmpty) {
      chips.add(_filterChip('Min Age: ${_minAgeController.text.trim()}'));
    }
    if (_maxAgeController.text.trim().isNotEmpty) {
      chips.add(_filterChip('Max Age: ${_maxAgeController.text.trim()}'));
    }
    if (_usingClientFilterFallback) {
      chips.add(_filterChip('Index Fallback: Client-side filtering'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Visible users on page: $visibleCount',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (chips.isNotEmpty)
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
          if (chips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: chips,
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.primaryRed.withAlpha(20),
    );
  }

  Widget _buildPaginationBar() {
    final hasNextCached = _pageCache.containsKey(_currentPage + 1);
    final canGoNext = hasNextCached || _hasMore;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Text('Server Page $_currentPage'),
          const Spacer(),
          DropdownButton<int>(
            value: _pageSize,
            items: const [10, 20, 50]
                .map((size) => DropdownMenuItem<int>(
                      value: size,
                      child: Text('$size / page'),
                    ))
                .toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _pageSize = value);
              await _resetAndLoadFirstPage();
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: canGoNext ? () => _loadPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  bool _matchesClientFilters(UserModel user) {
    if (!_matchesRole(user)) return false;
    if (!_matchesStatus(user)) return false;
    if (!_matchesProfile(user)) return false;
    if (!_matchesBloodGroup(user)) return false;
    if (!_matchesCity(user)) return false;
    if (!_matchesSearch(user)) return false;
    if (!_matchesAge(user)) return false;
    return true;
  }

  bool _matchesRole(UserModel user) {
    if (_selectedRole == 'all') return true;
    return user.role.name == _selectedRole;
  }

  bool _matchesStatus(UserModel user) {
    if (_selectedStatus == 'all') return true;
    if (_selectedStatus == 'active') return user.isActive;
    if (_selectedStatus == 'inactive') return !user.isActive;
    return true;
  }

  bool _matchesProfile(UserModel user) {
    if (_selectedProfile == 'all') return true;
    if (_selectedProfile == 'complete') return user.profileCompleted;
    if (_selectedProfile == 'incomplete') return !user.profileCompleted;
    return true;
  }

  bool _matchesBloodGroup(UserModel user) {
    if (_selectedBloodGroup == 'all') return true;
    final value = (user.metadata['bloodGroup'] ?? '').trim();
    return value == _selectedBloodGroup;
  }

  bool _matchesCity(UserModel user) {
    final selectedCity = _cityController.text.trim().toLowerCase();
    if (selectedCity.isEmpty) return true;
    final city = (user.metadata['city'] ?? '').trim().toLowerCase();
    return city == selectedCity;
  }

  bool _matchesSearch(UserModel user) {
    if (_query.isEmpty) return true;
    final name = (user.fullName ?? '').toLowerCase();
    final email = user.email.toLowerCase();
    final role = user.role.displayName.toLowerCase();
    final city = (user.metadata['city'] ?? '').toLowerCase();
    return name.contains(_query) ||
        email.contains(_query) ||
        role.contains(_query) ||
        city.contains(_query);
  }

  bool _matchesAge(UserModel user) {
    final age = int.tryParse(user.metadata['age'] ?? '');
    if (age == null) {
      return _minAgeController.text.trim().isEmpty &&
          _maxAgeController.text.trim().isEmpty;
    }

    final minAge = int.tryParse(_minAgeController.text.trim());
    final maxAge = int.tryParse(_maxAgeController.text.trim());

    if (minAge != null && age < minAge) return false;
    if (maxAge != null && age > maxAge) return false;
    return true;
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filter Users',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _dropdownField<String>(
                      label: 'Role (server filter)',
                      value: _selectedRole,
                      options: const ['all', 'donor', 'requester', 'admin'],
                      onChanged: (value) => setSheetState(
                          () => _selectedRole = value ?? _selectedRole),
                    ),
                    const SizedBox(height: 12),
                    _dropdownField<String>(
                      label: 'Status (server filter)',
                      value: _selectedStatus,
                      options: const ['all', 'active', 'inactive'],
                      onChanged: (value) => setSheetState(
                          () => _selectedStatus = value ?? _selectedStatus),
                    ),
                    const SizedBox(height: 12),
                    _dropdownField<String>(
                      label: 'Profile Completion (server filter)',
                      value: _selectedProfile,
                      options: const ['all', 'complete', 'incomplete'],
                      onChanged: (value) => setSheetState(
                          () => _selectedProfile = value ?? _selectedProfile),
                    ),
                    const SizedBox(height: 12),
                    _dropdownField<String>(
                      label: 'Blood Group (server filter)',
                      value: _selectedBloodGroup,
                      options: ['all', ...BloodGroup.values.map((e) => e.displayName)],
                      onChanged: (value) => setSheetState(() {
                        _selectedBloodGroup = value ?? _selectedBloodGroup;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City (exact, server filter)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAgeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Min Age'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAgeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Max Age'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Note: Age and text search are always client-side. Other filters are queried from Firestore when indexes exist; otherwise fallback client filtering is used for this page.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedRole = 'all';
                                _selectedStatus = 'all';
                                _selectedBloodGroup = 'all';
                                _selectedProfile = 'all';
                                _cityController.clear();
                                _minAgeController.clear();
                                _maxAgeController.clear();
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _resetAndLoadFirstPage();
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() {});
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(option.toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedRole = 'all';
      _selectedStatus = 'all';
      _selectedBloodGroup = 'all';
      _selectedProfile = 'all';
      _cityController.clear();
      _minAgeController.clear();
      _maxAgeController.clear();
      _query = '';
      _searchController.clear();
      _usingClientFilterFallback = false;
    });
    _resetAndLoadFirstPage();
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName ?? 'Unnamed User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Role: ${user.role.displayName}'),
            Text('Status: ${user.isActive ? 'Active' : 'Inactive'}'),
            Text('Profile: ${user.profileCompleted ? 'Complete' : 'Incomplete'}'),
            Text('Age: ${user.metadata['age'] ?? 'N/A'}'),
            Text('City: ${user.metadata['city'] ?? 'N/A'}'),
            Text('Blood Group: ${user.metadata['bloodGroup'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
