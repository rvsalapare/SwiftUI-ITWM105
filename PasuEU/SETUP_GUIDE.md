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

-- Added for the Report user flow.
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

-- Reports: write-only from the client's perspective.
alter table reports enable row level security;

create policy "Users can insert their own reports"
  on reports for insert with check (auth.uid() = reporter_id);
```

## 5. Enable Realtime on the tables you'll subscribe to

**Database → Replication** (or **Table Editor** → click a table → toggle
"Enable Realtime"). Turn this on for: `users`, `requests`, `messages`.
This is what makes `listenToOpenRequests`, `listenToAvailableBuddies`,
`listenToUserLocation`, and `listenToMessages` in `SupabaseManager.swift`
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
  PasuEUApp.swift                 # @main entry point; creates the SwiftData container
  Models/
    Models.swift                   # AppUser, ServiceRequest, Rating, Message, ...
    FeeRates.swift                 # every price in pesos and the estimate calculation
    FeeEstimate.swift              # line amounts and total for a request's fee estimate
    CampusArea.swift               # campus center, camera span and boundary polygon for the tracking map
    CachedRequest.swift            # SwiftData copy of a ServiceRequest, owned by the signed-in user
    CachedUser.swift               # SwiftData copy of an AppUser
    CachedConversation.swift       # SwiftData copy of a Conversation, owned by the signed-in user
    CachedMessage.swift            # SwiftData copy of a Message, including readAt
    AppNotification.swift          # in-app notification row with a computed kind (symbol and tint)
  Controllers/
    SupabaseManager.swift          # Auth + Postgrest + Storage + Realtime
    LocationManager.swift          # CoreLocation wrapper, broadcasts via SupabaseManager
    LocalStore.swift               # SwiftData cache of requests, conversations, messages and users
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
      OrderRow.swift                # open-order row with URGENT and NEW tags (buddy Home tab)
      CountPill.swift               # pulsing count pill for the Available Orders header
      ServiceCard.swift             # tappable Pabili / Pahatid / Paprint card on the client Home tab
      ActiveRequestBanner.swift     # banner for the user's most recent pending, accepted or in-progress request
    Requests/
      NewRequestView.swift          # Service → Payment → Confirmation stepper
      RequestDetailView.swift       # accept / progress / complete / report / cancel
      RequestHistoryView.swift      # "Transactions" tab
      RequestProgressTracker.swift  # Pending → Accepted → In progress → Completed step tracker (or Cancelled)
      FeeBreakdownCard.swift        # service fee, delivery fee, print cost, total and payment method
      HistoryFilter.swift           # All / Active / Completed / Cancelled filter for the Transactions tab
      ShareSheet.swift              # UIActivityViewController wrapper for sharing a downloaded Paprint file
    Map/
      MapTrackingView.swift         # MapKit live tracking of buddy and client with walking route
      TrackingInfoCard.swift        # bottom card: other person's name, distance, ETA
    Rating/
      RatingView.swift              # per-request star rating
    Messaging/
      ConversationListView.swift
      ConversationRow.swift         # row model: a conversation, the other user and the unread count
      ChatThreadView.swift
      MessageBuddyLink.swift        # resolves a buddy id into a conversation
    Social/
      BlockUserSheet.swift
      ReportUserSheet.swift
      ReportProblemLink.swift       # resolves a buddy id before reporting
    Notifications/
      NotificationsView.swift       # grouped notification list, mark all as read, opens the request or chat
      NotificationRow.swift         # one notification card with kind icon and unread dot
    Shared/
      Theme.swift                   # brand colors, gradient, corner radii and spacing constants
      ScreenHeader.swift            # gradient hero header (bar, centered or badge style)
      FormFieldRow.swift            # icon + input row used on Login, Sign Up and Profile
      PrimaryButton.swift           # full-width brand button with loading and disabled states
      CardContainer.swift           # rounded secondary-grouped-background card
      EmptyStateView.swift          # reusable icon / title / message / optional "Try again" state
      OfflineNotice.swift           # small "Offline: showing saved data" notice
      UnreadBadge.swift             # unread count badge ("99+" above 99)
    Profile/
      ProfileView.swift             # SF Symbol icon picker instead of photo
      SettingsView.swift
      AppFeedbackView.swift         # app-wide feedback, separate from per-request rating
      AboutView.swift               # About screen, pushed from Settings
      HelpView.swift                # Help screen, pushed from Settings
      ReportIssueView.swift         # "Report an issue" sheet, writes to issue_reports
```

Every screen and reusable component is its own `View` struct in its own
file — matching the rubric's "each screen or reusable component as a
separate SwiftUI View structure" and "organize the project into separate
Swift files" requirements directly. Models are grouped in
`Models/Models.swift`, the pricing types `FeeRates` and `FeeEstimate`
each have their own file in `Models/`, and a few files keep a small
private helper type next to the view that uses it.

## 10. What changed from the Firebase version, if you're comparing

| | Firebase | Supabase |
|---|---|---|
| Row/record IDs | `String?` (assigned by Firestore on write) | `UUID` (generated client-side, non-optional) |
| Live updates | `addSnapshotListener` → `ListenerRegistration` | Realtime channel → `DataSubscription` (same `.remove()` pattern) |
| File storage | `Storage.storage()`, needs Blaze (card) | Storage bucket, free tier, no card |
| Rating average | Manual Firestore transaction in Swift | Postgres trigger — Swift just inserts the row |
| Card required? | Yes, for Storage | No, for anything in this guide |

## 12. Additional table for blocking users

Added to support the Block User screen. The `reports` table used by the Report User screen is already created in steps 3 and 4.

```sql
create table blocked_users (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references users(id) on delete cascade,
  blocked_id uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);

alter table blocked_users enable row level security;

create policy "Users can view their own block list"
  on blocked_users for select using (auth.uid() = blocker_id);
create policy "Users can block others"
  on blocked_users for insert with check (auth.uid() = blocker_id);
create policy "Users can unblock"
  on blocked_users for delete using (auth.uid() = blocker_id);
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
| Conversations list | `Views/Messaging/ConversationListView.swift` |
| Chat thread | `Views/Messaging/ChatThreadView.swift` |
| Open a chat with a buddy (resolves buddy id) | `Views/Messaging/MessageBuddyLink.swift` |
| Block user confirmation | `Views/Social/BlockUserSheet.swift` |
| Report user | `Views/Social/ReportUserSheet.swift` |
| Report a problem with a buddy (resolves buddy id) | `Views/Social/ReportProblemLink.swift` |
| New request (service, payment incl. GCash/card, confirmation) | `Views/Requests/NewRequestView.swift` |
| Request detail | `Views/Requests/RequestDetailView.swift` |
| Request history (Transactions tab) | `Views/Requests/RequestHistoryView.swift` |
| Share downloaded Paprint file | `Views/Requests/ShareSheet.swift` |

## 14. Next build steps

1. Fill in your Project URL + anon key in `SupabaseManager.swift` (step 2 above)
2. Run the Part 12 SQL for `blocked_users`
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


## 16. Issue reports table

Backs the "Report an issue" row in Settings. Users can insert their own reports only; there is no read, update, or delete access from the client. Run in the SQL Editor:

```sql
create table issue_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  description text not null,
  created_at timestamptz not null default now()
);

alter table issue_reports enable row level security;

create policy "Users can insert their own issue reports"
  on issue_reports for insert with check (auth.uid() = user_id);
```

## 17. Unread message tracking

Adds a nullable `read_at` column to `messages`. A recipient marks a message read by setting it. Only participants of the conversation who are not the sender may update a message, and column-level privileges limit that update to `read_at` so nobody can edit message text. Run in the SQL Editor:

```sql
alter table messages add column read_at timestamptz;

revoke update on messages from anon, authenticated;
grant update (read_at) on messages to authenticated;

create policy "Recipients can mark messages read"
  on messages for update
  using (
    sender_id <> auth.uid()
    and exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
        and auth.uid() = any(c.participant_ids)
    )
  )
  with check (
    sender_id <> auth.uid()
    and exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
        and auth.uid() = any(c.participant_ids)
    )
  );
```

## 18. Local storage with SwiftData

SwiftData keeps a local copy of recent data so the app has something to show when the network is slow or down. Supabase stays the source of truth: every successful fetch overwrites the local copy, and nothing is ever written to Supabase from the cache.

- `Models/CachedRequest.swift`, `Models/CachedUser.swift`, `Models/CachedConversation.swift` and `Models/CachedMessage.swift` are the `@Model` classes. Each has an initializer from its `Codable` struct, an `update(from:)` method and a method that converts back. Cached requests and conversations also carry an `ownerId`, the signed-in user whose cache they belong to. A conversation's participant ids are stored as one comma-separated string.
- `Controllers/LocalStore.swift` wraps the `ModelContext` with `saveRequests(_:ownerId:)` (upsert, then delete that owner's rows missing from the fresh list), `loadRequests(ownerId:)` (newest first), `saveConversations(_:ownerId:)` and `loadConversations(ownerId:)` (newest first by last message), `saveMessages(_:conversationId:)` (only that conversation's messages are pruned) and `loadMessages(conversationId:)` (oldest first), `saveUser(_:)`, `loadUser(id:)` and `clearAll()`.
- `PasuEUApp.swift` creates the `ModelContainer` for all four models, attaches it with `.modelContainer`, and hands its context to `LocalStore`.
- `SupabaseManager` saves the results of `fetchMyRequests`, `fetchOpenRequests`, `fetchCompletedJobs`, `fetchConversations` and `fetchMessages`, saves every profile returned by `fetchUser(id:)` (so conversation names show offline), saves the user after `loadCurrentUser`, falls back to the cached user if that load fails with a network error, and calls `LocalStore.clearAll()` on sign out.
- `HomeDashboardView`, `RequestHistoryView`, `ConversationListView` and `ChatThreadView` show cached data as soon as they appear, replace it when fresh data arrives, and show "Offline: showing saved data" instead of the failure state when a fetch fails but cached data exists.
- Sending is unchanged and is not queued: a message sent while offline shows the inline send error and keeps the typed text.

No database setup is needed for this section. SwiftData requires iOS 17 or later.

## 19. In-app notifications

The app shows an in-app notification list (bell button on the Home header). The app only reads `notifications` and sets `read_at`; it never inserts rows. Rows are created by the database triggers further down. Run this in the SQL Editor only if the table does not already exist:

```sql
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  request_id uuid references requests(id) on delete cascade,
  conversation_id uuid references conversations(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on notifications (user_id, created_at desc);

alter table notifications enable row level security;

drop policy if exists "Users can read their own notifications" on notifications;
create policy "Users can read their own notifications"
  on notifications for select using (auth.uid() = user_id);

drop policy if exists "Users can mark their own notifications read" on notifications;
create policy "Users can mark their own notifications read"
  on notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

revoke insert, update, delete on notifications from anon, authenticated;
grant update (read_at) on notifications to authenticated;

alter publication supabase_realtime add table notifications;
```

The `revoke` and `grant update (read_at)` lines are what limit clients to changing `read_at` only. If `notifications` is already in the realtime publication, the last statement reports an error that can be ignored.

In the app, `SupabaseManager` fetches the latest 50 rows for the signed-in user, listens to realtime changes on `notifications` and refreshes (debounced, with a generation check so stale results are dropped), and exposes `notifications` and `unreadNotificationCount`. `markNotificationRead(id:)` and `markAllNotificationsRead(userId:)` update the local list first and then the server. Tracking starts and stops in `HomeView`, and `signOut` stops it.

### Triggers that create notifications

These four functions run as the database owner (`security definer`), so they can insert into `notifications` even though clients cannot. They are safe to run again: functions use `create or replace` and each trigger is dropped before it is created.

```sql
create or replace function notify_new_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into notifications (user_id, type, title, body, request_id)
  select
    u.id,
    'new_request',
    'New order available',
    new.meeting_place || case when new.is_urgent then ' (URGENT)' else '' end,
    new.id
  from users u
  where u.role = 'buddy'
    and u.id <> new.client_id;
  return new;
end;
$$;

drop trigger if exists trg_notify_new_request on requests;
create trigger trg_notify_new_request
  after insert on requests
  for each row execute function notify_new_request();

create or replace function notify_request_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  status_title text;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  status_title := case new.status
    when 'accepted' then 'Your request was accepted'
    when 'in_progress' then 'Your errand is in progress'
    when 'completed' then 'Your request is completed'
    when 'cancelled' then 'Your request was cancelled'
    else null
  end;

  if status_title is null then
    return new;
  end if;

  insert into notifications (user_id, type, title, body, request_id)
  values (new.client_id, 'status_' || new.status, status_title, new.meeting_place, new.id);

  if new.status = 'cancelled' and new.buddy_id is not null then
    insert into notifications (user_id, type, title, body, request_id)
    values (new.buddy_id, 'status_cancelled', 'A request was cancelled', new.meeting_place, new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_request_update on requests;
create trigger trg_notify_request_update
  after update on requests
  for each row execute function notify_request_update();

create or replace function notify_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into notifications (user_id, type, title, body, conversation_id)
  select
    participant,
    'message',
    'New message',
    left(new.text, 80),
    new.conversation_id
  from conversations c, unnest(c.participant_ids) as participant
  where c.id = new.conversation_id
    and participant <> new.sender_id;
  return new;
end;
$$;

drop trigger if exists trg_notify_new_message on messages;
create trigger trg_notify_new_message
  after insert on messages
  for each row execute function notify_new_message();

create or replace function notify_new_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into notifications (user_id, type, title, body, request_id)
  values (new.rated_user_id, 'rating', 'You received a rating', new.stars::text || ' star(s)', new.request_id);
  return new;
end;
$$;

drop trigger if exists trg_notify_new_rating on ratings;
create trigger trg_notify_new_rating
  after insert on ratings
  for each row execute function notify_new_rating();
```

The notification `type` values these triggers write are `new_request`, `status_accepted`, `status_in_progress`, `status_completed`, `status_cancelled`, `message` and `rating`, which the app's `AppNotification.kind` maps to its five kinds.
