# Firestore Index Checklist

This checklist reflects query patterns currently used in the app and helps prevent runtime index errors.

## Users Collection

File references:
- lib/repositories/admin_repository.dart

Potential composite indexes:
1. `users`: `role` Asc, `createdAt` Desc
2. `users`: `isActive` Asc, `createdAt` Desc
3. `users`: `profileCompleted` Asc, `createdAt` Desc
4. `users`: `metadata.city` Asc, `createdAt` Desc
5. `users`: `metadata.bloodGroup` Asc, `createdAt` Desc
6. `users`: `role` Asc, `isActive` Asc, `createdAt` Desc
7. `users`: `role` Asc, `profileCompleted` Asc, `createdAt` Desc
8. `users`: `role` Asc, `metadata.city` Asc, `createdAt` Desc
9. `users`: `role` Asc, `metadata.bloodGroup` Asc, `createdAt` Desc

Notes:
- Admin filters are combinable; Firestore may ask for additional indexes for specific combinations.
- Add indexes from Firebase Console error links when new combinations are introduced.

## Requests Collection

File references:
- lib/repositories/request_repository.dart

Potential composite indexes:
1. `requests`: `userId` Asc, `createdAt` Desc
2. `requests`: `isActive` Asc, `createdAt` Desc

Notes:
- Active request feeds now load from an `isActive` query and filter/sort in Dart, which avoids the previous composite index dependency.
- Request history by user still uses `userId` with `createdAt` ordering.

## Notifications Collection

File references:
- lib/repositories/notification_repository.dart

Potential composite indexes:
1. `notifications`: `recipientId` Asc, `status` Asc, `sentAt` Desc
2. `notifications`: `recipientId` Asc, `isRead` Asc, `status` Asc
3. `notifications`: `requestId` Asc, `type` Asc

Notes:
- Queries use `status != deleted`; Firestore may require specific index variants.
- Donor acceptance flow now hides `bloodRequest` notifications for other donors using `requestId` + `type` filters.
- If a query error appears, create the suggested index directly from the console link.

## Validation Steps

1. Run role flows: requester, donor, admin.
2. Open user management with different filter combinations.
3. Open notifications and run mark-all/clear-all operations.
4. Trigger active request feed in donor home with and without city metadata.
5. If index errors appear, use generated Firebase Console links to create missing indexes.
