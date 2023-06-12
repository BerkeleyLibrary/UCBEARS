// TODO: unify flash levels across Rails app & between Rails & JS/TS
export type FlashLevelInfo = 'success' | 'notice'
export type FlashLevelWarning = 'warning'
export type FlashLevelError = 'alert' | 'danger' | 'error'
export type FlashLevel = FlashLevelInfo | FlashLevelWarning | FlashLevelError

export type FlashMessage = {
  level: FlashLevel,
  text: string
}
