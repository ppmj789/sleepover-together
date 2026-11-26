# sleepover-together

영종도 1박 2일 수련활동(2026. 12. 11.~12.) 온라인 참가 동의서입니다.
화면은 GitHub Pages로 올리고, 응답은 Supabase에 저장합니다.

- 참가자용: `https://ppmj789.github.io/sleepover-together/`
- 진행자용 (퀴즈 결과 공개): `https://ppmj789.github.io/sleepover-together/host.html` ← 참가자에게 공유 금지

```
index.html        참가 동의서 (이름 · O/X 8문항 · 지목 투표 4개 · 선물 약속)
host.html         퀴즈 진행 화면 (진행자 코드 입력 → 문항별 'O 몇 명?' / 투표 1~3위 공개)
config.js         ★ Supabase URL · 키 · 선물 상한 · 마감 시각
questions.js      퀴즈 문구 (문구는 수정 가능, id는 바꾸지 마세요)
style.css         가정통신문 스타일
supabase/schema.sql
```

## 1. Supabase (설정 완료)

- 프로젝트: **UntoldChapters** (`kkkmsnyiwliovitsmsmw`) 에 `mt_rsvp`, `mt_config` 테이블과 함수 3개를 추가했습니다. 기존 테이블은 건드리지 않았습니다.
- `config.js` 에 Project URL과 Publishable key가 들어 있습니다 (공개용 키라 노출돼도 괜찮습니다).
- 진행자 코드: **`unseo-8352`** (host.html 에서 입력)

다른 프로젝트에 새로 깔 때만 `supabase/schema.sql` 을 SQL Editor 에서 실행하세요.

## 2. GitHub Pages

```bash
git clone https://github.com/ppmj789/sleepover-together.git
# 이 폴더 내용을 전부 복사해 넣고
git add . && git commit -m "참가 동의서" && git push
```

저장소 **Settings → Pages → Build and deployment**
- Source: **Deploy from a branch**
- Branch: **main** / **/(root)** → Save

1~2분 뒤 `https://ppmj789.github.io/sleepover-together/` 에서 열립니다.

## 3. 보안 / 공개 범위

| 데이터 | 누가 볼 수 있나 |
|---|---|
| 제출한 사람 이름 | 누구나 (동의서 하단 현황) |
| O/X 개별 답, 누구를 지목했는지, 선물 힌트 | Supabase 대시보드 관리자만 |
| O/X 인원수, 투표 순위 | 진행자 코드를 아는 사람 (host.html) |

- 비밀번호 없이 **이름으로만** 구분합니다. 같은 이름으로 다시 내면 덮어씁니다.
  남의 이름으로 내려고 하면 "이미 제출된 이름, 덮어쓸까요?" 확인 창이 뜹니다.
- 같은 기기에서 다시 열면 마지막에 낸 답이 채워져 있어 수정이 편합니다.

## 4. 운영 팁

- **응답 원본 보기 / CSV**: Table Editor → `mt_rsvp`
- **잘못 낸 응답 삭제**: `mt_rsvp` 에서 해당 행 삭제
- **진행자 코드 변경**: `update mt_config set value = '새코드' where key = 'host_code';`
- **퀴즈 문구 수정**: `questions.js` 의 `text` 만 고쳐서 푸시 (id는 그대로)
- 무료 플랜 프로젝트는 오래 안 쓰면 일시정지될 수 있으니, 당일 전에 대시보드에서 Active 인지 확인하세요.
