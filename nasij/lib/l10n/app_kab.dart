// Berber (Kabyle / Taqbaylit) translations
const Map<String, String> brStrings = {
  // App
  'app_title': 'Nassaj',

  // Auth Screen
  'auth_phone_hint': 'Uṭṭun n tilifun',
  'auth_choose_role': 'Fren tawuri-inek',
  'auth_mode_supplier': 'Aseǧǧaw',
  'auth_mode_worker': 'Axeddam',
  'auth_role_farmer': 'Aksab',
  'auth_role_producer': 'Amfares',
  'auth_role_slaughterhouse': 'Tamezliwt',
  'auth_role_collector': 'Ajemmal',
  'auth_role_depot': 'Amaxzan',
  'auth_role_lavery': 'Tasiradt',
  'auth_role_transformation': 'Asnifel',
  'auth_continue': 'Kemmel',
  'auth_email_hint': 'Uṭṭun n tilifun',
  'auth_password_hint': 'Awal uffir',
  'auth_employee_step1_title': 'Tuqqna n Uxeddam',
  'auth_employee_step1_subtitle': 'Aru uṭṭun n tilifun-ik n uxeddim',
  'auth_employee_step2_title': 'Awal uffir',
  'auth_employee_step2_subtitle':
      'Aru awal-ik uffir i wakken ad tkecmeḍ ɣer wemkan-ik',
  'auth_error_login_failed':
      'Uṭṭun n tilifun neɣ awal uffir mačči d iwata. Ɛreḍ tikelt nniḍen.',
  'auth_error_empty_phone': 'Ttxil-k(m) aru uṭṭun n tilifun-ik',
  'auth_error_invalid_phone':
      'Uṭṭun mačči d iwata. Isefk ad yebdu s 05, 06 neɣ 07 yerna ad yesɛu 10 n yizwilen.',
  'auth_error_empty_email': 'Ttxil-k(m) aru imayl-ik',
  'auth_error_invalid_email': 'Tansa n yimayl mačči d iwata.',
  'auth_error_empty_password': 'Ttxil-k(m) aru awal-ik uffir.',
  'auth_error_password_not_numeric':
      'Awal uffir ur yezmir ara ad yesɛu kan izwilen.',
  'auth_error_generic': 'Teḍra-d tuccḍa. Ttxil-k ɛreḍ tikelt nniḍen.',
  'auth_error_backend_unreachable':
      'Ur yezmir ara ad yaweḍ ɣer uqeddac (backend). Sekker API sbadu MOBILE_API_BASE_URL s IP n uselkim-ik.',
  'auth_error_backend_timeout':
      'Aqeddac yeṭṭef aṭas n lweqt i wakken ad d-yerr. Ssenqed ma yetteddu yerna yewjed.',
  'auth_error_invalid_server_url':
      'URL n uqeddac mačči d iwata. Ssenqed MOBILE_API_BASE_URL.',
  'auth_otp_hint': 'Aru tangalt n usenqed n 6 n yizwilen',
  'auth_otp_sent': 'Tangalt n usenqed tuzzn-ed',
  'auth_otp_resent': 'Tangalt n usenqed tettuceggeɛ-d i tikelt nniḍen',
  'auth_otp_resend': 'Ales azen tangalt',
  'auth_otp_resend_in': 'Ales azen deg {seconds}s',
  'auth_error_empty_otp': 'Ttxil-k(m) aru tangalt n usenqed.',
  'auth_error_invalid_otp': 'Tangalt isefk ad tesɛu 6 n yizwilen.',
  'auth_pending_title': 'Asenqed atan iteddu',
  'auth_pending_desc':
      'Aqlaɣ nessenqad asuter-ik. Akken kan ara nessiweḍ ad nesentem timagit-ik s usiwel, amiḍan-ik ad yermed.',
  'auth_wilaya_hint': 'Fren lwilaya-inek',
  'auth_error_select_wilaya': 'Ttxil-k(m) fren lwilaya-inek.',
  'auth_pending_registered_on': 'Ajerred ass n {date}',
  'auth_pending_deadline': 'Tiririt uqbel {date} (3 n wussan)',
  'auth_pending_check_status': 'Ssenqed addad',
  'auth_pending_still_waiting':
      'Amiḍan-ik mazal-it deg usenqed. Ttxil-k ɛreḍ tikelt nniḍen ɣer zdat.',

  // Map Screen
  'map_title': 'Nassij',
  'map_search_hint': 'Nadi timeqwa neɣ imahalen...',
  'map_type_farmer': 'AKSAB',
  'map_type_slaughterhouse': 'TAMEZLIWT',
  'map_type_storage': 'AMAXZAN',
  'map_call': 'Siwel',

  // List Screen
  'list_title': 'Umuɣ n imahalen',
  'list_filter_all': 'Akk imahalen',
  'list_filter_pending': 'Deg ugani',
  'list_filter_completed': 'Yemmed',
  'list_accept_task': 'Qbel amahil',
  'list_in_progress': 'Iteddu',

  // My Loads Screen
  'loads_title': 'Tiɛebbay-iw',
  'loads_active_job': 'AMAHIL YERMDEN',
  'loads_load_type': 'ANAW N TƐEBBAYT',
  'loads_sheep_count': 'AMḌAN N WULLI',
  'loads_pickup_slot': 'AKUD N UJMAƐ',
  'loads_contact_site': 'NEMSIWEL D WEMKAN',
  'loads_cancel_job': 'Sefsex amahil',
  'loads_cancel_confirm_title': 'Ad tsefsexḍ amahil?',
  'loads_cancel_confirm_body':
      'Tebɣiḍ s tidet ad tsefsexḍ amahil-a yermden? Tigawt-a ur d-tettuɣal ara ɣer deffir.',
  'loads_keep_job': 'Eǧǧ amahil',
  'loads_no_active_jobs': 'Ulac amahil yermden',
  'loads_no_active_jobs_desc':
      'Ur tesɛiḍ ara taɛebbayt yermden tura. Wali takarḍa i wakken ad tafeḍ imahalen n ujmaɛ yellan.',
  'loads_find_jobs': 'Af-d imahalen deg tkarḍa',
  'loads_calling_site': 'Asiwel i wemkan...',
};
