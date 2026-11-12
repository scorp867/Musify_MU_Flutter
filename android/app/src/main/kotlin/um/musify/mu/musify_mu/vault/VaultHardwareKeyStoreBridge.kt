package um.musify.mu.musify_mu.vault

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import android.util.Log
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.security.KeyStore
import java.security.ProviderException
import java.util.concurrent.atomic.AtomicBoolean
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Native Android KeyStore Platform Channel Bridge.
 *
 * Implements hardware-backed, non-exportable AES-256-GCM key management (TEE/StrongBox),
 * hardware-backed HMAC-SHA256 pepper derivation, BiometricPrompt.CryptoObject authentication,
 * off-thread cipher operations via Dispatchers.IO, and deterministic typed error code mapping.
 */
class VaultHardwareKeyStoreBridge(private val activity: FragmentActivity) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "VaultKeyStoreBridge"
        private const val CHANNEL_NAME = "com.musify.mu/vault_hardware_keystore"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val MASTER_KEY_ALIAS = "MusifyVaultMasterKey_v1"
        private const val BIOMETRIC_KEY_ALIAS = "MusifyVaultBiometricKey_v1"
        private const val PEPPER_KEY_ALIAS = "MusifyVaultHardwarePepper_v1"
        private const val AES_GCM_TRANSFORMATION = "AES/GCM/NoPadding"
        private const val HMAC_ALGORITHM = "HmacSHA256"
        private const val GCM_IV_LENGTH_BYTES = 12
        private const val GCM_TAG_LENGTH_BITS = 128
        private const val AES_KEY_SIZE_BITS = 256
    }

    private var channel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val bridgeScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val isSessionUnlocked = AtomicBoolean(false)

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler(this@VaultHardwareKeyStoreBridge)
        }
        Log.i(TAG, "VaultHardwareKeyStoreBridge registered on channel: $CHANNEL_NAME")
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        bridgeScope.cancel()
        isSessionUnlocked.set(false)
        Log.i(TAG, "VaultHardwareKeyStoreBridge detached and scope canceled")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasMasterKey" -> {
                bridgeScope.launch {
                    val exists = withContext(Dispatchers.IO) {
                        hasKeyInKeyStore(MASTER_KEY_ALIAS)
                    }
                    result.success(exists)
                }
            }

            "generateMasterKey" -> {
                val forceOverwrite = call.argument<Boolean>("forceOverwrite") ?: false
                bridgeScope.launch {
                    try {
                        withContext(Dispatchers.IO) {
                            val keyStore = getKeyStore()
                            if (keyStore.containsAlias(MASTER_KEY_ALIAS) && !forceOverwrite) {
                                Log.i(TAG, "Master key already exists; preserving existing hardware key")
                            } else {
                                generateHardwareKeys()
                            }
                        }
                        isSessionUnlocked.set(true)
                        result.success(true)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            "deriveHardwarePepper" -> {
                val data = extractByteArray(call, "data")
                if (data == null || data.isEmpty()) {
                    result.error("INVALID_ARGUMENT", "Data byte array is required for hardware pepper derivation", null)
                    return
                }

                bridgeScope.launch {
                    try {
                        val peppered = withContext(Dispatchers.IO) {
                            deriveHardwarePepperInternal(data)
                        }
                        result.success(peppered)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            "encryptPayload" -> {
                val payload = extractByteArray(call, "payload")
                if (payload == null) {
                    result.error("INVALID_ARGUMENT", "Payload byte array is required for encryption", null)
                    return
                }

                if (!isSessionUnlocked.get()) {
                    result.error("CRYPTO_FAULT_SESSION_LOCKED", "Vault session is locked. Authenticate first.", null)
                    return
                }

                bridgeScope.launch {
                    try {
                        val ciphertext = withContext(Dispatchers.IO) {
                            encryptPayloadInternal(payload)
                        }
                        result.success(ciphertext)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            "decryptPayload" -> {
                val payload = extractByteArray(call, "payload")
                if (payload == null) {
                    result.error("INVALID_ARGUMENT", "Payload byte array is required for decryption", null)
                    return
                }

                if (!isSessionUnlocked.get()) {
                    result.error("CRYPTO_FAULT_SESSION_LOCKED", "Vault session is locked. Authenticate first.", null)
                    return
                }

                bridgeScope.launch {
                    try {
                        val plaintext = withContext(Dispatchers.IO) {
                            decryptPayloadInternal(payload)
                        }
                        result.success(plaintext)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            "encryptConfigPayload" -> {
                val payload = extractByteArray(call, "payload")
                if (payload == null) {
                    result.error("INVALID_ARGUMENT", "Payload byte array is required for configuration encryption", null)
                    return
                }

                bridgeScope.launch {
                    try {
                        val ciphertext = withContext(Dispatchers.IO) {
                            encryptPayloadInternal(payload)
                        }
                        result.success(ciphertext)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            "decryptConfigPayload" -> {
                val payload = extractByteArray(call, "payload")
                if (payload == null) {
                    result.error("INVALID_ARGUMENT", "Payload byte array is required for configuration decryption", null)
                    return
                }

                bridgeScope.launch {
                    try {
                        val plaintext = withContext(Dispatchers.IO) {
                            decryptPayloadInternal(payload)
                        }
                        result.success(plaintext)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            "authenticateBiometrics" -> {
                val title = call.argument<String>("title") ?: "Unlock Secure Vault"
                val subtitle = call.argument<String>("subtitle") ?: "Verify your identity"
                val cancelButton = call.argument<String>("cancelButton") ?: "Cancel"

                dispatchBiometricPrompt(title, subtitle, cancelButton, result)
            }

            "unlockSession" -> {
                isSessionUnlocked.set(true)
                result.success(true)
            }

            "lockSession" -> {
                isSessionUnlocked.set(false)
                result.success(true)
            }

            "destroyMasterKey" -> {
                bridgeScope.launch {
                    try {
                        withContext(Dispatchers.IO) {
                            deleteKeyFromKeyStore(MASTER_KEY_ALIAS)
                            deleteKeyFromKeyStore(BIOMETRIC_KEY_ALIAS)
                            deleteKeyFromKeyStore(PEPPER_KEY_ALIAS)
                        }
                        isSessionUnlocked.set(false)
                        result.success(true)
                    } catch (e: Exception) {
                        handleException(e, result)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun extractByteArray(call: MethodCall, key: String): ByteArray? {
        val arg = call.argument<ByteArray>(key)
        if (arg != null) return arg
        val raw = call.arguments
        return if (raw is ByteArray) raw else null
    }

    private fun getKeyStore(): KeyStore {
        return KeyStore.getInstance(KEYSTORE_PROVIDER).apply {
            load(null)
        }
    }

    private fun hasKeyInKeyStore(alias: String): Boolean {
        return try {
            val keyStore = getKeyStore()
            keyStore.containsAlias(alias)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking KeyStore alias $alias", e)
            false
        }
    }

    private fun deleteKeyFromKeyStore(alias: String) {
        try {
            val keyStore = getKeyStore()
            if (keyStore.containsAlias(alias)) {
                keyStore.deleteEntry(alias)
                Log.i(TAG, "Successfully deleted KeyStore entry: $alias")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting KeyStore entry $alias", e)
            throw e
        }
    }

    private fun generateHardwareKeys() {
        val keyStore = getKeyStore()
        if (keyStore.containsAlias(MASTER_KEY_ALIAS)) {
            keyStore.deleteEntry(MASTER_KEY_ALIAS)
        }
        if (keyStore.containsAlias(BIOMETRIC_KEY_ALIAS)) {
            keyStore.deleteEntry(BIOMETRIC_KEY_ALIAS)
        }
        if (keyStore.containsAlias(PEPPER_KEY_ALIAS)) {
            keyStore.deleteEntry(PEPPER_KEY_ALIAS)
        }

        generateKeyWithFallback(MASTER_KEY_ALIAS, isBiometricBound = false)
        generateKeyWithFallback(BIOMETRIC_KEY_ALIAS, isBiometricBound = true)
        generateHardwarePepperKeyWithFallback()
    }

    private fun generateHardwarePepperKeyWithFallback() {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256, KEYSTORE_PROVIDER)

        // Attempt StrongBox-backed generation on Android 9+ (API 28+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val strongBoxSpec = KeyGenParameterSpec.Builder(
                    PEPPER_KEY_ALIAS,
                    KeyProperties.PURPOSE_SIGN
                )
                    .setIsStrongBoxBacked(true)
                    .build()
                keyGenerator.init(strongBoxSpec)
                keyGenerator.generateKey()
                verifyKeyNonExportable(PEPPER_KEY_ALIAS)
                Log.i(TAG, "Successfully generated hardware pepper key in StrongBox")
                return
            } catch (e: Exception) {
                when (e) {
                    is StrongBoxUnavailableException,
                    is ProviderException -> {
                        Log.w(TAG, "StrongBox unavailable for hardware pepper key, falling back to standard TEE: ${e.message}")
                    }
                    else -> throw e
                }
            }
        }

        // Standard TEE generation fallback
        val teeSpec = KeyGenParameterSpec.Builder(
            PEPPER_KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN
        ).build()
        keyGenerator.init(teeSpec)
        keyGenerator.generateKey()
        verifyKeyNonExportable(PEPPER_KEY_ALIAS)
        Log.i(TAG, "Successfully generated hardware pepper key in standard TEE KeyStore")
    }

    private fun deriveHardwarePepperInternal(data: ByteArray): ByteArray {
        val keyStore = getKeyStore()
        if (!keyStore.containsAlias(PEPPER_KEY_ALIAS)) {
            generateHardwarePepperKeyWithFallback()
        }
        val key = keyStore.getKey(PEPPER_KEY_ALIAS, null) as? SecretKey
            ?: throw IllegalStateException("Hardware pepper key not found in KeyStore. Key generation required.")

        val mac = Mac.getInstance(HMAC_ALGORITHM)
        mac.init(key)
        return mac.doFinal(data)
    }

    private fun generateKeyWithFallback(alias: String, isBiometricBound: Boolean) {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER)

        // Attempt StrongBox-backed generation on Android 9+ (API 28+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val strongBoxSpec = buildKeyGenSpec(alias, isStrongBox = true, isBiometricBound = isBiometricBound)
                keyGenerator.init(strongBoxSpec)
                keyGenerator.generateKey()
                verifyKeyNonExportable(alias)
                Log.i(TAG, "Successfully generated hardware key '$alias' in StrongBox")
                return
            } catch (e: Exception) {
                when (e) {
                    is StrongBoxUnavailableException,
                    is ProviderException -> {
                        Log.w(TAG, "StrongBox unavailable for '$alias', falling back to standard TEE: ${e.message}")
                    }
                    else -> throw e
                }
            }
        }

        // Standard TEE generation fallback
        val teeSpec = buildKeyGenSpec(alias, isStrongBox = false, isBiometricBound = isBiometricBound)
        keyGenerator.init(teeSpec)
        keyGenerator.generateKey()
        verifyKeyNonExportable(alias)
        Log.i(TAG, "Successfully generated hardware key '$alias' in standard TEE KeyStore")
    }

    private fun buildKeyGenSpec(alias: String, isStrongBox: Boolean, isBiometricBound: Boolean): KeyGenParameterSpec {
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(AES_KEY_SIZE_BITS)
            .setRandomizedEncryptionRequired(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && isStrongBox) {
            builder.setIsStrongBoxBacked(true)
        }

        if (isBiometricBound) {
            builder.setUserAuthenticationRequired(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(
                    0, // 0 = every cipher operation requires explicit authentication
                    KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setInvalidatedByBiometricEnrollment(true)
            }
        }

        return builder.build()
    }

    private fun verifyKeyNonExportable(alias: String) {
        val keyStore = getKeyStore()
        val key = keyStore.getKey(alias, null) as? SecretKey
            ?: throw IllegalStateException("Key '$alias' not found in KeyStore after generation")

        if (key.encoded != null) {
            keyStore.deleteEntry(alias)
            throw SecurityException(
                "CRITICAL SECURITY FAULT: Key '$alias' is exportable! key.encoded must be null for hardware-backed keys."
            )
        }
    }

    private fun encryptPayloadInternal(plaintext: ByteArray): ByteArray {
        val keyStore = getKeyStore()
        val key = keyStore.getKey(MASTER_KEY_ALIAS, null) as? SecretKey
            ?: throw IllegalStateException("Master key not found in KeyStore. Key generation required.")

        val cipher = Cipher.getInstance(AES_GCM_TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key)

        val iv = cipher.iv ?: throw IllegalStateException("Cipher failed to generate IV")
        check(iv.size == GCM_IV_LENGTH_BYTES) { "Invalid GCM IV length: ${iv.size} bytes (expected $GCM_IV_LENGTH_BYTES)" }

        val ciphertextWithTag = cipher.doFinal(plaintext)

        val buffer = ByteBuffer.allocate(GCM_IV_LENGTH_BYTES + ciphertextWithTag.size)
        buffer.put(iv)
        buffer.put(ciphertextWithTag)
        return buffer.array()
    }

    private fun decryptPayloadInternal(payload: ByteArray): ByteArray {
        val minRequiredLength = GCM_IV_LENGTH_BYTES + (GCM_TAG_LENGTH_BITS / 8) // 12 + 16 = 28 bytes
        if (payload.size < minRequiredLength) {
            throw IllegalArgumentException(
                "Ciphertext payload length (${payload.size}) is shorter than minimum required ($minRequiredLength bytes)"
            )
        }

        val keyStore = getKeyStore()
        val key = keyStore.getKey(MASTER_KEY_ALIAS, null) as? SecretKey
            ?: throw IllegalStateException("Master key not found in KeyStore. Key generation required.")

        val iv = payload.copyOfRange(0, GCM_IV_LENGTH_BYTES)
        val encryptedData = payload.copyOfRange(GCM_IV_LENGTH_BYTES, payload.size)

        val spec = GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv)
        val cipher = Cipher.getInstance(AES_GCM_TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key, spec)

        return cipher.doFinal(encryptedData)
    }

    private fun dispatchBiometricPrompt(
        title: String,
        subtitle: String,
        cancelButton: String,
        result: MethodChannel.Result
    ) {
        val biometricManager = BiometricManager.from(activity)
        val canAuth = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        if (canAuth != BiometricManager.BIOMETRIC_SUCCESS) {
            when (canAuth) {
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                    result.error("BIOMETRIC_NOT_ENROLLED", "No biometrics enrolled on device", null)
                    return
                }
                BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE,
                BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                    result.error("BIOMETRIC_UNAVAILABLE", "Biometric hardware is unavailable", null)
                    return
                }
                else -> {
                    result.error("BIOMETRIC_ERROR", "Biometric authentication not possible ($canAuth)", null)
                    return
                }
            }
        }

        val keyStore = getKeyStore()
        val key = keyStore.getKey(BIOMETRIC_KEY_ALIAS, null) as? SecretKey
        if (key == null) {
            result.error("CRYPTO_FAULT_KEY_NOT_FOUND", "Biometric key not found in KeyStore", null)
            return
        }

        val cipher: Cipher
        try {
            cipher = Cipher.getInstance(AES_GCM_TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, key)
        } catch (e: KeyPermanentlyInvalidatedException) {
            result.error(
                "CRYPTO_FAULT_KEY_INVALIDATED",
                "Biometric key permanently invalidated by new OS biometric enrollment",
                null
            )
            return
        } catch (e: Exception) {
            handleException(e, result)
            return
        }

        val cryptoObject = BiometricPrompt.CryptoObject(cipher)
        val executor = ContextCompat.getMainExecutor(activity)

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setNegativeButtonText(cancelButton)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .setConfirmationRequired(false)
            .build()

        val prompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    isSessionUnlocked.set(true)
                    result.success(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    when (errorCode) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        BiometricPrompt.ERROR_CANCELED -> {
                            result.error("BIOMETRIC_CANCELLED", errString.toString(), null)
                        }
                        BiometricPrompt.ERROR_LOCKOUT,
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> {
                            result.error("BIOMETRIC_LOCKED_OUT", errString.toString(), null)
                        }
                        else -> {
                            result.error("BIOMETRIC_ERROR", errString.toString(), null)
                        }
                    }
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                }
            }
        )

        prompt.authenticate(promptInfo, cryptoObject)
    }

    private fun handleException(e: Exception, result: MethodChannel.Result) {
        Log.e(TAG, "Unhandled exception in VaultHardwareKeyStoreBridge: ${e.message}", e)
        when (e) {
            is KeyPermanentlyInvalidatedException -> {
                result.error(
                    "CRYPTO_FAULT_KEY_INVALIDATED",
                    "Key permanently invalidated by new OS biometric enrollment.",
                    null
                )
            }
            is AEADBadTagException -> {
                result.error(
                    "CRYPTO_FAULT_DECRYPTION_CORRUPTED",
                    "Decryption authentication failed: corrupted ciphertext or tampered authentication tag.",
                    null
                )
            }
            is IllegalArgumentException -> {
                result.error(
                    "INVALID_ARGUMENT",
                    e.message ?: "Invalid cryptographic input argument.",
                    null
                )
            }
            is IllegalStateException -> {
                result.error(
                    "CRYPTO_FAULT_KEY_NOT_FOUND",
                    e.message ?: "KeyStore key not available.",
                    null
                )
            }
            is SecurityException -> {
                result.error(
                    "CRYPTO_FAULT_HARDWARE_UNAVAILABLE",
                    e.message ?: "Hardware security validation failed.",
                    null
                )
            }
            else -> {
                result.error(
                    "CRYPTO_FAULT_INTERNAL",
                    e.message ?: "Internal cryptographic error occurred.",
                    null
                )
            }
        }
    }
}
