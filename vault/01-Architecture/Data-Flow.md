---
title: "System Data Flow & Lifecycle"
type: "data-flow"
tags: [data-flow, sequence, lifecycle, async, network]
---

# System Data Flow & Lifecycle

This document traces primary asynchronous and reactive data flows throughout Musify MU.

## 1. Spotify Authentication & Multi-Host Session Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant LoginView as SpotifyLoginWebView
    participant AuthBloc as AuthBloc
    participant SessionProv as AuthSessionProvider
    participant Trans as SpotifyTransport
    participant Spotify as Spotify Pathfinder API

    User->>LoginView: Submits credentials via Webview
    LoginView->>AuthBloc: Emits LoginSuccess(cookies, sp_dc)
    AuthBloc->>SessionProv: Stores session & TOTP secret
    SessionProv->>Trans: Configures Bearer token
    Trans->>Spotify: Requests User Profile via GraphQL
    Spotify-->>Trans: Profile JSON payload
    Trans-->>AuthBloc: AuthState.authenticated(user)
```

## 2. Low-Latency Audio Playback & Sliding Queue

```mermaid
sequenceDiagram
    autonumber
    participant UI as PlayerScreen
    participant Ctrl as PlaybackController
    participant QMgr as PlaybackQueueManager
    participant AudioSvc as AudioPlaybackService
    participant Notif as AudioNotificationHandler

    UI->>Ctrl: playTrack(track, contextQueue)
    Ctrl->>QMgr: setQueue(contextQueue, startIndex)
    QMgr->>AudioSvc: loadWindow(tracks[0..50])
    AudioSvc->>Notif: syncMediaItem(currentTrack)
    Notif-->>UI: PlaybackState.playing + MediaItem
```

## 3. Kodiak Reactive Feeds & Background Protobuf Decoding

```mermaid
sequenceDiagram
    autonumber
    participant FeedBloc as HomeFeedBloc
    participant Casita as CasitaParser
    participant Isolate as ProtobufIsolate
    participant Pool as KodiakDataPool
    participant UI as HomeFeedView

    FeedBloc->>Casita: fetchHomeFeed()
    Casita->>Isolate: decode(rawBytes)
    Isolate-->>Casita: CasitaResolved protobuf
    Casita->>Pool: insertCells(elements, traits)
    Pool-->>FeedBloc: HomeViewData (cards & sections)
    FeedBloc-->>UI: emit(HomeFeedLoaded)
```

## 4. Asynchronous 401 Mutex Token Recovery

```mermaid
sequenceDiagram
    autonumber
    participant ReqA as In-Flight Request A
    participant ReqB as In-Flight Request B
    participant Mutex as TokenRefreshMutex
    participant Refresher as SpotifyTokenRefresher

    ReqA->>Mutex: 401 Unauthorized received
    ReqB->>Mutex: 401 Unauthorized received (blocks on mutex)
    Mutex->>Refresher: refreshAccessToken()
    Refresher-->>Mutex: New Access Token
    Mutex-->>ReqA: Replay with fresh token -> 200 OK
    Mutex-->>ReqB: Replay with fresh token -> 200 OK
```
