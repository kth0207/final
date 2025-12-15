# ============================================================
# IT 인구 프로젝트 - R 패키지 설치
# ============================================================

# 필수 패키지 목록
packages <- c(
  # 데이터 처리
  "tidyverse",      # dplyr, ggplot2, tidyr, readr 등 포함
  "data.table",     # 대용량 데이터 처리
  
  # 시각화
  "plotly",         # 인터랙티브 그래프
  "ggplot2",        # 정적 그래프 (tidyverse에 포함)
  "scales",         # 그래프 스케일 조정
  "RColorBrewer",   # 색상 팔레트
  
  # 데이터 불러오기
  "readr",          # CSV 읽기 (tidyverse에 포함)
  "readxl",         # Excel 파일
  "haven",          # SPSS, SAS 파일
  
  # 테이블 출력
  "knitr",          # Quarto/RMarkdown 필수
  "kableExtra",     # 예쁜 테이블
  "DT",             # 인터랙티브 테이블
  
  # 유틸리티
  "lubridate",      # 날짜 처리 (tidyverse에 포함)
  "glue",           # 문자열 처리
  "here"            # 경로 관리
)

# 설치 함수
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package, dependencies = TRUE)
    library(package, character.only = TRUE)
  }
}

# 패키지 설치
cat("R 패키지 설치 시작...\n")
cat("==============================================\n\n")

for (pkg in packages) {
  cat(sprintf("설치 중: %s\n", pkg))
  install_if_missing(pkg)
}

cat("\n==============================================\n")
cat("✓ 모든 패키지 설치 완료!\n\n")

# 설치된 패키지 버전 확인
cat("설치된 패키지 버전:\n")
cat("----------------------------------------------\n")
for (pkg in packages) {
  if (require(pkg, character.only = TRUE)) {
    version <- packageVersion(pkg)
    cat(sprintf("  %-20s %s\n", pkg, version))
  }
}

cat("\n")
cat("이제 Quarto 프로젝트를 실행할 준비가 되었습니다!\n")
cat("  quarto preview\n")

