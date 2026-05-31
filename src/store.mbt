///|
enum AppPathSeg {
  Field(String)
  Index(Int)
} derive(Eq, Hash, ToJson, @json.FromJson)

///|
enum ViewMode {
  Editing
  Diffing
} derive(Eq, ToJson, @json.FromJson)

///|
struct Store {
  draft_left : String
  draft_right : String
  left_text : String
  right_text : String
  mode : ViewMode
  states : @respo.RespoStatesTree
} derive(ToJson, @json.FromJson, Eq)

///|
let demo_left : String =
  #|{
  #|  "workspace": {
  #|    "id": "ws-analytics-core",
  #|    "name": "Analytics Control Plane",
  #|    "region": "eu-west-1",
  #|    "version": 17,
  #|    "owner": {
  #|      "id": "user-ada-01",
  #|      "name": "Ada Lovelace",
  #|      "role": "Engineer",
  #|      "active": true,
  #|      "timezone": "UTC+0",
  #|      "location": {
  #|        "city": "London",
  #|        "country": "UK"
  #|      },
  #|      "contacts": {
  #|        "email": "ada@example.com",
  #|        "slack": "@ada",
  #|        "phones": ["+44-20-0000-0001"]
  #|      }
  #|    }
  #|  },
  #|  "metrics": {
  #|    "score": 12,
  #|    "velocity": 7.5,
  #|    "risk": 0.18,
  #|    "tags": ["core", "moonbit", "infra"],
  #|    "history": [12, 11, 13, 12, 14, 15],
  #|    "flags": {
  #|      "mentor": true,
  #|      "oncall": false,
  #|      "shadow": null,
  #|      "blocked": false
  #|    },
  #|    "weekly": [
  #|      { "week": "2026-W18", "open": 14, "closed": 10, "sla": 0.95 },
  #|      { "week": "2026-W19", "open": 12, "closed": 13, "sla": 0.97 },
  #|      { "week": "2026-W20", "open": 16, "closed": 11, "sla": 0.9 },
  #|      { "week": "2026-W21", "open": 15, "closed": 14, "sla": 0.94 },
  #|      { "week": "2026-W22", "open": 18, "closed": 12, "sla": 0.89 },
  #|      { "week": "2026-W23", "open": 13, "closed": 16, "sla": 0.98 }
  #|    ]
  #|  },
  #|  "services": [
  #|    {
  #|      "id": "svc-api",
  #|      "name": "Public API",
  #|      "tier": "critical",
  #|      "replicas": 6,
  #|      "ports": [80, 443],
  #|      "owners": ["ada", "bob"],
  #|      "deploy": {
  #|        "strategy": "rolling",
  #|        "image": "registry/api:1.18.2",
  #|        "health": { "path": "/ready", "timeoutMs": 1500 }
  #|      }
  #|    },
  #|    {
  #|      "id": "svc-worker",
  #|      "name": "Async Worker",
  #|      "tier": "standard",
  #|      "replicas": 10,
  #|      "ports": [9100],
  #|      "owners": ["carol"],
  #|      "deploy": {
  #|        "strategy": "rolling",
  #|        "image": "registry/worker:1.18.2",
  #|        "health": { "path": "/healthz", "timeoutMs": 2000 }
  #|      }
  #|    },
  #|    {
  #|      "id": "svc-dashboard",
  #|      "name": "Ops Dashboard",
  #|      "tier": "standard",
  #|      "replicas": 3,
  #|      "ports": [3000],
  #|      "owners": ["dora", "erin"],
  #|      "deploy": {
  #|        "strategy": "blue-green",
  #|        "image": "registry/dashboard:5.4.0",
  #|        "health": { "path": "/status", "timeoutMs": 1200 }
  #|      }
  #|    },
  #|    {
  #|      "id": "svc-sync",
  #|      "name": "Metrics Sync",
  #|      "tier": "batch",
  #|      "replicas": 2,
  #|      "ports": [7070],
  #|      "owners": ["frank"],
  #|      "deploy": {
  #|        "strategy": "recreate",
  #|        "image": "registry/sync:2.0.1",
  #|        "health": { "path": "/live", "timeoutMs": 2500 }
  #|      }
  #|    }
  #|  ],
  #|  "projects": [
  #|    {
  #|      "id": "proj-alpha",
  #|      "name": "Alpha",
  #|      "status": "active",
  #|      "members": ["ada", "bob", "carol"],
  #|      "budget": { "currency": "USD", "monthly": 12000 },
  #|      "milestones": [
  #|        { "id": "m1", "title": "schema", "done": true },
  #|        { "id": "m2", "title": "rollout", "done": false }
  #|      ]
  #|    },
  #|    {
  #|      "id": "proj-docs",
  #|      "name": "Docs",
  #|      "status": "paused",
  #|      "members": ["ada"],
  #|      "budget": { "currency": "USD", "monthly": 2500 },
  #|      "milestones": [
  #|        { "id": "m1", "title": "inventory", "done": true },
  #|        { "id": "m2", "title": "guides", "done": false }
  #|      ]
  #|    },
  #|    {
  #|      "id": "proj-gamma",
  #|      "name": "Gamma",
  #|      "status": "design",
  #|      "members": ["erin", "frank", "gina"],
  #|      "budget": { "currency": "EUR", "monthly": 6400 },
  #|      "milestones": [
  #|        { "id": "m1", "title": "prototype", "done": false },
  #|        { "id": "m2", "title": "feedback", "done": false }
  #|      ]
  #|    }
  #|  ],
  #|  "tasks": [
  #|    { "id": "task-1", "title": "Draft spec", "done": false, "priority": 2, "labels": ["design", "api"], "estimate": 5 },
  #|    { "id": "task-2", "title": "Review UI", "done": false, "priority": 1, "labels": ["frontend"], "estimate": 3 },
  #|    { "id": "task-3", "title": "Sync metrics", "done": true, "priority": 3, "labels": [], "estimate": 2 },
  #|    { "id": "task-4", "title": "Map alerts", "done": false, "priority": 0, "labels": ["ops", "urgent"], "estimate": 1 },
  #|    { "id": "task-5", "title": "Trace latency", "done": false, "priority": 2, "labels": ["perf"], "estimate": 8 },
  #|    { "id": "task-6", "title": "Clean docs", "done": true, "priority": 4, "labels": ["docs"], "estimate": 2 }
  #|  ],
  #|  "inventories": {
  #|    "queues": [
  #|      { "name": "billing", "lag": 18, "consumers": 4 },
  #|      { "name": "events", "lag": 2, "consumers": 6 },
  #|      { "name": "exports", "lag": 0, "consumers": 2 },
  #|      { "name": "webhooks", "lag": 33, "consumers": 3 }
  #|    ],
  #|    "buckets": [
  #|      { "name": "raw", "objects": 1203, "encrypted": true },
  #|      { "name": "curated", "objects": 812, "encrypted": true },
  #|      { "name": "snapshots", "objects": 96, "encrypted": false }
  #|    ],
  #|    "regions": {
  #|      "eu-west-1": { "nodes": 14, "draining": 1 },
  #|      "us-east-1": { "nodes": 9, "draining": 0 },
  #|      "ap-southeast-1": { "nodes": 4, "draining": 0 }
  #|    }
  #|  },
  #|  "dashboards": [
  #|    {
  #|      "id": "db-overview",
  #|      "title": "Overview",
  #|      "widgets": [
  #|        { "kind": "chart", "metric": "latency.p95", "span": 6 },
  #|        { "kind": "chart", "metric": "error.rate", "span": 3 },
  #|        { "kind": "table", "metric": "queue.lag", "span": 3 }
  #|      ]
  #|    },
  #|    {
  #|      "id": "db-capacity",
  #|      "title": "Capacity",
  #|      "widgets": [
  #|        { "kind": "chart", "metric": "cpu", "span": 4 },
  #|        { "kind": "chart", "metric": "memory", "span": 4 },
  #|        { "kind": "chart", "metric": "replicas", "span": 4 }
  #|      ]
  #|    },
  #|    {
  #|      "id": "db-audit",
  #|      "title": "Audit",
  #|      "widgets": [
  #|        { "kind": "feed", "metric": "deploys", "span": 12 },
  #|        { "kind": "table", "metric": "reviewers", "span": 12 }
  #|      ]
  #|    }
  #|  ],
  #|  "featureFlags": {
  #|    "jsonDiffV2": true,
  #|    "compactRows": false,
  #|    "inlineBadges": true,
  #|    "betaSidebar": false,
  #|    "opsEscalation": true,
  #|    "sampling": 0.25
  #|  },
  #|  "settings": {
  #|    "theme": "light",
  #|    "notifications": {
  #|      "email": true,
  #|      "push": false,
  #|      "digestHour": 9,
  #|      "slack": true
  #|    },
  #|    "shortcuts": [
  #|      { "key": "cmd+k", "action": "search" },
  #|      { "key": "g d", "action": "dashboard" },
  #|      { "key": "g s", "action": "services" }
  #|    ]
  #|  },
  #|  "audit": {
  #|    "createdAt": "2026-05-01T10:00:00Z",
  #|    "updatedAt": "2026-05-29T08:20:00Z",
  #|    "reviewers": [
  #|      { "name": "Bob", "approved": true },
  #|      { "name": "Carol", "approved": false }
  #|    ],
  #|    "timeline": [
  #|      { "ts": "2026-05-01T10:00:00Z", "type": "created", "by": "ada" },
  #|      { "ts": "2026-05-12T09:10:00Z", "type": "deploy", "by": "bob" },
  #|      { "ts": "2026-05-18T17:44:00Z", "type": "rollback", "by": "carol" },
  #|      { "ts": "2026-05-29T08:20:00Z", "type": "review", "by": "ada" }
  #|    ]
  #|  },
  #|  "matrices": {
  #|    "availability": [[1, 1, 1, 1], [1, 0, 1, 1], [1, 1, 1, 0]],
  #|    "capacity": [[12, 13, 11], [9, 10, 10], [5, 5, 4]]
  #|  },
  #|  "notes": null
  #|}

///|
let demo_right : String =
  #|{
  #|  "workspace": {
  #|    "id": "ws-analytics-core",
  #|    "name": "Analytics Control Plane",
  #|    "region": "eu-central-1",
  #|    "version": 21,
  #|    "owner": {
  #|      "id": "user-ada-01",
  #|      "name": "Ada Lovelace",
  #|      "role": "Staff Engineer",
  #|      "active": true,
  #|      "timezone": "UTC+1",
  #|      "location": {
  #|        "city": "London",
  #|        "country": "UK",
  #|        "office": "Remote"
  #|      },
  #|      "contacts": {
  #|        "email": "ada@example.com",
  #|        "slack": "@ada-core",
  #|        "phones": ["+44-20-0000-0001", "+44-20-0000-0009"]
  #|      }
  #|    }
  #|  },
  #|  "metrics": {
  #|    "score": 18,
  #|    "velocity": 8.2,
  #|    "risk": 0.09,
  #|    "tags": ["core", "json", "moonbit", "perf"],
  #|    "history": [12, 11, 13, 18, 20, 21],
  #|    "flags": {
  #|      "mentor": true,
  #|      "oncall": true,
  #|      "shadow": false,
  #|      "blocked": false,
  #|      "expedite": true
  #|    },
  #|    "weekly": [
  #|      { "week": "2026-W18", "open": 14, "closed": 10, "sla": 0.95 },
  #|      { "week": "2026-W19", "open": 12, "closed": 13, "sla": 0.97 },
  #|      { "week": "2026-W20", "open": 11, "closed": 17, "sla": 0.99 },
  #|      { "week": "2026-W21", "open": 10, "closed": 18, "sla": 0.98 },
  #|      { "week": "2026-W22", "open": 8, "closed": 19, "sla": 0.99 },
  #|      { "week": "2026-W23", "open": 7, "closed": 22, "sla": 1.0 },
  #|      { "week": "2026-W24", "open": 9, "closed": 24, "sla": 0.98 }
  #|    ]
  #|  },
  #|  "services": [
  #|    {
  #|      "id": "svc-api",
  #|      "name": "Public API",
  #|      "tier": "critical",
  #|      "replicas": 8,
  #|      "ports": [80, 443],
  #|      "owners": ["ada", "bob", "helen"],
  #|      "deploy": {
  #|        "strategy": "canary",
  #|        "image": "registry/api:1.20.0",
  #|        "health": { "path": "/ready", "timeoutMs": 1200 }
  #|      }
  #|    },
  #|    {
  #|      "id": "svc-dashboard",
  #|      "name": "Ops Dashboard",
  #|      "tier": "critical",
  #|      "replicas": 5,
  #|      "ports": [3000, 3443],
  #|      "owners": ["dora", "erin"],
  #|      "deploy": {
  #|        "strategy": "blue-green",
  #|        "image": "registry/dashboard:5.8.1",
  #|        "health": { "path": "/status", "timeoutMs": 1000 }
  #|      }
  #|    },
  #|    {
  #|      "id": "svc-sync",
  #|      "name": "Metrics Sync",
  #|      "tier": "batch",
  #|      "replicas": 4,
  #|      "ports": [7070],
  #|      "owners": ["frank", "irene"],
  #|      "deploy": {
  #|        "strategy": "rolling",
  #|        "image": "registry/sync:2.2.0",
  #|        "health": { "path": "/live", "timeoutMs": 1800 }
  #|      }
  #|    },
  #|    {
  #|      "id": "svc-notify",
  #|      "name": "Notification Router",
  #|      "tier": "standard",
  #|      "replicas": 3,
  #|      "ports": [6060],
  #|      "owners": ["jane"],
  #|      "deploy": {
  #|        "strategy": "rolling",
  #|        "image": "registry/notify:0.9.4",
  #|        "health": { "path": "/ready", "timeoutMs": 1600 }
  #|      }
  #|    }
  #|  ],
  #|  "projects": [
  #|    {
  #|      "id": "proj-alpha",
  #|      "name": "Alpha",
  #|      "status": "active",
  #|      "members": ["ada", "bob", "carol", "dora"],
  #|      "budget": { "currency": "USD", "monthly": 18000 },
  #|      "milestones": [
  #|        { "id": "m1", "title": "schema", "done": true },
  #|        { "id": "m2", "title": "rollout", "done": true },
  #|        { "id": "m3", "title": "cleanup", "done": false }
  #|      ]
  #|    },
  #|    {
  #|      "id": "proj-beta",
  #|      "name": "Beta",
  #|      "status": "planning",
  #|      "members": ["ada", "erin"],
  #|      "budget": { "currency": "EUR", "monthly": 9000 },
  #|      "milestones": [
  #|        { "id": "m1", "title": "charter", "done": true },
  #|        { "id": "m2", "title": "estimates", "done": false }
  #|      ]
  #|    },
  #|    {
  #|      "id": "proj-gamma",
  #|      "name": "Gamma",
  #|      "status": "delivery",
  #|      "members": ["erin", "frank", "gina", "helen"],
  #|      "budget": { "currency": "EUR", "monthly": 8400 },
  #|      "milestones": [
  #|        { "id": "m1", "title": "prototype", "done": true },
  #|        { "id": "m2", "title": "feedback", "done": true },
  #|        { "id": "m3", "title": "launch", "done": false }
  #|      ]
  #|    }
  #|  ],
  #|  "tasks": [
  #|    { "id": "task-2", "title": "Review UI", "done": true, "priority": 1, "labels": ["frontend", "ux"], "estimate": 4 },
  #|    { "id": "task-4", "title": "Ship beta", "done": false, "priority": 0, "labels": ["release", "ops"], "estimate": 5 },
  #|    { "id": "task-5", "title": "Write migration notes", "done": false, "priority": 2, "labels": ["docs"], "estimate": 3 },
  #|    { "id": "task-6", "title": "Clean docs", "done": true, "priority": 4, "labels": ["docs", "archive"], "estimate": 1 },
  #|    { "id": "task-7", "title": "Stabilize canary", "done": false, "priority": 0, "labels": ["ops", "api"], "estimate": 8 },
  #|    { "id": "task-8", "title": "Backfill timeline", "done": true, "priority": 3, "labels": ["audit"], "estimate": 2 }
  #|  ],
  #|  "inventories": {
  #|    "queues": [
  #|      { "name": "billing", "lag": 4, "consumers": 5 },
  #|      { "name": "events", "lag": 0, "consumers": 8 },
  #|      { "name": "exports", "lag": 3, "consumers": 3 },
  #|      { "name": "webhooks", "lag": 12, "consumers": 5 },
  #|      { "name": "notifications", "lag": 1, "consumers": 2 }
  #|    ],
  #|    "buckets": [
  #|      { "name": "raw", "objects": 1402, "encrypted": true },
  #|      { "name": "curated", "objects": 1008, "encrypted": true },
  #|      { "name": "snapshots", "objects": 132, "encrypted": true },
  #|      { "name": "exports", "objects": 74, "encrypted": true }
  #|    ],
  #|    "regions": {
  #|      "eu-central-1": { "nodes": 18, "draining": 0 },
  #|      "us-east-1": { "nodes": 12, "draining": 1 },
  #|      "ap-southeast-1": { "nodes": 5, "draining": 0 },
  #|      "sa-east-1": { "nodes": 3, "draining": 0 }
  #|    }
  #|  },
  #|  "dashboards": [
  #|    {
  #|      "id": "db-overview",
  #|      "title": "Overview",
  #|      "widgets": [
  #|        { "kind": "chart", "metric": "latency.p95", "span": 4 },
  #|        { "kind": "chart", "metric": "error.rate", "span": 4 },
  #|        { "kind": "table", "metric": "queue.lag", "span": 4 },
  #|        { "kind": "stat", "metric": "incident.count", "span": 12 }
  #|      ]
  #|    },
  #|    {
  #|      "id": "db-capacity",
  #|      "title": "Capacity",
  #|      "widgets": [
  #|        { "kind": "chart", "metric": "cpu", "span": 3 },
  #|        { "kind": "chart", "metric": "memory", "span": 3 },
  #|        { "kind": "chart", "metric": "replicas", "span": 3 },
  #|        { "kind": "chart", "metric": "network", "span": 3 }
  #|      ]
  #|    },
  #|    {
  #|      "id": "db-audit",
  #|      "title": "Audit",
  #|      "widgets": [
  #|        { "kind": "feed", "metric": "deploys", "span": 8 },
  #|        { "kind": "table", "metric": "reviewers", "span": 4 },
  #|        { "kind": "table", "metric": "changes", "span": 12 }
  #|      ]
  #|    },
  #|    {
  #|      "id": "db-releases",
  #|      "title": "Releases",
  #|      "widgets": [
  #|        { "kind": "timeline", "metric": "release.train", "span": 12 }
  #|      ]
  #|    }
  #|  ],
  #|  "featureFlags": {
  #|    "jsonDiffV2": true,
  #|    "compactRows": true,
  #|    "inlineBadges": true,
  #|    "betaSidebar": true,
  #|    "opsEscalation": true,
  #|    "sampling": 0.5,
  #|    "showLatencyHeatmap": true
  #|  },
  #|  "settings": {
  #|    "theme": "solarized",
  #|    "notifications": {
  #|      "email": true,
  #|      "push": true,
  #|      "digestHour": 7,
  #|      "slack": true,
  #|      "sms": false
  #|    },
  #|    "shortcuts": [
  #|      { "key": "cmd+k", "action": "search" },
  #|      { "key": "g d", "action": "home" },
  #|      { "key": "g s", "action": "services" },
  #|      { "key": "shift+r", "action": "refresh" }
  #|    ]
  #|  },
  #|  "audit": {
  #|    "createdAt": "2026-05-01T10:00:00Z",
  #|    "updatedAt": "2026-06-01T09:45:00Z",
  #|    "reviewers": [
  #|      { "name": "Bob", "approved": true },
  #|      { "name": "Carol", "approved": true },
  #|      { "name": "Dora", "approved": false }
  #|    ],
  #|    "timeline": [
  #|      { "ts": "2026-05-01T10:00:00Z", "type": "created", "by": "ada" },
  #|      { "ts": "2026-05-12T09:10:00Z", "type": "deploy", "by": "bob" },
  #|      { "ts": "2026-05-18T17:44:00Z", "type": "rollback", "by": "carol" },
  #|      { "ts": "2026-05-29T08:20:00Z", "type": "review", "by": "ada" },
  #|      { "ts": "2026-06-01T09:45:00Z", "type": "promote", "by": "dora" }
  #|    ]
  #|  },
  #|  "matrices": {
  #|    "availability": [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
  #|    "capacity": [[14, 14, 13], [11, 12, 11], [6, 6, 5]],
  #|    "latencyBands": [[12, 18, 25, 31], [10, 15, 20, 28]]
  #|  },
  #|  "notes": "Promoted to staff track"
  #|}

///|
impl Default for Store with fn default() -> Store {
  {
    draft_left: demo_left,
    draft_right: demo_right,
    left_text: demo_left,
    right_text: demo_right,
    mode: Editing,
    states: @respo.RespoStatesTree::default(),
  }
}

///|
enum ActionOp {
  StatesChange(@respo.RespoUpdateState)
  EditLeftDraft(String)
  EditRightDraft(String)
  CompareDrafts
  EditDrafts
}

///|
impl @respo_node.RespoAction for ActionOp with fn build_states_action(
  cursor,
  a,
  j,
) {
  StatesChange({ cursor, data: a.map(@dom_ffi.js_obscure_to_v), backup: j })
}

///|
impl Show for ActionOp with fn output(self, logger) -> Unit {
  let s = match self {
    StatesChange(_) => "StatesChange"
    EditLeftDraft(_) => "EditLeftDraft"
    EditRightDraft(_) => "EditRightDraft"
    CompareDrafts => "CompareDrafts"
    EditDrafts => "EditDrafts"
  }
  logger.write_string(s)
}

///|
fn Store::update(self : Store, op : ActionOp) -> Store {
  match op {
    StatesChange(states) => { ..self, states: self.states.set_in(states) }
    EditLeftDraft(content) => { ..self, draft_left: content }
    EditRightDraft(content) => { ..self, draft_right: content }
    CompareDrafts =>
      {
        ..self,
        left_text: self.draft_left,
        right_text: self.draft_right,
        mode: Diffing,
      }
    EditDrafts => { ..self, mode: Editing }
  }
}
