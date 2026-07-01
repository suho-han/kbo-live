import { z } from 'zod'

export const rawKboTableCellSchema = z.object({
  Text: z.string().optional().nullable(),
  Class: z.string().optional().nullable()
}).passthrough()

export const rawKboTableRowSchema = z.object({
  row: z.array(rawKboTableCellSchema)
}).passthrough()

export const rawKboPitcherRecordAnalysisResponseSchema = z.object({
  rows: z.array(rawKboTableRowSchema),
  code: z.string().optional().nullable(),
  msg: z.string().optional().nullable()
}).passthrough()

export type RawKboPitcherRecordAnalysisResponse = z.infer<typeof rawKboPitcherRecordAnalysisResponseSchema>
