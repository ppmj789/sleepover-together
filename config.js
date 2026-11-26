// ============== 설정 (여기만 고치면 됩니다) ==============
export const CONFIG = {
  // Supabase → Project Settings → API
  SUPABASE_URL: 'https://kkkmsnyiwliovitsmsmw.supabase.co',
  // anon public 키 또는 sb_publishable_… 키 (service_role / secret 키는 절대 넣지 마세요)
  SUPABASE_KEY: 'sb_publishable_XivLnC4gw_Zn31IuzL0n_Q_pC236XIT',

  GIFT_LIMIT: 20000,                       // 선물 상한 (원, 미만)
  DEADLINE: '2026-12-09T23:59:59+09:00',   // 이 시각 이후 제출 버튼이 '마감'
};
