@isTest
private class TestDDCacheUtilityPartition {

Static testmethod void test1(){

	DDCacheUtilityPartition.clearCache('local.DLLonDemand', 'PricingAuthtoken');

	DDCacheUtilityPartition.containsKey('local.DLLonDemand', 'PricingAuthtoken');

	Object x = DDCacheUtilityPartition.getCache('local.DLLonDemand', 'PricingAuthtoken');

	DDCacheUtilityPartition.getCachedObject('local.DLLonDemand', 'PricingAuthtoken');

	DDCacheUtilityPartition.setCachedObject('local.DLLonDemand', 'PricingAuthtoken', 'value');

	DDCacheUtilityPartition.sessionInfo si = new DDCacheUtilityPartition.sessionInfo();
	si.sessionExpiration = system.now();
	si.sessionToken = 'big one';

	DDCacheUtilityPartition.getPartition('test');

	DDCacheUtilityPartition.testBoost();


}

Static testmethod void test2(){

	CacheUtilityPartition.clearCache('local.DLLonDemand', 'PricingAuthtoken');

	CacheUtilityPartition.containsKey('local.DLLonDemand', 'PricingAuthtoken');

	Object x = CacheUtilityPartition.getCache('local.DLLonDemand', 'PricingAuthtoken');

	CacheUtilityPartition.getCachedObject('local.DLLonDemand', 'PricingAuthtoken');

	CacheUtilityPartition.setCachedObject('local.DLLonDemand', 'PricingAuthtoken', 'value');

	CacheUtilityPartition.sessionInfo si = new CacheUtilityPartition.sessionInfo();
	si.sessionExpiration = system.now();
	si.sessionToken = 'big one';

	DDCacheUtilityPartition.getPartition('test');

	DDCacheUtilityPartition.testBoost();


}
}