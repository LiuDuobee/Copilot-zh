# Copilot Desktop 涓枃鍖栬祫婧?

杩欐槸涓€涓?*鐙珛鐨勩€侀潪渚靛叆寮?*涓枃鍖栬祫婧愰」鐩紝鐢ㄤ簬缁存姢 GitHub Copilot Desktop 鐨勭増鏈寲缈昏瘧鏄犲皠锛屽苟鍦ㄦ柊鐗堟湰鍙戝竷鍚庤嚜鍔ㄥ彂鐜版柊澧炵晫闈㈡枃鏈€?

鏈」鐩笉浼氫慨鏀广€侀噸鎵撳寘鎴栫粫杩?GitHub Copilot Desktop 鐨勪唬鐮佺鍚嶅拰鑷姩鏇存柊鏈哄埗銆傚彧鏈夊湪瀹樻柟鎻愪緵鍙姞杞界殑璇█璧勬簮鎺ュ彛锛屾垨鐢ㄦ埛鏄庣‘浣跨敤鍏煎鐨勫閮ㄨ鐩栧眰鏃讹紝缈昏瘧璧勬簮鎵嶈兘琚疄闄呭姞杞藉埌瀹㈡埛绔€?

## 褰撳墠鍔熻兘

- 缁存姢鎸夌増鏈粍缁囩殑鑻辨枃閿笌绠€浣撲腑鏂囩炕璇戙€?
- 浠庢湰鍦板鍑虹殑 Desktop 璧勬簮鏂囦欢涓壂鎻忚嫳鏂囨枃鏈€?
- 瀵圭収缈昏瘧鏄犲皠锛屾姤鍛婄己澶辩炕璇戙€?
- 鏌ヨ GitHub Releases锛屾娴嬩笂娓哥増鏈彉鍖栥€?
- GitHub Actions 瀹氭湡妫€鏌ユ渶鏂扮増鏈苟鐢熸垚寰呯炕璇戞竻鍗曘€?

鐢变簬 Copilot Desktop 鐨勫畼鏂瑰彂甯冨厓鏁版嵁鍦板潃涓嶅湪鏈」鐩腑鍏紑澹版槑锛屾洿鏂板櫒瑕佹眰閫氳繃
`COPILOT_RELEASES_URL` 鏄惧紡閰嶇疆鍙俊鐨勭増鏈厓鏁版嵁鎺ュ彛銆傛帴鍙ｅ簲杩斿洖鍖呭惈 `tag_name`
鎴?`name` 瀛楁鐨?JSON锛屽苟鍙€夎繑鍥?`html_url`銆?

## 浣跨敤

```powershell
npm run check
npm run scan -- .\resources\copilot-desktop.json
$env:COPILOT_RELEASES_URL = "https://example.invalid/releases/latest"
npm run update
```

`scan` 鎺ュ彈 JSON銆丣avaScript銆丠TML 鎴栫函鏂囨湰璧勬簮鏂囦欢銆傚畠鍙敓鎴愭姤鍛婏紝涓嶄細淇敼杈撳叆鏂囦欢銆?

## 璧勬簮鏍煎紡

缈昏瘧璧勬簮浣嶄簬 `locales\zh-CN.json`锛屾牸寮忓涓嬶細

```json
{
  "meta": {
    "source": "GitHub Copilot Desktop",
    "locale": "zh-CN",
    "upstreamVersion": "latest"
  },
  "messages": {
    "Settings": "璁剧疆"
  }
}
```

## 鍚堣璇存槑

璇烽伒瀹?GitHub Copilot Desktop 鐨勮鍙€佸晢鏍囧拰鏈嶅姟鏉℃銆備笉瑕佸垎鍙戜慨鏀瑰悗鐨勫畼鏂瑰畨瑁呭寘锛屼篃涓嶈缁曡繃绛惧悕楠岃瘉鎴栬嚜鍔ㄦ洿鏂颁繚鎶ゃ€?
