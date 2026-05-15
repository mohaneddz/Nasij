insert into users (id, phone_number, sector, full_name, wilaya, created_at) values
('11111111-1111-4111-8111-111111111111', '0770112233', 'MANAGER', 'NFN Admin', 'Alger', now() - interval '10 days'),
('22222222-2222-4222-8222-222222222222', '0555001122', 'C1_FARMER', 'Farmer 1122', 'Djelfa', now() - interval '9 days'),
('33333333-3333-4333-8333-333333333333', '0555123456', 'COLLECTOR', 'Collector 3456', 'Djelfa', now() - interval '9 days'),
('44444444-4444-4444-8444-444444444444', '0555012233', 'C3_AGGREGATOR', 'Aggregator 2233', 'Batna', now() - interval '8 days')
on conflict (id) do nothing;

insert into batches (
    batch_id, source_type, breed, wilaya, status, creator_id, collector_id,
    purchase_price_dzd, location_lat, location_lng, type_de_laine, proprete_score,
    sacs_count, weight_raw_e1_kg, weight_after_handclean_kg, stockage_zone,
    classification, temperature_tas_celsius, taux_matiere_vegetale_percent,
    weight_clean_d2_kg, yield_percentage, humidite_sortie_percent, ph_laine,
    fiber_length_mm, finesse_micron, humidity_percent, final_destination,
    is_ready_for_sale, action_timestamp, synced_at, created_at
) values
(
    'NFN-202', 'C1', 'OULED_DJELLAL', 'Djelfa', 'AT_D2_LAVAGE',
    '22222222-2222-4222-8222-222222222222', '33333333-3333-4333-8333-333333333333',
    15400.00, 34.78000000, 3.08000000, 'TOISON_ENTIERE', 2, 12,
    500.00, 460.00, 'OULED_DJELLAL', 'CLASSE_B_SOUILLEE', 38.00, 4.90,
    200.00, 40.00, 13.80, 7.20, null, null, null, null,
    false, now() - interval '4 days', now() - interval '4 days', now() - interval '4 days'
),
(
    'NFN-304', 'C2', 'MIXTE', 'M''Sila', 'AT_D1_STOCKAGE',
    '44444444-4444-4444-8444-444444444444', '33333333-3333-4333-8333-333333333333',
    18500.00, 35.70000000, 4.54000000, 'PELADE_CHIMIQUE', 2, 11,
    200.00, 80.00, 'EL_HAMRA', 'CLASSE_B_SOUILLEE', 45.00, 5.80,
    75.00, 37.50, 14.00, 7.30, null, null, null, null,
    false, now() - interval '3 days', now() - interval '3 days', now() - interval '3 days'
),
(
    'NFN-710', 'C1', 'OULED_DJELLAL', 'Djelfa', 'READY_FOR_SALE',
    '22222222-2222-4222-8222-222222222222', '33333333-3333-4333-8333-333333333333',
    21000.00, 34.90000000, 3.10000000, 'TOISON_ENTIERE', 4, 15,
    560.00, 548.00, 'OULED_DJELLAL', 'CLASSE_A_PROPRE', 34.00, 2.00,
    242.00, 44.16, 12.50, 7.10, 88.00, 21.10, 8.80, 'D3',
    true, now() - interval '2 days', now() - interval '2 days', now() - interval '2 days'
),
(
    'NFN-711', 'C3', 'BARBAR', 'Tiaret', 'IN_TRANSFORMATION',
    '44444444-4444-4444-8444-444444444444', '33333333-3333-4333-8333-333333333333',
    16000.00, 35.40000000, 1.29000000, 'TOISON_MORCEAUX', 3, 10,
    510.00, 500.00, 'BARBAR', 'CLASSE_B_SOUILLEE', 36.00, 4.00,
    180.00, 36.00, 13.20, 7.00, 62.00, 29.20, 10.50, 'D4',
    false, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day'
)
on conflict (batch_id) do nothing;

insert into alerts (id, batch_id, alert_type, severity, description, action, is_resolved, created_at) values
('11111111-1111-4111-8111-111111111202', 'NFN-202', 'ALERTE_RENDEMENT_INTELLIGENT', 'POINT_ROUGE',
 'Lot NFN-202 (Tonte C1). Rendement actuel: 40%. Anomalie: Le rendement tonte doit etre > 55%.',
 'Controle fournisseur', false, now() - interval '4 days'),
('22222222-2222-4222-8222-222222222304', 'NFN-304', 'ALERTE_AUTO_COMBUSTION', 'POINT_ROUGE',
 'Lot NFN-304 (Depot D1). Temperature du tas critique (45C). Risque d''incendie ou pourriture.',
 'Isoler le lot', false, now() - interval '3 days'),
('33333333-3333-4333-8333-333333333405', 'NFN-304', 'ALERTE_MATIERES_VEGETALES', 'POINT_JAUNE',
 'Lot NFN-304. Taux de paille > 5%. Action auto: Redirige vers Classe B (Engrais).',
 'Rediriger Classe B', false, now() - interval '3 days')
on conflict (id) do nothing;

