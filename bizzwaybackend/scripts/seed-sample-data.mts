/**
 * Sample Mongo data so the Flutter app shows real API products (not only dummy lists).
 *
 * Run from repo: `cd backend && npm run seed`
 *
 * Creates (if missing) a demo business owner + 2 businesses (grocery + restaurant) + a few products.
 */
import 'dotenv/config';
import mongoose from 'mongoose';

import { loadEnv } from '../src/config/env.js';
import { BusinessModel } from '../src/models/Business.js';
import { ProductModel } from '../src/models/Product.js';
import { UserModel } from '../src/models/User.js';
import { hashPassword } from '../src/utils/password.js';

async function main() {
  const env = loadEnv(process.env);
  await mongoose.connect(env.MONGODB_URI);

  const email = 'demo.owner@bizzway.local';
  const password = 'demo@12345';

  let owner = await UserModel.findOne({ email });
  if (!owner) {
    const passwordHash = await hashPassword(password);
    owner = await UserModel.create({
      email,
      passwordHash,
      roles: ['businessOwner'],
      name: 'Demo Owner (API)',
    });
    console.log('Created demo user', email, 'password:', password);
  }
  const ownerId = owner._id;

  async function ensureBiz(p: {
    name: string;
    type: string;
    address: string;
    lng: number;
    lat: number;
  }) {
    let b = await BusinessModel.findOne({ ownerId, type: p.type });
    if (!b) {
      b = await BusinessModel.create({
        ownerId,
        name: p.name,
        type: p.type,
        address: p.address,
        location: { type: 'Point', coordinates: [p.lng, p.lat] },
      });
      console.log('Created business', p.type, b._id.toString());
    }
    return b;
  }

  const g = await ensureBiz({
    name: 'Fresh Mart (API)',
    type: 'grocery',
    address: 'DHA Phase 5, Karachi',
    lng: 67.03,
    lat: 24.81,
  });

  const r = await ensureBiz({
    name: 'Karachi Kitchen (API)',
    type: 'restaurant',
    address: 'Clifton Block 2, Karachi',
    lng: 67.025,
    lat: 24.815,
  });

  const sampleProducts: { biz: typeof g; items: { name: string; price: number; category: string }[] }[] =
    [
      {
        biz: g,
        items: [
          { name: 'Atta 5kg', price: 1450, category: 'Staples (Basic Food)' },
          { name: 'Cooking Oil 1L', price: 890, category: 'Oil & Ghee' },
          { name: 'Biscuits Pack', price: 220, category: 'Snacks & Bakery' },
        ],
      },
      {
        biz: r,
        items: [
          { name: 'Chicken Biryani', price: 450, category: 'Food' },
          { name: 'Mint Margarita', price: 180, category: 'Drinks' },
        ],
      },
    ];

  for (const block of sampleProducts) {
    for (const it of block.items) {
      const exists = await ProductModel.findOne({
        businessId: block.biz._id,
        name: it.name,
      });
      if (exists) continue;
      await ProductModel.create({
        businessId: block.biz._id,
        name: it.name,
        category: it.category,
        price: it.price,
        images: [],
        stock: 20,
        isActive: true,
      });
      console.log('Added product', it.name, '→', block.biz.type);
    }
  }

  await mongoose.disconnect();
  console.log('Seed complete. Login app as business owner with', email, '/', password);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
