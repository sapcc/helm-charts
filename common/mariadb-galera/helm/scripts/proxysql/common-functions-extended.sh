MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}
