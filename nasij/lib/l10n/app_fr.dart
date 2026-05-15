// French translations (primary language)
const Map<String, String> frStrings = {
  // App
  'app_title': 'Nassaj',

  // Auth Screen
  'auth_phone_hint': 'Numéro de téléphone',
  'auth_choose_role': 'Choisissez votre rôle',
  'auth_mode_supplier': 'Fournisseur',
  'auth_mode_worker': 'Employé',
  'auth_role_farmer': 'Éleveur',
  'auth_role_producer': 'Producteur',
  'auth_role_slaughterhouse': 'Abattoir',
  'auth_role_collector': 'Collecteur',
  'auth_role_depot': 'Dépôt',
  'auth_role_lavery': 'Laverie',
  'auth_role_transformation': 'Transfo.',
  'auth_continue': 'Continuer',
  'auth_email_hint': 'Numero de telephone',
  'auth_password_hint': 'Mot de passe',
  'auth_employee_step1_title': 'Connexion Employé',
  'auth_employee_step1_subtitle':
      'Saisissez votre numero de telephone professionnel',
  'auth_employee_step2_title': 'Mot de passe',
  'auth_employee_step2_subtitle':
      'Saisissez votre mot de passe pour accéder à votre espace',
  'auth_error_login_failed':
      'Numero de telephone ou mot de passe incorrect. Veuillez reessayer.',
  'auth_error_empty_phone': 'Veuillez entrer votre numéro de téléphone',
  'auth_error_invalid_phone':
      'Numéro invalide. Doit commencer par 05, 06 ou 07 et contenir 10 chiffres.',
  'auth_error_empty_email': 'Veuillez entrer votre e-mail',
  'auth_error_invalid_email': 'Adresse e-mail invalide.',
  'auth_error_empty_password': 'Veuillez entrer votre mot de passe.',
  'auth_error_password_not_numeric':
      'Le mot de passe ne peut pas contenir uniquement des chiffres.',
  'auth_error_generic': 'Une erreur est survenue. Veuillez reessayer.',
  'auth_error_backend_unreachable':
      'Impossible de joindre le backend. Lancez l API et definissez MOBILE_API_BASE_URL avec l IP de votre ordinateur.',
  'auth_error_backend_timeout':
      'Le backend met trop de temps a repondre. Verifiez qu il est bien lance et accessible.',
  'auth_error_invalid_server_url':
      'L URL du backend est invalide. Verifiez MOBILE_API_BASE_URL.',
  'auth_otp_hint': 'Entrez le code de verification a 6 chiffres',
  'auth_otp_sent': 'Code de verification envoye',
  'auth_otp_resent': 'Code de verification renvoye',
  'auth_otp_resend': 'Renvoyer le code',
  'auth_otp_resend_in': 'Renvoyer dans {seconds}s',
  'auth_error_empty_otp': 'Veuillez entrer le code de verification.',
  'auth_error_invalid_otp': 'Le code doit contenir 6 chiffres.',
  'auth_pending_title': 'Verification en cours',
  'auth_pending_desc':
      'Nous verifions actuellement votre demande. Une fois votre identite confirmee par appel, votre compte sera active.',
  'auth_wilaya_hint': 'Selectionnez votre wilaya',
  'auth_error_select_wilaya': 'Veuillez selectionner votre wilaya.',
  'auth_pending_registered_on': 'Inscription le {date}',
  'auth_pending_deadline': 'Reponse avant le {date} (3 jours)',
  'auth_pending_check_status': 'Verifier le statut',
  'auth_pending_still_waiting':
      'Votre compte est toujours en verification. Veuillez reessayer plus tard.',

  // Map Screen
  'map_title': 'Nassij',
  'map_search_hint': 'Rechercher des zones ou tâches...',
  'map_type_farmer': 'ÉLEVEUR',
  'map_type_slaughterhouse': 'ABATTOIR',
  'map_type_storage': 'STOCKAGE',
  'map_call': 'Appeler',

  // List Screen (Prioritized Orders)
  'list_title': 'Liste des tâches',
  'list_filter_all': 'Toutes les tâches',
  'list_filter_pending': 'En attente',
  'list_filter_completed': 'Terminé',
  'list_accept_task': 'Accepter la tâche',
  'list_in_progress': 'En cours',

  // My Loads Screen
  'loads_title': 'Mes chargements',
  'loads_active_job': 'TÂCHE ACTIVE',
  'loads_load_type': 'TYPE DE CHARGE',
  'loads_sheep_count': 'NOMBRE DE MOUTONS',
  'loads_pickup_slot': 'CRÉNEAU DE COLLECTE',
  'loads_contact_site': 'CONTACTER LE SITE',
  'loads_cancel_job': 'Annuler la tâche',
  'loads_cancel_confirm_title': 'Annuler la tâche ?',
  'loads_cancel_confirm_body':
      'Êtes-vous sûr de vouloir annuler cette tâche active ? Cette action est irréversible.',
  'loads_keep_job': 'Garder la tâche',
  'loads_no_active_jobs': 'Aucune tâche active',
  'loads_no_active_jobs_desc':
      'Vous n\'avez aucun chargement actif pour le moment. Consultez la carte pour trouver des tâches de collecte disponibles.',
  'loads_find_jobs': 'Trouver des tâches sur la carte',
  'loads_calling_site': 'Appel du site...',
  'loads_following_seller': 'Suivi de la position du vendeur...',
  'loads_seller': 'Vendeur',

  // Profile Screen
  'profile_title': 'Profil',
  'profile_data_connectivity': 'DONNÉES & CONNECTIVITÉ',
  'profile_sync_status': 'État de synchronisation',
  'profile_offline_queue': 'File d\'attente hors ligne : {count} rapports',
  'profile_user_default': 'Utilisateur',
  'profile_connection_online': 'En ligne',
  'profile_connection_offline': 'Hors ligne',
  'profile_connection_online_desc': 'Connecté au réseau',
  'profile_connection_offline_desc': 'Mode hors ligne actif',
  'profile_log_out': 'Se déconnecter',

  // Bottom Nav
  'nav_home': 'Accueil',
  'nav_operations': 'Opérations',
  'nav_map': 'Carte',
  'nav_list': 'Liste',
  'nav_my_loads': 'Charges',
  'nav_profile': 'Profil',

  // Supplier Dashboard (shared)
  'supplier_dashboard': 'Tableau de bord',
  'supplier_ready': 'Prêt pour l\'envoi',
  'supplier_ready_desc_farmer':
      'Votre récolte est vérifiée. Assurez-vous que toutes les balles sont étiquetées.',
  'supplier_ready_desc_producer':
      'Déclarez le poids de laine disponible pour la collecte.',
  'supplier_ready_desc_slaughterhouse':
      'Déclarez les peaux et laine disponibles pour la collecte.',
  'supplier_new_request': 'NOUVELLE DEMANDE DE COLLECTE',
  'supplier_active_ops': 'Opérations actives',
  'supplier_total': '{count} TOTAL',
  'supplier_input_count': 'Nombre de têtes',
  'supplier_input_weight': 'Poids (kg)',
  'supplier_input_count_or_weight': 'Nombre ou Poids (kg)',
  'supplier_declare': 'Déclarer',

  // Producer / Worker placeholders
  'producer_title': 'Tableau de bord Producteur',
  'producer_welcome': 'Bienvenue Producteur',
  'worker_title': 'Tableau de bord Ouvrier',
  'worker_welcome': 'Bienvenue Ouvrier',
  'supplier_or_label': 'OU',
  'supplier_error_count_required': 'Veuillez saisir un nombre valide.',
  'supplier_error_weight_required': 'Veuillez saisir un poids valide.',
  'supplier_error_count_or_weight_required':
      'Veuillez saisir un nombre ou un poids.',
  'supplier_declare_success': 'Declaration creee avec succes.',
  'supplier_declare_saved_offline':
      'Declaration enregistree hors ligne et synchronisee automatiquement.',
  'supplier_ops_offline_fallback':
      'Affichage des operations hors ligne en attendant le reseau.',
  'supplier_cancel_pending_title': 'Supprimer l\'operation en attente ?',
  'supplier_cancel_pending_desc':
      'Cette operation en attente sera deplacee vers votre historique.',
  'supplier_cancel_assigned_title': 'Annuler une operation assignee',
  'supplier_cancel_assigned_desc':
      'Vous devez appeler le collecteur assigne avant l\'annulation.',
  'supplier_collector_phone': 'Telephone collecteur: {phone}',
  'supplier_call_collector': 'Appeler le collecteur',
  'supplier_confirm_cancel': 'Confirmer l\'annulation',
  'supplier_cancel_success': 'Operation annulee.',
  'supplier_cancel_saved_offline':
      'Annulation enregistree hors ligne et synchronisee automatiquement.',
  'supplier_status_pending': 'En attente',
  'supplier_status_assigned': 'Assignee',
  'supplier_status_cancelled_pending': 'Annulee (attente)',
  'supplier_status_cancelled_assigned': 'Annulee (assignee)',
  'supplier_status_completed': 'Terminee',
  'supplier_quantity_weight': 'Poids: {value} kg',
  'supplier_quantity_count': 'Nombre: {value}',
  'supplier_quantity_unknown': 'Quantite: --',
  'supplier_section_active': 'Operations actives',
  'supplier_section_history': 'Historique',
  'supplier_location_label': 'Localisation',
  'supplier_location_none': 'Aucune localisation enregistree',
  'supplier_location_farm': 'Partager la localisation de la ferme',
  'supplier_location_stock': 'Partager la localisation du stock',
  'supplier_location_abattoir': "Partager la localisation de l'abattoir",
  'supplier_created_at': 'Creee le: {value}',
  'supplier_delete_operation': 'Supprimer',
  'profile_trust_score': 'Score de confiance: {score}/100',
  'common_yes': 'Oui',
  'common_no': 'Non',
  'common_skip': 'Ignorer',
  'common_share_location': 'Partager la localisation',
};
