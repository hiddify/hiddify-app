import Foundation
import HiddifyCore
import Network
import Security
import XCTest

/// Simulator smoke for local-core mTLS (mirrors Android MtlsGrpcSmokeTest):
/// 1) start gRPC in mode 1
/// 2) register the fixture client certificate
/// 3) complete a TLS handshake to 127.0.0.1
final class MtlsGrpcSmokeTest: XCTestCase {
  func testMtlsServerAcceptsRegisteredClientCert() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("hiddify-mtls-ios-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let port: UInt16 = 17078
    let opts = MobileSetupOptions()
    opts.basePath = dir.path
    opts.workingDir = dir.path
    opts.tempDir = dir.path
    opts.listen = "127.0.0.1:\(port)"
    opts.secret = ""
    opts.debug = true
    opts.mode = 1
    opts.fixAndroidStack = false

    var setupError: NSError?
    MobileSetup(opts, nil, &setupError)
    XCTAssertNil(setupError, "MobileSetup failed: \(setupError?.localizedDescription ?? "")")
    defer { MobileClose(1) }

    let serverPem = try XCTUnwrap(MobileGetServerPublicKey(), "empty server public key")
    let serverPemString = String(data: serverPem, encoding: .utf8) ?? ""
    XCTAssertTrue(
      serverPemString.contains("BEGIN CERTIFICATE"),
      "server cert must be PEM, got \(serverPem.count) bytes"
    )

    let bundles: [Bundle] = {
      var list = [Bundle(for: MtlsGrpcSmokeTest.self)]
      #if SWIFT_PACKAGE
      list.append(Bundle.module)
      #endif
      return list
    }()
    func resourceURL(name: String, ext: String) -> URL? {
      for bundle in bundles {
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")
          ?? bundle.url(forResource: name, withExtension: ext) {
          return url
        }
      }
      return nil
    }
    let clientCertURL = try XCTUnwrap(resourceURL(name: "mtls_client", ext: "crt"), "mtls_client.crt missing")
    let clientP12URL = try XCTUnwrap(resourceURL(name: "mtls_client", ext: "p12"), "mtls_client.p12 missing")
    let clientCertPem = try Data(contentsOf: clientCertURL)
    let clientP12 = try Data(contentsOf: clientP12URL)

    var addError: NSError?
    MobileAddGrpcClientPublicKey(clientCertPem, &addError)
    XCTAssertNil(addError, "AddGrpcClientPublicKey failed: \(addError?.localizedDescription ?? "")")

    let identity = try loadIdentity(from: clientP12, password: "test")
    let serverCert = try loadCertificate(fromPEM: serverPem)

    let expectation = expectation(description: "mtls handshake")
    var handshakeError: Error?
    var didComplete = false

    let queue = DispatchQueue(label: "mtls.smoke")
    let tlsOptions = NWProtocolTLS.Options()
    sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
    guard let secIdentity = sec_identity_create(identity) else {
      return XCTFail("sec_identity_create failed")
    }
    sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)

    // Pin by comparing leaf to the PEM from MobileGetServerPublicKey; accept on match.
    sec_protocol_options_set_verify_block(
      tlsOptions.securityProtocolOptions,
      { _, trust, complete in
        let secTrust = sec_trust_copy_ref(trust).takeRetainedValue()
        guard let chain = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate],
              let leaf = chain.first
        else {
          complete(false)
          return
        }
        let leafData = SecCertificateCopyData(leaf) as Data
        let expectedData = SecCertificateCopyData(serverCert) as Data
        complete(leafData == expectedData)
      },
      queue
    )

    let params = NWParameters(tls: tlsOptions)
    let connection = NWConnection(
      host: NWEndpoint.Host("127.0.0.1"),
      port: NWEndpoint.Port(rawValue: port)!,
      using: params
    )

    connection.stateUpdateHandler = { state in
      NSLog("mtls smoke state: \(String(describing: state))")
      switch state {
      case .ready:
        didComplete = true
        expectation.fulfill()
      case .failed(let error):
        handshakeError = error
        expectation.fulfill()
      case .waiting(let error):
        // Keep waiting briefly; record last error for diagnostics.
        handshakeError = error
      case .cancelled:
        if !didComplete {
          handshakeError = handshakeError ?? NSError(
            domain: "MtlsSmoke",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "connection cancelled"]
          )
          expectation.fulfill()
        }
      default:
        break
      }
    }
    connection.start(queue: queue)

    wait(for: [expectation], timeout: 10)
    connection.cancel()

    XCTAssertNil(handshakeError, "TLS handshake failed: \(String(describing: handshakeError))")
    XCTAssertTrue(didComplete, "TLS handshake did not reach ready")
  }

  private func loadCertificate(fromPEM pem: Data) throws -> SecCertificate {
    let text = String(data: pem, encoding: .utf8) ?? ""
    let b64 = text
      .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
      .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
      .components(separatedBy: .whitespacesAndNewlines)
      .joined()
    guard let der = Data(base64Encoded: b64),
          let cert = SecCertificateCreateWithData(nil, der as CFData)
    else {
      throw NSError(domain: "MtlsSmoke", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "failed to parse server PEM",
      ])
    }
    return cert
  }

  private func loadIdentity(from p12: Data, password: String) throws -> SecIdentity {
    let options: [String: Any] = [kSecImportExportPassphrase as String: password]
    var items: CFArray?
    let status = SecPKCS12Import(p12 as CFData, options as CFDictionary, &items)
    guard status == errSecSuccess,
          let array = items as? [[String: Any]],
          let first = array.first,
          let identity = first[kSecImportItemIdentity as String] as! SecIdentity?
    else {
      throw NSError(domain: "MtlsSmoke", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "failed to import client p12 (osStatus=\(status))",
      ])
    }
    return identity
  }
}
