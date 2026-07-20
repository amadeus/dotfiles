const childSessions = new Set()

const notifications = {
  "permission.asked": "permission",
  "question.asked": "waiting",
  "session.idle": "waiting",
}

function updateChildSessions(event) {
  if (event.type === "session.deleted") {
    childSessions.delete(event.properties.info.id)
    return
  }

  if (event.type !== "session.created" && event.type !== "session.updated") {
    return
  }

  const session = event.properties.info
  if (session.parentID) {
    childSessions.add(session.id)
  } else {
    childSessions.delete(session.id)
  }
}

function notify(event) {
  const notification = notifications[event.type]
  if (!notification || !process.env.NVIM || !process.stdout.isTTY) {
    return
  }

  if (event.type === "session.idle" && childSessions.has(event.properties.sessionID)) {
    return
  }

  process.stdout.write(`\u001b]9;sidekick:${notification}\u001b\\`)
}

export const SidekickNotify = async () => ({
  event: async ({ event }) => {
    updateChildSessions(event)
    notify(event)
  },
})
