import '../data/sync_action.dart';
import 'api_service.dart';

Future<void> pushSyncAction({
  required String accessToken,
  required SyncAction action,
}) async {
  if (action.table == 'supplier_declarations' &&
      action.actionType == 'insert') {
    await ApiService.createDeclaration(
      accessToken: accessToken,
      quantityCount: action.payload['quantity_count'] as int?,
      quantityWeightKg: (action.payload['quantity_weight_kg'] as num?)
          ?.toDouble(),
      latitude: (action.payload['location_lat'] as num?)?.toDouble(),
      longitude: (action.payload['location_lng'] as num?)?.toDouble(),
    );
    return;
  }

  if (action.table == 'supplier_operations' && action.actionType == 'cancel') {
    final operationId = action.payload['operation_id'] as String?;
    if (operationId == null || operationId.isEmpty) {
      throw ApiException('Missing operation id in sync payload');
    }
    await ApiService.cancelSupplierOperation(
      accessToken: accessToken,
      operationId: operationId,
      callConfirmed: action.payload['call_confirmed'] as bool? ?? false,
      reason: action.payload['reason'] as String?,
    );
    return;
  }

  if (action.table == 'collector_batches' && action.actionType == 'claim') {
    final batchId = action.payload['batch_id'] as String?;
    if (batchId == null || batchId.isEmpty) {
      throw ApiException('Missing batch_id in sync payload');
    }
    await ApiService.claimCollectorBatch(
      accessToken: accessToken,
      batchId: batchId,
    );
    return;
  }

  if (action.table == 'collector_batches' &&
      action.actionType == 'cancel_claim') {
    final batchId = action.payload['batch_id'] as String?;
    if (batchId == null || batchId.isEmpty) {
      throw ApiException('Missing batch_id in sync payload');
    }
    await ApiService.cancelCollectorBatchClaim(
      accessToken: accessToken,
      batchId: batchId,
    );
    return;
  }

  throw ApiException(
    'Unsupported sync action: ${action.table}/${action.actionType}',
  );
}
