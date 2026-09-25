// Weekly upgrade check (GitLab scheduled pipeline). Compares the versions pinned in this repo
// against upstream latest; on drift it opens (or refreshes) one work item in peterk/work assigned
// to Peter and fails the job. A failed lookup also fails, so a broken check can't pass silently.

type Check = { name: string; files: string[]; pattern: RegExp; latest: () => Promise<string> };

const json = async (url: string) => {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url} -> HTTP ${res.status}`);
  return res.json() as Promise<any>;
};

const CHECKS: Check[] = [
  {
    name: "aws-cdk (npm CLI)",
    files: ["Dockerfile", "Dockerfile.java"],
    pattern: /aws-cdk@(\d+\.\d+\.\d+)/,
    latest: async () => (await json("https://registry.npmjs.org/aws-cdk/latest")).version,
  },
  {
    name: "aws-cdk-lib (PyPI)",
    files: ["Dockerfile"],
    pattern: /aws-cdk-lib==(\d+\.\d+\.\d+)/,
    latest: async () => (await json("https://pypi.org/pypi/aws-cdk-lib/json")).info.version,
  },
];

const REPO = "cdk";
const TITLE = `${REPO}: upgrades available`;

const rows: string[] = [];
let drift = false;
for (const c of CHECKS) {
  const latest = await c.latest();
  for (const f of c.files) {
    const pinned = (await Bun.file(f).text()).match(c.pattern)?.[1];
    if (!pinned) throw new Error(`${c.name}: pin not found in ${f}`);
    const behind = pinned !== latest;
    drift ||= behind;
    rows.push(`| ${c.name} | \`${f}\` | ${pinned} | ${latest} | ${behind ? "⬆️ upgrade" : "✅"} |`);
  }
}

const table = ["| Component | File | Pinned | Latest | |", "|---|---|---|---|---|", ...rows].join("\n");
console.log(table);
if (!drift) {
  console.log("\nAll pins current.");
  process.exit(0);
}

const token = process.env.WORK_ITEM_TOKEN;
if (!token) throw new Error("WORK_ITEM_TOKEN not set");
const api = `${process.env.CI_SERVER_URL}/api/v4/projects/${encodeURIComponent("peterk/work")}/issues`;
const headers = { "PRIVATE-TOKEN": token, "Content-Type": "application/json" };

const today = new Date().toISOString().slice(0, 10);
const description = [
  `Weekly check found pinned versions behind upstream in **peterk/${REPO}** (${today}).`,
  "",
  table,
  "",
  "Bump the pins (and CHANGELOG), build locally, verify versions + Trivy, then MR.",
  `Source: ${process.env.CI_JOB_URL ?? "local run"}`,
].join("\n");

const open = await (
  await fetch(`${api}?state=opened&in=title&search=${encodeURIComponent(TITLE)}`, { headers })
).json() as any[];
const existing = open.find((i) => i.title === TITLE);

const due = new Date(Date.now() + 7 * 864e5).toISOString().slice(0, 10);
const res = existing
  ? await fetch(`${api}/${existing.iid}`, { method: "PUT", headers, body: JSON.stringify({ description }) })
  : await fetch(api, {
      method: "POST",
      headers,
      body: JSON.stringify({
        title: TITLE,
        description,
        due_date: due,
        labels: "Agent:Sophia,Priority:P3,Property:internal,Status:queued,Type:task",
        assignee_ids: [3], // peterk — assignment is what emails him + lands it in his To-Do list
      }),
    });
if (!res.ok) throw new Error(`work item ${existing ? "update" : "create"} failed: HTTP ${res.status} ${await res.text()}`);
console.log(`\nWork item ${existing ? "updated" : "created"}: ${(await res.json()).web_url}`);

// Drift fails the job on purpose: the failed scheduled pipeline is the weekly alert email,
// and it keeps firing until the pins are bumped.
console.error("Upgrade needed — failing so GitLab sends the pipeline-failure alert.");
process.exit(1);
