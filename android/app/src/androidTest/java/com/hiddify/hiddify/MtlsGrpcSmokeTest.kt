package com.hiddify.hiddify

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.hiddify.core.mobile.Mobile
import com.hiddify.core.mobile.SetupOptions
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.ByteArrayInputStream
import java.security.KeyStore
import java.security.SecureRandom
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.TrustManagerFactory

/**
 * Emulator smoke for local-core mTLS:
 * 1) start gRPC in mode 1 (GRPC_NORMAL)
 * 2) register the fixture client certificate
 * 3) complete a TLS handshake to 127.0.0.1
 */
@RunWith(AndroidJUnit4::class)
class MtlsGrpcSmokeTest {

    @Test
    fun mtlsServerAcceptsRegisteredClientCert() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val assets = InstrumentationRegistry.getInstrumentation().context.assets
        val dir = ctx.filesDir.resolve("mtls-smoke").apply { mkdirs() }.absolutePath
        val port = 17078

        Mobile.setup(
            SetupOptions().also {
                it.basePath = dir
                it.workingDir = dir
                it.tempDir = dir
                it.listen = "127.0.0.1:$port"
                it.mode = 1L
                it.secret = ""
                it.debug = true
                it.fixAndroidStack = false
            },
            null,
        )

        try {
            val serverPem = Mobile.getServerPublicKey()
            assertTrue(
                "server cert must be PEM, got ${serverPem.size} bytes",
                String(serverPem).contains("BEGIN CERTIFICATE"),
            )

            val clientCertPem = assets.open("mtls_client.crt").readBytes()
            Mobile.addGrpcClientPublicKey(clientCertPem)

            val password = "test".toCharArray()
            val clientStore = KeyStore.getInstance("PKCS12").apply {
                load(assets.open("mtls_client.p12"), password)
            }
            val factory = sslSocketFactory(serverPem, clientStore, password)

            val socket = factory.createSocket("127.0.0.1", port) as SSLSocket
            try {
                socket.soTimeout = 5_000
                socket.startHandshake()
                assertTrue(socket.session.isValid)
                assertFalse(socket.session.peerCertificates.isNullOrEmpty())
            } finally {
                socket.close()
            }
        } finally {
            Mobile.close(1)
        }
    }

    private fun sslSocketFactory(
        serverPem: ByteArray,
        clientKeyStore: KeyStore,
        password: CharArray,
    ): javax.net.ssl.SSLSocketFactory {
        val cf = CertificateFactory.getInstance("X.509")
        val serverCert = cf.generateCertificate(
            ByteArrayInputStream(pemToDer(String(serverPem))),
        ) as X509Certificate

        val trustStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, null)
            setCertificateEntry("server", serverCert)
        }
        val tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).apply {
            init(trustStore)
        }
        val kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm()).apply {
            init(clientKeyStore, password)
        }
        return SSLContext.getInstance("TLS").apply {
            init(kmf.keyManagers, tmf.trustManagers, SecureRandom())
        }.socketFactory
    }

    private fun pemToDer(pem: String): ByteArray {
        val b64 = pem
            .replace("-----BEGIN CERTIFICATE-----", "")
            .replace("-----END CERTIFICATE-----", "")
            .replace("\\s".toRegex(), "")
        return android.util.Base64.decode(b64, android.util.Base64.DEFAULT)
    }
}
