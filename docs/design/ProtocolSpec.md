# 통신 프로토콜 명세서 (Protocol Specification)

## 현재 구현: wire protocol v3 (2026-09-12)

아래 v1 문서는 초기 설계입니다. 현재 `PacketEncoder`/`PacketDecoder`는 16바이트 공통 헤더와 Codable JSON 본문을 사용하며, Protobuf 정의는 실제 직렬화 경로에 연결되지 않았습니다.

- TCP는 TLS 1.3을 필수로 사용합니다. 정확한 버전 `0x03`과 최대 4 MiB 본문 길이를 확인하고 분할·연속 프레임을 처리합니다. 불완전 프레임으로 끝나거나 헤더가 잘못되면 연결을 종료합니다.
- 마우스 클릭은 메시지 ID `0x02`를 유지하되 TCP로 전송합니다. 이동·스크롤·자이로·핀치는 UDP를 사용합니다.
- 처음 연결하는 TLS 인증서는 임시로 관찰하되 아직 신뢰하지 않습니다. 이때 보내는 Handshake에는 기기 식별 정보만 포함하며, 제어 명령과 인증 토큰은 전송하지 않습니다.
- Mac의 QR 코드는 `snap-pair:` + Base64(JSON)입니다. version=3, serverID, 실제 TLS 인증서의 SHA-256 digest, 32바이트 challenge, 32바이트 일회성 비밀의 Base64 문자열(`pin`)을 포함합니다. 코드는 네트워크로 전송하지 않으며 60초 동안 해당 연결에서만 유효합니다.
- PairingChallenge에는 기기 이름·ID와 nonce만 보냅니다. 클라이언트는 직접 스캔하거나 붙여넣은 코드의 인증서·서버 ID·nonce가 현재 연결과 일치해야 PairingResponse에 비밀(`pinCode`)과 nonce를 전송합니다. 4자리 PIN은 지원하지 않습니다.
- 페어링 성공 시 서버가 새 32바이트 `authenticationToken`을 Keychain에 저장하고 TLS Handshake로 전달합니다. 클라이언트는 토큰과 인증서를 함께 Keychain에 저장합니다. 재연결 시 TLS 인증서를 고정 검증하고 토큰을 제출하며, 서버는 신뢰 기기 메타데이터와 토큰을 모두 확인합니다. ID만으로 수락하지 않습니다.
- 수락된 매 연결마다 새 32바이트 `udpSessionKey`를 TLS Handshake로 전달합니다. HKDF-SHA256(salt=`Snap UDP v3`, info=`client-to-server` 또는 `server-to-client`, output=32)으로 방향별 AES-GCM 키를 파생합니다.
- UDP wire format: `nonce (12 bytes) | encrypted packet | tag (16 bytes)`. nonce는 `53 4e 00 03` + big-endian UInt64 시퀀스(1부터)이며 AAD는 UTF-8 `Snap UDP v3`입니다. 인증 성공 후 마지막 수락 시퀀스 이하를 폐기합니다. 지연된 역순 데이터그램도 폐기하며, 세션 교체 시 이전 키와 카운터를 버립니다.
- 인증되지 않은 TCP 제어 명령과 암호화·인증되지 않은 UDP는 거부합니다. UDP 허용 메시지는 이동·스크롤·자이로·핀치로 제한합니다.

v1/v2와 직접 연결되지 않으므로 두 앱을 함께 업데이트하고 다시 페어링해야 합니다. 자세한 운영·검증 범위는 [보안 페어링 문서](../dev/secure-pairing.md)에 기록합니다.

---

| 버전 | v1.0.0 |
| --- | --- |
| **작성일** | 2025년 12월 27일 |
| **관련 문서** | PRD.md |

---

## 1. 개요 (Overview)

### 1.1 전송 계층 (Transport Layer)

| 프로토콜 | 용도 | 특성 |
| --- | --- | --- |
| **UDP** | 마우스/트랙패드 좌표, 자이로스코프 데이터 | 초저지연, 패킷 손실 허용 |
| **TCP** | 키보드 입력, 시스템 명령, 미디어 제어 | 신뢰성 보장, 순서 보장 |

### 1.2 직렬화 (Serialization)

- **Format:** Google Protocol Buffers (Protobuf 3)
- **Endianness:** Little Endian
- **문자 인코딩:** UTF-8

### 1.3 서비스 디스커버리 (Service Discovery)

- **Protocol:** Bonjour (mDNS/DNS-SD)
- **Service Type:** `_snap._tcp.` (TCP), `_snap._udp.` (UDP)
- **Domain:** `local.`

---

## 2. 패킷 구조 (Packet Structure)

### 2.1 공통 헤더

모든 패킷은 공통 헤더로 시작합니다.

```
+--------+--------+--------+--------+
|  Magic (2B)     | Version| Type   |
+--------+--------+--------+--------+
|          Timestamp (8B)           |
+--------+--------+--------+--------+
|          Payload Length (4B)      |
+--------+--------+--------+--------+
|          Payload (Variable)       |
+--------+--------+--------+--------+
```

| 필드 | 크기 | 설명 |
| --- | --- | --- |
| Magic | 2 bytes | `0x534E` ("SN" - Snap) |
| Version | 1 byte | 프로토콜 버전 (현재 `0x01`) |
| Type | 1 byte | 메시지 타입 (섹션 3 참조) |
| Timestamp | 8 bytes | Unix timestamp (microseconds) |
| Payload Length | 4 bytes | Payload 크기 (bytes) |
| Payload | Variable | Protobuf 인코딩된 데이터 |

### 2.2 메시지 타입 (Message Types)

#### UDP 메시지 (0x00 ~ 0x1F)

| Type | Name | 설명 | 전송 주기 |
| --- | --- | --- | --- |
| `0x01` | `MOUSE_MOVE` | 마우스 이동 (상대 좌표) | ~120Hz |
| `0x02` | `MOUSE_CLICK` | 마우스 클릭 | 이벤트 발생 시 |
| `0x03` | `SCROLL` | 스크롤 (2D) | ~60Hz |
| `0x04` | `GYRO_DATA` | 자이로스코프 데이터 | ~60Hz |

#### TCP 메시지 (0x20 ~ 0x7F)

| Type | Name | 설명 | 방향 |
| --- | --- | --- | --- |
| `0x20` | `KEY_EVENT` | 키보드 입력 | iOS → Mac |
| `0x21` | `KEY_COMBO` | 단축키 조합 | iOS → Mac |
| `0x30` | `MEDIA_CONTROL` | 재생/정지/볼륨 | iOS → Mac |
| `0x40` | `WINDOW_SNAP` | 윈도우 정렬 | iOS → Mac |
| `0x50` | `APP_LIST_REQUEST` | 실행 중인 앱 목록 요청 | iOS → Mac |
| `0x51` | `APP_LIST_RESPONSE` | 앱 목록 응답 | Mac → iOS |
| `0x52` | `APP_FOCUS` | 앱 포커스 전환 | iOS → Mac |
| `0x60` | `PRESENTATION` | 발표 제어 (슬라이드 넘김) | iOS → Mac |
| `0x70` | `VOICE_TEXT` | 음성 인식 텍스트 | iOS → Mac |

#### 시스템 메시지 (0x80 ~ 0xFF)

| Type | Name | 설명 | 방향 |
| --- | --- | --- | --- |
| `0x80` | `HANDSHAKE` | 연결 초기화 | 양방향 |
| `0x81` | `HEARTBEAT` | 연결 유지 확인 | 양방향 |
| `0x82` | `DISCONNECT` | 연결 종료 | 양방향 |
| `0xFE` | `ACK` | 응답 확인 | 양방향 |
| `0xFF` | `ERROR` | 에러 응답 | Mac → iOS |

---

## 3. Protobuf 메시지 정의

### 3.1 공통 타입

```protobuf
syntax = "proto3";
package snap;

// 2D 좌표
message Point {
  float x = 1;
  float y = 2;
}

// 3D 벡터 (자이로스코프용)
message Vector3 {
  float x = 1;
  float y = 2;
  float z = 3;
}
```

### 3.2 마우스/트랙패드 (UDP)

```protobuf
// 마우스 이동 (상대 좌표)
message MouseMove {
  float delta_x = 1;  // X축 이동량
  float delta_y = 2;  // Y축 이동량
}

// 마우스 클릭
message MouseClick {
  enum Button {
    LEFT = 0;
    RIGHT = 1;
    MIDDLE = 2;
  }
  enum Action {
    DOWN = 0;
    UP = 1;
    CLICK = 2;      // DOWN + UP
    DOUBLE = 3;     // 더블 클릭
  }
  Button button = 1;
  Action action = 2;
}

// 스크롤
message Scroll {
  float delta_x = 1;  // 수평 스크롤
  float delta_y = 2;  // 수직 스크롤
  bool is_inertia = 3;  // 관성 스크롤 여부
}
```

### 3.3 자이로스코프 (UDP)

```protobuf
// 자이로스코프 데이터 (Laser Pointer용)
message GyroData {
  Vector3 rotation_rate = 1;  // rad/s
  Vector3 attitude = 2;       // roll, pitch, yaw (rad)
  float sensitivity = 3;      // 감도 배율
}
```

### 3.4 키보드 (TCP)

```protobuf
// 키 이벤트
message KeyEvent {
  enum Action {
    DOWN = 0;
    UP = 1;
    PRESS = 2;  // DOWN + UP
  }

  uint32 key_code = 1;    // macOS virtual key code
  Action action = 2;
  uint32 modifiers = 3;   // 비트 플래그 (아래 참조)
  string character = 4;   // 입력 문자 (UTF-8)
}

// Modifier 비트 플래그
// 0x01: Shift
// 0x02: Control
// 0x04: Option (Alt)
// 0x08: Command
// 0x10: Caps Lock
// 0x20: Function

// 단축키 조합 (매크로용)
message KeyCombo {
  repeated uint32 key_codes = 1;
  uint32 modifiers = 2;
}
```

### 3.5 미디어 제어 (TCP)

```protobuf
message MediaControl {
  enum Command {
    PLAY_PAUSE = 0;
    NEXT_TRACK = 1;
    PREV_TRACK = 2;
    VOLUME_UP = 3;
    VOLUME_DOWN = 4;
    MUTE = 5;
    SET_VOLUME = 6;  // 절대값 설정
  }

  Command command = 1;
  float volume = 2;      // SET_VOLUME 시 0.0 ~ 1.0
}
```

### 3.6 윈도우 스냅 (TCP)

```protobuf
message WindowSnap {
  enum Position {
    LEFT_HALF = 0;
    RIGHT_HALF = 1;
    TOP_HALF = 2;
    BOTTOM_HALF = 3;
    FULL_SCREEN = 4;
    CENTER = 5;
    TOP_LEFT = 6;
    TOP_RIGHT = 7;
    BOTTOM_LEFT = 8;
    BOTTOM_RIGHT = 9;
  }

  Position position = 1;
}
```

### 3.7 앱 스위처 (TCP, 양방향)

```protobuf
// 앱 목록 요청 (iOS → Mac)
message AppListRequest {
  // 빈 메시지
}

// 앱 정보
message AppInfo {
  string bundle_id = 1;
  string name = 2;
  bytes icon_data = 3;  // PNG 데이터 (64x64)
  bool is_active = 4;
  uint32 pid = 5;
}

// 앱 목록 응답 (Mac → iOS)
message AppListResponse {
  repeated AppInfo apps = 1;
}

// 앱 포커스 전환 (iOS → Mac)
message AppFocus {
  string bundle_id = 1;
  uint32 pid = 2;
}
```

### 3.8 발표 제어 (TCP)

```protobuf
message Presentation {
  enum Command {
    NEXT_SLIDE = 0;
    PREV_SLIDE = 1;
    START = 2;
    END = 3;
    BLANK_SCREEN = 4;  // 화면 끄기 (B키)
  }

  Command command = 1;
}
```

### 3.9 음성 텍스트 (TCP)

```protobuf
message VoiceText {
  string text = 1;
  bool is_final = 2;  // 인식 완료 여부
}
```

### 3.10 시스템 메시지

```protobuf
// 핸드셰이크
message Handshake {
  string device_name = 1;
  string device_id = 2;     // UUID
  uint32 protocol_version = 3;
  string app_version = 4;
}

// 하트비트
message Heartbeat {
  uint64 timestamp = 1;
}

// 에러
message Error {
  enum Code {
    UNKNOWN = 0;
    INVALID_PACKET = 1;
    UNSUPPORTED_VERSION = 2;
    PERMISSION_DENIED = 3;
    INTERNAL_ERROR = 4;
  }

  Code code = 1;
  string message = 2;
}

// ACK
message Ack {
  uint64 original_timestamp = 1;
}
```

---

## 4. 연결 흐름 (Connection Flow)

### 4.1 초기 연결

```
iOS                                    macOS
  |                                      |
  |--- Bonjour: Browse _snap._tcp. ----->|
  |<-- Bonjour: Service Resolved --------|
  |                                      |
  |=== TCP Connect =====================>|
  |--- HANDSHAKE ----------------------->|
  |<-- HANDSHAKE / ERROR ----------------|
  |                                      |
  |=== UDP Socket Open =================>|
  |--- HEARTBEAT (UDP) ----------------->|
  |<-- HEARTBEAT (UDP) ------------------|
  |                                      |
```

### 4.2 연결 유지

- **TCP Heartbeat:** 5초 간격
- **UDP Heartbeat:** 1초 간격
- **Timeout:** 15초간 응답 없으면 연결 종료

### 4.3 연결 종료

```
iOS                                    macOS
  |                                      |
  |--- DISCONNECT (TCP) ---------------->|
  |<-- ACK -----------------------------|
  |=== TCP Close =======================>|
  |=== UDP Close ========================>|
  |                                      |
```

---

## 5. 포트 할당 (Port Assignment)

| 서비스 | 포트 | 프로토콜 |
| --- | --- | --- |
| TCP 제어 채널 | 51234 | TCP |
| UDP 데이터 채널 | 51235 | UDP |

---

## 6. 보안 고려사항 (Security Considerations)

### 6.1 현재 (MVP)

- 동일 로컬 네트워크 내에서만 동작
- Bonjour 서비스 광고로 자동 검색
- 별도 인증 없음 (신뢰된 네트워크 가정)

### 6.2 향후 (Post-MVP)

- [ ] TLS 1.3 암호화 (TCP)
- [ ] DTLS 1.2 암호화 (UDP)
- [ ] 페어링 코드 기반 인증
- [ ] 디바이스 화이트리스트
