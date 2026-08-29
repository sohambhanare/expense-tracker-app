# Expense Tracker — Full-Stack Flutter + FastAPI

A personal-finance tracker built as a full-stack project:

- **Flutter** app (Material 3, light/dark/system theme, animated charts) — the mobile/web client
- **FastAPI** REST API with **JWT authentication** and **SQLAlchemy** ORM (SQLite by default, Postgres-ready)
- **Automatic API docs** via Swagger UI at `/docs` (when running locally)

## Features

- Register / login with hashed passwords (bcrypt) and JWT bearer tokens (7-day expiry)
- 12 default categories auto-seeded per new account (custom colors/icons)
- Transactions: create, edit, delete with type, amount, category, date, note
- Filters: type (in/out), category, month, plus client-side note/category search
- Dashboard: total balance, this month's income/spent, recent activity
- Stats: spending-by-category pie (name legend, 2-col grid) + 6-month income/expense bar chart
- Budgets per category + progress bars and over-budget warnings
- Category manager (add/edit/delete with color + icon picker)
- CSV export of transactions via share sheet
- Light / dark / system theme + 30-currency selector (local preference)
- Token persisted securely on device (`shared_preferences`) with session restore
- Owner-scoped data: every query is scoped to the authenticated user

## Project layout

```
backend/
   app/
     main.py               FastAPI app + CORS + routers
     database.py           SQLAlchemy engine/session (SQLite default)
     models.py             User, Category, Transaction, Budget
     schemas.py            Pydantic request/response models
     security.py           bcrypt hashing + JWT issue/verify
     deps.py               get_current_user dependency
     routers/
       auth.py             /auth/register, /auth/login, /auth/me
       transactions.py     /transactions CRUD + filters
       categories.py       /categories CRUD
       budgets.py          /budgets CRUD (monthly limits)
       stats.py            /stats/summary (balance, slices, trend, budgets)
 expense_tracker/
  lib/
    api/                  HTTP client + typed repository
    models/               User, Category, Transaction, Summary
    state/                Provider state (auth + finance)
    screens/              login, register, home, dashboard,
                          transactions, stats, settings, txn sheet
    widgets/              transaction tile
     theme.dart            Material 3 light/dark themes
```

## Getting started

### 1. Backend

Requires Python 3.11+.

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
# then open http://localhost:8000/docs for the Swagger UI (local only)
```

Environment variables (optional):

| Variable          | Default        | Purpose                                   |
| ----------------- | -------------- | ----------------------------------------- |
| `JWT_SECRET`      | `dev-secret…`  | Set a strong secret in production         |
| `DB_PATH`         | `./expense.db` | Point at Postgres via SQLAlchemy URL edit |
| `ALLOWED_ORIGINS` | `*`            | Comma-separated CORS origins              |

### 2. Flutter app

Requires Flutter 3.x.

```bash
cd expense_tracker
flutter pub get
flutter run
```

The API base URL is auto-detected in `lib/config.dart`:

- Android emulator → `http://10.0.2.2:8000`
- iOS simulator / desktop / web → `http://localhost:8000`

If you run the backend on another machine, change `Config.apiBaseUrl`.

> **Android note:** HTTP to `10.0.2.2` works out of the box because
> `android:usesCleartextTraffic="true"` is enabled in the manifest for dev.
> Remove it and add HTTPS before shipping.

### 3. Demo account

A seeded test account from development exists (`test@example.com` / `password123`),
but you can simply register a new account — 12 categories are created automatically.

## Testing

```bash
# backend: run the API, then run a quick smoke test
cd backend
uvicorn app.main:app --port 8000 &
curl -X POST localhost:8000/auth/register -H 'Content-Type: application/json' \
  -d '{"name":"Demo","email":"demo@demo.com","password":"password123"}'

# flutter: analyze + unit tests
cd ../expense_tracker
flutter analyze
flutter test
```

## API overview

| Method | Path                  | Description                       |
| ------ | --------------------- | --------------------------------- |
| POST   | `/auth/register`      | Create account (returns JWT)      |
| POST   | `/auth/login`         | Login (returns JWT)               |
| GET    | `/auth/me`            | Current user                      |
| GET    | `/categories`         | List categories                   |
| POST   | `/categories`         | Create category                   |
| PUT    | `/categories/{id}`    | Update category                   |
| DELETE | `/categories/{id}`    | Delete category                   |
| GET    | `/transactions`       | List with `type`, `category_id`, `from_date`, `to_date`, `limit`, `offset` filters |
| POST   | `/transactions`       | Create transaction                |
| PUT    | `/transactions/{id}`  | Update transaction                |
| DELETE | `/transactions/{id}`  | Delete transaction                |
| GET    | `/stats/summary`      | Balance, month totals, category slices, N-month trend + budgets |
| GET    | `/budgets`            | List monthly budgets |
| PUT    | `/budgets/{categoryId}` | Create/update budget limit |
| DELETE | `/budgets/{categoryId}` | Delete budget |

## Roadmap (nice-to-haves)

- Recurring transactions
- Deployment (Docker + Postgres, hosted Flutter web build)
- Biometric app lock + push notifications

## Tech stack

Flutter 3.47 (Dart 3.13) · Provider · fl_chart · http · shared_preferences · intl
FastAPI · SQLAlchemy 2 · Pydantic v2 · PyJWT · bcrypt · SQLite
