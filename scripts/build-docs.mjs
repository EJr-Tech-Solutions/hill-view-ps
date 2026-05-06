import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { config } from 'dotenv';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(__dirname, '..');

// Load .env.local (local dev) — Netlify injects env vars directly
config({ path: resolve(rootDir, '.env.local'), optional: true });

const env = (key) => process.env[key] || '';

const template = readFileSync(resolve(rootDir, 'docs/index.template.html'), 'utf-8');

const output = template
  .replace(/__SUPA_URL__/g, env('NEXT_PUBLIC_SUPABASE_URL'))
  .replace(/__SUPA_KEY__/g, env('NEXT_PUBLIC_SUPABASE_ANON_KEY'))
  .replace(/__CLOUDINARY_CLOUD_NAME__/g, env('CLOUDINARY_CLOUD_NAME'))
  .replace(/__CLOUDINARY_API_KEY__/g, env('CLOUDINARY_API_KEY'))
  .replace(/__CLOUDINARY_API_SECRET__/g, env('CLOUDINARY_API_SECRET'));

writeFileSync(resolve(rootDir, 'docs/index.html'), output, 'utf-8');

console.log('[build-docs] docs/index.html generated from env vars');
