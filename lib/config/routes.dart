import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui/screens/auth/splash_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/auth/email_verification_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';
import '../ui/screens/auth/phone_verification_screen.dart';
import '../ui/screens/donor/donor_home_screen.dart';
import '../ui/screens/donor/donor_profile_screen.dart';
import '../ui/screens/donor/edit_donor_profile_screen.dart';
import '../ui/screens/donor/donation_history_screen.dart';
import '../ui/screens/donor/donor_availability_screen.dart';
import '../ui/screens/donor/donor_settings_screen.dart';
import '../ui/screens/donor/donor_blood_drives_screen.dart';
import '../ui/screens/requester/requester_home_screen.dart';
import '../ui/screens/requester/create_request_screen.dart';
import '../ui/screens/requester/request_detail_screen.dart';
import '../ui/screens/requester/active_requests_screen.dart';
import '../ui/screens/requester/request_history_screen.dart';
import '../ui/screens/requester/requester_profile_screen.dart';
import '../ui/screens/requester/edit_requester_profile_screen.dart';
import '../ui/screens/requester/requester_settings_screen.dart';
import '../ui/screens/admin/admin_dashboard_screen.dart';
import '../ui/screens/admin/admin_profile_screen.dart';
import '../ui/screens/admin/edit_admin_profile_screen.dart';
import '../ui/screens/admin/admin_settings_screen.dart';
import '../ui/screens/admin/admin_notifications_screen.dart';
import '../ui/screens/admin/user_management_screen.dart';
import '../ui/screens/admin/donor_verification_screen.dart';
import '../ui/screens/admin/request_monitoring_screen.dart';
import '../ui/screens/admin/analytics_screen.dart';
import '../ui/screens/chat/chat_list_screen.dart';
import '../ui/screens/chat/chat_detail_screen.dart';
import '../ui/screens/payment/donation_screen.dart';
import '../ui/screens/payment/payment_history_screen.dart';
import '../ui/screens/search/advanced_search_screen.dart';
import '../ui/screens/map/donor_map_screen.dart';
import '../ui/screens/common/notification_center_screen.dart';
import '../ui/screens/donor/donor_profile_setup_screen.dart';
import '../ui/screens/onboarding/welcome_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String verifyPhone = '/verify-phone';
  static const String donorHome = '/donor-home';
  static const String donorProfile = '/donor-profile';
  static const String editDonorProfile = '/edit-donor-profile';
  static const String donorHistory = '/donor-history';
  static const String donorAvailability = '/donor-availability';
  static const String donorSettings = '/donor-settings';
  static const String donorBloodDrives = '/donor-blood-drives';
  static const String requesterHome = '/requester-home';
  static const String requesterProfile = '/requester-profile';
  static const String editRequesterProfile = '/edit-requester-profile';
  static const String requesterSettings = '/requester-settings';
  static const String createRequest = '/create-request';
  static const String requestDetail = '/request-detail';
  static const String activeRequests = '/active-requests';
  static const String requestHistory = '/request-history';
  static const String adminHome = '/admin-home';
  static const String adminProfile = '/admin-profile';
  static const String editAdminProfile = '/edit-admin-profile';
  static const String adminSettings = '/admin-settings';
  static const String adminNotifications = '/admin-notifications';
  static const String userManagement = '/user-management';
  static const String donorVerification = '/donor-verification';
  static const String requestMonitoring = '/request-monitoring';
  static const String analytics = '/analytics';
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';
  static const String donation = '/donation';
  static const String paymentHistory = '/payment-history';
  static const String advancedSearch = '/advanced-search';
  static const String donorMap = '/donor-map';
  static const String notificationCenter = '/notifications';
  static const String completeDonorProfile = '/complete-donor-profile';
  static const String onboarding = '/onboarding';

  static final router = GoRouter(
    initialLocation: splash,
    redirect: (context, state) async {
      final currentPath = state.matchedLocation;
      const publicRoutes = {
        splash,
        login,
        signup,
        forgotPassword,
        verifyEmail,
        verifyPhone,
        onboarding,
      };

      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isPublicRoute = publicRoutes.contains(currentPath);

      if (firebaseUser == null) {
        return isPublicRoute ? null : login;
      }

      if (currentPath == login || currentPath == signup || currentPath == onboarding) {
        return splash;
      }

      if (isPublicRoute) {
        return null;
      }

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        final userData = userDoc.data();
        if (userData == null) return null;

        final role = (userData['role'] ?? '').toString();
        final profileCompleted =
            (userData['profileCompleted'] ?? userData['isProfileCompleted'] ?? false) == true;

        final isOnSetupPage = currentPath == completeDonorProfile;

        if (!profileCompleted && !isOnSetupPage) {
          return completeDonorProfile;
        }

        if (profileCompleted && isOnSetupPage) {
          if (role == 'admin') return adminHome;
          if (role == 'requester') return requesterHome;
          return donorHome;
        }
      } catch (_) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: verifyEmail,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: verifyPhone,
        builder: (context, state) => const PhoneVerificationScreen(),
      ),
      GoRoute(
        path: donorHome,
        builder: (context, state) => const DonorHomeScreen(),
      ),
      GoRoute(
        path: donorProfile,
        builder: (context, state) => const DonorProfileScreen(),
      ),
      GoRoute(
        path: editDonorProfile,
        builder: (context, state) => const EditDonorProfileScreen(),
      ),
      GoRoute(
        path: donorHistory,
        builder: (context, state) => const DonationHistoryScreen(),
      ),
      GoRoute(
        path: donorAvailability,
        builder: (context, state) => const DonorAvailabilityScreen(),
      ),
      GoRoute(
        path: donorSettings,
        builder: (context, state) => const DonorSettingsScreen(),
      ),
      GoRoute(
        path: donorBloodDrives,
        builder: (context, state) => const DonorBloodDrivesScreen(),
      ),
      GoRoute(
        path: requesterHome,
        builder: (context, state) => const RequesterHomeScreen(),
      ),
      GoRoute(
        path: requesterProfile,
        builder: (context, state) => const RequesterProfileScreen(),
      ),
      GoRoute(
        path: editRequesterProfile,
        builder: (context, state) => const EditRequesterProfileScreen(),
      ),
      GoRoute(
        path: requesterSettings,
        builder: (context, state) => const RequesterSettingsScreen(),
      ),
      GoRoute(
        path: createRequest,
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: requestDetail,
        builder: (context, state) {
          final extra = state.extra;
          final requestId = state.uri.queryParameters['id'] ??
              (extra is String ? extra : null);
          return RequestDetailScreen(requestId: requestId);
        },
      ),
      GoRoute(
        path: activeRequests,
        builder: (context, state) => const ActiveRequestsScreen(),
      ),
      GoRoute(
        path: requestHistory,
        builder: (context, state) => const RequestHistoryScreen(),
      ),
      GoRoute(
        path: adminHome,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: editAdminProfile,
        builder: (context, state) => const EditAdminProfileScreen(),
      ),
      GoRoute(
        path: adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: adminNotifications,
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: userManagement,
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: donorVerification,
        builder: (context, state) => const DonorVerificationScreen(),
      ),
      GoRoute(
        path: requestMonitoring,
        builder: (context, state) => const RequestMonitoringScreen(),
      ),
      GoRoute(
        path: analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: chatList,
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: chatDetail,
        builder: (context, state) {
          final extra = state.extra;
          final chatId = state.uri.queryParameters['id'] ??
              (extra is String ? extra : null) ??
              '';
          return ChatDetailScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: donation,
        builder: (context, state) => const DonationScreen(),
      ),
      GoRoute(
        path: paymentHistory,
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: advancedSearch,
        builder: (context, state) => const AdvancedSearchScreen(),
      ),
      GoRoute(
        path: donorMap,
        builder: (context, state) => const DonorMapScreen(),
      ),
      GoRoute(
        path: notificationCenter,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: completeDonorProfile,
        builder: (context, state) => const DonorProfileSetupScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
    ],
  );
}
