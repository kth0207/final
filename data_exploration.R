# ============================================================
# KOSIS 데이터 탐색 (R 버전)
# ============================================================
# 
# 이 스크립트는 KOSIS 데이터를 탐색하고 시각화합니다.
# 
# 사용법:
#   source("data_exploration.R")
#   또는 RStudio에서 Ctrl+Shift+Enter
#
# ============================================================

# 라이브러리 로드
library(tidyverse)
library(plotly)
library(scales)
library(glue)

cat("============================================================\n")
cat(" KOSIS 데이터 탐색기 (R 버전)\n")
cat("============================================================\n\n")

# ============================================================
# 1. 샘플 데이터 생성
# ============================================================
cat("[1] 샘플 데이터 생성 중...\n")

# IT 직종 취업자 샘플 데이터
set.seed(42)  # 재현 가능성을 위해

years <- 2015:2024
jobs <- c('소프트웨어개발자', '데이터분석가', '정보보안전문가', 
          '시스템엔지니어', 'UI/UX디자이너')

base_values <- list(
  '소프트웨어개발자' = 320000,
  '데이터분석가' = 85000,
  '정보보안전문가' = 65000,
  '시스템엔지니어' = 95000,
  'UI/UX디자이너' = 48000
)

# 데이터프레임 생성
df_employment <- expand.grid(
  연도 = years,
  직종 = jobs,
  stringsAsFactors = FALSE
) %>%
  as_tibble() %>%
  rowwise() %>%
  mutate(
    growth_rate = 1 + (연도 - 2015) * 0.07,
    취업자수 = as.integer(base_values[[직종]] * growth_rate * runif(1, 0.95, 1.05))
  ) %>%
  select(연도, 직종, 취업자수)

cat(glue("✓ IT 취업 데이터: {nrow(df_employment)} rows\n"))

# 인구 데이터
age_groups <- c('15-19', '20-24', '25-29', '30-34', '35-39', 
                '40-44', '45-49', '50-54', '55-59', '60-64')

df_population <- expand.grid(
  연도 = years,
  연령대 = age_groups,
  stringsAsFactors = FALSE
) %>%
  as_tibble() %>%
  rowwise() %>%
  mutate(
    age_start = as.numeric(str_split(연령대, "-")[[1]][1]),
    trend = ifelse(age_start < 30, -0.02, 0.01),
    base_pop = ifelse(age_start < 30, 3200000, 3800000),
    change = 1 + (연도 - 2015) * trend,
    인구수 = as.integer(base_pop * change * runif(1, 0.98, 1.02))
  ) %>%
  select(연도, 연령대, 인구수)

cat(glue("✓ 인구 데이터: {nrow(df_population)} rows\n"))

# ============================================================
# 2. 기본 정보 확인
# ============================================================
cat("\n============================================================\n")
cat("[2] 데이터 기본 정보\n")
cat("============================================================\n\n")

cat("▶ IT 취업 데이터\n")
cat(glue("  기간: {min(df_employment$연도)} ~ {max(df_employment$연도)}\n"))
cat(glue("  직종 수: {n_distinct(df_employment$직종)}\n"))
cat(glue("  총 레코드: {nrow(df_employment)}\n\n"))

cat("▶ 직종별 평균 취업자 (2015-2024)\n")
df_employment %>%
  group_by(직종) %>%
  summarise(평균취업자 = mean(취업자수)) %>%
  arrange(desc(평균취업자)) %>%
  mutate(평균취업자 = comma(평균취업자, accuracy = 1)) %>%
  {
    for(i in 1:nrow(.)) {
      cat(glue("  {.$직종[i]}: {.$평균취업자[i]}명\n"))
    }
  }

# ============================================================
# 3. 핵심 인사이트 계산
# ============================================================
cat("\n============================================================\n")
cat("[3] 핵심 발견 사항\n")
cat("============================================================\n\n")

# IT 전체 증가율
it_2015 <- df_employment %>% 
  filter(연도 == 2015) %>% 
  summarise(sum(취업자수)) %>% 
  pull()

it_2024 <- df_employment %>% 
  filter(연도 == 2024) %>% 
  summarise(sum(취업자수)) %>% 
  pull()

it_growth <- ((it_2024 - it_2015) / it_2015) * 100

cat("📈 IT 직종 취업자 변화:\n")
cat(glue("  2015년: {comma(it_2015)}명\n"))
cat(glue("  2024년: {comma(it_2024)}명\n"))
cat(glue("  증가율: +{round(it_growth, 1)}%\n\n"))

# 청년 인구 변화
youth_ages <- c('15-19', '20-24', '25-29')

youth_2015 <- df_population %>%
  filter(연도 == 2015, 연령대 %in% youth_ages) %>%
  summarise(sum(인구수)) %>%
  pull()

youth_2024 <- df_population %>%
  filter(연도 == 2024, 연령대 %in% youth_ages) %>%
  summarise(sum(인구수)) %>%
  pull()

youth_change <- ((youth_2024 - youth_2015) / youth_2015) * 100

cat("📉 청년 인구 (15-29세) 변화:\n")
cat(glue("  2015년: {comma(youth_2015)}명\n"))
cat(glue("  2024년: {comma(youth_2024)}명\n"))
cat(glue("  변화율: {round(youth_change, 1)}%\n\n"))

cat("🎯 핵심 인사이트:\n")
cat(glue("  ▶ IT는 늘고 (+{round(it_growth, 1)}%), 청년은 줄고 ({round(youth_change, 1)}%)\n"))
cat("  ▶ 기회의 창이 열리고 있습니다!\n")

# ============================================================
# 4. 직종별 성장률
# ============================================================
cat("\n============================================================\n")
cat("[4] 직종별 성장률 (2015 → 2024)\n")
cat("============================================================\n\n")

growth_by_job <- df_employment %>%
  filter(연도 %in% c(2015, 2024)) %>%
  select(연도, 직종, 취업자수) %>%
  pivot_wider(names_from = 연도, values_from = 취업자수, names_prefix = "yr_") %>%
  mutate(
    증가율 = ((yr_2024 - yr_2015) / yr_2015) * 100
  ) %>%
  arrange(desc(증가율))

for(i in 1:nrow(growth_by_job)) {
  cat(glue("  {i}. {growth_by_job$직종[i]}: +{round(growth_by_job$증가율[i], 1)}%\n"))
}

# ============================================================
# 5. 시각화 생성
# ============================================================
cat("\n============================================================\n")
cat("[5] 시각화 생성 중...\n")
cat("============================================================\n\n")

# IT 취업자 추이
fig1 <- plot_ly(df_employment, x = ~연도, y = ~취업자수, 
                color = ~직종, type = 'scatter', mode = 'lines+markers') %>%
  layout(
    title = 'IT 직종별 취업자 수 추이 (2015-2024)',
    xaxis = list(title = '연도'),
    yaxis = list(title = '취업자 수 (명)'),
    hovermode = 'x unified'
  )

htmlwidgets::saveWidget(fig1, "output_it_trend.html")
cat("✓ IT 추이 그래프: output_it_trend.html\n")

# 청년 인구 추이
youth_total <- df_population %>%
  filter(연령대 %in% youth_ages) %>%
  group_by(연도) %>%
  summarise(인구수 = sum(인구수))

fig2 <- plot_ly(youth_total, x = ~연도, y = ~인구수, 
                type = 'scatter', mode = 'lines+markers',
                fill = 'tozeroy',
                line = list(color = 'rgb(255, 0, 0)', width = 3),
                marker = list(size = 10)) %>%
  layout(
    title = '청년 인구 (15-29세) 변화',
    xaxis = list(title = '연도'),
    yaxis = list(title = '인구 (명)')
  )

htmlwidgets::saveWidget(fig2, "output_youth_population.html")
cat("✓ 청년 인구 그래프: output_youth_population.html\n")

# 역설 그래프
it_total <- df_employment %>%
  group_by(연도) %>%
  summarise(취업자수 = sum(취업자수)) %>%
  mutate(IT지수 = (취업자수 / first(취업자수)) * 100)

youth_total <- youth_total %>%
  mutate(청년지수 = (인구수 / first(인구수)) * 100)

fig3 <- plot_ly() %>%
  add_trace(data = it_total, x = ~연도, y = ~IT지수, 
            type = 'scatter', mode = 'lines+markers',
            name = 'IT 취업자',
            line = list(color = 'rgb(0, 0, 255)', width = 3),
            marker = list(size = 10)) %>%
  add_trace(data = youth_total, x = ~연도, y = ~청년지수,
            type = 'scatter', mode = 'lines+markers',
            name = '청년 인구',
            line = list(color = 'rgb(255, 0, 0)', width = 3),
            marker = list(size = 10)) %>%
  layout(
    title = '역설: IT는 늘고, 청년은 줄고 (2015=100)',
    xaxis = list(title = '연도'),
    yaxis = list(title = '지수'),
    hovermode = 'x unified',
    shapes = list(
      list(type = 'line', y0 = 100, y1 = 100, x0 = 2015, x1 = 2024,
           line = list(dash = 'dash', color = 'gray'))
    )
  )

htmlwidgets::saveWidget(fig3, "output_paradox.html")
cat("✓ 역설 그래프: output_paradox.html\n")

cat("\n→ 브라우저에서 HTML 파일을 열어 그래프를 확인하세요!\n")

# ============================================================
# 6. 데이터 저장
# ============================================================
cat("\n============================================================\n")
cat("[6] 데이터 저장\n")
cat("============================================================\n\n")

write_csv(df_employment, "sample_it_employment.csv")
cat("✓ sample_it_employment.csv 저장\n")

write_csv(df_population, "sample_population.csv")
cat("✓ sample_population.csv 저장\n")

# ============================================================
# 7. 요약
# ============================================================
cat("\n============================================================\n")
cat(" 탐색 완료!\n")
cat("============================================================\n\n")

cat("📊 생성된 파일:\n")
cat("  - sample_it_employment.csv\n")
cat("  - sample_population.csv\n")
cat("  - output_it_trend.html\n")
cat("  - output_youth_population.html\n")
cat("  - output_paradox.html\n\n")

cat("💡 다음 단계:\n")
cat("  1. HTML 파일을 브라우저로 열어 그래프 확인\n")
cat("  2. CSV 파일을 Excel로 열어 데이터 확인\n")
cat("  3. KOSIS에서 실제 데이터 다운로드\n")
cat("  4. Quarto 프로젝트에 적용\n\n")

cat("============================================================\n")

# 데이터 미리보기 (선택사항)
cat("\n📋 IT 취업 데이터 미리보기:\n")
print(head(df_employment, 10))

cat("\n📋 인구 데이터 미리보기:\n")
print(head(df_population, 10))
