# InvoiceManager — iOS Midterm Project

A small invoicing app for a solo accounting practice: manage clients, issue
invoices with line items, and see what is still owed. Built with Swift,
SwiftUI and Xcode, organised with the Model–View–Controller pattern.

---

## 1. Setting it up in Xcode

1. **File ▸ New ▸ Project… ▸ iOS ▸ App**
2. Product Name: `InvoiceManager` · Interface: **SwiftUI** · Language: **Swift**
3. Set the **Minimum Deployment** target to **iOS 17.0** (Project ▸ General).
4. In the new project, **delete** the generated `ContentView.swift` **and**
   `InvoiceManagerApp.swift` (move to Trash).
5. Drag the `Models`, `Controllers`, `Views` and `Support` folders plus
   `InvoiceManagerApp.swift` from this package into the Xcode navigator.
   Tick **Copy items if needed** and **Create groups**.
6. Build and run (⌘R).

If your project has a different name, only the `struct InvoiceManagerApp`
line needs to change — nothing else references the project name.

---

## 2. Folder structure

```
InvoiceManager/
├── InvoiceManagerApp.swift        App entry point; creates the controller
├── Models/                        Data only — no SwiftUI imports
│   ├── Client.swift
│   ├── Invoice.swift
│   ├── InvoiceStatus.swift
│   ├── LineItem.swift
│   └── SampleData.swift
├── Controllers/                   All logic and all mutations
│   ├── InvoiceStore.swift         Owns the data, exposes queries + actions
│   └── TotalsCalculator.swift     Subtotal / VAT / total arithmetic
├── Views/
│   ├── RootTabView.swift          Tab bar container
│   ├── Overview/OverviewView.swift
│   ├── Invoices/
│   │   ├── InvoiceListView.swift
│   │   ├── InvoiceDetailView.swift
│   │   └── InvoiceFormView.swift
│   ├── Clients/
│   │   ├── ClientListView.swift
│   │   ├── ClientDetailView.swift
│   │   └── ClientFormView.swift
│   └── Components/                Small reusable views
│       ├── StatusBadgeView.swift
│       ├── InvoiceRowView.swift
│       ├── ClientRowView.swift
│       ├── SummaryTileView.swift
│       └── LineItemEditorRow.swift
└── Support/
    ├── AppConfiguration.swift     Currency code, VAT rate, payment terms
    └── Decimal+Currency.swift     Shared money / date formatting
```

---

## 3. How MVC is applied

| Layer | Files | Responsibility |
|---|---|---|
| **Model** | `Client`, `Invoice`, `LineItem`, `InvoiceStatus` | Plain `struct`/`enum` types holding data and validation rules. They import `Foundation` only — deliberately no `SwiftUI`, so a status never knows what colour it is drawn in. |
| **Controller** | `InvoiceStore`, `TotalsCalculator` | `InvoiceStore` is an `ObservableObject` that owns the two arrays. They are `@Published private(set)`, so a view can read them but can only change them by calling a method. `TotalsCalculator` holds every peso computation in one place. |
| **View** | Everything in `Views/` | Displays state and forwards user intent to the controller. No view performs money arithmetic or edits stored data directly. |

The controller is created once in `InvoiceManagerApp` and passed down with
`.environmentObject(...)`, so all screens read from a single source of truth.

Detail screens store only an **ID** (`InvoiceDetailView(invoiceID:)`) and look
the record up in the controller each time the body runs. That is why editing an
invoice on the detail screen instantly updates the list and the overview.

---

## 4. Screens and navigation

| # | Screen | Reached by |
|---|---|---|
| 1 | **Overview** — outstanding vs collected, counts by status, recent invoices | Tab 1 |
| 2 | **Invoice List** — filter by status, search, swipe to delete | Tab 2 |
| 3 | **Invoice Detail** — line items, computed totals, status control | Push from list, overview, or client detail |
| 4 | **Invoice Form** — create/edit with live totals | Modal sheet from list (+) or detail (Edit) |
| 5 | **Client List** — search, swipe to delete | Tab 3 |
| 6 | **Client Detail** — contact info, billing summary, their invoices | Push from client list or invoice detail |
| 7 | **Client Form** — create/edit | Modal sheet |

Three navigation styles are demonstrated: `TabView` (tabs),
`NavigationStack` + `NavigationLink` (push), and `.sheet` (modal).

---

## 5. Midterm progress — what works today

**Done (well past the 50% requirement)**

- [x] All 7 screens laid out and navigable
- [x] Full create / read / update / delete for clients
- [x] Full create / read / update / delete for invoices
- [x] Line item editor with add, delete and live per-row amounts
- [x] Subtotal, VAT and total computed correctly with `Decimal`
- [x] Status filtering, search, and overdue detection
- [x] Overview dashboard driven by real data
- [x] Auto-generated invoice numbers (`INV-2026-004`)
- [x] Deleting a client cascades to their invoices
- [x] Save buttons disabled until the form is valid
- [x] Xcode previews on every view

**Planned for the final submission**

- [ ] Persistence — encode to JSON and store in `UserDefaults` or a file, so
      data survives relaunch (models are already `Codable`)
- [ ] PDF export and a share sheet for sending an invoice
- [ ] Payment records, so an invoice can be partially paid
- [ ] Charts screen — monthly billings using Swift Charts
- [ ] Light/dark theme polish and an app icon
- [ ] Unit tests for `TotalsCalculator`

---

## 6. Conventions used

- One `View` struct per file; the filename matches the struct name.
- `// MARK: -` dividers separate sections inside longer files.
- Types are `UpperCamelCase`, properties and methods `lowerCamelCase`.
- View state is `private @State`; controller access is
  `private @EnvironmentObject`.
- Money is `Decimal` (never `Double`) and is rounded through one function.
- Forms edit a local `draft` copy and only commit on **Save**, so **Cancel**
  really cancels.
