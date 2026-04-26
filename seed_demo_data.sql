-- CreatorNote Demo Seed Data
-- Supabase SQL Editor에서 실행하세요
-- cshoon80@gmail.com 계정 기준

-- 1) user_id, workspace_id 자동 조회
DO $$
DECLARE
  v_user_id uuid;
  v_workspace_id uuid;
  v_sp1 uuid; v_sp2 uuid; v_sp3 uuid; v_sp4 uuid; v_sp5 uuid;
  v_sp6 uuid; v_sp7 uuid; v_sp8 uuid; v_sp9 uuid; v_sp10 uuid;
BEGIN
  -- 유저 조회
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'cshoon80@gmail.com' LIMIT 1;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'cshoon80@gmail.com 유저를 찾을 수 없습니다';
  END IF;

  -- 워크스페이스 조회
  SELECT workspace_id INTO v_workspace_id FROM public.workspace_members WHERE user_id = v_user_id LIMIT 1;
  IF v_workspace_id IS NULL THEN
    RAISE EXCEPTION '워크스페이스를 찾을 수 없습니다';
  END IF;

  -- 기존 데모 데이터 정리 (선택사항 - 필요시 주석 해제)
  -- DELETE FROM public.settlements WHERE workspace_id = v_workspace_id;
  -- DELETE FROM public.reels_notes WHERE workspace_id = v_workspace_id;
  -- DELETE FROM public.general_notes WHERE workspace_id = v_workspace_id;
  -- DELETE FROM public.sponsorships WHERE workspace_id = v_workspace_id;

  -- ============================================================
  -- 2) 협찬 (Sponsorships) - 다양한 상태, 10개
  -- ============================================================

  -- 완료 (completed)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '올리브영', '글로우 에디션 세럼',
    '제품 리뷰 릴스 1건 + 스토리 2건. 올리브영 공식 계정 태그 필수. #올리브영추천 해시태그 포함.',
    1500000, '2026-03-01', '2026-03-31', 'completed', false, '2026-03-01')
  RETURNING id INTO v_sp1;

  -- 완료 (completed)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '무신사', '여름 룩북 촬영',
    '무신사 스탠다드 여름 컬렉션 룩북. 릴스 2건 + 피드 1건. 의상 3벌 협찬.',
    2000000, '2026-03-10', '2026-04-10', 'completed', false, '2026-03-10')
  RETURNING id INTO v_sp2;

  -- 정산 대기 (pendingSettlement)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '삼성전자', '갤럭시 Z 플립6',
    '갤럭시 Z 플립6 언박싱 + 일상 브이로그. 릴스 1건 + 유튜브 숏츠 1건. 삼성 공식 태그.',
    3000000, '2026-04-01', '2026-04-20', 'pendingSettlement', true, '2026-04-01')
  RETURNING id INTO v_sp3;

  -- 정산 대기 (pendingSettlement)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '아모레퍼시픽', '설화수 자음생 크림',
    '설화수 자음생 라인 리뷰. 릴스 1건 + 스토리 3건. 30대 타겟 뷰티 콘텐츠.',
    1800000, '2026-04-05', '2026-04-22', 'pendingSettlement', false, '2026-04-05')
  RETURNING id INTO v_sp4;

  -- 제출완료 (submitted) - 진행중
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '나이키코리아', '에어맥스 DN',
    '나이키 에어맥스 DN 스타일링. 릴스 2건 + 피드 1건. 운동/일상 두 가지 룩.',
    2500000, '2026-04-15', '2026-05-15', 'submitted', true, '2026-04-15')
  RETURNING id INTO v_sp5;

  -- 제출완료 (submitted)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '쿠팡', '로켓배송 일상템',
    '쿠팡 로켓배송 추천 아이템 5가지. 릴스 1건. #쿠팡추천 #로켓배송.',
    800000, '2026-04-20', '2026-05-10', 'submitted', false, '2026-04-20')
  RETURNING id INTO v_sp6;

  -- 검토중 (underReview)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '스타벅스코리아', '여름 신메뉴 프로모션',
    '스타벅스 여름 시즌 신메뉴 3종 리뷰. 릴스 1건 + 스토리 2건. 매장 방문 촬영.',
    1200000, '2026-05-01', '2026-05-31', 'underReview', false, '2026-04-22')
  RETURNING id INTO v_sp7;

  -- 검토중 (underReview)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    'LG생활건강', '빌리프 모이스처 밤',
    '빌리프 수분 라인 리뷰. 릴스 1건. 피부 타입별 추천 포인트 강조.',
    1000000, '2026-05-05', '2026-05-25', 'underReview', false, '2026-04-23')
  RETURNING id INTO v_sp8;

  -- 제출 전 (preSubmit)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '배달의민족', '배민 라이브 먹방',
    '배달의민족 라이브 먹방 콜라보. 릴스 1건 + 라이브 1회. 치킨/피자 주문 컨셉.',
    1500000, '2026-05-10', '2026-06-10', 'preSubmit', false, '2026-04-24')
  RETURNING id INTO v_sp9;

  -- 제출 전 (preSubmit)
  INSERT INTO public.sponsorships (id, workspace_id, created_by, brand_name, product_name, details, amount, start_date, end_date, status, is_pinned, created_at)
  VALUES (gen_random_uuid(), v_workspace_id, v_user_id,
    '현대자동차', '캐스퍼 일렉트릭',
    '캐스퍼 EV 시승 브이로그. 릴스 2건 + 유튜브 1건. 도심 드라이브 + 충전 편의성.',
    5000000, '2026-05-15', '2026-06-30', 'preSubmit', false, '2026-04-25')
  RETURNING id INTO v_sp10;

  -- ============================================================
  -- 3) 정산 (Settlements) - 6개
  -- ============================================================

  -- 올리브영 - 정산 완료
  INSERT INTO public.settlements (workspace_id, created_by, brand_name, amount, fee, tax, settlement_date, is_paid, memo, sponsorship_id)
  VALUES (v_workspace_id, v_user_id, '올리브영', 1500000, 49500, 136500, '2026-04-10', true, '3월 캠페인 정산 완료', v_sp1);

  -- 무신사 - 정산 완료
  INSERT INTO public.settlements (workspace_id, created_by, brand_name, amount, fee, tax, settlement_date, is_paid, memo, sponsorship_id)
  VALUES (v_workspace_id, v_user_id, '무신사', 2000000, 66000, 182000, '2026-04-15', true, '룩북 촬영 정산', v_sp2);

  -- 삼성전자 - 미정산
  INSERT INTO public.settlements (workspace_id, created_by, brand_name, amount, fee, tax, settlement_date, is_paid, memo, sponsorship_id)
  VALUES (v_workspace_id, v_user_id, '삼성전자', 3000000, 99000, 273000, '2026-05-01', false, '갤럭시 플립6 캠페인 - 5월 정산 예정', v_sp3);

  -- 아모레퍼시픽 - 미정산
  INSERT INTO public.settlements (workspace_id, created_by, brand_name, amount, fee, tax, settlement_date, is_paid, memo, sponsorship_id)
  VALUES (v_workspace_id, v_user_id, '아모레퍼시픽', 1800000, 59400, 163800, '2026-05-05', false, '설화수 크림 정산 대기', v_sp4);

  -- 별도 정산 (협찬 연결 없음)
  INSERT INTO public.settlements (workspace_id, created_by, brand_name, amount, fee, tax, settlement_date, is_paid, memo, sponsorship_id)
  VALUES (v_workspace_id, v_user_id, '인스타그램 보너스', 500000, 16500, 45500, '2026-03-25', true, '릴스 보너스 프로그램 3월분', NULL);

  -- 별도 정산
  INSERT INTO public.settlements (workspace_id, created_by, brand_name, amount, fee, tax, settlement_date, is_paid, memo, sponsorship_id)
  VALUES (v_workspace_id, v_user_id, '유튜브 애드센스', 320000, 0, 29120, '2026-04-20', true, '4월 애드센스 수익', NULL);

  -- ============================================================
  -- 4) 릴스 노트 (Reels Notes) - 8개
  -- ============================================================

  -- 업로드 완료
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '올리브영 세럼 리뷰 릴스',
    '인트로: 요즘 피부 고민 언급 (건조함)
메인: 글로우 에디션 세럼 텍스처 클로즈업
사용 전후 비교 (3일차, 7일차)
아웃트로: "올리브영에서 만나요" + 할인 코드 자막
BGM: 잔잔한 어쿠스틱
러닝타임: 30초 이내',
    'uploaded', ARRAY['뷰티', '스킨케어', '올리브영'], true, v_sp1);

  -- 업로드 완료
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '무신사 여름 룩북 #1',
    '씬1: 카페 도착 (캐주얼 룩 - 오버사이즈 티 + 와이드 팬츠)
씬2: 거울 앞 스타일링 디테일컷
씬3: 거리 워킹샷 (슬로우모션)
트랜지션: 옷 갈아입기 전환
BGM: 트렌디한 팝
태그: @musinsastandard',
    'uploaded', ARRAY['패션', '룩북', '무신사'], false, v_sp2);

  -- 업로드 준비
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '갤럭시 플립6 언박싱',
    '인트로: 택배 도착 (설렘 표현)
언박싱: 박스 오픈 ASMR + 구성품 소개
메인: 플립 접는 모션 슬로우모션
카메라 테스트: 셀피 + 풍경
플렉스 모드 활용: 영상통화, 타임랩스
아웃트로: 한줄평 "이건 진짜 갓벽"',
    'readyToUpload', ARRAY['테크', '언박싱', '갤럭시'], true, v_sp3);

  -- 업로드 준비
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '나이키 에어맥스 스타일링',
    '파트1: 운동룩 (짐웨어 + 에어맥스 DN)
- 러닝 장면, 쿠셔닝 강조
파트2: 캐주얼룩 (데님 + 에어맥스)
- 카페, 거리 장면
트랜지션: 신발 클로즈업에서 전환
BGM: 에너지틱한 힙합',
    'readyToUpload', ARRAY['패션', '운동', '나이키'], false, v_sp5);

  -- 작성중
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '스타벅스 여름 신메뉴 리뷰',
    '후보 메뉴:
1. 망고 패션 프루트 블렌디드
2. 제주 말차 크림 프라푸치노
3. 서머 딸기 라떼

촬영 구상:
- 매장 분위기 B-roll
- 음료 제조 과정 (바리스타 POV)
- 맛 리액션 클로즈업',
    'drafting', ARRAY['카페', '음료', '스타벅스'], false, v_sp7);

  -- 작성중 (협찬 없는 자체 콘텐츠)
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '일상 브이로그 - 주말 루틴',
    '아침: 모닝 루틴 (스킨케어 + 커피)
오전: 운동 (필라테스 or 러닝)
점심: 건강식 레시피 (샐러드 볼)
오후: 카페에서 작업
저녁: 집밥 쿠킹
밤: 독서 + 마무리

포인트: 자연광 활용, 내추럴한 분위기',
    'drafting', ARRAY['일상', '브이로그', '루틴'], true, NULL);

  -- 작성중
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    '5월 콘텐츠 아이디어 모음',
    '1. 여름 향수 추천 TOP 5
2. 자외선 차단제 비교 리뷰
3. 여행 캐리어 패킹 팁
4. 홈카페 레시피 시리즈
5. OOTD 1주일 챌린지

우선순위: 2번 (시즌성) > 1번 > 5번',
    'drafting', ARRAY['기획', '아이디어'], false, NULL);

  -- 업로드 완료 (자체)
  INSERT INTO public.reels_notes (workspace_id, created_by, title, plain_content, status, tags, is_pinned, sponsorship_id)
  VALUES (v_workspace_id, v_user_id,
    'GRWM 출근 메이크업',
    '베이스: 톤업 선크림 + 쿠션 (가볍게)
아이: 브라운 음영 + 얇은 아이라인
립: MLBB 컬러 (롬앤 베어)
포인트: 5분 컷 스피드 메이크업
BGM: 경쾌한 팝
캡션: "바쁜 아침 5분이면 충분!"',
    'uploaded', ARRAY['뷰티', 'GRWM', '메이크업'], false, NULL);

  -- ============================================================
  -- 5) 일반 메모 (General Notes) - 6개
  -- ============================================================

  INSERT INTO public.general_notes (workspace_id, created_by, title, plain_content, tags, is_pinned)
  VALUES (v_workspace_id, v_user_id,
    '5월 콘텐츠 캘린더',
    '5/1-5/7: 스타벅스 신메뉴 콘텐츠 제작
5/8-5/14: 나이키 에어맥스 촬영 + 편집
5/15-5/21: 배달의민족 라이브 준비
5/22-5/31: 현대차 캐스퍼 시승 촬영

목표: 릴스 주 2회 업로드 유지
인스타 팔로워 목표: 5만 달성',
    ARRAY['일정', '캘린더'], true);

  INSERT INTO public.general_notes (workspace_id, created_by, title, plain_content, tags, is_pinned)
  VALUES (v_workspace_id, v_user_id,
    '협찬 단가 기준표',
    '릴스 1건: 80~150만원 (팔로워 3만 기준)
릴스 + 스토리: 120~200만원
릴스 + 피드: 150~250만원
유튜브 숏츠 포함: +50만원
라이브 1회: 100~200만원

브랜드 규모별:
- 대기업: 200만원~
- 중견기업: 100~200만원
- 스타트업: 50~100만원 (+ 제품 협찬)',
    ARRAY['비즈니스', '단가'], true);

  INSERT INTO public.general_notes (workspace_id, created_by, title, plain_content, tags, is_pinned)
  VALUES (v_workspace_id, v_user_id,
    '촬영 장비 리스트',
    'iPhone 16 Pro Max (메인 카메라)
갤럭시 Z 플립6 (서브/셀피)
DJI OM 7 짐벌
고덕스 SL60W 조명
Rode Wireless ME 마이크
삼각대: 맨프로토 미니
배경지: 화이트/그레이/마블

업그레이드 고려:
- Sony ZV-E10 II (유튜브용)
- 링라이트 18인치',
    ARRAY['장비', '촬영'], false);

  INSERT INTO public.general_notes (workspace_id, created_by, title, plain_content, tags, is_pinned)
  VALUES (v_workspace_id, v_user_id,
    '인스타그램 성장 전략',
    '현재 팔로워: 32,400명
목표: 6월까지 50,000명

전략:
1. 릴스 업로드 빈도 증가 (주 3회)
2. 트렌드 오디오 적극 활용
3. 콜라보 릴스 (다른 크리에이터)
4. 댓글 소통 시간 확보 (매일 30분)
5. 해시태그 최적화 (10-15개)

분석: 릴스 평균 도달 15K, 피드 평균 5K',
    ARRAY['전략', '성장'], false);

  INSERT INTO public.general_notes (workspace_id, created_by, title, plain_content, tags, is_pinned)
  VALUES (v_workspace_id, v_user_id,
    '세금 신고 준비 메모',
    '2026년 상반기 수입 정리
- 1월: 1,200,000원
- 2월: 800,000원
- 3월: 3,820,000원 (올리브영+무신사+인스타보너스)
- 4월: 5,120,000원 (삼성+아모레+애드센스)

경비 항목:
- 장비 구입비
- 촬영 소품/의상
- 교통비/주차비
- 카페/식비 (미팅)

세무사: 김OO (02-XXX-XXXX)',
    ARRAY['세금', '재무'], false);

  INSERT INTO public.general_notes (workspace_id, created_by, title, plain_content, tags, is_pinned)
  VALUES (v_workspace_id, v_user_id,
    '브랜드 컨택 리스트',
    '대기중:
- 젠틀몬스터: DM 발송 (4/20)
- 다이슨: 메일 발송 (4/18)
- 이니스프리: 담당자 미팅 예정 (5/2)

관계 유지:
- 올리브영 담당 박OO: 다음 시즌도 논의중
- 무신사 담당 이OO: 가을 룩북 제안 받음
- 삼성 담당 김OO: 갤럭시 워치 추가 제안',
    ARRAY['브랜드', '네트워크'], false);

  RAISE NOTICE '데모 데이터 삽입 완료! 협찬 10건, 정산 6건, 릴스노트 8건, 메모 6건';
END $$;
