# PasuEU — Midterm Rubric Alignment

A direct mapping from your instructor's requirements to where each one is
satisfied in this project. Useful as reference for your submission
write-up.

---

### "Your application must demonstrate at least 50% of its planned interface and functionality."

The app currently has **18 distinct screens** covering the full loop for
both user roles (client and Errand Buddy): onboarding, auth (including
forgot-password/OTP/reset), the three service types (Pabili/Pahatid/
Paprint) as a full request flow, live map tracking, messaging, ratings,
block/report, and profile/settings. That's comfortably past the 50%
threshold set out in your original Application Design Proposal.

### "Use appropriate SwiftUI layouts and user-interface components."

`Form`, `List`, `NavigationStack`, `TabView`, `ScrollView`, `LazyVGrid`,
`Map` (MapKit), `Picker`/segmented control, `Stepper`, `TextEditor`,
`sheet`/`fileImporter`/`Menu` are all used where they're the natural fit
— e.g. `Form` for the Sign Up/Profile edit screens, `Map` for
`MapTrackingView.swift`, `TabView` for the four-tab home shell.

### "Contain at least four distinct screens." / "Provide working navigation between the screens."

18 screens (well past the minimum of four), connected via `NavigationStack`
+ `navigationDestination`, `TabView`, and `.sheet()` presentations. The
full navigation graph is diagrammed in `SETUP_GUIDE.md` section 9 — start
there if your instructor asks you to walk through the flow.

### "Define each screen or reusable interface component as a separate SwiftUI View structure."

Every screen (`LoginView`, `HomeDashboardView`, `NewRequestView`, etc.) and
every reusable component (`BlockUserSheet`, `ReportUserSheet`,
`MessageBuddyLink`) is its own `View` struct.

### "Organize the project into separate Swift files according to each file's purpose or functionality."

Every screen and reusable component is its own `View` struct in its own
`.swift` file. The models are grouped together in `Models/Models.swift`,
and `Models/` also holds `FeeRates.swift` and `FeeEstimate.swift`
(pricing types, each in its own file). A few files keep a small private
helper type (an enum or struct used only by that view) next to the view
that uses it. Folders are grouped by feature area (`Auth/`, `Requests/`, `Messaging/`, `Social/`,
etc.), matching the project structure in `SETUP_GUIDE.md` section 9.

### "Apply the Model–View–Controller (MVC) architectural pattern."

- **Model** — `Models/Models.swift`. Plain `Codable` structs
  (`AppUser`, `ServiceRequest`, `Rating`, `Message`, `Conversation`,
  `AppFeedback`) with zero business logic — they only describe data shape.
- **Controller** — `Controllers/SupabaseManager.swift` and
  `Controllers/LocationManager.swift`. Both are `ObservableObject`
  classes that own app state as `@Published` properties and contain all
  business logic — talking to the Supabase backend, wrapping
  CoreLocation. This is the layer that mediates between the Model and
  the View, which is the defining role of a Controller in MVC.
- **Local storage (SwiftData)** — `Models/CachedRequest.swift`,
  `Models/CachedUser.swift`, `Models/CachedConversation.swift` and
  `Models/CachedMessage.swift` are `@Model` classes, and
  `Controllers/LocalStore.swift` wraps the `ModelContext`. Supabase stays
  the source of truth; the cache lets the Home, Transactions, Messages and
  chat screens show saved requests, conversations and messages immediately
  and keep working with an "Offline: showing saved data" notice when a fetch
  fails. See `SETUP_GUIDE.md` section 18.
- **View** — everything under `Views/`. SwiftUI structs are kept
  presentational: they read a Controller's `@Published` state through
  `@EnvironmentObject`/`@StateObject` and call Controller methods in
  response to user actions (e.g. `LoginView` calls
  `supabase.signIn(email:password:)` rather than talking to Supabase's
  SDK directly).

If your instructor wants this spelled out explicitly in your report, the
short version is: **Views bind to Controllers, Controllers own Models —
Views never touch the backend or CoreLocation directly.**

### "Follow consistent naming, formatting, and code-organization practices."

- PascalCase for types (`ServiceRequest`, `LoginView`), camelCase for
  properties/methods (`currentUser`, `signIn(email:password:)`).
- Consistent 4-space indentation and brace style throughout.
- Consistent brand color (`Color(red: 0.42, green: 0.08, blue: 0.1)`,
  matching your Figma's maroon) is used the same way across every screen.
- Code is comment-free by request — file purpose is instead conveyed by
  folder placement (`Controllers/`, `Views/<Feature>/`) and clear type/
  method names.

### "Compile and run without errors."

**This is the one requirement not yet verified** — none of this code has
been compiled, since it was written without access to Xcode/a Mac in this
conversation. Before you submit:

1. Finish `SETUP_GUIDE.md` steps 1–2 and 8 (Supabase project + credentials
   + Swift package) — the database schema (steps 3–7) is **not** required
   for the midterm demo; see "Demo Mode" below.
2. Build (⌘B) in Xcode
3. Send me any compiler errors, in order, and I'll fix them — the most
   likely source of first-build errors is the Realtime API calls in
   `SupabaseManager.swift` (flagged in section 8 of the setup guide),
   since `supabase-swift` moves faster than most packages

---

### Demo Mode (bypassing the database for the midterm)

`SupabaseManager.signInWithDemoAccount(role:)` signs a hardcoded
`AppUser` in locally — no network call, no dependency on the `users`
table existing yet. Two buttons on the Login screen ("Demo — Client" /
"Demo — Buddy") call it directly, so the full navigation graph, both
role-specific dashboards, and every screen are demoable right now, even
with a placeholder Supabase URL/key.

**What this does and doesn't prove:**
- ✅ Every screen renders, navigates, and is role-aware
- ✅ Forms validate and the request-flow stepper works
- ⚠️ Lists that read from the database (open orders, transaction history,
  available buddies, messages) will render **empty**, not broken — the
  fetch methods in `SupabaseManager` catch errors and fall back to an
  empty array rather than crashing, so this looks like "no data yet"
  rather than a bug
- ❌ Nothing actually persists (a submitted request, a sent message, a
  rating won't survive a relaunch) until the schema in `SETUP_GUIDE.md`
  steps 3–7 is run

**Before your final submission**, once the database is fully connected:
remove the `demoSection` view and its two buttons in `LoginView.swift`,
and the `signInWithDemoAccount(role:)` method in `SupabaseManager.swift`
— both are named distinctly enough to find easily even without a comment
flagging them.
