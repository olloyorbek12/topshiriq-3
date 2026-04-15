# Shifoxona Navbat Smart-kontrakti

Bu loyiha shifoxonada navbat olish uchun Solidity smart-kontraktini yaratadi.

## Talablar Qanday Bajarilgan

- `takeQueue(uint8 serviceType)` funksiyasi `payable`.
- To‘lov faqat `allowedPayer` adresidan qabul qilinadi.
- Minimal to‘lov `require(msg.value >= minPayment)` bilan tekshiriladi.
- Shart bajarilsa pul `hospitalWallet` yoki `emergencyWallet` adreslariga o‘tkaziladi.
- `if/else` yordamida 3 holat bor:
- `serviceType == 1`: shoshilinch navbat, pul to‘liq `emergencyWallet`ga ketadi.
- `msg.value >= vipPayment`: VIP navbat, 70% shifoxonaga, 20% emergency walletga, 10% kontraktda qoladi.
- Aks holda oddiy navbat, 90% shifoxonaga, 10% kontraktda qoladi.
- `mapping(address => uint256) userBalances` foydalanuvchi jami qancha to‘laganini saqlaydi.
- `withdraw()` funksiyasini faqat contract egasi chaqira oladi.
- To‘lov bo‘lganda `QueuePaid` va `MoneyRouted` eventlari `emit` qilinadi.

## O‘rnatish

```powershell
cd "C:\Users\Odilbek_PC\Downloads\web3_project_version3-main\web3_project_version3-main"
npm install
```

## Compile Qilish

```powershell
npm run compile
```

## Demo Ishga Tushirish

Demo local Hardhat simulated networkda kontraktni deploy qiladi va quyidagilarni ko‘rsatadi:

- noto‘g‘ri adresdan to‘lov rad etilishi;
- oddiy navbat to‘lovi;
- VIP navbat to‘lovi;
- shoshilinch navbat to‘lovi;
- mapping balansni o‘qish;
- owner tomonidan kontrakt zaxirasini yechib olish.
- terminalda bo‘limlar (`Deployment`, `Access checks`, `Queue payments`, `Final stats`) bo‘yicha ko‘rinishli loglar.

```powershell
npm run demo
```

## Localhost Deploy

1-terminal:

```powershell
npm run node
```

2-terminal:

```powershell
npm run deploy:localhost
```

Deploy script chiqargan `Allowed payer` adresi faqat to‘lov qila oladigan adres hisoblanadi.
