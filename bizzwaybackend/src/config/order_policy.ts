/** Max active (non-terminal) orders a single rider can carry at once (assign-rider). */
export const RIDER_MAX_CONCURRENT_ASSIGNMENTS = 3;

/** Order statuses that count toward rider capacity (not yet delivered / cancelled). */
export const ORDER_STATUSES_ACTIVE_FOR_RIDER = [
  'pending',
  'accepted',
  'preparing',
  'ready',
  'picked',
] as const;
