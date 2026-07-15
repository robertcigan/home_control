# Home Control — Application Behavior Documentation

Reference documentation of the current behavior, features and frontend patterns of the
application. Its purpose is to serve as the baseline for the planned frontend upgrade
from the legacy jQuery + AJAX (`js.erb`) + Turbolinks stack to Stimulus/Hotwire (Turbo
Drive / Frames / Streams) with Action Cable used through Turbo Streams. Every behavior
described here must either survive the migration unchanged (from the user's point of
view) or be consciously replaced.

Related docs: [README.md](../README.md) (HW & domain overview), [TEST_PLAN.md](TEST_PLAN.md)
(test coverage & plan).

---

## 1. Architecture Overview

### 1.1 Processes

| Process | What it runs | Entry point |
|---|---|---|
| **Web** | Rails 7.2 + Puma, serves HTML/JS/JSON and mounts Action Cable at `/websockets` | `config.ru` |
| **Automation** | Standalone EventMachine process. Runs a TCP server on port **7777** for Arduino boards, a Modbus TCP client, periodic timers (programs, log compression, pings…). Connects to the web process **as an Action Cable client** (`action_cable_client` gem) | `lib/arduino_server.rb` |

Action Cable is therefore used for two distinct purposes:

1. **Browser live updates** — channels `BoardChannel`, `DeviceChannel`, `ProgramChannel`,
   `PanelChannel` (streams `boards`, `devices`, `programs`, `panels`).
2. **Inter-process message bus** — channels `ArduinoChannel` (stream `arduino`) and
   `ModbusChannel` (stream `modbus`), consumed by the automation process, never by the
   browser.

> **Migration constraint:** purpose (2) must keep working exactly as-is. The automation
> process subscribes to `ArduinoChannel` / `ModbusChannel` by name and expects the raw
> JSON payloads produced by `Board#send_to_arduino` / `Board#send_to_modbus`. Turbo
> Streams may replace purpose (1) only. Do not rename channels/streams or change payload
> format for (2).

### 1.2 Data flow

```
Arduino/ESP board  --TCP:7777 JSON lines-->  ArduinoMessenger (EventMachine)
                                                  |  Board#parse -> Device#set -> save
                                                  v
                                             PostgreSQL
                                                  |
     Device/Board/Program/Panel after_commit(update) -> WebsocketPushChange
                                                  |
                                                  v
             ActionCable.server.broadcast("<devices|boards|programs|panels>", json_data)
                                                  |
                                                  v
     Browser channel subscription -> writes values into data-* attributes
                                  -> triggers jQuery custom events -> DOM update

Web UI (write path):  Rails controller -> model save -> after_commit detect_change
                      -> Board#send_to_board -> broadcast("arduino"|"modbus", …)
                      -> automation process -> TCP/Modbus to the physical board
```

### 1.3 Frontend stack (current)

- Sprockets asset pipeline, CoffeeScript, HAML views, `js.erb` AJAX responses.
- Turbolinks 5 (`turbolinks:load` hooks, `turbolinks-cache-control: no-cache` meta).
- jQuery + jquery_ujs (`remote: true`, `data-confirm`, `data-disable-with`, `data-method`).
- Bootstrap 4 (modals, collapse navbar), bootstrap-notify (flash toasts), animate.css.
- select2 (all selects), cocoon (nested forms), CodeMirror (Ruby editor),
  Chartkick + Chart.js (charts), gridstack (panel dashboards), jquery.debounce.
- Custom JS namespace `HomeControl.*` (`lib/assets/javascripts/namespace.coffee`), pages
  bootstrapped by inline `:javascript` blocks calling `HomeControl.<Section>.init*()`.
- Responders gem with a collection responder + custom `AjaxModalResponder`
  (`lib/responders/ajax_modal_responder.rb`).

### 1.4 Authentication & authorization

- Global HTTP Basic auth (`ApplicationController#authenticate`, credentials from
  `ADMIN_USERNAME` / `ADMIN_PASSWORD` env vars). **Skipped entirely in test env.**
- Exceptions to authentication:
  - `PanelsController#show` — skips the before_action; renders the panel when
    `panel.public_access?` **or** basic auth passes.
  - `Widgets::DevicesController#set` and `Widgets::ProgramsController#run` — same
    pattern; a public panel is fully operable without login.
- CanCanCan is present but `Ability` grants `can :manage, :all` — effectively single-user.
- Global rescues: `StaleObjectError` → flash + redirect (or `render_exception` for JS),
  `InvalidAuthenticityToken` → redirect to referer with "Please try again".

---

## 2. Global UI Patterns (the heart of the migration)

These patterns repeat across all sections. Migrating each pattern once and applying it
everywhere is most of the work.

### 2.1 AJAX modal CRUD (`#ajax-modal`)

The single generic Bootstrap modal in the layout (`common/ajax_modal/_ajax_modal`) is
used for **all** create/edit forms (boards, devices, programs, panels, widgets).

Flow:
1. Trigger link has `data-toggle="ajax-modal"`, plus `data-title` (modal title) and
   `data-class` (`modal-md`/`modal-lg`/`modal-sm` size).
2. `layout.coffee initAjaxModal` intercepts the click, sets the title/size and runs
   `$.getScript(href)` → `GET new.js` / `edit.js`.
3. The server responds through `AjaxModalResponder`: since no `new.js.erb`/`edit.js.erb`
   template exists, it renders `common/ajax_modal/form.js.erb`, which injects the
   `_form` partial into `#ajax-modal-content` (`ajax_modal_render` helper).
4. The form is `simple_form_for(..., remote: true)`; submit POSTs/PATCHes as JS.
5. `create.js.erb` / `update.js.erb` behavior:
   - **errors present or `@reload`** → re-render the form inside the modal
     (validation errors displayed via simple_form `error_notification`),
   - **success** → refresh the list via `refresh_list_by_script` (see 2.2), hide the
     modal, show flash toast.
6. On modal hide, its content is reset back to the loading spinner.
7. `ajaxmodalloaded` event fires on `#ajax-modal` after content injection (hook point).

### 2.2 Dynamic form reload (`data-reload`) — dependent fields

Form inputs that change the shape of the form carry `data: { reload: true }`
(e.g. `board_type`, `device_type`, `board_id`, `log_enabled`, `compression_type`,
`show_label`). `Layout.initReloadForm`:

1. On change, appends `<input type=hidden name=reload value=1>` and submits the form.
2. Controller (`before_action :load_reload`) detects `params[:reload] == "1"`:
   `create` **does not save** (`Board.new` + validations skipped), `update` only
   `assign_attributes` — then responds with the form template again (responder receives
   `reload: @reload`), so the modal re-renders with fields matching the new selection,
   preserving user input.

Examples of dependent fields:
- Board: `slave_address` + `data_read_interval` only for `modbus_tcp` type.
- Device: `pin` (Arduino/ESP) vs `holding_register_address`/`scale`/`modbus_data_type`
  (Modbus board); `poll`, `inverted`, value field per subtype (`value_attribute`);
  compression fields only when `log_enabled` && `compressable?` && type chosen.
- Program: nested device rows; Panel/Widget: `name` input only when `show_label?`.

### 2.3 Remote list pattern (index pages)

All index pages (Boards, Devices, Programs, Panels) share:

- A `simple_form_for @search` (Ransack) with `remote: true, method: :get` and a stable
  DOM id (`#board_search`, `#device_search`, `#program_search`, `#panel_search`).
- Text inputs with class `search-field`: debounced auto-submit (default 1000 ms,
  `data-debounce-time` override) via `Layout.initSearchField`.
- Selects/checkboxes with `data-autosubmit`: submit the form on change.
- Per-page select (`common/_per_page`, options 10/20/50/100). The chosen value is
  persisted **per controller+action in a cookie** (`ApplicationController#restore_per_page`).
- Ransack `sort_link ... remote: true` column sorting and Kaminari `paginate ... remote: true`
  pagination — all responses go through `index.js.erb`, which replaces the inner HTML of
  the list container (`#boards`, `#devices`, …) with the re-rendered `_<collection>` partial.
- After create/update/destroy, `refresh_list_by_script(form_selector)` re-fetches the
  current list state: serializes the search form, appends the current page number (read
  from `.pagination` `data-page`), and `$.getScript`s the index URL.

The list partial re-runs its own init (`HomeControl.<X>.initList()` inline script) to
re-bind live-update handlers on the fresh DOM.

> **Hotwire mapping:** this whole pattern collapses into a Turbo Frame wrapping the
> search form + table + pagination, with a Stimulus controller for
> debounce/autosubmit. Sorting/pagination links target the frame.

### 2.4 Flash messages

- Never rendered inline — always shown as a **bootstrap-notify toast** (top center,
  animate.css back-in-down/back-out-up) via `HomeControl.Layout.showFlash(text, type)`.
- Two delivery paths: HTML render (`layouts/common/_flash` emits an inline script) and
  JS responses (`show_flash` helper in `application_helper.rb`).
- `flash.now` is used in controllers for JS responses; `notice` → success (green),
  `alert` → alert (red).

### 2.5 Confirmation modal (custom `data-confirm`)

`lib/assets/javascripts/confirm_modal.coffee` **overrides `$.rails.allowAction`**: any
element with `data-confirm` opens the `#confirm-modal` Bootstrap modal instead of
`window.confirm`. The confirm button is a *clone* of the original link (preserving
`data-method`/`data-remote`), rendered into the modal. Supports `data-submit` (button
label), `data-title`, `data-header`. Handles nesting with the AJAX modal (temporarily
hides `#ajax-modal`, restores it after cancel, optional
`data-close-modal-after-success`).

> **Hotwire mapping:** `Turbo.setConfirmMethod` / `data-turbo-confirm` with a custom
> dialog implementation.

### 2.6 Lazy-loaded page fragments (`data-onload-content`)

Show pages (board, device) render placeholder cards with a spinner and
`data: { onload_content: <url> }`. `Layout.initContentOnLoad` fetches the URL as HTML
and **replaces the whole element** with the response (`$.ajax` + `replaceWith`). Used
for the chart card and the log-table card (`BoardLogs#chart`, `BoardLogs#index`,
`DeviceLogs#chart`, `DeviceLogs#index` — all rendered with `layout: false`).

> **Hotwire mapping:** `<turbo-frame src=…>` with lazy loading — near 1:1 replacement.

### 2.7 Live updates over Action Cable (browser side)

`Layout.initCable` creates one consumer and subscribes to the four browser channels on
every page load. Server side, the `WebsocketPushChange` concern broadcasts the model's
`json_data` **after every update commit** of Board, Device, Program and Panel.

Payloads (`json_data`):

| Model | Payload keys |
|---|---|
| Board | `id`, `status` ("true"/"false" = connected), `ssid`, `signal-strength` |
| Device | `id`, `status`, `updated` (localized last_change), `value`, `indication` |
| Program | `id`, `enabled`, `runtime` (ms), `thread-utilisation`, `last-run`, `last-error-at`, `has-error` |
| Panel | `id` only |

Browser handling (all in CoffeeScript channels + section files):

- **Device/Board/Program:** find all matching elements by `[data-device-id=…]` (etc. —
  the attribute comes from rendering `data: { device: device.json_data }`), write the
  received values into jQuery `.data()`, then trigger a custom event
  (`device:update`, `board:update`, `program:update`). Event handlers update the DOM:
  - toggle CSS state classes `device-on/off`, `board-on/off`, `program-on/off`,
    `program-error` (CSS shows/hides the paired toggle icons, colors widgets — e.g.
    `.toggle-on`/`.toggle-off` links and the connected/disconnected icons),
  - update text of child nodes: `.indication`, `.updated`, `.ssid`, `.signal-strength`,
    `.runtime`, `.thread-utilisation`, `.last-run`, `.last-error-at`,
  - devices additionally trigger `widget:resize` on the enclosing grid-stack item
    (font auto-resize, see 2.9).
- **Panel:** if the currently displayed panel's id matches, do a full
  `Turbolinks.visit(document.location.href)` — i.e. **any widget layout/content change
  reloads the open panel dashboard**.
- On page render the same events are triggered once (`$(".device").trigger("device:update")`)
  so initial state and live updates share one code path.
- The automation process re-broadcasts every device that has widgets and hasn't changed
  for 60 s (`ArduinoServer.push_device_values`, scope `Device.repeated_ws_push`) — a
  keep-fresh mechanism for panel dashboards.

> **Hotwire mapping:** this is the Action Cable → Turbo Streams part. Options:
> `broadcasts_to` with stream/partial replacement per `dom_id`, or keep the JSON
> channels and port the handlers to Stimulus controllers. Note that a single device
> update must refresh **all** its renderings on screen (table row, show header card,
> multiple widgets on a panel), which today's `[data-device-id=…]` multi-match handles.

### 2.8 select2 everywhere

`Layout.initSelect` runs on every `turbolinks:load` (page scope) and on every modal
form render / cocoon insert (modal scope — the `modal` argument scopes the selector to
`#ajax-modal` or a given element). Defaults: bootstrap4 theme, allowClear, search shown
from 7 options. Supports an AJAX mode (`data-ajax-select`, `data-source-url`,
Ransack-style `data-search-term`… — currently no view uses it). `data-autosubmit`
selects submit their form on change.

### 2.9 Panel widget font auto-resizing

`Layout.autoFontResize` fits `.resizable-font-size` text into its parent (80 % height,
60 % width heuristics, multi-line recalculation, >50 px damping). Triggered on panel
render, window resize, `widget:resize` event (after device updates and gridstack
changes).

### 2.10 Page-level JS bootstrapping

Every page/partial ends with an inline `:javascript` block calling its initializer
(`HomeControl.Boards.initIndex()`, `initList()`, `initShow()`, `initForm()` …). Since
list partials re-render via AJAX, the `initList()` call is inside the partial — the
re-init contract must be preserved (or made obsolete by Stimulus lifecycle) during
migration.

---

## 3. Application Sections

### 3.1 Boards (`/boards`)

CRUD for physical boards. Types: `arduino_mega_8b`, `esp`, `modbus_tcp`
(`AttributeOption` concern generates scopes, predicates, i18n collections).

- **Index:** remote list (2.3) — search by name/IP (`name_or_ip_cont`), sortable
  columns, pagination, per-page. Each row carries `data-board=<json_data>` and the
  `.board` class → live connected/disconnected icon, SSID and signal strength (ESP
  only) via BoardChannel.
- **New/Edit:** AJAX modal (2.1); `board_type` reloads the form (2.2) — Modbus shows
  `slave_address` + `data_read_interval`. Fields: name, ip, type,
  `days_to_preserve_logs`.
- **Validations:** name & IP presence, uniqueness (unless Modbus); type presence;
  Modbus requires slave_address + data_read_interval.
- **Destroy:** confirm modal; `restrict_with_error` on devices (deleting a board with
  devices fails — surfaces as flash error), board_logs deleted.
- **Show:** header card with live status; two lazy-loaded cards (2.6): connection
  history **chart** and **connection log** table.
- **Domain behavior** (context): `connected?` = heartbeat within 25 s;
  `Board#parse` handles `pong` (stores version/ssid/rssi), `send_devices` (pushes pin
  config for all devices), `device` (routes value to `Device#set`). Any change of
  connection state/ssid/signal creates a `BoardLog` row (`log_board_log` before_save).
  Modbus read groups devices into consecutive-register blocks; int16 conversion and
  `scale` division applied. Sending to boards goes through the `arduino` / `modbus`
  cable streams.

### 3.2 Board Logs (nested under board show)

- **Connection log table:** Ransack filter `connected_eq` (All/Connected/Disconnected,
  autosubmit), per-page select, remote sorting and pagination — everything re-renders
  `#board_logs` only (`index.js.erb`).
- **Chart:** Chartkick area chart (stepped) fed by `chart.json` — two series:
  Connection (0/1) and Signal Strength (scaled /100). Timespan tabs
  Year/Month/Week/Day/Hour + prev/current/next navigation buttons (all `remote: true`,
  re-render the chart card via `chart.js.erb`). The JSON endpoint pads the series with
  the last value before `min` and the first value after `max` (or current board state)
  so the line spans the full window. Default timespan: `day`.

### 3.3 Devices (`/devices`)

CRUD for devices, STI on `Device` (`device_type` is the inheritance column). Types:
Button, Switch, Distance, DS18B20, AnalogInput, Relay, PWM, Sound, Curtain, BoardTest,
VirtualBoolean, VirtualInteger, VirtualDecimal, VirtualString.

- **Index:** remote list — filters: name (`name_cont`), pin (`pin_eq`), multi-select
  type (`device_type_in`), board (`board_id_eq`); sortable columns; live rows
  (`.device` + `data-device`): `.indication` and `.updated` cells update via
  DeviceChannel. **Toggle buttons** (only for `toggle?` types — Relay, VirtualBoolean):
  paired on/off links `PATCH /devices/:id/set` with `device[value]=true|false`;
  visibility of the pair is CSS-driven by `device-on`/`device-off` class, so the
  buttons flip only when the cable pushes the new state back. `set.js.erb` is
  **intentionally empty** — no direct DOM feedback, the websocket round-trip is the
  feedback.
- **New/Edit:** AJAX modal; `device_type`, `board_id` and `log_enabled` reload the
  form. Field matrix per type/board described in 2.2. Value field name follows
  `value_attribute` (`value_boolean` / `value_integer` / `value_decimal` /
  `value_string`), unit suffix configurable. Log compression settings (type
  average/weighted-average/end-value/max-value, timespan 1/5/10 min/hour/day, backlog)
  shown only for numeric (`compressable?`) devices with logging enabled. Warning hint:
  disabling `log_enabled` deletes all existing logs (`detect_log_enabled_change`).
- **Validations:** name & device_type presence; pin uniqueness per board;
  `holding_register_address` required on Modbus boards; compression timespan/backlog
  required when compression type set; PWM value 0–100; HW types require board.
- **Destroy:** confirm modal, remote; deletes logs, programs_devices, widgets.
- **Show:** header card (live indication + last change), attribute grid (only relevant
  fields shown per type), then — only when `log_enabled?` — lazy-loaded value chart and
  device log table (same pattern as board logs; chart type adapts: line for numeric,
  stepped area for boolean, points-only for others).
- **Side effects on save** (important — must not double-fire after migration):
  changing board/pin/type/poll/inverted re-sends pin configuration to the board(s);
  every value change logs a `DeviceLog` (if enabled), broadcasts to `devices` stream,
  runs triggered programs (`trigger_programs` — programs linked with `trigger: true`);
  writable devices push the new value to the HW (`set_value_to_board`).

### 3.4 Device Logs (nested under device show)

Same UI as Board Logs: filterable/sortable/paginated table (`#device_logs`) and a
Chartkick chart with timespan tabs + prev/next navigation. Chart JSON pads with the
value before the window; y-axis title from device unit.

### 3.5 Programs (`/programs`)

User-written Ruby automation scripts (evaluated with `eval` in `Program#run` context,
helpers from `ProgramsHelper`: `set`/`get` persistent storage, `time_between`,
`log_debug/info/warn/error` writing to `output`).

- **Index:** remote list — filters name (`name_cont`), type (`program_type_eq`:
  default/repeated); live rows via ProgramChannel: last run, runtime (ms), thread
  utilization (%), enabled state (`program-on/off` classes flip the enable/disable
  toggle pair), error state. Row actions: **Run** (`PATCH run`, confirm modal),
  **Copy** (opens new-program modal prefilled via `amoeba_dup`, `?program_id=`),
  **Edit**, **Delete**. Enable/disable toggle: `PATCH set` with
  `program[enabled]=true|false` → `set.js.erb` shows only a flash; visual state comes
  back over the cable.
- **New/Edit:** AJAX modal (large). **CodeMirror** Ruby editor for `code`; cocoon
  nested `programs_devices` rows (device select + `variable_name` + `trigger`
  checkbox); Hide/Show Devices buttons toggle the two-column layout; `program_type`
  reload shows `repeat_every` for repeated programs. On save, `{{variable}}`
  placeholders are precompiled into `Device.find(id)` assignments (`compiled_code`).
- **Show:** live header (enabled/runtime/utilization/last error + message), device
  bindings list, storage variables dump, **Output Log** card (updated after each run),
  code + compiled code side by side. `run.js.erb` additionally re-renders the
  `#program_<id>_output_log` partial if present on page.
- **Run visual feedback:** mousedown/mouseup on any program link briefly adds
  `program-running` class (300 ms), simulating activity.
- **Automation:** repeated programs run from the automation process every second
  (`Program.repeated_to_run` — enabled + interval elapsed); `default` programs run when
  a linked trigger device changes value.
- **Validations:** unique name, type presence.

### 3.6 Panels & Widgets (`/panels`, `/panels/:id/widgets`)

Dashboards built from widgets on a gridstack grid (panel `column` × `row`, default 12×12).

- **Panels index:** remote list (search by name, pagination). Row actions: **Layout**
  (widget grid editor), Edit (modal), Delete. Panel name links to the dashboard with
  `data-turbolinks=false` (full page load — panel uses its own minimal layout
  `layouts/panel`, no navbar).
- **Panel New/Edit modal:** name, `public_access` checkbox, plus nested **widgets**
  via cocoon (widget_type, show_label→name, show_updated, device/program selects,
  color_1/color_2). Panel `column`/`row` inputs exist but are commented out.
- **Widget types:** `switch` (device on/off control — two stacked links,
  CSS-swapped by device state), `button` (runs a program), `boolean_value` (cog icon,
  spinning when true), `text_value` (live `.indication` text). All support label
  header, last-updated footer, two configurable colors; validation: device required
  for switch/boolean/text, program required for button.
- **Dashboard (`show`):** static (non-editable) gridstack, `cellHeight` = 100/rows %.
  Live behavior: device/program updates via cable (2.7) + font auto-resize (2.9).
  **Any panel/widget change broadcast on the `panels` stream reloads the page** via
  Turbolinks if the shown panel id matches. Public access: no auth when
  `public_access?`, otherwise basic auth challenge.
  - Widget switch toggle: `PATCH /panels/:pid/widgets/:id/device/set`
    (`Widgets::DevicesController#set`, public-aware) — empty JS response, state
    returns via DeviceChannel.
  - Widget button: `PATCH /panels/:pid/widgets/:id/program/run?silent=true`
    (`Widgets::ProgramsController#run`, public-aware) — silent (no flash), feedback via
    ProgramChannel + the mousedown "running" animation.
- **Layout editor (`/panels/:id/widgets`):** editable gridstack (drag & resize; resize
  handles always shown on mobile UAs). On every gridstack `change`, each moved item
  writes x/y/w/h into hidden fields of an embedded `form_with` and submits it →
  `PATCH update_position` (empty JS response) → `panel.push_value_change` → all open
  dashboards of this panel reload. Add Widget / per-widget Edit open the AJAX modal
  (widget `_form`); Delete uses the confirm modal. Widget create/update/destroy also
  push the panel reload broadcast.

### 3.7 Home dashboard (`/`)

Landing page listing all Panels (buttons, open in new tab), all Devices and all Boards
with links. Markup still uses Bootstrap 3 classes (`panel panel-primary`, `label`,
`pull-right`) and its live-update init (`HomeControl.Home.init()`) is **commented
out** — rows render `json_data` data attributes but do not currently update. De facto
a legacy page; candidate for redesign during migration rather than 1:1 port.

### 3.8 Backups (`/backup`)

- **Show:** two download cards — SQL format and PostgreSQL custom format.
- **Download:** runs `pg_dump` synchronously with credentials from the AR connection
  config, streams it via `send_data` (`<db>_<timestamp>.sql|.dump`). Unknown format →
  `400`; pg_dump failure → flash alert + redirect back. PostgreSQL-only feature.

### 3.9 Server Logs (`/logs/index`, `/logs/show?file=…`)

Not linked in the navbar. Lists `log/*.log` files with mtimes; show renders
`tail -n 1000` of the selected file (file name validated against the directory listing
before shelling out). Bootstrap 3 markup, plain full-page navigation.

### 3.10 Welcome (`/welcome#index`)

Rails scaffold leftover, unused. Candidate for deletion during cleanup.

---

## 4. Behavioral Details Worth Preserving (easy to miss)

1. **Empty JS responses as a pattern** — `devices/set`, `widgets/devices/set`,
   `widgets/programs/run`, `widgets/update_position` intentionally return nothing;
   *all* UI feedback flows through Action Cable. Toggle buttons must not optimistically
   flip.
2. **Initial state and live updates share one code path** — pages trigger
   `*:update` events on load from server-rendered `data-*` attributes. After migration,
   first render and stream updates must stay consistent (no flash of stale state).
3. **One device, many renderings** — a single broadcast updates table rows, show
   header and any number of panel widgets simultaneously.
4. **Per-page cookie** (`<controller>_<action>_per`) persists list page size across
   visits, per list.
5. **`reload` form round-trip preserves user input** and skips saving/validation.
6. **Panel full-reload semantics** — widget layout changes anywhere (editor drag,
   widget CRUD) refresh every open instance of that dashboard.
7. **Modal nesting** — confirm modal opened from inside the AJAX modal hides and
   restores it (widget delete inside layout editor, etc.).
8. **Flash always as toast**, including after full-page HTML renders.
9. **Chart window padding** — chart JSON prepends the last value before the window
   (and appends the next/current one for boards) so stepped lines span the full axis.
10. **`refresh_list_by_script` keeps the current page** after create/update/delete
    (reads `data-page` from the Kaminari pagination block).
11. **The keep-alive re-push** (60 s) exists only for devices that have widgets.
12. **`data-turbolinks=false` on panel links** — dashboards intentionally escape
    Turbolinks (different layout, own height-100 body). Same consideration applies to
    Turbo Drive.
13. **Test-env auth bypass** — `authenticate` returns early in test env; feature specs
    rely on it.

---

## 5. Migration Mapping Summary (current → Hotwire)

| # | Current pattern | Target |
|---|---|---|
| 1 | Turbolinks 5 | Turbo Drive (drop turbolinks gem, `data-turbolinks` → `data-turbo`) |
| 2 | AJAX modal + `*.js.erb` + AjaxModalResponder | Turbo Frame modal (frame in layout, forms respond with `turbo_stream`/frame; errors re-render in frame) |
| 3 | `refresh_list_by_script` + `index.js.erb` | Turbo Frame around list (search/sort/pagination target the frame) + Stimulus autosubmit/debounce controller |
| 4 | `data-reload` form reload | Stimulus controller (`change → requestSubmit` with `reload` param), response re-renders form frame |
| 5 | Custom cable channels + jQuery data events | Turbo Streams broadcasts (`broadcasts_to`) replacing partials by `dom_id`, or Stimulus-ported channel handlers; keep `arduino`/`modbus` channels untouched |
| 6 | PanelChannel full reload | `turbo_stream` page refresh (Turbo 8 morph refresh) or explicit stream action |
| 7 | bootstrap-notify flash | Turbo Stream append to a toast container + Stimulus toast controller |
| 8 | `$.rails.allowAction` confirm modal | `Turbo.setConfirmMethod` custom dialog |
| 9 | `data-onload-content` | Lazy `<turbo-frame src>` |
| 10 | select2 / cocoon / CodeMirror / gridstack / chartkick inits | Stimulus controllers (connect/disconnect lifecycle replaces manual re-init) |
| 11 | jquery_ujs (`data-method`, `data-disable-with`) | Turbo method links / button_to, Turbo submit disabling |
| 12 | Inline `:javascript` page inits | removed — Stimulus `data-controller` attributes |

---

*Document generated 2026-07-13 against v3.4.6 (Rails 7.2.3, Ruby 3.3.6).*
