#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const endpoint = "https://chatgpt.com/backend-api/codex/rate-limit-reset-credits";
const authPath = path.join(os.homedir(), ".codex", "auth.json");
const timeZone = process.env.TZ || Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";

function fail(message, details = {}) {
  console.log(JSON.stringify({ ok: false, error: message, ...details }, null, 2));
  process.exitCode = 1;
}

function sanitize(value) {
  if (Array.isArray(value)) {
    return value.map(sanitize);
  }

  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => {
        if (/token|secret|cookie|authorization|auth|jwt|key/i.test(key)) {
          return [key, "[redacted]"];
        }
        return [key, sanitize(nested)];
      }),
    );
  }

  if (typeof value === "string") {
    return value
      .replace(/Bearer\s+[A-Za-z0-9._~+/-]+/g, "Bearer [redacted]")
      .replace(/eyJ[A-Za-z0-9._-]+/g, "[jwt-redacted]");
  }

  return value;
}

function formatLocal(isoString) {
  if (!isoString) {
    return null;
  }

  const date = new Date(isoString);
  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
    timeZoneName: "shortOffset",
  }).format(date);
}

async function main() {
  let auth;
  try {
    auth = JSON.parse(fs.readFileSync(authPath, "utf8"));
  } catch (error) {
    fail(`Unable to read Codex auth file at ${authPath}`, { detail: error.message });
    return;
  }

  const accessToken = auth.tokens?.access_token;
  const accountId = auth.tokens?.account_id;

  if (!accessToken || !accountId) {
    fail("Codex auth file did not contain ChatGPT access_token and account_id");
    return;
  }

  let response;
  try {
    response = await fetch(endpoint, {
      headers: {
        authorization: `Bearer ${accessToken}`,
        "chatgpt-account-id": accountId,
        "openai-account-id": accountId,
        "oai-account-id": accountId,
        "user-agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Codex reset-credits Safari/537.36",
        accept: "application/json, text/plain, */*",
        origin: "https://chatgpt.com",
        referer: "https://chatgpt.com/codex/settings/usage",
      },
    });
  } catch (error) {
    fail("Request to ChatGPT reset-credit endpoint failed", { detail: error.message });
    return;
  }

  const contentType = response.headers.get("content-type") || "";
  const body = await response.text();

  if (!response.ok) {
    fail("ChatGPT reset-credit endpoint returned a non-2xx status", {
      status: response.status,
      contentType,
      bodyPreview: sanitize(body).slice(0, 800),
    });
    return;
  }

  let json;
  try {
    json = JSON.parse(body);
  } catch (error) {
    fail("ChatGPT reset-credit endpoint did not return JSON", {
      status: response.status,
      contentType,
      bodyPreview: sanitize(body).slice(0, 800),
    });
    return;
  }

  const credits = Array.isArray(json.credits) ? json.credits : [];
  const sanitizedCredits = credits.map((credit) => ({
    reset_type: credit.reset_type ?? null,
    granted_at: credit.granted_at ?? null,
    expires_at: credit.expires_at ?? null,
    expires_local: formatLocal(credit.expires_at),
  }));

  console.log(
    JSON.stringify(
      sanitize({
        ok: true,
        endpoint,
        timeZone,
        available_count: json.available_count ?? sanitizedCredits.length,
        total_earned_count: json.total_earned_count ?? null,
        credits: sanitizedCredits,
      }),
      null,
      2,
    ),
  );
}

await main();
