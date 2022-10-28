/**
 * Created by ShiqiSun on 11/17/2021.
 */

public with sharing class priceQuotePageController {
    @AuraEnabled
    public static List<LookupSearchResult> searchContacts(String searchTerm) {
        List<LookupSearchResult> lookupToReturn = new List<LookupSearchResult>();
        List<Contact> contacts = [ SELECT Id, Name FROM Contact WHERE LastName = :searchTerm OR FirstName = :searchTerm];
        for(Contact c : contacts){ LookupSearchResult lookUp = new LookupSearchResult(c.Id, 'Contact', 'Contact', c.Name, '');
            lookupToReturn.add(lookUp);
        }
        return lookupToReturn;
    }
}