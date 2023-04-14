/*****************************************************************************************************************
* Dll on Demaind (DD) PRICING UTILITY CLASS
*
* Change Log:
*
*  4/20/2023 - MRM Created class

*******************************************************************************************************************/
public without sharing class PricingUtilsWoSharing {    

    public class salesRep {
        public String id;
        public String name;
    }

    public static String getSalesReps(String originatingSiteId){         //site selected on portal

	if (originatingSiteId == null)
		return null;

	List<SalesRep> sList = new List<SalesRep>();
	Boolean error=false;
	String ErrorMsg = null;


	try{

		system.debug(originatingSiteId);


		Account a = [select id from Account
		             where originating_site_id__c = : originatingSiteId
		                                            ];

		

		List<Contact> cList = new List<Contact>();
		cList = [select name
		         from Contact
		         where accountId = : a.id
		                           and role__c = 'Partner Sales Rep'
		];

		for (Contact c : cList) {
			SalesRep r = new SalesRep();
			r.id = c.id;
			r.name = c.name;
			sList.add(r);
		}

	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getSalesReps:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		throw new AuraHandledException(ErrorMsg);
	}
	if (error)
		return null;
	else
		return JSON.serialize(sList);
}

}