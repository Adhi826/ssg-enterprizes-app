const fs = require('fs');
const path = require('path');

console.log('🚀 Starting Production Compilation for Netlify...');

const distDir = path.join(__dirname, 'dist');
const distImagesDir = path.join(distDir, 'assets', 'images');

// 1. Create target directories recursively
if (!fs.existsSync(distImagesDir)) {
  fs.mkdirSync(distImagesDir, { recursive: true });
  console.log('📁 Created directory structure: dist/assets/images');
}

// Load local .env file if it exists (for local test builds)
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  try {
    const envContent = fs.readFileSync(envPath, 'utf8');
    envContent.split(/\r?\n/).forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const index = trimmed.indexOf('=');
        if (index > -1) {
          const key = trimmed.substring(0, index).trim();
          const val = trimmed.substring(index + 1).trim();
          if (key && val) {
            process.env[key] = val;
          }
        }
      }
    });
    console.log('📝 Loaded local environment variables from .env file.');
  } catch(e) {
    console.warn('⚠️ Warning: Failed to parse local .env file:', e.message);
  }
}

// 2. Load Environment Variables from Netlify or local process.env
const apiKey = process.env.FIREBASE_API_KEY || '___FIREBASE_API_KEY___';
const projectId = process.env.FIREBASE_PROJECT_ID || '___FIREBASE_PROJECT_ID___';
const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || (projectId && projectId !== '___FIREBASE_PROJECT_ID___' ? `${projectId}.appspot.com` : '___FIREBASE_STORAGE_BUCKET___');
const appId = process.env.FIREBASE_APP_ID || '___FIREBASE_APP_ID___';
const authDomain = projectId && projectId !== '___FIREBASE_PROJECT_ID___' ? `${projectId}.firebaseapp.com` : '___FIREBASE_AUTH_DOMAIN___';

console.log(`🔑 Firebase configuration mapped from environment variables:`);
console.log(`   - Project ID: ${projectId}`);
console.log(`   - Storage Bucket: ${storageBucket}`);
console.log(`   - API Key Status: ${apiKey !== '___FIREBASE_API_KEY___' ? 'POPULATED' : 'NOT CONFIGURED (Fallback enabled)'}`);

// 3. Read index.html and inject configurations
const indexHtmlPath = path.join(__dirname, 'index.html');
if (!fs.existsSync(indexHtmlPath)) {
  console.error('❌ Error: index.html not found in root directory!');
  process.exit(1);
}

let indexContent = fs.readFileSync(indexHtmlPath, 'utf8');

// Replace Firebase configuration placeholders
indexContent = indexContent
  .replace(/___FIREBASE_API_KEY___/g, apiKey)
  .replace(/___FIREBASE_AUTH_DOMAIN___/g, authDomain)
  .replace(/___FIREBASE_PROJECT_ID___/g, projectId)
  .replace(/___FIREBASE_STORAGE_BUCKET___/g, storageBucket)
  .replace(/___FIREBASE_APP_ID___/g, appId);

// Save production index.html
fs.writeFileSync(path.join(distDir, 'index.html'), indexContent, 'utf8');
console.log('✅ Injected environment configuration into dist/index.html successfully.');

// 4. Copy PWA Assets to dist
const filesToCopy = ['manifest.json', 'sw.js'];
filesToCopy.forEach(fileName => {
  const srcPath = path.join(__dirname, fileName);
  const destPath = path.join(distDir, fileName);
  if (fs.existsSync(srcPath)) {
    fs.copyFileSync(srcPath, destPath);
    console.log(`📄 Copied PWA asset: ${fileName}`);
  } else {
    console.warn(`⚠️ Warning: PWA asset ${fileName} not found in root.`);
  }
});

// 5. Copy and duplicate Logo assets to dist and root directories for PWA support
const logoSrcPath = path.join(__dirname, 'assets', 'images', 'logo.png');
if (fs.existsSync(logoSrcPath)) {
  // Copy to dist/assets/images/
  fs.copyFileSync(logoSrcPath, path.join(distImagesDir, 'logo.png'));
  fs.copyFileSync(logoSrcPath, path.join(distImagesDir, 'logo_192.png'));
  fs.copyFileSync(logoSrcPath, path.join(distImagesDir, 'logo_512.png'));
  console.log('🖼️ Copied logo assets to dist/assets/images/');

  // Copy standard PWA icons to dist/ root for production
  fs.copyFileSync(logoSrcPath, path.join(distDir, 'icon-192.png'));
  fs.copyFileSync(logoSrcPath, path.join(distDir, 'icon-512.png'));
  fs.copyFileSync(logoSrcPath, path.join(distDir, 'apple-touch-icon.png'));
  fs.copyFileSync(logoSrcPath, path.join(distDir, 'favicon.ico'));
  console.log('📱 Created PWA icons in dist/ root directory.');

  // Copy standard PWA icons to repository root for local server testing
  fs.copyFileSync(logoSrcPath, path.join(__dirname, 'icon-192.png'));
  fs.copyFileSync(logoSrcPath, path.join(__dirname, 'icon-512.png'));
  fs.copyFileSync(logoSrcPath, path.join(__dirname, 'apple-touch-icon.png'));
  fs.copyFileSync(logoSrcPath, path.join(__dirname, 'favicon.ico'));
  console.log('🏠 Created PWA icons in repository root directory.');
} else {
  console.warn('⚠️ Warning: Original logo.png not found at assets/images/logo.png');
}

// 6. Write Netlify _redirects file
const redirectsContent = '/*    /index.html   200\n';
fs.writeFileSync(path.join(distDir, '_redirects'), redirectsContent, 'utf8');
console.log('🌐 Created SPA redirect configuration in dist/_redirects.');

console.log('🎉 Production compilation successfully finished! The directory dist/ is ready to deploy.');
