// Arabic translations
const Map<String, String> arStrings = {
  // App
  'app_title': 'ناسج',

  // Auth Screen
  'auth_phone_hint': 'رقم الهاتف',
  'auth_choose_role': 'اختر دورك',
  'auth_mode_supplier': 'مورد',
  'auth_mode_worker': 'موظف',
  'auth_role_farmer': 'مربي ماشية',
  'auth_role_producer': 'منتج',
  'auth_role_slaughterhouse': 'مجزرة',
  'auth_role_collector': 'جامع',
  'auth_role_depot': 'عامل مستودع',
  'auth_role_lavery': 'عامل غسيل',
  'auth_role_transformation': 'عامل تحويل',
  'auth_continue': 'متابعة',
  'auth_email_hint': 'رقم الهاتف',
  'auth_password_hint': 'كلمة المرور',
  'auth_employee_step1_title': 'تسجيل دخول الموظف',
  'auth_employee_step1_subtitle': 'أدخل رقم هاتفك المهني',
  'auth_employee_step2_title': 'كلمة المرور',
  'auth_employee_step2_subtitle': 'أدخل كلمة المرور للوصول إلى مساحة عملك',
  'auth_error_login_failed':
      'رقم الهاتف أو كلمة المرور غير صحيحة. حاول مجدداً.',
  'auth_error_empty_phone': 'يرجى إدخال رقم هاتفك',
  'auth_error_invalid_phone':
      'رقم هاتف غير صحيح. يجب أن يبدأ بـ 05 أو 06 أو 07 ويتكوّن من 10 أرقام.',
  'auth_error_empty_email': 'يرجى إدخال بريدك الإلكتروني',
  'auth_error_invalid_email': 'عنوان البريد الإلكتروني غير صحيح.',
  'auth_error_empty_password': 'يرجى إدخال كلمة المرور.',
  'auth_error_password_not_numeric':
      'لا يمكن أن تتكون كلمة المرور من أرقام فقط.',
  'auth_error_generic': 'حدث خطأ ما. يرجى المحاولة مجدداً.',
  'auth_error_backend_unreachable':
      'تعذّر الوصول إلى الخادم. تأكد من تشغيل API وضبط MOBILE_API_BASE_URL بعنوان IP جهازك.',
  'auth_error_backend_timeout':
      'استغرق الخادم وقتاً طويلاً للردّ. تحقق من أنه يعمل ويمكن الوصول إليه.',
  'auth_error_invalid_server_url':
      'رابط الخادم غير صحيح. تحقق من MOBILE_API_BASE_URL.',
  'auth_otp_hint': 'أدخل رمز التحقق المكوّن من 6 أرقام',
  'auth_otp_sent': 'تم إرسال رمز التحقق',
  'auth_otp_resent': 'تمت إعادة إرسال رمز التحقق',
  'auth_otp_resend': 'إعادة إرسال الرمز',
  'auth_otp_resend_in': 'إعادة الإرسال بعد {seconds} ثانية',
  'auth_error_empty_otp': 'يرجى إدخال رمز التحقق.',
  'auth_error_invalid_otp': 'يجب أن يتكوّن الرمز من 6 أرقام.',
  'auth_pending_title': 'التحقق قيد التنفيذ',
  'auth_pending_desc':
      'نحن نتحقق حالياً من طلبك. بمجرد الاتصال بك وتأكيد هويتك، سيتم تفعيل حسابك.',
  'auth_wilaya_hint': 'اختر ولايتك',
  'auth_error_select_wilaya': 'يرجى اختيار ولايتك.',
  'auth_pending_registered_on': 'تاريخ التسجيل: {date}',
  'auth_pending_deadline': 'الرد قبل: {date} (3 أيام)',
  'auth_pending_check_status': 'تحقق من الحالة',
  'auth_pending_still_waiting':
      'حسابك ما يزال قيد المراجعة. يرجى المحاولة لاحقاً.',

  // Map Screen
  'map_title': 'ناسج',
  'map_search_hint': 'ابحث عن مناطق أو مهام...',
  'map_type_farmer': 'مربي ماشية',
  'map_type_slaughterhouse': 'مجزرة',
  'map_type_storage': 'تخزين',
  'map_call': 'اتصال',

  // List Screen (Prioritized Orders)
  'list_title': 'قائمة المهام',
  'list_filter_all': 'كل المهام',
  'list_filter_pending': 'قيد الانتظار',
  'list_filter_completed': 'مكتملة',
  'list_accept_task': 'قبول المهمة',
  'list_in_progress': 'جارية',

  // My Loads Screen
  'loads_title': 'أحمالي',
  'loads_active_job': 'المهمة الحالية',
  'loads_load_type': 'نوع الحمولة',
  'loads_sheep_count': 'عدد الأغنام',
  'loads_pickup_slot': 'موعد الاستلام',
  'loads_contact_site': 'التواصل مع الموقع',
  'loads_cancel_job': 'إلغاء المهمة',
  'loads_cancel_confirm_title': 'إلغاء المهمة؟',
  'loads_cancel_confirm_body':
      'هل أنت متأكد من إلغاء هذه المهمة الجارية؟ لا يمكن التراجع عن هذا الإجراء.',
  'loads_keep_job': 'الإبقاء على المهمة',
  'loads_no_active_jobs': 'لا توجد مهام نشطة',
  'loads_no_active_jobs_desc':
      'ليس لديك أي أحمال نشطة في الوقت الحالي. تحقق من الخريطة لإيجاد مهام جمع متاحة.',
  'loads_find_jobs': 'البحث عن مهام في الخريطة',
  'loads_calling_site': 'جارٍ الاتصال بالموقع...',
  'loads_following_seller': 'متابعة موقع البائع...',
  'loads_seller': 'البائع',

  // Profile Screen
  'profile_title': 'الملف الشخصي',
  'profile_data_connectivity': 'البيانات والاتصال',
  'profile_sync_status': 'حالة المزامنة',
  'profile_offline_queue': 'الطابور غير المتصل: {count} تقارير',
  'profile_user_default': 'مستخدم',
  'profile_connection_online': 'متصل',
  'profile_connection_offline': 'غير متصل',
  'profile_connection_online_desc': 'متصل بالشبكة',
  'profile_connection_offline_desc': 'يعمل في وضع عدم الاتصال',
  'profile_trust_score': 'درجة الثقة: {score}/100',
  'profile_log_out': 'تسجيل الخروج',

  // Bottom Nav
  'nav_home': 'الرئيسية',
  'nav_operations': 'العمليات',
  'nav_map': 'الخريطة',
  'nav_list': 'القائمة',
  'nav_my_loads': 'أحمالي',
  'nav_profile': 'الملف الشخصي',

  // Supplier Dashboard (shared)
  'supplier_dashboard': 'لوحة التحكم',
  'supplier_ready': 'جاهز للإرسال',
  'supplier_ready_desc_farmer':
      'تم التحقق من محصولك. تأكد من وسم جميع البالات واستعدادها.',
  'supplier_ready_desc_producer': 'أعلن عن وزن الصوف المتاح للجمع.',
  'supplier_ready_desc_slaughterhouse': 'أعلن عن الجلود والصوف المتاحة للجمع.',
  'supplier_new_request': 'طلب جمع جديد',
  'supplier_active_ops': 'العمليات الجارية',
  'supplier_total': 'الإجمالي: {count}',
  'supplier_input_count': 'عدد الرؤوس',
  'supplier_input_weight': 'الوزن (كغ)',
  'supplier_input_count_or_weight': 'العدد أو الوزن (كغ)',
  'supplier_declare': 'تصريح',
  'supplier_or_label': 'أو',
  'supplier_error_count_required': 'يرجى إدخال عدد رؤوس صحيح.',
  'supplier_error_weight_required': 'يرجى إدخال وزن صحيح.',
  'supplier_error_count_or_weight_required': 'يرجى إدخال العدد أو الوزن.',
  'supplier_declare_success': 'تم إنشاء التصريح بنجاح.',
  'supplier_declare_saved_offline':
      'تم حفظ التصريح دون اتصال وسيتم مزامنته تلقائياً.',
  'supplier_ops_offline_fallback':
      'عرض العمليات المحفوظة محلياً في انتظار الشبكة.',
  'supplier_cancel_pending_title': 'حذف العملية قيد الانتظار؟',
  'supplier_cancel_pending_desc': 'ستُنقل هذه العملية إلى سجل تاريخك.',
  'supplier_cancel_assigned_title': 'إلغاء عملية مُسنَدة',
  'supplier_cancel_assigned_desc':
      'يجب عليك الاتصال بالجامع المُسنَد قبل الإلغاء.',
  'supplier_collector_phone': 'هاتف الجامع: {phone}',
  'supplier_call_collector': 'الاتصال بالجامع',
  'supplier_confirm_cancel': 'تأكيد الإلغاء',
  'supplier_cancel_success': 'تم إلغاء العملية.',
  'supplier_cancel_saved_offline':
      'تم حفظ الإلغاء دون اتصال وسيتم مزامنته تلقائياً.',
  'supplier_status_pending': 'قيد الانتظار',
  'supplier_status_assigned': 'مُسنَدة',
  'supplier_status_cancelled_pending': 'ملغاة (انتظار)',
  'supplier_status_cancelled_assigned': 'ملغاة (مُسنَدة)',
  'supplier_status_completed': 'مكتملة',
  'supplier_quantity_weight': 'الوزن: {value} كغ',
  'supplier_quantity_count': 'العدد: {value}',
  'supplier_quantity_unknown': 'الكمية: --',
  'supplier_section_active': 'العمليات الجارية',
  'supplier_section_history': 'السجل التاريخي',
  'supplier_location_label': 'الموقع',
  'supplier_location_none': 'لم يتم تسجيل موقع',
  'supplier_location_farm': 'مشاركة موقع المزرعة',
  'supplier_location_stock': 'مشاركة موقع المخزن',
  'supplier_location_abattoir': 'مشاركة موقع المجزرة',
  'supplier_created_at': 'تاريخ الإنشاء: {value}',
  'supplier_delete_operation': 'حذف',
  'common_yes': 'نعم',
  'common_no': 'لا',
  'common_skip': 'تخطي',
  'common_share_location': 'مشاركة الموقع',

  // Producer / Worker
  'producer_title': 'لوحة تحكم المنتج',
  'producer_welcome': 'مرحباً بك أيها المنتج',
  'worker_title': 'لوحة تحكم الموظف',
  'worker_welcome': 'مرحباً بك أيها الموظف',
};
