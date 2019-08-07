# 기본 기능셋

1. Networking
* URLSession을 통한 네트워킹
* 네트워킹 결과인 Result를 연관 값으로하여 성공일 경우 data를, 실패일 경우 error를 설정

2. Model & Parser
* Model : ConciseCity, DetailCity, DailyWeather, HourlyWeather
* JSON Parser : userLocation, city, cities, detail에 따른 Parsing Process 진행

3. API 응답을 이용한 날씨 정보화면 구축
* 리스트 화면 : OpenWeather API (단일 지역, 복수 지역, 날씨 이미지)
* 상세 화면 : DarkSky API (단일 지여 상세)

4-1. 검색
* MKLocalSearchCompleter로 디테일한 주소 검출
* 검출한 주소들과 MKLocalSearch로 MKMapItem 검출

4-2. Reduce MKLocalSearch Request
* Request를 자주, 짧은 시간동안 여러번 Call하게되면 결과를 받지 못하는 Issue 발생
* Request Call을 줄이기 위해 검색한 데이터를 Dictionary(key: search bar text)로 저장
* search bar text가 dictionary key와 일치할 경우 저장된 데이터를 보여줌
* dictionary key가 search bar text의 일부일 경우, search bar text를 포함한 결과에 대한 요청은 배제

# 추가 구현 내용

1. User Location

* LocationManager를 활용하여 사용자 GPS 정보 도출
* OpenWeather API는 한글로 설정해도 이름이 영어로 나옴
* CLGeocoder를 활용하여 이름 검출 및 Parsing Process 진행

2. 시계

* Timer를 활용한 시계
* 처음 시간을 받고 60초에서 처음 시간의 초를 뺀 후 처리 위임(update data)
* 이후, 60초 간격으로 처리 위임(update data)

3. 데이터 캐싱
* 비행기 모드 등으로 데이터 이용이 제한되는 경우 이전 데이터를 나타냄
* ConciseCity와 DetailCity가 Codable Protocol 준수(UserDefault에 저장할 수 있도록)
* ConciseCity는 배열형태로 UserDefault에 저장
* DetailCity는 해당 ConciseCity의 name을 key로 하여 저장
* Networking에 실패할 경우, 저장된 데이터를 


