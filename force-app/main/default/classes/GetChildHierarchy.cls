public class GetChildHierarchy {

    public static List<Id> getChildAccountswithOrgSiteId(Id pId){
        List<Account> acc = new List<Account>();
        List<Id> retAccId = new List<Id>();
        acc = [Select id from Account where (ParentId =:pId or Parent.ParentId =:pId 
                                             or Parent.Parent.ParentId =:pId or Parent.Parent.Parent.ParentId =:pId) 
                                      and Originating_Site_ID__c!= null];
        
        if(acc.size() >0){
            for(Account a:acc){
                retAccId.add(a.Id);
            }
            return retAccId;
        }else 
        {
            return null;
    }
}
}