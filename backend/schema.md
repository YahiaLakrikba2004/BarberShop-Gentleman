# Firestore Schema

## Collections

### `users`
- `id` (string): User UID
- `email` (string)
- `name` (string)
- `role` (string): 'client', 'barber', 'admin'
- `phoneNumber` (string, optional)

### `barbers`
- `id` (string): Barber ID
- `name` (string)
- `imageUrl` (string)
- `specialties` (array of strings)
- `startHour` (number): 0-23
- `endHour` (number): 0-23

### `services`
- `id` (string): Service ID
- `name` (string)
- `durationMinutes` (number)
- `price` (number)
- `description` (string)

### `appointments`
- `id` (string): UUID
- `customerId` (string)
- `customerName` (string)
- `barberId` (string)
- `barberName` (string)
- `serviceId` (string)
- `serviceName` (string)
- `date` (timestamp): Start time
- `durationMinutes` (number)
- `price` (number)
- `status` (string): 'pending', 'confirmed', 'completed', 'cancelled'
