import Fastify from 'fastify'

import { registerGamesRoutes } from './routes/games.js'
import { registerHealthRoutes } from './routes/health.js'
import { KboDateInputError } from './utils/date.js'

type ApiErrorCode = 'INVALID_DATE' | 'INTERNAL_ERROR'

function apiError(code: ApiErrorCode, message: string, statusCode: number) {
  return {
    error: {
      code,
      message,
      statusCode
    }
  }
}

export function buildServer() {
  const server = Fastify({
    logger: {
      transport: process.env.NODE_ENV === 'production'
        ? undefined
        : {
            target: 'pino-pretty',
            options: {
              translateTime: 'SYS:standard',
              ignore: 'pid,hostname'
            }
          }
    }
  })

  registerHealthRoutes(server)
  registerGamesRoutes(server)

  server.setErrorHandler((error, request, reply) => {
    if (error instanceof KboDateInputError) {
      request.log.warn({ error }, 'invalid KBO date input')
      void reply.status(400).send(apiError('INVALID_DATE', error.message, 400))
      return
    }

    request.log.error({ error }, 'request failed')
    void reply.status(500).send(apiError(
      'INTERNAL_ERROR',
      error instanceof Error ? error.message : String(error),
      500
    ))
  })

  return server
}
