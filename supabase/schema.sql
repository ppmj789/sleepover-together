-- =====================================================================
-- sleepover-together · 영종도 수련활동 온라인 참가 동의서
-- Supabase 대시보드 → SQL Editor → New query → 전체 붙여넣고 Run (한 번만)
--
-- ★ 실행 전에 맨 아래 '진행자 코드'를 원하는 값으로 바꾸세요. (퀴즈 결과 공개 페이지용)
--
-- 테이블 (다른 프로젝트와 겹치지 않게 mt_ 접두어)
--   mt_rsvp   : 응답 (이름 기준, 같은 이름으로 다시 내면 덮어씀)
--   mt_config : 진행자 코드
-- 보안
--   두 테이블 모두 RLS를 켜고 anon 직접 접근을 막음. 브라우저는 아래 함수만 호출 가능:
--     mt_submit   : 제출 / 덮어쓰기
--     mt_board    : 제출한 사람 이름 목록 (답은 안 보임)
--     mt_results  : 진행자 코드가 맞을 때만 문항별 인원수 · 투표 집계 (개인 답은 안 나옴)
-- =====================================================================

create table if not exists public.mt_rsvp (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 20),
  name_key    text not null,
  gift_ok     boolean not null,
  gift_hint   text check (char_length(gift_hint) <= 100),
  ox          jsonb not null default '{}'::jsonb,   -- {"q1": true, "q2": false, ...}  true = O
  votes       jsonb not null default '{}'::jsonb,   -- {"v1": "홍길동", ...}
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create unique index if not exists mt_rsvp_name_key_idx on public.mt_rsvp (name_key);

create table if not exists public.mt_config (
  key    text primary key,
  value  text not null
);

alter table public.mt_rsvp   enable row level security;
alter table public.mt_config enable row level security;
revoke all on public.mt_rsvp, public.mt_config from anon, authenticated;

-- 이름 정규화: 공백 제거 + 소문자
create or replace function public.mt_name_key(p text)
returns text language sql immutable as $$
  select lower(regexp_replace(coalesce(p, ''), '\s', '', 'g'))
$$;

-- ---------- 제출 / 덮어쓰기 ----------
create or replace function public.mt_submit(
  p_name      text,
  p_gift_ok   boolean,
  p_gift_hint text  default null,
  p_ox        jsonb default '{}'::jsonb,
  p_votes     jsonb default '{}'::jsonb
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key    text := public.mt_name_key(p_name);
  v_votes  jsonb := '{}'::jsonb;
  v_exists boolean;
  r        record;
begin
  if v_key = '' or char_length(trim(p_name)) > 20 then
    raise exception '이름을 1~20자로 입력해 주세요.';
  end if;
  if coalesce(p_gift_ok, false) is not true then
    raise exception '선물 준비(2만원 미만)에 체크해 주세요.';
  end if;

  if jsonb_typeof(coalesce(p_ox, '{}'::jsonb)) <> 'object' then
    raise exception 'O/X 답 형식이 잘못됐어요.';
  end if;
  for r in select * from jsonb_each(coalesce(p_ox, '{}'::jsonb)) loop
    if r.key !~ '^q[0-9]{1,2}$' or jsonb_typeof(r.value) <> 'boolean' then
      raise exception 'O/X 답 형식이 잘못됐어요.';
    end if;
  end loop;

  if jsonb_typeof(coalesce(p_votes, '{}'::jsonb)) <> 'object' then
    raise exception '투표 형식이 잘못됐어요.';
  end if;
  for r in select * from jsonb_each_text(coalesce(p_votes, '{}'::jsonb)) loop
    if r.key !~ '^v[0-9]{1,2}$' or char_length(r.value) > 20 then
      raise exception '투표는 이름(20자 이내)으로 적어 주세요.';
    end if;
    if trim(r.value) <> '' then
      v_votes := v_votes || jsonb_build_object(r.key, trim(r.value));
    end if;
  end loop;

  select exists(select 1 from public.mt_rsvp where name_key = v_key) into v_exists;

  insert into public.mt_rsvp (name, name_key, gift_ok, gift_hint, ox, votes)
  values (trim(p_name), v_key, true, nullif(trim(p_gift_hint), ''), coalesce(p_ox, '{}'::jsonb), v_votes)
  on conflict (name_key) do update set
    name       = excluded.name,
    gift_ok    = excluded.gift_ok,
    gift_hint  = excluded.gift_hint,
    ox         = excluded.ox,
    votes      = excluded.votes,
    updated_at = now();

  return case when v_exists then 'updated' else 'created' end;
end;
$$;

-- ---------- 제출 현황 (이름만) ----------
create or replace function public.mt_board()
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'count', (select count(*) from public.mt_rsvp),
    'names', coalesce((select json_agg(name order by created_at) from public.mt_rsvp), '[]'::json)
  )
$$;

-- ---------- 퀴즈 결과 (진행자용, 집계만) ----------
create or replace function public.mt_results(p_code text)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  select value into v_code from public.mt_config where key = 'host_code';
  if v_code is null or v_code = '여기에-진행자-코드' then
    raise exception '진행자 코드가 아직 설정되지 않았어요. (mt_config 테이블)';
  end if;
  if coalesce(p_code, '') <> v_code then
    raise exception '진행자 코드가 맞지 않아요.';
  end if;

  return json_build_object(
    'total', (select count(*) from public.mt_rsvp),
    'ox', coalesce((
      select json_object_agg(key, json_build_object('o', o, 'x', x))
        from (select e.key,
                     count(*) filter (where e.value = 'true'::jsonb)  as o,
                     count(*) filter (where e.value = 'false'::jsonb) as x
                from public.mt_rsvp, jsonb_each(ox) e
               group by e.key) s
    ), '{}'::json),
    'votes', coalesce((
      select json_object_agg(key, ranking)
        from (select key, json_agg(json_build_object('name', name, 'count', cnt) order by cnt desc, name) as ranking
                from (select e.key, min(e.value) as name, count(*) as cnt
                        from public.mt_rsvp, jsonb_each_text(votes) e
                       group by e.key, public.mt_name_key(e.value)) t
               group by key) s
    ), '{}'::json)
  );
end;
$$;

revoke all on function public.mt_submit(text, boolean, text, jsonb, jsonb) from public;
revoke all on function public.mt_board() from public;
revoke all on function public.mt_results(text) from public;
grant execute on function public.mt_submit(text, boolean, text, jsonb, jsonb) to anon, authenticated;
grant execute on function public.mt_board() to anon, authenticated;
grant execute on function public.mt_results(text) to anon, authenticated;
grant execute on function public.mt_name_key(text) to anon, authenticated;

-- ---------- ★ 진행자 코드 (퀴즈 결과 페이지 host.html 에서 입력) ----------
insert into public.mt_config (key, value)
values ('host_code', 'unseo-8352')
on conflict (key) do nothing;
-- 나중에 바꾸려면:  update public.mt_config set value = '새코드' where key = 'host_code';
