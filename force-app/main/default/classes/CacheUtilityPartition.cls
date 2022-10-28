/**
 * This class is used to add, retrieve, and manage values in the org cache. 
 * The org cache is not tied to any session and is available to the organization across requests and to all users.
 * 
 * Change Log:
 * 
 *  09/29/2021 - MRM Created class
 */


 /* SAMPLE CALL

        String KEY = 'PricingAuthtoken';
        public static String PARTITION = 'local.DLLonDemand';

        CacheUtilityPartition.sessionInfo s = new CacheUtilityPartition.sessionInfo();
         
        if (cacheUtilityPartition.containsKey(PARTITION,KEY)){
            s = (sessionInfo)CacheUtilityPartition.getCachedObject(KEY);  //returns the object in cache
            if (system.now() > s.sessionExpiration){
                 
                cacheUtility.clearCache(PARTITION, KEY); //expired  

                //Create/Store new token
                s.sessionToken =  the token your oauth call returned
                s.sessionExpiration = the expiration date your call returned less 1 hour
                 
                CacheUtility.setCachedObject(PARTITION,KEY, s);

             }
            else{
                system.debug('Found cache' + ' ' + s);
                return s.sessionToken;  //USE THIS TOKEN
            }
        }   
        else{
            //Create/Store new token
                
            s.sessionToken =  the token your oauth call returned
            s.sessionExpiration = the expiration date your call returned less 1 hour
                 
            CacheUtility.setCachedObject(PARTITION, KEY, s);

        }
 */

public class CacheUtilityPartition {

    /**
     * Method checks if the org cache contains a cached value corresponding to the specified key.
     * Key is an unique case-sensitive string value
     * 
     * @return Boolean type: true if the org cache contains specified key
     */

    /* Structures to Store in Cache */
    public class sessionInfo {
            public string sessionToken {get;set;}
            public dateTime sessionExpiration {get;set;}
    }

    public static Cache.OrgPartition getPartition(String partitionName){
 
        return  Cache.Org.getPartition(partitionName);
        
        
    }
    
    public static Boolean containsKey(String partitionName, String key) {

        Boolean cacheExists = false;

        
        try {
         system.debug(' in get partition' + CacheUtilityPartition.getPartition(partitionName));
         if ( CacheUtilityPartition.getPartition(partitionName).contains(key))
                cacheExists = true;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }

        return cacheExists;
    }

    /**
     * Method checks if the org cache contains a cached value corresponding to the specified key and get value by this key.
     * 
     * @return Object (the cached value corresponding to the specified key from the org cache).
     */
    public static Object getCachedObject(String partitionName, String key) {

        Object cachedObject;

        try {
            if (containsKey(partitionName,key)) {
                cachedObject =  CacheUtilityPartition.getPartition(partitionName).get(key);
            }
        } catch (Exception ex) {
            System.debug('Cache not found' + ex.getMessage());
        }
        
        return cachedObject;
    }

    /**
     * Method stores the specified key/value pair as a cached entry in the org cache. 
     * The put method can write only to the cache in your org’s namespace.
     */
    public static void setCachedObject(String partitionName, String key, Object value) {

        system.debug('putting the following in to cache' + key + '-' + value);
        try {
            CacheUtilityPartition.getPartition(partitionName).put(key, value);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    /**
     * Method checks if the org cache contains a cached value corresponding to the specified key and get value by this key.
     * 
     * @return Object (the cached value corresponding to the specified key from the org cache).
     */
    public static Object getCache(String partitionName, String key) {

        Object result = null;
        if (containsKey(partitionName,key)) {
            result =  CacheUtilityPartition.getPartition(partitionName).get(key);
        } 
        return result;
    }

    /**
     * Method deletes the cached value corresponding to the specified key from the org cache.
     */
    public static void clearCache(String partitionName, String key) {
        if ( CacheUtilityPartition.getPartition(partitionName).contains(key)) {
            CacheUtilityPartition.getPartition(partitionName).remove(key);
        }
    }
}