// Is the guest's live-notification socket actually up on a public page?
//
// The popup is meant to land on ANY screen. On 2026-09-12 a host declined in
// one window and nothing appeared in the other, on the property page the guest
// was reading — so before blaming the toast, ask the socket.
//
//   node negotiation-journey/socketcheck.mjs [path]
import { open, pause, dismissBanners, SITE } from "./rig.mjs";

const path = process.argv[2] || "/property?id=29291&from=12-09-2026&to=13-09-2026&guests=2";

const { browser, page } = await open("renter");
try {
  const logs = [];
  const wanted = [];
  page.on("console", (m) => logs.push(`${m.type()}: ${m.text()}`.slice(0, 220)));
  page.on("pageerror", (e) => logs.push(`pageerror: ${e.message}`.slice(0, 220)));
  // "ws" as a substring also matches "reviews", which is how the first run of
  // this file reported the reviews endpoint as a websocket.
  page.on("request", (r) => {
    const u = r.url();
    if (u.includes("/socket.io/") || u.includes("/user/detail") || u.startsWith("ws")) {
      wanted.push(`${r.method()} ${u.slice(0, 150)}`);
    }
  });
  // The SHAPE of /user/detail, never its contents: the question is which key
  // the id arrives under, and printing a profile would put a real person's
  // details in a log.
  page.on("response", async (r) => {
    if (!r.url().includes("/user/detail")) return;
    try {
      const body = await r.json();
      const data = body?.data?.data ?? body?.data ?? body;
      wanted.push(`RESPONSE /user/detail ${r.status()} envelope=[${Object.keys(body || {}).join(",")}] payload=[${Object.keys(data || {}).slice(0, 24).join(",")}]`);
      for (const k of ["userId", "user_id", "cred_user_id"]) {
        if (data && data[k] != null) wanted.push(`  id key "${k}" is present`);
      }
    } catch (e) { wanted.push(`RESPONSE /user/detail unreadable: ${e.message}`); }
  });
  page.on("requestfailed", (r) => {
    const u = r.url();
    if (u.includes("/socket.io/") || u.includes("/user/detail")) {
      wanted.push(`FAILED ${u.slice(0, 120)} — ${r.failure()?.errorText}`);
    }
  });

  /**
   * A websocket is not a request.
   *
   * page.on("request") never fires for a WS upgrade, and socket.io is
   * configured websocket-first — so the first run of this file reported "no
   * socket.io traffic" about a page whose socket may well have been open. CDP
   * is the only place the handshake is visible.
   */
  const cdp = await page.target().createCDPSession();
  await cdp.send("Network.enable");
  const sockets = [];
  cdp.on("Network.webSocketCreated", (e) => sockets.push(`created ${String(e.url).slice(0, 120)}`));
  cdp.on("Network.webSocketHandshakeResponseReceived", (e) => sockets.push(`handshake ${e.response?.status}`));
  cdp.on("Network.webSocketClosed", () => sockets.push("closed"));
  cdp.on("Network.webSocketFrameError", (e) => sockets.push(`frame error ${e.errorMessage}`));
  // The frames themselves say whether anything ARRIVED. Only the event name is
  // printed: a notification frame carries a person's booking details.
  cdp.on("Network.webSocketFrameReceived", (e) => {
    const m = /"([a-z_:]+)"/i.exec(String(e.response?.payloadData || ""));
    if (m) sockets.push(`recv ${m[1]}`);
  });

  await page.goto(SITE + path, { waitUntil: "domcontentloaded" });
  await pause(10000);
  await dismissBanners(page);
  await pause(3000);

  const state = await page.evaluate(() => {
    // Never print a token. Its presence and length are the whole question.
    const tok = localStorage.getItem("aajao_token");
    return {
      path: location.pathname,
      tokenPresent: tok != null,
      tokenLength: tok ? tok.length : 0,
      socketDisconnected: localStorage.getItem("socketDisconnected"),
    };
  });
  console.log(JSON.stringify(state, null, 1));

  console.log("\nrequests that matter:");
  console.log(wanted.length ? [...new Set(wanted)].slice(0, 10).join("\n") : "  (none — no /user/detail, no socket.io)");

  console.log("\nwebsocket:");
  console.log(sockets.length ? sockets.slice(0, 14).join("\n") : "  (no websocket was ever created)");

  console.log("\nconsole:");
  console.log(logs.slice(-20).join("\n") || "  (quiet)");
} finally {
  await browser.close();
}
