// ============================================================================
// 1:1 Replicated Spotify Esperanto DodoService Native Adapter
// Sources:
// - `liborbit-jni-spotify.so` (arm64): `spotify::connect::esperanto::proto::DodoService`
//   dispatcher @ `0xe3fdb4`, vtable @ `0x18f4a08` (`0xe3de2e`, `0xe3def8`, `0xe3e0d2`)
// - `dodos_messages.proto` descriptor offset `5714450` / `0x5a1dd0`
// ============================================================================

#include "DodoServiceImpl.h"

#include "../network/NativeLog.h"

namespace spotify::connectstate::esperanto {
namespace {

Status map_cluster_http_status(const ClusterHttpResult& res) {
    if (res.ok) {
        return Status::OK;
    }
    if (res.http_status == 404) {
        return Status::NOT_FOUND;
    }
    if (res.http_status == 501) {
        return Status::UNIMPLEMENTED;
    }
    return Status::BACKEND_FAILURE;
}

}  // namespace

DodoServiceImpl::DodoServiceImpl(ConnectSubsystem& subsystem)
    : subsystem_(subsystem) {}

EsperantoCallResult DodoServiceImpl::dispatch(
    std::string_view method,
    const uint8_t* payload,
    size_t len) {
    if (method == "DodoSub" || method == "Dodos" || method == "Sub") {
        return handle_dodo_sub(payload, len);
    }
    if (method == "SwitchToDodo") return handle_switch_to_dodo(payload, len);
    if (method == "CreateNewDodo") return handle_create_new_dodo(payload, len);
    if (method == "EndDodo") return handle_end_dodo(payload, len);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kUnknownMethod,
        .payload = {},
    };
}

std::vector<uint8_t> DodoServiceImpl::encode_dodos(
    const std::vector<spotify::connectstate::SingleDodo>& dodos) const {
    return encode_dodo_sub_response(dodos);
}

EsperantoCallResult DodoServiceImpl::handle_dodo_sub(
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
        .payload = encode_dodo_sub_response(subsystem_.list_dodos()),
    };
}

EsperantoCallResult DodoServiceImpl::handle_switch_to_dodo(
    const uint8_t* payload,
    size_t len) {
    SwitchToDodoRequest req;
    if (!decode_switch_to_dodo_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (req.cs_id.empty()) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::NOT_FOUND),
        };
    }
    const ClusterHttpResult res = subsystem_.switch_to_dodo(req.cs_id);
    if (!res.ok) {
        CONNECT_LOGW(
            "DodoService::SwitchToDodo failed cs_id=%s http=%d err=%s",
            req.cs_id.c_str(),
            res.http_status,
            res.error_message.c_str());
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(map_cluster_http_status(res)),
    };
}

EsperantoCallResult DodoServiceImpl::handle_create_new_dodo(
    const uint8_t* payload,
    size_t len) {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    const ClusterHttpResult res = subsystem_.create_new_dodo();
    if (!res.ok) {
        CONNECT_LOGW(
            "DodoService::CreateNewDodo failed http=%d err=%s",
            res.http_status,
            res.error_message.c_str());
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(map_cluster_http_status(res)),
    };
}

EsperantoCallResult DodoServiceImpl::handle_end_dodo(
    const uint8_t* payload,
    size_t len) {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    const ClusterHttpResult res = subsystem_.end_dodo();
    if (!res.ok) {
        CONNECT_LOGW(
            "DodoService::EndDodo failed http=%d err=%s",
            res.http_status,
            res.error_message.c_str());
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(map_cluster_http_status(res)),
    };
}

}  // namespace spotify::connectstate::esperanto
