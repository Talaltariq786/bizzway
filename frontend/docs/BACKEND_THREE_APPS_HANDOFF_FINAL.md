# 🚀 BizzWay — Three Apps Unified Backend Flow (Final Handoff)

**Purpose:**  
Yeh document backend team ke liye **complete system overview** deta hai — BizzWay ke **3 apps (Customer, Business Owner, Rider/Service Worker)** ka data flow, models aur API expectations.

👉 **Goal:** **Ek backend jo teeno apps ko connect kare**

---

## 🧩 1. System Overview (Simple)

BizzWay = **3 connected apps, 1 backend**

| App | Role | Kaam |
| --- | --- | --- |
| **Customer App** | `customer` | Browse, order, booking |
| **Business App** | `businessOwner` | Products, orders, bookings manage |
| **Rider / Worker App** | `rider` / `serviceWorker` | Delivery + service jobs |

👉 Backend = **single source of truth**

---

## 🔐 2. User & Roles

```json
{
  "id": "user1",
  "name": "Ali",
  "phone": "0300xxxxxxx",
  "role": "customer | businessOwner | rider | serviceWorker"
}
```

### Backend rules

- JWT authentication  
- Role-based access  
- Har API role check kare  

---

## 🏪 3. Core Entities (System Backbone)

### 3.1 Business

```json
{
  "id": "b1",
  "name": "Pizza Shop",
  "businessTypeId": "restaurant",
  "deliveryBaseCharge": 100,
  "deliveryPerKmCharge": 20
}
```

### 3.2 Product

```json
{
  "id": "p1",
  "businessId": "b1",
  "name": "Burger",
  "price": 500,
  "category": "Fast Food",
  "isAvailable": true
}
```

### 3.3 Order (Customer → Business → Rider)

```json
{
  "id": "o1",
  "customerId": "c1",
  "businessId": "b1",
  "items": [{ "productId": "p1", "qty": 2 }],
  "status": "pending | active | completed",
  "deliveryCharge": 150,
  "assignedRiderId": "r1"
}
```

### 3.4 Booking (Appointments / Rent-a-car)

```json
{
  "id": "bk1",
  "businessId": "b1",
  "itemId": "p1",
  "dateTime": "ISO_DATE",
  "status": "pending | confirmed | completed",
  "customerFullName": "Ali",
  "customerNic": "42101-xxxxxxx-x"
}
```

### 3.5 JobRequest (Rider / Worker system)

👉 **MOST IMPORTANT**

```json
{
  "id": "j1",
  "serviceTypeId": "rider | mechanic | plumber",
  "status": "pending | accepted | completed",
  "customerName": "Ali",
  "customerPhone": "0300xxxx",
  "originLat": 24.85,
  "originLng": 67.0,
  "destLat": 24.86,
  "destLng": 67.01,
  "itemsTotal": 1200,
  "deliveryFee": 150,
  "merchantFulfillmentStatus": "preparing | ready_for_rider"
}
```

---

## 🔄 4. End-to-End Flow (VERY IMPORTANT)

### 🧍 Customer flow

1. Customer app open karta hai  
2. Businesses fetch:

```http
GET /businesses
```

3. Products dekhta hai:

```http
GET /businesses/:id/products
```

4. Order place:

```http
POST /orders
```

5. Booking create:

```http
POST /bookings
```

### 🏪 Business owner flow

1. Owner login  
2. Products manage:

```http
POST /owner/products
PATCH /owner/products/:id
```

3. Orders receive:

```http
GET /owner/orders
```

4. Order prepare:

```http
PATCH /owner/orders/:id
```

👉 Set:

```json
{
  "merchantFulfillmentStatus": "ready_for_rider"
}
```

### 🛵 Rider / Worker flow

1. Rider online hota hai:

```http
PATCH /rider/status
```

2. Jobs fetch:

```http
GET /jobs
```

3. Job accept:

```http
PATCH /jobs/:id/accept
```

4. Job complete:

```http
PATCH /jobs/:id/complete
```

---

## 🔗 5. Flow Connection (Key Understanding)

```
Customer
   ↓
Order / Booking
   ↓
Business Owner
   ↓
(Job ready)
   ↓
Rider / Worker
```

👉 Sab kuch backend se linked hoga.

---

## ⚙️ 6. Current App Reality (IMPORTANT)

| Feature | Status |
| --- | --- |
| Products | Dummy / local |
| Orders | Dummy / local |
| Jobs | Dummy / local |
| Auth | Local |
| Bookings | Partial API |

👉 Matlab: **Backend abhi complete nahi** → jab real APIs aa jayein tab end-to-end system chalega.

---

## 🧠 7. Backend Rules (Must Implement)

### 1. Role-based access

- Customer → orders / booking  
- Owner → products / orders  
- Rider → jobs only  

### 2. Job visibility

```text
Rider ko job tab dikhe:
merchantFulfillmentStatus == ready_for_rider
AND rider.isOnline == true
```

### 3. Delivery logic

- Distance-based charges  
- **Backend must calculate** (not frontend-only for billing)

---

## 📡 8. Required APIs (Minimum)

### Auth

```http
POST /auth/login
POST /auth/register
GET /auth/me
```

### Customer

```http
GET /businesses
GET /businesses/:id/products
POST /orders
GET /orders
POST /bookings
GET /bookings
```

### Owner

```http
GET /owner/business
POST /owner/products
GET /owner/orders
PATCH /owner/orders/:id
```

### Rider / Worker

```http
GET /jobs
PATCH /jobs/:id/accept
PATCH /jobs/:id/complete
PATCH /rider/status
```

---

## 🏁 Final Summary

👉 BizzWay system =

> **Customer order karta hai → Business prepare karta hai → Rider deliver karta hai**

### 💬 Backend team ke liye one-line

> **Build a role-based API where customers create orders/bookings, businesses manage them, and riders/service workers fulfill jobs.**

---

## 🤝 Next step

- Node.js backend starter / routes expand  
- MongoDB schema design (align with Flutter `Order`, `CustomerBooking`, `Product`)  
- Postman collection  
- Flutter `ApiClient` + repositories step-by-step  

---

*Technical cross-check (repo paths, `apiBaseUrl`, mock vs API): `docs/BACKEND_UNIFIED_FROM_THREE_APPS.md`*

