import type { FastifyInstance } from 'fastify'

function healthPayload() {
  return {
    ok: true,
    source: 'kbo-official-spike',
    now: new Date().toISOString()
  }
}

function readinessPayload() {
  return {
    ok: true,
    source: 'kbo-official-spike',
    checks: {
      config: true
    },
    now: new Date().toISOString()
  }
}

export function registerHealthRoutes(server: FastifyInstance) {
  server.get('/health', async () => {
    return healthPayload()
  })

  server.get('/v1/health', async () => {
    return healthPayload()
  })

  server.get('/ready', async () => {
    return readinessPayload()
  })

  server.get('/v1/ready', async () => {
    return readinessPayload()
  })
}
