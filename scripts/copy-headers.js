#!/usr/bin/env node

/**
 * Script to copy sherpa-onnx header files to Android and iOS include directories.
 * This ensures that the headers are available when the package is published to npm,
 * even if the git submodule is not initialized.
 */

const fs = require('fs');
const path = require('path');

const SOURCE_DIR = path.join(
  __dirname,
  '..',
  'sherpa-onnx',
  'sherpa-onnx',
  'c-api'
);
const ANDROID_DEST_DIR = path.join(
  __dirname,
  '..',
  'android',
  'src',
  'main',
  'cpp',
  'include',
  'sherpa-onnx',
  'c-api'
);
const IOS_DEST_DIR = path.join(
  __dirname,
  '..',
  'ios',
  'include',
  'sherpa-onnx',
  'c-api'
);

const HEADER_FILES = ['c-api.h', 'cxx-api.h'];

function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`Created directory: ${dirPath}`);
  }
}

function copyFile(source, destination) {
  try {
    fs.copyFileSync(source, destination);
    console.log(
      `✓ Copied: ${path.basename(source)} -> ${path.relative(
        process.cwd(),
        destination
      )}`
    );
    return true;
  } catch (error) {
    console.error(`✗ Failed to copy ${source}:`, error.message);
    return false;
  }
}

function main() {
  console.log('Copying sherpa-onnx header files...\n');

  // Check if source directory exists
  if (!fs.existsSync(SOURCE_DIR)) {
    console.error(`Error: Source directory not found: ${SOURCE_DIR}`);
    console.error(
      'Please ensure the sherpa-onnx git submodule is initialized.'
    );
    console.error('Run: git submodule update --init --recursive');
    process.exit(1);
  }

  // Ensure destination directories exist
  ensureDirectoryExists(ANDROID_DEST_DIR);
  ensureDirectoryExists(IOS_DEST_DIR);

  let successCount = 0;
  let failCount = 0;

  // Copy header files to Android
  console.log('Copying to Android...');
  for (const headerFile of HEADER_FILES) {
    const source = path.join(SOURCE_DIR, headerFile);
    const destination = path.join(ANDROID_DEST_DIR, headerFile);

    if (!fs.existsSync(source)) {
      console.error(`✗ Source file not found: ${source}`);
      failCount++;
      continue;
    }

    if (copyFile(source, destination)) {
      successCount++;
    } else {
      failCount++;
    }
  }

  // Copy header files to iOS
  console.log('\nCopying to iOS...');
  for (const headerFile of HEADER_FILES) {
    const source = path.join(SOURCE_DIR, headerFile);
    const destination = path.join(IOS_DEST_DIR, headerFile);

    if (!fs.existsSync(source)) {
      console.error(`✗ Source file not found: ${source}`);
      failCount++;
      continue;
    }

    if (copyFile(source, destination)) {
      successCount++;
    } else {
      failCount++;
    }
  }

  console.log(`\n${'='.repeat(50)}`);
  console.log(
    `Summary: ${successCount} files copied successfully, ${failCount} failed`
  );

  if (failCount > 0) {
    process.exit(1);
  } else {
    console.log('✓ All header files copied successfully!');
  }
}

main();
