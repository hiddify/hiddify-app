package com.hiddify.hiddify.utils

import android.util.Log
import com.hiddify.core.mobile.Mobile
import com.hiddify.hiddify.Settings
import com.squareup.wire.GrpcClient
import okhttp3.OkHttpClient
import okhttp3.Protocol
import java.io.ByteArrayInputStream
import java.io.File
import java.security.KeyFactory
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Base64
import java.util.concurrent.TimeUnit
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

/**
 * gRPC client for the core's server, which runs in this process.
 *
 * When the app registered its client certificate, the core serves mTLS and this client presents the
 * same identity the app uses: the certificate and key Flutter keeps once in `<base dir>/grpc`
 * (client.crt, client.key), and trusts only the core's own server certificate. Without one the core
 * serves plain HTTP/2 on the loopback port.
 */
object GrpcClientProvider {
    private const val TAG = "GrpcClientProvider"
    private const val IDENTITY_DIR = "grpc"
    private const val CERTIFICATE_FILE = "client.crt"
    private const val PRIVATE_KEY_FILE = "client.key"

    /**
     * Whether the core serves mTLS: the app keeps a client identity in its private storage exactly
     * when it runs the core that way (and removes it otherwise), so the files are the switch.
     */
    val usesMutualTls: Boolean
        get() = File(identityDirectory(), CERTIFICATE_FILE).exists()

    private fun identityDirectory() = File(Settings.baseDir, IDENTITY_DIR)

    /**
     * Built on every call: the server certificate exists only once the core is set up, and the
     * client identity is made by Flutter before it starts the service.
     */
    val grpcClient: GrpcClient
        get() = buildClient()

    // Metadata streams can be idle indefinitely. Keep unary calls bounded as before.
    val streamingGrpcClient: GrpcClient
        get() = buildClient(streaming = true)

    private fun buildClient(streaming: Boolean = false): GrpcClient {
        val port = Settings.grpcServiceModePort
        val builder = OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(if (streaming) 0 else 10, TimeUnit.SECONDS)
            .writeTimeout(10, TimeUnit.SECONDS)

        if (!usesMutualTls) {
            val client = builder.protocols(listOf(Protocol.H2_PRIOR_KNOWLEDGE)).build()
            return GrpcClient.Builder().client(client).baseUrl("http://127.0.0.1:$port").build()
        }

        val (sslContext, trustManager) = mutualTls()
        val client = builder
            .protocols(listOf(Protocol.HTTP_2, Protocol.HTTP_1_1))
            .sslSocketFactory(sslContext.socketFactory, trustManager)
            .build()
        return GrpcClient.Builder().client(client).baseUrl("https://127.0.0.1:$port").build()
    }

    private fun mutualTls(): Pair<SSLContext, X509TrustManager> {
        val directory = identityDirectory()
        val clientCertificate = readCertificate(File(directory, CERTIFICATE_FILE).readBytes())
        val clientKey = readPrivateKey(File(directory, PRIVATE_KEY_FILE).readText())
        val serverCertificate = readCertificate(Mobile.getServerPublicKey())

        val password = CharArray(0)
        val identityStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, password)
            setKeyEntry("client", clientKey, password, arrayOf(clientCertificate))
        }
        val keyManagers = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
            .apply { init(identityStore, password) }.keyManagers

        // only the core's own certificate is trusted
        val trustStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, password)
            setCertificateEntry("core", serverCertificate)
        }
        val trustManager = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
            .apply { init(trustStore) }.trustManagers.filterIsInstance<X509TrustManager>().single()

        val sslContext = SSLContext.getInstance("TLS").apply { init(keyManagers, arrayOf(trustManager), null) }
        Log.d(TAG, "using the stored client identity for mTLS")
        return sslContext to trustManager
    }

    private fun readCertificate(pem: ByteArray): X509Certificate =
        CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(pem)) as X509Certificate

    /** PKCS#8 PEM, as Flutter writes it. */
    private fun readPrivateKey(pem: String): java.security.PrivateKey {
        val body = pem
            .replace("-----BEGIN PRIVATE KEY-----", "")
            .replace("-----END PRIVATE KEY-----", "")
            .replace(Regex("\\s"), "")
        return KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(Base64.getDecoder().decode(body)))
    }
}
