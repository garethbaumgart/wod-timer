package app.mentalmetal.wharfwod.wear.application

import android.content.SharedPreferences

/** The settings store, so the rules can be tested without Android. Keys are additive, never migrated. */
interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun getBoolean(key: String, default: Boolean): Boolean
    fun putBoolean(key: String, value: Boolean)
    fun contains(key: String): Boolean
}

class MemoryStore : KeyValueStore {
    val values = mutableMapOf<String, Any>()
    override fun getString(key: String) = values[key] as? String
    override fun putString(key: String, value: String) { values[key] = value }
    override fun getBoolean(key: String, default: Boolean) = values[key] as? Boolean ?: default
    override fun putBoolean(key: String, value: Boolean) { values[key] = value }
    override fun contains(key: String) = values.containsKey(key)
}

class PrefsStore(private val prefs: SharedPreferences) : KeyValueStore {
    override fun getString(key: String): String? = prefs.getString(key, null)
    override fun putString(key: String, value: String) = prefs.edit().putString(key, value).apply()
    override fun getBoolean(key: String, default: Boolean) = prefs.getBoolean(key, default)
    override fun putBoolean(key: String, value: Boolean) = prefs.edit().putBoolean(key, value).apply()
    override fun contains(key: String) = prefs.contains(key)
}
