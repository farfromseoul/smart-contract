# Giwa ERC20 Token Sale – 전체 플로우 & 시행착오 정리

> **목표**
>
> * Giwa Sepolia 테스트넷에서 ERC20 토큰을 직접 발행
> * 토큰 판매(Sale) 스마트 컨트랙트 구현
> * MetaMask + Remix 기반으로 배포/구매/잔고 확인까지 전 과정 경험
> * 실제로 겪은 시행착오를 통해 개념 정리

---

## 1. 전체 구조 한눈에 보기

```
[Seller (EOA)]
   │
   │ 1) ERC20 토큰 배포 & 초기 민팅
   ▼
[MyToken (ERC20)]
   │
   │ 2) 판매 재고 공급 (transfer)
   ▼
[SaleToken (Token Sale Contract)]
   │
   │ 3) ETH 지불 + buyToken()
   ▼
[Buyer (EOA)]
```

---

## 2. 사전 준비 상태

* MetaMask 설치
* Giwa Sepolia 네트워크 추가
* Faucet으로 소량의 테스트 ETH 확보
* Remix IDE 사용

---

## 3. MyToken (ERC20) 설계 및 배포

### 핵심 설계

* ERC20 표준 기반
* `decimals = 18`
* 배포 시 모든 토큰은 **배포자(owner)** 지갑으로 민팅

### 핵심 포인트

* ERC20에서 **주소 = 정체성**
* 같은 코드라도 **여러 번 배포하면 서로 다른 토큰**
* MetaMask는 **ERC20 표준 함수(balanceOf, decimals 등)** 만 보고 토큰을 인식

### 결과

* Seller 계정이 초기 전체 공급량 보유

---

## 4. SaleToken (토큰 판매 컨트랙트) 설계

### 역할

* ERC20 토큰을 보관(재고)
* ETH를 받고 토큰을 구매자에게 전달

### 핵심 함수

* `buyToken()`

  * payable 함수
  * 구매 수량은 **msg.value / pricePerToken** 으로 계산
* `withdrawETH()`

  * 판매자가 누적된 ETH 출금

### 가격 정책 예시

```
1 GTG = 0.000001 ETH = 1000 gwei
```

---

## 5. 실제 배포 & 실행 순서

1. **Seller 계정으로 MyToken 배포**
2. **Seller 계정으로 SaleToken 배포**

   * 생성자에 MyToken 주소 전달
3. **Seller → SaleToken으로 토큰 재고 공급**

   * ERC20 `transfer(SaleToken, amount)`
4. **Buyer 계정으로 buyToken() 실행**

   * Value 필드에 ETH 입력

---

## 6. buyToken 동작 방식 이해

### 중요한 개념

* `buyToken()`에는 입력 파라미터가 없음
* 구매 수량은 **함수 입력값이 아니라 msg.value(ETH)** 로 결정됨

### 예시

| 구매 토큰 수 | Value 입력   |
| ------- | ---------- |
| 1 GTG   | 1000 gwei  |
| 10 GTG  | 10000 gwei |

---

## 7. MetaMask에서 토큰이 보이는 원리

### MetaMask가 할 수 있는 것

* **EOA(지갑 계정)** 기준으로 ERC20 잔고 표시
* ERC20 표준 함수 호출로 토큰 인식

### MetaMask가 못 하는 것

* 컨트랙트 주소의 토큰 잔고 조회
* ERC20이 아닌 컨트랙트를 토큰처럼 표시

### 중요한 결론

* **MyToken(ERC20)** 은 MetaMask에서 보임
* **SaleToken(일반 컨트랙트)** 은 MetaMask에서 잔고 조회 불가
* 컨트랙트 잔고는 항상 `MyToken.balanceOf(address)`로 확인

---

## 8. 실제로 겪은 주요 시행착오 정리

### 1) buyToken 실행했는데 아무 일도 안 일어남

* 원인: `Value`에 ETH를 입력하지 않음
* 해결: Remix 상단 Value 필드에 gwei 단위로 ETH 입력

---

### 2) MetaMask 서명 팝업이 안 뜸

* 원인: Remix Environment가 `Injected Provider - MetaMask` 아님
* 해결: Environment 재선택 후 MetaMask 연결 승인

---

### 3) "Not enough token" 에러 발생

* 원인: SaleToken에 토큰 재고가 없음
* 해결: Seller → SaleToken으로 ERC20 transfer 실행

---

### 4) SaleToken 주소에서 토큰이 0으로 보임

* 원인: MetaMask는 컨트랙트 주소 잔고 조회 불가
* 해결: Remix에서 `balanceOf(SaleToken주소)`로 확인

---

### 5) 토큰이 여러 개 보이거나 잔고가 이상함

* 원인: 같은 코드로 MyToken을 여러 번 배포
* 해결:

  * 실제 사용하는 MyToken 주소만 기준으로 확인
  * MetaMask에서 안 쓰는 토큰 제거

---

### 6) 실패했던 buyToken이 실제 구매된 것처럼 보임

* 원인: 성공 트랜잭션만 상태 변경됨
* 정리:

  * revert된 트랜잭션은 **구매 아님**
  * 실제 잔고는 성공한 트랜잭션의 누적 결과

---

## 9. 핵심 개념 요약 (가장 중요)

* ERC20은 **표준 인터페이스**
* 지갑과 툴은 **코드를 이해하지 않고 표준만 신뢰**
* 토큰 이동의 진실은 항상:

```
balanceOf(address)
```

* MetaMask는 **지갑 UI**이지 **컨트랙트 디버거가 아님**

---

## 10. 최종 상태 요약

* ERC20 토큰 발행 성공
* 토큰 판매 컨트랙트 정상 동작
* Buyer 구매 및 잔고 확인 완료
* 주소 / 계정 / 컨트랙트 역할 명확히 구분 가능

---

## 11. 다음 단계로 확장 가능 항목

* OpenZeppelin ERC20으로 리팩토링
* approve / allowance 구조 학습
* 프론트엔드(dApp) 연동
* DEX 스왑 구조 이해
* 토큰 이코노미 설계 (mint / burn / cap)

---
## 12. 판매자가 WithDraw 전에 구매자가 납부한 대금은 어디에?

* SaleToken Contract 주소를 Sepolia Explorer에서 조회 하면 ETH 수량이 확인됨
* WithDraw 기능이 없다면 영원히 자금이 묶일수있음
* WithDraw 하면 해당 컨트랙트를 배포한 Owner의 EOA 지갑으로 인출됨


## 13. Seller(Owner), Buyer EOA Account Status

<img width="450" height="350" alt="Image" src="https://github.com/user-attachments/assets/09034e5a-9d2d-4610-b8ca-333603cc83ba" />

<img width="450" height="350" alt="Image" src="https://github.com/user-attachments/assets/566cdf89-5fa8-4bde-a040-228d94689a3a" />

---


> 이 문서는 **실습 기반 학습 기록** 이며, GIWA Sepolia 체인에서 학습함
