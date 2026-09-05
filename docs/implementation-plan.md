# HelloPlant — Implementation Plan (Version 1)

## Problem

People living in the same home cannot tell whether someone else has already watered the
plants. The result is double watering or no watering at all.

## Proposed approach

One shared **Home** that contains all plants for a household. Each tap on **Watered Now**
appends an immutable `WateringEvent`. The "last watered" status is always *derived* from the
newest event, never stored. Data lives in Core Data locally and syncs through
`NSPersistentCloudKitContainer`. The Home is shared exactly once with `CKShare` +
`UICloudSharingController`; every plant and event inside it follows automatically.

Target experience: **Open app → check status → tap Watered Now → close app.**

---

## Current repository state (verified)

| Fact | Value |
| --- | --- |
| Project | `HelloPlant.xcodeproj`, `objectVersion = 77` (Xcode 16+ format) |
| Groups | Uses `PBXFileSystemSynchronizedRootGroup` — **new files in `HelloPlant/` are added to the target automatically**, no `.pbxproj` editing needed |
| Existing code | `HelloPlantApp.swift`, `ContentView.swift` (template "Hello, world!") |
| Test targets | `HelloPlantTests` (Swift Testing), `HelloPlantUITests` (XCTest) — both already wired |
| Bundle ID | `com.rahulsinghvi.HelloPlant` |
| Team | `9GLZK7V7CD` |
| Deployment target | `26.5` → **to be lowered to `17.4`** (decision) |
| Swift version | 5.0 setting, `SWIFT_APPROACHABLE_CONCURRENCY = YES` |

### Confirmed decisions

1. Deployment target is lowered to **iOS 17.4**.
2. The Core Data model `contents` XML is **hand-written in VS Code** and only *verified* in
   Xcode's model editor.
3. Automated tests are **local unit tests only** (no CloudKit, no UI tests). CloudKit and
   sharing are validated by manual two-device testing.

### Honesty note

Everything produced in VS Code on Windows is **written but not compiled and not tested**.
Swift/SwiftUI/Core Data cannot be built here. Every phase below therefore separates
"prepared in VS Code" from "must be compiled in Xcode on Mac". No phase may be called
complete until it has been built and run on a Mac.

---

## 0. Agreed UX (locked)

Prototype: **[ux-prototype.html](./ux-prototype.html)** — 12 screens, rendered and reviewed.
Open it in any browser. It is a static HTML mockup for agreement only; it is not SwiftUI and
proves nothing about the build.

### Visual direction — botanical & warm

* **Palette.** Warm cream paper (`#FDFAF3`) with a soft sage gradient wash, not iOS grey.
  Leaf green (`#3E9B54` → `#2A7340`) is the single action colour.
* **Per-plant accent colours** — leaf green, terracotta, sun, sky, lilac, rose. Each plant card
  carries a coloured spine, a tinted wash and a gradient icon tile in its own accent.
  **Accent colour is plant identity, never status** — this keeps the "no overdue styling"
  rule intact while making the screen colourful.
* **Plant icon per plant**, chosen from a small preset picker when adding or editing. In the
  mockup these are emoji; **in the app they become SF Symbols** (`leaf.fill`, `camera.macro`,
  `tree.fill`, …) tinted with the plant's accent, so they scale with Dynamic Type and work
  with VoiceOver. No photos, no plant recognition.
* **Cards, not table rows.** Rounded 20 pt cards with soft shadows, generous spacing.
* **Personal header** — `OUR HOME` eyebrow, a greeting (`Good morning, Alex`), a factual
  summary (`4 plants · 3 watered this week`), and overlapping participant avatars.
* **Person chips.** Who watered is a coloured avatar chip (`A you`, `S Sam`), not plain text —
  this is the app's core information, so it is given visual weight.
* Decorative oversized leaf motifs at very low opacity on empty and welcome screens.

### Screen inventory

| # | Screen | Purpose |
| --- | --- | --- |
| 1 | Onboarding | Display name, asked once, device-local |
| 2 | Empty state | Single inviting "Add a plant" action |
| 3 | **Plant list** ★ | The whole app: colour-coded cards, status + who + one-tap Water |
| 4 | **After tap** ★ | Card blooms green, "Just now · you" + undo banner |
| 5 | Add plant | Name + optional icon picker |
| 6 | Plant detail | Gradient hero with derived status + full history |
| 7 | Edit plant | Rename + icon + archive |
| 8 | Share home | Participants + Add People (`UICloudSharingController`) |
| 9 | Accept invite | "Join Alex's home?" |
| 10 | Offline | Amber offline bar + "1 change waiting to sync" |
| 11 | Archived | Greyed cards, Restore, history preserved |
| 12 | Accessibility | Card as one element, colour never carries meaning |

### Locked decisions

1. **Row button = droplet + "Water"**, a green gradient pill. The literal "Watered Now" pill
   clipped the status to `2 days ago · by S…`, destroying the app's core information. The
   **accessibility label remains "Watered Now"**, and the full-width button on the detail
   screen keeps the full "Watered Now" wording.
2. **No overdue styling.** Status text is always neutral. An amber "9 days ago" implies a
   watering schedule, which the brief excludes. The app reports facts; the human judges.
   Card accent colours are decorative identity only and must never be derived from status.
3. **List order = longest-unwatered first, never-watered at the top.** Purely a sort over the
   derived latest event — no plant-care thresholds involved.
4. **Undo = banner for ~6 seconds.** After it disappears the local event id is forgotten and
   the watering is permanent. Undo never touches a housemate's event.
5. **Card position is stable while the undo banner is visible**, then the list re-sorts. Cards
   must not jump under the user's finger.
6. **A watered card gets a green wash and a "✓ Watered" state** for the life of the banner,
   then returns to its normal accent.

### Status string vocabulary

`Never watered` · `Just now` · `Today 08:15` · `2 days ago`, each followed by a person chip
(`you` / `Sam`). Spoken form: *"Monstera, last watered two days ago by Sam."*

### Data model impact of the visual direction

The botanical UI needs one field the original brief did not have:

* **`Plant.iconName: String?`** — the SF Symbol name chosen from a small preset picker
  (for example `leaf.fill`, `camera.macro`, `tree.fill`, `microbe.fill`, `fan.fill`).
  It is optional, defaults to a generic leaf, and is CloudKit-safe.
* **The accent colour is derived from `iconName`, not stored.** A pure function
  `PlantAccent.color(for:)` maps the icon to one of six palette colours. No extra field, and
  the colour can be retuned later without a schema migration.
* Nothing else changes. There is still **no stored `lastWateredAt`**, no photo, no species.

Because the CloudKit production schema is append-only, `iconName` must be present in the
Phase 3 model before the Phase 4 schema push.

### UX rules carried into every phase

* The card is the only place a watering is recorded in one tap; detail is the second entry
  point, never the required one.
* Nothing on the main screen may push the status text or the person chip into truncation.
* Colour is decorative; every state is also carried by text.
* No photos, species, rooms, groups, schedules, reminders or care tips anywhere.

---

## 1. Recommended project structure

```
HelloPlant/
├─ App/
│  ├─ HelloPlantApp.swift            // @main, injects AppEnvironment
│  ├─ AppDelegate.swift              // UIApplicationDelegateAdaptor, scene config
│  ├─ SceneDelegate.swift            // CKShare invitation acceptance
│  └─ AppEnvironment.swift           // composition root (repository + profile store)
├─ Models/
│  ├─ Home.swift                     // struct Home
│  ├─ Plant.swift                    // struct Plant
│  ├─ WateringEvent.swift            // struct WateringEvent
│  ├─ LocalProfile.swift             // struct LocalProfile
│  └─ PlantStatus.swift              // derived status: lastEvent, wateredBy, age
├─ Repository/
│  ├─ PlantRepository.swift          // protocol (the only seam Views/VMs know)
│  ├─ InMemoryPlantRepository.swift  // Phase 1–2, also used by tests & previews
│  └─ CoreDataPlantRepository.swift  // Phase 3+
├─ Persistence/
│  ├─ PersistenceController.swift    // NSPersistentCloudKitContainer setup
│  ├─ HelloPlant.xcdatamodeld/
│  │  └─ HelloPlant.xcdatamodel/contents
│  ├─ ManagedObjects/
│  │  ├─ CDHome.swift                // codegen = Manual/None
│  │  ├─ CDPlant.swift
│  │  └─ CDWateringEvent.swift
│  └─ ManagedObjectMapping.swift     // CD* → domain structs
├─ Sharing/
│  ├─ ShareCoordinator.swift         // creates/fetches CKShare for the Home
│  └─ CloudSharingView.swift         // UIViewControllerRepresentable wrapper
├─ ViewModels/
│  ├─ PlantListViewModel.swift
│  ├─ PlantDetailViewModel.swift
│  └─ OnboardingViewModel.swift
├─ Views/
│  ├─ RootView.swift                 // onboarding gate → PlantListView
│  ├─ OnboardingView.swift
│  ├─ PlantListView.swift
│  ├─ PlantCardView.swift            // colour-accented card + Water button
│  ├─ PersonChip.swift               // avatar + name chip
│  ├─ HomeHeaderView.swift           // eyebrow, greeting, summary, avatars
│  ├─ UndoBanner.swift
│  ├─ PlantIconPicker.swift
│  ├─ AddPlantView.swift
│  └─ PlantDetailView.swift          // history + rename + archive
├─ Support/
│  ├─ LocalProfileStore.swift        // UserDefaults, device-local, never synced
│  └─ RelativeDateText.swift         // "2 days ago" formatting + a11y label
├─ Theme/
│  ├─ Palette.swift                  // cream/sage/leaf + 6 plant accents
│  ├─ PlantAccent.swift              // pure iconName -> accent mapping
│  └─ PlantIcon.swift                // preset SF Symbol list for the picker
├─ Assets.xcassets
└─ HelloPlant.entitlements           // created in Xcode (Phase 4)

HelloPlantTests/
├─ InMemoryPlantRepositoryTests.swift
├─ PlantStatusTests.swift
├─ PlantListViewModelTests.swift
├─ UndoWateringTests.swift
└─ CoreDataPlantRepositoryTests.swift   // in-memory store at /dev/null
```

`ContentView.swift` is deleted in Phase 1 (replaced by `RootView`).

### Architecture rule

```
SwiftUI Views → View Models → PlantRepository (protocol) → Core Data → CloudKit
```

* Views never import `CoreData` or `CloudKit`. Views only see domain structs.
* View models are `@Observable` (`Observation`, available from iOS 17) and hold a
  `PlantRepository`.
* `CoreDataPlantRepository` is the only type that touches `NSManagedObjectContext`.
* `ShareCoordinator` is the single exception boundary that touches CloudKit types; it is
  reached through the repository/environment, and the view only receives a prepared
  `UICloudSharingController`.
* No third-party packages. No extra abstraction layers.

### Key modelling rules (non-negotiable)

* **No `lastWateredAt` attribute anywhere.** Status is computed as
  `plant.wateringEvents.max(by: wateredAt)`.
* Every **Watered Now** tap creates a new `WateringEvent` with a fresh `UUID`.
* **Undo** removes only the event whose id was recorded by the most recent *local* tap in
  this app session; it can never delete a household member's event or an older event.
* `wateredBy` stores a **snapshot of the display name string** at event time (there are no
  user accounts to reference).
* CloudKit mirroring constraints: every attribute optional or with a default value, no
  unique constraints, every relationship optional and with an inverse.

---

## 2. Phase-by-phase implementation plan

Legend: 🪟 = can be prepared in VS Code (Windows) · 🍎 = must be compiled/run in Xcode on Mac ·
⚙️ = manual Xcode/portal configuration · 📱📱 = requires two physical iPhones with different
iCloud accounts.

---

### Phase 1 — Local in-memory prototype

**Objective.** Establish the domain model, the repository seam, and the core screen with no
persistence at all.

**User-visible result.** Launch the app, type a display name once, see a hard-coded list of
2–3 plants with "Never watered", tap **Watered Now**, and see the row change to "Just now ·
by <you>". Everything is lost on relaunch — that is expected.

**Files to create or modify.**
* Create: `Models/Home.swift`, `Models/Plant.swift`, `Models/WateringEvent.swift`,
  `Models/LocalProfile.swift`, `Models/PlantStatus.swift`
* Create: `Theme/Palette.swift`, `Theme/PlantAccent.swift`, `Theme/PlantIcon.swift`
* Create: `Repository/PlantRepository.swift`, `Repository/InMemoryPlantRepository.swift`
* Create: `ViewModels/PlantListViewModel.swift`, `ViewModels/OnboardingViewModel.swift`
* Create: `Views/RootView.swift`, `Views/OnboardingView.swift`, `Views/PlantListView.swift`,
  `Views/PlantCardView.swift`, `Views/PersonChip.swift`, `Views/HomeHeaderView.swift`,
  `Views/UndoBanner.swift`
* Create: `Support/LocalProfileStore.swift`, `Support/RelativeDateText.swift`,
  `App/AppEnvironment.swift`
* Modify: `App/HelloPlantApp.swift` (move file, inject environment)
* Delete: `ContentView.swift`

**Agreed UX to implement (see section 0).** Warm cream background with a sage wash; each plant
is a rounded card with a per-plant accent spine, tinted icon tile, name, status and a green
droplet/"Water" pill whose accessibility label is "Watered Now". Who watered it is a coloured
person chip. Status text is never colour-coded by recency. Sort longest-unwatered first with
never-watered at the top.

**Main Swift types.**
```swift
struct Home: Identifiable, Hashable { let id: UUID; var name: String; var createdAt: Date }
struct Plant: Identifiable, Hashable { let id: UUID; var name: String; var createdAt: Date; var archivedAt: Date?; var iconName: String? }
struct WateringEvent: Identifiable, Hashable { let id: UUID; var wateredAt: Date; var wateredBy: String; var createdAt: Date; var plantID: UUID }
struct LocalProfile { var displayName: String; let installationIdentifier: UUID }
struct PlantStatus { let plant: Plant; let lastEvent: WateringEvent? }

protocol PlantRepository {
    func home() async throws -> Home
    func plantStatuses(includeArchived: Bool) async throws -> [PlantStatus]
    func addPlant(named: String) async throws -> Plant
    func recordWatering(plantID: UUID, by displayName: String, at: Date) async throws -> WateringEvent
    func undoWatering(eventID: UUID) async throws
}

@Observable final class PlantListViewModel { ... }   // holds [PlantStatus], lastLocalEventID
```

**Tests (`HelloPlantTests`, Swift Testing).**
* `PlantStatusTests` — status of a plant with no events is "never watered"; with several
  events the newest `wateredAt` wins even when inserted out of order.
* `InMemoryPlantRepositoryTests` — `recordWatering` appends a new event with a unique id;
  two taps produce two events.
* `PlantListViewModelTests` — tapping water updates the row and sets `lastLocalEventID`.
* `PlantOrderTests` — never-watered plants sort above watered ones; among watered plants the
  oldest last-watering sorts first.
* `PlantAccentTests` — `PlantAccent.color(for:)` is deterministic, covers every preset icon,
  and falls back to the default leaf accent for `nil` or an unknown icon name.

**Manual Xcode work.**
* ⚙️ Set `IPHONEOS_DEPLOYMENT_TARGET` to `17.4` for all three targets.
* 🍎 Open the project, confirm the synchronized group picked up the new folders, build and
  run in the simulator, run the unit tests.

**Completion criteria.**
Builds on Mac; unit tests pass; the onboarding → list → Watered Now loop works in the
simulator; no `CoreData` or `CloudKit` import exists anywhere yet.

**Copilot prompt.**
> Create the Phase 1 in-memory prototype for the iOS app HelloPlant in Swift 5 / SwiftUI,
> deployment target iOS 17.4. Add value-type domain models `Home`, `Plant`, `WateringEvent`,
> `LocalProfile` and a derived `PlantStatus` that computes the latest watering from an event
> array — do not add any `lastWateredAt` stored property. Define a `PlantRepository` protocol
> with async methods `home()`, `plantStatuses(includeArchived:)`, `addPlant(named:)`,
> `recordWatering(plantID:by:at:)` and `undoWatering(eventID:)`, and implement
> `InMemoryPlantRepository` as an actor seeded with three sample plants. Add an `@Observable`
> `PlantListViewModel` and `OnboardingViewModel`, a `LocalProfileStore` backed by
> `UserDefaults` storing a display name and a generated installation `UUID`, and SwiftUI views
> `RootView`, `OnboardingView`, `PlantListView`, `HomeHeaderView`, `PlantCardView`,
> `PersonChip` and `UndoBanner`. Style: warm cream background (`#FDFAF3`) with a soft sage
> gradient wash; each plant is a rounded 20 pt card with a 5 pt accent spine, a gradient icon
> tile showing the plant's SF Symbol, the name, the relative status, a person chip for who
> watered it, and a green gradient pill button showing a droplet and the word "Water" whose
> accessibility label is "Watered Now". Add `Theme/Palette.swift`, `Theme/PlantIcon.swift`
> (preset SF Symbols) and `Theme/PlantAccent.swift`, a pure function mapping `iconName` to one
> of six accent colours. Accent colour is plant identity only — never derive any colour from
> watering recency and never imply a schedule. Sort the list with never-watered plants first,
> then by oldest last-watering. Views must not import CoreData or CloudKit. Delete
> `ContentView.swift`
> and update `HelloPlantApp` to inject an `AppEnvironment`. Add Swift Testing unit tests for
> status derivation, repeated watering creating distinct UUIDs, and the view model update.

---

### Phase 2 — Multiple plants, history, undo, rename, archive

**Objective.** Complete the full Version 1 feature surface while still fully in memory.

**User-visible result.** Add plants from a "+" sheet, open a plant to see its complete
watering history (time + who), rename it, archive it (archived plants leave the main list),
and undo an accidental check-in right after tapping.

**Files to create or modify.**
* Create: `Views/AddPlantView.swift`, `Views/PlantDetailView.swift`,
  `Views/PlantIconPicker.swift`, `ViewModels/PlantDetailViewModel.swift`
* Modify: `PlantRepository.swift` (+ `renamePlant`, `archivePlant`, `wateringHistory(plantID:)`),
  `InMemoryPlantRepository.swift`, `PlantListView.swift`, `PlantListViewModel.swift`

**Main Swift types.** `PlantDetailViewModel`, `AddPlantView`, and an undo affordance
(`UndoBanner` inside `PlantListView`) driven by `lastLocalEventID` + the plant it belongs to.

**Undo semantics to implement.**
`lastLocalEventID` is in-memory session state on the view model. It is set only by a local
`recordWatering` call, cleared after undo, after the banner times out, and on app relaunch.
`undoWatering` refuses any id that is not the recorded local one.

**Tests.**
* Undo removes exactly one event and only the locally created one; undoing twice is a no-op.
* Undo of an event created by another person's name (simulated) is rejected.
* Archiving hides a plant from `plantStatuses(includeArchived: false)` but keeps its events.
* Rename preserves id and history.

**Manual Xcode work.** 🍎 Build, run, exercise flows in the simulator.

**Completion criteria.**
Every Version 1 feature except persistence and sharing works in the simulator; all unit tests
pass; no forbidden features (schedules, reminders, photos, groups) added.

**Copilot prompt.**
> Extend the HelloPlant in-memory prototype to Phase 2. Add `renamePlant(id:to:iconName:)`,
> `archivePlant(id:)`, `restorePlant(id:)` and `wateringHistory(plantID:)` to `PlantRepository`
> and `InMemoryPlantRepository`. Add `PlantIconPicker`, a horizontal row of preset SF Symbol
> tiles rendered in each icon's accent colour with a ring on the selected one. Add `AddPlantView`
> (name field + icon picker + Add), `PlantDetailView` with a gradient hero showing the derived
> status and a full-width "Watered Now" button, followed by the complete watering history
> newest-first as cards with person avatars, and `PlantDetailViewModel`. Add an edit screen for
> rename, icon change and archive. Add undo: after a local "Watered Now" tap the list shows an
> undo banner for that event; `PlantListViewModel` stores the event id of the last local tap in
> memory only, and `undoWatering` must reject any id other than that one. Archived plants must
> disappear from the main list while keeping their history and be restorable from an archived
> screen showing greyed cards. Add Swift Testing cases for undo restrictions, archive filtering,
> restore, and rename preserving id and events.

---

### Phase 3 — Local Core Data persistence

**Objective.** Replace the in-memory store with Core Data on the device, with a schema that is
already CloudKit-compatible.

**User-visible result.** Plants and watering history survive app relaunch. Behaviour is
otherwise identical.

**Files to create or modify.**
* Create: `Persistence/HelloPlant.xcdatamodeld/HelloPlant.xcdatamodel/contents` (hand-written XML)
* Create: `Persistence/PersistenceController.swift` (plain `NSPersistentContainer` in this phase)
* Create: `Persistence/ManagedObjects/CDHome.swift`, `CDPlant.swift`, `CDWateringEvent.swift`
  (codegen Manual/None)
* Create: `Persistence/ManagedObjectMapping.swift`, `Repository/CoreDataPlantRepository.swift`
* Modify: `App/AppEnvironment.swift` (switch the concrete repository)

**Model (`contents` XML) — CloudKit-safe from day one.**

| Entity | Attributes | Relationships |
| --- | --- | --- |
| `CDHome` | `id: UUID?`, `name: String?`, `createdAt: Date?` | `plants` → `CDPlant` (to-many, optional, inverse `home`, cascade delete) |
| `CDPlant` | `id: UUID?`, `name: String?`, `createdAt: Date?`, `archivedAt: Date?`, `iconName: String?` | `home` → `CDHome` (to-one, optional, inverse `plants`), `wateringEvents` → `CDWateringEvent` (to-many, optional, inverse `plant`, cascade delete) |
| `CDWateringEvent` | `id: UUID?`, `wateredAt: Date?`, `wateredBy: String?`, `createdAt: Date?` | `plant` → `CDPlant` (to-one, optional, inverse `wateringEvents`) |

No unique constraints, no non-optional attributes, no ordered relationships (all forbidden by
CloudKit mirroring). `LocalProfile` is **not** in Core Data — it stays in `UserDefaults` so it
never syncs to the household.

**Main Swift types.** `PersistenceController` (with an `inMemory` initializer pointing the
store URL at `/dev/null` for tests), `CoreDataPlantRepository` performing all work on a
background context and returning domain structs, `CDHome/CDPlant/CDWateringEvent` subclasses.

**Tests.**
* `CoreDataPlantRepositoryTests` against an in-memory container: create home on first launch
  (exactly one Home ever), add plant, record two waterings → two rows, undo removes one,
  archive/rename persist, status derived from newest event.

**Manual Xcode work.**
* 🍎 Open `HelloPlant.xcdatamodeld` in Xcode's model editor and confirm the hand-written XML
  loads and shows the three entities.
* ⚙️ Verify each entity's *Codegen* is set to **Manual/None** and the class names match.
* 🍎 Build and run; verify data survives a relaunch.

**Completion criteria.**
Model opens without error in Xcode; repository tests pass against the in-memory store; data
persists across relaunch; the in-memory repository still compiles and is used by previews and
tests.

**Copilot prompt.**
> Add Phase 3 Core Data persistence to HelloPlant. Hand-write
> `Persistence/HelloPlant.xcdatamodeld/HelloPlant.xcdatamodel/contents` as valid Core Data model
> XML with entities `CDHome`, `CDPlant` (including the `iconName` string attribute) and
> `CDWateringEvent` exactly as specified: all attributes
> optional, no unique constraints, all relationships optional with inverses, cascade delete from
> home to plants and from plant to events, codegen Manual/None. Write matching `NSManagedObject`
> subclasses with `@NSManaged` properties and `fetchRequest()` helpers. Add `PersistenceController`
> using `NSPersistentContainer` with an `inMemory` option that sets the store URL to `/dev/null`,
> `automaticallyMergesChangesFromParent = true` and a merge-by-property-object-trump policy.
> Implement `CoreDataPlantRepository` conforming to `PlantRepository`, doing all work on a
> background context, creating a single default Home on first launch, and mapping managed objects
> to the domain structs in `ManagedObjectMapping.swift`. Never store a lastWateredAt value.
> Switch `AppEnvironment` to the Core Data repository and add Swift Testing tests that run against
> the in-memory container.

---

### Phase 4 — iCloud synchronization (private database)

**Objective.** Mirror the local store to the user's private CloudKit database so the same
iCloud account stays in sync across that person's own devices.

**User-visible result.** Install on iPhone and iPad with the same Apple ID: plants and
watering events appear on both within seconds.

**Files to create or modify.**
* Modify: `Persistence/PersistenceController.swift` → `NSPersistentCloudKitContainer`,
  private store description with `NSPersistentCloudKitContainerOptions`
  (`containerIdentifier: iCloud.com.rahulsinghvi.HelloPlant`), history tracking and remote
  change notifications enabled.
* Create: `HelloPlant.entitlements` (generated by Xcode).
* Modify: `App/AppEnvironment.swift` if a remote-change observer is added.

**Main Swift types.** `PersistenceController` (CloudKit variant), a small remote-change
observer that tells `PlantListViewModel` to reload on
`.NSPersistentStoreRemoteChange`.

**Tests.** Unit tests continue to run against the **local in-memory** container only —
CloudKit is not unit tested. Add a test asserting that the test configuration never enables
CloudKit (guards against accidental network use in CI).

**Manual Xcode work.**
* ⚙️ Signing & Capabilities → add **iCloud** → check **CloudKit** → create container
  `iCloud.com.rahulsinghvi.HelloPlant`.
* ⚙️ Add **Background Modes** → **Remote notifications**.
* ⚙️ Confirm `HelloPlant.entitlements` is attached to the app target only.
* 🍎 Run once on a real device signed into iCloud, then use Xcode's
  `initializeCloudKitSchema(options:)` (temporary debug-only call) or a development run to
  push the schema, and verify entities appear in CloudKit Console (Development environment).
* 📱 Requires at least one real device signed into iCloud (simulator sync is unreliable).

**Completion criteria.**
Schema visible in CloudKit Console; records created on device A appear on device B under the
same Apple ID; app still works with iCloud signed out (local-only, no crash).

**Copilot prompt.**
> Upgrade HelloPlant's `PersistenceController` to Phase 4 iCloud sync. Replace
> `NSPersistentContainer` with `NSPersistentCloudKitContainer`. Configure the private store
> description with `NSPersistentHistoryTrackingKey` and
> `NSPersistentStoreRemoteChangeNotificationPostOptionKey` set to true, and
> `NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.rahulsinghvi.HelloPlant")`
> with `databaseScope = .private`. Keep the `inMemory` test path completely free of CloudKit
> options. Set the view context to `automaticallyMergesChangesFromParent = true` and
> `NSMergeByPropertyObjectTrumpMergePolicy`. Add an observer of `.NSPersistentStoreRemoteChange`
> that asks the repository to reload so `PlantListViewModel` refreshes. Do not change the schema
> or the domain layer, and do not add UI in this phase.

---

### Phase 5 — Share the Home with another iCloud user

**Objective.** Let one household member share the single Home object; all plants and events
inside it follow automatically.

**User-visible result.** A share button in the plant list opens the standard iOS sharing
sheet ("Add People"), producing an invitation link to send by Messages.

**Files to create or modify.**
* Modify: `Persistence/PersistenceController.swift` → add a **second** store description with
  `databaseScope = .shared` (both stores in the `Default` configuration).
* Create: `Sharing/ShareCoordinator.swift`, `Sharing/CloudSharingView.swift`
* Modify: `Views/PlantListView.swift` (toolbar share button),
  `ViewModels/PlantListViewModel.swift` (share state, participant list)

**Main Swift types.**
```swift
final class ShareCoordinator {                 // only file that imports CloudKit
    func existingShare(forHome: NSManagedObjectID) -> CKShare?
    func makeShare(forHome: NSManagedObjectID) async throws -> (CKShare, CKContainer)
    func participants(for share: CKShare) -> [String]
}
struct CloudSharingView: UIViewControllerRepresentable { /* wraps UICloudSharingController */ }
```
Sharing always targets the **Home** object only — never an individual plant.

**Tests.** No unit tests for CloudKit. Add a unit test that the share entry point is
disabled/hidden when no Home exists, using a fake coordinator protocol.

**Manual Xcode work.**
* ⚙️ Ensure the CloudKit container has both private and shared scope usage (automatic once
  `CKShare` is created).
* 🍎 Build and run on a real device; open the share sheet.
* 📱📱 Two iPhones with different iCloud accounts are needed to actually send the invitation.

**Completion criteria.**
`UICloudSharingController` presents with the Home's name; a share link can be sent; the
`CKShare` record is visible in CloudKit Console; the second store description loads without
error at launch.

**Copilot prompt.**
> Add Phase 5 Home sharing to HelloPlant. In `PersistenceController`, add a second
> `NSPersistentStoreDescription` pointing at a separate `.sqlite` file in the same directory,
> using the same `Default` configuration, with `NSPersistentCloudKitContainerOptions` whose
> `databaseScope` is `.shared`, and enable history tracking and remote change notifications on
> both stores. Create `Sharing/ShareCoordinator.swift` as the only type importing CloudKit: it
> looks up an existing `CKShare` for the Home's `NSManagedObjectID` via
> `persistentContainer.fetchShares(matching:)`, and otherwise creates one with
> `persistentContainer.share([home], to: nil)`, setting the share title to the home name. Create
> `Sharing/CloudSharingView.swift`, a `UIViewControllerRepresentable` wrapping
> `UICloudSharingController` with `.allowReadWrite` and `.allowPrivate` permissions. Add a share
> toolbar button to `PlantListView` that presents it. Only the Home object is ever shared, never
> individual plants. Views must still not import CloudKit or CoreData.

---

### Phase 6 — Invitation acceptance

**Objective.** Make the invited person's app accept the share and show the shared Home.

**User-visible result.** The invited person taps the link, the app opens, and the same plant
list appears. Both people can add plants and record waterings.

**Files to create or modify.**
* Create: `App/AppDelegate.swift`, `App/SceneDelegate.swift`
* Modify: `App/HelloPlantApp.swift` (`@UIApplicationDelegateAdaptor`)
* Modify: `Repository/CoreDataPlantRepository.swift` — resolve the Home from **either** the
  private or the shared store; if a shared Home exists, prefer it and do not create a local
  duplicate.
* Modify: `PlantListView` — show participants and, for a participant, "Stop using shared
  plants" instead of "Share".

**Main Swift types.** `SceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)` calling
`persistentContainer.acceptShareInvitations(from:into:)` against the shared store; a
`HomeResolver` helper in the repository.

**Tests.** Unit test the Home resolution rule with a seeded in-memory context: when both a
local Home and a shared Home exist, the shared one wins and the local one is not shown twice.

**Manual Xcode work.**
* ⚙️ Confirm the app has a scene delegate class configured through
  `application(_:configurationForConnecting:options:)`.
* 📱📱 **Two physical iPhones with different iCloud accounts are mandatory here** — invitation
  acceptance cannot be tested in the simulator or with one account.

**Completion criteria.**
Person B accepts and sees Person A's plants; B's watering event appears on A's phone with B's
display name; neither phone shows duplicate homes.

**Copilot prompt.**
> Add Phase 6 CloudKit share acceptance to HelloPlant. Create `AppDelegate` and `SceneDelegate`
> classes, wire them with `@UIApplicationDelegateAdaptor` in `HelloPlantApp`, and implement
> `windowScene(_:userDidAcceptCloudKitShareWith:)` to call
> `persistentContainer.acceptShareInvitations(from:into:)` targeting the shared persistent store,
> then post a notification so the plant list reloads. Update `CoreDataPlantRepository` so that
> home resolution checks the shared store first and only creates a new Home in the private store
> when neither a shared nor a private Home exists, guaranteeing exactly one visible Home. Update
> `PlantListView` to show participant display names and to offer "Stop using shared plants"
> instead of "Share" when the current user is a participant rather than the owner. Add a unit test
> for the home-resolution precedence rule using an in-memory context.

---

### Phase 7 — Offline behaviour and synchronization testing

**Objective.** Guarantee the app is fully usable offline and converges correctly afterwards.

**User-visible result.** In Airplane Mode the app opens instantly, plants are listed, and
**Watered Now** works. When connectivity returns, both phones converge without losing events.

**Files to create or modify.**
* Modify: `PlantListViewModel` / `PlantListView` — a subtle "Syncing…" / "Up to date" hint and
  a non-blocking error state; never block the water action on network.
* Modify: `CoreDataPlantRepository` — ensure saves never wait on CloudKit.
* Possibly modify: `PersistenceController` — event-observing for
  `NSPersistentCloudKitContainer.eventChangedNotification`.

**Main Swift types.** `SyncStatusObserver` (small, in `Persistence/`), exposed to the view
model as a plain enum, not a CloudKit type.

**Tests.** Unit tests for the sync-status enum mapping (import/export started/succeeded/failed
→ idle/syncing/error). Conflict behaviour is verified manually.

**Manual Xcode work / device testing.**
* 📱📱 Airplane Mode on both phones, water the same plant on each, restore connectivity, and
  confirm **both** events exist (append-only model must not lose either).
* 📱📱 Confirm undo performed offline still removes only the local event after sync.
* 🍎 Force-quit and relaunch during sync; verify no duplicate Home.

**Completion criteria.**
No data loss in any of the offline scenarios; the app never blocks on the network; conflicting
simultaneous waterings both survive as separate events.

**Copilot prompt.**
> Add Phase 7 offline resilience to HelloPlant. Add a `SyncStatusObserver` in `Persistence/` that
> listens to `NSPersistentCloudKitContainer.eventChangedNotification` and maps setup/import/export
> events to a plain `SyncStatus` enum (`idle`, `syncing`, `error(String)`) with no CloudKit types
> in its public surface. Expose it through `PlantListViewModel` and show an unobtrusive status
> line in `PlantListView`. Ensure `CoreDataPlantRepository` saves complete locally without waiting
> for CloudKit and that "Watered Now" is never disabled by network state. Add Swift Testing cases
> covering the event-to-status mapping and that recording a watering succeeds when sync reports an
> error.

---

### Phase 8 — Accessibility and production readiness

**Objective.** Make the one-tap flow usable for everyone and ready for release.

**User-visible result.** VoiceOver reads "Monstera, last watered two days ago by Alex" and the
button as "Watered Now, button". Dynamic Type up to accessibility sizes does not clip. Works in
light and dark mode.

**Files to create or modify.**
* Modify: all views — `accessibilityLabel`, `accessibilityValue`, `accessibilityHint`,
  minimum 44×44pt targets, `.dynamicTypeSize` friendly layouts (`ViewThatFits` where needed).
* Modify: `Support/RelativeDateText.swift` — spoken-friendly full sentence label.
* Create: `HelloPlant/Localizable.xcstrings` (English only, but no hard-coded strings in views).
* Modify: `Assets.xcassets` — real AppIcon.

**Main Swift types.** No new types; view refinements only.

**Tests.** Unit tests for the accessibility label builder (never-watered, just-now, days-ago,
other-person cases).

**Manual Xcode work.**
* 🍎 VoiceOver pass on device, Dynamic Type XXXL pass, dark mode pass.
* ⚙️ Set app display name, icon, version 1.0/build 1, and confirm no unused capabilities.
* ⚙️ Archive build validates with the correct entitlements.

**Completion criteria.**
Full VoiceOver walkthrough of onboarding → list → water → undo → detail; no clipped text at
the largest Dynamic Type size; archive validates; all unit tests green.

**Copilot prompt.**
> Add Phase 8 accessibility polish to HelloPlant. Give every plant row a combined accessibility
> element with a label like "Monstera, last watered two days ago by Alex" or "Monstera, never
> watered", and give the Watered Now button an explicit label and hint. Extract the spoken string
> building into `RelativeDateText.swift` as a pure function and unit test it for never-watered,
> just-now, hours-ago, days-ago and other-person cases. Ensure all tap targets are at least 44 by
> 44 points, replace fixed-height rows with Dynamic-Type-friendly layouts, verify dark mode
> colours, and move all user-facing strings into a `Localizable.xcstrings` catalog with English
> values. Do not add any new features.

---

## Split of responsibility

**Can be fully prepared in VS Code (Windows) — written, not compiled:**
all Swift sources, the `.xcdatamodeld/contents` XML, unit test files, the string catalog.

**Must be compiled and run in Xcode on a Mac:**
every phase's build, every unit test run, model-editor verification, all simulator checks.

**Manual Xcode / Apple Developer configuration (cannot be scripted from here):**
deployment target change to 17.4, iCloud + CloudKit capability and container creation,
Background Modes → Remote notifications, entitlements file, CloudKit schema initialization and
Development→Production schema deploy, app icon, signing.

**Requires two physical iPhones with different iCloud accounts:**
Phase 5 invitation sending, Phase 6 invitation acceptance and two-way editing, Phase 7 offline
conflict convergence, and the "both phones" checks in the testing checklist. This cannot be
done in the simulator or with a single Apple ID.

---

## 3. Testing checklist

**Automated (unit, Mac, no network)**
- [ ] Status of a plant with no events is "never watered"
- [ ] Newest `wateredAt` wins regardless of insertion order
- [ ] Two taps create two events with distinct UUIDs
- [ ] Undo removes only the last local event; second undo is a no-op
- [ ] Undo rejects an id that was not created by the last local tap
- [ ] Archive hides the plant but preserves its history
- [ ] Rename preserves id and events
- [ ] Core Data repository creates exactly one Home on first launch
- [ ] Shared Home takes precedence over a private Home
- [ ] Sync event → `SyncStatus` mapping
- [ ] Accessibility label builder output for all status cases
- [ ] `PlantAccent` mapping is deterministic and falls back safely for nil/unknown icons
- [ ] Test configuration never enables CloudKit

**Manual — single device / simulator**
- [ ] First launch asks for a display name exactly once
- [ ] Add, rename, archive plants
- [ ] Watering history lists newest first with time and person
- [ ] Data survives force-quit and relaunch
- [ ] App works with iCloud signed out (local only, no crash)
- [ ] VoiceOver, Dynamic Type XXXL, dark mode

**Manual — two iPhones, two different iCloud accounts (📱📱)**
- [ ] A shares the Home; B receives and accepts the invitation
- [ ] B sees all of A's plants and history
- [ ] B waters a plant; A sees it with B's display name
- [ ] A adds a plant; B sees it
- [ ] Both offline, both water the same plant, then reconnect → both events survive
- [ ] Undo made offline syncs correctly and removes only that one event
- [ ] Archiving on one phone reflects on the other
- [ ] No duplicate Home appears on either phone

---

## 4. Version 1 definition of done

1. Onboarding captures a display name once; it is stored locally and never synced.
2. A household has exactly one Home; sharing it once shares every plant and event.
3. Plants can be added, renamed and archived; archived plants leave the main list.
4. Each row shows when the plant was last watered and by whom, derived only from
   `WateringEvent` records — no `lastWateredAt` is stored anywhere.
5. One tap on **Watered Now** creates a new `WateringEvent` with a fresh UUID.
6. Undo removes only the event created by the latest local action.
7. Full watering history is visible per plant.
8. The app is fully usable offline; changes sync when connectivity returns.
9. Two iPhones with different iCloud accounts see each other's plants and watering events.
10. All unit tests pass on a Mac; the full two-device manual checklist passes.
11. Architecture holds: Views → View Models → Repository → Core Data → CloudKit, with no
    CoreData/CloudKit imports in views and no third-party packages.
12. None of the excluded features (gardens, rooms, reminders, schedules, notifications,
    care advice, AI, recognition, photos, accounts, external backend, ads, analytics,
    payments) are present.
13. The shipped UI matches the agreed prototype in section 0: warm cream/sage botanical styling,
    per-plant accent cards with SF Symbol icons, person chips for who watered, droplet +
    "Water" pill with the "Watered Now" accessibility label, no status-derived colour anywhere,
    never-watered-first ordering, and a ~6 second undo banner that does not reorder the list
    while visible.
14. `Plant.iconName` is the only field added beyond the original brief; the accent colour is
    derived from it and is not stored.

---

## 4a. Step-by-step guide: testing on a Mac

Everything below happens on the Mac, in Xcode. Nothing here can be scripted from Windows.

> **Apple Developer Program requirement.** CloudKit sync and Home sharing (Phases 4-6:
> `NSPersistentCloudKitContainer` mirroring, `ShareCoordinator`, share-acceptance) need the
> **iCloud** and **Push Notifications** capabilities. Apple does not allow a free "Personal
> Team" account to provision either capability — only a paid **Apple Developer Program**
> membership ($99/year) can. If you only have a free/personal Apple ID, Xcode will fail to
> create a provisioning profile the moment those capabilities are attached to the target.
>
> **You can still test everything else on the Mac without paying.** `PersistenceController`
> has a `static let isCloudSyncAvailable = false` flag (in
> `HelloPlant/Persistence/PersistenceController.swift`). While it is `false`, the app loads a
> single local SQLite store with no CloudKit involvement at all, so it builds, signs, and runs
> under a free Personal Team. Remove the **iCloud** and **Push Notifications** capabilities in
> **Signing & Capabilities** to match (see step 4 below), then run through sections A-D and the
> **single-device** checklist in section 3 — everything except syncing/sharing across devices
> is fully testable this way. Skip section E (two-device sharing) and the CloudKit schema step
> (13) until you enroll. Once enrolled, re-add both capabilities, flip the flag to `true`, and
> resume from step 13.

### A. One-time setup

1. Copy or `git clone` this repository onto the Mac (or `git pull` if it already exists there).
2. Install **Xcode 16 or newer** from the App Store (required for `objectVersion = 77`).
3. Open `HelloPlant.xcodeproj` (double-click, or `open HelloPlant.xcodeproj` in Terminal).
4. In the Project Navigator, select the **HelloPlant** project → target **HelloPlant** →
   **Signing & Capabilities**.
   * Set **Team** to the Apple Developer account that owns `9GLZK7V7CD` (or switch to your
     own team if this is a personal account — Xcode will rewrite the bundle ID/team pairing).
   * Confirm **Automatically manage signing** is checked.
   * **With a paid Apple Developer Program account:** confirm an **iCloud** capability is
     present with **CloudKit** checked and container `iCloud.com.rahulsinghvi.HelloPlant`
     selected (create it here if it's missing — Xcode will register it in your developer
     account), and confirm **Background Modes** → **Remote notifications** is checked (needed
     for CloudKit push updates).
   * **With only a free Personal Team account:** remove the **iCloud** and **Push
     Notifications** capability cards entirely (click the "x" on each) and leave
     `PersistenceController.isCloudSyncAvailable` set to `false`. Signing will succeed and the
     app runs on a local-only store; revisit this step once you enroll in the paid program.
5. Repeat the Team check for the `HelloPlantTests` and `HelloPlantUITests` targets.

### B. Build and open the data model

6. Select `Persistence/HelloPlant.xcdatamodeld` in the navigator. Xcode's model editor should
   open the hand-written entities (`CDHome`, `CDPlant`, `CDWateringEvent`) without errors or
   warnings. Fix anything Xcode flags before continuing — do not hand-edit around a model
   error.
7. Build the app: **Product → Build** (`⌘B`). Fix any compile errors — this is the first real
   compile of this code, so budget time for Swift/SwiftUI issues that can't be caught outside
   Xcode.

### C. Run the automated unit tests

8. Select the **HelloPlant** scheme, choose any iPhone 17.4+ simulator, then
   **Product → Test** (`⌘U`).
9. Confirm all `HelloPlantTests` (Swift Testing) cases pass, including:
   * `InMemoryPlantRepositoryTests`, `PlantStatusTests`, `PlantListViewModelTests`,
     `PlantAccentTests`, `SyncStatusTests`.
   * `CoreDataPlantRepositoryTests` — these exercise Core Data against an in-memory store
     (`/dev/null`) with CloudKit disabled, so they should be network-free and fast.
10. `HelloPlantUITests` are the stock template tests; run them too but they are not part of
    the Version 1 checklist.

### D. Manual single-device pass (simulator or one iPhone)

11. Run the app (`⌘R`) on a simulator or a real device.
12. Walk the **Manual — single device / simulator** checklist in section 3 above: onboarding
    name capture, add/rename/archive plants, Watered Now + Undo, history ordering, force-quit
    and relaunch (data persists), iCloud signed out (still works, no crash), VoiceOver,
    Dynamic Type XXXL, dark mode.
13. **Requires a paid Apple Developer Program account and the iCloud/Push capabilities
    re-enabled with `isCloudSyncAvailable = true`.** Push the CloudKit schema once, from a
    device signed into iCloud: either call
    `container.initializeCloudKitSchema()` temporarily (debug-only) or just run the app once
    with a real device/iCloud account so the container mirrors and creates the schema
    automatically. Then check **CloudKit Console** (developer.apple.com → your container →
    Development environment) and confirm `CDHome`, `CDPlant`, `CDWateringEvent` record types
    exist.

### E. Manual two-device pass (sharing and sync)

> Requires the paid Apple Developer Program account and `isCloudSyncAvailable = true` (see
> the note at the top of this section). Skip this whole section on a free Personal Team.

14. You need **two physical iPhones signed into two different iCloud accounts** (simulators
    cannot reliably test CloudKit sharing).
15. Install the app on both devices (TestFlight, or a direct Xcode run to each device).
16. On device A: open **Share Home**, send an invite (Messages/Mail/link) to the iCloud
    account used on device B.
17. On device B: accept the invitation. This should trigger
    `SceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)` and populate the shared
    store.
18. Walk the **Manual — two iPhones** checklist in section 3: B sees A's plants/history, B
    waters a plant and A sees B's name, A adds a plant and B sees it, both devices go offline
    and water the same plant then reconnect (both events survive), an offline undo syncs
    correctly, archiving on one phone reflects on the other, no duplicate Home appears.

### F. Wrap-up

19. Fix any bugs found above directly in Xcode (or send the details back for a Windows-side
    patch), then re-run the affected steps — do not skip re-testing after a fix.
20. Once every box in section 3 and every item in section 4 is checked, Version 1 is
    functionally complete and ready to move to launch preparation (section 4b).

---

## 4b. Next steps after testing: launching the app

Once all testing above passes, these are the remaining steps to ship HelloPlant, roughly in
order:

1. **Promote the CloudKit schema to Production.** In CloudKit Console, use **Deploy Schema
   Changes** to push the Development schema to the Production environment. Do this only after
   the model is final — Production schema is append-only (see Notes and risks).
2. **Switch build configuration to Release** and re-run the full manual checklist once against
   Release (Debug and Release can behave differently, especially around CloudKit timing).
3. **App icon and launch assets.** Confirm `AppIcon.appiconset` is complete for all required
   sizes (already present) and that `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` are set
   correctly for the first submission (currently `1.0` / `1`).
4. **App Store Connect setup.**
   * Create the app record (bundle ID `com.rahulsinghvi.HelloPlant`).
   * Fill in app name, description, category, privacy policy URL, and support URL.
   * Complete the **App Privacy** questionnaire — note that this app collects a device-local
     display name (not synced, not linked to identity beyond CloudKit's own account handling)
     and syncs plant/watering data via the user's private/shared iCloud database.
   * Add screenshots for required device sizes (can be generated from the simulator once the
     UI is final).
5. **TestFlight beta (recommended before public release).** Archive the app
   (**Product → Archive**), upload via Xcode Organizer, and invite a small group — ideally
   including the two-device household you tested with — to confirm real-world sharing works
   outside your development devices.
6. **Final review against section 4's definition of done** — re-confirm items 1–14 with fresh
   eyes, especially item 12 (no excluded features slipped in) and item 13 (UI matches the
   agreed prototype).
7. **Submit for App Review.** Provide review notes explaining the iCloud sharing flow, since
   reviewers may only have one Apple ID and can't fully exercise multi-user sharing — clarify
   that single-device use (add plants, water, undo) is fully functional without a second
   account.
8. **Post-approval.** Release manually or with phased release; monitor CloudKit Console for
   unexpected record volumes/errors and Xcode Organizer/App Store Connect for crash reports in
   the first few days.

---

## 5. First implementation prompt

Use this as the very first Copilot prompt (Phase 1):

> Create the Phase 1 in-memory prototype for the iOS app HelloPlant using Swift 5, SwiftUI and
> the Observation framework, deployment target iOS 17.4. The app lets housemates see when each
> home plant was last watered and by whom, and record a watering with one tap.
>
> 1. In `HelloPlant/Models/`, add value types `Home` (id, name, createdAt), `Plant` (id, name,
>    createdAt, archivedAt, iconName), `WateringEvent` (id, wateredAt, wateredBy, createdAt,
>    plantID), `LocalProfile` (displayName, installationIdentifier) and `PlantStatus`, which
>    derives the latest watering from an array of events. Never introduce a stored
>    `lastWateredAt`.
> 2. In `HelloPlant/Theme/`, add `Palette.swift` (cream `#FDFAF3`, sage wash, leaf green
>    `#3E9B54`/`#2A7340`, and six plant accents: leaf, terracotta, sun, sky, lilac, rose),
>    `PlantIcon.swift` listing about six preset SF Symbols for plants, and `PlantAccent.swift`
>    with a pure deterministic function mapping an optional `iconName` to an accent, falling
>    back to the leaf accent.
> 3. In `HelloPlant/Repository/`, define a `PlantRepository` protocol with async throwing
>    methods `home()`, `plantStatuses(includeArchived:)`, `addPlant(named:iconName:)`,
>    `recordWatering(plantID:by:at:)` and `undoWatering(eventID:)`, and implement
>    `InMemoryPlantRepository` as an actor seeded with three sample plants using different icons.
> 4. In `HelloPlant/Support/`, add `LocalProfileStore` persisting the display name and a
>    generated installation UUID in `UserDefaults`, and `RelativeDateText` producing strings
>    like "Never watered", "Just now", "Today 08:15", "2 days ago".
> 5. In `HelloPlant/ViewModels/`, add `@Observable` `OnboardingViewModel` and
>    `PlantListViewModel`; the latter loads statuses, records waterings, and remembers the id of
>    the last locally created event in memory only.
> 6. In `HelloPlant/Views/`, add `RootView` (shows onboarding until a display name exists, then
>    the list), `OnboardingView`, `PlantListView`, `HomeHeaderView`, `PlantCardView`,
>    `PersonChip` and `UndoBanner`. Use a warm cream background with a soft sage gradient wash.
>    `HomeHeaderView` shows an "OUR HOME" eyebrow, a time-based greeting such as
>    "Good morning, Alex", a factual summary line, and overlapping participant avatars.
>    `PlantCardView` is a rounded 20 pt white card with a 5 pt accent spine, a faint accent
>    tint, a gradient tile containing the plant's SF Symbol, the plant name, the relative status
>    (for example "2 days ago", "Never watered"), a `PersonChip` showing who watered it, and a
>    green gradient pill containing a droplet and the word "Water". Give that pill the
>    accessibility label "Watered Now" and make the card a single combined accessibility element
>    reading "Monstera, last watered two days ago by Sam". Accent colours express plant identity
>    only — never colour anything by watering recency and never imply a schedule. Sort
>    never-watered plants to the top, then by oldest last-watering first.
> 7. Show an `UndoBanner` for about six seconds after a local tap, naming the plant and offering
>    Undo; give the watered card a green wash and a "✓ Watered" state, keep it in its current
>    position while the banner is visible, and re-sort only after it disappears.
> 8. In `HelloPlant/App/`, add `AppEnvironment` as the composition root and update
>    `HelloPlantApp.swift` to inject it; delete `ContentView.swift`.
> 9. In `HelloPlantTests/`, add Swift Testing tests for status derivation with out-of-order
>    events, two taps creating two distinct event UUIDs, the sort order rule, the
>    `PlantAccent` mapping including its fallback, and the view model refreshing after a
>    watering.
>
> Constraints: no CoreData, no CloudKit, no third-party packages, no networking, and no
> reminders, schedules, notifications, photos or plant groups. Views must depend only on view
> models and domain types.

---

## Notes and risks

* **CloudKit schema is append-only in Production.** Get the Phase 3 model right before the
  Phase 4 schema push; adding attributes later is fine, renaming/removing is not.
* **Two-store setup is the main source of Phase 5/6 bugs.** Both stores must use the same
  model configuration and both need history tracking enabled, or share acceptance fails
  silently.
* **`wateredBy` is a name snapshot.** If someone renames themselves, past events keep the old
  name. This is intentional and keeps V1 free of user records.
* **Undo is deliberately narrow** (last local action only) so it can never race with a
  household member's event arriving through sync.
* **Simulator limits.** CloudKit sync and share acceptance need real devices; plan device
  access before Phases 5–7.
* Existing `HelloPlantUITests` target stays in place but is not extended (per the tests
  decision); leave the generated launch test so the target keeps compiling.
