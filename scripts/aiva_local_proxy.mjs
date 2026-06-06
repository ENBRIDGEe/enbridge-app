import { createServer } from 'node:http';
import { existsSync } from 'node:fs';
import { readFile } from 'node:fs/promises';

const PORT = Number(process.env.AIVA_PROXY_PORT ?? 8787);
const CONFIG_PATH = process.env.AIVA_ENV_FILE ?? '.env.json';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

async function loadApiKey() {
  if (process.env.NVIDIA_API_KEY) {
    return process.env.NVIDIA_API_KEY;
  }

  if (!existsSync(CONFIG_PATH)) {
    return '';
  }

  try {
    const raw = await readFile(CONFIG_PATH, 'utf8');
    const parsed = JSON.parse(raw);
    return String(parsed.NVIDIA_API_KEY ?? '');
  } catch {
    return '';
  }
}

const nvidiaApiKey = await loadApiKey();

if (!nvidiaApiKey) {
  throw new Error(
    'NVIDIA_API_KEY not found. Add it to .env.json or set the NVIDIA_API_KEY environment variable.',
  );
}

function writeJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    ...corsHeaders,
    'Content-Type': 'application/json',
  });
  res.end(JSON.stringify(payload));
}

const server = createServer(async (req, res) => {
  if (!req.url) {
    writeJson(res, 400, { error: 'Missing request URL' });
    return;
  }

  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  if (req.method !== 'POST' || req.url !== '/aiva-chat') {
    writeJson(res, 404, { error: 'Not found' });
    return;
  }

  try {
    let rawBody = '';
    for await (const chunk of req) {
      rawBody += chunk;
    }

    const body = JSON.parse(rawBody || '{}');

    const upstream = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${nvidiaApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const text = await upstream.text();
    res.writeHead(upstream.status, {
      ...corsHeaders,
      'Content-Type': 'application/json',
    });
    res.end(text);
  } catch (error) {
    writeJson(res, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`AIVA local proxy listening on http://127.0.0.1:${PORT}/aiva-chat`);
});
