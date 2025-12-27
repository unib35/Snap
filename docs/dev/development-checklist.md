# Acadesk v2 개발 체크리스트

> 이 문서는 Acadesk v2 개발에 필요한 모든 기능, 화면, 컴포넌트를 체계적으로 정리한 체크리스트입니다.
>
> **범례**: ✅ 완료 | 🚧 진행중 | ⬜ 미착수

---

## 목차

1. [인프라 & 공통](#1-인프라--공통)
2. [인증 & 온보딩](#2-인증--온보딩)
3. [대시보드](#3-대시보드)
4. [학생 관리](#4-학생-관리)
5. [보호자 관리](#5-보호자-관리)
6. [수업 관리](#6-수업-관리)
7. [출결 관리](#7-출결-관리)
8. [TODO & 숙제](#8-todo--숙제)
9. [성적 & 시험](#9-성적--시험)
10. [교재 & 도서 관리](#10-교재--도서-관리)
11. [캘린더](#11-캘린더)
12. [상담 관리](#12-상담-관리)
13. [리포트 관리](#13-리포트-관리)
14. [학원비 & 결제 관리](#14-학원비--결제-관리)
15. [직원 관리](#15-직원-관리)
16. [메시지 & 알림 관리](#16-메시지--알림-관리)
17. [설정](#17-설정)
18. [프로필](#18-프로필)
19. [도움말](#19-도움말)

---

## 1. 인프라 & 공통

### 1.1 모노레포 설정

| 항목                 | 상태 | 비고                              |
| -------------------- | ---- | --------------------------------- |
| pnpm workspace 설정  | ✅   | `pnpm-workspace.yaml`             |
| Turborepo 설정       | ✅   | `turbo.json`                      |
| TypeScript 기본 설정 | ✅   | `tsconfig.base.json`              |
| ESLint 설정          | ✅   | `@acadesk/eslint-config`          |
| Prettier 설정        | ✅   | `.prettierrc` + tailwind 플러그인 |
| Husky + lint-staged  | ✅   | 커밋 전 린트/포맷                 |

### 1.2 패키지 (@acadesk/\*)

#### @acadesk/ui (packages/ui)

| 컴포넌트               | 상태 | 비고                        |
| ---------------------- | ---- | --------------------------- |
| **기본 UI**            |      |                             |
| Button                 | ✅   | 다양한 variant 지원         |
| Input                  | ✅   |                             |
| Textarea               | ✅   |                             |
| Select                 | ✅   |                             |
| Checkbox               | ✅   |                             |
| Radio Group            | ✅   |                             |
| Switch                 | ✅   |                             |
| Label                  | ✅   |                             |
| **레이아웃**           |      |                             |
| Card                   | ✅   |                             |
| Separator              | ✅   |                             |
| Tabs                   | ✅   |                             |
| Accordion              | ✅   |                             |
| Collapsible            | ✅   |                             |
| Scroll Area            | ✅   |                             |
| **오버레이**           |      |                             |
| Dialog                 | ✅   |                             |
| Alert Dialog           | ✅   |                             |
| Sheet                  | ✅   | 사이드 패널                 |
| Popover                | ✅   |                             |
| Dropdown Menu          | ✅   |                             |
| Command                | ✅   | 검색 팔레트용               |
| **피드백**             |      |                             |
| Toast                  | ✅   |                             |
| Toaster                | ✅   |                             |
| Alert                  | ✅   |                             |
| Badge                  | ✅   |                             |
| Progress               | ✅   |                             |
| Skeleton               | ✅   |                             |
| **폼**                 |      |                             |
| Form                   | ✅   | react-hook-form 연동        |
| Date Picker            | ✅   |                             |
| Time Picker            | ✅   |                             |
| Time Range Picker      | ✅   |                             |
| Phone Input            | ✅   |                             |
| **데이터 표시**        |      |                             |
| Table                  | ✅   |                             |
| Pagination             | ✅   |                             |
| Avatar                 | ✅   |                             |
| Student Avatar         | ✅   | 학생 전용                   |
| Calendar               | ✅   |                             |
| Chart                  | ✅   | recharts 기반               |
| **상태 표시**          |      |                             |
| Empty State            | ✅   |                             |
| Loading State          | ✅   |                             |
| Loading Button         | ✅   |                             |
| Error Fallback         | ✅   |                             |
| Confirmation Dialog    | ✅   |                             |
| Page Header            | ✅   |                             |
| Page Skeleton          | ✅   | 페이지 로딩 스켈레톤        |
| Widget Skeleton        | ✅   |                             |
| Skeleton Blocks        | ✅   |                             |
| Slider                 | ✅   | Radix UI 기반               |
| **추가 필요 컴포넌트** |      |                             |
| Data Table             | ⬜   | 정렬/필터/페이지네이션 통합 |
| Combobox               | ⬜   | 검색 가능한 Select          |
| Multi Select           | ⬜   | 다중 선택                   |
| Tag Input              | ⬜   | 태그 입력                   |
| File Upload            | ⬜   | 파일 업로드                 |
| Image Upload           | ⬜   | 이미지 업로드 + 미리보기    |
| Color Picker           | ⬜   | 색상 선택                   |
| Rich Text Editor       | ⬜   | 서식 있는 텍스트 편집기     |
| Stat Card              | ⬜   | 통계 카드                   |
| Timeline               | ⬜   | 활동 타임라인               |
| Calendar (Full)        | ⬜   | 전체 캘린더 뷰              |

#### @acadesk/database (packages/database)

| 항목                 | 상태 | 비고                    |
| -------------------- | ---- | ----------------------- |
| database.types.ts    | 🚧   | Supabase 자동 생성 타입 |
| Supabase Client 설정 | ⬜   | 클라이언트/서버 분리    |
| 공통 쿼리 헬퍼       | ⬜   |                         |

#### @acadesk/utils (apps/web/src/shared/lib)

| 항목            | 상태 | 비고                            |
| --------------- | ---- | ------------------------------- |
| 날짜 유틸리티   | ✅   | date.ts (date-fns 기반)         |
| 전화번호 포맷   | ✅   | phone.ts (formatPhone, mask 등) |
| 금액 포맷       | ✅   | currency.ts (VAT 계산 포함)     |
| 검증 유틸리티   | ✅   | validators.ts (Zod 스키마)      |
| 문자열 유틸리티 | ✅   | string.ts (한글 조사 처리 포함) |
| 상수 정의       | ✅   | constants.ts (옵션, 상태값 등)  |

#### @acadesk/error (packages/error)

| 항목             | 상태 | 비고                  |
| ---------------- | ---- | --------------------- |
| 에러 클래스 정의 | ⬜   | AppError, ApiError 등 |
| 에러 핸들러      | ⬜   |                       |
| 에러 바운더리    | ⬜   | React Error Boundary  |

### 1.3 레이아웃 시스템 (apps/web)

| 컴포넌트            | 상태 | 파일 경로                                    | 비고                 |
| ------------------- | ---- | -------------------------------------------- | -------------------- |
| Root Layout         | ✅   | `app/layout.tsx`                             |                      |
| Dashboard Layout    | ✅   | `app/(dashboard)/layout.tsx`                 |                      |
| Auth Layout         | ✅   | `app/(auth)/layout.tsx`                      | 인증 페이지 레이아웃 |
| AppShell            | ✅   | `components/layout/app-shell.tsx`            |                      |
| Sidebar             | ✅   | `components/layout/sidebar.tsx`              |                      |
| Header              | ✅   | `components/layout/header.tsx`               |                      |
| Breadcrumb          | ✅   | `components/layout/breadcrumb.tsx`           |                      |
| PageContainer       | ✅   | `components/layout/page-container.tsx`       |                      |
| ThemeToggle         | ✅   | `components/layout/theme-toggle.tsx`         |                      |
| NotificationPopover | ✅   | `components/layout/notification-popover.tsx` |                      |
| HelpMenu            | ✅   | `components/layout/help-menu.tsx`            |                      |
| UserMenu            | ✅   | `components/layout/user-menu.tsx`            | 사용자 드롭다운      |
| MobileNav           | ⬜   | `components/layout/mobile-nav.tsx`           | 모바일 네비게이션    |

### 1.4 공통 Hooks (apps/web/src/shared/hooks)

| Hook            | 상태 | 비고                           |
| --------------- | ---- | ------------------------------ |
| useDebounce     | ✅   | 검색 디바운싱                  |
| useLocalStorage | ✅   | 로컬 스토리지 (SSR 안전)       |
| useMediaQuery   | ✅   | 반응형 처리                    |
| usePagination   | ✅   | 페이지네이션 상태              |
| useTableSort    | ✅   | 테이블 정렬                    |
| useTableFilter  | ✅   | 테이블 필터                    |
| useConfirm      | ✅   | 확인 다이얼로그 (Promise 기반) |
| useToast        | ✅   | @acadesk/ui에서 제공           |
| useAuth         | ✅   | 인증 상태                      |
| useTenant       | ✅   | 테넌트 정보                    |
| useUser         | ✅   | 현재 사용자 정보               |

### 1.5 공통 라이브러리 (apps/web/src/shared/lib)

| 파일                   | 상태 | 비고                  |
| ---------------------- | ---- | --------------------- |
| utils.ts               | ✅   | cn() 등 유틸리티      |
| design-system.ts       | ✅   | 디자인 시스템 상수    |
| features.config.ts     | ✅   | 기능 플래그           |
| breadcrumb-config.ts   | ✅   | 브레드크럼 설정       |
| supabase/client.ts     | ✅   | 브라우저 클라이언트   |
| supabase/server.ts     | ✅   | 서버 클라이언트       |
| supabase/middleware.ts | ✅   | 미들웨어용 클라이언트 |
| validators.ts          | ✅   | Zod 스키마 정의       |
| constants.ts           | ✅   | 상수 정의             |
| api-client.ts          | ⬜   | API 호출 래퍼         |

### 1.6 설정 (apps/web/src/config)

| 파일      | 상태 | 비고              |
| --------- | ---- | ----------------- |
| nav.ts    | ✅   | 네비게이션 설정   |
| site.ts   | ⬜   | 사이트 메타데이터 |
| routes.ts | ⬜   | 라우트 상수       |

### 1.7 Supabase 설정

| 항목                           | 상태 | 비고                                       |
| ------------------------------ | ---- | ------------------------------------------ |
| Supabase 프로젝트 생성         | ⬜   | 리모트                                     |
| 로컬 개발 환경                 | ✅   | `supabase/`                                |
| Extensions                     | ✅   | `00001_extensions.sql`                     |
| Enums                          | ✅   | `00002_enums.sql`                          |
| Core Tables                    | ✅   | `00003_core_tables.sql`                    |
| Auth Helpers                   | ✅   | `00004_auth_helpers.sql`                   |
| Core RLS                       | ✅   | `00005_core_rls.sql`                       |
| Learning Tables                | ✅   | `00006_learning_tables.sql`                |
| Learning RLS                   | ✅   | `00007_learning_rls.sql`                   |
| Assessment Tables              | ✅   | `00008_assessment_tables.sql`              |
| Assessment RLS                 | ✅   | `00009_assessment_rls.sql`                 |
| Library Tables                 | ✅   | `00010_library_tables.sql`                 |
| Library RLS                    | ✅   | `00011_library_rls.sql`                    |
| Communication Tables           | ✅   | `00012_communication_tables.sql`           |
| Communication RLS              | ✅   | `00013_communication_rls.sql`              |
| Payment Tables                 | ✅   | `00014_payment_tables.sql`                 |
| Payment RLS                    | ✅   | `00015_payment_rls.sql`                    |
| RPC Functions                  | ✅   | `00016_rpc_functions.sql`                  |
| Audit Log                      | ✅   | `00017_audit_log.sql`                      |
| Views                          | ✅   | `00018_views.sql`                          |
| Calendar Tables                | ✅   | `00019_calendar_tables.sql`                |
| Calendar RLS                   | ✅   | `00020_calendar_rls.sql`                   |
| Report Tables                  | ✅   | `00021_report_tables.sql`                  |
| Report RLS                     | ✅   | `00022_report_rls.sql`                     |
| Messaging Service Tables       | ✅   | `00023_messaging_service_tables.sql`       |
| Messaging Service RLS          | ✅   | `00024_messaging_service_rls.sql`          |
| Todo Templates Enhancement     | ✅   | `00025_todo_templates_enhancement.sql`     |
| Additional RPC Functions       | ✅   | `00026_additional_rpc_functions.sql`       |
| Additional Views               | ✅   | `00027_additional_views.sql`               |
| InApp Notification Enhancement | ✅   | `00028_inapp_notification_enhancement.sql` |
| InApp Notification RLS         | ✅   | `00029_inapp_notification_rls.sql`         |
| InApp Notification RPC         | ✅   | `00030_inapp_notification_rpc.sql`         |
| Structural Improvements        | ✅   | `00031_structural_improvements.sql`        |
| Seed Data                      | ✅   | `supabase/seed.sql` - 2학원, 12학생 등     |

---

## 2. 인증 & 온보딩

### 2.1 페이지

| 페이지               | 상태 | 경로               | 비고                  |
| -------------------- | ---- | ------------------ | --------------------- |
| 로그인               | ✅   | `/login`           |                       |
| 회원가입 (학원 등록) | ✅   | `/signup`          | 학원 + 원장 계정 생성 |
| 비밀번호 찾기        | ✅   | `/forgot-password` |                       |
| 비밀번호 재설정      | ✅   | `/reset-password`  |                       |
| 이메일 인증          | ✅   | `/verify-email`    |                       |
| 초대 수락            | ✅   | `/invite/[token]`  | 직원 초대 링크        |
| 온보딩               | ✅   | `/onboarding`      | 초기 설정 마법사      |

### 2.2 컴포넌트 (features/auth/components)

| 컴포넌트           | 상태 | 비고                        |
| ------------------ | ---- | --------------------------- |
| LoginForm          | ✅   | 로그인 폼                   |
| SignupForm         | ✅   | 학원 등록 폼                |
| ForgotPasswordForm | ✅   | 비밀번호 찾기 폼            |
| ResetPasswordForm  | ✅   | 비밀번호 재설정 폼          |
| VerifyEmailCard    | ✅   | 이메일 인증 카드            |
| InviteAcceptForm   | ✅   | 초대 수락 폼                |
| OnboardingWizard   | ✅   | 온보딩 마법사               |
| OnboardingStep1    | ✅   | 학원 정보 입력              |
| OnboardingStep2    | ✅   | 과목 설정                   |
| OnboardingStep3    | ✅   | 첫 반 생성                  |
| OnboardingStep4    | ✅   | 완료                        |
| SocialLoginButtons | ⬜   | 소셜 로그인 (Google, Kakao) |
| AuthGuard          | ✅   | 인증 필요 페이지 가드       |
| RoleGuard          | ✅   | 역할 기반 접근 제어         |

### 2.3 Server Actions (features/auth/actions)

| Action                        | 상태 | 비고                  |
| ----------------------------- | ---- | --------------------- |
| login.action.ts               | ✅   | 로그인                |
| signup.action.ts              | ✅   | 학원 등록 + 원장 계정 |
| logout.action.ts              | ✅   | 로그아웃              |
| forgot-password.action.ts     | ✅   | 비밀번호 찾기         |
| reset-password.action.ts      | ✅   | 비밀번호 재설정       |
| verify-email.action.ts        | ✅   | 이메일 인증           |
| get-invite.action.ts          | ✅   | 초대 정보 조회        |
| accept-invite.action.ts       | ✅   | 초대 수락             |
| complete-onboarding.action.ts | ✅   | 온보딩 완료           |

### 2.4 Hooks (features/auth/hooks)

| Hook       | 상태 | 비고              |
| ---------- | ---- | ----------------- |
| useSession | ⬜   | 세션 상태         |
| useSignIn  | ⬜   | 로그인 mutation   |
| useSignUp  | ⬜   | 회원가입 mutation |
| useSignOut | ⬜   | 로그아웃 mutation |

### 2.5 Types (features/auth/types)

| Type           | 상태 | 비고          |
| -------------- | ---- | ------------- |
| User           | ⬜   | 사용자 타입   |
| Session        | ⬜   | 세션 타입     |
| SignInInput    | ⬜   | 로그인 입력   |
| SignUpInput    | ⬜   | 회원가입 입력 |
| OnboardingData | ⬜   | 온보딩 데이터 |

---

## 3. 대시보드

### 3.1 페이지

| 페이지        | 상태 | 경로         | 비고           |
| ------------- | ---- | ------------ | -------------- |
| 대시보드 메인 | ✅   | `/dashboard` | 위젯 통합 완료 |

### 3.2 컴포넌트 (features/dashboard/components)

| 컴포넌트                   | 상태 | 비고                                 |
| -------------------------- | ---- | ------------------------------------ |
| DashboardClient            | ✅   | 대시보드 클라이언트 컴포넌트         |
| **통계 위젯**              |      |                                      |
| StatsOverview              | ✅   | 전체 통계 요약                       |
| StatCard                   | ✅   | 개별 통계 카드 (아이콘, 트렌드 지원) |
| TotalStudentsCard          | -    | StatCard로 대체                      |
| ActiveClassesCard          | -    | StatCard로 대체                      |
| TodayAttendanceCard        | -    | StatCard로 대체                      |
| PendingTodosCard           | -    | StatCard로 대체                      |
| **오늘 일정**              |      |                                      |
| TodaySessionsList          | ✅   | 오늘 수업 목록                       |
| TodaySessionItem           | -    | TodaySessionsList에 포함             |
| QuickAttendanceButton      | ⬜   | 빠른 출석 체크 버튼                  |
| **학생 관련**              |      |                                      |
| RecentStudentsList         | ✅   | 최근 등록 학생                       |
| BirthdayStudentsList       | ⬜   | 생일 학생                            |
| StudentAlertsList          | ⬜   | 주의 필요 학생                       |
| LongAbsenceAlert           | ⬜   | 장기 결석 알림                       |
| PendingAssignmentAlert     | ⬜   | 미제출 과제 알림                     |
| **상담/연락**              |      |                                      |
| ScheduledConsultationsList | ⬜   | 예정 상담                            |
| ParentsToContactList       | ⬜   | 연락 필요 학부모                     |
| **재정**                   |      |                                      |
| FinancialSummary           | ⬜   | 재정 요약                            |
| UnpaidInvoicesAlert        | ⬜   | 미납 청구서 알림                     |
| MonthlyRevenueChart        | ⬜   | 월별 매출 차트                       |
| **수업 현황**              |      |                                      |
| ClassStatusList            | ⬜   | 반별 현황                            |
| ClassCapacityBar           | ⬜   | 정원 대비 현황 바                    |
| **캘린더/일정**            |      |                                      |
| MiniCalendar               | ⬜   | 미니 캘린더                          |
| UpcomingEventsList         | ⬜   | 다가오는 일정                        |
| **활동 로그**              |      |                                      |
| RecentActivityList         | ⬜   | 최근 활동                            |
| ActivityItem               | ⬜   | 활동 항목                            |
| **퀵 액션**                |      |                                      |
| QuickActions               | ✅   | 빠른 작업 버튼들                     |
| QuickAddStudent            | -    | QuickActions에 포함                  |
| QuickAddTodo               | -    | QuickActions에 포함                  |
| QuickAttendance            | -    | QuickActions에 포함                  |

### 3.3 Server Actions (features/dashboard/actions)

| Action                | 상태 | 비고                               |
| --------------------- | ---- | ---------------------------------- |
| get-dashboard-data.ts | ✅   | 대시보드 데이터 조회 (mock 데이터) |
| get-stats.ts          | ⬜   | 통계 조회                          |
| get-today-sessions.ts | ⬜   | 오늘 수업 조회                     |
| get-alerts.ts         | ⬜   | 알림/경고 조회                     |

### 3.4 Types (features/dashboard/types)

| Type                  | 상태 | 비고                 |
| --------------------- | ---- | -------------------- |
| DashboardStats        | ✅   | 대시보드 통계        |
| RecentStudent         | ✅   | 최근 학생            |
| TodaySession          | ✅   | 오늘 수업            |
| BirthdayStudent       | ✅   | 생일 학생            |
| ScheduledConsultation | ✅   | 예정 상담            |
| StudentAlert          | ✅   | 학생 알림            |
| FinancialData         | ✅   | 재정 데이터          |
| ClassStatus           | ✅   | 수업 현황            |
| ParentToContact       | ✅   | 연락 필요 학부모     |
| CalendarEvent         | ✅   | 캘린더 이벤트        |
| ActivityLog           | ✅   | 활동 로그            |
| DashboardData         | ✅   | 대시보드 전체 데이터 |

---

## 4. 학생 관리

### 4.1 페이지

| 페이지    | 상태 | 경로                            | 비고                   |
| --------- | ---- | ------------------------------- | ---------------------- |
| 학생 목록 | ✅   | `/dashboard/students`           | 검색/필터/페이지네이션 |
| 학생 등록 | ✅   | `/dashboard/students/new`       |                        |
| 학생 상세 | ✅   | `/dashboard/students/[id]`      |                        |
| 학생 수정 | ✅   | `/dashboard/students/[id]/edit` |                        |

### 4.2 컴포넌트 (features/students/components)

| 컴포넌트                | 상태 | 비고                  |
| ----------------------- | ---- | --------------------- |
| **목록**                |      |                       |
| StudentList             | ✅   | 학생 목록 메인        |
| StudentTable            | ⬜   | 학생 테이블           |
| StudentTableRow         | ⬜   | 테이블 행             |
| StudentCard             | ✅   | 학생 카드 (그리드 뷰) |
| StudentListToolbar      | ⬜   | 검색/필터/뷰 전환     |
| StudentSearchInput      | ⬜   | 학생 검색             |
| StudentFilters          | ⬜   | 필터 (상태, 학년 등)  |
| StudentBulkActions      | ⬜   | 일괄 작업             |
| **폼**                  |      |                       |
| StudentForm             | ✅   | 학생 등록/수정 폼     |
| StudentBasicInfoForm    | ⬜   | 기본 정보 입력        |
| StudentSchoolInfoForm   | ⬜   | 학교 정보 입력        |
| StudentGuardianForm     | ⬜   | 보호자 연결           |
| **상세**                |      |                       |
| StudentDetail           | ✅   | 학생 상세 메인        |
| StudentHeader           | ⬜   | 학생 프로필 헤더      |
| StudentInfoTab          | ⬜   | 기본 정보 탭          |
| StudentAttendanceTab    | ⬜   | 출결 탭               |
| StudentGradesTab        | ⬜   | 성적 탭               |
| StudentTodosTab         | ⬜   | TODO 탭               |
| StudentClassesTab       | ⬜   | 수강 정보 탭          |
| StudentPaymentsTab      | ⬜   | 결제 내역 탭          |
| StudentConsultationsTab | ⬜   | 상담 기록 탭          |
| StudentNotesTab         | ⬜   | 메모 탭               |
| StudentTimelineTab      | ⬜   | 활동 기록 탭          |
| **공통**                |      |                       |
| StudentAvatar           | ⬜   | 학생 아바타           |
| StudentStatusBadge      | ⬜   | 상태 뱃지             |
| StudentQuickView        | ⬜   | 빠른 미리보기         |
| StudentSelectDialog     | ⬜   | 학생 선택 다이얼로그  |
| StudentMultiSelect      | ⬜   | 학생 다중 선택        |

### 4.3 Server Actions (features/students/actions)

| Action                  | 상태 | 비고                    |
| ----------------------- | ---- | ----------------------- |
| get-students.ts         | ✅   | 학생 목록 조회          |
| get-student.ts          | ✅   | 학생 상세 조회          |
| create-student.ts       | ✅   | 학생 등록               |
| update-student.ts       | ✅   | 학생 수정               |
| delete-student.ts       | ✅   | 학생 삭제 (soft delete) |
| search-students.ts      | ⬜   | 학생 검색               |
| bulk-update-students.ts | ⬜   | 일괄 수정               |
| export-students.ts      | ⬜   | 학생 목록 내보내기      |
| import-students.ts      | ⬜   | 학생 일괄 등록          |

### 4.4 Hooks (features/students/hooks)

| Hook             | 상태 | 비고               |
| ---------------- | ---- | ------------------ |
| useStudents      | ⬜   | 학생 목록 조회     |
| useStudent       | ⬜   | 학생 상세 조회     |
| useCreateStudent | ⬜   | 학생 등록 mutation |
| useUpdateStudent | ⬜   | 학생 수정 mutation |
| useDeleteStudent | ⬜   | 학생 삭제 mutation |
| useStudentSearch | ⬜   | 학생 검색          |

### 4.5 Types (features/students/types)

| Type                 | 상태 | 비고         |
| -------------------- | ---- | ------------ |
| Student              | ✅   | 학생 타입    |
| StudentWithGuardians | ✅   | 보호자 포함  |
| StudentFormInput     | ✅   | 폼 입력 타입 |
| StudentFilters       | ✅   | 필터 타입    |
| StudentStats         | ⬜   | 학생 통계    |

---

## 5. 보호자 관리

### 5.1 페이지

| 페이지      | 상태 | 경로                             | 비고 |
| ----------- | ---- | -------------------------------- | ---- |
| 보호자 목록 | ✅   | `/dashboard/guardians`           |      |
| 보호자 등록 | ✅   | `/dashboard/guardians/new`       |      |
| 보호자 상세 | ✅   | `/dashboard/guardians/[id]`      |      |
| 보호자 수정 | ✅   | `/dashboard/guardians/[id]/edit` |      |

### 5.2 컴포넌트 (features/guardians/components)

| 컴포넌트               | 상태 | 비고                   |
| ---------------------- | ---- | ---------------------- |
| **목록**               |      |                        |
| GuardianList           | ✅   | 보호자 목록            |
| GuardianTable          | ⬜   | 보호자 테이블          |
| GuardianSearchInput    | ⬜   | 보호자 검색            |
| **폼**                 |      |                        |
| GuardianForm           | ✅   | 보호자 등록/수정 폼    |
| GuardianStudentLink    | ⬜   | 학생 연결 관리         |
| **상세**               |      |                        |
| GuardianDetail         | ✅   | 보호자 상세            |
| GuardianHeader         | ⬜   | 보호자 헤더            |
| GuardianStudentsList   | ⬜   | 연결된 학생 목록       |
| GuardianContactHistory | ⬜   | 연락 이력              |
| **공통**               |      |                        |
| GuardianSelectDialog   | ⬜   | 보호자 선택 다이얼로그 |
| GuardianQuickAdd       | ⬜   | 빠른 보호자 등록       |

### 5.3 Server Actions (features/guardians/actions)

| Action             | 상태 | 비고           |
| ------------------ | ---- | -------------- |
| get-guardians.ts   | ✅   | 보호자 목록    |
| get-guardian.ts    | ✅   | 보호자 상세    |
| create-guardian.ts | ✅   | 보호자 등록    |
| update-guardian.ts | ✅   | 보호자 수정    |
| link-student.ts    | ⬜   | 학생 연결      |
| unlink-student.ts  | ⬜   | 학생 연결 해제 |

### 5.4 Types (features/guardians/types)

| Type                    | 상태 | 비고             |
| ----------------------- | ---- | ---------------- |
| Guardian                | ✅   | 보호자 타입      |
| GuardianWithStudents    | ✅   | 학생 포함        |
| StudentGuardianRelation | ⬜   | 학생-보호자 관계 |

---

## 6. 수업 관리

### 6.1 페이지

| 페이지        | 상태 | 경로                           | 비고           |
| ------------- | ---- | ------------------------------ | -------------- |
| 수업(반) 목록 | ✅   | `/dashboard/classes`           |                |
| 수업 등록     | ✅   | `/dashboard/classes/new`       |                |
| 수업 상세     | ✅   | `/dashboard/classes/[id]`      |                |
| 수업 수정     | ✅   | `/dashboard/classes/[id]/edit` |                |
| 수강 관리     | ⬜   | `/classes/[id]/enrollments`    |                |
| 시간표        | ⬜   | `/classes/timetable`           | 전체 시간표 뷰 |

### 6.2 컴포넌트 (features/classes/components)

| 컴포넌트             | 상태 | 비고                      |
| -------------------- | ---- | ------------------------- |
| **목록**             |      |                           |
| ClassList            | ✅   | 수업 목록                 |
| ClassTable           | ⬜   | 수업 테이블               |
| ClassCard            | ✅   | 수업 카드                 |
| ClassFilters         | ⬜   | 필터 (과목, 선생님 등)    |
| **폼**               |      |                           |
| ClassForm            | ✅   | 수업 등록/수정 폼         |
| ClassBasicInfoForm   | ⬜   | 기본 정보                 |
| ClassScheduleForm    | ⬜   | 시간표 설정               |
| ClassTimetableEditor | ⬜   | 시간표 편집기             |
| **상세**             |      |                           |
| ClassDetail          | ✅   | 수업 상세                 |
| ClassHeader          | ⬜   | 수업 헤더                 |
| ClassInfoTab         | ⬜   | 기본 정보 탭              |
| ClassEnrollmentsTab  | ⬜   | 수강생 탭                 |
| ClassSessionsTab     | ⬜   | 수업 회차 탭              |
| ClassAttendanceTab   | ⬜   | 출결 탭                   |
| ClassScheduleTab     | ⬜   | 시간표 탭                 |
| **수강 관리**        |      |                           |
| EnrollmentList       | ⬜   | 수강생 목록               |
| EnrollmentForm       | ⬜   | 수강 등록 폼              |
| EnrollStudentDialog  | ⬜   | 학생 수강 등록 다이얼로그 |
| BulkEnrollDialog     | ⬜   | 일괄 수강 등록            |
| DropEnrollmentDialog | ⬜   | 수강 취소                 |
| **시간표**           |      |                           |
| TimetableView        | ⬜   | 시간표 전체 뷰            |
| TimetableGrid        | ⬜   | 시간표 그리드             |
| TimetableCell        | ⬜   | 시간표 셀                 |
| TimetableFilters     | ⬜   | 필터 (선생님, 요일)       |
| **공통**             |      |                           |
| ClassSelectDialog    | ⬜   | 수업 선택 다이얼로그      |
| ClassBadge           | ⬜   | 수업 뱃지                 |

### 6.3 Server Actions (features/classes/actions)

| Action                   | 상태 | 비고           |
| ------------------------ | ---- | -------------- |
| get-classes.ts           | ✅   | 수업 목록      |
| get-class.ts             | ✅   | 수업 상세      |
| create-class.ts          | ✅   | 수업 등록      |
| update-class.ts          | ✅   | 수업 수정      |
| delete-class.ts          | ✅   | 수업 삭제      |
| get-enrollments.ts       | ⬜   | 수강생 목록    |
| enroll-student.ts        | ⬜   | 수강 등록      |
| enroll-students-batch.ts | ⬜   | 일괄 수강 등록 |
| drop-enrollment.ts       | ⬜   | 수강 취소      |
| generate-sessions.ts     | ⬜   | 수업 회차 생성 |
| get-timetable.ts         | ⬜   | 시간표 조회    |

### 6.4 Types (features/classes/types)

| Type             | 상태 | 비고           |
| ---------------- | ---- | -------------- |
| Class            | ✅   | 수업 타입      |
| ClassWithDetails | ✅   | 상세 정보 포함 |
| ClassTimetable   | ⬜   | 시간표         |
| Enrollment       | ⬜   | 수강 정보      |
| Session          | ✅   | 수업 회차      |

---

## 7. 출결 관리

### 7.1 페이지

| 페이지      | 상태 | 경로                    | 비고          |
| ----------- | ---- | ----------------------- | ------------- |
| 출결 현황   | ✅   | `/dashboard/attendance` | 전체 현황     |
| 일일 출석부 | ⬜   | `/attendance/daily`     | 날짜별 출석부 |
| 출결 통계   | ⬜   | `/attendance/stats`     | 통계 뷰       |

### 7.2 컴포넌트 (features/attendance/components)

| 컴포넌트                 | 상태 | 비고                                 |
| ------------------------ | ---- | ------------------------------------ |
| **현황**                 |      |                                      |
| AttendanceOverview       | ✅   | 출결 현황 개요 (AttendanceDashboard) |
| AttendanceCalendar       | ⬜   | 출결 캘린더                          |
| AttendanceSummaryCard    | ⬜   | 요약 카드                            |
| **일일 출석**            |      |                                      |
| DailyAttendance          | ⬜   | 일일 출석부 메인                     |
| DailyAttendanceHeader    | ⬜   | 날짜/반 선택 헤더                    |
| AttendanceSessionList    | ⬜   | 수업별 목록                          |
| AttendanceSessionCard    | ⬜   | 수업 카드                            |
| AttendanceTable          | ⬜   | 출석 테이블                          |
| AttendanceRow            | ⬜   | 출석 행                              |
| AttendanceStatusSelect   | ⬜   | 상태 선택                            |
| AttendanceTimeInput      | ⬜   | 출석 시간 입력                       |
| AttendanceNoteInput      | ⬜   | 메모 입력                            |
| BulkAttendanceActions    | ⬜   | 일괄 출석 처리                       |
| QuickAttendanceSheet     | ⬜   | 빠른 출석 체크 시트                  |
| **통계**                 |      |                                      |
| AttendanceStats          | ⬜   | 출결 통계                            |
| AttendanceRateChart      | ⬜   | 출석률 차트                          |
| AttendanceTrendChart     | ⬜   | 출결 추이 차트                       |
| AttendanceByClassChart   | ⬜   | 반별 출결 차트                       |
| AttendanceByStudentTable | ⬜   | 학생별 출결 테이블                   |
| **공통**                 |      |                                      |
| AttendanceStatusBadge    | ⬜   | 상태 뱃지                            |
| AttendanceDatePicker     | ⬜   | 날짜 선택                            |
| AttendanceClassSelect    | ⬜   | 반 선택                              |

### 7.3 Server Actions (features/attendance/actions)

| Action                    | 상태 | 비고                        |
| ------------------------- | ---- | --------------------------- |
| get-daily-attendance.ts   | ⬜   | 일일 출결 조회              |
| get-session-attendance.ts | ✅   | 수업별 출결                 |
| mark-attendance.ts        | ✅   | 출결 체크 (check-in.action) |
| batch-attendance.ts       | ⬜   | 일괄 출결 체크              |
| get-attendance-stats.ts   | ⬜   | 출결 통계                   |
| get-student-attendance.ts | ⬜   | 학생별 출결                 |
| export-attendance.ts      | ⬜   | 출결 내보내기               |

### 7.4 Types (features/attendance/types)

| Type                   | 상태 | 비고           |
| ---------------------- | ---- | -------------- |
| Attendance             | ✅   | 출결 타입      |
| AttendanceStatus       | ✅   | 상태 enum      |
| AttendanceWithStudent  | ✅   | 학생 정보 포함 |
| DailyAttendanceSummary | ⬜   | 일일 요약      |
| AttendanceStats        | ⬜   | 통계 타입      |

---

## 8. TODO & 숙제

### 8.1 페이지

| 페이지           | 상태 | 경로                     | 비고                |
| ---------------- | ---- | ------------------------ | ------------------- |
| TODO 목록        | ✅   | `/todos`                 |                     |
| TODO 등록        | ✅   | `/todos/new`             |                     |
| TODO 상세        | ✅   | `/todos/[id]`            |                     |
| TODO 템플릿      | ✅   | `/todos/templates`       |                     |
| TODO 템플릿 등록 | ✅   | `/todos/templates/new`   |                     |
| TODO 검증        | ⬜   | `/todos/verify`          | 완료 확인 대기 목록 |
| TODO 통계        | ⬜   | `/todos/stats`           |                     |
| 숙제 관리        | -    | `/homeworks`             | TODO로 통합         |
| 제출 현황        | -    | `/homeworks/submissions` | TODO로 통합         |

### 8.2 컴포넌트 (features/todos/components)

| 컴포넌트              | 상태 | 비고                       |
| --------------------- | ---- | -------------------------- |
| **목록**              |      |                            |
| TodoList              | ✅   | TODO 목록                  |
| TodoTable             | ⬜   | TODO 테이블                |
| TodoCard              | ✅   | TODO 카드                  |
| TodoKanban            | ⬜   | 칸반 보드 뷰               |
| TodoFilters           | ✅   | 필터 (상태, 학생, 기한 등) |
| TodoBulkActions       | ⬜   | 일괄 작업                  |
| **폼**                |      |                            |
| TodoForm              | ✅   | TODO 등록/수정 폼          |
| TodoBasicForm         | -    | TodoForm에 포함            |
| TodoAssignForm        | -    | TodoForm에 포함            |
| TodoChecklistForm     | -    | TodoForm에 포함            |
| TodoFromTemplate      | ⬜   | 템플릿에서 생성            |
| BulkTodoAssign        | ✅   | 일괄 TODO 배정             |
| **상세**              |      |                            |
| TodoDetail            | ✅   | TODO 상세                  |
| TodoHeader            | -    | TodoDetail에 포함          |
| TodoProgress          | -    | TodoDetail에 포함          |
| TodoChecklist         | ✅   | 체크리스트                 |
| TodoAttachments       | ⬜   | 첨부파일                   |
| TodoComments          | ⬜   | 코멘트/피드백              |
| TodoHistory           | ⬜   | 변경 이력                  |
| **검증**              |      |                            |
| TodoVerifyList        | ✅   | 검증 대기 목록             |
| TodoVerifyCard        | ✅   | 검증 카드                  |
| TodoVerifyForm        | ✅   | 검증 폼 (점수, 피드백)     |
| **템플릿**            |      |                            |
| TodoTemplateList      | ✅   | 템플릿 목록                |
| TodoTemplateCard      | ✅   | 템플릿 카드                |
| TodoTemplateForm      | ✅   | 템플릿 등록/수정           |
| TodoTemplateSelect    | ⬜   | 템플릿 선택                |
| **통계**              |      |                            |
| TodoStats             | ⬜   | TODO 통계                  |
| TodoCompletionChart   | ⬜   | 완료율 차트                |
| TodoByStudentTable    | ⬜   | 학생별 현황                |
| TodoPointsLeaderboard | ⬜   | 포인트 순위                |
| **공통**              |      |                            |
| TodoStatusBadge       | ✅   | 상태 뱃지                  |
| TodoPriorityBadge     | ✅   | 우선순위 뱃지              |
| TodoCategoryBadge     | ✅   | 카테고리 뱃지              |
| TodoDueDate           | ✅   | 기한 표시                  |

### 8.3 Server Actions (features/todos/actions)

| Action               | 상태 | 비고           |
| -------------------- | ---- | -------------- |
| get-todos.ts         | ✅   | TODO 목록      |
| get-todo.ts          | ✅   | TODO 상세      |
| create-todo.ts       | ✅   | TODO 생성      |
| update-todo.ts       | ✅   | TODO 수정      |
| delete-todo.ts       | ✅   | TODO 삭제      |
| complete-todo.ts     | ✅   | TODO 완료 처리 |
| verify-todo.ts       | ✅   | TODO 검증      |
| bulk-assign-todos.ts | ✅   | 일괄 배정      |
| get-templates.ts     | ✅   | 템플릿 목록    |
| create-template.ts   | ✅   | 템플릿 생성    |
| update-template.ts   | ✅   | 템플릿 수정    |
| delete-template.ts   | ✅   | 템플릿 삭제    |
| get-todo-stats.ts    | ✅   | TODO 통계      |

### 8.4 Types (features/todos/types)

| Type              | 상태 | 비고            |
| ----------------- | ---- | --------------- |
| Todo              | ✅   | TODO 타입       |
| TodoStatus        | ✅   | 상태 enum       |
| TodoPriority      | ✅   | 우선순위 enum   |
| TodoCategory      | ✅   | 카테고리 enum   |
| TodoTemplate      | ✅   | 템플릿 타입     |
| TodoChecklistItem | ✅   | 체크리스트 항목 |
| TodoStats         | ✅   | 통계 타입       |

---

## 9. 성적 & 시험

### 9.1 페이지

| 페이지      | 상태 | 경로                      | 비고           |
| ----------- | ---- | ------------------------- | -------------- |
| 성적 조회   | ✅   | `/grades`                 | 성적 목록      |
| 성적 입력   | ✅   | `/grades/entry`           | 성적 일괄 입력 |
| 시험 목록   | ✅   | `/grades/exams`           |                |
| 시험 등록   | ✅   | `/grades/exams/new`       |                |
| 시험 상세   | ✅   | `/grades/exams/[id]`      |                |
| 시험 수정   | ✅   | `/grades/exams/[id]/edit` |                |
| 재시험 관리 | ⬜   | `/grades/retests`         |                |
| 시험 템플릿 | ⬜   | `/grades/exam-templates`  |                |

### 9.2 컴포넌트 (features/grades/components)

| 컴포넌트               | 상태 | 비고                    |
| ---------------------- | ---- | ----------------------- |
| **성적 조회**          |      |                         |
| GradeList              | ✅   | 성적 목록               |
| GradeCard              | ✅   | 성적 카드               |
| GradeTable             | ⬜   | 성적 테이블             |
| GradeFilters           | ✅   | 필터 (시험, 학생, 기간) |
| GradeStudentView       | ⬜   | 학생별 성적 뷰          |
| GradeExamView          | ⬜   | 시험별 성적 뷰          |
| GradeChart             | ⬜   | 성적 추이 차트          |
| **성적 입력**          |      |                         |
| GradeEntry             | ⬜   | 성적 입력 메인          |
| GradeEntryForm         | ⬜   | 성적 입력 폼            |
| GradeEntryTable        | ⬜   | 일괄 입력 테이블        |
| GradeEntryRow          | ⬜   | 입력 행                 |
| GradeBulkImport        | ⬜   | 일괄 가져오기           |
| **시험**               |      |                         |
| ExamList               | ✅   | 시험 목록               |
| ExamCard               | ✅   | 시험 카드               |
| ExamForm               | ✅   | 시험 등록/수정 폼       |
| ExamDetail             | ✅   | 시험 상세               |
| ExamCategoryBadge      | ✅   | 시험 유형 뱃지          |
| ExamScoresTab          | ⬜   | 성적 탭                 |
| ExamStatsTab           | ⬜   | 통계 탭                 |
| ExamRankingTable       | ⬜   | 등수 테이블             |
| **재시험**             |      |                         |
| RetestList             | ⬜   | 재시험 목록             |
| RetestForm             | ⬜   | 재시험 등록             |
| RetestStudentSelect    | ⬜   | 재시험 대상 선택        |
| **템플릿**             |      |                         |
| ExamTemplateList       | ⬜   | 템플릿 목록             |
| ExamTemplateForm       | ⬜   | 템플릿 등록/수정        |
| **공통**               |      |                         |
| ScoreBadge             | ✅   | 점수 뱃지               |
| ScoreResultBadge       | ✅   | 합격/불합격 뱃지        |
| RankBadge              | ✅   | 등수 뱃지               |
| GradeDistributionChart | ⬜   | 성적 분포 차트          |

### 9.3 Server Actions (features/grades/actions)

| Action                     | 상태 | 비고             |
| -------------------------- | ---- | ---------------- |
| get-grades.ts              | ✅   | 성적 목록        |
| get-exams.ts               | ✅   | 시험 목록        |
| get-exam.ts                | ✅   | 시험 상세        |
| get-student-grades.ts      | ✅   | 학생별 성적      |
| create-exam.ts             | ✅   | 시험 등록        |
| update-exam.ts             | ✅   | 시험 수정        |
| delete-exam.ts             | ✅   | 시험 삭제        |
| create-exam-with-scores.ts | ⬜   | 시험 + 성적 등록 |
| enter-scores.ts            | ✅   | 성적 입력        |
| update-score.ts            | ✅   | 성적 수정        |
| calculate-ranks.ts         | ✅   | 등수 계산        |
| get-grade-report.ts        | ⬜   | 성적표 조회      |
| get-exam-stats.ts          | ✅   | 시험 통계        |
| create-retest.ts           | ⬜   | 재시험 등록      |

### 9.4 Types (features/grades/types)

| Type             | 상태 | 비고           |
| ---------------- | ---- | -------------- |
| Exam             | ✅   | 시험 타입      |
| ExamWithSubject  | ✅   | 과목 정보 포함 |
| ExamWithDetails  | ✅   | 상세 정보 포함 |
| ExamCategory     | ✅   | 시험 유형 enum |
| Score            | ✅   | 성적 타입      |
| ScoreWithStudent | ✅   | 학생 정보 포함 |
| ScoreWithExam    | ✅   | 시험 정보 포함 |
| ScoreWithDetails | ✅   | 전체 정보 포함 |
| ScoreResult      | ✅   | 점수 결과 enum |
| GradeReport      | ✅   | 성적표         |
| ExamStats        | ✅   | 시험 통계      |
| ExamListFilter   | ✅   | 시험 필터      |
| GradeListFilter  | ✅   | 성적 필터      |
| ActionResult     | ✅   | 액션 결과      |

---

## 10. 교재 & 도서 관리

### 10.1 페이지

| 페이지    | 상태 | 경로                    | 비고      |
| --------- | ---- | ----------------------- | --------- |
| 교재 목록 | ✅   | `/textbooks`            |           |
| 교재 등록 | ✅   | `/textbooks/new`        |           |
| 교재 상세 | ✅   | `/textbooks/[id]`       |           |
| 교재 수정 | ✅   | `/textbooks/[id]/edit`  |           |
| 교재 대여 | ✅   | `/library/lendings`     | 대여 현황 |
| 대여 등록 | ✅   | `/library/lendings/new` |           |

### 10.2 컴포넌트 (features/library/components)

| 컴포넌트            | 상태 | 비고                 |
| ------------------- | ---- | -------------------- |
| **교재**            |      |                      |
| BookList            | ✅   | 교재 목록            |
| BookTable           | ⬜   | 교재 테이블          |
| BookCard            | ✅   | 교재 카드            |
| BookForm            | ✅   | 교재 등록/수정       |
| BookDetail          | ✅   | 교재 상세            |
| BookCoverUpload     | ⬜   | 표지 업로드          |
| BookStockBadge      | ✅   | 재고 뱃지            |
| BookFilters         | ⬜   | 필터 (과목, 재고 등) |
| **대여**            |      |                      |
| LendingList         | ✅   | 대여 현황            |
| LendingTable        | ⬜   | 대여 테이블          |
| LendingCard         | ✅   | 대여 카드            |
| LendingForm         | ✅   | 대여 등록            |
| LendingReturnForm   | ⬜   | 반납 처리            |
| OverdueLendingAlert | ⬜   | 연체 알림            |
| LendingHistory      | ⬜   | 대여 이력            |
| **공통**            |      |                      |
| BookSelectDialog    | ⬜   | 교재 선택 다이얼로그 |
| LendingStatusBadge  | ✅   | 대여 상태 뱃지       |

### 10.3 Server Actions (features/library/actions)

| Action                  | 상태 | 비고      |
| ----------------------- | ---- | --------- |
| get-books.ts            | ✅   | 교재 목록 |
| get-book.ts             | ✅   | 교재 상세 |
| create-book.ts          | ✅   | 교재 등록 |
| update-book.ts          | ✅   | 교재 수정 |
| delete-book.ts          | ✅   | 교재 삭제 |
| get-lendings.ts         | ✅   | 대여 현황 |
| lend-book.ts            | ✅   | 대여 등록 |
| return-book.ts          | ✅   | 반납 처리 |
| get-overdue-lendings.ts | ✅   | 연체 목록 |

### 10.4 Types (features/library/types)

| Type               | 상태 | 비고           |
| ------------------ | ---- | -------------- |
| Book               | ✅   | 교재 타입      |
| BookWithSubject    | ✅   | 과목 정보 포함 |
| Lending            | ✅   | 대여 타입      |
| LendingStatus      | ✅   | 대여 상태 enum |
| LendingWithStudent | ✅   | 학생 정보 포함 |
| LendingWithDetails | ✅   | 상세 정보 포함 |
| OverdueLending     | ✅   | 연체 정보 포함 |
| BookStats          | ✅   | 교재 통계      |
| BookListFilter     | ✅   | 교재 필터      |
| LendingListFilter  | ✅   | 대여 필터      |
| ActionResult       | ✅   | 액션 결과      |

---

## 11. 캘린더

### 11.1 페이지

| 페이지    | 상태 | 경로                  | 비고             |
| --------- | ---- | --------------------- | ---------------- |
| 캘린더    | ✅   | `/calendar`           | 전체 일정 캘린더 |
| 일정 등록 | ✅   | `/calendar/new`       |                  |
| 일정 상세 | ✅   | `/calendar/[id]`      |                  |
| 일정 수정 | ✅   | `/calendar/[id]/edit` |                  |
| 휴일 관리 | ✅   | `/calendar/holidays`  |                  |

### 11.2 컴포넌트 (features/calendar/components)

| 컴포넌트            | 상태 | 비고                          |
| ------------------- | ---- | ----------------------------- |
| **캘린더 뷰**       |      |                               |
| CalendarView        | ✅   | 캘린더 메인 (월간 뷰 통합)    |
| CalendarMonth       | ⏭️   | 월간 뷰 (CalendarView에 통합) |
| CalendarWeek        | ⬜   | 주간 뷰 (미구현)              |
| CalendarDay         | ⬜   | 일간 뷰 (미구현)              |
| CalendarAgenda      | ⬜   | 어젠다 뷰 (미구현)            |
| CalendarToolbar     | ⏭️   | 툴바 (CalendarView에 통합)    |
| EventFilters        | ✅   | 필터 (유형, 검색)             |
| **일정**            |      |                               |
| EventCard           | ✅   | 일정 카드                     |
| EventList           | ✅   | 일정 목록                     |
| EventForm           | ✅   | 일정 등록/수정                |
| EventDetail         | ✅   | 일정 상세                     |
| EventTypeBadge      | ✅   | 일정 유형 뱃지                |
| RecurrenceBadge     | ✅   | 반복 설정 뱃지                |
| UpcomingEvents      | ✅   | 다가오는 일정 위젯            |
| EventRecurrenceForm | ⏭️   | 반복 설정 (EventForm에 통합)  |
| EventAttendees      | ⬜   | 참석자 관리 (미구현)          |
| EventQuickAdd       | ⬜   | 빠른 일정 추가 (미구현)       |
| **휴일**            |      |                               |
| HolidayList         | ✅   | 휴일 목록                     |
| HolidayCard         | ✅   | 휴일 카드                     |
| HolidayForm         | ✅   | 휴일 등록                     |
| HolidayImport       | ⬜   | 공휴일 가져오기 (미구현)      |

### 11.3 Server Actions (features/calendar/actions)

| Action                       | 상태 | 비고                    |
| ---------------------------- | ---- | ----------------------- |
| get-events.action.ts         | ✅   | 일정 목록               |
| get-event.action.ts          | ✅   | 일정 상세               |
| create-event.action.ts       | ✅   | 일정 등록               |
| update-event.action.ts       | ✅   | 일정 수정               |
| delete-event.action.ts       | ✅   | 일정 삭제               |
| get-monthly-events.action.ts | ✅   | 월간 일정 (캘린더 뷰용) |
| get-holidays.action.ts       | ✅   | 휴일 목록               |
| create-holiday.action.ts     | ✅   | 휴일 등록               |
| delete-holiday.action.ts     | ✅   | 휴일 삭제               |

### 11.4 Types (features/calendar/types)

| Type                | 상태 | 비고               |
| ------------------- | ---- | ------------------ |
| CalendarEvent       | ✅   | 일정 타입          |
| EventWithDetails    | ✅   | 관계 포함 일정     |
| EventType           | ✅   | 일정 유형 enum     |
| RecurrenceType      | ✅   | 반복 유형 enum     |
| CalendarViewType    | ✅   | 캘린더 뷰 타입     |
| Holiday             | ✅   | 휴일 타입          |
| CreateEventInput    | ✅   | 일정 생성 입력     |
| UpdateEventInput    | ✅   | 일정 수정 입력     |
| CreateHolidayInput  | ✅   | 휴일 생성 입력     |
| MonthlyCalendarData | ✅   | 월간 캘린더 데이터 |
| DayEvents           | ✅   | 일별 일정 그룹     |

---

## 12. 상담 관리

### 12.1 페이지

| 페이지      | 상태 | 경로                       | 비고             |
| ----------- | ---- | -------------------------- | ---------------- |
| 상담 목록   | ✅   | `/consultations`           |                  |
| 상담 등록   | ✅   | `/consultations/new`       |                  |
| 상담 상세   | ✅   | `/consultations/[id]`      |                  |
| 상담 수정   | ✅   | `/consultations/[id]/edit` |                  |
| 상담 캘린더 | ⬜   | `/consultations/calendar`  | 상담 일정 캘린더 |

### 12.2 컴포넌트 (features/consultations/components)

| 컴포넌트                   | 상태 | 비고           |
| -------------------------- | ---- | -------------- |
| **목록**                   |      |                |
| ConsultationList           | ✅   | 상담 목록      |
| ConsultationTable          | ⬜   | 상담 테이블    |
| ConsultationCard           | ✅   | 상담 카드      |
| ConsultationFilters        | ✅   | 필터           |
| ConsultationCalendar       | ⬜   | 상담 캘린더    |
| **폼**                     |      |                |
| ConsultationForm           | ✅   | 상담 등록/수정 |
| ConsultationStudentSelect  | ⬜   | 학생 선택      |
| ConsultationGuardianSelect | ⬜   | 보호자 선택    |
| ConsultationScheduleForm   | ⬜   | 일정 설정      |
| **상세**                   |      |                |
| ConsultationDetail         | ✅   | 상담 상세      |
| ConsultationHeader         | ⬜   | 상담 헤더      |
| ConsultationContent        | ⬜   | 상담 내용      |
| ConsultationFollowUp       | ⬜   | 후속 조치      |
| ConsultationHistory        | ⬜   | 상담 이력      |
| **공통**                   |      |                |
| ConsultationTypeBadge      | ✅   | 상담 유형 뱃지 |
| ConsultationQuickSchedule  | ⬜   | 빠른 일정 등록 |

### 12.3 Server Actions (features/consultations/actions)

| Action                       | 상태 | 비고        |
| ---------------------------- | ---- | ----------- |
| get-consultations.ts         | ✅   | 상담 목록   |
| get-consultation.ts          | ✅   | 상담 상세   |
| create-consultation.ts       | ✅   | 상담 등록   |
| update-consultation.ts       | ✅   | 상담 수정   |
| delete-consultation.ts       | ✅   | 상담 삭제   |
| get-consultation-stats.ts    | ✅   | 상담 통계   |
| get-student-consultations.ts | ⬜   | 학생별 상담 |
| schedule-consultation.ts     | ⬜   | 상담 예약   |

### 12.4 Types (features/consultations/types)

| Type                    | 상태 | 비고           |
| ----------------------- | ---- | -------------- |
| Consultation            | ✅   | 상담 타입      |
| ConsultationType        | ✅   | 상담 유형 enum |
| ConsultationWithDetails | ✅   | 상세 정보 포함 |
| ConsultationListFilter  | ✅   | 목록 필터      |
| ConsultationStats       | ✅   | 통계 타입      |

---

## 13. 리포트 관리

### 13.1 페이지

| 페이지        | 상태 | 경로                 | 비고           |
| ------------- | ---- | -------------------- | -------------- |
| 리포트 목록   | ✅   | `/reports`           | 생성된 리포트  |
| 리포트 생성   | ✅   | `/reports/new`       |                |
| 리포트 상세   | ✅   | `/reports/[id]`      |                |
| 리포트 템플릿 | ⬜   | `/reports/templates` |                |
| 리포트 스케줄 | ⬜   | `/reports/schedules` | 자동 발송 설정 |

### 13.2 컴포넌트 (features/reports/components)

| 컴포넌트             | 상태 | 비고             |
| -------------------- | ---- | ---------------- |
| **목록**             |      |                  |
| ReportList           | ✅   | 리포트 목록      |
| ReportTable          | ⬜   | 리포트 테이블    |
| ReportCard           | ✅   | 리포트 카드      |
| ReportFilters        | ✅   | 필터             |
| **생성**             |      |                  |
| ReportForm           | ✅   | 리포트 생성 폼   |
| ReportGenerator      | ⬜   | 리포트 생성      |
| ReportTypeSelect     | ⬜   | 리포트 유형 선택 |
| ReportStudentSelect  | ⬜   | 학생 선택        |
| ReportPeriodSelect   | ⬜   | 기간 선택        |
| ReportTemplateSelect | ⬜   | 템플릿 선택      |
| ReportPreview        | ⬜   | 미리보기         |
| **상세**             |      |                  |
| ReportDetail         | ✅   | 리포트 상세      |
| ReportHeader         | ⬜   | 리포트 헤더      |
| ReportContent        | ⬜   | 리포트 내용      |
| ReportPDFViewer      | ⬜   | PDF 뷰어         |
| ReportSendForm       | ⬜   | 발송 폼          |
| **템플릿**           |      |                  |
| ReportTemplateList   | ⬜   | 템플릿 목록      |
| ReportTemplateForm   | ⬜   | 템플릿 편집      |
| ReportTemplateEditor | ⬜   | 템플릿 에디터    |
| **스케줄**           |      |                  |
| ReportScheduleList   | ⬜   | 스케줄 목록      |
| ReportScheduleForm   | ⬜   | 스케줄 설정      |
| **공통**             |      |                  |
| ReportTypeBadge      | ✅   | 리포트 유형 뱃지 |
| ReportStatusBadge    | ✅   | 상태 뱃지        |

### 13.3 Server Actions (features/reports/actions)

| Action                  | 상태 | 비고        |
| ----------------------- | ---- | ----------- |
| get-reports.ts          | ✅   | 리포트 목록 |
| get-report.ts           | ✅   | 리포트 상세 |
| create-report.ts        | ✅   | 리포트 생성 |
| update-report.ts        | ✅   | 리포트 수정 |
| delete-report.ts        | ✅   | 리포트 삭제 |
| get-report-templates.ts | ✅   | 템플릿 목록 |
| send-report.ts          | ⬜   | 리포트 발송 |
| create-template.ts      | ⬜   | 템플릿 생성 |
| update-template.ts      | ⬜   | 템플릿 수정 |
| get-schedules.ts        | ⬜   | 스케줄 목록 |
| create-schedule.ts      | ⬜   | 스케줄 생성 |
| update-schedule.ts      | ⬜   | 스케줄 수정 |

### 13.4 Types (features/reports/types)

| Type              | 상태 | 비고               |
| ----------------- | ---- | ------------------ |
| GeneratedReport   | ✅   | 생성된 리포트 타입 |
| ReportType        | ✅   | 리포트 유형        |
| ReportStatus      | ✅   | 리포트 상태        |
| ReportTemplate    | ✅   | 템플릿 타입        |
| ReportWithDetails | ✅   | 상세 정보 포함     |
| ReportListFilter  | ✅   | 목록 필터          |
| ReportSchedule    | ✅   | 스케줄 타입        |

---

## 14. 학원비 & 결제 관리

### 14.1 페이지

| 페이지      | 상태 | 경로                      | 비고      |
| ----------- | ---- | ------------------------- | --------- |
| 학원비 관리 | ⬜   | `/payments`               | 결제 현황 |
| 청구서 목록 | ⬜   | `/payments/invoices`      |           |
| 청구서 등록 | ⬜   | `/payments/invoices/new`  |           |
| 청구서 상세 | ⬜   | `/payments/invoices/[id]` |           |
| 수납 처리   | ⬜   | `/payments/receive`       |           |
| 수납금 플랜 | ⬜   | `/payments/plans`         |           |
| 결제 통계   | ⬜   | `/payments/stats`         |           |

### 14.2 컴포넌트 (features/payments/components)

| 컴포넌트             | 상태 | 비고             |
| -------------------- | ---- | ---------------- |
| **현황**             |      |                  |
| PaymentOverview      | ⬜   | 결제 현황 개요   |
| PaymentSummaryCard   | ⬜   | 요약 카드        |
| MonthlyRevenueChart  | ⬜   | 월별 매출 차트   |
| UnpaidInvoicesList   | ⬜   | 미납 청구서 목록 |
| **청구서**           |      |                  |
| InvoiceList          | ✅   | 청구서 목록      |
| InvoiceTable         | ⬜   | 청구서 테이블    |
| InvoiceCard          | ✅   | 청구서 카드      |
| InvoiceForm          | ⬜   | 청구서 등록/수정 |
| InvoiceDetail        | ⬜   | 청구서 상세      |
| InvoicePreview       | ⬜   | 청구서 미리보기  |
| InvoiceSendForm      | ⬜   | 청구서 발송      |
| BulkInvoiceGenerator | ⬜   | 일괄 청구서 생성 |
| **수납**             |      |                  |
| PaymentReceiveForm   | ✅   | 수납 처리 폼     |
| PaymentMethodSelect  | ⬜   | 결제 방법 선택   |
| PaymentConfirmDialog | ⬜   | 수납 확인        |
| PaymentReceipt       | ⬜   | 영수증           |
| **플랜**             |      |                  |
| TuitionPlanList      | ⬜   | 수납금 플랜 목록 |
| TuitionPlanForm      | ⬜   | 플랜 등록/수정   |
| TuitionPlanCard      | ⬜   | 플랜 카드        |
| **통계**             |      |                  |
| PaymentStats         | ⬜   | 결제 통계        |
| PaymentTrendChart    | ⬜   | 결제 추이 차트   |
| PaymentByMethodChart | ⬜   | 결제 방법별 차트 |
| **공통**             |      |                  |
| InvoiceStatusBadge   | ✅   | 청구서 상태 뱃지 |
| PaymentMethodBadge   | ✅   | 결제 방법 뱃지   |
| AmountDisplay        | ⬜   | 금액 표시        |

### 14.3 Server Actions (features/payments/actions)

| Action                       | 상태 | 비고                  |
| ---------------------------- | ---- | --------------------- |
| get-invoices.ts              | ✅   | 청구서 목록           |
| get-invoice.ts               | ✅   | 청구서 상세           |
| create-invoice.ts            | ✅   | 청구서 생성           |
| update-invoice.ts            | ⬜   | 청구서 수정           |
| delete-invoice.ts            | ⬜   | 청구서 삭제           |
| send-invoice.ts              | ✅   | 청구서 발송           |
| generate-monthly-invoices.ts | ⬜   | 월별 청구서 일괄 생성 |
| record-payment.ts            | ✅   | 수납 처리             |
| get-payment-summary.ts       | ✅   | 결제 요약             |
| get-tuition-plans.ts         | ✅   | 플랜 목록             |
| create-tuition-plan.ts       | ✅   | 플랜 생성             |
| update-tuition-plan.ts       | ⬜   | 플랜 수정             |
| delete-tuition-plan.ts       | ⬜   | 플랜 삭제             |

### 14.4 Types (features/payments/types)

| Type           | 상태 | 비고             |
| -------------- | ---- | ---------------- |
| Invoice        | ✅   | 청구서 타입      |
| InvoiceStatus  | ✅   | 청구서 상태 enum |
| Payment        | ✅   | 결제 타입        |
| PaymentMethod  | ✅   | 결제 방법 enum   |
| TuitionPlan    | ✅   | 수납금 플랜      |
| PaymentSummary | ✅   | 결제 요약        |

---

## 15. 직원 관리

### 15.1 페이지

| 페이지         | 상태 | 경로               | 비고 |
| -------------- | ---- | ------------------ | ---- |
| 직원 목록      | ✅   | `/staff`           |      |
| 직원 등록/초대 | ✅   | `/staff/new`       |      |
| 직원 상세      | ✅   | `/staff/[id]`      |      |
| 직원 수정      | ⬜   | `/staff/[id]/edit` |      |

### 15.2 컴포넌트 (features/staff/components)

| 컴포넌트          | 상태 | 비고                 |
| ----------------- | ---- | -------------------- |
| **목록**          |      |                      |
| StaffList         | ✅   | 직원 목록            |
| StaffTable        | ⬜   | 직원 테이블          |
| StaffCard         | ✅   | 직원 카드            |
| StaffFilters      | ⬜   | 필터 (역할 등)       |
| **폼**            |      |                      |
| StaffInviteForm   | ✅   | 직원 초대 폼         |
| StaffForm         | ⬜   | 직원 정보 수정       |
| StaffRoleSelect   | ⬜   | 역할 선택            |
| StaffPermissions  | ⬜   | 권한 설정            |
| **상세**          |      |                      |
| StaffDetail       | ⬜   | 직원 상세            |
| StaffHeader       | ⬜   | 직원 헤더            |
| StaffClassesTab   | ⬜   | 담당 수업 탭         |
| StaffScheduleTab  | ⬜   | 시간표 탭            |
| StaffActivityTab  | ⬜   | 활동 기록 탭         |
| **공통**          |      |                      |
| StaffRoleBadge    | ✅   | 역할 뱃지            |
| StaffStatusBadge  | ⬜   | 상태 뱃지            |
| StaffSelectDialog | ⬜   | 직원 선택 다이얼로그 |

### 15.3 Server Actions (features/staff/actions)

| Action               | 상태 | 비고          |
| -------------------- | ---- | ------------- |
| get-staff.ts         | ✅   | 직원 목록     |
| get-staff-member.ts  | ✅   | 직원 상세     |
| invite-staff.ts      | ✅   | 직원 초대     |
| update-staff.ts      | ✅   | 직원 수정     |
| deactivate-staff.ts  | ✅   | 직원 비활성화 |
| resend-invite.ts     | ⬜   | 초대 재발송   |
| update-staff-role.ts | ✅   | 역할 변경     |

### 15.4 Types (features/staff/types)

| Type             | 상태 | 비고           |
| ---------------- | ---- | -------------- |
| StaffMember      | ✅   | 직원 타입      |
| StaffRole        | ✅   | 역할 enum      |
| StaffWithClasses | ✅   | 담당 수업 포함 |

---

## 16. 메시지 & 알림 관리

### 16.1 페이지

| 페이지           | 상태 | 경로                              | 비고 |
| ---------------- | ---- | --------------------------------- | ---- |
| 알림/메시지 현황 | ✅   | `/notifications`                  |      |
| 메시지 발송      | ⬜   | `/notifications/send`             |      |
| 발송 내역        | ✅   | `/notifications/history`          |      |
| 알림 서비스 연동 | ⬜   | `/settings/messaging-integration` |      |
| 메시지 템플릿    | ⬜   | `/settings/message-templates`     |      |

### 16.2 컴포넌트 (features/notifications/components)

| 컴포넌트                | 상태 | 비고                       |
| ----------------------- | ---- | -------------------------- |
| **인앱 알림**           |      |                            |
| NotificationCenter      | ⬜   | 알림 센터                  |
| NotificationList        | ✅   | 알림 목록                  |
| NotificationItem        | ✅   | 알림 항목                  |
| NotificationBell        | ⬜   | 알림 벨 아이콘             |
| NotificationPopover     | ✅   | 알림 팝오버                |
| NotificationFilters     | ⬜   | 알림 필터                  |
| NotificationSettings    | ⬜   | 알림 설정                  |
| **메시지 발송**         |      |                            |
| MessageComposer         | ⬜   | 메시지 작성기              |
| MessageRecipientSelect  | ⬜   | 수신자 선택                |
| MessageChannelSelect    | ⬜   | 채널 선택 (SMS, 카카오 등) |
| MessageTemplateSelect   | ⬜   | 템플릿 선택                |
| MessagePreview          | ⬜   | 미리보기                   |
| BulkMessageSender       | ⬜   | 일괄 발송                  |
| **발송 내역**           |      |                            |
| MessageLogList          | ✅   | 발송 내역 목록             |
| MessageLogTable         | ⬜   | 발송 테이블                |
| MessageLogDetail        | ⬜   | 발송 상세                  |
| MessageLogFilters       | ✅   | 필터                       |
| **템플릿**              |      |                            |
| MessageTemplateList     | ⬜   | 템플릿 목록                |
| MessageTemplateForm     | ⬜   | 템플릿 등록/수정           |
| MessageTemplateEditor   | ⬜   | 템플릿 에디터              |
| MessageVariables        | ⬜   | 변수 삽입                  |
| **서비스 연동**         |      |                            |
| MessagingProviderList   | ⬜   | 연동 서비스 목록           |
| MessagingProviderForm   | ⬜   | 서비스 연동 설정           |
| MessagingProviderStatus | ⬜   | 연동 상태                  |
| **공통**                |      |                            |
| MessageChannelBadge     | ✅   | 채널 뱃지                  |
| MessageStatusBadge      | ✅   | 발송 상태 뱃지             |
| NotificationTypeBadge   | ✅   | 알림 유형 뱃지             |

### 16.3 Server Actions (features/notifications/actions)

| Action                    | 상태 | 비고              |
| ------------------------- | ---- | ----------------- |
| get-notifications.ts      | ✅   | 알림 목록         |
| mark-notification-read.ts | ✅   | 알림 읽음 처리    |
| mark-all-read.ts          | ✅   | 전체 읽음 처리    |
| get-unread-count.ts       | ✅   | 읽지 않은 알림 수 |
| send-message.ts           | ⬜   | 메시지 발송       |
| send-bulk-message.ts      | ⬜   | 일괄 발송         |
| get-message-logs.ts       | ✅   | 발송 내역         |
| get-message-templates.ts  | ⬜   | 템플릿 목록       |
| create-template.ts        | ⬜   | 템플릿 생성       |
| update-template.ts        | ⬜   | 템플릿 수정       |
| delete-template.ts        | ⬜   | 템플릿 삭제       |
| get-providers.ts          | ⬜   | 연동 서비스 목록  |
| configure-provider.ts     | ⬜   | 서비스 연동 설정  |

### 16.4 Types (features/notifications/types)

| Type              | 상태 | 비고           |
| ----------------- | ---- | -------------- |
| Notification      | ✅   | 알림 타입      |
| NotificationType  | ✅   | 알림 유형 enum |
| MessageLog        | ✅   | 발송 기록      |
| MessageChannel    | ✅   | 채널 enum      |
| MessageStatus     | ✅   | 발송 상태 enum |
| MessageTemplate   | ⬜   | 템플릿 타입    |
| MessagingProvider | ⬜   | 연동 서비스    |

---

## 17. 설정

### 17.1 페이지

| 페이지           | 상태 | 경로                              | 비고              |
| ---------------- | ---- | --------------------------------- | ----------------- |
| 전체 설정        | ⬜   | `/settings`                       | 설정 대시보드     |
| 학원 설정        | ⬜   | `/settings/academy`               | 학원 기본 정보    |
| 과목 관리        | ⬜   | `/settings/subjects`              |                   |
| 알림 서비스 연동 | ⬜   | `/settings/messaging-integration` |                   |
| 메시지 템플릿    | ⬜   | `/settings/message-templates`     |                   |
| 보안 설정        | ⬜   | `/settings/security`              |                   |
| 데이터 관리      | ⬜   | `/settings/data`                  | 내보내기/가져오기 |
| 감사 로그        | ⬜   | `/settings/audit-logs`            |                   |

### 17.2 컴포넌트 (features/settings/components)

| 컴포넌트            | 상태 | 비고                     |
| ------------------- | ---- | ------------------------ |
| **공통**            |      |                          |
| SettingsLayout      | ⬜   | 설정 레이아웃            |
| SettingsSidebar     | ⬜   | 설정 사이드바            |
| SettingsSection     | ⬜   | 설정 섹션                |
| SettingsCard        | ⬜   | 설정 카드                |
| **학원 설정**       |      |                          |
| AcademySettingsForm | ⬜   | 학원 정보 폼             |
| AcademyLogoUpload   | ⬜   | 로고 업로드              |
| BusinessHoursForm   | ⬜   | 운영 시간 설정           |
| AcademyAddressForm  | ⬜   | 주소 설정                |
| **과목 관리**       |      |                          |
| SubjectList         | ⬜   | 과목 목록                |
| SubjectForm         | ⬜   | 과목 등록/수정           |
| SubjectCard         | ⬜   | 과목 카드                |
| SubjectSortable     | ⬜   | 과목 순서 변경           |
| SubjectColorPicker  | ⬜   | 색상 선택                |
| **보안**            |      |                          |
| SecuritySettings    | ⬜   | 보안 설정                |
| PasswordPolicy      | ⬜   | 비밀번호 정책            |
| SessionSettings     | ⬜   | 세션 설정                |
| TwoFactorSetup      | ⬜   | 2FA 설정                 |
| **데이터**          |      |                          |
| DataExport          | ⬜   | 데이터 내보내기          |
| DataImport          | ⬜   | 데이터 가져오기          |
| DataBackup          | ⬜   | 백업 설정                |
| DangerZone          | ⬜   | 위험 영역 (계정 삭제 등) |
| **감사 로그**       |      |                          |
| AuditLogList        | ⬜   | 감사 로그 목록           |
| AuditLogTable       | ⬜   | 로그 테이블              |
| AuditLogDetail      | ⬜   | 로그 상세                |
| AuditLogFilters     | ⬜   | 필터                     |

### 17.3 Server Actions (features/settings/actions)

| Action                     | 상태 | 비고            |
| -------------------------- | ---- | --------------- |
| get-academy-settings.ts    | ⬜   | 학원 설정 조회  |
| update-academy-settings.ts | ⬜   | 학원 설정 수정  |
| get-subjects.ts            | ⬜   | 과목 목록       |
| create-subject.ts          | ⬜   | 과목 생성       |
| update-subject.ts          | ⬜   | 과목 수정       |
| delete-subject.ts          | ⬜   | 과목 삭제       |
| reorder-subjects.ts        | ⬜   | 과목 순서 변경  |
| export-data.ts             | ⬜   | 데이터 내보내기 |
| import-data.ts             | ⬜   | 데이터 가져오기 |
| get-audit-logs.ts          | ⬜   | 감사 로그 조회  |

### 17.4 Types (features/settings/types)

| Type            | 상태 | 비고          |
| --------------- | ---- | ------------- |
| AcademySettings | ⬜   | 학원 설정     |
| Subject         | ⬜   | 과목 타입     |
| AuditLog        | ⬜   | 감사 로그     |
| ExportOptions   | ⬜   | 내보내기 옵션 |

---

## 18. 프로필

### 18.1 페이지

| 페이지        | 상태 | 경로                     | 비고 |
| ------------- | ---- | ------------------------ | ---- |
| 내 프로필     | ⬜   | `/profile`               |      |
| 비밀번호 변경 | ⬜   | `/profile/password`      |      |
| 알림 설정     | ⬜   | `/profile/notifications` |      |

### 18.2 컴포넌트 (features/profile/components)

| 컴포넌트                | 상태 | 비고             |
| ----------------------- | ---- | ---------------- |
| ProfileView             | ⬜   | 프로필 뷰        |
| ProfileForm             | ⬜   | 프로필 수정 폼   |
| ProfileAvatarUpload     | ⬜   | 아바타 업로드    |
| PasswordChangeForm      | ⬜   | 비밀번호 변경 폼 |
| NotificationPreferences | ⬜   | 알림 설정        |
| ProfileHeader           | ⬜   | 프로필 헤더      |

### 18.3 Server Actions (features/profile/actions)

| Action                       | 상태 | 비고           |
| ---------------------------- | ---- | -------------- |
| get-profile.ts               | ⬜   | 프로필 조회    |
| update-profile.ts            | ⬜   | 프로필 수정    |
| change-password.ts           | ⬜   | 비밀번호 변경  |
| update-notification-prefs.ts | ⬜   | 알림 설정 수정 |
| upload-avatar.ts             | ⬜   | 아바타 업로드  |

### 18.4 Types (features/profile/types)

| Type                    | 상태 | 비고        |
| ----------------------- | ---- | ----------- |
| Profile                 | ⬜   | 프로필 타입 |
| NotificationPreferences | ⬜   | 알림 설정   |

---

## 19. 도움말

### 19.1 페이지

| 페이지   | 상태 | 경로              | 비고           |
| -------- | ---- | ----------------- | -------------- |
| 가이드   | ⬜   | `/help/guide`     | 사용 가이드    |
| FAQ      | ⬜   | `/help/faq`       | 자주 묻는 질문 |
| 문의하기 | ⬜   | `/help/contact`   |                |
| 단축키   | ⬜   | `/help/shortcuts` | 키보드 단축키  |

### 19.2 컴포넌트 (features/help/components)

| 컴포넌트       | 상태 | 비고          |
| -------------- | ---- | ------------- |
| GuideList      | ⬜   | 가이드 목록   |
| GuideArticle   | ⬜   | 가이드 문서   |
| FAQAccordion   | ⬜   | FAQ 아코디언  |
| ContactForm    | ⬜   | 문의 폼       |
| ShortcutsTable | ⬜   | 단축키 테이블 |
| SearchHelp     | ⬜   | 도움말 검색   |

---

## 요약 통계

### 전체 진행률

| 카테고리       | 완료 | 진행중 | 미착수 | 합계 |
| -------------- | ---- | ------ | ------ | ---- |
| 인프라 & 공통  | 많음 | 일부   | 일부   | -    |
| 페이지         | 2    | 2      | ~60    | ~64  |
| 컴포넌트       | ~60  | ~5     | ~300   | ~365 |
| Server Actions | 2    | 2      | ~100   | ~104 |
| Types          | ~15  | 0      | ~80    | ~95  |
| Hooks          | 0    | 0      | ~30    | ~30  |

### 우선순위별 작업

#### 🔴 P0 - 핵심 MVP (즉시 착수)

1. 인증 시스템 완성 (로그인/회원가입/로그아웃)
2. 학생 관리 CRUD
3. 보호자 관리 CRUD
4. 수업 관리 CRUD
5. 출결 관리

#### 🟠 P1 - 주요 기능 (MVP 후 착수)

1. TODO & 숙제 관리
2. 성적 & 시험 관리
3. 대시보드 위젯 구현
4. 캘린더

#### 🟡 P2 - 부가 기능

1. 교재 & 도서 관리
2. 상담 관리
3. 리포트 관리
4. 학원비 관리

#### 🟢 P3 - 확장 기능

1. 메시지 & 알림 시스템
2. 직원 관리
3. 설정 고급 기능
4. 도움말

---

## 변경 이력

| 날짜       | 작성자 | 내용      |
| ---------- | ------ | --------- |
| 2024-XX-XX | Claude | 초안 작성 |
