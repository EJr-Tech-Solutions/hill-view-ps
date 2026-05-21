import { TwaManifest, TwaGenerator, Config, JdkHelper, KeyTool } from '@bubblewrap/core';
import { readFile, writeFile } from 'fs/promises';
import { join, resolve } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { createHash } from 'crypto';
import { execSync } from 'child_process';

const PROJECT_DIR = resolve(import.meta.dirname, '..');
const ANDROID_DIR = join(PROJECT_DIR, 'android');
const ANDROID_HOME = '/opt/android-sdk';
const JAVA_HOME = '/usr/lib/jvm/java-17-openjdk';

process.env.ANDROID_HOME = ANDROID_HOME;
process.env.JAVA_HOME = JAVA_HOME;

if (existsSync(ANDROID_DIR)) {
  execSync(`rm -rf "${ANDROID_DIR}"`, { stdio: 'pipe' });
}
mkdirSync(ANDROID_DIR, { recursive: true });

const twaManifest = await TwaManifest.fromFile(join(PROJECT_DIR, 'twa-manifest.json'));
twaManifest.signingKey.path = join(ANDROID_DIR, 'android-signing.keystore');
twaManifest.signingKey.alias = 'mykey';
twaManifest.generatorApp = 'bubblewrap-cli';

const config = new Config(JAVA_HOME, ANDROID_HOME);
const jdkHelper = new JdkHelper(process, config);
const twaGenerator = new TwaGenerator();
const log = { log: console.log, warn: console.warn, error: console.error, info: () => {} };

console.log('[INFO] Generating Android project...');
let progress = 0;
await twaGenerator.createTwaProject(ANDROID_DIR, twaManifest, log, (c, t) => { progress = c / t * 100; });

console.log('[INFO] Saving manifest...');
await twaManifest.saveToFile(join(ANDROID_DIR, 'twa-manifest.json'));

console.log('[INFO] Creating checksum...');
const manifestContent = await readFile(join(ANDROID_DIR, 'twa-manifest.json'));
const checksum = createHash('sha1').update(manifestContent).digest('hex');
await writeFile(join(ANDROID_DIR, 'manifest-checksum.txt'), checksum);

if (!existsSync(twaManifest.signingKey.path)) {
  console.log('[INFO] Creating signing key...');
  const keytool = new KeyTool(jdkHelper);
  await keytool.createSigningKey({
    fullName: 'Hill View School',
    organizationalUnit: 'IT',
    organization: 'Hill View Primary School',
    country: 'UG',
    password: 'android',
    keypassword: 'android',
    alias: 'mykey',
    path: twaManifest.signingKey.path,
  });
}

console.log('[INFO] TWA project initialized in android/');
