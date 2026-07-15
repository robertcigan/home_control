# Test Coverage & Test Plan for the Hotwire Migration

Companion to [APP_BEHAVIOR.md](APP_BEHAVIOR.md). Maps what is covered today, what is
not, and which tests should be **added before** the jQuery/AJAX → Stimulus/Hotwire
migration so the migration has a safety net. This is a plan only — no tests are added
by this document.

Test stack: RSpec + FactoryBot + shoulda-matchers + Capybara/Cuprite (headless Chrome)
+ database_cleaner + timecop. The `test/` (Minitest) directory contains only generated
stubs and is unused — consider deleting it to avoid confusion.

---

## 1. Current Coverage

### 1.1 Model specs (good coverage)

| Area | File(s) | State |
|---|---|---|
| Board — validations, scopes, `connected?`, `parse` (pong/send_devices/device), cable sends (`send_to_arduino/modbus` broadcasts), pins, modbus read/write blocks, `clear_logs`, `log_board_log`, chart data | `spec/models/board_spec.rb` (466 lines) | ✅ thorough |
| Device (base) — validations, scopes, `json_data`, predicates, `trigger_programs`, `detect_hw_change`, `detect_log_enabled_change`, `clear_logs`, `reset_pins` | `spec/models/device_spec.rb` (422 lines) | ✅ thorough |
| All 14 device subtypes — `set`, value mapping, `setup_pin` payloads, `readable?/writable?/toggle?`, logging, trigger side effects | `spec/models/device/*_spec.rb` | ✅ thorough |
| Program — validations, scopes incl. `repeated_to_run`, `run` (success/error/output), `thread_utilisation`, storage, `precompile_code`, `json_data` | `spec/models/program_spec.rb` | ✅ good |
| BoardLog / DeviceLog — chart data, indication, scopes | `spec/models/*_log_spec.rb` | ✅ good |
| Panel, Widget, ProgramsDevice, Ability | small specs | ✅ adequate |

### 1.2 Feature specs (Cuprite, `js: true`)

| Area | File | Covered scenarios |
|---|---|---|
| Boards | `boards_spec.rb` | index list + filter + pagination, create (all 3 types) via modal incl. dynamic modbus fields, validation errors, edit, delete, show (all types) |
| Board logs | `board_logs_spec.rb` | chart render + timespan tabs + day/hour prev-next navigation, log table filter/pagination/sort without reload |
| Devices | `devices_spec.rb` (583 lines) | index filters (name/pin/type/board), create of every HW + virtual type via modal, edit (incl. modbus fields), delete, show, toggle via `set` buttons, toggle buttons hidden for non-toggle types |
| Programs | `programs_spec.rb` | index filter/sort/pagination, create with nested devices (cocoon), validation errors, edit, copy (amoeba), delete, enable/disable + run from show, run failure flash, **cable-pushed runtime updates** |
| Panels/Widgets | `panels_spec.rb` | index filter/pagination, create panel with nested widget, validation errors, edit, widget add/edit/remove via modal, dashboard rendering, **cable-driven widget updates**, **panel reload push** |
| Home | `home_page_spec.rb` | smoke test |

### 1.3 Not covered at all

- `LogCompression#run_compression` / `#compress_logs` — the most complex pure-logic
  code in the app (4 compression types × 5 timespans, backlog window math,
  `compression_last_run_at` advancement, replace_logs deletion). Only validations and
  the `for_compression` scope are tested.
- `WebsocketPushChange` concern in isolation (channel name derivation, broadcast on
  update-commit only).
- `lib/arduino_messenger.rb` — TCP framing (`process_buffer`: newline-delimited JSON,
  partial buffers, overflow reset, parse-error recovery), connect/reject logic
  (unknown IP, duplicate IP), disconnect cleanup.
- `lib/arduino_server.rb` — periodic jobs logic (at minimum `repeated_to_run`
  execution path is indirectly covered via Program scope spec).
- Helpers: `ProgramsHelper` (`time_between`, log methods), `ChartsHelper`
  (`chart_options` unit selection by timespan), `ApplicationHelper`
  (`refresh_list_by_script`, `show_flash` — will change during migration anyway).
- **No request specs at all.** Everything HTTP-level is only covered indirectly
  through feature specs (or not at all): `js.erb` vs HTML content types, `reload`
  round-trip semantics, per-page cookie, chart JSON endpoints (window padding logic),
  public-access rules for panels/widgets, backups download, logs controller.
- Channels: no subscription specs (`test/channels` is a stub).
- Sections with zero specs: Backups, server Logs, device-logs chart/table on device
  show (board_logs has specs; the device variant does not), widget `update_position`,
  Home page live behavior (currently disabled in JS anyway).

---

## 2. What to Add — Prioritized Plan

Guiding principle: the migration rewrites *views, js.erb responses and all frontend
JS*. Tests that assert **user-visible behavior through the browser** (feature specs)
survive the rewrite and act as the safety net. Tests binding to `js.erb`/jQuery
internals would be throwaway — don't write those. Pure-logic unit tests (compression,
messenger framing) are migration-independent and protect against regressions while
touching neighboring code.

### Priority A — before starting the migration (safety net)

**A1. Device Logs feature spec** (`spec/features/device_logs_spec.rb`)
Mirror of `board_logs_spec.rb` on the device show page:
- chart renders for numeric / boolean / string devices (3 chart type variants),
- timespan tabs + prev/next navigation,
- log table filter + sort + pagination without page reload,
- chart/table hidden entirely when `log_enabled: false`.

**A2. Live-update feature specs for Boards and Devices**
Programs and Panels already assert cable-pushed DOM updates; Boards/Devices don't.
- boards index + show: broadcast `connected` change → icon class flips, ssid/signal
  text updates,
- devices index + show: value change → `.indication`/`.updated` cells update; toggle
  button pair flips only after the push (assert no optimistic flip),
- panel dashboard: text_value widget indication updates, switch widget flips
  (extend `panels_spec.rb` if more natural there).

**A3. Panel public access + widget endpoints** (feature or request level)
- `panels#show`: public panel renders without auth; non-public → no content
  (document/lock current behavior even if odd — in test env `authenticate` returns
  `nil`, so assert what production semantics should be via request spec with
  `ADMIN_*` config stubbed and `Rails.env.test?` bypass accounted for),
- widget switch `set` and button `run` on a public panel work; on a private panel
  without credentials do nothing,
- widget button run is silent (no flash), program `last_run` updates via cable.

**A4. Flash & confirm-modal behavior** (small feature spec)
These two global patterns get fully rewritten; pin them down:
- toast appears after create/update/delete (success + error variants),
- `data-confirm` opens the custom modal, Cancel aborts (record still exists),
  Confirm proceeds; confirm nested inside the AJAX modal (widget delete from layout
  editor) restores the underlying modal on cancel.

**A5. `reload` form round-trip** (feature, can extend existing CRUD specs)
Explicit assertions that switching `device_type`/`board_type`/`log_enabled` re-renders
the form **preserving already-entered values** and does not create a record. Exists
implicitly in some specs; make at least one explicit scenario per form (board, device,
program, panel widget fields).

**A6. Widget layout editor** (`spec/features/widget_layout_spec.rb`)
- editor renders grid with widgets at stored x/y/w/h,
- `update_position` request spec: PATCH updates coordinates and broadcasts panel
  reload (drag itself is impractical in Cuprite; cover the endpoint + the broadcast,
  optionally simulate by dispatching gridstack change via JS),
- open dashboard reloads when layout changes (already partially in `panels_spec.rb`;
  extend for `update_position`).

**A7. List-state request specs** (cheap, protocol-level)
- per-page cookie: `per` param persists per controller+action and is restored,
- `refresh_list_by_script` semantics replacement guard: after create/delete the list
  keeps current filters and page (feature-level assertion is fine too),
- chart JSON endpoints (`board_logs#chart.json`, `device_logs#chart.json`): series
  shape, window padding (value before `min` prepended, next/current appended),
  timespan defaults min/max computation (use timecop).

### Priority B — logic gaps independent of the migration

**B1. `LogCompression` unit spec** (`spec/models/concerns/log_compression_spec.rb`)
The biggest untested area. Matrix to cover with timecop:
- `run_compression` start-time derivation: nil `compression_last_run_at` (from first
  log, rounded per timespan: min1/min5/min10/hour/day) vs. subsequent runs
  (+1 timespan, rounded),
- backlog window: compression only runs when now − start > backlog × timespan,
- `compress_logs` for each type: `average`, `w_average` (incl. previous-window
  boundary value weighting), `end_value`, `max_value`; timestamps of created log
  (starts_at vs ends_at semantics differ per type),
- `replace_logs: true` deletes source rows, saves compressed row, advances
  `compression_last_run_at`; single-row window only advances the timestamp,
- devices with non-numeric values are excluded (`compressable?`).

**B2. `ArduinoMessenger#process_buffer` unit spec**
Instantiable without EventMachine reactor (call methods on an allocated instance with
stubbed board):
- complete line → parsed and routed to `Board#parse`,
- multiple JSONs in one packet; trailing partial JSON kept in buffer,
- invalid JSON → buffer reset, no crash,
- >10 MB buffer overflow reset,
- `post_init`/`unbind` connect & disconnect bookkeeping (known IP, unknown IP
  rejected, duplicate IP rejected) — with `get_peername` stubbed.

**B3. `WebsocketPushChange` concern spec**
- broadcasts on update commit only (not create/destroy),
- channel name derivation (`Device::Relay` → `devices`),
- payload equals `json_data`.
Use `have_broadcasted_to` (ActionCable test adapter is already configured).

**B4. Helper specs**
- `ProgramsHelper#time_between` (inside/outside range, boundary values),
- `ChartsHelper#chart_options` unit thresholds (second/minute/hour/day/month).

**B5. Channel subscription specs** (`spec/channels/`)
Trivial but pins the contract the automation process depends on: subscribing to each
channel streams from the expected literal stream name (`arduino`, `modbus`, `boards`,
`devices`, `panels`, `programs`). **These six names are an inter-process API** — a
failing spec on rename is exactly what you want during the Action Cable rework.

### Priority C — nice to have / cleanup

- **Backups**: request spec for `download` — unknown format → 400; success path with
  `pg_dump` stubbed (don't shell out in CI); failure path → flash + redirect.
- **Server logs pages**: request spec incl. the security property that
  `params[:file]` outside `log/*.log` is rejected (guards the `tail` shell-out).
- **Home page**: decide fate first (legacy Bootstrap 3 markup, disabled JS init);
  write specs only for whatever it becomes after the migration.
- Delete unused `test/` Minitest scaffolding and `welcome` controller/view (separate
  cleanup commit; adjust this plan if kept).

---

## 3. During / After the Migration

- Feature specs from section 1.2 + Priority A are the acceptance suite: they should
  pass unchanged (selectors used in them are semantic — table text, buttons, ids like
  `#devices` — keep those stable in new views).
- Expect to rewrite assertions that touch implementation details: Bootstrap modal
  classes (`#ajax-modal` visibility), `.pagination` data attributes, inline-script
  driven flashes. Where a spec asserts such an internal, prefer loosening it to the
  visible outcome *before* migrating.
- After moving live updates to Turbo Streams, replace payload-shape specs (B3) with
  `turbo_stream` broadcast assertions — but keep the `arduino`/`modbus` channel specs
  (B5) byte-for-byte.
- Add a smoke feature spec per migrated pattern as it lands (modal via Turbo Frame,
  list frame, toast, confirm dialog) — the pattern list in APP_BEHAVIOR.md §5 doubles
  as the checklist.

---

*Plan created 2026-07-13 against v3.4.6.*
