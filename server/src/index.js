const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

const PORT = Number(process.env.PORT) || 3000;
const DATA_PATH = path.join(__dirname, '..', 'data', 'bookings.json');

function loadBookings() {
  try {
    const raw = fs.readFileSync(DATA_PATH, 'utf8');
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveBookings(list) {
  const dir = path.dirname(DATA_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(DATA_PATH, JSON.stringify(list, null, 2), 'utf8');
}

function nextId(list) {
  const max = list.reduce((m, b) => {
    const n = String(b.id || '').replace(/\D/g, '');
    const v = parseInt(n, 10);
    return Number.isFinite(v) ? Math.max(m, v) : m;
  }, 0);
  return `BK-${String(max + 1).padStart(3, '0')}`;
}

function normalizeBooking(body) {
  const b = body && typeof body === 'object' ? body : {};
  return {
    id: b.id != null && String(b.id).trim() !== '' ? String(b.id) : undefined,
    businessId: String(b.businessId ?? ''),
    businessName: String(b.businessName ?? ''),
    businessTypeId: String(b.businessTypeId ?? ''),
    itemId: String(b.itemId ?? ''),
    itemName: String(b.itemName ?? ''),
    price: typeof b.price === 'number' ? b.price : Number(b.price) || 0,
    durationMinutes:
      b.durationMinutes == null ? null : Number.parseInt(String(b.durationMinutes), 10),
    dateTime: b.dateTime != null ? String(b.dateTime) : new Date().toISOString(),
    status: String(b.status ?? 'pending'),
    notes: b.notes == null ? null : String(b.notes),
    userId: b.userId == null ? null : String(b.userId),
  };
}

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/bookings', (req, res) => {
  const userId = req.query.userId;
  let list = loadBookings();
  if (userId != null && String(userId).trim() !== '') {
    list = list.filter((b) => b.userId === String(userId));
  }
  res.json({ data: list });
});

app.post('/bookings', (req, res) => {
  const raw = normalizeBooking(req.body);
  if (!raw.businessId || !raw.businessName) {
    res.status(400).json({ message: 'businessId and businessName are required' });
    return;
  }

  const list = loadBookings();
  const id = raw.id || nextId(list);
  if (list.some((b) => b.id === id)) {
    res.status(409).json({ message: 'Booking id already exists' });
    return;
  }

  const booking = {
    id,
    businessId: raw.businessId,
    businessName: raw.businessName,
    businessTypeId: raw.businessTypeId,
    itemId: raw.itemId,
    itemName: raw.itemName,
    price: raw.price,
    durationMinutes: Number.isFinite(raw.durationMinutes) ? raw.durationMinutes : null,
    dateTime: raw.dateTime,
    status: raw.status || 'pending',
    notes: raw.notes,
    ...(raw.userId ? { userId: raw.userId } : {}),
  };

  list.unshift(booking);
  saveBookings(list);
  res.status(201).json({ data: booking });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`BizLabel API listening on http://localhost:${PORT}`);
});
