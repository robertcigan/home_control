import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

// Feature specs wait for an open socket before broadcasting live updates.
if (typeof window !== "undefined") {
  window.__HOME_CONTROL_CABLE__ = consumer
}

export default consumer
