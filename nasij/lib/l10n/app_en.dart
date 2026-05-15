// English translations
const Map<String, String> enStrings = {
  // App
  'app_title': 'Nassaj',

  // Auth Screen
  'auth_phone_hint': 'Phone Number',
  'auth_choose_role': 'Choose your role',
  'auth_mode_supplier': 'Supplier',
  'auth_mode_worker': 'Employee',
  'auth_role_farmer': 'Farmer',
  'auth_role_producer': 'Producer',
  'auth_role_slaughterhouse': 'Slaughterhouse',
  'auth_role_collector': 'Collector',
  'auth_role_depot': 'Depot',
  'auth_role_lavery': 'Lavery',
  'auth_role_transformation': 'Transfo.',
  'auth_continue': 'Continue',
  'auth_email_hint': 'Phone Number',
  'auth_password_hint': 'Password',
  'auth_employee_step1_title': 'Employee Login',
  'auth_employee_step1_subtitle': 'Enter your work phone number',
  'auth_employee_step2_title': 'Enter Password',
  'auth_employee_step2_subtitle':
      'Enter your password to access your workspace',
  'auth_error_login_failed':
      'Invalid phone number or password. Please try again.',
  'auth_error_empty_phone': 'Please enter your phone number',
  'auth_error_invalid_phone':
      'Invalid phone number. Must start with 05, 06, or 07 and be 10 digits.',
  'auth_error_empty_email': 'Please enter your email',
  'auth_error_invalid_email': 'Invalid email address.',
  'auth_error_empty_password': 'Please enter your password.',
  'auth_error_password_not_numeric': 'Password cannot contain only numbers.',
  'auth_error_generic': 'Something went wrong. Please try again.',
  'auth_error_backend_unreachable':
      'Cannot reach the backend. Start the API and set MOBILE_API_BASE_URL to your computer IP.',
  'auth_error_backend_timeout':
      'The backend took too long to respond. Check that it is running and reachable.',
  'auth_error_invalid_server_url':
      'The backend URL is invalid. Check MOBILE_API_BASE_URL.',
  'auth_otp_hint': 'Enter the 6-digit verification code',
  'auth_otp_sent': 'Verification code sent',
  'auth_otp_resent': 'Verification code resent',
  'auth_otp_resend': 'Resend code',
  'auth_otp_resend_in': 'Resend in {seconds}s',
  'auth_error_empty_otp': 'Please enter the verification code.',
  'auth_error_invalid_otp': 'Code must be 6 digits.',
  'auth_pending_title': 'Verification In Progress',
  'auth_pending_desc':
      'We are currently verifying your request. Once we call and verify you, we will activate your account.',
  'auth_wilaya_hint': 'Select your wilaya',
  'auth_error_select_wilaya': 'Please select your wilaya.',
  'auth_pending_registered_on': 'Registered on {date}',
  'auth_pending_deadline': 'Response by {date} (3 days)',
  'auth_pending_check_status': 'Check Status',
  'auth_pending_still_waiting':
      'Your account is still under review. Please try again later.',

  // Map Screen
  'map_title': 'Nassaj',
  'map_search_hint': 'Search areas or tasks...',
  'map_type_farmer': 'FARMER',
  'map_type_slaughterhouse': 'SLAUGHTERHOUSE',
  'map_type_storage': 'STORAGE',
  'map_call': 'Call',

  // List Screen (Prioritized Orders)
  'list_title': 'Task List',
  'list_filter_all': 'All Tasks',
  'list_filter_pending': 'Pending',
  'list_filter_completed': 'Completed',
  'list_accept_task': 'Accept Task',
  'list_in_progress': 'In Progress',

  // My Loads Screen
  'loads_title': 'My Loads',
  'loads_active_job': 'ACTIVE JOB',
  'loads_load_type': 'LOAD TYPE',
  'loads_sheep_count': 'SHEEP COUNT',
  'loads_pickup_slot': 'PICKUP SLOT',
  'loads_contact_site': 'CONTACT SITE',
  'loads_cancel_job': 'Cancel Job',
  'loads_cancel_confirm_title': 'Cancel Job?',
  'loads_cancel_confirm_body':
      'Are you sure you want to cancel this active job? This action cannot be undone.',
  'loads_keep_job': 'Keep Job',
  'loads_no_active_jobs': 'No Active Jobs',
  'loads_no_active_jobs_desc':
      'You don\'t have any active loads at the moment. Check the map to find available collection tasks.',
  'loads_find_jobs': 'Find Jobs on Map',
  'loads_calling_site': 'Calling site...',
  'loads_following_seller': 'Following seller location...',
  'loads_seller': 'Seller',

  // Profile Screen
  'profile_title': 'Profile',
  'profile_data_connectivity': 'DATA & CONNECTIVITY',
  'profile_sync_status': 'Sync Status',
  'profile_offline_queue': 'Offline Queue: {count} Reports',
  'profile_user_default': 'User',
  'profile_connection_online': 'Online',
  'profile_connection_offline': 'Offline',
  'profile_connection_online_desc': 'Connected to network',
  'profile_connection_offline_desc': 'Working in offline mode',
  'profile_log_out': 'Log Out',

  // Bottom Nav
  'nav_home': 'Home',
  'nav_operations': 'Operations',
  'nav_map': 'Map',
  'nav_list': 'List',
  'nav_my_loads': 'My Loads',
  'nav_profile': 'Profile',

  // Supplier Dashboard (shared)
  'supplier_dashboard': 'Dashboard',
  'supplier_ready': 'Ready for Dispatch',
  'supplier_ready_desc_farmer':
      'Your harvest is verified. Ensure all bales are tagged and ready.',
  'supplier_ready_desc_producer':
      'Declare the weight of wool available for collection.',
  'supplier_ready_desc_slaughterhouse':
      'Declare the hides and wool available for collection.',
  'supplier_new_request': 'NEW COLLECTION REQUEST',
  'supplier_active_ops': 'Active Operations',
  'supplier_total': '{count} TOTAL',
  'supplier_input_count': 'Head count',
  'supplier_input_weight': 'Weight (kg)',
  'supplier_input_count_or_weight': 'Count or Weight (kg)',
  'supplier_declare': 'Declare',
  'supplier_or_label': 'OR',
  'supplier_error_count_required': 'Please enter a valid head count.',
  'supplier_error_weight_required': 'Please enter a valid weight.',
  'supplier_error_count_or_weight_required': 'Please enter count or weight.',
  'supplier_declare_success': 'Declaration created successfully.',
  'supplier_declare_saved_offline':
      'Declaration saved offline and will sync automatically.',
  'supplier_ops_offline_fallback':
      'Showing offline operations while network is unavailable.',
  'supplier_cancel_pending_title': 'Delete Pending Operation?',
  'supplier_cancel_pending_desc':
      'This pending operation will be moved to your history.',
  'supplier_cancel_assigned_title': 'Cancel Assigned Operation',
  'supplier_cancel_assigned_desc':
      'You must call the assigned collector before cancellation.',
  'supplier_collector_phone': 'Collector phone: {phone}',
  'supplier_call_collector': 'Call Collector',
  'supplier_confirm_cancel': 'Confirm Cancel',
  'supplier_cancel_success': 'Operation cancelled.',
  'supplier_cancel_saved_offline':
      'Cancellation saved offline and will sync automatically.',
  'supplier_status_pending': 'Pending',
  'supplier_status_assigned': 'Assigned',
  'supplier_status_cancelled_pending': 'Cancelled (Pending)',
  'supplier_status_cancelled_assigned': 'Cancelled (Assigned)',
  'supplier_status_completed': 'Completed',
  'supplier_quantity_weight': 'Weight: {value} kg',
  'supplier_quantity_count': 'Count: {value}',
  'supplier_quantity_unknown': 'Quantity: --',
  'supplier_section_active': 'Active Operations',
  'supplier_section_history': 'History',
  'supplier_location_label': 'Location',
  'supplier_location_none': 'No location recorded',
  'supplier_location_farm': 'Share your farm location',
  'supplier_location_stock': 'Share your stock location',
  'supplier_location_abattoir': 'Share your abattoir location',
  'supplier_created_at': 'Created at: {value}',
  'supplier_delete_operation': 'Delete',
  'profile_trust_score': 'Trust score: {score}/100',
  'common_yes': 'Yes',
  'common_no': 'No',
  'common_skip': 'Skip',
  'common_share_location': 'Share Location',

  // Producer / Worker placeholders
  'producer_title': 'Producer Dashboard',
  'producer_welcome': 'Welcome Producer',
  'worker_title': 'Worker Dashboard',
  'worker_welcome': 'Welcome Worker',
};
