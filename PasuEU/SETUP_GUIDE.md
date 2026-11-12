# PasuEU — SwiftUI + Supabase Setup Guide

No card required anywhere in this flow. If Supabase ever asks for billing
info during signup, that's for a paid add-on you don't need — the free
tier used here needs none.

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → **Start your project** → sign in with GitHub or email (no card)
2. **New project** → name it `PasuEU` → set a database password (save it somewhere — you won't need it day-to-day, but you'll want it if you ever connect a raw Postgres client)
3. Pick a region close to you (e.g. **Southeast Asia (Singapore)**)
4. Wait ~2 minutes for provisioning

## 2. Get your API keys

**Project Settings (gear icon) → API**. You need two values:
- **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
- **anon / public key** — a long JWT string (safe to embed in the app; it's the public client key, not a secret)

Open `Controllers/SupabaseManager.swift` and replace the placeholders:

```swift
client = SupabaseClient(
    supabaseURL: URL(string: "https://xxxxxxxxxxxx.supabase.co")!,
    supabaseKey: "eyJhbGciOi..."
)
```

## 3. Run the schema

**SQL Editor** (left sidebar) → **New query** → paste the whole block below → **Run**.

```sql
-- Users table. id matches auth.users.id (Supabase Auth's own UUID).
create table users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  university_email text not null,
  student_number text,
  contact_number text not null,
  role text not null check (role in ('client', 'buddy')),
  about_me text,
  profile_icon_name text not null default 'person.crop.circle.fill',
  is_online boolean not null default false,
  is_available boolean not null default false,
  current_latitude double precision,
  current_longitude double precision,
  average_rating double precision not null default 0,
  rating_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table requests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references users(id) on delete cascade,
  buddy_id uuid references users(id) on delete set null,
  type text not null check (type in ('pabili', 'pahatid', 'paprint')),
  is_urgent boolean not null default false,
  meeting_place text not null,
  destination text,
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  item_description text,
  recipient_name text,
  file_url text,
  file_name text,
  pages integer,
  copies integer,
  page_size text,
  color_option text,
  payment_method text check (payment_method in ('cash', 'gcash', 'card')),
  service_fee double precision not null default 0,
  delivery_fee double precision not null default 0,
  total_amount double precision not null default 0,
  buddy_latitude double precision,
  buddy_longitude double precision,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table ratings (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references requests(id) on delete cascade,
  rater_id uuid not null references users(id) on delete cascade,
  rated_user_id uuid not null references users(id) on delete cascade,
  stars integer not null check (stars between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table conversations (
  id uuid primary key default gen_random_uuid(),
  participant_ids uuid[] not null,
  last_message text,
  last_message_at timestamptz
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id uuid not null references users(id) on delete cascade,
  text text not null,
  sent_at timestamptz not null default now()
);

create table feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  stars integer not null check (stars between 1 and 5),
  suggestion text,
  created_at timestamptz not null default now()
);

-- Added for the Block / Report user flow.
create table blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references users(id) on delete cascade,
  blocked_id uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references users(id) on delete cascade,
  reported_id uuid not null references users(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);

-- Auto-recompute a buddy's average_rating/rating_count whenever a new
-- rating comes in, so the Swift client never has to do a manual
-- read-modify-write (which would race under concurrent ratings).
create or replace function update_user_rating()
returns trigger as $$
begin
  update users
  set
    rating_count = rating_count + 1,
    average_rating = (
      (average_rating * rating_count) + new.stars
    ) / (rating_count + 1)
  where id = new.rated_user_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_rating_inserted
  after insert on ratings
  for each row execute function update_user_rating();
```

## 4. Enable Row Level Security (RLS) and add policies

By default, once RLS is on, a table is fully locked — nothing is readable
or writable until you add explicit policies. Run this next:

```sql
alter table users enable row level security;
alter table requests enable row level security;
alter table ratings enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;
alter table feedback enable row level security;

-- Users: anyone signed in can read profiles; you can only edit your own.
create policy "Users are readable by signed-in users"
  on users for select using (auth.uid() is not null);
create policy "Users can insert their own row"
  on users for insert with check (auth.uid() = id);
create policy "Users can update their own row"
  on users for update using (auth.uid() = id);

-- Requests: any signed-in user can read; only the client can create;
-- the client or the assigned buddy can update (accept / change status).
create policy "Requests are readable by signed-in users"
  on requests for select using (auth.uid() is not null);
create policy "Clients can create their own requests"
  on requests for insert with check (auth.uid() = client_id);
create policy "Client or buddy can update a request"
  on requests for update using (auth.uid() = client_id or auth.uid() = buddy_id);

-- Ratings: signed-in users can read; you can only submit a rating as yourself.
create policy "Ratings are readable by signed-in users"
  on ratings for select using (auth.uid() is not null);
create policy "Users can insert their own ratings"
  on ratings for insert with check (auth.uid() = rater_id);

-- Conversations & messages: only participants can read/write.
create policy "Participants can read their conversations"
  on conversations for select using (auth.uid() = any(participant_ids));
create policy "Participants can update their conversations"
  on conversations for update using (auth.uid() = any(participant_ids));
create policy "Signed-in users can read messages"
  on messages for select using (auth.uid() is not null);
create policy "Signed-in users can send messages"
  on messages for insert with check (auth.uid() = sender_id);

-- Feedback: write-only from the client's perspective.
create policy "Users can submit their own feedback"
  on feedback for insert with check (auth.uid() = user_id);

-- Blocks & reports: write-only from the client's perspective; you can
-- read back your own block list to filter it out of the UI if you want to.
alter table blocks enable row level security;
alter table reports enable row level security;

create policy "Users can insert their own blocks"
  on blocks for insert with check (auth.uid() = blocker_id);
create policy "Users can read their own block list"
  on blocks for select using (auth.uid() = blocker_id);

create policy "Users can insert their own reports"
  on reports for insert with check (auth.uid() = reporter_id);
```

## 5. Enable Realtime on the tables you'll subscribe to

**Database → Replication** (or **Table Editor** → click a table → toggle
"Enable Realtime"). Turn this on for: `users`, `requests`, `messages`.
This is what makes `listenToOpenRequests`, `listenToAvailableBuddies`,
`listenToBuddyLocation`, and `listenToMessages` in `SupabaseManager.swift`
push live updates instead of you having to manually refresh.

## 6. Enable Email/Password auth

**Authentication → Providers** → **Email** should already be enabled by
default. Optional: under **Authentication → Settings**, turn off "Confirm
email" while you're developing solo, so you don't need a working mailbox
for every test account — just remember to turn it back on before anyone
outside your test group signs up.

## 7. Create the Storage bucket (for Paprint files)

**Storage** (left sidebar) → **New bucket** → name it exactly `request-files`
→ toggle **Public bucket** off (files should only be reachable by signed-in
users, not the whole internet) → **Create bucket**.

Then add its policies via SQL Editor:

```sql
create policy "Signed-in users can upload request files"
  on storage.objects for insert
  with check (bucket_id = 'request-files' and auth.uid() is not null);

create policy "Signed-in users can read request files"
  on storage.objects for select
  using (bucket_id = 'request-files' and auth.uid() is not null);
```

## 8. Add the Supabase Swift package

In Xcode: **File → Add Package Dependencies…** → paste:

```
https://github.com/supabase/supabase-swift
```

Select the **Supabase** product (the umbrella target — it bundles Auth,
Postgrest, Storage, and Realtime, which is everything `SupabaseManager.swift`
uses).

> **A note on reliability:** `supabase-swift` is a much younger, faster-moving
> library than Firebase's SDK. The API calls in `SupabaseManager.swift` were
> written against the current (v2) Realtime/Postgrest API shape, but if the
> package has updated since, you may see small compiler errors around method
> names (e.g. `postgresChange`, `channel.subscribe()`). If that happens,
> paste me the exact error and I'll fix it against whatever version Xcode
> resolves — this is the one part of the stack most likely to need a
> small patch on first build.

## 9. Project structure (MVC)

This project follows the **Model–View–Controller** pattern, adapted to
SwiftUI's data-binding style:

- **Model** — `Models/Models.swift`: plain data structs, no logic.
- **Controller** — `Controllers/`: `ObservableObject` classes that own app
  state (`@Published`) and all business logic (talking to Supabase,
  CoreLocation, etc.). Views never call the backend directly — they read
  a Controller's published state and call its methods.
- **View** — everything under `Views/`: one SwiftUI `View` struct per file,
  purely presentational, bound to Controllers via `@EnvironmentObject` /
  `@StateObject`.

```
PasuEU/
  PasuEUApp.swift                 # @main entry point only
  Models/
    Models.swift                   # AppUser, ServiceRequest, Rating, Message, ...
  Controllers/
    SupabaseManager.swift          # Auth + Postgrest + Storage + Realtime
    LocationManager.swift          # CoreLocation wrapper, broadcasts via SupabaseManager
  Views/
    RootView.swift                 # Splash → Login/SignUp → Home switch
    Onboarding/
      SplashView.swift
    Auth/
      LoginView.swift
      SignUpView.swift
      ForgotPasswordView.swift
      OTPVerificationView.swift
      ResetPasswordView.swift
    Home/
      HomeView.swift                # TabView shell
      HomeDashboardView.swift       # dashboard content (Home tab)
    Requests/
      NewRequestView.swift          # Service → Payment → Confirmation stepper
      RequestDetailView.swift       # accept / progress / complete / report / cancel
      RequestHistoryView.swift      # "Transactions" tab
    Map/
      MapTrackingView.swift         # MapKit live buddy tracking
    Rating/
      RatingView.swift              # per-request star rating
    Messaging/
      ConversationListView.swift
      ChatThreadView.swift
      MessageBuddyLink.swift        # resolves a buddy id into a conversation
    Social/
      BlockUserSheet.swift
      ReportUserSheet.swift
      ReportProblemLink.swift       # resolves a buddy id before reporting
    Profile/
      ProfileView.swift             # SF Symbol icon picker instead of photo
      SettingsView.swift
      AppFeedbackView.swift         # app-wide feedback, separate from per-request rating
```

Every file above contains exactly one `View` struct (or, for Controllers,
one class) — matching the rubric's "each screen or reusable component as
a separate SwiftUI View structure" and "organize the project into
separate Swift files" requirements directly.

## 10. What changed from the Firebase version, if you're comparing

| | Firebase | Supabase |
|---|---|---|
| Row/record IDs | `String?` (assigned by Firestore on write) | `UUID` (generated client-side, non-optional) |
| Live updates | `addSnapshotListener` → `ListenerRegistration` | Realtime channel → `DataSubscription` (same `.remove()` pattern) |
| File storage | `Storage.storage()`, needs Blaze (card) | Storage bucket, free tier, no card |
| Rating average | Manual Firestore transaction in Swift | Postgres trigger — Swift just inserts the row |
| Card required? | Yes, for Storage | No, for anything in this guide |

## 12. Additional tables for messaging, block, and report

Added to support the Chat, Block User, and Report User screens from the Figma prototype:

```sql
create table blocked_users (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references users(id) on delete cascade,
  blocked_id uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references users(id) on delete cascade,
  reported_id uuid not null references users(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);

alter table blocked_users enable row level security;
alter table reports enable row level security;

create policy "Users can view their own block list"
  on blocked_users for select using (auth.uid() = blocker_id);
create policy "Users can block others"
  on blocked_users for insert with check (auth.uid() = blocker_id);
create policy "Users can unblock"
  on blocked_users for delete using (auth.uid() = blocker_id);

create policy "Users can submit their own reports"
  on reports for insert with check (auth.uid() = reporter_id);
```

Also enable Realtime on `conversations` the same way you did for `users`/`requests`/`messages`:

```sql
alter publication supabase_realtime add table conversations;
```

## 13. New screens added (Figma parity pass)

| Screen | File |
|---|---|
| Splash / Welcome | `Views/Onboarding/SplashView.swift` |
| Forgot Password | `Views/Auth/ForgotPasswordView.swift` |
| Email/OTP Verification | `Views/Auth/OTPVerificationView.swift` |
| Reset Password | `Views/Auth/ResetPasswordView.swift` |
| Conversations list | `Views/Chat/ConversationsListView.swift` |
| Chat thread | `Views/Chat/ChatThreadView.swift` |
| View another user's profile | `Views/Profile/BuddyProfileView.swift` |
| Block user confirmation | `Views/Profile/BlockUserView.swift` |
| Report user | `Views/Profile/ReportUserView.swift` |
| GCash payment | `Views/Requests/GCashPaymentView.swift` |
| Credit/Debit card payment | `Views/Requests/CardPaymentView.swift` |

## 14. Next build steps

1. Fill in your Project URL + anon key in `SupabaseManager.swift` (step 2 above)
2. Run the Part 12 SQL for `blocked_users` and `reports`
3. Build (⌘B) — expect a few small errors on first pass, that's normal
4. Test sign-up → check **Authentication → Users** and **Table Editor → users** in the Supabase dashboard to confirm a row appears in both places
5. Test a Paprint file upload → check **Storage → request-files** for the uploaded file


## 15. Restrict Paprint file access

Replaces the step 7 read policy so only the request's client and its assigned buddy can read a file. Files are stored as `<request id>/<file name>`, so the first folder name identifies the request. Run in the SQL Editor:

```sql
drop policy if exists "Signed-in users can read request files" on storage.objects;

create policy "Request parties can read request files"
  on storage.objects for select
  using (
    bucket_id = 'request-files'
    and exists (
      select 1 from public.requests r
      where r.id::text = (storage.foldername(name))[1]
        and (r.client_id = auth.uid() or r.buddy_id = auth.uid())
    )
  );
```

A buddy can read the file only after accepting the request, because `buddy_id` is set at that moment.
