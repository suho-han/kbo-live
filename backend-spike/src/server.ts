import Fastify from 'fastify'

import { registerGamesRoutes } from './routes/games.js'
import { registerHealthRoutes } from './routes/health.js'
import { KboDateInputError } from './utils/date.js'

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
      void reply.status(400).send({
        error: 'Bad Request',
        message: error.message
      })
      return
    }

    request.log.error({ error }, 'request failed')
    void reply.status(500).send({
      error: 'Internal Server Error',
      message: error instanceof Error ? error.message : String(error)
    })
  })

  return server
}
