import { promises as fs } from 'fs';
import os from 'os';
import path from 'path';
import { spawn } from 'child_process';

import { getUserById } from '../db/users';
import { CUSTOM_USER_VOICE_ID } from './constants';

const customVoicePythonBin =
  process.env.CUSTOM_VOICE_PYTHON_BIN ||
  '/opt/masalevi/xtts-venv/bin/python';

async function runPythonClone(input: {
  samplePath: string;
  text: string;
}): Promise<Buffer> {
  const scriptPath = path.resolve(process.cwd(), 'scripts', 'clone_voice.py');
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'masalevi-xtts-'));
  const textPath = path.join(tempDir, 'input.txt');
  const outputPath = path.join(tempDir, 'output.mp3');
  await fs.writeFile(textPath, input.text, 'utf8');

  try {
    await new Promise<void>((resolve, reject) => {
      const child = spawn(customVoicePythonBin, [
        scriptPath,
        '--speaker',
        input.samplePath,
        '--text-file',
        textPath,
        '--output',
        outputPath,
        '--language',
        'tr',
      ]);

      let stderr = '';
      child.stderr.on('data', (chunk) => {
        stderr += String(chunk);
      });

      child.on('error', (error) => reject(error));
      child.on('close', (code) => {
        if (code === 0) {
          resolve();
          return;
        }
        reject(
          new Error(
            stderr.trim().length === 0
                ? `Custom voice clone failed with code ${code ?? -1}`
                : stderr.trim(),
          ),
        );
      });
    });

    return await fs.readFile(outputPath);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

export async function synthesizeSpeechWithCustomVoice(input: {
  userId: string;
  text: string;
}): Promise<string | null> {
  const user = await getUserById(input.userId);
  if (!user?.custom_voice_sample_path) {
    throw new Error('Kullanici ses ornegi bulunamadi.');
  }

  try {
    await fs.access(user.custom_voice_sample_path);
  } catch (_) {
    throw new Error('Kayitli ses ornegi dosyasi bulunamadi.');
  }

  console.info(
    '[custom-voice] synthesis started',
    JSON.stringify({
      userId: input.userId,
      textLength: input.text.length,
    }),
  );
  const audioBuffer = await runPythonClone({
    samplePath: user.custom_voice_sample_path,
    text: input.text,
  });
  console.info(
    '[custom-voice] synthesis finished',
    JSON.stringify({
      userId: input.userId,
      byteLength: audioBuffer.byteLength,
    }),
  );
  return audioBuffer.toString('base64');
}
