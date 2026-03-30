"""
Fetch NBS 70-city housing price data from AKShare.
The function takes 2 cities at a time, so we loop through all 70 cities.
Saves panel data to data/ for R analysis.
"""

import akshare as ak
import pandas as pd
import os
import sys
import time

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
os.makedirs(DATA_DIR, exist_ok=True)

# === NBS 70 cities (Chinese names) ===
# These are the standard 70 cities in the NBS housing price index
NBS_70_CITIES = [
    "北京", "天津", "石家庄", "太原", "呼和浩特",
    "沈阳", "大连", "长春", "哈尔滨", "上海",
    "南京", "杭州", "宁波", "合肥", "福州",
    "厦门", "南昌", "济南", "青岛", "郑州",
    "武汉", "长沙", "广州", "深圳", "南宁",
    "海口", "重庆", "成都", "贵阳", "昆明",
    "西安", "兰州", "西宁", "银川", "乌鲁木齐",
    # Additional cities in 70-city panel
    "唐山", "秦皇岛", "包头", "丹东", "锦州",
    "吉林", "牡丹江", "无锡", "扬州", "徐州",
    "温州", "金华", "蚌埠", "安庆", "泉州",
    "九江", "赣州", "烟台", "济宁", "洛阳",
    "平顶山", "宜昌", "襄阳", "岳阳", "常德",
    "韶关", "惠州", "湛江", "桂林", "北海",
    "三亚", "泸州", "南充", "遵义", "大理",
]

# === 22 treated cities under "double concentration" reform ===
TREATED_CITIES_CN = [
    "北京", "上海", "广州", "深圳",
    "南京", "苏州", "杭州", "厦门", "福州",
    "重庆", "成都", "武汉", "郑州", "青岛",
    "济南", "合肥", "长沙", "沈阳", "宁波",
    "长春", "天津", "无锡"
]

# Note: 苏州 (Suzhou) is in the treated list but may not be in the 70-city panel
# We'll handle this gracefully

CN_TO_EN = {
    "北京": "Beijing", "天津": "Tianjin", "石家庄": "Shijiazhuang",
    "太原": "Taiyuan", "呼和浩特": "Hohhot", "沈阳": "Shenyang",
    "大连": "Dalian", "长春": "Changchun", "哈尔滨": "Harbin",
    "上海": "Shanghai", "南京": "Nanjing", "杭州": "Hangzhou",
    "宁波": "Ningbo", "合肥": "Hefei", "福州": "Fuzhou",
    "厦门": "Xiamen", "南昌": "Nanchang", "济南": "Jinan",
    "青岛": "Qingdao", "郑州": "Zhengzhou", "武汉": "Wuhan",
    "长沙": "Changsha", "广州": "Guangzhou", "深圳": "Shenzhen",
    "南宁": "Nanning", "海口": "Haikou", "重庆": "Chongqing",
    "成都": "Chengdu", "贵阳": "Guiyang", "昆明": "Kunming",
    "西安": "Xian", "兰州": "Lanzhou", "西宁": "Xining",
    "银川": "Yinchuan", "乌鲁木齐": "Urumqi",
    "唐山": "Tangshan", "秦皇岛": "Qinhuangdao", "包头": "Baotou",
    "丹东": "Dandong", "锦州": "Jinzhou", "吉林": "Jilin_city",
    "牡丹江": "Mudanjiang", "无锡": "Wuxi", "扬州": "Yangzhou",
    "徐州": "Xuzhou", "温州": "Wenzhou", "金华": "Jinhua",
    "蚌埠": "Bengbu", "安庆": "Anqing", "泉州": "Quanzhou",
    "九江": "Jiujiang", "赣州": "Ganzhou", "烟台": "Yantai",
    "济宁": "Jining", "洛阳": "Luoyang", "平顶山": "Pingdingshan",
    "宜昌": "Yichang", "襄阳": "Xiangyang", "岳阳": "Yueyang",
    "常德": "Changde", "韶关": "Shaoguan", "惠州": "Huizhou",
    "湛江": "Zhanjiang", "桂林": "Guilin", "北海": "Beihai",
    "三亚": "Sanya", "泸州": "Luzhou", "南充": "Nanchong",
    "遵义": "Zunyi", "大理": "Dali", "苏州": "Suzhou",
}


def fetch_all_cities():
    """Fetch housing price data for all 70 cities by iterating city pairs."""
    all_dfs = []
    fetched_cities = set()

    # Create pairs of cities to fetch
    cities_to_fetch = list(NBS_70_CITIES)

    # Also try to fetch Suzhou (苏州) which is treated but may not be in 70-city panel
    if "苏州" not in cities_to_fetch:
        cities_to_fetch.append("苏州")

    # Process in pairs
    for i in range(0, len(cities_to_fetch), 2):
        city1 = cities_to_fetch[i]
        city2 = cities_to_fetch[i + 1] if i + 1 < len(cities_to_fetch) else cities_to_fetch[0]

        if city1 in fetched_cities and city2 in fetched_cities:
            continue

        try:
            df = ak.macro_china_new_house_price(city_first=city1, city_second=city2)
            if len(df) > 0:
                all_dfs.append(df)
                for c in df['城市'].unique():
                    fetched_cities.add(c)
                print(f"  Fetched {city1}/{city2}: {len(df)} rows, cities: {df['城市'].unique()}")
            time.sleep(0.5)  # Rate limiting
        except Exception as e:
            print(f"  Failed {city1}/{city2}: {e}")
            # Try individually
            for city in [city1, city2]:
                if city not in fetched_cities:
                    try:
                        df = ak.macro_china_new_house_price(city_first=city, city_second="北京")
                        city_df = df[df['城市'] == city]
                        if len(city_df) > 0:
                            all_dfs.append(city_df)
                            fetched_cities.add(city)
                            print(f"    Recovered {city}: {len(city_df)} rows")
                        time.sleep(0.5)
                    except Exception as e2:
                        print(f"    Failed {city}: {e2}")

    if not all_dfs:
        print("ERROR: No data fetched!")
        sys.exit(1)

    # Combine all data
    combined = pd.concat(all_dfs, ignore_index=True)

    # Remove duplicates (same city-date)
    combined = combined.drop_duplicates(subset=['日期', '城市'])

    # Add English names and treatment indicator
    combined['city_en'] = combined['城市'].map(CN_TO_EN)
    combined['treated'] = combined['城市'].isin(TREATED_CITIES_CN).astype(int)

    # Rename columns
    combined = combined.rename(columns={
        '日期': 'date',
        '城市': 'city_cn',
        '新建商品住宅价格指数-同比': 'new_house_yoy',
        '新建商品住宅价格指数-环比': 'new_house_mom',
        '新建商品住宅价格指数-定基': 'new_house_base',
        '二手住宅价格指数-同比': 'used_house_yoy',
        '二手住宅价格指数-环比': 'used_house_mom',
        '二手住宅价格指数-定基': 'used_house_base',
    })

    print(f"\nCombined panel: {combined.shape}")
    print(f"Cities fetched: {len(combined['city_cn'].unique())}")
    print(f"Treated cities found: {combined[combined['treated']==1]['city_cn'].nunique()}")
    print(f"Control cities: {combined[combined['treated']==0]['city_cn'].nunique()}")
    print(f"Date range: {combined['date'].min()} to {combined['date'].max()}")

    return combined


if __name__ == '__main__':
    print("Fetching NBS 70-city housing price data...")
    panel = fetch_all_cities()

    # Save
    outpath = os.path.join(DATA_DIR, 'nbs_housing_panel.csv')
    panel.to_csv(outpath, index=False)
    print(f"\nSaved to {outpath}")
    print(f"Total observations: {len(panel)}")
