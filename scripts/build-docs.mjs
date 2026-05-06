import { copyFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(__dirname, '..');

copyFileSync(resolve(rootDir, 'docs/index.template.html'), resolve(rootDir, 'docs/index.html'));

console.log('[build-docs] docs/index.html copied from template');
