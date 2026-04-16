export type Role = 'customer' | 'businessOwner' | 'rider' | 'serviceWorker' | 'admin';

export type JwtPayload = {
  sub: string; // userId
  roles: Role[];
};

