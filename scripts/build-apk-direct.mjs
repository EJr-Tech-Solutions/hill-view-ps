import { TwaManifest, TwaGenerator, JdkHelper, KeyTool, AndroidSdkTools, Config } from '@bubblewrap/core';
import { readFile, writeFile } from 'fs/promises';
import { join, resolve } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { createHash } from 'crypto';
import { execSync } from 'child_process';

const PROJECT_DIR = resolve(import.meta.dirname, '..');
const ANDROID_DIR = join(PROJECT_DIR, 'android');
const DOCS_DIR = join(PROJECT_DIR, 'docs');
const ANDROID_HOME = '/opt/android-sdk';
const JAVA_HOME = '/usr/lib/jvm/java-17-openjdk';

// Set env
process.env.ANDROID_HOME = ANDROID_HOME;
process.env.JAVA_HOME = JAVA_HOME;

// Create android directory if needed
if (!existsSync(ANDROID_DIR)) mkdirSync(ANDROID_DIR, { recursive: true });

// Read local twa-manifest
const twaManifest = await TwaManifest.fromFile(join(PROJECT_DIR, 'twa-manifest.json'));

// Fix paths for local build
const manifest = twaManifest;
manifest.signingKey.path = join(ANDROID_DIR, 'android-signing.keystore');
manifest.generatorApp = 'bubblewrap-cli';

// Generate project
const twaGenerator = new TwaGenerator();
const log = { log: console.log, warn: console.warn, error: console.error, info: console.log };
await twaGenerator.createTwaProject(ANDROID_DIR, manifest, log, (c, t) => {});

// Save twa-manifest
await manifest.saveToFile(join(ANDROID_DIR, 'twa-manifest.json'));

// Generate checksum
const manifestContent = await readFile(join(ANDROID_DIR, 'twa-manifest.json'));
const checksum = createHash('sha1').update(manifestContent).digest('hex');
await writeFile(join(ANDROID_DIR, 'manifest-checksum.txt'), checksum);

// Create signing key if not exists
if (!existsSync(manifest.signingKey.path)) {
  const config = new Config('', JAVA_HOME);
  const jdkHelper = new JdkHelper(process, config);
  const keytool = new KeyTool(jdkHelper);
  await keytool.createSigningKey({
    fullName: 'Hill View School',
    organizationalUnit: 'IT',
    organization: 'Hill View Primary School',
    country: 'UG',
    password: 'android',
    keypassword: 'android',
    alias: 'mykey',
    path: manifest.signingKey.path,
  });
  console.log('[INFO] Signing key created');
}

// Build
console.log('[INFO] Building APK...');
const buildResult = execSync('npx bubblewrap build', {
  cwd: ANDROID_DIR,
  env: { ...process.env, JAVA_HOME, ANDROID_HOME },
  stdio: 'pipe',
});
console.log(buildResult.stdout?.toString() || '');
console.error(buildResult.stderr?.toString() || '');

console.log('[INFO] Done!');
