import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "../..");
const webDir = path.resolve(__dirname, "..");

const versionTxtPath = path.join(rootDir, "version.txt");
const manifestPath = path.join(rootDir, ".release-please-manifest.json");
const webVersionJsonPath = path.join(webDir, "lib", "version.json");
const webPackageJsonPath = path.join(webDir, "package.json");

let currentVersion = "0.1.0";

if (fs.existsSync(versionTxtPath)) {
  const content = fs.readFileSync(versionTxtPath, "utf8").trim();
  if (content) {
    currentVersion = content;
  }
} else if (fs.existsSync(manifestPath)) {
  try {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    if (manifest["."]) {
      currentVersion = manifest["."];
    }
  } catch (err) {
    console.warn("Could not parse .release-please-manifest.json", err);
  }
}

// 1. Update web/lib/version.json
let versionObj = {
  version: currentVersion,
  repoUrl: "https://github.com/ihusnainalii/SwiftNetworkKit"
};

if (fs.existsSync(webVersionJsonPath)) {
  try {
    const existing = JSON.parse(fs.readFileSync(webVersionJsonPath, "utf8"));
    versionObj = { ...existing, version: currentVersion };
  } catch {}
}

fs.writeFileSync(webVersionJsonPath, JSON.stringify(versionObj, null, 2) + "\n", "utf8");

// 2. Sync web/package.json version
if (fs.existsSync(webPackageJsonPath)) {
  try {
    const pkg = JSON.parse(fs.readFileSync(webPackageJsonPath, "utf8"));
    if (pkg.version !== currentVersion) {
      pkg.version = currentVersion;
      fs.writeFileSync(webPackageJsonPath, JSON.stringify(pkg, null, 2) + "\n", "utf8");
    }
  } catch (err) {
    console.warn("Could not sync package.json", err);
  }
}

console.log(`[sync-version] Synchronized website version to v${currentVersion}`);
