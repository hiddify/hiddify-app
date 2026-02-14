//
//  DartBridge.swift
//  Runner
//
//  Created by Aleksandr Strizhnev on 20.02.2025.
//

import Foundation

struct DartApiEntry {
    var name: UnsafePointer<CChar>?
    var function: (@convention(c) () -> Void)?
}

struct DartApi {
    var major: Int32
    var minor: Int32
    var functions: UnsafePointer<DartApiEntry>?
}

enum Dart_CObject_Type: Int {
    case kNull = 0
    case kBool
    case kInt32
    case kInt64
    case kDouble
    case kString
    case kArray
    case kTypedData
    case kExternalTypedData
    case kSendPort
    case kCapability
    case kNativePointer
    case kUnsupported
    case kUnmodifiableExternalTypedData
    case kNumberOfTypes
}

struct Dart_CObject {
    var type: Dart_CObject_Type
    
    enum Dart_CObjectUnion {
        case string(UnsafePointer<CChar>?)
        case int32(Int32)
        case int64(Int64)
        case double(Double)

        var stringValue: String? {
            if case .string(let stringPointer) = self {
                return stringPointer.map { String(cString: $0) }
            }
            return nil
        }
    }
    
    var value: Dart_CObjectUnion
    
    init(type: Dart_CObject_Type, stringValue: UnsafePointer<CChar>?) {
        self.type = type
        self.value = .string(stringValue)
    }
    
    func getString() -> String? {
        guard type == .kString else { return nil }
        return value.stringValue
    }
}

func getString(from rawPointer: UnsafeRawPointer) -> String? {
    let dartCObject = rawPointer.bindMemory(to: Dart_CObject.self, capacity: 1)
    return dartCObject.pointee.getString()
}

var Dart_PortListener: ((Int64, UnsafeRawPointer?) -> Void)? = nil

@_cdecl("Dart_PostCObject")
func Dart_PostCObject(port_id: Int64, message: UnsafeRawPointer?) -> Bool {
    Dart_PortListener?(port_id, message)

    return true
}

@_cdecl("Dart_PostInteger")
func Dart_PostInteger(port_id: Int64, message: Int64) -> Bool {
    return false
}

@_cdecl("Dart_NewNativePort")
func Dart_NewNativePort(name: UnsafePointer<CChar>?, handler: UnsafeRawPointer?, handle_concurrently: Bool) -> Int64 {
    return 0
}

@_cdecl("Dart_CloseNativePort")
func Dart_CloseNativePort(native_port_id: Int64) -> Bool {
    return false
}

@_cdecl("Dart_IsError")
func Dart_IsError(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_IsApiError")
func Dart_IsApiError(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_IsUnhandledExceptionError")
func Dart_IsUnhandledExceptionError(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_IsCompilationError")
func Dart_IsCompilationError(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_IsFatalError")
func Dart_IsFatalError(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_GetError")
func Dart_GetError(handle: UnsafeRawPointer?) -> UnsafePointer<CChar>? {
    return nil
}

@_cdecl("Dart_ErrorHasException")
func Dart_ErrorHasException(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_ErrorGetException")
func Dart_ErrorGetException(handle: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_ErrorGetStackTrace")
func Dart_ErrorGetStackTrace(handle: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_NewApiError")
func Dart_NewApiError(error: UnsafePointer<CChar>?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_NewCompilationError")
func Dart_NewCompilationError(error: UnsafePointer<CChar>?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_NewUnhandledExceptionError")
func Dart_NewUnhandledExceptionError(exception: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_PropagateError")
func Dart_PropagateError(handle: UnsafeRawPointer?) {
}

@_cdecl("Dart_HandleFromPersistent")
func Dart_HandleFromPersistent(object: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_HandleFromWeakPersistent")
func Dart_HandleFromWeakPersistent(object: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_NewPersistentHandle")
func Dart_NewPersistentHandle(object: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_SetPersistentHandle")
func Dart_SetPersistentHandle(obj1: UnsafeRawPointer?, obj2: UnsafeRawPointer?) {
}

@_cdecl("Dart_DeletePersistentHandle")
func Dart_DeletePersistentHandle(object: UnsafeRawPointer?) {
}

@_cdecl("Dart_NewWeakPersistentHandle")
func Dart_NewWeakPersistentHandle(object: UnsafeRawPointer?, peer: UnsafeRawPointer?, external_allocation_size: Int, callback: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_DeleteWeakPersistentHandle")
func Dart_DeleteWeakPersistentHandle(object: UnsafeRawPointer?) {
}

@_cdecl("Dart_NewFinalizableHandle")
func Dart_NewFinalizableHandle(object: UnsafeRawPointer?, peer: UnsafeRawPointer?, external_allocation_size: Int, callback: UnsafeRawPointer?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_DeleteFinalizableHandle")
func Dart_DeleteFinalizableHandle(object: UnsafeRawPointer?, strong_ref_to_object: UnsafeRawPointer?) {
}

@_cdecl("Dart_CurrentIsolate")
func Dart_CurrentIsolate() -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_ExitIsolate")
func Dart_ExitIsolate() {
}

@_cdecl("Dart_EnterIsolate")
func Dart_EnterIsolate(isolate: UnsafeRawPointer?) {
}

@_cdecl("Dart_Post")
func Dart_Post(port_id: Int64, object: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_NewSendPort")
func Dart_NewSendPort(port_id: Int64) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_SendPortGetId")
func Dart_SendPortGetId(port: UnsafeRawPointer?, port_id: UnsafeMutablePointer<Int64>?) -> UnsafeRawPointer? {
    return nil
}

@_cdecl("Dart_EnterScope")
func Dart_EnterScope() {
}

@_cdecl("Dart_ExitScope")
func Dart_ExitScope() {
}

@_cdecl("Dart_IsNull")
func Dart_IsNull(handle: UnsafeRawPointer?) -> Bool {
    return false
}

@_cdecl("Dart_UpdateExternalSize")
func Dart_UpdateExternalSize(object: UnsafeRawPointer?, external_allocation_size: Int) {
}

@_cdecl("Dart_UpdateFinalizableExternalSize")
func Dart_UpdateFinalizableExternalSize(object: UnsafeRawPointer?, strong_ref_to_object: UnsafeRawPointer?, external_allocation_size: Int) {
}

func persistentCString(_ string: String) -> UnsafePointer<CChar> {
    guard let ptr = strdup(string) else {
        fatalError("Failed to strdup \(string)")
    }
    return UnsafePointer(ptr)
}

let dartApiEntries: [DartApiEntry] = [
    DartApiEntry(
        name: persistentCString("Dart_PostCObject"),
        function: unsafeBitCast(
            Dart_PostCObject as @convention(c) (Int64, UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_PostInteger"),
        function: unsafeBitCast(
            Dart_PostInteger as @convention(c) (Int64, Int64) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewNativePort"),
        function: unsafeBitCast(
            Dart_NewNativePort as @convention(c) (UnsafePointer<CChar>?, UnsafeRawPointer?, Bool) -> Int64,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_CloseNativePort"),
        function: unsafeBitCast(
            Dart_CloseNativePort as @convention(c) (Int64) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_IsError"),
        function: unsafeBitCast(
            Dart_IsError as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_IsApiError"),
        function: unsafeBitCast(
            Dart_IsApiError as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_IsUnhandledExceptionError"),
        function: unsafeBitCast(
            Dart_IsUnhandledExceptionError as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_IsCompilationError"),
        function: unsafeBitCast(
            Dart_IsCompilationError as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_IsFatalError"),
        function: unsafeBitCast(
            Dart_IsFatalError as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_GetError"),
        function: unsafeBitCast(
            Dart_GetError as @convention(c) (UnsafeRawPointer?) -> UnsafePointer<CChar>?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_ErrorHasException"),
        function: unsafeBitCast(
            Dart_ErrorHasException as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_ErrorGetException"),
        function: unsafeBitCast(
            Dart_ErrorGetException as @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_ErrorGetStackTrace"),
        function: unsafeBitCast(
            Dart_ErrorGetStackTrace as @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewApiError"),
        function: unsafeBitCast(
            Dart_NewApiError as @convention(c) (UnsafePointer<CChar>?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewCompilationError"),
        function: unsafeBitCast(
            Dart_NewCompilationError as @convention(c) (UnsafePointer<CChar>?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewUnhandledExceptionError"),
        function: unsafeBitCast(
            Dart_NewUnhandledExceptionError as @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_PropagateError"),
        function: unsafeBitCast(
            Dart_PropagateError as @convention(c) (UnsafeRawPointer?) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_HandleFromPersistent"),
        function: unsafeBitCast(
            Dart_HandleFromPersistent as @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_HandleFromWeakPersistent"),
        function: unsafeBitCast(
            Dart_HandleFromWeakPersistent as @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewPersistentHandle"),
        function: unsafeBitCast(
            Dart_NewPersistentHandle as @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_SetPersistentHandle"),
        function: unsafeBitCast(
            Dart_SetPersistentHandle as @convention(c) (UnsafeRawPointer?, UnsafeRawPointer?) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_DeletePersistentHandle"),
        function: unsafeBitCast(
            Dart_DeletePersistentHandle as @convention(c) (UnsafeRawPointer?) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewWeakPersistentHandle"),
        function: unsafeBitCast(
            Dart_NewWeakPersistentHandle as @convention(c) (UnsafeRawPointer?, UnsafeRawPointer?, Int, UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_DeleteWeakPersistentHandle"),
        function: unsafeBitCast(
            Dart_DeleteWeakPersistentHandle as @convention(c) (UnsafeRawPointer?) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewFinalizableHandle"),
        function: unsafeBitCast(
            Dart_NewFinalizableHandle as @convention(c) (UnsafeRawPointer?, UnsafeRawPointer?, Int, UnsafeRawPointer?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_DeleteFinalizableHandle"),
        function: unsafeBitCast(
            Dart_DeleteFinalizableHandle as @convention(c) (UnsafeRawPointer?, UnsafeRawPointer?) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_CurrentIsolate"),
        function: unsafeBitCast(
            Dart_CurrentIsolate as @convention(c) () -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_ExitIsolate"),
        function: Dart_ExitIsolate as @convention(c) () -> Void
    ),
    DartApiEntry(
        name: persistentCString("Dart_EnterIsolate"),
        function: unsafeBitCast(
            Dart_EnterIsolate as @convention(c) (UnsafeRawPointer?) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_Post"),
        function: unsafeBitCast(
            Dart_Post as @convention(c) (Int64, UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_NewSendPort"),
        function: unsafeBitCast(
            Dart_NewSendPort as @convention(c) (Int64) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_SendPortGetId"),
        function: unsafeBitCast(
            Dart_SendPortGetId as @convention(c) (UnsafeRawPointer?, UnsafeMutablePointer<Int64>?) -> UnsafeRawPointer?,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_EnterScope"),
        function: Dart_EnterScope as @convention(c) () -> Void
    ),
    DartApiEntry(
        name: persistentCString("Dart_ExitScope"),
        function: Dart_ExitScope as @convention(c) () -> Void
    ),
    DartApiEntry(
        name: persistentCString("Dart_IsNull"),
        function: unsafeBitCast(
            Dart_IsNull as @convention(c) (UnsafeRawPointer?) -> Bool,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_UpdateExternalSize"),
        function: unsafeBitCast(
            Dart_UpdateExternalSize as @convention(c) (UnsafeRawPointer?, Int) -> Void,
            to: (@convention(c) () -> Void).self
        )
    ),
    DartApiEntry(
        name: persistentCString("Dart_UpdateFinalizableExternalSize"),
        function: unsafeBitCast(
            Dart_UpdateFinalizableExternalSize as @convention(c) (UnsafeRawPointer?, UnsafeRawPointer?, Int) -> Void,
            to: (@convention(c) () -> Void).self
        )
    )
]

let entryCount = dartApiEntries.count
let pinnedApiEntries = UnsafeMutablePointer<DartApiEntry>.allocate(capacity: entryCount)

var dartApi = DartApi(major: 2, minor: 3, functions: UnsafePointer(pinnedApiEntries))

let pinnedDartApi = UnsafeMutablePointer<DartApi>.allocate(capacity: 1)

let rawDartApiPointer: UnsafeRawPointer = UnsafeRawPointer(pinnedDartApi)

func setDartPortListener(_ listener: @escaping (Int64, UnsafeRawPointer?) -> Void) {
    Dart_PortListener = listener
}

func createDartApi() -> UnsafeRawPointer {
    pinnedApiEntries.initialize(from: dartApiEntries, count: entryCount)
    pinnedDartApi.initialize(to: dartApi)
    
    return rawDartApiPointer
}
