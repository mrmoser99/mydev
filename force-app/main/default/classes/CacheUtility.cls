/**
 * This class is used to add, retrieve, and manage values in the org cache. 
 * The org cache is not tied to any session and is available to the organization across requests and to all users.
 * 
 * @author Elena Sokolova @date 2021-01-15
 */
public class CacheUtility {

    /**
     * Method checks if the org cache contains a cached value corresponding to the specified key.
     * Key is an unique case-sensitive string value
     * 
     * @return Boolean type: true if the org cache contains specified key
     */
    public static Boolean containsKey(String key) {
        Boolean cacheExists = false;
        
        try {
            cacheExists = Cache.Org.contains(key);
        } catch (Exception ex) {
           ErrorLogger errorLog = new ErrorLogger();
           errorLog.logException(ex, Constants.GENERIC_ERRORLOG_RECORDTYPE,null, true); 
        }

        return cacheExists;
    }
    /**
     * Method checks if the org cache contains a cached value corresponding to the specified key and get value by this key.
     * 
     * @return Object (the cached value corresponding to the specified key from the org cache).
     */
    public static Object getCachedObject(String key) {
        Object cachedObject;

        try {
            if (containsKey(key)) {
                cachedObject = Cache.Org.get(key);
            }
        } catch (Exception ex) {
           ErrorLogger errorLog = new ErrorLogger();
           errorLog.logException(ex, Constants.GENERIC_ERRORLOG_RECORDTYPE,null, true); 
        }  

        return cachedObject;
    }
    /**
     * Method stores the specified key/value pair as a cached entry in the org cache. 
     * The put method can write only to the cache in your org’s namespace.
     */
    public static void setCachedObject(String key, Object value) {
        try {
            Cache.Org.put(key, value);
        } catch (Exception ex) {
           ErrorLogger errorLog = new ErrorLogger();
           errorLog.logException(ex, Constants.GENERIC_ERRORLOG_RECORDTYPE,null, true); 
        }
    }
    /**
     * Method checks if the org cache contains a cached value corresponding to the specified key and get value by this key.
     * 
     * @return Object (the cached value corresponding to the specified key from the org cache).
     */
    public static List<sObject> getCache(String key, String query) {
        List<sObject> result = null;
        
        if (containsKey(key)) {
            result = (List<SObject>) Cache.Org.get(key);
        } else {
            result = Database.query(query);
            setCachedObject(key, result);
        }

        return result;
    }
    /**
     * Method deletes the cached value corresponding to the specified key from the org cache.
     */
    public static void clearCache(String key) {
        if (Cache.Org.contains(key)) {
            Cache.Org.remove(key);
        }
    }
}