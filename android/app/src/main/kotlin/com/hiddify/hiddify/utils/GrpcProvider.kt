package com.hiddify.hiddify.utils

/*
 * Copyright (C) 2019 Square, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import com.hiddify.core.api.v2.hcore.CoreClient
import com.hiddify.hiddify.Settings
import com.squareup.wire.GrpcClient
import io.grpc.CallOptions
import io.grpc.ManagedChannelBuilder
import java.io.IOException
import java.io.InputStream
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.time.Duration
import java.util.Arrays
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocketFactory
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Protocol.HTTP_1_1
import okhttp3.Protocol.HTTP_2
import okio.Buffer
import java.util.concurrent.TimeUnit

object GrpcClientProvider {
    private val okHttpClient = OkHttpClient.Builder()
        .protocols(listOf(Protocol.H2_PRIOR_KNOWLEDGE))
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()

    val grpcClient: GrpcClient = GrpcClient.Builder()
        .client(okHttpClient)
        .baseUrl("http://127.0.0.1:${Settings.grpcServiceModePort}")
        .build()


    private fun socketFactoryAndTrustManager(): Pair<SSLSocketFactory, X509TrustManager> {
        val trustManager: X509TrustManager
        val sslSocketFactory: SSLSocketFactory
        try {
            trustManager = trustManagerForCertificates(
                trustedCertificatesInputStream(),
            )
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, arrayOf(trustManager), null)
            sslSocketFactory = sslContext.socketFactory
        } catch (e: GeneralSecurityException) {
            throw RuntimeException(e)
        }

        return sslSocketFactory to trustManager
    }

    private fun trustedCertificatesInputStream(): InputStream {
        val myCertificate = "-----BEGIN CERTIFICATE-----\n" +
                "MIIC/DCCAeSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAvMS0wKwYDVQQDEyRkNWY2\n" +
                "NTRhNC0zOWJlLTQyYjEtOGNlYi1kYTI3MmJmNTI2ZTQwIBcNMTkwODEyMjEwMzIx\n" +
                "WhgPMjExOTA3MTkyMTAzMjFaMC8xLTArBgNVBAMTJGQ1ZjY1NGE0LTM5YmUtNDJi\n" +
                "MS04Y2ViLWRhMjcyYmY1MjZlNDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC\n" +
                "ggEBAJQzrBa2Zp7lJ8vJ/EWrkGU2BAOublkMl5XI0cbSIfbvuITXgHX7W5sDeEwx\n" +
                "6ultnUBVg6PmEbLAaZFtqg7gFPaVGbvP4h07FHSjRdf+y8W3QgoBIhc7/zuJiw1h\n" +
                "CsJ9D7eGl2dnXO6FgdY6ISnPAfxzzrZPCJtKL+Ffm9UnfCA7AYaQQZoymqVTGIsC\n" +
                "QAekkRkRia7gpUrTvR0hXST18KMcB7QKEv75rL8pEPHirJjyujBh+4VYVpLRDtbc\n" +
                "QKxCCXcn/zhTsn+4TV/4SgO1IhU+TBv4/iffzLi/aXKEEoPJhgIbMOd5ri1XBsTe\n" +
                "pGNaBOlYlEm8q8u1E3nGxzmkBtMCAwEAAaMhMB8wHQYDVR0RAQH/BBMwEYIJbG9j\n" +
                "YWxob3N0hwQKAAICMA0GCSqGSIb3DQEBCwUAA4IBAQAjL/inUHQbYD6bosFDQfyL\n" +
                "E9LOanO3ewiuZr5Sa4DJ5n8kNPdAO9M9urfmTbOUdvMfrH+fqiEwo6a7NTqT9bGk\n" +
                "Ewz7/LdpvWIGMpnijLEPTDTur2VmjpjqtawvzbFiHhdzOZk3o6bKbY3qac7CxaaO\n" +
                "MWZKF+o+YRCXVAJ2NQZLW2D9ee1qOXpK7VA360MFoyfo3cP8z6DDdNJm6gDAK+wI\n" +
                "1pMCdrdwHuu+ExKKA8za4r6dThVQu5jp6d7GO+2qf9rGkm1idIgjGtsgC+hPmhLb\n" +
                "7RK0ynU3Ai32elqwTDpD1WGuP2yacSWweh3GG6lG1NNY7n3tsccUWnsZztQ66Oh4\n" +
                "-----END CERTIFICATE-----"
        return Buffer()
            .writeUtf8(myCertificate)
            .inputStream()
    }

    @Throws(GeneralSecurityException::class)
    private fun trustManagerForCertificates(inputStream: InputStream): X509TrustManager {
        val certificateFactory = CertificateFactory.getInstance("X.509")
        val certificates = certificateFactory.generateCertificates(inputStream)
        if (certificates.isEmpty()) {
            throw IllegalArgumentException("expected non-empty set of trusted certificates")
        }

        // Put the certificates a key store.
        val password = "password".toCharArray() // Any password will work.
        val keyStore = newEmptyKeyStore(password)
        for ((index, certificate) in certificates.withIndex()) {
            val certificateAlias = index.toString()
            keyStore.setCertificateEntry(certificateAlias, certificate)
        }

        // Use it to build an X509 trust manager.
        val keyManagerFactory = KeyManagerFactory.getInstance(
            KeyManagerFactory.getDefaultAlgorithm(),
        )
        keyManagerFactory.init(keyStore, password)
        val trustManagerFactory = TrustManagerFactory.getInstance(
            TrustManagerFactory.getDefaultAlgorithm(),
        )
        trustManagerFactory.init(keyStore)
        val trustManagers = trustManagerFactory.trustManagers
        if (trustManagers.size != 1 || trustManagers[0] !is X509TrustManager) {
            throw IllegalStateException(
                "Unexpected default trust managers:" + Arrays.toString(trustManagers),
            )
        }
        return trustManagers[0] as X509TrustManager
    }

    @Throws(GeneralSecurityException::class)
    private fun newEmptyKeyStore(password: CharArray): KeyStore {
        try {
            val keyStore = KeyStore.getInstance(KeyStore.getDefaultType())
            val inputStream: InputStream? = null // By convention, 'null' creates an empty key store.
            keyStore.load(inputStream, password)
            return keyStore
        } catch (e: IOException) {
            throw AssertionError(e)
        }
    }
}