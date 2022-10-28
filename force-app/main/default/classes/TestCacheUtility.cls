/**
 * Test class for cacheUtility apex class
 * 
 * Version 1.0
 * 
 */
@isTest
public with sharing class TestCacheUtility {
    
    @isTest
    public static void testCacheEnabled() {

        Boolean cacheEnabled = true;
        try {
            Cache.Org.contains('testKey');
        } catch (Exception ex) {
            cacheEnabled = false;
        }

        System.assertEquals(true, cacheEnabled);
    }

    @isTest
    public static void testContainsKey() {

        String cacheKey = 'testKey';
        Cache.Org.put(cacheKey, 'test');
        Boolean cacheContainsKey = CacheUtility.containsKey(cacheKey);

        System.assertEquals(true, cacheContainsKey);
        Cache.Org.remove(cacheKey);
    }

    @isTest
    public static void testGetCachedObject() {

        String cacheKey = 'testKey';
        List<String> listStrings = new List<String>{'test'};
        Cache.Org.put(cacheKey, listStrings);

        List<String> cachedList = (List<String>) CacheUtility.getCachedObject(cacheKey);

        System.assertEquals(listStrings, cachedList);
        Cache.Org.remove(cacheKey);
    }

    @isTest
    public static void testSetCachedObject() {

        String cacheKey = 'testKey';
        List<String> listStrings = new List<String>{'test'};

        CacheUtility.setCachedObject(cacheKey, listStrings);

        List<String> cachedList = (List<String>) Cache.Org.get(cacheKey);

        System.assertEquals(listStrings, cachedList);
        Cache.Org.remove(cacheKey);
    }

    @isTest
    public static void testGetCache() {

        String cacheKey = 'testKey';
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        String query = 'SELECT Name FROM Account';
        Integer soqlQueries = Limits.getQueries();
        List<Account> accountsFromDatabase = (List<Account>) CacheUtility.getCache(cacheKey, query);

        System.assertEquals(1, Limits.getQueries() - soqlQueries);
        System.assertEquals(1, accountsFromDatabase.size());

        List<Account> accountsFromCache = (List<Account>) CacheUtility.getCache(cacheKey, query);

        System.assertEquals(1, Limits.getQueries() - soqlQueries);
        System.assertEquals(1, accountsFromCache.size());
        System.assertEquals(accountsFromDatabase, accountsFromCache);

        Cache.Org.remove(cacheKey);
    }

    @isTest
    public static void testClearCache() {

        String cacheKey = 'testKey';
        Cache.Org.put(cacheKey, 'test');

        CacheUtility.clearCache(cacheKey);

        System.assertEquals(false, Cache.Org.contains(cacheKey));
    }
    
    @isTest
    public static void testContainsKeyException() {

        Boolean cacheContainsKey;
      	Boolean exception1 = false;
        
        Test.startTest();
        try{
            String cacheKey = '@ASG!#asbd';
            Cache.Org.put(cacheKey, 'testexp');
            cacheContainsKey = CacheUtility.containsKey(cacheKey);
        }
        catch(Exception ex){
            exception1 = true;
        }
        Test.stopTest();      
        System.assertEquals(true, exception1);
    }
   
}