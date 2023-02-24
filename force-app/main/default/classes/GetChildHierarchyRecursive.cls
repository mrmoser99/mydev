/**
 * @description       : 
 * @author            : Mark R. Moser
 * @group             : 
 * @last modified on  : 01-20-2023
 * @last modified by  : Mark Moser
 * 
 * this is a recursive class and will run soql per level in a hierarchy. we will normally have 1-4 levels in a dealer hierarchy.  SOQL limits are 100 soql statements; we will never
 * have a dealer hierarchy with 100 levels.  If we get 100 levels, then we should give up on go home.
 * 
 * mark did an amazing job on this!!!!
 * 
 * call this as follows:

    Set<ID> test = new Set<ID>();
    test.add('00178000007a3yB');
    GetChildHierarchyRecursive t = new GetChildHierarchyRecursive(test);
    system.debug('final parent set is: ' + t.finalParentSet);

**/

public class GetChildHierarchyRecursive {
    
        /* holder of final set of parents */
        public Set<ID> finalParentSet = new Set<ID>();

        /*constructor*/
        public GetChildHierarchyRecursive(Set<ID> accountSet){
            getChildren(accountSet);
        }

        /* Recursive method returning children of a set of parents) */
   	    public Set<ID> getChildren(Set<ID> accountSet) {

            List<Account> tempList = [select id, Originating_Site_ID__c from account where ParentId in :accountSet];
            Set<ID> childSet = new Set<ID>(); 
            for (Account a:tempList){
                if(String.isNotBlank(a.Originating_Site_ID__c)){
                	finalParentSet.add(a.id);
                }
                    childSet.add(a.id);
            } 
            if (tempList.size() == 0){
                return null;
            }
            else{
                return getChildren(childSet);  
            }
        }
    
    //get child contact 
    @AuraEnabled
    public static List<Contact> getChildContacts(Id accountId){
        GetChildHierarchyRecursive obj = new GetChildHierarchyRecursive(new Set<id> {accountId});
         string condition = null;
         boolean isCondition = false;
        
        List<Contact> retContactList = new List<Contact>();
        system.debug('obj.finalParentSet = ' +obj.finalParentSet);
      //  system.debug('conName ' +conName);
       
      
             retContactList = [Select id, FirstName, LastName, email, Role__c, Account.name 
                          from Contact 
                          where accountId = :obj.finalParentSet];
              
        system.debug('retconlist' +retContactList.size());
        
        return retContactList;
        
    }
    
  /*  public static getCondition(String conName, String conRole, String conBlank){
        String condition = '';
         if(String.isNotBlank(conName)){
             condition = ' NAME LIKE  '
         }
    }*/
    
    //create customer - call from lWC
   @auraEnabled
    public static void createPartnerUser(String profileName, List<Id> contactIds){
      //  Map<String, String>  contactMap = (Map<String, String>) JSON.deserialize(JSON.serialize(contactIds), Map<String, String>.class);
       
        
        List<Contact> conList = [Select id, FirstName, LastName, Email
                                 from Contact where ID =:contactIds];
        Profile profileId = [Select id from Profile where name = :profileName limit 1] ;
        
        User usr = new User( email='genelia001.dsouza@gmail.com',
                profileid = profileId.Id, 
                UserName='genelia001.dsouza@gmail.com.test', 
                LastName = 'testP',
                Alias = 'GDS',
                TimeZoneSidKey='America/New_York',
                EmailEncodingKey='ISO-8859-1',
                LocaleSidKey='en_US', 
                LanguageLocaleKey='en_US',
                ContactId = conList[0].Id,
                PortalRole = 'Manager');
        
        insert usr;
        
        
    }
    
}