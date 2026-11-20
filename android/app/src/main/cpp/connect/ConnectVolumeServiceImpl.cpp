// ============================================================================
// 1:1 Replicated Spotify Esperanto ConnectVolumeService Native Adapter
// Sources:
// - `liborbit-jni-spotify.so` (arm64): `spotify::connect::esperanto::proto::ConnectVolumeService`
//   dispatcher @ `0xe40268`, vtable @ `0x18f49a0` (handlers `0xe3d1b0..0xe3d80e`)
// - Decompiled Java: `p199p/C2086nd.java`, `p199p/lw51.java`, `p199p/a0f1.java`, `p199p/a170.java`
// ============================================================================

#include "ConnectVolumeServiceImpl.h"

#include <algorithm>
#include <utility>

#include "../network/NativeLog.h"

namespace spotify::connectstate::esperanto {

ConnectVolumeServiceImpl::ConnectVolumeServiceImpl(ConnectSubsystem& subsystem)
    : subsystem_(subsystem) {}

EsperantoCallResult ConnectVolumeServiceImpl::dispatch(
    std::string_view method,
    const uint8_t* payload,
    size_t len) {
    if (method == "Volume") return handle_volume(payload, len);
    if (method == "LocalVolume") return handle_local_volume(payload, len);
    if (method == "VolumeSet") return handle_volume_set(payload, len);
    if (method == "VolumeUp") return handle_volume_up(payload, len);
    if (method == "VolumeDown") return handle_volume_down(payload, len);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kUnknownMethod,
        .payload = {},
    };
}

VolumeResponse ConnectVolumeServiceImpl::build_volume_response(
    const ConnectVolumeSnapshot& snapshot) const {
    VolumeResponse resp;
    const std::string local_id = subsystem_.devices().local_device_id();
    if (snapshot.active_device_connect_state_identifier.empty() && local_id.empty()) {
        resp.status = Status::NOT_FOUND;
    } else {
        resp.status = Status::OK;
        const uint32_t bounded =
            std::min<uint32_t>(snapshot.volume, ConnectSubsystem::kMaxVolumeSteps);
        resp.volume = static_cast<int32_t>(bounded);
    }

    if (!snapshot.active_device_connect_state_identifier.empty()) {
        resp.active_device_connect_state_identifier =
            snapshot.active_device_connect_state_identifier;
    }
    for (const auto& [group_id, vol] : snapshot.group_device_volumes) {
        resp.group_device_volumes[group_id] = vol;
    }
    return resp;
}

std::vector<uint8_t> ConnectVolumeServiceImpl::encode_volume_snapshot(
    const ConnectVolumeSnapshot& snapshot) const {
    return encode_volume_response(build_volume_response(snapshot));
}

std::vector<uint8_t> ConnectVolumeServiceImpl::encode_local_volume(
    uint32_t volume,
    spotify::connectstate::LocalVolumeReason reason) const {
    LocalVolumeResponse resp;
    resp.volume = static_cast<int32_t>(
        std::min<uint32_t>(volume, ConnectSubsystem::kMaxVolumeSteps));
    resp.reason = reason == spotify::connectstate::LocalVolumeReason::kSystem
                      ? LocalVolumeReason::SYSTEM
                      : LocalVolumeReason::USER;
    return encode_local_volume_response(resp);
}

EsperantoCallResult ConnectVolumeServiceImpl::handle_volume(
    const uint8_t* payload,
    size_t len) const {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_volume_snapshot(subsystem_.current_volume_snapshot()),
    };
}

EsperantoCallResult ConnectVolumeServiceImpl::handle_local_volume(
    const uint8_t* payload,
    size_t len) const {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    const ConnectVolumeSnapshot snap = subsystem_.current_volume_snapshot();
    const spotify::connectstate::LocalVolumeReason reason =
        (snap.local_reason == "remote" || snap.local_reason == "system")
            ? spotify::connectstate::LocalVolumeReason::kSystem
            : spotify::connectstate::LocalVolumeReason::kUser;
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_local_volume(snap.local_volume, reason),
    };
}

uint32_t ConnectVolumeServiceImpl::resolve_volume_step(
    const std::string& group_device_id) const {
    const std::string target_id = !group_device_id.empty()
                                      ? group_device_id
                                      : subsystem_.devices().active_device_id();
    int32_t steps = 0;
    if (!group_device_id.empty()) {
        const auto member_vols = subsystem_.devices().group_device_volumes_snapshot();
        const auto it = member_vols.find(group_device_id);
        if (it != member_vols.end() && it->second.volume_steps > 0) {
            steps = it->second.volume_steps;
        }
    }
    if (steps <= 0 && !target_id.empty()) {
        if (const auto dev = subsystem_.devices().find_device(target_id)) {
            steps = dev->capabilities.volume_steps;
        }
    }
    if (steps <= 0) {
        steps = subsystem_.devices().local_device_info().capabilities.volume_steps;
    }
    if (steps > 0) {
        const uint32_t computed =
            ConnectSubsystem::kMaxVolumeSteps / static_cast<uint32_t>(steps);
        return computed > 0 ? computed : 1U;
    }
    return ConnectSubsystem::kDefaultVolumeStep;
}

EsperantoCallResult ConnectVolumeServiceImpl::handle_volume_set(
    const uint8_t* payload,
    size_t len) {
    VolumeSetRequest req;
    if (!decode_volume_set_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (req.volume < 0 || !is_valid_command_id(req.logging_params)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    const uint32_t bounded = std::min<uint32_t>(
        static_cast<uint32_t>(req.volume), ConnectSubsystem::kMaxVolumeSteps);
    const std::string group_id = req.group_device_identifier.value_or("");
    const AckHttpResult res = subsystem_.volume_set(bounded, group_id);
    if (!res.ok && !res.throttled) {
        CONNECT_LOGW(
            "ConnectVolumeService::VolumeSet failed vol=%u group=%s http=%d err=%s",
            bounded,
            group_id.c_str(),
            res.http_status,
            res.error_message.c_str());
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            (res.ok || res.throttled) ? Status::OK : Status::BACKEND_FAILURE),
    };
}

EsperantoCallResult ConnectVolumeServiceImpl::handle_volume_up(
    const uint8_t* payload,
    size_t len) {
    VolumeStepRequest req;
    if (!decode_volume_step_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (!is_valid_command_id(req.logging_params)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    const std::string group_id = req.group_device_identifier.value_or("");
    const uint32_t step = resolve_volume_step(group_id);
    const AckHttpResult res = subsystem_.volume_up(step, group_id);
    if (!res.ok && !res.throttled) {
        CONNECT_LOGW(
            "ConnectVolumeService::VolumeUp failed group=%s http=%d err=%s",
            group_id.c_str(),
            res.http_status,
            res.error_message.c_str());
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            (res.ok || res.throttled) ? Status::OK : Status::BACKEND_FAILURE),
    };
}

EsperantoCallResult ConnectVolumeServiceImpl::handle_volume_down(
    const uint8_t* payload,
    size_t len) {
    VolumeStepRequest req;
    if (!decode_volume_step_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (!is_valid_command_id(req.logging_params)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    const std::string group_id = req.group_device_identifier.value_or("");
    const uint32_t step = resolve_volume_step(group_id);
    const AckHttpResult res = subsystem_.volume_down(step, group_id);
    if (!res.ok && !res.throttled) {
        CONNECT_LOGW(
            "ConnectVolumeService::VolumeDown failed group=%s http=%d err=%s",
            group_id.c_str(),
            res.http_status,
            res.error_message.c_str());
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            (res.ok || res.throttled) ? Status::OK : Status::BACKEND_FAILURE),
    };
}

}  // namespace spotify::connectstate::esperanto
