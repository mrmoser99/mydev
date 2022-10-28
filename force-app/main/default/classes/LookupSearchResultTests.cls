/**
 * Test class for LookupSearchResult apex class 
 * 
 * Version 1.0
 * 
 */
@isTest(isParallel=true)
public class LookupSearchResultTests {
    @isTest
    static void compareTo_should_work_with_two_null_titles() {
        LookupSearchResult r1 = getSearchResult(null);
        LookupSearchResult r2 = getSearchResult(null);

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(0, compareResult);
    }

    @isTest
    static void compareTo_should_work_with_this_null_title() {
        LookupSearchResult r1 = getSearchResult(null);
        LookupSearchResult r2 = getSearchResult('a');

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(1, compareResult);
    }

    @isTest
    static void compareTo_should_work_with_other_null_title() {
        LookupSearchResult r1 = getSearchResult('a');
        LookupSearchResult r2 = getSearchResult(null);

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(-1, compareResult);
    }

    @isTest
    static void compareTo_should_work_with_non_null_titles() {
        LookupSearchResult r1 = getSearchResult('a');
        LookupSearchResult r2 = getSearchResult('b');

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(-1, compareResult);
    }

    @isTest
    static void getters_should_work() {
        // For the sake of code coverage
        LookupSearchResult r = new LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle');
        LookupSearchResult r1 = new LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle','prodtype');
        LookupSearchResult r2 = new LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle','prodtype',false);
		LookupSearchResult r3 = new LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle','prodtype',false,false);
		LookupSearchResult r4 = new LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle','prodtype',false,false,false,false);
		//LookupSearchResult r5 = new LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle','prodtype',false,false);

        System.assertEquals('0010R00000yvEyRQAU', r.getId());
        System.assertEquals('type', r.getSObjectType());
        System.assertEquals('icon', r.getIcon());
        System.assertEquals('title', r.getTitle());
        System.assertEquals('subtitle', r.getSubtitle());
        System.assertEquals('prodtype', r3.getProductType());
		System.assertEquals(false, r3.getIsItadApplicable());
        System.assertEquals(false, r3.getIsPurchaseOptionAvailable());
        System.assertEquals(false, r4.getisProductAvailable());
        System.assertEquals(false, r4.getIsInsuranceAvailable());
    }

    private static LookupSearchResult getSearchResult(String title) {
        return new LookupSearchResult(null, null, null, title, null);
    }
}