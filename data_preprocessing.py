"""
KOSIS 데이터 전처리 스크립트

이 스크립트는 KOSIS에서 다운로드한 원본 데이터를 
Quarto 프로젝트에서 사용하기 쉬운 형태로 변환합니다.

사용법:
    python scripts/data_preprocessing.py
"""

import pandas as pd
import numpy as np
from pathlib import Path

# 프로젝트 경로 설정
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"


def load_kosis_csv(filename, encoding='cp949'):
    """
    KOSIS CSV 파일 로드 (인코딩 처리)
    
    Args:
        filename: 파일명
        encoding: 인코딩 (기본값: cp949)
    
    Returns:
        DataFrame
    """
    filepath = DATA_DIR / filename
    try:
        df = pd.read_csv(filepath, encoding=encoding)
        print(f"✓ {filename} 로드 완료 ({len(df)} rows)")
        return df
    except FileNotFoundError:
        print(f"✗ {filename} 파일을 찾을 수 없습니다.")
        print(f"   경로: {filepath}")
        return None
    except Exception as e:
        print(f"✗ {filename} 로드 중 오류: {e}")
        return None


def clean_population_data(df):
    """
    인구 데이터 정제
    
    - 컬럼명 정리
    - 숫자 형식 변환
    - 결측치 처리
    """
    if df is None:
        return None
    
    print("\n[인구 데이터 정제 중...]")
    
    # 컬럼명 간소화 (실제 KOSIS 컬럼명에 맞게 수정 필요)
    # 예시:
    # df.rename(columns={
    #     '시점': '연도',
    #     '연령별(5세)': '연령대',
    #     '인구 (명)': '인구수'
    # }, inplace=True)
    
    # 숫자 컬럼에서 쉼표 제거 및 숫자 변환
    numeric_columns = df.select_dtypes(include=['object']).columns
    for col in numeric_columns:
        if df[col].dtype == 'object':
            # 쉼표 제거 시도
            try:
                df[col] = df[col].str.replace(',', '').astype(float)
            except:
                pass
    
    # 결측치 확인
    missing = df.isnull().sum()
    if missing.any():
        print(f"  결측치 발견: {missing[missing > 0]}")
    
    print("✓ 인구 데이터 정제 완료")
    return df


def clean_employment_data(df):
    """
    고용 데이터 정제
    """
    if df is None:
        return None
    
    print("\n[고용 데이터 정제 중...]")
    
    # IT 관련 직종만 필터링 (예시)
    it_keywords = [
        '소프트웨어', '컴퓨터', '정보', '데이터', 
        '네트워크', '시스템', '프로그래머', '개발'
    ]
    
    # 직업명에 키워드가 포함된 행만 선택 (실제 컬럼명에 맞게 수정)
    # if '직업' in df.columns:
    #     mask = df['직업'].str.contains('|'.join(it_keywords), na=False)
    #     df = df[mask]
    #     print(f"  IT 직종 필터링: {len(df)} rows")
    
    print("✓ 고용 데이터 정제 완료")
    return df


def create_summary_statistics(population_df, employment_df):
    """
    요약 통계 생성
    """
    print("\n[요약 통계 생성 중...]")
    
    summary = {}
    
    if population_df is not None:
        # 최근 연도 인구 (예시)
        # summary['latest_population'] = population_df.groupby('연도')['인구수'].sum().iloc[-1]
        pass
    
    if employment_df is not None:
        # IT 취업자 수 추이 (예시)
        # summary['it_employment_trend'] = employment_df.groupby('연도')['취업자수'].sum()
        pass
    
    print("✓ 요약 통계 생성 완료")
    return summary


def save_processed_data(df, filename):
    """
    처리된 데이터 저장
    """
    if df is None:
        return
    
    output_path = DATA_DIR / f"processed_{filename}"
    df.to_csv(output_path, index=False, encoding='utf-8-sig')
    print(f"✓ 저장 완료: {output_path}")


def main():
    """
    메인 실행 함수
    """
    print("="*60)
    print("KOSIS 데이터 전처리 시작")
    print("="*60)
    
    # 1. 데이터 로드
    print("\n[1단계: 데이터 로드]")
    population_df = load_kosis_csv("kosis_population.csv")
    employment_df = load_kosis_csv("kosis_employment.csv")
    regional_df = load_kosis_csv("kosis_regional_population.csv")
    
    # 2. 데이터 정제
    print("\n[2단계: 데이터 정제]")
    population_clean = clean_population_data(population_df)
    employment_clean = clean_employment_data(employment_df)
    
    # 3. 요약 통계
    print("\n[3단계: 요약 통계]")
    summary = create_summary_statistics(population_clean, employment_clean)
    
    # 4. 데이터 저장
    print("\n[4단계: 처리된 데이터 저장]")
    save_processed_data(population_clean, "population.csv")
    save_processed_data(employment_clean, "employment.csv")
    
    # 5. 완료
    print("\n" + "="*60)
    print("전처리 완료!")
    print("="*60)
    
    # 데이터 미리보기
    if population_clean is not None:
        print("\n[인구 데이터 미리보기]")
        print(population_clean.head())
        print(f"\n형태: {population_clean.shape}")
    
    if employment_clean is not None:
        print("\n[고용 데이터 미리보기]")
        print(employment_clean.head())
        print(f"\n형태: {employment_clean.shape}")


if __name__ == "__main__":
    main()


# ============================================================
# 유틸리티 함수들
# ============================================================

def convert_age_group(age_str):
    """
    연령대 문자열을 숫자로 변환
    
    예: "15-19세" -> 15
    """
    if pd.isna(age_str):
        return None
    
    # 숫자만 추출
    import re
    numbers = re.findall(r'\d+', str(age_str))
    if numbers:
        return int(numbers[0])
    return None


def calculate_growth_rate(df, value_column, year_column='연도'):
    """
    증가율 계산
    
    Args:
        df: DataFrame
        value_column: 값 컬럼명
        year_column: 연도 컬럼명
    
    Returns:
        증가율이 추가된 DataFrame
    """
    df = df.sort_values(year_column)
    df['증가율'] = df[value_column].pct_change() * 100
    return df


def pivot_data_for_visualization(df, index_col, columns_col, values_col):
    """
    시각화를 위한 피벗 테이블 생성
    
    Args:
        df: DataFrame
        index_col: 인덱스로 사용할 컬럼
        columns_col: 컬럼으로 사용할 컬럼
        values_col: 값으로 사용할 컬럼
    
    Returns:
        피벗된 DataFrame
    """
    pivot_df = df.pivot_table(
        index=index_col,
        columns=columns_col,
        values=values_col,
        aggfunc='sum'
    )
    return pivot_df


# ============================================================
# 샘플 데이터 생성 함수 (테스트용)
# ============================================================

def create_sample_data():
    """
    KOSIS 데이터가 없을 때 테스트용 샘플 데이터 생성
    """
    print("\n[샘플 데이터 생성]")
    print("실제 KOSIS 데이터가 없을 경우 테스트용으로 사용")
    
    # 샘플 인구 데이터
    years = range(2015, 2025)
    age_groups = ['15-19', '20-24', '25-29', '30-34']
    
    sample_population = []
    for year in years:
        for age in age_groups:
            population = np.random.randint(2000000, 3500000)
            sample_population.append({
                '연도': year,
                '연령대': age,
                '인구수': population
            })
    
    pop_df = pd.DataFrame(sample_population)
    pop_df.to_csv(DATA_DIR / "sample_population.csv", index=False, encoding='utf-8-sig')
    print("✓ sample_population.csv 생성")
    
    # 샘플 고용 데이터
    jobs = ['소프트웨어개발자', '데이터분석가', '정보보안전문가']
    sample_employment = []
    
    for year in years:
        for job in jobs:
            employment = np.random.randint(50000, 200000)
            sample_employment.append({
                '연도': year,
                '직업': job,
                '취업자수': employment
            })
    
    emp_df = pd.DataFrame(sample_employment)
    emp_df.to_csv(DATA_DIR / "sample_employment.csv", index=False, encoding='utf-8-sig')
    print("✓ sample_employment.csv 생성")
    
    print("\n샘플 데이터로 테스트해보세요!")


# 샘플 데이터 생성이 필요한 경우 아래 주석 해제:
# create_sample_data()
