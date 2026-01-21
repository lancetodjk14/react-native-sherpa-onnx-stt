/**
 * Configuration for test audio files.
 * Audio files should be placed in:
 * - Android: android/app/src/main/assets/test_wavs/
 * - iOS: Add to Xcode project as folder reference in test_wavs/
 */

export const TEST_AUDIO_FILES = {
  // English test files (for Zipformer model)
  EN_1: 'test_wavs/0-en.wav',
  EN_2: 'test_wavs/1-en.wav',
  EN_3: 'test_wavs/8k-en.wav',

  // Chinese test files (for Paraformer model)
  ZH_1: 'test_wavs/0-zh.wav',
  ZH_2: 'test_wavs/1-zh.wav',
  ZH_3: 'test_wavs/8k-zh.wav',

  // Mixed language files (for Paraformer model)
  ZH_EN_1: 'test_wavs/2-zh-en.wav',
} as const;

export type AudioFileId =
  (typeof TEST_AUDIO_FILES)[keyof typeof TEST_AUDIO_FILES];

export interface AudioFileInfo {
  id: AudioFileId;
  name: string;
  description: string;
  language: 'en' | 'zh';
}

export const AUDIO_FILES: AudioFileInfo[] = [
  {
    id: TEST_AUDIO_FILES.EN_1,
    name: 'English Sample 1',
    description: 'English audio sample 1',
    language: 'en',
  },
  {
    id: TEST_AUDIO_FILES.EN_2,
    name: 'English Sample 2',
    description: 'English audio sample 2',
    language: 'en',
  },
  {
    id: TEST_AUDIO_FILES.EN_3,
    name: 'English Sample 3',
    description: 'English audio sample 3',
    language: 'en',
  },
  {
    id: TEST_AUDIO_FILES.ZH_1,
    name: '中文样本 1',
    description: 'Chinese audio sample 1',
    language: 'zh',
  },
  {
    id: TEST_AUDIO_FILES.ZH_2,
    name: '中文样本 2',
    description: 'Chinese audio sample 2',
    language: 'zh',
  },
  {
    id: TEST_AUDIO_FILES.ZH_3,
    name: '中文样本 3',
    description: 'Chinese audio sample 3',
    language: 'zh',
  },
  {
    id: TEST_AUDIO_FILES.ZH_EN_1,
    name: '中英混合样本',
    description: 'Chinese-English mixed audio sample',
    language: 'zh', // Paraformer supports both, so we can categorize it as 'zh'
  },
];

/**
 * Get audio files compatible with the given model
 * - Zipformer: English files only
 * - Paraformer: All files (English and Chinese) - supports both languages
 * - NeMo CTC: English files only
 */
export function getAudioFilesForModel(modelId: string): AudioFileInfo[] {
  const isParaformer = modelId.includes('paraformer');
  const isZipformer = modelId.includes('zipformer');
  const isNemoCtc = modelId.includes('nemo') || modelId.includes('ctc');
  const isEnglish = modelId.includes('en') && !isParaformer;

  // Paraformer supports both English and Chinese
  if (isParaformer) {
    return AUDIO_FILES;
  }

  // Zipformer and NeMo CTC support only English
  if (isZipformer || isNemoCtc || isEnglish) {
    return AUDIO_FILES.filter((file) => file.language === 'en');
  }

  // Default: return Chinese files (for other models)
  return AUDIO_FILES.filter((file) => file.language === 'zh');
}
