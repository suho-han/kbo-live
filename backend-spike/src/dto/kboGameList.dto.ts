import { z } from 'zod'

export const rawKboGameSchema = z.object({
  G_ID: z.string(),
  G_DT: z.string().optional().nullable(),
  G_TM: z.string().optional().nullable(),
  S_NM: z.string().optional().nullable(),
  AWAY_ID: z.string().optional().nullable(),
  HOME_ID: z.string().optional().nullable(),
  AWAY_NM: z.string().optional().nullable(),
  HOME_NM: z.string().optional().nullable(),
  T_PIT_P_NM: z.string().optional().nullable(),
  B_PIT_P_NM: z.string().optional().nullable(),
  T_PIT_P_ID: z.union([z.string(), z.number()]).optional().nullable(),
  B_PIT_P_ID: z.union([z.string(), z.number()]).optional().nullable(),
  W_PIT_P_NM: z.string().optional().nullable(),
  L_PIT_P_NM: z.string().optional().nullable(),
  SV_PIT_P_NM: z.string().optional().nullable(),
  T_RANK_NO: z.union([z.string(), z.number()]).optional().nullable(),
  B_RANK_NO: z.union([z.string(), z.number()]).optional().nullable(),
  GAME_STATE_SC: z.string().optional().nullable(),
  GAME_INN_NO: z.union([z.string(), z.number()]).optional().nullable(),
  GAME_TB_SC: z.string().optional().nullable(),
  T_SCORE_CN: z.union([z.string(), z.number()]).optional().nullable(),
  B_SCORE_CN: z.union([z.string(), z.number()]).optional().nullable(),
  STRIKE_CN: z.union([z.string(), z.number()]).optional().nullable(),
  BALL_CN: z.union([z.string(), z.number()]).optional().nullable(),
  OUT_CN: z.union([z.string(), z.number()]).optional().nullable(),
  B1_BAT_ORDER_NO: z.union([z.string(), z.number()]).optional().nullable(),
  B2_BAT_ORDER_NO: z.union([z.string(), z.number()]).optional().nullable(),
  B3_BAT_ORDER_NO: z.union([z.string(), z.number()]).optional().nullable(),
  T_P_NM: z.string().optional().nullable(),
  B_P_NM: z.string().optional().nullable(),
  RECENT_PLAY: z.string().optional().nullable(),
  RECENT_PLAY_TEXT: z.string().optional().nullable(),
  LAST_PLAY: z.string().optional().nullable(),
  LAST_PLAY_TEXT: z.string().optional().nullable(),
  LIVE_TEXT: z.string().optional().nullable(),
  GAME_TEXT: z.string().optional().nullable(),
  LE_ID: z.union([z.string(), z.number()]).optional().nullable(),
  SR_ID: z.union([z.string(), z.number()]).optional().nullable(),
  SEASON_ID: z.union([z.string(), z.number()]).optional().nullable(),
  START_PIT_CK: z.union([z.string(), z.number()]).optional().nullable()
}).passthrough()

export const rawKboGameListResponseSchema = z.object({
  game: z.array(rawKboGameSchema)
}).passthrough()

export type RawKboGame = z.infer<typeof rawKboGameSchema>
export type RawKboGameListResponse = z.infer<typeof rawKboGameListResponseSchema>
